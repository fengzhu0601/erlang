-module(db_mysqlutil).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("include/common.hrl").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

%% --------------------------------------------------------------------
%% Exported Functions
%% --------------------------------------------------------------------
-export([
		 make_insert_sql/2,
		 make_insert_sql/3,
		 
		 make_select_sql/3,
		 make_select_sql/5,
		 
		 make_replace_sql/3,
		 make_replace_sql/2,
		 
		 make_update_sql/3,
		 make_update_sql/4,
		 make_update_sql/5,
		 
		 make_delete_sql/2,
         get_where_sql/1
		 ]).

%% ====================================================================
%% API Functions
%% ====================================================================
-spec make_insert_sql(atom(), list(), list()) -> list().
%% @doc Make insert sql sentence.
make_insert_sql(Table_name, FieldList, ValueList) ->
	L = make_conn_sql(FieldList, ValueList, []),
	lists:concat(["insert into `", Table_name, "` set ", L]).

-spec make_insert_sql(atom(), list()) -> list().
%% @doc Make insert sql sentence.
make_insert_sql(Table_name, Field_Value_List) ->
	Fun = fun({Field, Val}, Sum) ->	
				  Expr = io_lib:format("`~s`=~s",[Field, mysql:encode(Val)]),
				  S1 = if Sum == length(Field_Value_List) -> io_lib:format("~s",[Expr]);
						  true -> io_lib:format("~s,",[Expr])
					   end,
				  {S1, Sum+1}
		  end,
	{Vsql, _Count1} = lists:mapfoldl(Fun, 1, Field_Value_List),
	lists:concat(["insert into `", Table_name, "` set ",
				  lists:flatten(Vsql)
				 ]).

-spec make_replace_sql(atom(), list(), list()) -> list().
%% @doc Make replace sql sentence.
make_replace_sql(Table_name, FieldList, ValueList) ->
	L = make_conn_sql(FieldList, ValueList, []),
	lists:concat(["replace into `", Table_name, "` set ", L]).

-spec make_replace_sql(atom(), list()) -> list().
%% @doc Make replace sql sentence.
make_replace_sql(Table_name, Field_Value_List) ->
	Fun = fun({Field, Val}, Sum) ->
				  Expr = io_lib:format("`~s`=~s",[Field, mysql:encode(Val)]),
				  S1 = if Sum == length(Field_Value_List) -> io_lib:format("~s",[Expr]);
						  true -> io_lib:format("~s,",[Expr])
					   end,
				  {S1, Sum+1}
		  end,
	{Vsql, _Count1} = lists:mapfoldl(Fun, 1, Field_Value_List),
	lists:concat(["replace into `", Table_name, "` set ",
				  lists:flatten(Vsql)
				 ]).

-spec make_update_sql(atom(), list(), list(), term(), term()) -> list().
%% @doc Make update sql sentence.
make_update_sql(Table_name, Field, Data, Key, Value) ->
	L = make_conn_sql(Field, Data, []),
	lists:concat(["update `", Table_name, "` set ",L," where `",Key,"`='",tool:to_list(Value),"'"]).

%% @doc Make update sql sentence.
make_update_sql(Table_name, Field, Data, Where_List) ->
	L = make_conn_sql(Field, Data, []),
	WL = make_where_sql(Where_List),
	lists:concat(["update `", Table_name, "` set ",L,WL," "]).

-spec make_update_sql(atom(), list(), list()) -> list().
%% @doc Make update sql sentence.
make_update_sql(Table_name, Field_Value_List, Where_List) ->
	Fun = fun(Field_value, Sum) ->	
				  Expr = case Field_value of
							 {Field, Val, add} -> io_lib:format("`~s`=`~s`+~p", [Field, Field, Val]);
							 {Field, Val, sub} -> io_lib:format("`~s`=`~s`-~p", [Field, Field, Val]);						 
							 {Field, Val} -> io_lib:format("`~s`=~s",[Field, mysql:encode(Val)])
						 end,
				  S1 = if Sum == length(Field_Value_List) -> io_lib:format("~s",[Expr]);
						  true -> io_lib:format("~s,",[Expr])
					   end,
				  {S1, Sum+1}
		  end,
	{Vsql, _Count1} = lists:mapfoldl(Fun, 1, Field_Value_List),
	{Wsql, Count2} = get_where_sql(Where_List),
	WhereSql = 
		if Count2 > 1 -> lists:concat([" where ", lists:flatten(Wsql)]);
		   true -> ""
		end,
	lists:concat(["update `", Table_name, "` set ",
				  lists:flatten(Vsql), WhereSql, ""
				 ]).

-spec make_delete_sql(atom(), list()) -> list().
%% @doc Make delete sql sentence.
make_delete_sql(Table_name, Where_List) ->
	{Wsql, Count2} = get_where_sql(Where_List),
	WhereSql = 
		if Count2 > 1 -> lists:concat(["where ", lists:flatten(Wsql)]);
		   true -> ""
		end,
	lists:concat(["delete from `", Table_name, "` ", WhereSql]).

-spec make_select_sql(atom(), string(), list()) -> list().
%% @doc Make select sql sentence.
make_select_sql(Table_name, Fields_sql, Where_List) ->
	make_select_sql(Table_name, Fields_sql, Where_List, [], []).

-spec make_select_sql(atom(), string(), list(), list(), list()) -> list().
%% @doc Make select sql sentence.
make_select_sql(Table_name, Fields_sql, Where_List, Order_List, Limit_num) ->
	{Wsql, Count1} = get_where_sql(Where_List),
	WhereSql = 
		if Count1 > 1 -> lists:concat(["where ", lists:flatten(Wsql)]);
		   true -> ""
		end,
	{Osql, Count2} = get_order_sql(Order_List),
	OrderSql = 
		if Count2 > 1 -> lists:concat([" order by ", lists:flatten(Osql)]);
		   true -> ""
		end,
	LimitSql = case Limit_num of
				   [] -> "";
				   [Num] -> lists:concat([" limit ", Num])
			   end,
	lists:concat(["select ", Fields_sql," from `", Table_name, "` ", WhereSql, OrderSql, LimitSql]).

%% ====================================================================
%% Local Functions
%% ====================================================================
make_conn_sql([], _, L ) ->
	L ;
make_conn_sql(_, [], L ) ->
	L ;
make_conn_sql([F | T1], [D | T2], []) ->
	L  = ["`", tool:to_list(F), "`=",mysql:encode(D)],
	make_conn_sql(T1, T2, L);
make_conn_sql([F | T1], [D | T2], L) ->
	L1  = L ++ [",`", tool:to_list(F),"`=",mysql:encode(D)],
	make_conn_sql(T1, T2, L1).

make_where_sql(Where_List) ->
	{Wsql, Count2} = get_where_sql(Where_List),
	if Count2 > 1 -> lists:concat([" where ", lists:flatten(Wsql)]);
	   true -> ""
	end.

get_order_sql(Order_List) ->
	Fun = fun(Field_Order, Sum) ->	
				  Expr = 
					  case Field_Order of   
						  {Field, Order} ->
							  io_lib:format("~p ~p",[Field, Order]);
						  {Field} ->
							  io_lib:format("~p",[Field]);
						  _-> ""
					  end,
				  S1 = if Sum == length(Order_List) -> io_lib:format("~s",[Expr]);
						  true -> io_lib:format("~s,",[Expr])
					   end,
				  {S1, Sum+1}
		  end,
	lists:mapfoldl(Fun, 1, Order_List).

get_where_sql(Where_List) ->
	Fun = fun(Field_Operator_Val, Sum) ->	
				  [Expr, Or_And_1] = 
					  case Field_Operator_Val of   
						  {Field, Operator, Val, Or_And} ->
							  [io_lib:format("`~s`~s~s",[Field, Operator, mysql:encode(Val)]), Or_And];
						  {Field, Operator, Val} ->
							  [io_lib:format("`~s`~s~s",[Field, Operator, mysql:encode(Val)]), "and"];
						  {Field, Val} ->  
							  [io_lib:format("`~s`=~s",[Field, mysql:encode(Val)]), "and"];
						  _->
							  ["true", "and"]
					  end,
				  S1 = if Sum == length(Where_List) -> io_lib:format("~s",[Expr]);
						  true -> io_lib:format("~s ~s ",[Expr, Or_And_1])
					   end,
				  {S1, Sum+1}
		  end,
	lists:mapfoldl(Fun, 1, Where_List).



%% ====================================================================
%% Test
%% ====================================================================
-ifdef(TEST).
make_sql_test() ->
	Table_name = t_players,
	
	Sql_1 = "insert into `t_players` set `id`='1',`name`='test'",
	Make_1 = make_insert_sql(Table_name, [id, name], [1, "test"]),
	?assertEqual(Sql_1, lists:flatten(Make_1)),
	
	Sql_2 = "insert into `t_players` set `id`=1,`name`='test'",
	Make_2 = make_insert_sql(Table_name, [{id, 1}, {name, "test"}]),
	?assertEqual(Sql_2, lists:flatten(Make_2)),
	
	Sql_3 = "replace into `t_players` set `id`=1,`name`='test'",
	Make_3 = make_replace_sql(Table_name, [{id, 1}, {name, "test"}]),
	?assertEqual(Sql_3, lists:flatten(Make_3)),
	
	Sql_4 = "update `t_players` set `id`=`id`+1,`exp`=`exp`-1,`name`='test' where `name`='test'",
	Make_4 = make_update_sql(Table_name, [{id, 1, add}, {exp, 1, sub}, {name, "test"}], [{name, "=", "test"}]),
	?assertEqual(Sql_4, lists:flatten(Make_4)),
	
	Sql_5 = "update `t_players` set `id`='1',`name`='test' where `id`='1'",
	Make_5 = make_update_sql(Table_name, [id, name], [1, "test"], id, 1),
	?assertEqual(Sql_5, lists:flatten(Make_5)),
	
	Sql_6 = "delete from `t_players` where `id`>1 or `name`='test'",
	Make_6 = make_delete_sql(Table_name, [{id, ">", 1, "or"}, {name, "test"}]),
	?assertEqual(Sql_6, lists:flatten(Make_6)),
	
	Sql_7 = "select id, name from `t_players` where `id`>1 and true",
	Make_7 = make_select_sql(Table_name, "id, name", [{id, ">", 1}, {skip}]),
	?assertEqual(Sql_7, lists:flatten(Make_7)),
	
	Sql_8 = "select * from `t_players` where `name`='test' or `id`=1 order by id desc limit 1",
	Make_8 = make_select_sql(Table_name, "*", [{name, "=", "test", "or"}, {id, 1}], [{id, desc}], [1]),
	?assertEqual(Sql_8, lists:flatten(Make_8)),
	
	Sql_9 = "replace into `t_players` set `id`='1',`name`='test'",
	Make_9 = make_replace_sql(Table_name, [id, name], [1, "test"]),
	?assertEqual(Sql_9, lists:flatten(Make_9)),
	ok.
-endif.

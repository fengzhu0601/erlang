%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 生成操作模块函数, 生成的函数只会对本地的table进行查询。
%%%      并不会对全局DB table 查询.
%%%  TODO get nil call worker
%%% @end
%%%-------------------------------------------------------------------

-module(pangzi_gen_code).

-define(no_pangzi_behaviour, 1).
-include("../include/pangzi.hrl").

-export([gen_db_module/1]).

gen_db_module(Metas) ->
    {ok, Mod}=application:get_env(gen_mod),
                                                %io:format("DBNames:~p Mod:~p\n", [DBNames, Mod]),
    Format= smerl:new(Mod),

    %% Add func
    NewFormat=
        lists:foldl(
          fun(Func, AccIn) -> Func(AccIn, Metas) end,
          Format,
          [
           fun update/2,
           fun insert_new/2,
           fun update_counter/2,
           fun update_element/2,
           fun delete/2,
           fun lookup/2,
           fun lookup_element/2,
           fun load_data/2,
           fun info/2,
           fun load_tabs/2
           %%fun index_read/2
          ]),

    ok=smerl:to_src(NewFormat, atom_to_list(Mod) ++ ".erl"),
    smerl:compile(NewFormat, [{outdir, "ebin"}]).


                                                %fun(Func, AccIn) -> Func(AccIn, Metas) end,

%% TODO
%% @doc 生成index 查询信息
%%index_read(Format, Metas) ->
%%    Str=index_read__(Metas,
%%                     "index_read(T, _V, _Pos)-> "
%%                     "erlang:error({badarg, T})."),
%%    {ok, NewFormat} =smerl:add_func(Format, lists:flatten(Str)),
%%    NewFormat.
%%
%%index_read__([], Str) ->
%%    Str;
%%index_read__([M | Metas], Str) ->
%%    case M#db_table_meta.index of
%%        [] ->
%%            index_read__(Metas, Str);
%%        _ ->
%%            Table=M#db_table_meta.name,
%%            index_read__(Metas,
%%                         io_lib:format(
%%                           "index_read(~p, V, Pos) -> "
%%                           "mnesia:dirty_index_read(~p, V, Pos); ",
%%                           [Table, Table]) ++ Str)
%%    end.



%% @doc  一次load 多个tab 使用同一个key
load_tabs(Format, _Metas) ->
    Str= 
"load_tabs(Key, TabList) -> "
"lists:map(fun(Tab) -> "
                 " case dbcache:load_data(Tab, Key) of "
                 "    [] -> none; [N] -> N "
                 " end end, "
         " TabList). ",
         %%io:format("~s\n", [Str]),

          
    {ok, NewFormat} =smerl:add_func(Format, Str),
    NewFormat.

%% @doc 查看每个表的meta
info(Format, Metas) ->
    Str=info__(Metas,
               "info(T)-> "
               "erlang:error({badarg, T})."),
                                                %io:format("Str:~s\n", [Str]),
    {ok, NewFormat} =smerl:add_func(Format, lists:flatten(Str)),
    NewFormat.

info__([], Str) ->
    Str;

info__([M|Metas], Str) ->
    Table=M#db_table_meta.name,
    info__(Metas,
           io_lib:format(
             "info(~p)-> ~p ;",
             [Table, M#db_table_meta{init=undefined}]) ++
               Str).


%% TODO 现在只能插入单个的,不能是一个list
%% @doc add update/2 func.
%% update(xxx, Objec) ->
%%     true = ets:insert(xxx, Objecs),
%%     xxx ! {set, Objec}.
%%
update(Format, Metas) ->
    Str=update__(Metas,
                 "update(T,O)->"
                 %"io:format(\"insert bad arg T:~p\n\", [T]), "
                 "io:format(\"insert2 bad arg T:~p\n\", [lists:nth(1,T)]), "
                 %"io:format(\"insert bad arg T:~p O~p\n\",[T,O]),"
                 "erlang:error(badarg)."),
                                                %io:format("Str:~s\n", [Str]),
    {ok, NewFormat} =smerl:add_func(Format, lists:flatten(Str)),
    NewFormat.

update__([], Str) ->
    Str;
update__([M|Metas], Str) ->
    Table=M#db_table_meta.name,
    update__(Metas,
             io_lib:format(
               "update(~p, Obj) -> "
               "OldData = get(~p),"
               "if OldData =:= Obj ->"
               "pass;"
               "true ->"
                       "ets:insert(~p, Obj),"
                       "~p ! {set, Obj}, put(~p, Obj) "
                "end; "
               ,[Table, Table, Table, Table, Table]) ++
                 Str).


%% @doc add insert_new/2 func.
%% if options set all will generate
%% insert_new(xxx, Objecs) ->
%%     case ets:insert_new(xxx, Objecs) of
%%         true ->
%%             xxx ! {set_new, Objecs},
%%             true;
%%         false -> false
%%     end.
%%
insert_new(Format, Metas) ->
    Str=insert_new__(Metas,
                     "insert_new(T,O)-> "
                     "io:format(\"insert_new bad arg T:~p O~p~n\",[T,O]),"
                     "erlang:error(badarg)."),
    %%io:format("Str:~s\n", [Str]),
    {ok, NewFormat} =smerl:add_func(Format, lists:flatten(Str)),
    NewFormat.

insert_new__([], Str) ->
    Str;
insert_new__([M|Metas], Str) ->
    Table=M#db_table_meta.name,
    insert_new__(Metas,
                 io_lib:format(
                   "insert_new(~p, Obj) -> "
                   "  case ets:insert_new(~p, Obj) of "
                   "     true -> (~p ! {first_set, Obj}), true;"
                   "     false -> false "
                   "  end; "
                   ,[Table, Table, Table]) ++
                     Str).


%% @doc add update_counter
%% update_counter(DBTable, Key, UpdataOp) ->
%%     R = ets:update_counter(DBTable,Key,UpdataOp),
%%     ets:insert(change_mark, {Key}),
%%     R.
update_counter(Format, Metas) ->
    Str=update_counter__(Metas,
                         "update_counter(T,K,O) -> "
                         "io:format(\"update_counter bad arg T:~p K:~p, O~p~n\",[T,K,O]),"
                         "erlang:error(badarg)."),
    %%io:format("Str:~s\n", [Str]),
    {ok, NewFormat} =smerl:add_func(Format, lists:flatten(Str)),
    NewFormat.

update_counter__([], Str) ->
    Str;
update_counter__([M|Metas], Str) ->
    Table=M#db_table_meta.name,
    update_counter__(Metas,
                     io_lib:format(
                       "update_counter(~p, Key, Op)-> "
                       "R=ets:update_counter(~p, Key, Op),"
                       "~p ! {update_counter, Key, Op},"
                       "R; "
                       ,[Table, Table, Table]) ++
                         Str).


%% @doc add update_element func.
%% update_element(DBTable, Key, UpdataOp) ->
%%     R = ets:update_element(DBTable,Key,UpdataOp),
%%     ets:insert(change_mark, {Key,0}),
%%     R.
update_element(Format, Metas) ->
    Str=update_element__(Metas,
                         "update_element(T,K,O) -> "
                         "io:format(\"update_element bad arg T:~p K:~p, O~p~n\",[T,K,O]),"
                         "erlang:error(badarg)."),
    %%io:format("Str:~s\n", [Str]),
    {ok, NewFormat} =smerl:add_func(Format, lists:flatten(Str)),
    NewFormat.

%% TODO false call pid
update_element__([], Str) ->
    Str;
update_element__([M|Metas], Str) ->
    Table=M#db_table_meta.name,
    update_element__(Metas,
                     io_lib:format(
                       "update_element(~p, Key, Op)-> "
                       "case ets:update_element(~p, Key, Op) of "
                       "  true -> "
                       "      ~p ! {update_element, Key}, "
                       "      true; "
                       "  false ->"
                       "      false "
                       "  end; "
                       ,[Table, Table, Table]) ++
                         Str).

%% @doc add delete func.
%% delete_object(DBTable, Key) ->
%%     ets:delete(DBTable, Key),
%%     ets:insert(change_mark, {Key,-1}),
%%     true.
delete(Format, Metas) ->
    Str=delete_object__(Metas,
                        "delete(T,K) -> "
                        "io:format(\"delete/2 bad arg T:~p K:~p~n\",[T,K]),"
                        "erlang:error(badarg)."),
                                                %io:format("Str:~s\n", [Str]),
    {ok, NewFormat} =smerl:add_func(Format, lists:flatten(Str)),
    NewFormat.

delete_object__([], Str) ->
    Str;
delete_object__([M|Metas], Str) ->
    Table=M#db_table_meta.name,
    delete_object__(Metas,
                    io_lib:format(
                      "delete(~p, Key) -> "
                      "ets:delete(~p, Key),"
                      "~p ! {delete, Key}; "
                      ,[Table, Table, Table]) ++
                        Str).

%% %% TODO
%% %delete_object(DBTable, Key, Obj) ->
%%     %ets:delete_object(DBTable, Obj),
%%     %ets:insert(change_mark, {Key,-1}),
%%     %true.

%% @doc lookup func.
%% lookup(DBTable, Key) ->
%%   ets:lookup(DBTable, Key).
%%   ->[] | Obj
%%
%lookup([#db_table_meta{flush_interval=0}=M|Metas], Str) ->

lookup(Format, _Metas) ->
    Str=
        "lookup(T, Key) ->  "
        "case ets:lookup(T, Key) of "
        "    [] -> "
        "         List = mnesia:dirty_read(T, Key), "
        "         if List =/= [] -> "
        "                case ets:insert_new(T, List) of "
        "                  true -> "
        %"                    T ! {get, Key},"
        "                    List;"
        "                  false ->"
        "                    ets:lookup(T, Key)"
        "                 end;"
        "            true -> [] "
        "         end; "
        "    List -> "
        %"        T ! {get, Key},"
        "        List "
        "end.",
                                                %io:format("Str:~s\n", [Str]),
    {ok, NewFormat} =smerl:add_func(Format, lists:flatten(Str)),
    NewFormat.



%% @doc add lookup_element func.
%%  if can not find key throw badarg.
%% lookup_element(DBTable, Key, Pos) ->
%%   ets:lookup_element(DBTable, Key, Pos).
%%
%% the row is in cache
lookup_element(Format, _Metas) ->
    {ok, NewFormat} =smerl:add_func(Format,
                                    "lookup_element(T,Key,Pos)-> "
                                    "case ets:lookup(T, Key) of "
                                    "    [] -> "
                                    "         case mnesia:dirty_read(T, Key) of "
                                    "         [] -> throw(badarg); "
                                    "         [R] ->  "
                                    "              case ets:insert_new(T, R) of "
                                    "                true ->"
                                    %"                  T ! {get, Key},"
                                    "                  element(Pos, R);"
                                    "                false ->"
                                    "                   [O] = ets:lookup(T, Key), "
                                    "                   element(Pos, O) "
                                    "               end "
                                    "         end; "
                                    "    [R] -> "
                                    %"        T ! {get, Key},"
                                    "        element(Pos, R) "
                                    "end."),
    NewFormat.


%% @doc load db rom to est cache.
%% @return  listObjects
load_data(Format, _Metas) ->
    {ok, NewFormat} =smerl:add_func(Format,
                                    "load_data(T, Key) -> "
                                    "lookup(T, Key)."),
    NewFormat.

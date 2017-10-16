%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc sqlite配置,
%%%  1.目前只导出两个函数 insert/2 插入数据  like/2 模糊查询数据，目前默认查询出30条数据
%%%  2.数据库只能存在一个，写死在程序中，通过宏定义DATABASE_NAME定义数据库路径以及名称
%%%  3.如何新建表. a.通过宏定义ALL_TABLES，定义表信息,在应用启动时创建表. b.目前每一个表只能存在一个字段，被设置成主键
%%% @end
%%%-------------------------------------------------------------------
-module(esqlite_config).

-behaviour(gen_server).

-export
([
    start_link/0
    ,insert/2  %向sqlite数据库中插入数据
    ,like/2, like/3 %模糊查询
]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

%% @doc 定义数据库文件名称
-define(DATABASE_FILEPATH, "../Database/").
-define(DATABASE_NAME, "../Database/game.db").

%% @doc 定义该数据库中的所有表,目前每张表只能存在一个字段
-define(ALL_TABLES,
    [
        {player_tab, name, 20} %player_tab->表名 name->表字段 32->该字段长度
    ]).

-define(SQL_SELECT_LIMIT, 30).

-define(SQL_CREATE_TABLE(TabName, TabColumnName, VarcharSize),
        <<"CREATE TABLE `",TabName/binary, "` (`", TabColumnName/binary, "` VARCHAR(",VarcharSize/binary,") NOT NULL,PRIMARY KEY  (`",TabColumnName/binary,"`))">>).
-define(SQL_INSERT_DATA(TabName, Value),
        <<"INSERT INTO `",TabName/binary,"` VALUES ( '",Value/binary,"' );">>).

%% 目前默认只取出30条匹配的数据
-define(SQL_LIKE_DATA(TabName, TabColumnName, Value, Len),
        <<"SELECT * FROM `",TabName/binary,"` WHERE ",TabColumnName/binary," LIKE '%",Value/binary,"%'LIMIT 0, ",Len/binary,";">>).

-record(state, {conn}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    case filelib:is_dir(?DATABASE_FILEPATH) of
        false ->
            file:make_dir(?DATABASE_FILEPATH);
        true -> ok
    end,

    try esqlite3:open(?DATABASE_NAME) of
        {ok, Db} ->
            FunMap = fun( {TabName, TabColumnName, VarcharSize} ) ->
                TabNameBin = all_to_binary(TabName),
                TabColumnNameBin = all_to_binary(TabColumnName),
                VarcharSizeBin = all_to_binary(VarcharSize),
                Sql = ?SQL_CREATE_TABLE(TabNameBin, TabColumnNameBin, VarcharSizeBin),
                case esqlite3:exec(Sql, Db) of
                    ok -> ok;
                    {error, Other} ->
                        ErrStr = "table `"++atom_to_list(TabName)++"` already exists",
                        case Other of
                            {sqlite_error, ErrStr} -> ok;
                            Other -> io:format( "create sqlite table error:~p~n", [Other] )
                        end
                end
            end,
            lists:map( FunMap, ?ALL_TABLES ),
            {ok, #state{conn=Db}}
    catch
        _Catch:_Why ->
            io:format( "sqlite open database error:~p~n", [_Why] ),
            {ok, #state{}}
    end.

handle_call({like, Sql}, _From, State) ->
    Reply =
        try esqlite3:q( Sql, State#state.conn ) of
            QueryData -> QueryData
        catch
            _Catch:Why -> Why
        end,
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({insert, Sql}, State) ->
    catch esqlite3:exec( Sql, State#state.conn ),
    {noreply, State};

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, State) ->
    esqlite3:close( State#state.conn ),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

-spec insert( atom(), binary() ) -> {error, timeout, erlang:make_ref()}|ok.
insert(TabName, Value) ->
    TabNameBin = all_to_binary(TabName),
    ValueBin = all_to_binary(Value),
    Sql = ?SQL_INSERT_DATA( TabNameBin, ValueBin ),
    gen_server:cast(?SERVER, {insert, Sql}).

-spec like( atom(), Value ) -> {error, string()}|TupleList|{error, timeout, erlang:make_ref()} when Value :: string()|binary(), TupleList :: [tuple()].
like(TabName, Value) ->
    like( TabName, Value, ?SQL_SELECT_LIMIT ).

like( TabName, Value, Len ) ->
    case lists:keyfind( TabName, 1, ?ALL_TABLES ) of
        false -> {error, "no this table, tableName mast be atom"};
        {_, TabColumnName, _} ->
            TabNameBin = all_to_binary(TabName),
            TabColumnNameBin = all_to_binary(TabColumnName),
            ValueBin = all_to_binary(Value),
            LenBin = all_to_binary(Len),
            Sql = ?SQL_LIKE_DATA( TabNameBin, TabColumnNameBin, ValueBin, LenBin ),
            gen_server:call(?SERVER, {like, Sql})
    end.

all_to_binary( Binary ) when is_binary(Binary) -> Binary;
all_to_binary( Atom ) when is_atom(Atom) -> list_to_binary(atom_to_list( Atom ));
all_to_binary( Str ) when is_list(Str) -> list_to_binary( Str );
all_to_binary( Integer ) when is_integer(Integer) -> integer_to_binary( Integer );
all_to_binary( _Other ) -> <<"arg_error">>.
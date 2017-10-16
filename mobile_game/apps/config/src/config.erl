%%coding: utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc config behaviour 实现
%%%
%%% 为cofnig behaviour 的模块提供配置的加载，解析和验证服务。
%%% 并自动生成查询函数.
%%%
%%% -behaviour(config).
%%% -export([load_config_meta/0]).
%%%
%%% 自动导出的三个函数
%%% 比如配置record 的名字是XX. 就会导出
%%% 1. `lookup_XX(Key)' -> none | Config.
%%% 2. `lookup_XX'(K, Pos::integer()) -> none | term().
%%% 3. `is_exist_XX(K)' -> boolean().
%%% 
%%% TODO
%%% 4. 对于指定orderd_sets 类型还会导出
%%%     `first_XX()' -> first key
%%%     `last_XX()' -> last key
%%%
%%  Usage:
%%   e.g.
%%   -module(guild_cfg).
%%   -incude("config.hrl").
%%   -behaviour(config).
%%
%%   -export([load_config_meta/0
%%            ]).
%%
%%   -record(guild_cfg, {id,
%%                       total=100,
%%                       daily_prize}).
%%
%%   -record(guild_prize, {id, prize}).
%%
%%   load_config_meta() ->
%%       [
%%        #config_meta{record=#?MODULE{},
%%                     keypos=1,
%%                     verify=fun verify/1},
%%        #config_meta{record=#guild_prize{},
%%                     keypos=2,
%%                     file= "xx.cfg"
%%                     verify=fun verify_prize/1}
%%       ].
%%
%%
%%   verify(#?MODULE{id=_Id, total=_T, daily_prize=_P}) ->
%%       %io:format("guild verify ~w ~w ~ts~n", [Id, T, P]).
%%       ok.
%%
%%   verify_prize(_Cfg) ->
%%       %io:format("guild_prize:~p~n", [Cfg]).
%%       ok.
%%
%%
%% config 文件格式，
%% 第一行是中文注释
%% 第二行是record
%% 使用table 分割fields
%%
%%ID     名字    消耗的物品id=个数       元宝    金券    金币
%%id     client_name     goods   unbinded_treasure       binded_treasure money
%%201    喇叭

%%% @end
%%%-------------------------------------------------------------------


-module(config).
-behaviour(gen_server).

%% TODO reload

%%=======================================================================
%% Internal functions
%%=======================================================================
-define(no_config_transform, 1).
-include("config.hrl").
-include_lib("common/include/com_log.hrl").
-include_lib("common/include/com_define.hrl").
-include_lib("common/include/eunit_ext.hrl").

%% Module Interface
-export([start_link/0]).
%% gen_server callbacks
-export([init/1,handle_call/3,handle_cast/2,handle_info/2,terminate/2,code_change/3]).



%% @doc config_lib behaviour 需要实现的就口，返会config_meta
-callback load_config_meta() -> [config_meta()].

-export([parse_transform/2]).

-type config_meta() :: #config_meta{}.
%% @doc 配置验证函数类型
-type config_verify_fun() :: fun((Cfg::term()) -> ok) | 
                             fun((FileId::integer(), Cfg::term()) -> ok). %% file = {Dir, ".txt}

-export_type([config_meta/0,
              config_verify_fun/0]).

%% config 文件格式，
%% 第一行是中文注释
%% 第二行是record
%% 使用table 分割fields
%%%
%%ID     名字    消耗的物品id=个数       元宝    金券    金币
%%id     client_name     goods   unbinded_treasure       binded_treasure money
%%201    喇叭

%% [{filed,pos}]
-define(pd_cfg_field, pd_cfg_field).
%% integer 配置文件每一行需要的field 数量
-define(pd_cfg_field_size, pd_cfg_field_size).
%% 每个field 的所有值
-define(pd_all, pd_all). %% row{ gb_sets
-define(pd_file_name, pd_file_name).
-define(pd_namespace_key, pd_namespace_key).


%%
%-record(inter_meta, {
          %record,
          %name,
          %fields,
          %keypos,
          %is_compile,
          %all
         %}).

-define(CONFIG_PATH, "./data/").
-define(config_temp_ets, config_temp_ets).


%%
%%   1. 加载ets
%%   2. 生成func
%%   3. 现在的配置的列顺序必须和record的定义相同，
%%
%%% TODO 运行期对可以成功, 函数的配置生成对应函数
%% 两种得到配置的方法， 1，访问ets，灵活
%%                    2. 动态生成配置函数， 比ets快，但是需要大量编译时间，
%%

%% TODO update_config_data
%% @doc load all config data
%% TODO config is a process


%% @doc Starts the server
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


%% @spec handle_cast(Msg, State) -> {noreply, State} |
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'ETS-TRANSFER', _Tid, _FromPid, ok}, State) ->
    {noreply, State};

handle_info(_Msg, State) ->
    {noreply, State}.


%% @spec terminate(Reason, State) -> no_return()
%%       Reason = normal | shutdown | {shutdown, term()} | term()
terminate(?normal, _State) ->
    ok;
terminate(R, _State) ->
    ?ERROR_LOG("~p Crash with ~p", [?pname(), R]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

get_record_name([{record_field, _, {atom, _, record}, {record, _, Name, _}} | _]) ->
    Name;
get_record_name([_ | Other]) ->
    get_record_name(Other).

%%cons_fold({cons, _L, H, Tail}, Acc) ->
cons_fold({nil,_}, _) ->
    [];
cons_fold({cons, _L, {record, _, _, FieldList}, Tail}, Acc) ->
    case Tail of
        {nil, _} ->
            [get_record_name(FieldList) | Acc];
        _ ->
            cons_fold(Tail, [get_record_name(FieldList) | Acc])
    end.

get_config_records(Meta) ->
    case smerl:get_func(Meta, load_config_meta, 0) of
        {ok, Fn} ->
            {function, _, load_config_meta, _, [Clause]} = Fn,
            {clause, _, _, _, [CfgMetaCons]} = Clause,
            cons_fold(CfgMetaCons, []);
        _E ->
            ?ERROR_LOG("~p can not find load_config_meta func ~p", [smerl:get_module(Meta), _E]),
            %%?DEBUG_LOG("mate ~p", [smerl:get_all_func(Meta)]),
            exit(bag)
    end.

%remove_verify(MetaCons) ->
    %io:format("FN ~p", [MetaCons]),

    %ok.

%%% asf -> term
%get_config_metas(Meta) ->
    %{ok, Fn} = smerl:get_func(Meta, load_config_meta, 0),
    %{function, _, load_config_meta, _, [Clause]} = Fn,
    %{clause, _, _, _, [CfgMetaCons]} = Clause,

    %%% 1 remove verify asf
    %remove_verify(CfgMetaCons),

    %ok.


parse_transform(Forms, _Opts) ->
    {ok, Meta} = smerl:new_from_forms(Forms),
%%    io:format("==Meta:======~p~n",[Meta]),
    %get_config_metas(Meta),
    case get_config_records(Meta) of
        [] ->
            error_logger:format("config ~p not load meta", [smerl:get_module(Meta)]),
            Forms;
        CR ->
            io:format("all config records ~p ~n", [CR]),
            NewMeta =  % Add func
            lists:foldl(
              fun(R, AccIn) ->
                      GetCfg=
                      io_lib:format(
                        "lookup_~p(K)->"
                        "case ets:lookup(~p, K) of"
                        " [] -> none;"
                        " [{_,Cfg}] -> Cfg end.", [R,R]),
                      {ok, Meta1} =smerl:add_func(AccIn, lists:flatten(GetCfg)),

                      IsExite=
                      io_lib:format("is_exist_~p(K)-> ets:member(~p, K) .", [R,R]),
                      {ok, Meta2} =smerl:add_func(Meta1, lists:flatten(IsExite)),

                      GetElement=
                      io_lib:format(
                        "lookup_~p(Key, Pos)->"
                        "case ets:lookup(~p,Key) of"
                        " [] -> none;"
                        " [{_,Cfg}] -> element(Pos, Cfg) end.", [R,R]),
                      {ok, Meta3} =smerl:add_func(Meta2, lists:flatten(GetElement)),

                      All =
                      io_lib:format(
                        "lookup_all_~p(Pos)->"
                        "case ets:lookup(~p, {'$all', Pos}) of"
                        " [] -> none;"
                        " [{_,All}] -> All end.", [R, R]),
                      {ok, Meta4} =smerl:add_func(Meta3, lists:flatten(All)),

                      Group = 
                      io_lib:format(
                        "lookup_group_~p(Pos, Id)->"
                        "case ets:lookup(~p, {{'$group', Pos}, Id}) of"
                        " [] -> none;"
                        " [{_,All}] -> All end.", [R, R]),
                      {ok, Meta5} =smerl:add_func(Meta4, lists:flatten(Group)),

                      Namespace =
                      io_lib:format(
                        "lookup_file_~p(FileId)->"
                        "case ets:lookup(~p, {'$file', FileId}) of"
                        " [] -> none;"
                        " [{_,Keys}] -> Keys end.", [R, R]),
                      {ok, MetaOk} =smerl:add_func(Meta5, lists:flatten(Namespace)),

                      MetaOk end,
              Meta,
              CR),

            smerl:to_forms(NewMeta)
    end.



%% ====================================================================
%% Internal functions
%% ====================================================================
init(_) ->
    com_process:init_name(<<"config">>),
    com_process:init_type(?MODULE),

    ?config_temp_ets = ets:new(?config_temp_ets, [bag, public, named_table]),
    Modules =
        com_module:get_all_behaviour_mod("./ebin", ?config_behavior),
                                                %?DEBUG_LOG("config modules ~p ", [Modules]),
    get_all_config_meta_info(Modules),
    get_all_config_data(),
    rewrite_all_config_data(),

    verify_all_config_data(),

    build_extren_info(),

    compile_to_beam(),

    {ok, ok}.

check_is_repeat_meta(Meta) ->
    TableName = get_table_name(Meta),
    case gb_sets:is_element(TableName, get(pd_tables)) of
        false ->
            put(pd_tables, gb_sets:add(TableName, get(pd_tables)));
        true ->
            ?ERROR_LOG("重复config meta ~p", [Meta]),
            exit(bad)
    end.


-spec get_all_config_meta_info([atom()]) -> ok.
get_all_config_meta_info(Modules) ->
    put(pd_tables, gb_sets:empty()),
    lists:foreach(
      fun(Mod) ->
              Metas = Mod:load_config_meta(),
              lists:foreach(
                fun(Meta) ->
                        check_is_repeat_meta(Meta),
                        ets:insert(?config_temp_ets, Meta)
                end,
                Metas)
      end,
      Modules),
    ok.


get_ns_info(#config_meta{file={_,_}}, Key, _, Acc) ->
    FileId = element(1, Key),
    dict:append(FileId, Key, Acc);
get_ns_info(_, _, _, Acc) ->
    Acc.
insert_ns_info(TableName, Info) ->
    lists:foreach(fun({FileId, Keys}) ->
                          Row = {{'$file', FileId}, Keys},
                          case ets:insert_new(TableName, Row) of
                              true -> ok;
                              E ->
                                  ?ERROR_LOG("~p insert file ~p ~p", [TableName, FileId, E])
                          end
                  end,
                  dict:to_list(Info)).

get_all_info(#config_meta{all=All}, _, Row, Acc) ->
    %%io:format("all load row ~p",[Row]),
    com_record:foldl_index(
      fun(Index, E, Acc2) ->
              case lists:member(Index, All) of
                  true ->
                      %?Assert2(tuple_size(Acc) >= Index, "in ~pAcc ~p", [Index, Acc]),
                      %%io:format("E ~p ~p~n", [E, TableName]),
                      NE = gb_sets:add(E, element(Index, Acc2)),
                      setelement(Index, Acc2, NE);
                  false ->
                      Acc2
              end
      end,
      Acc,
      Row,
      2).

insert_all_info(TableName, All, Info) ->
    com_record:foreach(fun(Index, Sets) ->
                               case lists:member(Index, All) of
                                   true ->
                                       Row = {{'$all', Index},gb_sets:to_list(Sets)},
                                       %% Keypos
                                       case ets:insert_new(TableName,Row) of
                                           true -> ok;
                                           E ->
                                               ?ERROR_LOG("~p insert all index ~p ~p", [TableName, Index, E])
                                       end;
                                   false ->
                                       ok
                               end
                       end,
                       Info),
    ok.

get_group_info(#config_meta{groups=[]}, _, _, Acc) ->
    Acc;
get_group_info(#config_meta{groups=Groups}, Key, Row, Acc)->
    com_record:foldl_index(
      fun(Index, E, Acc2) ->
              case lists:member(Index, Groups) of
                  true ->
                      %?Assert2(tuple_size(Acc) >= Index, "in ~pAcc ~p", [Index, Acc]),
                      %%io:format("E ~p ~p~n", [E, TableName]),
                      NE = dict:append(E, Key, element(Index, Acc2)),
                      setelement(Index, Acc2, NE);
                  false ->
                      Acc2
              end
      end,
      Acc,
      Row,
      2).

insert_group_info(TableName, Groups, Info) ->
    com_record:foreach(fun(Index, Dict) ->
                               case is_list(Groups) andalso lists:member(Index, Groups) of
                                   true ->
                                       lists:foreach(fun({Key, V}) ->
                                                             ?assert(is_integer(Key)),
                                                             Row = {{{'$group', Index}, Key}, V},
                                                             %% Keypos
                                                             case ets:insert_new(TableName,Row) of
                                                                 true -> ok;
                                                                 E ->
                                                                     ?ERROR_LOG("~p insert group index ~p ~p", [TableName, Index, E])
                                                             end
                                                     end,
                                                     dict:to_list(Dict));
                                   false ->
                                       ok
                               end
                       end,
                       Info),
%%      ok;
%% %%
%%  insert_group_info(TableName, Groups, Info) ->
%%       ?ERROR_LOG("insert_group_info Group ~p Info ~p",[Groups,Info]),
    ok.


build_extren_info() ->
    Metas = ets:lookup(?config_temp_ets, config_meta),
    lists:foreach(fun(#config_meta{record=R, all=All, groups=Groups}=Meta) ->
                          TableName = get_table_name(Meta),

                          {AllInfo, NSInfo, GroupInfo}=
                          ets:foldl(fun({Key, Row}, {AllAcc, NSAcc, GroupInfo}) -> 
                                            {get_all_info(Meta, Key, Row, AllAcc),
                                             get_ns_info(Meta, Key, Row, NSAcc),
                                             get_group_info(Meta, Key, Row, GroupInfo)
                                            }
                                    end,
                                    {erlang:make_tuple(tuple_size(R), gb_sets:empty()),
                                     dict:new(),
                                     erlang:make_tuple(tuple_size(R), dict:new())
                                    },
                                    TableName),

                          %% insert to ets
                          insert_all_info(TableName, All, AllInfo),
                          insert_ns_info(TableName, NSInfo),
                          insert_group_info(TableName, Groups, GroupInfo)
                  end,
                  Metas),
    ok.


rewrite_all_config_data() ->
    ?DEBUG_LOG("config rwrite data"),

    Metas = ets:lookup(?config_temp_ets, config_meta),
    lists:foreach(fun(#config_meta{rewrite=?undefined}) -> ok;
                     (#config_meta{record=_Record, rewrite=Fun, keypos=KeyPos}=Meta) ->

                          %%?DEBUG_LOG("config rwrite data ~p", [_Record]),
                          TableName = get_table_name(Meta),
                          case catch Fun(Meta) of
                              {'EXIT', E} ->
                                  ?ERROR_LOG("rewrite record ~p ~p rewriteFn:~p",[E,_Record,Fun]),
                                  sleep(),
                                  exit(err);
                              %%TODO 检测对key值的修改
                              NewCfgList ->
                                  lists:foreach(fun(NewCfg) ->
                                                        %%?DEBUG_LOG("rewrite config key ~p ", [fetch_key(KeyPos, NewCfg)]),
                                                        ets:insert(TableName, {fetch_key(KeyPos, NewCfg), NewCfg})
                                                        %%?DEBUG_LOG("rewrite ok")
                                                end,
                                                NewCfgList)
                          end
                  end,
                  Metas),
    ok.


get_all_config_data() ->
    %% get all
    Metas = ets:lookup(?config_temp_ets, config_meta),
    get_all_config_data__(Metas).


get_all_config_data__([]) -> ok;
get_all_config_data__([M|Other]) ->
    case catch get_config_data(M) of
        {'EXIT', E} ->
            ?ERROR_LOG("load ~p data ~p error ", [M, E]),
            sleep();
        _ -> ok
    end,
    get_all_config_data__(Other).

%% map
    %%Returns =
        %%map_reduce:do(fun get_config_data/1, Metas),

    %%case lists:filter(fun(ok) -> false;
                         %%(_) -> true end,
                      %%Returns)
    %%of
        %%[] -> ok;
        %%_X ->
            %%?ERROR_LOG("加载配置出现错误, 请检查配置 ~p", [_X]),
            %%sleep()
    %%end,

-spec get_config_data(#config_meta{}) -> ok .
get_config_data(#config_meta{file=none} = Meta) ->
    ConfigPid = erlang:whereis(?MODULE),
    TableName = get_table_name(Meta),
    %% ets {Key, Config}
    %%     {{'$all', Pos,} All}}
    case ets:new(TableName,
                        [?named_table,
                         ?protected,
                         {?keypos, 1}, 
                         {?read_concurrency, ?true},
                         {heir, ConfigPid, ok}])
    of
        TableName -> ok;
        Err ->
            ?ERROR_LOG("create ets ~p error ~p", [TableName, Err]),
            exit(Err)
    end,

    ok;

get_config_data(#config_meta{file=File, fields=Fields} = Meta) when is_list(File)->
    ?INFO_LOG("loading config file~p ... ", [File]),
    ConfigPath =
        case application:get_env(config_file_path) of
            {ok, Path} -> Path;
            _ -> ?CONFIG_PATH
        end,
    FullPath = ConfigPath ++File,
    put(?pd_file_name, File),

    case is_utf8_encode(FullPath) of
        ?true -> ok;
        E ->
            ?ERROR_LOG("File ~p not utf8 encoding ~p", [File, E])
    end,

    case file:open(FullPath, [read, raw, binary, {read_ahead, 1024 * 128}]) of
        {error, Reason} ->
            ?ERROR_LOG("Open file ~ts error:~p~n", [FullPath, Reason]),
            erlang:exit({error, FullPath, Reason});
        {ok, FD} ->
            %% create ets and set heir processs in a temp process.
            ConfigPid = erlang:whereis(?MODULE),

            TableName = get_table_name(Meta),
            TableName
                = ets:new(TableName,
                          [?named_table,
                           ?ordered_set,
                           ?protected,
                           {?keypos, 1},
                           {?read_concurrency, ?true},
                           {heir, ConfigPid, ok}]),

            %% pos <-> name
            lists:foldl(fun(F, Pos) ->
                                F2 = erlang:atom_to_binary(F, ?latin1),
                                put(F2, Pos),
                                put(Pos, F2),
                                Pos+1
                        end, 2, Fields),


            ok = com_file:read_line_foreach(fun insert_record_to_ets/3, FD, Meta),

            ok = file:close(FD)
            %%?INFO_LOG("loading config file~p over", [File])
    end;

get_config_data(#config_meta{file={DirPath, FileSuffix}, fields=Fields} = Meta) ->
    ?INFO_LOG("loading config ~p ~p files ... ", [DirPath, FileSuffix]),

    ConfigPath =
        case application:get_env(config_file_path) of
            {ok, Path} -> Path;
            _ -> ?CONFIG_PATH
        end,

    FullDirPath = ConfigPath ++ DirPath,
    case com_file:dir_match_suffix_files(FullDirPath, FileSuffix) of
        {error, R} ->
            ?ERROR_LOG("open dir ~p ~p", [FullDirPath, R]),
            erlang:exit({error, FullDirPath, R});
        AllFiles ->
            %% create ets and set heir processs in a temp process.
            ConfigPid = erlang:whereis(?MODULE),

            TableName = get_table_name(Meta),
            TableName = ets:new(TableName,
                                [?named_table,
                                 ?ordered_set,
                                 ?protected,
                                 {?keypos, 1},
                                 {?read_concurrency, ?true},
                                 {heir, ConfigPid, ok}]),
            %% pos <-> name
            lists:foldl(fun(F, Pos) ->
                                F2 = erlang:atom_to_binary(F, ?latin1),
                                put(F2, Pos),
                                put(Pos, F2),
                                Pos+1
                        end, 2, Fields),


            lists:foreach(fun(FileName) ->
                                  FullPath = FullDirPath ++ "/" ++ FileName,
                                  [_SpaceKey] = binary:split(?l2b(FileName), [?l2b(FileSuffix)], [trim]),
                                  %%?DEBUG_LOG("spaceKey ~p", [_SpaceKey]),
                                  SpaceKey = ?b2i(_SpaceKey),

                                  put(?pd_namespace_key, SpaceKey),
                                  put(?pd_file_name, FullPath),

                                  case is_utf8_encode(FullPath) of
                                      ?true -> ok;
                                      E ->
                                          ?ERROR_LOG("File ~p not utf8 encoding ~p", [FullPath, E])
                                  end,

                                  case file:open(FullPath, [read, raw, binary, {read_ahead, 1024 * 128}]) of
                                      {error, Reason} ->
                                          ?ERROR_LOG("Open file ~ts error:~p~n", [FullPath, Reason]),
                                          erlang:exit({error, FullPath, Reason});
                                      {ok, FD} ->
                                          ok = com_file:read_line_foreach(fun insert_record_to_ets/3, FD, Meta),
                                          erase(?pd_namespace_key),

                                          ok = file:close(FD)
                                          %%?INFO_LOG("loading config file~p over", [File])
                                  end
                          end,
                          AllFiles)
    end;

get_config_data(Meta) ->
    ?ERROR_LOG("无效的配置信息 ~p", [Meta]),
    exit(bad).


insert_record_to_ets(1, _Line, _Meta) -> ok; %%comment
insert_record_to_ets(2, OLine, Meta) ->
    [Line] = binary:split(OLine, [<<$\n>>, <<$\r,$\n>>], [global, trim]),
    Fields = binary:split(Line, [<<$\t>>], [global]),
    case lists:any(fun(_Field) ->
                           _Field =:= <<>>
                   end,
                   Fields)
    of
        true ->
            ?ERROR_LOG("~p fields ~p 行有空TAB,请检查", [get(?pd_file_name), Fields]),
            exit(bad);
        _ ->
            ok
    end,

    %%?DEBUG_LOG("Fields ~p ~n", [Fields]),

    lists:foreach(fun(Field) ->
                          case lists:member(erlang:atom_to_binary(Field, ?latin1), Fields) of
                              false ->
                                  ?ERROR_LOG("配置文件~p 没有record ~p 中的~p 字段", [Meta#config_meta.file, com_record:get_name(Meta#config_meta.record), Field]),
                                  erlang:exit("bad cfg");
                              true -> ok
                          end
                  end,
                  Meta#config_meta.fields),

    {MaxPos, UsedFields} =
        lists:foldl(fun(<<"client_", _/binary>>, {Pos, AccIn}) ->
                            {Pos+1, AccIn};
                       (Field, {Pos, AccIn}) ->
                            case erlang:get(Field) of
                                ?undefined ->
                                    ?ERROR_LOG("record ~p 没有定义配置文件的:~p 字段", [Meta#config_meta.record, Field]),
                                    erlang:exit("bad cfg");
                                _ ->
                                    {Pos+1, AccIn ++ [{Field, Pos}]}
                            end
                    end,
                    {1, []},
                    Fields),
    erlang:put(?pd_cfg_field, UsedFields),
    erlang:put(?pd_cfg_field_size, MaxPos-1),
    %erlang:put(?pd_all, erlang:make_tuple(tuple_size(Meta#config_meta.record), gb_sets:empty())),
    ok;

insert_record_to_ets(_LineNum, <<>>, Meta) ->
    ?ERROR_LOG("配置文件 ~p :~p 空白行 ", [Meta#config_meta.file, _LineNum]),
    erlang:exit(bad);
insert_record_to_ets(_LineNum, <<$\n>>, Meta) ->
    ?ERROR_LOG("配置文件 ~p :~p 空白行 ", [Meta#config_meta.file, _LineNum]),
    erlang:exit(bad);
insert_record_to_ets(_LineNum, <<$\r,$\n>>, Meta) ->
    ?ERROR_LOG("配置文件 ~p :~p 空白行 ", [Meta#config_meta.file, _LineNum]),
    erlang:exit(bad);
insert_record_to_ets(_LineNum, OLine, Meta) ->
    [Line] = binary:split(OLine, [<<$\n>>, <<$\r,$\n>>], [global, trim]),
    DefRow = Meta#config_meta.record,

    CfgRow__ = binary:split(Line, [<<$\t>>], [global]),
    FieldSize =  erlang:get(?pd_cfg_field_size),

    CfgRow =
        case erlang:length(CfgRow__) of
            FieldSize ->  CfgRow__;
            Have when Have =< FieldSize ->
                NilFieldCount = FieldSize - Have,
                %%?DEBUG_LOG("xxx totoal~p have ~p", [FieldSize, Have]),
                CfgRow__ ++ lists:duplicate(NilFieldCount, <<>>);
            _ ->
                ?ERROR_LOG("~p : ~p 配置格式有无效有多余fields ~p", [get(?pd_file_name), _LineNum, CfgRow__]),
                erlang:exit(bad)
        end,

    Row =
        lists:foldl(fun({Field, CfgRowPos}, AccIn) ->
                            DefRowPos = erlang:get(Field),
                            if DefRowPos =:= ?undefined ->
                                   ?ERROR_LOG("配置文件 field ~p undefined ~p:~p", [Meta#config_meta.file, Field, _LineNum]),
                                   exit(error);
                               true ->
                                   ok
                            end,

                            case catch lists:nth(CfgRowPos, CfgRow) of
                                <<>> ->
                                    AccIn;
                                Bin when erlang:is_binary(Bin) ->
                                    %% TODO 可以给每个ｆｉｌｅｄ　提供一个自定义的解析函数回调
                                    case com_util:binary2term(Bin) of
                                        {error, R} ->
                                            ?ERROR_LOG("read config file [~p:~p] parase ~p error~p",
                                                       [Meta#config_meta.file, _LineNum, Bin, R]),
                                            erlang:exit(bad);
                                        Term ->
                                            case tuple_size(AccIn) >= DefRowPos of
                                                false->
                                                    erlang:exit({tuple_size_out, DefRowPos, AccIn, Term});
                                                true ->
                                                    erlang:setelement(DefRowPos, AccIn, Term)
                                            end
                                    end;
                                Err ->
                                    ?ERROR_LOG("read config file [~p:~p] field:~p pos:~p row~p Crash ~p",
                                               [Meta#config_meta.file, _LineNum, Field, CfgRowPos, CfgRow, Err]),
                                    erlang:exit(bad)

                            end
                    end,
                    DefRow,
                    erlang:get(?pd_cfg_field)),

    Table =
        case Meta#config_meta.name of
            ?undefined ->
                com_record:get_name(DefRow);
            N ->
                N
        end,

    %% fetch key
    Key = fetch_key(Meta#config_meta.keypos, Row),

    case ets:insert_new(Table, {Key,Row}) of
        true -> ok;
        _ ->
            ?ERROR_LOG("配置文件 ~p 主键~p重复", [Meta#config_meta.file, erlang:element(Meta#config_meta.keypos, Row)]),
            exit(bag)
    end,
    ok.


verify_all_config_data() ->
    ?DEBUG_LOG("start config verify"),
    Metas = ets:lookup(?config_temp_ets, config_meta),

    lists:foreach(
      fun(#config_meta{verify=Verify, name=Name, file=File, record=Record}) ->
              Table =
                  case Name of
                      ?undefined ->
                          com_record:get_name(Record);
                      N ->
                          N
                  end,
                  com_ets:foreach(fun({Key, R}) ->
                                          case File of
                                              {_, _} ->
                                                  FileId = element(1, Key),
                                                  case catch Verify(FileId, R) of
                                                      {'EXIT', E} ->
                                                          ?ERROR_LOG("配置验证错误 name ~p \nverifyFn~p  ~p ~p row:~p", [element(1, Record), Verify, Name, E, R]),
                                                          sleep();
                                                      _ ->
                                                          ok
                                                  end;
                                              _ ->
                                                  case catch Verify(R) of
                                                      {'EXIT', E} ->
                                                          ?ERROR_LOG("配置验证错误 name ~p \nverifyFn~p  ~p ~p row:~p", [element(1, Record), Verify, Name, E, R]),
                                                          sleep();
                                                      _ ->
                                                          ok
                                                  end
                                          end
                                  end, Table) 
      end,
      lists:keysort(#config_meta.name, Metas)),

    %Returns =
    %map_reduce:do(
    %fun(#config_meta{verify=Verify, record=Record}) ->
    %RecordName = com_record:get_name(Record),
    %%?DEBUG_LOG("verify ~p",[RecordName]),
    %com_ets:foreach(Verify, RecordName),
    %?AssertNot2(com_ets:is_empty(RecordName), "Error config ets ~p is empty \n", [RecordName])
    %end,
    %Metas),

    %case lists:filter(fun({error,_,_}) -> true;
    %(ok) -> false end,
    %Returns)
    %of
    %[] -> ok;
    %Errors ->
    %?ERROR_LOG("配置verify not pass ~p", [Errors])
    %end,
    ok.


sleep() ->
    case os:type() of
        {unix, _} ->
            erlang:halt();
        {win32, _} ->
            timer:sleep(100000000)
    end.

is_utf8_encode(FullFile) ->
    case os:type() of
        {unix, _} ->
            case os:cmd("file --mime-encoding -b " ++ FullFile) of
                "utf-8\n" -> 
                    true;
                "iso-8859-1\n" ->
                    true;
                "us-ascii\n" ->
                    true;
                E ->
                    E
            end;
        _ -> true
    end.


get_table_name(Meta) ->
    case Meta#config_meta.name of
        ?undefined ->
            com_record:get_name(Meta#config_meta.record);
        Name -> Name
    end.

compile_to_beam() ->
    Metas = ets:lookup(?config_temp_ets, config_meta),
%%    io:format("Verify :~p~n", [Metas]),
    %% md5
    %%map_reduce:do(
    lists:foreach(
        fun(#config_meta{keypos=Key, is_compile=true, record=R}=Meta) ->
            RecordName = com_record:get_name(R),
            TableName = get_table_name(Meta),
            ModName = atom_to_list(TableName) ++ "_data",

            File =
                lists:foldl(
                    fun(Row, Acc) ->
                        Id = element(Key-1, Row),
                        ?DEBUG_LOG("Row:~p~n",[Row]),
                        ?DEBUG_LOG("Key:~p~n",[Key]),
                        Fa = lists:flatten(io_lib:format("lookup_~p(~w) -> ~w;\n", [RecordName, Id, Row])),
                        %%io:format("Fa ~p~n", [Fa]),
                        <<Acc/binary, (list_to_binary(Fa))/binary>>
                    end,
                    <<>>,
                    lists:keysort(Key, ets:tab2list(TableName))),

            Head = lists:flatten(io_lib:format("-module(~s).~n~n-export([lookup_~p/1]).~n~n", [ModName, RecordName])),
            Unmatch = lists:flatten(io_lib:format("lookup_~p(_) -> none.\n", [RecordName])),
            %%io:format("Head ~p Unmatch ~p~n", [Head, Unmatch]),

            Dir = "edata/",
            FileName = Dir ++ ModName ++ ".erl",
            ?DEBUG_LOG("FileName:~p~n", [FileName]),
            ?DEBUG_LOG("pwd:~p~n", [file:get_cwd()]),

            case file:write_file(FileName,
                <<(list_to_binary(Head))/binary,
                    File/binary,
                    (list_to_binary(Unmatch))/binary
                >>)
            of
                ok ->
                    io:format("=======:~p",[FileName]),
                    compile:file(FileName, [{outdir, "./_build/default/lib/slot_server/ebin"}]),
                    ok;
                E ->
                    io:format("write ~p err ~p", [FileName, E])
            end;
            (_) ->
                ok
        end,
        Metas),

    ok.

%% 对于一个keypos 就是本身， 对于多个，key则是{pos1, pos2}
fetch_key(KeyPos, Row) when is_list(KeyPos) ->
    SpaceKey=
    case get(?pd_namespace_key) of
        ?undefined ->
            {};
        Key ->
            {Key}
    end,
    lists:foldl(fun(Pos, Acc) ->
                        erlang:append_element(Acc, element(Pos, Row))
                end,
                SpaceKey,
                KeyPos);

fetch_key(KeyPos, Row) when is_integer(KeyPos) ->
    case get(?pd_namespace_key) of
        ?undefined ->
            element(KeyPos, Row);
        Key ->
            {Key, element(KeyPos, Row)}
    end.

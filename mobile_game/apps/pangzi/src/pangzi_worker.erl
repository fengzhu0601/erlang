%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 负责同步数据回写脏数据
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(pangzi_worker).

-behaviour(gen_server).

-include_lib("common/include/com_define.hrl").
-include_lib("common/include/com_log.hrl").
-include_lib("common/include/eunit_ext.hrl").

-define(no_pangzi_behaviour, 1).
-include("../include/pangzi.hrl").


%% internal callback
-export([start_link/1]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3
        ]).


-record(state, {meta,
                visit_keys = gb_sets:empty(),
                set_objs = gb_trees:empty() %% gb_trees 如果是因为delete而设置的 Value=nil
               }).

-define(IS_FULL, 1000).
-define(WAIT_TIME, random:uniform(20) + 10). %% s
-define(DELETE, nil).
-define(flush_interval, flush_interval).

-define(flush_data, flush_data).
-define(shrink_data, shrink_data).
-define(is_can_flush_data, is_can_flush_data).

-define(st_meta(State), (State#state.meta)).
-define(st_set_objs(State), (State#state.set_objs)).

-define(pd_keypos, pd_keypos).
-define(pd_record_name, pd_record_name).
-define(pd_table_name, pd_table_name).
-define(pd_field_size, pd_field_size). %% record 的field 数量
-define(pd_shrink_size, pd_shrink_size). %%
-define(pd_load_all, pd_load_all).
-define(pd_shrink_interval,  pd_shrink_interval).
-define(pd_objs_size, pd_objs_size).
-define(pd_last_obj, pd_last_obj).

-define(key(Obj), (element(get(?pd_keypos), Obj))).


start_link(Meta) when is_record(Meta, db_table_meta) ->
    gen_server:start_link({local, Meta#db_table_meta.name}, ?MODULE, Meta, []).


init(#db_table_meta{name=Name, type=Type, fields=Fields, init=InitFn}=Meta) ->
    process_flag(trap_exit, true),

   %?DEBUG_LOG("db name:~p",[Name]),
    com_process:init_name("db_worker:" ++ erlang:atom_to_list(Name)),
    com_process:init_type(?MODULE),


    Keypos = 2, %% 由于numasi 的key 设定死了是第一个元素 所以ets 也设为2

    %% create ets cache
    Opts = [?named_table,
            ?public,
            Type,
            {keypos, Keypos},
            {?read_concurrency, ?true},
            {?write_concurrency, true} ],

    Name = ets:new(Name, Opts),

    ?pd_new(?pd_keypos, Keypos),
    ?pd_new(?pd_record_name, get_record_name(Meta)),
    ?pd_new(?pd_table_name, Name),
    ?pd_new(?pd_field_size, erlang:length(Fields)),
    ?pd_new(?pd_load_all, Meta#db_table_meta.load_all),
    ?pd_new(?pd_shrink_size, Meta#db_table_meta.shrink_size),
    ?pd_new(?pd_shrink_interval, Meta#db_table_meta.shrink_interval),
    ?pd_new(?pd_objs_size, 0),
    ?pd_new(?is_can_flush_data, true),
    %?pd_new(?pd_last_obj, undefined),

    %% create tables
    case com_mnesia:is_exist_table(Name) of
        true ->
            case mnesia:wait_for_tables([Name], 5000) of
                ok -> ok;
                Err->
                    ?ERROR_LOG("wait mnesia table ~p error~p", [Name, Err])
            end,

            %?INFO_LOG("db_table :~p start loading data...", [?pname()]),
            % FIXME 现在对于kv table 是在启动时load 所有数据，因为现在生成的load 函数不能正确
            % load kv table 类型的数据
            check_record(Meta),
            load_data(Meta),
            ?INFO_LOG("db_table :~p loading data over", [?pname()]),
            ok;
        false ->
            create_table(Meta),
            ?ifdo(InitFn =/= ?undefined, InitFn()),
            ok
    end,


    _=
    case Meta#db_table_meta.flush_interval of
        0 -> ok;
        FlushT ->
            _= random:seed(os:timestamp()),
            Offset1 = random:uniform(60) * 1000,
            set_flush_data_timer(FlushT, Offset1)
    end,

    _=
    case Meta#db_table_meta.load_all of
        true ->
            ok;
        false -> 
            ShrinkT = Meta#db_table_meta.shrink_interval,
            Offset2 = random:uniform(60) * 1000,
            set_shrink_data_timer(ShrinkT, Offset2)
    end,

    {ok, #state{meta=Meta}}.




handle_call(_Request, _From, State) ->
    ?ERROR_LOG("unknown msg~p", [_Request]),
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    ?ERROR_LOG("unknown msg~p", [_Msg]),
    {noreply, State}.

handle_info(Msg, State) ->
    New = handle_msg(Msg, State),
    {noreply, New}.

-spec handle_msg(_, #state{}) -> #state{}.
handle_msg(?flush_data, State) ->
    IsCanFlushData = get(?is_can_flush_data),
    if
        IsCanFlushData =:= true; IsCanFlushData =:= ?undefined ->
            case catch flush_data(State) of
                ok -> ok;
                E ->
                    ?ERROR_LOG("~p catch flush data crash ~p", [?pname(), E])
            end,
            set_flush_data_timer(?st_meta(State)#db_table_meta.flush_interval),
            %State#state{set_objs=gb_trees:empty()};
            State;
        true ->
            send_after_of_flush_data_timer(?WAIT_TIME),
            State
    end;


handle_msg(?shrink_data, State) ->
    Onlineplayer = gb_sets:from_list(com_ets:keys(world)),
    case catch shrink_data(Onlineplayer) of
        ok -> ok;
        E ->
            ?ERROR_LOG("~p catch flush data crash ~p", [?pname(), E])
    end,
    set_shrink_data_timer(?st_meta(State)#db_table_meta.shrink_interval),
    %set_shrink_data_timer(1),
    %State#state{visit_keys=gb_sets:empty()};
    State;

handle_msg({first_set, Obj}, State) when is_tuple(Obj) ->
    case catch first_set(Obj, State) of
        {ok, NewState} ->
            NewState;
        E ->
            ?ERROR_LOG("~p catch set crash ~p", [?pname(), E]),
            State
    end;


%% new or update
handle_msg({set, Obj}, State) when is_tuple(Obj) ->
    case catch set(Obj, State) of
        {ok, NewState} ->
            NewState;
        E ->
            ?ERROR_LOG("~p catch set crash ~p", [?pname(), E]),
            State
    end;

handle_msg({update_element, Key}, State) ->
    case ets:lookup(get(?pd_table_name), Key) of
        [] ->
            State;
        [Obj] ->
            case  set(Obj, State) of
                {ok, NewState} ->
                    NewState;
                E ->
                    ?ERROR_LOG("~p catch set crash ~p", [?pname(), E]),
                    State
            end
    end;

handle_msg({update_counter, Key, Op}, State) ->
    case catch mnesia:dirty_update_counter(get(?pd_table_name), Key, Op) of
        {'EXIT', E} ->
            ?ERROR_LOG("~p update_counter ~p ~p ~p", [?pname(), Key, Op, E]);
        _ ->
            ok
    end,
    %State#state{visit_keys=up_visit_key(State#state.visit_keys, Key)}; 
    State;

handle_msg({delete, Key}, State) ->
    {ok, NewState} = set_delete(Key, State),
    NewState;

handle_msg({get, Key}, State) ->
    State#state{visit_keys=gb_sets:add(Key, State#state.visit_keys)};

handle_msg(_Info, State) ->
    ?ERROR_LOG("receive a unknown mag ~p", [_Info]),
    State.

handle_all_msg_then_terminate(State) ->
    receive
        Msg ->
            handle_all_msg_then_terminate( handle_msg(Msg, State))
    after 1000 ->
              % lock ets TODO
              if (State#state.meta)#db_table_meta.flush_interval =/= 0 ->
                     flush_data(State);
                 true ->
                     ok
              end,
              mnesia:sync_log()
    end.


%% TODO terminate flush all msg
%% @spec terminate(Reason, State) -> no_return()
%%       Reason = normal | shutdown | {shutdown, term()} | term()
terminate(Reason, _State) ->

    %% no print because process_leager is no_exist
    {_, MsgC} = erlang:process_info(self(), message_queue_len),
    if Reason =:= ?normal; Reason =:= ?shutdown ->
            ?INFO_LOG("~p TERMINATE ~p message_queue_len ~p", [?pname(), Reason, MsgC]);
       true ->
            ?ERROR_LOG("~p Crash with ~p message_queue_len ~p", [?pname(), Reason, MsgC])
    end,

    State = handle_msg(?flush_data, _State),
    handle_all_msg_then_terminate(State),
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%=======================================================================
%% Internal functions
%%=======================================================================



%%% @doc sync the data change to db.
%%%
%% 数据回写
flush_data(State) ->
    %% 如果在查找和删除之间有数据改动不会有影响
    put(?is_can_flush_data, false),
    Meta =?st_meta(State),
    SetTree = ?st_set_objs(State),
    Table = Meta#db_table_meta.name,

    %%?DEBUG_LOG("SetTree ~p", [SetTree]),

    %% HACK 这里会再次查找原table，来看改变的类型，最好不要查看
    %% 当前方法可以保证回写时不会出现条件竞争

    {_DeleteKeys, UpObjects} =
        com_util:gb_trees_fold(
          fun(Key, ?DELETE, {FD, FU}) ->
                  {[Key | FD], FU};
             (_, FObj, {FD, FU}) ->
                  {FD, [FObj | FU]};
             (_,_,Acc) ->
                  ?ERROR_LOG("not macth"),
                  Acc
          end,
          {[],[]},
          SetTree),
    %io:format("DeleteKeys------------------------------:~p~n",[DeleteKeys]),
    %io:format("UpObjects-------------------------------:~p~n",[UpObjects]),
        %com_process:show_info([{message_queue_len,2}, {memory, 5*?M}]),
    %% test hanele tiem
    % Bd=com_time:timestamp_msec(),
    % DelCount =
    %     lists:foldl(
    %       fun(Key, AccIn) ->
    %               case mnesia:dirty_delete(Table, Key) of
    %                   ok ->
    %                       ok;
    %                   ED ->
    %                       ?ERROR_LOG("~p delete kye ~p ~p", [?pname(), Key, ED])
    %               end,
    %               AccIn+1
    %       end,
    %       0,
    %       DeleteKeys),

    % Ed=com_time:timestamp_msec(),

    % ?ifdo(DelCount > 0,
    %       ?INFO_LOG("~p delete ~p objs used Time ~p(ms)",
    %                 [?pname(), DelCount, Bd-Ed])),


    %Bu=com_time:timestamp_msec(),
    %UpdateCount=
    %    lists:foldl(
    %      fun(Obj,AccIn) ->
    %              case mnesia:dirty_write(Table, Obj) of
    %                  ok -> ok;
    %                  ED ->
    %                      ?ERROR_LOG("~p write obj ~p ~p", [?pname(), Obj, ED])
    %              end,
    %              AccIn+1
    %      end,
    %      0, %% kv
    %      ?if_else(Meta#db_table_meta.kv,
    %               row_to_kv_objects(Meta#db_table_meta.fields,
    %                                 UpObjects),
    %               UpObjects)),
    %Eu=com_time:timestamp_msec(),


    %?ifdo(UpdateCount > 100,
    %     ?INFO_LOG("~p sync ~p objs to db use Time ~p(ms)",
    %                [?pname(), UpdateCount, Eu-Bu])),
    lists:foreach(fun(Obj) ->
        case mnesia:dirty_write(Table, Obj) of
            ok -> ok;
            ED ->
                ?ERROR_LOG("~p write obj ~p ~p", [?pname(), Obj, ED])
        end
    end,
    ?if_else(Meta#db_table_meta.kv,
                   row_to_kv_objects(Meta#db_table_meta.fields,
                                     UpObjects),
                   UpObjects)),

    put(?is_can_flush_data, true),
    ok.

%% 吧　ｋｖ　的查询编译成代码　想ｃｏｗｂｏｄｙ一样，　load的时候查看是否是ｋｖ，
%% {Key, [atom()], {term}}
-record(kv_table, {key, fields_name, fields}).


%% FIXME just store one fieldlist to DB table.
                                                %[record] -> [{kv, Id, F}]
row_to_kv_objects(FieldList, UpObjects) ->
    Keypos = 2,
    [#kv_table{key=erlang:element(Keypos, Object), fields_name=FieldList, fields=Object}
     || Object <- UpObjects].



%% @private
% load_data(Meta=#db_table_meta{name = Tab, kv=false, load_all=false}) ->
%     ?DEBUG_LOG("pangzi_worker----------1-----------------:~p",[Tab]),
%     check_record(Meta);
load_data(Meta=#db_table_meta{name = Tab, kv=false, load_all=false}) ->
    %?DEBUG_LOG("pangzi_worker----------1-----------------:~p",[Tab]),
    ok;


load_data(#db_table_meta{name=Tab, kv=true, defualt_values=DefRow, fields=NewFieldsName}) ->
    ?DEBUG_LOG("pangzi_worker TabName----------2------------:~p",[Tab]),
    NewKV=lists:zip([Tab | NewFieldsName],
                    tuple_to_list(DefRow)),

    B=com_time:timestamp_msec(),
    %% TODO test lager tables 100W
    lists:foreach(fun(#kv_table{fields_name=FN, fields=Row} = D)  when FN =:= NewFieldsName ->
                        ?DEBUG_LOG("D--------------------:~p",[D]),
                          true = ets:insert_new(Tab, Row);
                     (#kv_table{fields_name=OldFieldsName, fields=Row}) ->
                          OldKV=lists:zip([Tab | OldFieldsName], tuple_to_list(Row)),
                          NewRow =
                              list_to_tuple(
                                lists:map(fun({F,V}) ->
                                                  case lists:keyfind(F, 1, OldKV) of
                                                      false -> V;
                                                      {_, OldV} -> OldV
                                                  end
                                          end,
                                          NewKV)),

                          %%?DEBUG_LOG("inser ~p", [Row]),
                          true = ets:insert_new(Tab, NewRow) %% set changed
                  end,
                  mnesia:dirty_select(Tab, [{'$1', [], ['$1']}])),

    E=com_time:timestamp_msec(),
    ?INFO_LOG("~p load data completed table size:~p use time:~p(mesc)",
              [?pname(),
               com_ets:table_size(Tab),
               E-B
              ]),
    ok;

%% FIXME  如果是load_all 检测 hasick 
load_data(#db_table_meta{name=Tab, load_all=true}) ->
    %?DEBUG_LOG("pangzi_worker--------------3----------------:~p",[Tab]),
    ets:insert_new(Tab,
                   mnesia:dirty_select(Tab, [{'$1', [], ['$1']}])).

check_record( Meta ) ->
    TabName = Meta#db_table_meta.name,
    %?DEBUG_LOG("TabName---------------------:~p",[TabName]),
    TabRecord = mnesia:table_info( TabName, ?attributes ),
    TabNewRecord = Meta#db_table_meta.fields,
    %?DEBUG_LOG("TabRecord-------------------:~p",[TabRecord]),
    %?DEBUG_LOG("TabNewRecord-----------------:~p",[TabNewRecord]),
    if
        TabRecord =:= TabNewRecord ->
            ok;
        true ->
            mnesia:transform_table( TabName, record_fun( TabName, TabRecord, TabNewRecord ), TabNewRecord )
    end.

record_fun(TabName, OldRecord, NewRecord) ->
    OldLen = length(OldRecord),
    OldArg = string:join(["A" ++ integer_to_list(I) || I <- lists:seq(1, OldLen)], ","),
    FunFoldl = 
    fun(New, NewArg) ->
        case lists_member_index(OldRecord, New, 0) of
            0 -> ["undefined" | NewArg];
            Index -> ["A" ++ integer_to_list(Index) | NewArg]
        end
    end,
    NewFunArg = string:join(lists:reverse(lists:foldl(FunFoldl, [], NewRecord)), ","),
    FunString = "fun({"++atom_to_list(TabName)++","++OldArg++"}) -> {"++atom_to_list(TabName)++", "++NewFunArg++"} end",
    {Fun, _} = com_util:eval(FunString),
    ?DEBUG_LOG("FunString-------------------------:~p",[FunString]),
    ?DEBUG_LOG("Fun-------------------------------:~p",[Fun]),
    Fun.

lists_member_index( [], _Key, _Index ) -> 0;
lists_member_index( [H|R], Key, Index ) ->
    if
        Key =:= H -> Index+1;
        true ->
            lists_member_index( R, Key, Index+1 )
    end.

get_record_name(Meta) ->
    case Meta#db_table_meta.record_name of
        ?undefined -> Meta#db_table_meta.name;
        RName-> RName
    end.

%% @private
create_table(#db_table_meta{name=Name, type=Type, flush_interval=FI, index=Index, fields=Fields, kv=IsKv}=Meta) ->
    RecordName = get_record_name(Meta),

    Opts =
        if IsKv andalso FI =/= 0 ->
                [{?attributes, ?record_fields(kv_table)},
                 {type, Type},
                 {record_name, kv_table},
                 {?disc_only_copies, [node()]}
                ];
           IsKv andalso FI =:= 0 ->
                ?ERROR_LOG("Table ~p can not set kv and flush_interval = 0", [Name]),
                exit(bad_args);
           %%not IsKv andalso FI =:= 0 ->
                %%[{?attributes, Fields},
                 %%{type, Type},
                 %%{record_name, RecordName},
                 %%{?disc_copies, [node()]},
                 %%{index, Index}
                %%];
           true ->
                [{?attributes, Fields},
                 {type, Type},
                 {record_name, RecordName},
                 {?disc_only_copies, [node()]},
                 {index, Index}
                ]
        end,
    case mnesia:create_table(Name, Opts) of
        {atomic, ok} ->
            ?INFO_LOG("create db_table ~p:~p", [Name, Opts]),
            ok;
        Err->
            ?ERROR_LOG("create_table ~p error:~p ~p",[Name, Err, Opts]),
            erlang:exit(bad)
    end.


%% @private
-spec set_flush_data_timer(_) -> no_return().
set_flush_data_timer(0) ->
    ok;
set_flush_data_timer(Minute) ->
    _=erlang:send_after(60 * 1000 * Minute, self(), ?flush_data).
set_flush_data_timer(Minute, Offset) ->
    _=erlang:send_after(60 * 1000 * Minute + Offset, self(), ?flush_data).

send_after_of_flush_data_timer(T) ->
    _=erlang:send_after(T * 1000, self(), ?flush_data).


set_shrink_data_timer(Minute) ->
    _=erlang:send_after(60 * 1000 * Minute, self(), ?shrink_data).
set_shrink_data_timer(Minute, Offset) ->
    _=erlang:send_after(60 * 1000 * Minute + Offset, self(), ?shrink_data).

% up_visit_key(VisitKeySet, Key) ->
%     case get(?pd_load_all) orelse get(?pd_shrink_interval) =:= 0 of %% not shrink
%         true ->
%             VisitKeySet;
%         false ->
%             gb_sets:add(Key, VisitKeySet)
%     end.

%% -> {ok, NewState}
%% 
is_full_objs(Key, Obj, State) ->
    Size = get(?pd_objs_size) + 1,
    if
        Size >= ?IS_FULL ->
            Meta = ?st_meta(State),
            TabName = Meta#db_table_meta.name,
            ?DEBUG_LOG("TabName-----:~p--Size-------------------------:~p",[TabName, Size]),
            flush_data(State),
            put(?pd_objs_size, 0),
            %put(?pd_last_obj, undefined),
            {ok, State#state{set_objs=gb_trees:empty()}};
        true ->
            put(?pd_objs_size, Size),
            %put(?pd_last_obj, Obj),
            {ok, State#state{set_objs= gb_trees:enter(Key, Obj, State#state.set_objs)}}
    end.

first_set(Obj, State) ->
    case com_record:get_name(Obj) =:= get(?pd_record_name) of
        ?false ->
            ?ERROR_LOG("~p error", [?pname()]),
            {error, badarg};
        ?true ->
            Meta = ?st_meta(State), 
            %?DEBUG_LOG("meta---------------------------:~p",[Meta]),
            %?DEBUG_LOG("Obj---------------------------------:~p",[Obj]),
            mnesia:dirty_write(Meta#db_table_meta.name, Obj),
            {ok, State}
    end.


set(Obj, State) ->
    case com_record:get_name(Obj) =:= get(?pd_record_name) of
        ?false ->
            ?ERROR_LOG("~p error", [?pname()]),
            {error, badarg};
        ?true ->
            %LastObj = get(?pd_last_obj),
            %?DEBUG_LOG("LastObj-------------------------:~p",[LastObj]),
            %?DEBUG_LOG("Obj---------------------------:~p",[Obj]),
            %?DEBUG_LOG("is true----------------------:~p",[LastObj == Obj]),
            %if
            %    LastObj =:= Obj ->
            %        io:format("is same ---------------------------------~n"),
            %        {ok, State};
            %    true ->
                    Key = ?key(Obj),
                    Meta = ?st_meta(State), 
                    case Meta#db_table_meta.flush_interval of
                        0 -> %% write just in time
                            %put(?pd_last_obj, Obj),
                            mnesia:dirty_write(Meta#db_table_meta.name, Obj),
                            %{ok, State#state{visit_keys=up_visit_key(State#state.visit_keys, Key)}};
                            {ok, State};
                       _ ->
                            %{ok, State#state{set_objs= gb_trees:enter(Key, Obj, State#state.set_objs)}}
                            %{ok, State#state{set_objs= gb_trees:enter(Key, Obj, State#state.set_objs),
                            %                 visit_keys=up_visit_key(State#state.visit_keys, Key)} }
                            is_full_objs(Key, Obj, State)
                    end
            %end
    end.

set_delete(Key, State) ->
    %%case Meta#db_table_meta.flush_interval of
    %%    0 -> %% write just in time
    %%        mnesia:dirty_delete(get(?pd_table_name), Key),
    %%        {ok, State#state{set_objs= gb_trees:enter(Key, Obj, State#state.set_objs)}};
    %%    _ ->
    %%        {ok, State#state{set_objs= gb_trees:enter(Key, Obj, State#state.set_objs),
    %%                         visit_keys=up_visit_key(State#state.visit_keys, Key)} }
    %%end.
    
    mnesia:dirty_delete(get(?pd_table_name), Key),
    {ok, State#state{set_objs= gb_trees:delete_any(Key, State#state.set_objs)}}.



%% TODO 只计算一次ets key
%% 重用剩下的

shrink_data(VisitKeySet) ->
    Tab = get(?pd_table_name),
    UsedBytes = com_ets:table_memory(Tab),
    ShrinkSize = get(?pd_shrink_size),
    if UsedBytes div (1024 * 1024) > ShrinkSize ->
            ?DEBUG_LOG("shrink_data, max size ~p UsedBytes ~p", [ShrinkSize, UsedBytes]),
            AllKeys =
                gb_sets:from_list(
                  com_ets:keys(get(?pd_table_name), get(?pd_field_size)+1)),

            CanShrinkKeysSet =
                gb_sets:fold(fun(Key, Acc) ->
            %            ?DEBUG_LOG("Key-------------------:~p",[Key]),
                                     gb_sets:delete_any(Key, Acc)
                             end,
                             AllKeys,
                             VisitKeySet),
            %?DEBUG_LOG("ets size ~p CanShrinkKeysSet ~p", [com_ets:table_size(Tab), gb_sets:size(CanShrinkKeysSet)]),
            %?DEBUG_LOG("AllKeys------------------------------:~p",[AllKeys]),
            %?DEBUG_LOG("VisitKeySet--------------------------:~p",[VisitKeySet]),
            %?DEBUG_LOG("CanShrinkKeysSet---------------------------:~p",[CanShrinkKeysSet]),
            B=com_time:timestamp_msec(),
            BSize = com_ets:table_size(Tab),

            shrink_data__(gb_sets:size(CanShrinkKeysSet),
                          gb_sets:to_list(CanShrinkKeysSet)),

            ESize = com_ets:table_size(Tab),

            E=com_time:timestamp_msec(),
            ?INFO_LOG("~p shrink data ~p speed ~p (ms)", [?pname(), BSize - ESize, E-B]);

       true ->
            ok %% non need shrink
    end,
    ok.

delete_obj(N, _, _) when N < 0 ->
    ?ERROR_LOG("N ~p < 0", [N]);
delete_obj(0, _, O) ->
    O;
delete_obj(N, Tab, [Key | Other]) ->
    ets:delete(Tab, Key),
    delete_obj(N-1, Tab, Other).


%% 更好的算法
%% 现在的算法是每次shrink 在上轮没有被visit的1/2
shrink_data__(0, _) -> ok;
shrink_data__(Size, KeyList) ->
    Tab = get(?pd_table_name),
    UsedBytes = com_ets:table_memory(Tab),
    ?DEBUG_LOG("~p :used bytes ~p ~p (MB) Size:~p table_size:~p", 
               [?pname(), UsedBytes, UsedBytes div 1024 div 1024, Size, com_ets:table_size(Tab)]),
    delete_obj(Size, Tab, KeyList),
    %ShrinkSize = get(?pd_shrink_size),
    %if UsedBytes div (1024 * 1024) > ShrinkSize ->
    %        Table =  get(?pd_table_name),
    %        DelSize = Size div 2,
    %        shrink_data__(Size - DelSize,delete_obj(DelSize, Tab, KeyList)),
    %   true ->
    %        ok %% non need shrink
    %end,
    ok.


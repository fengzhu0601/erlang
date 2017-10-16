%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 事件系统的观察者
%%% 所有游戏感兴趣的事件都可义定义为一个类型的event
%%%  比如玩家杀死了一个怪
%%% 事件的产生由一个event，或者函数调用表达，
%%% 实现event 和event 相关的处理来支撑整个游戏引擎
%%%
%%% @end
%%%-------------------------------------------------------------------



% 比如说 kill_monster
% trigger event = ev_kill_monster


%
%% 删除一个事件
%%  unreg(ev_kill_monste, {task, 10})
%%

-module(event_eng).

-include_lib("common/include/inc.hrl").
-include_lib("pangzi/include/pangzi.hrl").


-include("player.hrl").
-include("player_mod.hrl").

%%% @doc 所有的事件类型
%%% see game.hrl

-define(player_event_tab, player_event_tab).
-record(event_tab, {id,
    eng = new()}).

%% @doc
%% 所有时间发生时的　参数
%%  ev_kill_monster arg = MonsterId
%%
%%
%-define(ev_, ev_collect). %% 采集
%% 杀怪，采集，NPC对话，护送-护送NPC，不能死亡, 探索
%% 打造一个物品
%% 加入一个工会
%% ...... 行为任务

-record(event_eng, {poll = gb_trees:empty()}).

%% 一个event type的触发器
-record(event_sub, {all = [], % [handlers()]
    handlers = gb_trees:empty(), %% gb_trees {arg, [handler()]}
    keys = gb_trees:empty() %% gb_trees {key, arg}
}).

%API
-export
([
    new/0,
    is_reg/2,
    is_reg_arg/2,
    reg/5,
    unreg/2,
    post/2,
    post/3,


    is_reg/3,
    is_reg_arg/3,
    reg/6,
    unreg/3
]).



new() ->
    #event_eng{}.

%% @doc 注册一个事件
%%  reg(ev_kill_monster, 50123, {task,10}, {io,formt}, nil, Eng)
%%
%% handler() {Key, Fc, Data}
%%
%% Key 在一个event_sub 中唯一表示了一个 trigger
%% arg 指定所关心的事件的参数 比如　对于 ev_kill_monste 事件arg 就是　monsterId
%%     只有在事件是对应的arg 时才会调用 fc
%% Cb :: {Mod, Func} Func/4
%%      回调的函数，在回调时会传递给关心的时间参数和自己指定的参数
%%      回调是传入的参数为Mode:func(Key,Arg, Data, PostArg) ::  PostArg 调用post的时候传递的
%% Data 用户指定的在Fc调用是传递的参数

-spec reg(atom(), all | any(), any(), {Mod :: atom(), Func :: atom()}, any()) -> ok.
reg(Event, Arg, Key, Cb, Data) ->
    case reg(Event, Arg, Key, Cb, Data, get(?pd_event_eng)) of
        ?key_exists -> ok;
        Mng ->
            put(?pd_event_eng, Mng)
    end.


unreg(Event, Key) ->
    put(?pd_event_eng,
        unreg(Event, Key, get(?pd_event_eng))).

%% @doc 产生事件
%%  post(eve_kill_monster, 50124)
post(Event, Arg) ->
    post(Event, Arg, nil, get(?pd_event_eng)).
post(Event, Arg, PostArg) ->
    post(Event, Arg, PostArg, get(?pd_event_eng)).

%% @doc 注册一个事件，　不能注册重复的key
%% key_exists | #event_eng
%% Event--ev_kill_monster   事件类型
%% Key----{task,10001}
%% Arg---10001
%% Cb----{task_mng,handle_ev_kill_monster}
%% Data----1
reg(Event, Arg, Key, Cb, Data, #event_eng{poll = Poll} = Eng) ->
    %?DEBUG_LOG("Event---:~p----Arg----:~p----Key--:~p",[Event, Arg, Key]),
    case gb_trees:lookup(Event, Poll) of
        ?none ->
            Sub = sub_add(Arg, Key, Cb, Data, sub_new()),
            Eng#event_eng{poll = gb_trees:insert(Event, Sub, Poll)};
        {?value, _Sub} ->
            case sub_add(Arg, Key, Cb, Data, _Sub) of
                ?key_exists ->
                    ?key_exists;
                Sub ->
                    Eng#event_eng{poll = gb_trees:update(Event, Sub, Poll)}
            end
    end.


%% @doc check is reg a spcifiy event and key
is_reg(Event, Key) ->
    is_reg(Event, Key, get(?pd_event_eng)).

is_reg_arg(Event, Arg) ->
    is_reg_arg(Event, Arg, get(?pd_event_eng)).

%% @doc 删除一个注册的事件　
unreg(Event, Key, #event_eng{poll = Poll} = Eng) ->
    case gb_trees:lookup(Event, Poll) of
        ?none -> Eng;
        {?value, _Sub} ->
            %?DEBUG_LOG("_Sub--------------:~p",[_Sub]),
            Sub = sub_del(Key, _Sub),
            %?DEBUG_LOG("Sub-------------------:~p",[Sub]),
            Eng#event_eng{poll = gb_trees:update(Event, Sub, Poll)}
    end.


%% @doc 查询是否注册过指定的事件
is_reg(Event, Key, #event_eng{poll = Poll}) ->
    case gb_trees:lookup(Event, Poll) of
        ?none -> ?false;
        {?value, Sub} ->
            sub_is_exist_key(Key, Sub)
    end.


is_reg_arg(Event, Arg, #event_eng{poll = Poll}) ->
    case gb_trees:lookup(Event, Poll) of
        ?none -> ?false;
        {?value, Sub} ->
            sub_is_exist_arg(Arg, Sub)
    end.


post(Event, Arg, CbData, #event_eng{poll = Poll}) ->
    case gb_trees:lookup(Event, Poll) of
        ?none ->
            ok;
        {?value, Sub} ->
            sub_post(Arg, CbData, Sub)
    end.



-define(sub_all(), Sub#event_sub.all).
-define(make_handle(Key, Cb, Data), {(Key), (Cb), (Data)}).

%% Sub op ----------------------------------------------------------
sub_new() ->
    #event_sub{}.

%% Key 已经不能存在
sub_add(all, Key, Cb, Data, #event_sub{keys = Keys, all = All} = Sub) ->
    case gb_trees:is_defined(Key, Keys) of
        ?true ->
            ?key_exists;
        ?false ->
            Sub#event_sub{keys = gb_trees:insert(Key, all, Keys),
                all = [?make_handle(Key, Cb, Data) | All]}
    end;
sub_add(Arg, Key, Cb, Data, #event_sub{keys = Keys, handlers = H} = Sub) ->
    case gb_trees:lookup(Key, Keys) of
        {?value, _} ->
            ?ERROR_LOG("sub key ~p alreay_in arg ~p", [Key, Arg]),
            ?key_exists;
        ?none ->
            Handlers =
                case gb_trees:lookup(Arg, H) of
                    ?none ->
                        gb_trees:insert(Arg, [?make_handle(Key, Cb, Data)], H);
                    {?value, V} ->
                        gb_trees:update(Arg, [?make_handle(Key, Cb, Data) | V], H)
                end,

            Sub#event_sub{keys = gb_trees:insert(Key, Arg, Keys),handlers = Handlers}
    end.


sub_del(Key, #event_sub{keys = Keys, all = _All, handlers = H} = Sub) ->
    %?DEBUG_LOG("Key---:~p-------Keys--:~p---handlers---:~p",[Key, Keys, H]),
    case gb_trees:lookup(Key, Keys) of
        ?none ->
            Sub;
        {?value, all} ->
            Sub#event_sub{keys = gb_trees:delete(Key, Keys),
                all = lists:keydelete(Key, 1, _All)};
        {?value, Arg} ->
            %?DEBUG_LOG("Arg--------------:~p",[Arg]),
            {?value, L} = gb_trees:lookup(Arg, H),
            case lists:keydelete(Key, 1, L) of
                [] ->
                    Sub#event_sub{keys = gb_trees:delete(Key, Keys),
                        handlers = gb_trees:delete(Arg, H)};
                NL ->
                    Sub#event_sub{keys = gb_trees:delete(Key, Keys),
                        handlers = gb_trees:update(Arg, NL, H)}
            end
    end.



sub_is_exist_key(Key, #event_sub{keys = Keys}) ->
    gb_trees:is_defined(Key, Keys).


sub_is_exist_arg(Arg, #event_sub{all = All, handlers = H}) ->
    if All =/= [] -> true;
        true ->
            gb_trees:is_defined(Arg, H)
    end.


sub_post(Arg, CbData, #event_sub{all = All, handlers = H}) ->
    lists:foreach(fun({Key, Cb, Data}) ->
        handle_ev(Cb, Key, Arg, Data, CbData)
    end,
    lists:reverse(All)),
    case gb_trees:lookup(Arg, H) of
        ?none -> 
            ok;
        {?value, Handlers} ->
            %?DEBUG_LOG("Handlers---------------:~p",[Handlers]),
            lists:foreach(fun({Key, Cb, Data}) ->
                handle_ev(Cb, Key, Arg, Data, CbData)
            end,
            lists:reverse(Handlers))
    end.


handle_ev({Mod, Func}, Key, Arg, Data, CbData) ->
    com_util:safe_apply(Mod, Func, [Key, Arg, Data, CbData]).



create_mod_data(SelfId) ->
    case dbcache:insert_new(?player_event_tab,
        #event_tab{id = SelfId})
    of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create new task msg not alread exists ", [SelfId])
    end,
    ok.


load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_event_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find player_task_tab mode", [PlayerId]),
            Eng = new(),
            dbcache:insert_new(?player_event_tab, #event_tab{id = PlayerId, eng = Eng}),
            Eng;
        [#event_tab{eng = Eng}] ->
            Eng
    end,
    ?assert(Eng =/= ?undefined),
    ?pd_new(?pd_event_eng, Eng),
    ok.

init_client() -> ok.
view_data(Acc) -> Acc.
online() -> ok.


offline(_PlayerId) ->
    ok.

handle_frame(_) ->
    save_data(erlang:get(?pd_id)),
    ok.

save_data(_PlayerId) ->
    dbcache:update(?player_event_tab, #event_tab{id = _PlayerId, eng = get(?pd_event_eng)}),
    ok.

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_event_tab,
            fields = ?record_fields(event_tab),
            record_name = event_tab,
            shrink_size = 20,
            flush_interval = 2
        }
    ].


%============= TEST unit
%-define(TEST,1).
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").


all_test() ->
    %Eng = new(),
    %?assert(not is_reg(ev_kill_monste, {task, 10}, Eng)),
    %Eng1 = reg(ev_kill_monste, 456, {task, 10}, , Eng),
    %?assert(is_reg(ev_kill_monste, {task, 10}, Eng1)),
    %Eng2 =unreg(ev_kill_monste, {task, 10}, Eng1),
    %?assert(not is_reg(ev_kill_monste, {task, 10}, Eng2)),

    ok.


-endif.

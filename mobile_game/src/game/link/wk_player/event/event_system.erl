%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 七月 2015 下午5:32
%%%-------------------------------------------------------------------
-module(event_system).
-author("clark").

%% API
-export([
    reg_vote/3
    , unreg_vote/3
    , reg_run/3
    , unreg_run/3
    , fire_vote/3
    , fire_run/3
    , fire/3
]).


-include("inc.hrl").
-include("game.hrl").
-include("player.hrl").


%% 本想把事件机做为工具用， 他本身不挂勾数据保存的，但是改动多，先这样了。
%% ----------------------------------------------------------------
%% %% 创建备份
%% create_memento() -> {get(?pd_vote_evts_tree), get(?pd_run_evts_tree)}.
%%
%% %% 载入备份
%% set_memento( {VoteTree, RunTree} ) -> put(?pd_vote_evts_tree, VoteTree), put(?pd_run_evts_tree, RunTree).
%%
%% %% 清空数据
%% clear() -> set_memento({gb_trees:empty(), gb_trees:empty()}).
%% ----------------------------------------------------------------




%% 注册否决（不作重复性注册的过滤）
-spec reg_vote(atom(), all | any(), {Mod :: atom(), Func :: atom(), UID :: any()}) -> ok.
reg_vote(EvtID, FromUID, Callback) ->
    VoteTree = get(?pd_vote_evts_tree),
    NewVoteTree = do_reg(VoteTree, EvtID, FromUID, Callback),
    put(?pd_vote_evts_tree, NewVoteTree).

%% 注销否决
-spec unreg_vote(atom(), all | any(), {Mod :: atom(), Func :: atom(), UID :: any()}) -> ok.
unreg_vote(EvtID, FromUID, Callback) ->
    VoteTree = get(?pd_vote_evts_tree),
    NewVoteTree = do_unreg(VoteTree, EvtID, FromUID, Callback),
    put(?pd_vote_evts_tree, NewVoteTree).

%% 注册执行（不作重复性注册的过滤）
-spec reg_run(atom(), all | any(), {Mod :: atom(), Func :: atom(), UID :: any()}) -> ok.
reg_run(EvtID, FromUID, Callback) ->
    RunTree = get(?pd_run_evts_tree),
    NewRunTree = do_reg(RunTree, EvtID, FromUID, Callback),
    put(?pd_run_evts_tree, NewRunTree).

%% 注销执行
-spec unreg_run(atom(), all | any(), {Mod :: atom(), Func :: atom(), UID :: any()}) -> ok.
unreg_run(EvtID, FromUID, Callback) ->
    RunTree = get(?pd_run_evts_tree),
    NewRunTree = do_unreg(RunTree, EvtID, FromUID, Callback),
    put(?pd_run_evts_tree, NewRunTree).


%% 派发否决事件
-spec fire_vote(atom(), all | any(), any()) -> true | false.
fire_vote(EvtID, FromUID, EvtPar) ->
    Tree = get(?pd_vote_evts_tree),
    IsAllVote =
        if
            FromUID =/= all ->
                case gb_trees:lookup({EvtID, all}, Tree) of
                    none ->
                        false;
                    {_, CallbackList} ->
                        vote(lists:reverse(CallbackList), EvtID, EvtPar)
                end;
            true ->
                false
        end,
    Ret =
        case IsAllVote of
            true -> true;
            _ ->
                case gb_trees:lookup({EvtID, FromUID}, Tree) of
                    none -> false;
                    {_, VoteCallbackList} ->
                        vote(lists:reverse(VoteCallbackList), EvtID, EvtPar)
                end
        end,
    Ret.


%% 派发执行事件
-spec fire_run(atom(), all | any(), any()) -> ok.
fire_run(EvtID, FromUID, EvtPar) ->
    Tree = get(?pd_run_evts_tree),
    if
        FromUID =/= all ->
            case gb_trees:lookup({EvtID, all}, Tree) of
                none -> ok;
                {_, CallbackList} -> run(lists:reverse(CallbackList), EvtID, EvtPar)
            end;
        true -> ok
    end,
    case gb_trees:lookup({EvtID, FromUID}, Tree) of
        none -> ok;
        {_, RunCallbackList} -> run(lists:reverse(RunCallbackList), EvtID, EvtPar)
    end.


%% 派发事件
-spec fire(atom(), all | any(), any()) -> ok.
fire(EvtID, FromUID, EvtPar) ->
    case fire_vote(EvtID, FromUID, EvtPar) of
        true -> ok;
        _ ->
            fire_run(EvtID, FromUID, EvtPar),
            ok
    end.




%% -------------------------------------------------------------
%% -------------------------------------------------------------
do_reg(Trees, EvtID, FromUID, Callback) ->
    NewTrees =
        case gb_trees:lookup({EvtID, FromUID}, Trees) of
            none ->
                gb_trees:insert({EvtID, FromUID}, [Callback], Trees);
            {_, CallbackList} ->
                gb_trees:update({EvtID, FromUID}, [Callback | CallbackList], Trees)
        end,
%%     ?INFO_LOG("do_reg ~p", [NewTrees]),
    NewTrees.


do_unreg(Trees, EvtID, FromUID, Callback) ->
    NewTrees =
        case gb_trees:lookup({EvtID, FromUID}, Trees) of
            none -> Trees;
            {_, CallbackList} ->
                case lists:delete(Callback, CallbackList) of
                    [] ->
                        gb_trees:delete({EvtID, FromUID}, Trees);
                    NewCallbackList ->
                        gb_trees:update({EvtID, FromUID}, NewCallbackList, Trees)
                end
        end,
    NewTrees.

vote([], _Evt, _EvtPar) -> false;
vote([{Mod, Func, UID} | TailList], Evt, EvtPar) ->
    case Mod:Func(UID, Evt, EvtPar) of
        true -> true;
        _ -> vote(TailList, Evt, EvtPar)
    end.

run([], _Evt, _EvtPar) -> ok;
run([{Mod, Func, UID} | TailList], Evt, EvtPar) ->
    Mod:Func(UID, Evt, EvtPar),
    run(TailList, Evt, EvtPar).




%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 九月 2015 上午11:01
%%%-------------------------------------------------------------------
-module(map_block).
-author("clark").

%% API
-export(
[
    p_block_insert/2
    , p_block_remove/2
    , get_p_block_agent_idxs/1
    , p_block_update/3
    , p_block_get/1
    , get_p_block_id/2
    , get_p_block_id/1
    , get_window_agents/1
    , get_osn_of_window_agents/2
]).


-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").

-define(p_block_key(BlockId), {'@p_block@', BlockId}).



get_p_block_id(X, Y) ->
    {X div ?BLOCK_W, Y div ?BLOCK_H}.

get_p_block_id({X, Y}) ->
    {X div ?BLOCK_W, Y div ?BLOCK_H}.


p_block_insert(Idx, BlockId) ->
    case erlang:get(?p_block_key(BlockId)) of
        ?undefined ->
            erlang:put(?p_block_key(BlockId), {1, {Idx, nil, nil}});    
        Set ->
            ?Assert2(not gb_sets:is_member(Idx, Set), "idx ~p alread in ~p", [Idx, BlockId]),
            erlang:put(?p_block_key(BlockId), gb_sets:insert(Idx, Set))
    end.

p_block_remove(Idx, BlockId) ->
    case erlang:get(?p_block_key(BlockId)) of
        {1, {Idx, _, _}} -> %%{1, {_Idx, nil, nil}}
            erlang:erase(?p_block_key(BlockId));
        Set ->
            case gb_sets:is_set(Set) andalso gb_sets:is_member(Idx, Set) of
                true ->
                    erlang:put(?p_block_key(BlockId), gb_sets:delete(Idx, Set));
                _ ->
                    ret:ok()
            end
    end.


get_p_block_agent_idxs(BlockId) ->
    case erlang:get(?p_block_key(BlockId)) of
        ?undefined -> [];
        Set ->
            gb_sets:to_list(Set)
    end.

p_block_update(Idx, OldBlockId, NewBlockId) ->
    if
        OldBlockId =/= NewBlockId ->
            p_block_remove(Idx, OldBlockId),
            p_block_insert(Idx, NewBlockId);
        true ->
            ret:ok()
    end.

% p_block_get([]) -> [];
% p_block_get([BlockId | TailList]) ->
    % case p_block_get(BlockId) of
    %     ?undefined -> 
    %         p_block_get(TailList);
    %     Set ->
    %         IdsList = gb_sets:to_list(Set),
    %         IdsList ++ p_block_get(TailList)
    % end;
p_block_get(List) when is_list(List)->
    p_block_get_(List, []);
p_block_get(BlockId)->
    get(?p_block_key(BlockId)).


p_block_get_([], L) ->
    L;
p_block_get_([BlockId | TailList], L) ->
    case p_block_get(BlockId) of
        ?undefined ->
            p_block_get_(TailList, L);
        Set ->
            IdsList = gb_sets:to_list(Set),
            p_block_get_(TailList, util:list_add_list(IdsList, L))
    end.


get_window_agents(VBs) ->
    BlockList = get_blocks_in_window(VBs),
    p_block_get(BlockList).


get_blocks_in_window({{Xl, Yt}, W, H}) ->
    [{X, Y} || X <- lists:seq(Xl, Xl + W), Y <- lists:seq(Yt, Yt + H)].

get_osn_of_window_agents(VBs1, VBs2) ->
    case com_ordsets:osn
    (
        get_blocks_in_window(VBs1),
        get_blocks_in_window(VBs2)
    )
    of
        same -> same;
        {[], _, []} -> same;
        {ExitBlocks, _, EnterBlocks} ->
            com_ordsets:osn
            (
                p_block_get(ExitBlocks),
                p_block_get(EnterBlocks)
            );
        _ ->
            ?ERROR_LOG("failed in broadcast_move"),
            same
    end.
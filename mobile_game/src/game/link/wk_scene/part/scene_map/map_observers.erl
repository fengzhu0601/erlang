%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 九月 2015 下午6:48
%%%-------------------------------------------------------------------
-module(map_observers).
-author("clark").

%% API
-export(
[
    init/2
    , get_range/3

    , view_blocks_new/2
    , view_blocks_new_list/3
    , view_blocks_update/3
    , view_blocks_foreach/2
    , view_blocks_fold/3

    , view_blocks_insert/2
    , view_blocks_remove/2
    , view_block_get/1
    , view_block_player_foreach/2
    , view_block_player_ids/1
    , view_blocks_agents_foreach/2
    , view_blocks_agents_fold/3

    , get_view_block_player_agent_idx/1
    , in_range_agents_foreach/3
    , in_range_agents_fold/4

    , get_player_by_blockid/1
    , get_osn_of_block_agents/2
    , get_player_by_blockid_un_own/2
]).






-include("inc.hrl").
-include("scene.hrl").
-include("scene_agent.hrl").


-define(view_block_key(BlockId), {'@view_block@', BlockId}).


init(W, H) -> [pd_gb_sets:new(?view_block_key({X, Y})) || X <- lists:seq(0, W), Y <- lists:seq(0, H)].



% @doc 得到视野内的所有block id,
%%
%%  Yt
%%  .
%%  .
%% Xl ...... Xr
%%  .
%%  .
%%  Yb
%%
%% 其实这么多点可以使用一个左上角blockId 和 XblockCount, YBlockCount
%% 代替
-type view_blocks() :: {block_id(), pos_integer(), pos_integer()}.
-spec view_blocks_new(map_point(), map_point()) -> view_blocks().
view_blocks_new({Xl, Xr}, {Yt, Yb}) ->
    ?Assert2(Xl =< Xr andalso Yt =< Yb, "bad ~p, ~p", [{Xl, Xr}, {Yt, Yb}]),
    ?Assert(Xl >= 0 andalso Yb >= 0, "< 0"),
    Bxl = Xl div ?BLOCK_W,
    Bxr = Xr div ?BLOCK_W,
    Byt = Yt div ?BLOCK_H,
    Byb = Yb div ?BLOCK_H,
    {
        {Bxl, Byt},
        Bxr - Bxl,
        Byb - Byt
    }.


%% 得到所有视野的block id
?INLINE(view_blocks_new_list, 3).
view_blocks_new_list({X, Y}, Xr, Yr) ->
    view_blocks_to_list
    (
        view_blocks_new
        (
            get_range(X, Xr, get(?pd_map_width)),
            get_range(Y, Yr, get(?pd_map_height))
        )
    ).


view_blocks_to_list({{Xl, Yt}, W, H}) ->
    [{X, Y} || X <- lists:seq(Xl, Xl + W), Y <- lists:seq(Yt, Yt + H)].

?INLINE(view_blocks_update, 3).
view_blocks_update(_Idx, Same, Same) -> same;
view_blocks_update(Idx, OldVBs, NewVBs) -> %% 可以使用bitmap 然后bitor bitand 提高速度
    {O, S, N} =
        com_ordsets:osn
        (
            view_blocks_to_list(OldVBs),
            view_blocks_to_list(NewVBs)
        ),
    %%?debug_log_scene_aoi("view_blocks_update remove ~p, ~p", [O, N]),
    view_blocks_remove_list(Idx, O),
    %%?debug_log_scene_aoi("view_blocks_update insert ~p, ~p", [O, N]),
    view_blocks_insert_list(Idx, N),
    %%?debug_log_scene_aoi("view_blocks_update end ~p, ~p", [O, N]),

    %% FOR TEST develep
    view_blocks_foreach
    (
        fun(BlockId) ->
            ?assert(gb_sets:is_member(Idx, view_block_get(BlockId)))
        end,
        NewVBs
    ),
    %% END
    {O, S, N}.




view_blocks_foreach(Fn, {{X, Y}, XCount, YCount}) ->
    com_util:for
    (
        X, X + XCount,
        fun
            (Bx) ->
                com_util:for
                (
                    Y, Y + YCount,
                    fun
                        (By) -> Fn({Bx, By})
                    end
                )
        end
    ).

view_blocks_fold(Fn, AccIn, {{X, Y}, XCount, YCount}) ->
    com_util:fold
    (
        X,
        X + XCount,
        fun(Bx, Acc) ->
            com_util:fold
            (
                Y,
                Y + YCount,
                fun(By, Acc_1) ->
                    Fn({Bx, By}, Acc_1)
                end,
                Acc
            )
        end,
        AccIn
    ).


%% 插入我的idx, 不允许重复插入
?INLINE(view_blocks_insert, 2).
view_blocks_insert(Idx, VB) ->
    view_blocks_foreach
    (
        fun(BlockId) ->
            ?Assert2
            (
                (not gb_sets:is_member(Idx, view_block_get(BlockId))),
                "insert repeta Idx ~p vb ~p", [Idx, BlockId]
            ),
            put(?view_block_key(BlockId),
                gb_sets:insert(Idx, get(?view_block_key(BlockId))))
        end,
        VB
    ).

?INLINE(view_blocks_insert_list, 2).
view_blocks_insert_list(Idx, BlockIdList) ->
    lists:foreach
    (
        fun(BlockId) ->
            ?Assert2(gb_sets:is_set(view_block_get(BlockId)), "not set ~p ~p cc ~p",
                [BlockId, view_block_get(BlockId), erlang:get(pd_map_block_count)]),
            ?Assert2((not gb_sets:is_member(Idx, view_block_get(BlockId))), "insert repeta Idx ~p vb ~p", [Idx, BlockId]),
            put(?view_block_key(BlockId), gb_sets:insert(Idx, get(?view_block_key(BlockId))))
        end,
        BlockIdList
    ).

%% VB 中必须存在 idx
?INLINE(view_blocks_remove, 2).
view_blocks_remove(Idx, VB) ->
    view_blocks_foreach
    (
        fun(BlockId) ->
            case gb_sets:is_member(Idx, view_block_get(BlockId)) of
                ?true ->
                    ?Assert2(gb_sets:is_member(Idx, view_block_get(BlockId)), "delete Idx ~p vb ~p", [Idx, BlockId]),
                    put(?view_block_key(BlockId), gb_sets:delete(Idx, get(?view_block_key(BlockId)))),
                    ?assert(view_block_get(BlockId) =/= ?undefined);
                ?false ->
                    ok
                    % ?ERROR_LOG("not member idx ~p bid~p vb ~p ~p", [Idx, VB, BlockId, ?get_agent(Idx)])
            end
        end,
        VB
    ).

?INLINE(view_blocks_remove_list, 2).
view_blocks_remove_list(Idx, BlockIdList) ->
    lists:foreach
    (
        fun(BlockId) ->
            %%?Assert2(gb_sets:is_set(get(?view_block_key(BlockId))), "not set vb ~p", [BlockId]),
            ?Assert2(gb_sets:is_member(Idx, view_block_get(BlockId)), "delete Idx ~p vb ~p", [Idx, BlockId]),
            put(?view_block_key(BlockId), gb_sets:delete(Idx, get(?view_block_key(BlockId)))),
            ?assert(view_block_get(BlockId) =/= ?undefined)
        end,
        BlockIdList
    ).

?INLINE(view_block_get, 1).
view_block_get(BlockId) ->
    get(?view_block_key(BlockId)).

get_range(Center, R, Max) ->
    % ?Assert(Center < Max, "bad ponit"),
    ?Assert(Center >= 0, "bad center"),
    ?Assert(R >= 0, "bad center"),
    ?Assert(Max >= 1, "bad center"),

    if
        Center =< R ->
            {0, min(2 * R, Max - 1)};
        Center + R > Max - 1 ->
            {max(0, Max - 1 - 2 * R), Max - 1};
        true -> %% 90% 落入这里
            {Center - R, Center + R}
    end.

%% 得到一个view block 的所有　player agent idx -> ordsets()
?INLINE(get_view_block_player_agent_idx, 1).
-spec get_view_block_player_agent_idx(block_id()) -> ordsets:ordset().
get_view_block_player_agent_idx(BlockId) ->
    [Idx || Idx <- gb_sets:to_list(map_observers:view_block_get(BlockId)), Idx > 0].

%% 能看见这个blockId players
view_block_player_foreach(Fn, BlockIdList) when is_list(BlockIdList) ->
    lists:foreach
    (
        fun
            (BlockId) ->
                view_block_player_foreach(Fn, BlockId)
        end,
        BlockIdList
    );
view_block_player_foreach(Fn, BlockId) ->
    gb_sets:fold
    (
        fun(Idx, _) when Idx > 0 -> %% TODO 可以考虑monster player 分开存
            Fn(?get_agent(Idx));
            (_, _) -> nil
        end,
        unused,
        map_observers:view_block_get(BlockId)
    ).

view_block_player_ids(BlockId) ->
    gb_sets:fold
    (
        fun
            (Idx, Acc_1) when Idx > 0 -> [Idx | Acc_1];
            (_, Acc_1) -> Acc_1
        end,
        [],
        map_observers:view_block_get(BlockId)
    ).


%%%% TODO 可以再次优化为，全覆盖视野块，和部分覆盖视野块,
view_blocks_agents_foreach(Fn, VBs) ->
    map_observers:view_blocks_foreach
    (
        fun(BlockId) ->
            case map_block:p_block_get(BlockId) of
                ?undefined ->
                    ok;
                Sets ->
                    gb_sets:fold
                    (
                        fun(Idx, _) ->
                            Fn(?get_agent(Idx))
                        end,
                        unused,
                        Sets
                    )
            end
        end,
        VBs
    ).

%% TODO 判断两个矩形是否相交
is_in_range(#agent{x = X, y = Y}, {Xr, Xl}, {Yt, Yd}) ->
    X >= Xr
        andalso X =< Xl
        andalso Y >= Yt
        andalso Y =< Yd.


view_blocks_agents_fold(Fn, AccIn, VBs) ->
    map_observers:view_blocks_fold
    (
        fun
            (BlockId, Acc) ->
                case map_block:p_block_get(BlockId) of
                    ?undefined -> Acc;
                    Sets ->
                        gb_sets:fold
                        (
                            fun
                                (Idx, Acc_1) -> Fn(?get_agent(Idx), Acc_1)
                            end,
                            Acc,
                            Sets
                        )
                end
        end,
        AccIn,
        VBs
    ).

%% @doc 得到指定范围内的所有agent's id
in_range_agents_foreach(Fn, Xrange, Yrange) ->
    map_observers:view_blocks_agents_foreach
    (
        fun(A) ->
            case is_in_range(A, Xrange, Yrange) of
                ?false -> ok;
                ?true -> Fn(A)
            end
        end,
        map_observers:view_blocks_new(Xrange, Yrange)
    ).

in_range_agents_fold(Fn, Xrange, Yrange, AccIn) ->
    map_observers:view_blocks_agents_fold
    (
        fun(A, Acc) ->
            case is_in_range(A, Xrange, Yrange) of
                ?false -> Acc;
                ?true -> Fn(A, Acc)
            end
        end,
        AccIn,
        map_observers:view_blocks_new(Xrange, Yrange)
    ).

%% 得到一个view block 的所有　player agent idx -> ordsets()
get_player_by_blockid_un_own(?undefined, _) ->
    [];
get_player_by_blockid_un_own(BlockId, OwnIdx) ->
    case view_block_get(BlockId) of
        ?undefined ->
            [];
        Set ->
            [Idx || Idx <- gb_sets:to_list(Set), Idx > 0, Idx =/= OwnIdx]
    end.

get_player_by_blockid(?undefined) -> 
    [];
get_player_by_blockid(BlockId) ->
    case view_block_get(BlockId) of
        ?undefined -> 
            [];
        Set ->
            [Idx || Idx <- gb_sets:to_list(Set), Idx > 0]
    end.



get_osn_of_block_agents(BlockID1, BlockID2) ->
    Block1 = get_player_by_blockid(BlockID1),
    Block2 = get_player_by_blockid(BlockID2),
%%     ?INFO_LOG("get_osn_of_block_agents ~p", [{Block1, Block2}]),
    com_ordsets:osn
    (
        Block1,
        Block2
    ).
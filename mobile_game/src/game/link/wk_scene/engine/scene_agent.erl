%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_agent).


-include("inc.hrl").

-include("scene.hrl").
-include("skill_struct.hrl").
-include("scene_agent.hrl").
-include("model_box.hrl").
-include("load_cfg_scene.hrl").

-export(
[
    take_player_idx/0
    % ,take_player_idx/2
    , cancel_state_timer/1
    , get_view_info/1     %自己的agent打包后可以直接发给客户端
    , get_monster_view_info/1

    , leave_scene/1         %离开场景

    , add_agent_hurt_cb/2
    , del_agent_hurt_cb/1
    , del_agent_hurt_cb/2

    , add_agent_die_cb/2
    , del_agent_die_cb/1
    , del_agent_die_cb/2

    , pkg_enter_view_msg/1  %根据agent打包成可以直接发给客户端的二进制
]).



pkg_enter_view_msg(#agent{} = A) ->
    if
        A#agent.idx > 0 ->
            scene_sproto:pkg_msg(?MSG_SCENE_ENTER_VIEW, {[get_view_info(A)], []});
        true ->
            scene_sproto:pkg_msg(?MSG_SCENE_ENTER_VIEW, {[], [get_monster_view_info(A)]})
    end.


%% agent 离开场景，调用结束了，会清扫agent 在场景中的
%% 所有信息,　agent 也不能在使用ａｇｅｎｔ.
leave_scene(#agent{idx = Idx, id = Id, state_timer = StateTimer}) ->
    ?ifdo(Idx > 0, erase(?player_idx(Id))),
    %% TODO cancel all state timer
    scene_fight:cancle_releasing_skill(Idx),
    cancel_state_timer(StateTimer),
    del_agent_hurt_cb(Idx),
    del_agent_die_cb(Idx),
    map_agent:delete(Idx),
    case load_cfg_scene:is_normal_scene(get(?pd_scene_id)) of
        true -> %% 主城
            free_idx(Idx);
        _ -> pass
    end,
    ok.

take_player_idx() ->
    FreeIdxSets = get(?pd_player_free_id),
    case gb_sets:is_empty(FreeIdxSets) of
        true ->
            Idx = get(?pd_player_max_id) + 1,
            put(?pd_player_max_id, Idx);
        _ ->
            {Idx, FreeIdxSets2} = gb_sets:take_smallest(FreeIdxSets),
            put(?pd_player_free_id, FreeIdxSets2)
    end,
    Idx.

% take_player_idx() ->
%     Idx = util:get_pd_field(?pd_player_max_id, 0) + 1,
%     util:set_pd_field(?pd_player_max_id, Idx),
%     Idx.
% take_player_idx(SceneId, PlayerId) ->
%     SIndex = "1",
%     SSceneId = get_really_SceneId_to_make(SceneId),
%     {_, _, SId} = un_playerid(PlayerId),
%     Id = SIndex ++ SSceneId ++ integer_to_list(SId),
%     Idx = list_to_integer(Id),
%     put(?pd_player_max_id, Idx),
%     Idx.

% un_playerid(PlayerId) ->
%     PlatformId = PlayerId div 10000000000 rem 10000,
%     ServerId = PlayerId div 1000000 rem 10000,
%     Id = PlayerId rem 1000000,
%     {PlatformId, ServerId, Id}.

% get_really_SceneId_to_make(SceneId) ->
%     case SceneId of
%         {SId, _, _} ->
%             make_scene_id(SId);
%         _ ->
%             make_scene_id(SceneId)
%     end.

% make_scene_id(SceneId) ->
%     S = integer_to_list(SceneId),
%     Ssize = length(S),
%     if
%         Ssize =:= 5 ->
%             S;
%         Ssize =:= 4 ->
%             "0" ++ S;
%         Ssize =:= 3 ->
%             "00" ++ S;
%         Ssize =:= 2 ->
%             "000" ++ S;
%         Ssize =:= 1 ->
%             "0000" ++ S;
%         true ->
%             "00000"
%     end.

free_idx(Idx) when Idx > 0 ->
    FreeIdxSets = get(?pd_player_free_id),
    case get(?pd_player_max_id) of
        Idx ->
            {MaxIdx, NewFreeIdxSets} = scene_eng:shrink_idx(Idx - 1, FreeIdxSets, -1),
            put(?pd_player_max_id, MaxIdx),
            put(?pd_player_free_id, NewFreeIdxSets);
        _ ->
            put(?pd_player_free_id, gb_sets:add(Idx, FreeIdxSets))
    end;
free_idx(Idx) ->
    FreeIdxSets = get(?pd_monster_free_id),
    case get(?pd_monster_max_id) of
        Idx ->
            {MaxIdx, NewFreeIdxSets} = scene_eng:shrink_idx(Idx + 1, FreeIdxSets, 1),
            put(?pd_monster_max_id, MaxIdx),
            put(?pd_monster_free_id, NewFreeIdxSets);
        _ ->
            put(?pd_monster_free_id, gb_sets:add(Idx, FreeIdxSets))
    end.

%% @doc 设置伤害回调
add_agent_hurt_cb(Idx, Cb) when is_function(Cb, 3) ->
    case get(?pd_agent_hurt_cb(Idx)) of
        ?undefined ->
            ?debug_log_scene("++++++++add_agent_hurt_cb,IDx =~p", [Idx]),
            put(?pd_agent_hurt_cb(Idx), [Cb]);
        L ->
            ?debug_log_scene("++++++++add_agent_hurt_cb,IDx =~p", [Idx]),
            NList = lists:delete(Cb, L),
            put(?pd_agent_hurt_cb(Idx), [Cb | NList])
    end.

del_agent_hurt_cb(Idx) ->
    erase(?pd_agent_hurt_cb(Idx)).

del_agent_hurt_cb(Idx, Cb) when is_function(Cb, 3) ->
    case get(?pd_agent_hurt_cb(Idx)) of
        ?undefined ->
            ?ERROR_LOG("delete agent ~p hurt cb but not find", [Idx]);
        List ->
            case lists:delete(Cb, List) of
                [] ->
                    erase(?pd_agent_hurt_cb(Idx));
                NList ->
                    put(?pd_agent_hurt_cb(Idx), NList)
            end
    end.


%% @doc 添加死亡回调
%% cd (Agent, _Killer) ->
add_agent_die_cb(Idx, Cb) when is_function(Cb, 2) ->
    case get(?pd_agent_die_cb(Idx)) of
        ?undefined ->
            put(?pd_agent_die_cb(Idx), [Cb]);
        L ->
            NList = lists:delete(Cb, L),
            put(?pd_agent_die_cb(Idx), [Cb | NList])
    end.


del_agent_die_cb(Idx) ->
    erase(?pd_agent_die_cb(Idx)).

del_agent_die_cb(Idx, Cb) when is_function(Cb, 2) ->
    case get(?pd_agent_die_cb(Idx)) of
        ?undefined ->
            ?ERROR_LOG("delete agent ~p die cb but not find", [Idx]);
        List ->
            case lists:delete(Cb, List) of
                [] ->
                    erase(?pd_agent_die_cb(Idx));
                NList ->
                    put(?pd_agent_die_cb(Idx), NList)
            end
    end.

get_view_info(
    #agent{
        idx = Idx, d = D, x = X, y = Y, h = H, hp = Hp, max_hp = MaxHp, mp = Mp, max_mp = MaxMp,
        move_vec = MV, enter_view_info = ViewInfo, eft_list = Efts, cardId = CardId, rideId = RideId, party = Party, ai_flag = AiFlag
    }
) ->
    {
        Idx,
        D,
        X,
        Y,
        H,
        {
            MV#move_vec.x_speed,
            MV#move_vec.y_speed,
            200
        },
        {
            MV#move_vec.x_vec,
            MV#move_vec.y_vec,
            MV#move_vec.h_vec
        },
        Hp,
        MaxHp,
        Mp,
        MaxMp,
        ViewInfo,
        Efts,
        CardId,
        RideId,
        Party,
        AiFlag
    }.


get_monster_view_info(#agent{idx = Idx, d = D, x = X, y = Y, h = H, level = Level, hp = Hp, max_hp = MaxHp, move_vec = MV, enter_view_info = ViewInfo, party = Party, ai_flag = AiFlag}) ->
    {
        Idx,
        D,
        X,
        Y,
        H,
        {
            MV#move_vec.x_speed,
            MV#move_vec.y_speed,
            200
        },
        {
            MV#move_vec.x_vec,
            MV#move_vec.y_vec,
            MV#move_vec.h_vec
        },
        Level,
        Hp,
        MaxHp,
        ViewInfo,
        Party,
        AiFlag
    }.


cancel_state_timer(?none) -> ok;
cancel_state_timer({?ss_stiff, Ref, _NewStiffEndTime}) ->
    case scene_eng:is_wait_timer(Ref) of
        ?true ->
            scene_eng:cancel_timer(Ref);
        ?false ->
            ?ERROR_LOG("can not find timer stiff")
    end;
cancel_state_timer(Ref) ->
    case Ref of
        {ba_ti, Ref} ->
            ?ERROR_LOG("bad Ref ~p", [Ref]);
        {reaction, Ref} ->
            ?ERROR_LOG("bad Ref ~p", [Ref]);
        {spell, _} ->
            ?ERROR_LOG("bad Ref ~p", [Ref]);
        {stroll, Ref} ->
            ?ERROR_LOG("bad Ref ~p", [Ref]);
        _ ->
            scene_eng:cancel_timer(Ref)
    end.

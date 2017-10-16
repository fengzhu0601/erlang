%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%-------------------------------------------------------------------
-module(sky_handle_client).

-include("inc.hrl").
-include("player.hrl").
-include("handle_client.hrl").

-include("sky_struct.hrl").
-include("main_ins_struct.hrl").

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% @doc 进入活动副本
handle_client(?MSG_ENTER_CLIENT_INS, {Type}) ->
    case sky_service:is_open() of
        ?TRUE ->
            case get(?pd_sky_ins_tab) of
                0 -> ?return_err(?ERR_NOT_OPEN_FUN);
                SkyInsTab ->
                    SceneId = sky_mng:enter_scene(Type),
                    EndTime = sky_service:get_end_time(),
                    put(?pd_sky_ins_tab, SkyInsTab#player_sky_ins_tab{join_time = EndTime}),
                    ?player_send(sky_ins_sproto:pkg_msg(?MSG_ENTER_CLIENT_INS, {SceneId}))
            end;
        ?FALSE -> ?return_err(?ERR_NOT_OPEN_FUN)
    end;

handle_client(?MSG_SKY_INS_RANK, {}) ->
    FunFoldl = fun(MonsterId, {MonsterInfo, Rank}) ->
        case sky_service:get_box_info(MonsterId) of
            [] ->
                {MonsterInfo, Rank + 1};
            [SkyInsBox] ->
                {[{Rank + 1, SkyInsBox#sky_ins_kill_box.player_career,
                    SkyInsBox#sky_ins_kill_box.player_id,
                    SkyInsBox#sky_ins_kill_box.player_name,
                    SkyInsBox#sky_ins_kill_box.player_level, []} | MonsterInfo],
                    Rank + 1}
        end
    end,
    {RankList, _} = lists:foldl(FunFoldl, {[], 0}, ?SKY_INS_BOX_MONSTER_IDS),
    ?player_send(sky_ins_sproto:pkg_msg(?MSG_SKY_INS_RANK, {lists:reverse(RankList)}));


handle_client(?MSG_SKY_INS_BOX_LEVEL, {}) ->
    Level = sky_service:get_box_level(),
    ?player_send(sky_ins_sproto:pkg_msg(?MSG_SKY_INS_BOX_LEVEL, {Level}));

handle_client(_Msg, _Arg) ->
    ok.



%% This file is a header for player gen_server.
-ifndef(PLAYER_HRL).
-define(PLAYER_HRL, 1).

-include("player_def.hrl").
-include("../../auto/proto/inc.hrl").

-define(all_player_eng_mods(), [timer_eng, event_eng, limit_value_eng]).
%% TODO auto gen
-define(all_player_logic_mods(),
    [
        player_mng,
        player_base_data,
%%        auction_mng,
        skill_mng,
        scene_mng,
        gem_mng,
        shop_mng,
        mail_mng,
        task_mng_new,
        main_instance_mng,
%%        crown_mng,
        crown_new_mng,
        achievement_mng,
        % arena_system,
        arena_mng,
        %pet_mng,
        friend_mng,
        guild_mng,
        card_mng,
        mall_mng,
        %seller_mng,
        title_mng,
        camp_mng,
        abyss_mng,
        daily_activity_mng,
        sky_mng,
        alchemy_mng,
        team_mng,
        course_mng,
        system_log,
        phase_achievement_mng,
        honest_user_mng,
        main_star_shop_mng,
        pet_new_mng,
        ride_mng,
        gongcheng_mng,
        equipment_mng,
        bounty_mng,
        open_server_happy_mng,
        vip_new_mng,
        recharge_reward_mng,
        nine_lottery_mng,
        impact_ranking_list_handle_client,
        guild_mining_mng,
        server_login_prize_mng
    ]).
-define(tcp_send(Data), robot_eng:tcp_send(Data)).

%% 存放某个技能的cd 配置时间
%%-define(pd_skill_cd(SkillId), {pd_skill_cd, SkillId}).

%% 存放某个技能的最后释放时间
-define(pd_release_skill_time(SkillId), {pd_release_skill_time, SkillId}).

-define(player_send(Data), player:player_send(Data)).
-define(player_send_err(__CmdId, __ErrCode),
    (fun() ->
        %% Uncomment the following line if you need it.
        case player_eng:tcp_send(<<?MSG_PLAYER_ERROR:16, __CmdId:16, __ErrCode:16>>) of
            ok ->
                pass;
                % ?DEBUG_LOG("send errer msg ~p, errCode= ~p ", [proto_info:to_s(__CmdId), err_info_def:err_code_to_s(__ErrCode)]);
            __Why ->
                ?WARN_LOG("send errer msg failed ~p Cmd= ~p, errCode= ~p ", [__Why, proto_info:to_s(__CmdId), err_info_def:err_code_to_s(__ErrCode)])
        end
    end())).

-define(player_send_err(__CmdId, __ErrCode, __Arg),
    (fun() ->
        %% Uncomment the following line if you need it.
        case player_eng:tcp_send(<<?MSG_PLAYER_ERROR:16, __CmdId:16, __ErrCode:16, __Arg/binary>>) of
            ok -> ok;
            __Why ->
                ?WARN_LOG("send errer msg failed ~p Cmd= ~p, errCode= ~p ", [__Why, proto_info:to_s(__CmdId), err_info_def:err_code_to_s(__ErrCode)])
        end
    end())).

-endif.

%% 群聊频道
-define(CHAT_WORLD, 1).   %世界频道
-define(CHAT_SCENE, 2).   %场景频道
-define(CHAT_GUILD, 3).   %帮会频道
-define(CHAT_TEAM, 4).   %队伍频道
-define(CHAT_HORN, 5).   %喇叭频道

%% 单聊频道
-define(CHAT_P2P_NORMAL, 1).   %世界频道
-define(CHAT_P2P_FERIEND, 2).   %好友频道
-define(CHAT_P2P_FERIEND_SYS, 3).   %好友系统频道

%% 掉线原因
-define(OFFLINE_KICKOUT_MSG, 1).    %% 被踢下线

-define(LONGWEN_COST_ID, 23).

-record(zip_keys_data,
{
    keys_00 = <<0:1, 0:31>>,
    vals_00 = [],
    keys_01 = <<1:1, 0:31>>,
    vals_01 = []
}).

-define(SHARE_GAME, 1).        %% 分享游戏
-define(PRIZE_SHARE_GAME, 2).  %% 分享游戏领奖

-define(REPLY_SHARE_GAME_OK, 0).       %% 成功
-define(REPLY_SHARE_GAME_1, 1).        %% 未分享
-define(REPLY_SHARE_GAME_2, 2).        %% 已领奖
-define(REPLY_SHARE_GAME_255, 255).    %% 类型错误



%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午5:08
%%%-------------------------------------------------------------------
-author("clark").

-include("inc.hrl").

%% 插件字段
-define(room_ref_unknown,               0).     %% 未知接口
-define(room_ref_scene_plug,            1).     %% 场景插件
-define(room_ref_enter_plug,            2).     %% 进入插件
-define(room_ref_complete_plug,         3).     %% 结算插件
-define(room_ref_kill_plug,             4).     %% 杀怪插件
-define(room_ref_mopup_plug,            5).     %% 扫荡插件
-define(room_ref_chapter_prize,         6).     %% 章节奖励插件
-define(room_ref_client_start,          7).     %% 单机副本插件
-define(room_ref_team_create,           8).     %% 组队副本房间创建插件
-define(room_ref_team_start,            9).     %% 开始组队副本插件
-define(room_ref_team_quick_join,       10).    %% 快速加入组队副本插件
-define(room_ref_leave_team,            11).    %% 离开组队副本插件
-define(room_ref_team_kickout,          12).    %% 组队副本踢出队友插件
-define(room_ref_team_dissolve,         13).    %% 解散队伍插件
-define(room_ref_rand_start,            14).    %% 进入随机副本插件
-define(room_ref_shop_plug,             15).    %% 副本商店插件
-define(room_ref_enter_next,            16).    %% 进入下一个场景插件
-define(room_ref_course_plug,           17).    %% 战争学院插件
-define(room_ref_wizard_plug,           18).    %% 新手引导副本插件
-define(room_ref_camp_plug,             19).    %% 神魔争霸插件
-define(room_ref_abyss_plug,            20).    %% 深渊副本插件
-define(room_ref_rank_info,             21).    %% 副本排行榜插件
-define(room_ref_com_start_fight_plug,  22).    %% 公共的开始战斗插件



%% 数据字段
-define(room_data_unknown,              0).     %% 未知数据
-define(room_data_cfg_id,               1).     %% 配置表ID


%% 房间结构
-record(room_struct,
{
    scene_id                            = 0,    %% 副本表第一个场景
    room_master_id                      = 0,    %% player_id or team_id
    room_type                           = 0,    %% 副本类型，1主线副本 2自由副本 3神魔 4虚空 6天空之城随机 7天空之城迷宫  8日常活动
    query_interface                     = [],   %% COM接口, 用户可以通过此函数来查询组件是否支持某个特定的接口, 若无则返回none
    room_data                           = []    %% 副本数据
}).

%%  副本模块回复码
-define(REPLY_MSG_MAIN_INSTANCE_RAND_START_OK, 0).
-define(REPLY_MSG_MAIN_INSTANCE_RAND_START_1, 1).     %% 没有找到对应的物品
-define(REPLY_MSG_MAIN_INSTANCE_RAND_START_2, 2).     %% 消耗不足
-define(REPLY_MSG_MAIN_INSTANCE_RAND_START_255, 255).   %% 进入随机副本异常

%%-define(main_instance_id_ing, main_instance_id_ing).
%%-define(current_pata_instance_id, current_pata_instance_id).
%%-define(maining_instance_lianji_count, maining_instance_lianji_count).
%%-define(maining_instance_shouji_count, maining_instance_shouji_count).

%% 断言执行函数的进程类型
-define(player_proc(), ?assert(?ptype() =:= ?PT_PLAYER)).
-define(team_gen_proc(), ?assert(?ptype() =:= ?MODULE)).

-define(PKG_MSG, main_instance_sproto:pkg_msg).

-define(teamroom_wait_ets, teamroom_wait_ets). %% room{} 所有等待的房间
-define(teamroom_start_can_join_ets, teamroom_start_can_join_ets). %% room{} 所有开始的房间, 可以quick_join
-define(teamroom_start_cannot_join_ets, teamroom_start_cannot_join_ets). %% room{} 所有开始的房间,不能quick_join
-define(teamroom_player_ets, teamroom_player_ets). %% {PlayerId, roomId} 玩家如果在房间,会存放一个object

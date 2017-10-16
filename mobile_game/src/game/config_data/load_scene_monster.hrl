%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 十一月 2015 下午3:54
%%%-------------------------------------------------------------------
-author("clark").


-include("scene.hrl").
-include("scene_monster_def.hrl").


-record(monster_new_cfg,
{
    id,
    type = ?MT_NORMAL, %% 怪物类型
    mtype = 1,
    party = ?PK_MONSTER, %% | {pk_mode, } TODO


    level = 1, % monster level
    attr,

    ba_ti = 0, %% FALSE %% 是否是永久霸体

    stroll_range = 0, % 闲逛 0 是不闲逛
    chase_range = 0,  % 最大追击距离，　0不追击
    is_strike_back = false, %% bool 遭到攻击时是否反击

    guard_range = 0, %% 主动攻击区域，以出生点为中心 0不主动攻击

    skills = [], %% [{spellId, random}]
    relive = {0, 2}, % -1是无限复活 {复活次数, 复活间隔秒}
    death_cmds = [],

    drop = none,
    back_range = 5,  % unused 最大离开出生点距离

    model_box_id, %% 模型大小

    range = 4,  % unused 视野范围
    chase_speed = 1.0, % unused 在speed 上的加成
    show_group = none
    , can_beat_fly = 0   %% 是否可以被击飞或浮空
    , can_beat_back = 0   %% 是否可以被击退
    , can_beat_down = 0   %% 是否可以被击倒
    , getup_time = 0   %% 起身时间(ms
    , getup_flag = 0   %% 起身时携带的标记 无0 无敌1 霸体2
    , monster_exp = 0   %% 怪物经验
    , can_destroy = 0   %% 是否可被摧毁
    , has_hp_bar = 0   %% 是否显示血条
    , is_air = 0 %% 是否空中怪
    , abyss_integral = 0    %% 虚空深渊怪物积分
}).


%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 十月 2015 上午10:33
%%%-------------------------------------------------------------------
-author("clark").

%% 技能段配置表
-record(skill_cfg,
{
    id,
    cd, % 技能段cb时间毫秒
    client_name,
    global_cd, %公共cd unused
    release_range = {0, 3}, %% {X, Y} 在X ~ Y 距离内可释放
    render_time = 1000, %% 技能的整个动画时间
    hard_time = 0, %% 僵直时间
    rush = 0,
    rush_height = 0, %% 冲锋高度
    rush_speed = none,
    delay = none, %% 释放技能延迟　毫秒
    move_grid = none, %% unused 释放技能前先移动的格子瞬间移动

    %0=无，1=挑空，2=击飞 ,3=直接倒地
    %%launch_type = 0, %% stiff type 0 just monster

    hit_area, %% [{Delay, Lx,Ty,Rx,Dy,TH,Dh}]
    base_hit = 0, %% 基础伤害
    pure_hit = 0, %% 无视防御伤害
    skill_coe, %% 技能系数
    var_coe, %% 变量系数
    attr_type, %% 职业主属性
    m = none,   %% 普通伤害系数
    beat_fly_dist = 0,  %% 击飞距离
    beat_back_dist = 0, %% 击退距离格子数
    beat_back_speed = 0, %% 击退每格移动的毫秒数
    beat_height = 0, %% 击飞高度
    beat_air_stay_time = 0, %%滞空时间ms

    hit_repeat_time = 0, %% 攻击重复次数
    hit_repeat_interval, %% 每次重复间隔时间 毫秒
    hit_repeat_is_follow = 0, %% 每次重复伤害时，是以当前玩家的位置,还以第一次释放是位置 -- 已作废

    break_pri, %%
    breaked_pri,

    buffs = [], %% buffId
    %%buff_object=1, %% buff作用的对象, 1自己,2敌人,3友军

    link = none,
    ba_ti = 0, %% 是否技能是的霸体时间毫秒

    release_limit = 0, %% 释放限制
    release_height_limit = 0, %% 释放高度限制
    career_limit, %% 职业限制
    level_limit, %% 得到技能的最低等级
    upgrade_cost = 1, %% 升级消耗 默认1为空消耗
    cost_mp = 0,          %%使用技能消耗
    gain_anger = 0,        %%使用技能得到多少怒气(皇冠)
    release_objs = [],
    skill_bias          %%技能属性偏向
}).

-record(skill_release_obj_cfg,
{
    id,
    delay = 0, %% 移动前的延迟
    born_point,%%{X, Y, h} 默认向右
    speed, %% X
    move_grid, %% 移动的距离
    size %% {x,y,h} 中心点，半径
}).


-record(player_skill_tab,
{id,
    skills = [],
    dressed_skills = [], %% {index, skillId}
    dress_group_id = 1, %目前装备的技能组
    long_wens = [],
    skills_reset_times = []
}).

-define(player_skill_tab, player_skill_tab).
%%-record(spell_hit_cfg, {id, %{SpellId, D}
%%points }).


-record(skill_modify_cfg,
{
    %% 功能ID
    id = 0,

    client_name = [],

    %% 类型(cd=1, prop1(固定值）=2, prop2(千分比)=3, buff=4, 5减少耗蓝)
    type = 0,

    trigger_type = 0,

    client_trigger_condi = 0,

    %% 关联技能
    skill = 0,

    %% 关联技能段
    segment = 0,

    %% 变化
    cd = 0,

    prop_target_type = 0,

    %% 固定属性变化
    prop = 0,

    %% 千分比属性变化
    coef_prop = 0,

    svr_prop = 0,

    svr_coef_prop = 0,

%%    client_buff_target_type = 0,
    buff_target_type = 0,

    %% buff变化
    buff = 0,

    %% mp变化
    mp = 0,

    anger = 0,

    client_normal = 0,

    client_coef_damage = 0,

    client_desc = 0


}).


-record(long_wen_cfg,
{
    id, %%
    lev,
    skill, %% 技能ｉｄ
    unlock_level, %% 解锁等级
    cost = 1, %% 添加的消耗 默认1为空消耗
    skill_modifications = []
}).


-record(skills_org_cfg,
{
    id
    ,key
    ,type
    ,level_limit
    ,career_limit
    ,move_type
    ,cast_limit
    ,cast_height_limit
    ,carry_bati
    ,priority
    ,anchor_cast
    ,attack_priority
    ,cd
    ,priority_cd
    ,segments = []
    ,damage_coef
    ,main_prop_id
    ,prop_coef
    ,base_damage
    ,skill_coef
    ,release_range
    ,server_cost_mp
    ,server_gain_anger
}).
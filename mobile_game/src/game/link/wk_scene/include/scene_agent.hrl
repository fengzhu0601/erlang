-include("scene_agent_def.hrl").

%% 目的地的移动数据
-record(move_vec,
{
    reason %% move_reason

    , skill_move_timer = none
    , x_timer = none
    , y_timer = none
    , h_timer = none

    , x_vec = 0    %% 待移动量
    , y_vec = 0    %% 待移动量
    , h_vec = 0    %% 待移动量

    , x_speed
    , y_speed
    , h_speed
    , cfg_speed = 0 %% 原始速度
    , hug_time = 0 %% 上挑
}).

-record(move_obj,
{
    id,
    type,
    x, y, h,
    d,
    p_block_id,
    move_vec,
    info
}).


-record(fsm_state,
{
    pre_state_id = nil,
    cur_state_id = nil,
    client_state = nil
}).

-record(pl_ba_ti_info,
{
    bati_end_tm = 0
}).
-record(pl_stiff_info,
{
    stiff_end_tm = 0
}).
-record(pl_attack_info,
{
    skill_id = 0
}).


-record(buff_state, {buffType=0,buffTime=0,ref}).

-record(agent,
{
    idx,
    pid, % 对于monster pid 存放index, % 宠物存放playerid
    type,

    id,
    x,      %% 当前位置
    y,      %% 当前位置
    h,      %% 高度
    d,      %% direction

    rx, ry, %% 视野长度 %% 怪物的用来存grund_range
    view_blocks,
    view_totle_player = 1,  %同场景看到的玩家最大数量
    p_block_id,

    hp = 1000,
    hudun_hp = 0,
    max_hp = 1000,

    mp = 1000,
    max_mp = 1000,

    anger_value = 0,
    max_anger_value = 200,

    attr, %%

    move_vec = none, % | {Ref, Steps} ReF = none 时　说明是first move step | {Ref, none} monster stroll
    % 当腾空时格式为{Ref, fly_move_step} | {Ref, Steps, Oldspeed}
    %%speed_vec= 500, % 这个值会被更新的，在这只是个防御性赋值

    is_unbeatable = false, %% 是否可以被攻击
    is_ba_ti = false,

    skill_time = none,
    state = none, %% die
    state_timer = none, %%  ?none | {ss_stiff, NTRef, NewStiffEndTime} | TRef

    stiff_state = none :: agent_ss_state(), %%% 僵直的状态,
    %%stiff_state_timer = none,


    level = erlang:exit(need_level),
    % player {Pk_mode, Playerid, team_id, family_id, nation_id, evil}
    % monster {monster, -1 %pary}
    % 玩家召唤{player_call, playerId, teamId, family_id, nationId}
%%         pk_info = erlang:exit(need_pk_info),
    pk_info = none,
    %jump  = 500,
    %armor = ?ARMOR_NONE,
    %relation, %% {player_id()|monster_cfg_id(), _, _}
    %stiff = none,

    enter_view_info = <<>>,
%% <<0,0,0,0,0,0,0,2,18,232,169,185,230,163,174,229,133,139,233,135,140,231,144,
%% 180,230,150,175,2,100,0,0,0>>

    ex,
    psychic_state = none,

    attack_time = none,
    stiff_time = none,
    segment_cartoon_time = none,
    eft_list = [], %% 装备特效
    cardId = 0,     %% 变身卡牌的ID
    rideId = 0    %% 坐骑ID
    ,party = 0
    ,ai_flag = 0

    %% ----------------------
    , login_num = 0
    , pl_cur_state_plugs = [] %%[mod,mod,mod]
    , pl_ba_ti_info = #pl_ba_ti_info{}
    , pl_deat_info = none
    , pl_stiff = #pl_stiff_info{}
    , pl_attack = #pl_attack_info{}
    , bullet_attack_timer = none
    , pl_be_freedown = true
    , pl_del_timer = none
    , pl_bullet_box = none
    , fidx = none
    , pl_from_skill = none
    , pre_recover_mp_tm = none
    , show_player_count = 10

    % buff的信息
    , buff_states =[]
    , skill_modifies =[]        %% 技能修改集id列表
    , skill_modifies_effects = []   %% 技能修改集作用效果
    , room_obj_flag = nil       %% 房间标志
    , relaxation_check_timer = nil

    % 性格
    , character = []
    , born_x = 0
    , born_y = 0
    , debug_x = 0
    , debug_y = 0
    , dizzy_time = 0
}).



-type agent() :: #agent{}.


-define(change_stiff_st(St), stiff_state = St).



%% 所有agent 存入　
%% {agent, Idx} : Agent
-define(agent_new(Idx, Agent), ?undefined = erlang:put({agent, Idx}, Agent)).
-define(get_agent(Idx), erlang:get({agent, Idx})).
-define(update_agent(Idx, Agent), erlang:put({agent, Idx}, Agent)).
%%debug
%%-define(update_agent(Idx, Agent), (fun() ->
%%                                            if Idx > 0 ->
%%                                                   ?DEBUG_LOG("Idx ~p update agent", [Idx]);
%%                                               true -> ok
%%                                            end,
%%erlang:put({agent, Idx}, (Agent))
%%end)()).

-define(del_agent(Idx), erlang:erase({agent, Idx})).
-define(agent_state(__A), (__A#agent.state)).



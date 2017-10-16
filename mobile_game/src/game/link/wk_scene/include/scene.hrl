-include("scene_cfg_struct.hrl").
-include("scene_def.hrl").

-define(ADD_HP_MP_CD, misc_cfg:get_misc_cfg(add_hp_mp_cfg)).   %% 加hp/mp按钮cd时间(单位s)


%%-define(update_agent(Idx, Agent), update_agent__(Idx, Agent)).
%%update_agent__(Idx, #agent{idx=Idx}=A) ->
%%%?ifdo(Idx =:= 1, ?DEBUG_LOG("updateaget 1 view_me_agents:~p ", [A#agent.view_me_agents])),
%%erlang:put({agent, Idx}, A),
%%ok.

%%{pk_mode, []}

-define(KEEP_MOVEING, 125).
-define(is_keep_moveing(_X), (abs(_X) =:= ?KEEP_MOVEING)).

-define(PK_MONSTER, 11). %怪物模式, 只有怪物使用

-define(make_player_pk_info(PkMode, PlayerId, TeamId, FamilyId),
    {PkMode, PlayerId, TeamId, FamilyId}).

-define(make_monster_pk_info(V), {monster, V}).

-define(pk_info_get_player_id(Info), erlang:element(2, Info)).
-define(pk_info_get_team_id(Info), erlang:element(3, Info)).
-define(pk_info_get_pk_mode(Info), erlang:element(1, Info)).

-define(pk_info_set_pk_mode(M, Info), erlang:setelement(1, Info, M)).

%%-define(pd_chase_spell(Idx), {pd_chase_spell, Idx}). %% 追击后释放的一个技能 {SpellId, Range}


%% 地图 block id
-type idx() :: integer().
-type block_id() :: {integer(), integer()}.


%% monster 的出生点
-define(pd_monster_born(Index), {pd_monster_born, Index}). % {x,Y}
-define(get_monster_bron(Index), get({pd_monster_born, Index})).

%% monster die const
-define(pd_monster_die_count(Index), {pd_monster_die_count, Index}).


-define(D_DELTA(D),
    case D of
        ?D_U ->
            {0, -1};
        ?D_D ->
            {0, 1};
        ?D_L ->
            {-1, 0};
        ?D_R ->
            {1, 0};
        ?D_LU ->
            {-0.707, -0.707};
        ?D_LD ->
            {-0.707, 0.707};
        ?D_RU ->
            {0.707, -0.707};
        ?D_RD ->
            {0.707, 0.707}
    end).


%% 下一步的超时时间
-define(next_45_angle_step_time(T), (round(?speed_gms(T) * 1.4))).
-define(next_step_time(T), ?speed_gms(T)).


%% process direction

%% ETS
%% player_id -> idx
-define(player_idx(__PlayerId), {player_idx, __PlayerId}).

-define(pet_idx(__Index), {pet_idx, __Index}).%% __Index = {PlayerID, PetID}
%% index -> monster_idx
-define(monster_idx(__Index), {monster_idx, __Index}).


-define(get_player_max_id(), (erlang:get(?pd_player_max_id))).
-define(get_monster_max_id(), (erlang:get(?pd_monster_max_id))).


%% + 视野划分区块假设 前台最大显示大小为 1400 X 900
%%   地图每个格子的像素为36X36
%%   划分一个视野块为 最大屏幕的/3
%%  80 X 48, point 从0，0开始
-define(BLOCK_W, 10).
-define(BLOCK_H, 10).
-define(GRID_PIX, 32). %% 一格的像素


% H= 7 grid
% T = 0.0473
-define(JUMP_HIGHT, 7).
-define(JUMP_V, 295.983087). % v = 2h/t = 2 * 13 / 0.0947 因为速度的单位为10s
-define(JUMP_G, 6257.57055). % g = v/t

%%-define(FREELY_FALL_BASE_TIME, 255.4402).
-define(JUMP_GRID_TIMEOUT, 71). %% 每格移动时间(匀速)ms T / H

-define(DEFALUT_FLY_MOVE_SPEED, 100). %% 空中移动速度

%%% 战斗相关
-define(pd_agent_hurt_cb(__Idx), {pd_agent_hurt_cb, __Idx}). %% 伤害回调
-define(pd_agent_die_cb(__Idx), {pd_agent_die_cb, __Idx}). %% 死亡时回调


-define(ATT_NORMAL, 0).
-define(ATT_BLOCK, 1). % 格挡
-define(ATT_CRIT, 2). %暴击


%-define(ALL_PK_MODES, [?PK_ALL, ?PK_TEAM, ?PK_FAMILY, ?PK_NATION, ?PK_GOOD_BAD, ?PK_PEACE]).

-define(BUFF_OBJ_SELF, 1). %% 自己
-define(BUFF_OBJ_ENEMY, 2). %% 敌人
-define(BUFF_OBJ_FRIEND, 3). %% 友军


%% 场景人物插件
-define(pd_player_plugin, pd_player_plugin).


-define(pd_convoy_npc(__Idx), {pd_convoy_npc, __Idx}).




%% 加hp/mp部分
-define(ADD_TYPE_HP_MP_TYPE, 1).   %% 加满hp/mp
-define(ADD_TYPE_BUFF_TYPE, 2).   %% 使用buff加


%% 龙纹释放 buff id的 临时存储, 用于击中敌方
-define(long_wen_release_buff, long_wen_release_buff).

% 因为技能有很多重复动作, 用这个值来判断buff只中一次
-define(release_skill_state, release_skill_state).

% 技能附带的龙纹
-define(release_skill_long_wens, release_skill_long_wens).


-define(fight_pet_new_on_scene, fight_pet_new_on_scene).
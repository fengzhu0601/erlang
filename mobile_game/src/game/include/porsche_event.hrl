%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 四月 2016 下午6:22
%%%-------------------------------------------------------------------
-author("clark").




%% 规则改变状态
-record(rule_set_state, {gearbox_id=0, to_id = 0}).

%% 规则进入状态
-record(rule_enter_state, {gearbox_id=0, to_id = 0}).

%% 规则退出状态
-record(rule_exit_state, {gearbox_id=0, from_id=0}).

%% 用户规则
-record(rule_user_evt, {gearbox_id=0, state_id=0, evt_id=0}).

%% 用户规则
-record(rule_callback_begine, {gearbox_id=0, evt=0}).

%% 用户规则
-record(rule_callback_end, {gearbox_id=0, evt=0}).

%% 房间建造完毕
-record(room_new_end, {}).

%% 房间开始删除
-record(room_delete_start, {}).

%% 用户进入房间
-record(room_enter_room, {player_idx=0}).

%% 用户退出房间
-record(room_exit_room, {player_idx=0}).

%% 房间建造完毕
-record(room_delete_end, {}).

%% 玩家移动
-record(player_move, {}).

%% 怪物死亡
-record(monster_die, {killer, die}).

%% 玩家死亡
-record(player_die, {killer, die}).

%% 玩家复活
-record(player_revive, {}).

%% 设置移动
-record(agent_move_over, {idx=0}).

%% 怪物休闲
-record(agent_relaxation, {idx=0}).

%% 伤害包
-record(damaged_bag, {attacker, defender, damage}).


%% 伤害包
-record(skill_over, {idx=0, segment=0}).

%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 九月 2015 下午2:30
%%%-------------------------------------------------------------------
-module(fight_interface).
-author("clark").

%% API
-export
([
]).


-include("inc.hrl").
-include("skill_struct.hrl").
-include("load_spirit_attr.hrl").

-include("scene.hrl").
-include("scene_agent.hrl").
-include("scene_monster.hrl").


%% 进入施法状态
release_skill(#agent{idx = _Idx, x = _X, y = _Y, h = _H} = _A, _SkillId, _D, _Dx, _Dy, _Dh) -> ok.

%% 僵直状态
start_stiff_hard_time(#agent{idx = _OIdx} = _Attacker, _Skill, _StartT) -> ok.

%% 解除施法状态
cancle_releasing_skill(_Idx) -> ok.

%% 场景机关施放技能
device_release_skill(_DeviceId, _DevicePos, _HitPer, _SkillId) -> ok.






%% 计算是否格挡
is_block_attack(_LevRate, _AAttr, _BAttr) -> false.

%% 攻击
attack(#agent{level = _Level, x = _X, y = _Y, attr = _Attr} = _A,
    #agent{idx = _OIdx, hp = _OHp, x = _Ox, y = _Oy, h = _Oh, level = _OLevel, state = _State, stiff_state = _StiffSt, attr = _OAttr} = _Attacker,
    _Skill,
    _D) -> ok.

%% 机关能否攻击
device_is_can_attack(_FA) -> ok.

%% 机关攻击
device_attack(_DeviceId,
    #agent{idx = _OIdx, max_hp = _FullHp, hp = _OHp, x = _Ox, y = _Oy, h = _Oh, level = _OLevel, state = _State, stiff_state = _StiffSt, attr = _OAttr} = _Attacker,
    _HitPer, _Skill) -> ok.





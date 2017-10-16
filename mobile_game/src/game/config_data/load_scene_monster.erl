%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 十一月 2015 下午3:52
%%%-------------------------------------------------------------------
-module(load_scene_monster).
-author("clark").

%% API

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_scene_monster.hrl").
-include("load_spirit_attr.hrl").

-export
([
    can_beat_fly/1
    , can_beat_back/1
    , get_monster_hp/1
]).



load_config_meta() ->
    [
        #config_meta
        {
            record = #monster_new_cfg{},
            fields = ?record_fields(monster_new_cfg),
            file = "monster.txt",
            keypos = #monster_new_cfg.id,
            verify = fun verify/1
        }
    ].


verify(#monster_new_cfg{}) ->
    ok.

can_beat_fly(MonsterId) ->
    case load_scene_monster:lookup_monster_new_cfg(MonsterId) of
        #monster_new_cfg{} = MonsterCfg ->
            if
                0 == MonsterCfg#monster_new_cfg.can_beat_fly -> false;
                true -> true
            end;

        _ ->
            false
    end.

can_beat_back(MonsterId) ->
    case load_scene_monster:lookup_monster_new_cfg(MonsterId) of
        #monster_new_cfg{} = MonsterCfg ->
            if
                0 == MonsterCfg#monster_new_cfg.can_beat_back -> false;
                true -> true
            end;

        _ ->
            false
    end.

get_monster_hp(MonsterId) ->
    case load_scene_monster:lookup_monster_new_cfg(MonsterId) of
        #monster_new_cfg{attr = AttrId} ->
            case load_spirit_attr:get_attr(AttrId) of
                #attr{} = Attr -> Attr#attr.hp;
                nil -> 0
            end;

        _ ->
            false
    end.


%% verify(#monster_new_cfg{id=MonsterId, type=Type, is_strike_back=IsSb, can_beat_fly = CFly, can_beat_back = CBack, can_beat_down = CDown,
%%     model_box_id = ModelBoxId, getup_time = GTime, getup_flag = GFlag, monster_exp=_Exp, can_destroy=_CanDestory,
%%     has_hp_bar=HpBar}=R
%% ) ->
%%     ?check(com_util:is_valid_cli_bool(CFly), "monster.txt [~p] can_beat_fly [~w] 错误 ",[MonsterId, CFly]),
%%     ?check(com_util:is_valid_cli_bool(CBack), "monster.txt [~p] can_beat_back[~w] 错误 ",[MonsterId, CBack]),
%%     ?check(com_util:is_valid_cli_bool(CDown), "monster.txt [~p] can_beat_down [~w] 错误 ",[MonsterId, CDown]),
%%     ?check(is_integer(GTime) andalso GTime>= 0, "monster.txt [~p]  getup_time [~w] 错误 ",[MonsterId, GTime]),
%%     ?check(game_def:is_valid_ex_state(GFlag), "monster.txt [~p] getup_flag [~w] 错误 ",[MonsterId, GFlag]),
%%
%%     ?check(is_integer(R#monster_new_cfg.party), "monster[~p] party 无效", [MonsterId]),
%%
%%     ?check(scene_monster_def:is_valid_mon_type(Type), "monster.txt [~p] type ~p 无效类型", [MonsterId, Type]),
%%
%%     ?check(IsSb =:= ?TRUE orelse IsSb =:= ?FALSE, "monster.txt [~p] is_strike_back ~p 无效类型　必须是0 or 1", [MonsterId, IsSb]),
%%
%%     ChaseRange = R#monster_new_cfg.chase_range,
%%     ?check(ChaseRange >= 0, "monster[~p] chase_range ~p 无效!  >= 0", [MonsterId, ChaseRange]),
%%
%%     SR = R#monster_new_cfg.stroll_range,
%%     ?check(SR >=0,  "monster[~p] stroll_range 无效! 必须>=0 ", [MonsterId]),
%%
%%     SkillList = R#monster_new_cfg.skills,
%%     ?check(erlang:is_list(SkillList) , "monster[~p] skills ~p 无效不是list 形式 ", [MonsterId, SkillList]),
%%
%%     if IsSb ->
%%         ?check(SkillList =:= [] , "monster[~p] skills 不能为[]", [MonsterId]);
%%         true -> ok
%%     end,
%%
%%     %% 已经根据Random 排序 {20,A}, {40,B}, {70, C}, {100, D}
%%     Is100 =
%%         lists:foldl(fun({SkillId, Random}, Acc) ->
%%             ?check(load_cfg_skill:is_exist_skill_cfg(SkillId),  "monster[~p] skill id~p 无效无法找到", [MonsterId, SkillId]),
%%             ?check(Random > Acc,  "monster[~p] skill id ~p 概率无do_use_item([{friend_gift_qua,  EndQua}|T], {Item, ItemCfg, Num}, ItemList) ->
%% 效", [MonsterId, Random]),
%%             Random
%%         end,
%%             0,
%%             SkillList),
%%     if SkillList =/= [] ->
%%         ?check(Is100 =:= 100, "monster[~p] skills 概率总和不是 100 ~p ", [MonsterId, Is100]);
%%         true ->
%%             ok
%%     end,
%%
%%
%%     case R#monster_new_cfg.relive of
%%         {0, _} ->
%%             ok;
%%         {ReliveTimes, ReliveInterval} ->
%%             ?check(ReliveTimes >=-1 andalso ReliveInterval >= 1, "monster[~p] 的relive ~p 间隔时间 无效! ", [MonsterId, R#monster_new_cfg.relive]);
%%         _R ->
%%             ?check(false, "monster[~p] 的relive ~p 无效! ", [MonsterId, _R])
%%     end,
%%
%%
%%     CmdList = R#monster_new_cfg.death_cmds,
%%     ?check(erlang:is_list(CmdList), "monster[~p] death_cmds 无效不是list 形式", [MonsterId]),
%%
%%     lists:foreach(fun(CmdId) ->
%%         ?check(command:is_exist_command_cfg(CmdId),
%%             "monster[~p] death_cmds ~p 没有找到", [MonsterId, CmdId])
%%     end,
%%         CmdList),
%%
%%     ?check(load_spirit_attr:is_exist_attr(R#monster_new_cfg.attr), "monster[~p] 的attr没有找到!", [MonsterId]),
%%
%%     Level =R#monster_new_cfg.level,
%%     ?check(is_integer(Level) andalso Level > 0, "monster [~p] level ~p invailed ", [MonsterId, Level]),
%%
%%     Drop = R#monster_new_cfg.drop,
%%     ?check(Drop =:= none orelse scene_drop:is_exist_scene_drop_cfg(Drop), "monster [~p] drop ~p 不存在", [MonsterId, Drop]),
%%
%%     Mtype = R#monster_new_cfg.mtype,
%%     ?check(monster_group:is_exist_monster_mtype_cfg({Mtype, 1}), "monster [~p] mtype ~p 无效", [MonsterId, Mtype]),
%%
%%     ShowGroup = R#monster_new_cfg.show_group,
%%     ?check(ShowGroup =:= ?none orelse monster_show:is_exist_monster_show_group_cfg(ShowGroup), "monster [~p] show_group ~p 无效", [MonsterId, ShowGroup]),
%%
%%     ok.



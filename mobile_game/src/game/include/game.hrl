-ifndef(SYS_GAME).
-define(SYS_GAME, 1).

-include("type.hrl").

-define(AGREE, 1).
-define(DISAGREE, 0).

-define(send_to_client, send_to_client).



%% player_mod call
-define(player_mod_call(Mod, Msg), gen_server:call(player_eng, {mod, Mod, Msg}).
-define(player_mod_call(Mod, Msg, Timeout), gen_server:call(player_eng, {mod, Mod, Msg}, Timeout).

-define(mod_msg(Mod, Msg), {mod, Mod, ?MODULE, Msg}).
-define(send_mod_msg(Pid, Mod, Msg), Pid ! {mod, Mod, ?MODULE, Msg}).

-define(scene_mod_msg(Mod, Msg), {mod, Mod, Msg}).

%% -define(send_to_client(Pid, Msg), Pid ! {?send_to_client, Msg}).
-define(send_to_client(Pid, Msg), util:node_send_to_client(Pid, Msg)).
-define(to_client_msg(Msg), {?send_to_client, Msg}).




%% process type
-define(PT_SCENE, scene).
-define(PT_PLAYER, player).

-define(return(_Value), erlang:throw(_Value)).
-define(err(ErrCod), {error, {{where, ?MODULE, ?LINE}, ErrCod}}).
-define(err_match(__ErrCod), {error, {{where, _, _}, __ErrCod}}).
-define(return_err(Value), ?return(?err(Value))).

-define(ok(__Ok), {ok, {{where, ?MODULE, ?LINE}, __Ok}}).
-define(ok_match(__Ok), {ok, {{where, _, _}, __Ok}}).
-define(return_ok(__Ok), ?return(?ok(__Ok))).



-define(catch_return(__EXP), (fun() ->
    catch case __EXP of {'EXIT', ExitRason} -> exit(ExitRason); Ret -> Ret end end())).

%% todo in scene.hrl
-define(DEFAULT_ENTER_POINT, {-1, -1}).
%% 所有的 scene_id
%% -> scene().
%% main ins
%%-define(mk_scene_id_main_single(__SceneCfgId, __PlayerId), {__SceneCfgId, ?main_instance, {single, __PlayerId}}).
%%-define(mk_scene_id_main_team(__SceneCfgId, __RoomId),     {__SceneCfgId, ?main_instance, {team, __RoomId}}).

-define(scene_cfg_id(__SceneId), element(1, __SceneId)).


%%%% send to player msg
%%-define(add_exp_msg, add_exp_msg).
%%-define(add_item_msg, add_item_msg).
%%-define(kill_monster_add_exp, kill_monster_add_exp).


-define(add_item_msg(ItemList, Reason), ?mod_msg(player_mng, {?msg_add_item, ItemList, Reason})). % items list
-define(add_item_msg(ItemId, ItemCount, Reason), ?add_item_msg([{ItemId, ItemCount}], Reason)).
%%-define(add_item_msg(ItemId, ItemCount), {?mod_msg(player, {?add_item_msg, [{ItemId, ItemCount}]})})


%% Env
-ifdef(env_develop).

-define(ENV_develop(__Exp), __Exp).
-define(ENV_develop(__Exp1, __Exp2), __Exp1, __Exp2).

-define(ENV_product(__Exp), ok).

-else.

-ifdef(env_product).
-define(ENV_develop(__Exp), ok).
-define(ENV_develop(__Exp1, __Exp2), ok).

-define(ENV_product(__Exp), __Exp).
-endif.

-endif.




%% 定义所有需要共用的命名ETS
%%

%% 所有的存在的scene process
%% sup 负责创建
%% 每个scene process init call ets:insert, terminate  call delete
-define(ets_scene_processes, ets_scene_processes).  %% {SceneId, Pid}

%% ffsj  gloabl ets
-define(ets_server, ets_server).


%%% @doc 所有的事件类型
%% -define(ev_kill_monster, ev_kill_monster). % post arg = monster_id
%% -define(ev_collect_item, ev_collect_item). %% 采集 arg = itemId
%% -define(ev_died, ev_died). %% i'am died post arg = killed
%% -define(ev_kill_monster_exp_addition, ev_kill_monster_exp_addition). %% arg = AddExp reg is all
%% -define(ev_buy_item, ev_buy_item). %% 购买物品 arg {ItemId, Count}
%% -define(ev_complete_task, ev_complete_task). %% 完成任务
%% -define(ev_enter_scene, ev_enter_scene).%% 进入场景 arg=SceneId
%% -define(ev_leave_scene, ev_leave_scene).%% 离开场景 arg=SceneId
%% -define(ev_offline, ev_offline).%% arg=SceneId 下线
%% -define(ev_main_ins_pass, ev_main_ins_pass). %% 单人副本 arg=InstaceId



%% direction
%% 行走方向 不要改变顺序
-define(D_NONE, 0).
-define(D_U, 1). %^
-define(D_RU, 2). %
-define(D_R, 3).
-define(D_RD, 4).
-define(D_D, 5).
-define(D_LD, 6).
-define(D_L, 7).
-define(D_LU, 8).

-define(is_vaild_dir(D), ((D) > 0 andalso (D) < 9)).


%% 前端的背包index 到后端的index
-define(bpos_c2s(_N), ((_N) + 1)).
-define(bpos_s2c(_N), ((_N) - 1)).

%% 速度单位 1格/10秒. 每10秒一格
-define(SPEED_UNIT, 10).

%% 从定义的速度转化为多少毫秒一格
-define(speed_gms(_S), (10000 div _S)). %% SPEED_UNIT * 1000

%%%% 物品品质
%%-define(EQUIP_Q_WHITE  , 1).
%%-define(EQUIP_Q_BLUE   , 2).
%%-define(EQUIP_Q_PURPLE , 3).
%%-define(EQUIP_Q_GREEN  , 4).
%%-define(EQUIP_Q_ORANGE , 5).


%%%% 仓库类型
%%-define(BAG_TYPE, 1).
%%-define(DEPOT_TYPE, 2).

%%%% 物品类型
%%-define(IT_EQUIP, 1). %% 装备
%%-define(IT_GEM, 2). %% 宝石
%%-define(IT_OTHER, 3). %% 其他


%% 物品类型
%%-define(ITEM_TYPE_EQUIP, 1).
%%-define(ITEM_TYPE_GEM, 2).
%%-define(ITEM_TYPE_GOODS, 3).

-record(connect_state,
{
    name,
    wait
}).

-include("game_def.hrl").
-endif.

%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 皇冠系统
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(crown_mng).


%% TODO
%% 宝石
%% 存储
%% 附魔
%% 升级
%% 兑换
%% 宝石组合
%% 怒气值
%% 关联技能

-include_lib("pangzi/include/pangzi.hrl").
%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("load_cfg_crown.hrl").
-include("cost.hrl").
-include("load_phase_ac.hrl").

%% GM
-export([gm_add_gem/1, gm_add_pearl/1]).
%% API
-export
([
    add_gem/1,
    add_anger/1,
    is_full_anger/0,
    get_anger/0,
    clear_anger/0,
    collection_anger/1,
    add_gem/2,
    restore_crown/0,
    release_skill/1
]).

-record(crown_gem, {id = exit(<<"crown_gem require 'id' field">>),
    cfg_id = exit(<<"crown_gem require 'cfg_id' field">>),
    enchant_sats = []
}).

-record(?player_crown_tab, {id,
    gen_id = 1,
    anger = 0,
    dressed_gems = [],
    used_skill = [],
    mng = gb_trees:empty()
}).

%%-record(crown_skill_cfg, {id, %% id = lists:sum([#crown_gem_cfg.type,...])
%%    skill_id}).

%%-record(crown_gem_cfg, {
%%    type, %% 1 ice, 10 fire, 100 throuhgt
%%    level,
%%    upgrade_cost, %%
%%    sell_fragment, %% 兑换碎片的数量
%%    attr_id,
%%    bid, %% 用于前台
%%    enchant_cost, %% 附魔兑换
%%    enchant_sats%% random_sats_cfg 中的id
%%}).


%%-define(CROWN_CFG_FILE, "crown_gem.txt").
-define(DRESS_GEM_MAX_COUNT, 3).
-define(crown_anger_max_value, 200).


collection_anger(Anger) ->
    OldAnger = get(?pd_crown_anger),
    NewAnger = min(OldAnger ++ Anger, ?crown_anger_max_value),
    put(?pd_crown_anger, NewAnger),
    ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_ANGER_CHANGE, {NewAnger})).

add_anger(GainAnger) ->
    OldAnger = get(?pd_crown_anger),
    NewAnger = min(OldAnger + GainAnger, ?crown_anger_max_value),
    put(?pd_crown_anger, NewAnger),
    ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_ANGER_CHANGE, {NewAnger})).

is_full_anger() ->
    get_anger() >= ?crown_anger_max_value.

get_anger() ->
    get(?pd_crown_anger).

clear_anger() ->
    NewAnger = 0,
    put(?pd_crown_anger, NewAnger),
    ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_ANGER_CHANGE, {NewAnger})).

%%is_anger_skill(SkillID) ->
%%    lists:member(SkillID, lookup_all_crown_skill_cfg(#crown_skill_cfg.skill_id)).


gm_add_gem(GemCfgID) ->
    add_gem(GemCfgID).

gm_add_pearl(Pearl) ->
    player:add_pearl(Pearl).

%% @doc 添加一个宝石
add_gem(CfgId) ->
    case new_gem(CfgId) of
        {error, R} ->
            ?ERROR_LOG("new gem ~p ~p", [R, CfgId]);
        Gem ->
            mng_add_gem(Gem),
            ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_GEM_ADD, {Gem#crown_gem.id,
                Gem#crown_gem.cfg_id}))
    end.

add_gem(CfgId, Count) when Count > 0 ->
    add_gem(CfgId),
    add_gem(CfgId, Count - 1);

add_gem(_CfgId, 0) -> ok.

%%new_mng() ->
%%todo.

new_gem(CfgId) ->
    case load_cfg_crown:is_exist_crown_gem_cfg(CfgId) of
        ?false ->
            {error, <<"can not find cfg">>};
        ?true ->
            Id = next_gem_id(),
            #crown_gem{id = Id, cfg_id = CfgId}
    end.








load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_crown_tab,
            fields = ?record_fields(?player_crown_tab),
            shrink_size = 1,
            flush_interval = 3
        }
    ].


%% 玩家第一次登陆是调用
create_mod_data(SelfId) ->
    InitGem = gb_trees:empty(), %% init_gem_for_test(),
    PCT = #?player_crown_tab{id = SelfId, mng = InitGem},
    ?debug_log_crown("init_gem self ~p gems ~p", [SelfId, PCT]),
    case dbcache:insert_new(?player_crown_tab, PCT)
    of
        ?true -> ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_auction_tab not alread exists ", [SelfId])
    end,
    ok.

init_gem_for_test() ->
    crown_gems(gb_trees:empty()),
    crown_gem_id(1),
    Gem1 = new_gem(4011),
    Gem2 = new_gem(4012),
    Gem3 = new_gem(4013),
    Gem4 = new_gem(4021),
    Gem5 = new_gem(4031),
    mng_add_gem(Gem1),
    mng_add_gem(Gem2),
    mng_add_gem(Gem3),
    mng_add_gem(Gem4),
    mng_add_gem(Gem5),
    Gems = crown_gems(),
    erase(?pd_crown_gen_id),
    erase(?pd_crown_mng),
    erase(?pd_crown_dressed_gems),
    Gems.

crown_gems(Gems) ->
    put(?pd_crown_mng, Gems).

crown_gems() ->
    get(?pd_crown_mng).

crown_gem_id(ID) ->
    put(?pd_crown_gen_id, ID).

crown_gem_id() ->
    get(?pd_crown_gen_id).

next_gem_id() ->
    GemId = crown_gem_id(),
    NewId = (GemId + 1) band 16#FFFFFFFF,
    crown_gem_id(NewId),
    case gb_trees:is_defined(NewId, crown_gems()) of
        ?true ->
            next_gem_id();
        ?false ->
            NewId
    end.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_crown_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find auction_tab  mode", [PlayerId]),
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#?player_crown_tab{gen_id = GenId, anger = Anger, dressed_gems = Gems, mng = Mng,
            used_skill = UseSkill}] ->
            ?debug_log_crown("load_mod_data id ~p dress ~p mng ~p", [GenId, Gems, Mng]),
            ?pd_new(?pd_crown_anger, Anger),
            ?pd_new(?pd_crown_dressed_gems, Gems) %% list(Id)
            , ?pd_new(?pd_crown_mng, Mng) %% gb_trees
            , ?pd_new(?pd_crown_gen_id, GenId) %% u16
            , ?pd_new(?pd_crown_used_skill, UseSkill)
    end,
    ok.

init_client() ->
    ?debug_log_crown("init_client ~p ~p ~p", [get(?pd_id), get(?pd_crown_dressed_gems), gb_trees:to_list(get(?pd_crown_mng))]),
    ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_INIT_CLIENT,
        {get(?pd_crown_anger), [?r2t(Gem) || {_Key, Gem} <- gb_trees:to_list(get(?pd_crown_mng))],
            get(?pd_crown_dressed_gems)})),
    ok.


view_data(Acc) -> Acc.

online() -> ok.

save_data(_) ->
    dbcache:update(?player_crown_tab, #?player_crown_tab{id = get(?pd_id),
        gen_id = get(?pd_crown_gen_id),
        dressed_gems = get(?pd_crown_dressed_gems),
        used_skill = get(?pd_crown_used_skill),
        mng = get(?pd_crown_mng)
    }).

offline(_SelfId) ->
    ok.

handle_frame(_) -> todo.


mng_update_gem(#crown_gem{id = Id} = NewGem) ->
    put(?pd_crown_mng,
        gb_trees:enter(Id, NewGem, get(?pd_crown_mng))).

mng_add_gem(NewGem) ->
    mng_update_gem(NewGem).

mng_find_gem(GemId) ->
    case gb_trees:lookup(GemId, get(?pd_crown_mng)) of
        ?none -> ?none;
        {?value, Gem} -> Gem
    end.

is_gem_dressed(Id) ->
    lists:keymember(Id, 2, get(?pd_crown_dressed_gems)).

is_gem_position(Pos) ->
    lists:keymember(Pos, 1, get(?pd_crown_dressed_gems)).

%%还原人物身上的皇冠
restore_crown() ->
    %%%%获取人物身上的皇冠，它是个[{pos,id},{2,4}]这种形式的表
    DressedGemIds = get(?pd_crown_dressed_gems),
    %%如果皇冠满了加技能
    ?ifdo(length(DressedGemIds) >= ?DRESS_GEM_MAX_COUNT,
        dress_skill(DressedGemIds)),
    %%遍历人物身上的每个皇冠碎片，将它的战斗力加到人物身上
    lists:foreach(
        fun({_, Id}) ->
            ?ifdo(not is_gem_dressed(Id),
                ?return_err(?ERR_CROWN_GEM_NOT_DRESSED)),
            Gem = mng_find_gem(Id),
            AttrId = load_cfg_crown:lookup_crown_gem_cfg(Gem#crown_gem.cfg_id, #crown_gem_cfg.attr_id),
            AttrSat = attr_new:list_2_attr(Gem#crown_gem.enchant_sats),
            attr_new:player_add_attr(AttrSat),
            attr_new:player_add_attr_by_id(AttrId)
        end,
        DressedGemIds
    ).

undress_crown(Id) ->
    Gem = mng_find_gem(Id),
    DressedGemIds = get(?pd_crown_dressed_gems),
    ?ifdo(not is_gem_dressed(Id),
        ?return_err(?ERR_CROWN_GEM_NOT_DRESSED)),

    AttrId = load_cfg_crown:lookup_crown_gem_cfg(Gem#crown_gem.cfg_id, #crown_gem_cfg.attr_id),
    AttrSat = attr_new:list_2_attr(Gem#crown_gem.enchant_sats),
    attr_new:player_sub_attr(AttrSat),
    attr_new:player_sub_attr_by_id(AttrId),
    % player:sub_attr_by_sats(Gem#crown_gem.enchant_sats),
    % player:sub_attr_amend(AttrId),

    put(?pd_crown_dressed_gems,
        lists:keydelete(Id, 2, DressedGemIds)),

    %% 卸下技能
    ?ifdo(length(DressedGemIds) >= ?DRESS_GEM_MAX_COUNT,
        undress_skill(DressedGemIds)),
    ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_GEM_UNDRESS, {Id})),
    ok.

dress_gem(Gem, Pos, Id) ->
    DressedGemList = get(?pd_crown_dressed_gems),
    case length(DressedGemList) < ?DRESS_GEM_MAX_COUNT of
        true ->
            AttrId = load_cfg_crown:lookup_crown_gem_cfg(Gem#crown_gem.cfg_id, #crown_gem_cfg.attr_id),
            %%player:add_attr_by_sats(Gem#crown_gem.enchant_sats),
            %%player:add_attr_amend(AttrId),
            AttrSats = attr_new:list_2_attr(Gem#crown_gem.enchant_sats),
            attr_new:player_add_attr(AttrSats),
            attr_new:player_add_attr_by_id(AttrId),
            NewDressedGemList = [{Pos, Id} | DressedGemList],
            put(?pd_crown_dressed_gems, NewDressedGemList),
            ?ifdo(length(NewDressedGemList) >= ?DRESS_GEM_MAX_COUNT,
                dress_skill(NewDressedGemList)),
            ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_GEM_DRESS, {Pos, Id}));
        false ->
            ?return_err(?ERR_CROWN_SLOT_FULL)
    end.


replace_gem(Gem, Pos, Id) ->
    DressedGemIds = get(?pd_crown_dressed_gems),
    case lists:keyfind(Pos, 1, DressedGemIds) of
        ?false ->
            pass;
        {_, OldId} ->
            OldGem = mng_find_gem(OldId),
            AttrId = load_cfg_crown:lookup_crown_gem_cfg(OldGem#crown_gem.cfg_id, #crown_gem_cfg.attr_id),
            %%player:sub_attr_by_sats(OldGem#crown_gem.enchant_sats),
            %%player:sub_attr_amend(AttrId),
            AttrSats = attr_new:list_2_attr(Gem#crown_gem.enchant_sats),
            attr_new:player_sub_attr(AttrSats),
            attr_new:player_sub_attr_by_id(AttrId),
            put(?pd_crown_dressed_gems, lists:keydelete(Pos, 1, DressedGemIds)),
            dress_gem(Gem, Pos, Id)
    end.




handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_CROWN) of
        ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
        ?true -> handle_client(Pack, Arg)
    end.

%% %% 附魔
%% handle_client(?MSG_CROWN_GEM_ENCHANT, {Id}) ->
%%     #crown_gem{cfg_id = CfgId, enchant_sats = OldSats} =
%%         _Gem = mng_find_gem(Id),
%%     Cfg = load_cfg_crown:lookup_crown_gem_cfg(CfgId),
%%
%%     case cost:cost(Cfg#crown_gem_cfg.enchant_cost) of
%%         {error, W} ->
%%             ?ERROR_LOG("cost wrown gem:~p ~p", [Id, W]),
%%             ?player_send_err(?MSG_CROWN_GEM_ENCHANT, ?ERR_COST_NOT_ENOUGH);
%%         ok ->
%%             SatList = attr:random_sats(Cfg#crown_gem_cfg.enchant_sats),
%%             ?ifdo(is_gem_dressed(Id),
%%                 attr_new:begin_sync_attr(),
%%                 attr_change(OldSats, SatList)),
%%                 attr_new:end_sync_attr(),
%%
%%             mng_update_gem(_Gem#crown_gem{enchant_sats = SatList}),
%%             event_eng:post(?ev_crown_imbue, {?ev_crown_imbue, 0}, 1),
%%             ?debug_log_crown("gem_enchant ~p ~p", [Id, SatList]),
%%             event_eng:post( ?ev_crown_imbue, {?ev_crown_imbue,0}, 1 ),
%%             ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_GEM_ENCHANT, {Id, SatList}))
%%     end,
%%     ok;

%% 附魔(change lan)
% handle_client(?MSG_CROWN_GEM_ENCHANT, {Id}) ->
%     #crown_gem{cfg_id = CfgId, enchant_sats = OldSats} =
%         _Gem = mng_find_gem(Id),
%     Cfg = load_cfg_crown:lookup_crown_gem_cfg(CfgId),
%     case cost:lookup_cost_cfg(Cfg#crown_gem_cfg.enchant_cost) of
%         ?none -> {error, not_found_cost};
%         #cost_cfg{goods = GoodsList} ->
%             GoodsList1 = cost:do_cost_tp(GoodsList),
%             case game_res:can_del(GoodsList1) of
%                 {error, W} ->
%                     ?ERROR_LOG("cost wrown gem:~p ~p", [Id, W]),
%                     ?player_send_err(?MSG_CROWN_GEM_ENCHANT, ?ERR_COST_NOT_ENOUGH);
%                 ok ->
%                     game_res:del(GoodsList1),
%                     SatList = attr:random_sats(Cfg#crown_gem_cfg.enchant_sats),
%                     ?ifdo(is_gem_dressed(Id),
%                         attr_new:begin_sync_attr(),
%                         attr_change(OldSats, SatList)),
%                     attr_new:end_sync_attr(),

%                     mng_update_gem(_Gem#crown_gem{enchant_sats = SatList}),
%                     ?debug_log_crown("gem_enchant ~p ~p", [Id, SatList]),
%                     event_eng:post(?ev_crown_imbue, {?ev_crown_imbue, 0}, 1),
%                     daily_task_tgr:do_daily_task({?ev_crown_imbue, 0}, 1),
%                     ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_GEM_ENCHANT, {Id, SatList}))
%             end
%     end,
%     ok;


%% %% 升级
%% handle_client(?MSG_CROWN_GEM_UPGRADE, {Id}) ->
%%     #crown_gem{cfg_id = CfgId} = _Gem = mng_find_gem(Id),
%%     #crown_gem_cfg{upgrade_cost = CostId,
%%         level = _Level} = load_cfg_crown:lookup_crown_gem_cfg(CfgId),
%%     case cost:cost(CostId) of
%%         {error, W} ->
%%             ?ERROR_LOG("cost wrown gem:~p ~p", [Id, W]),
%%             ?player_send_err(?MSG_CROWN_GEM_UPGRADE, ?ERR_COST_NOT_ENOUGH);
%%         ok ->
%%             case load_cfg_crown:lookup_crown_gem_cfg(CfgId + 1) of
%%                 ?none ->
%%                     ?return_err(?ERR_CROWN_GEM_FULL_LEVEL);
%%                 #crown_gem_cfg{attr_id = NewAttrId} ->
%%                     OldAttrId = load_cfg_crown:lookup_crown_gem_cfg(CfgId, #crown_gem_cfg.attr_id),
%%                     mng_update_gem(_Gem#crown_gem{cfg_id = CfgId + 1}),
%%                     ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_GEM_UPGRADE, {Id})),
%%                     event_eng:post(?ev_crown_level, {?ev_crown_level, 0}, 1),
%%                     case is_gem_dressed(Id) of
%%                         true ->
%%                             attr_new:begin_sync_attr(),
%%                             %%player:sub_attr_amend(OldAttrId),
%%                             %%player:add_attr_amend(NewAttrId),
%%                             attr_new:player_sub_attr_by_id(OldAttrId),
%%                             attr_new:player_add_attr_by_id(NewAttrId),
%%                             attr_new:end_sync_attr();
%%                         false ->
%%                             ok
%%                     end
%%             end
%%     end;

%% 升级(change lan)
% handle_client(?MSG_CROWN_GEM_UPGRADE, {Id}) ->
%     #crown_gem{cfg_id = CfgId} = _Gem = mng_find_gem(Id),
%     #crown_gem_cfg{upgrade_cost = CostId,
%         level = _Level} = load_cfg_crown:lookup_crown_gem_cfg(CfgId),
%     case cost:lookup_cost_cfg(CostId) of
%         ?none -> {error, not_found_cost};
%         #cost_cfg{goods = GoodsList} ->
%             GoodsList1 = cost:do_cost_tp(GoodsList),
%             case game_res:can_del(GoodsList1) of
%                 {error, W} ->
%                     ?ERROR_LOG("cost wrown gem:~p ~p", [Id, W]),
%                     ?player_send_err(?MSG_CROWN_GEM_UPGRADE, ?ERR_COST_NOT_ENOUGH);
%                 ok ->
%                     game_res:del(GoodsList1),
%                     case load_cfg_crown:lookup_crown_gem_cfg(CfgId + 1) of
%                         ?none ->
%                             ?return_err(?ERR_CROWN_GEM_FULL_LEVEL);
%                         #crown_gem_cfg{attr_id = NewAttrId} ->
%                             OldAttrId = load_cfg_crown:lookup_crown_gem_cfg(CfgId, #crown_gem_cfg.attr_id),
%                             mng_update_gem(_Gem#crown_gem{cfg_id = CfgId + 1}),
%                             ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_GEM_UPGRADE, {Id})),
%                             event_eng:post(?ev_crown_level, {?ev_crown_level, 0}, 1),
%                             daily_task_tgr:do_daily_task({?ev_crown_level, 0}, 1),
%                             case is_gem_dressed(Id) of
%                                 true ->
%                                     attr_new:begin_sync_attr(),
%                                     %%player:sub_attr_amend(OldAttrId),
%                                     %%player:add_attr_amend(NewAttrId),
%                                     attr_new:player_sub_attr_by_id(OldAttrId),
%                                     attr_new:player_add_attr_by_id(NewAttrId),
%                                     attr_new:end_sync_attr();
%                                 false ->
%                                     ok
%                             end
%                     end
%             end
%     end;

%% 装备
handle_client(?MSG_CROWN_GEM_DRESS, {Pos, Id}) ->
    %?DEBUG_LOG("Pos------:~p------Id-----:~p",[Pos, Id]),
    Gem = mng_find_gem(Id),
    case is_gem_dressed(Id) orelse is_gem_position(Pos) of
        ?true ->
            %?DEBUG_LOG("replace-------------------------"),
            attr_new:begin_sync_attr(),
            replace_gem(Gem, Pos, Id),
            attr_new:end_sync_attr(),
            replace;
        ?false ->
            %?DEBUG_LOG("dress_gem--------------------------"),
            attr_new:begin_sync_attr(),
            dress_gem(Gem, Pos, Id),
            attr_new:end_sync_attr(),
            dress
    end,
    ok;


%% 卸下
handle_client(?MSG_CROWN_GEM_UNDRESS, {Id}) ->
    attr_new:begin_sync_attr(),
    undress_crown(Id),
    attr_new:end_sync_attr();

%% 兑换
handle_client(?MSG_CROWN_GEM_SELL, {IdList}) ->
    Fun = 
    fun(Id) ->
        ?ifdo(is_gem_dressed(Id),
            handle_msg(?MSG_CROWN_GEM_UNDRESS, {Id})),

        #crown_gem{cfg_id = CfgId} = mng_find_gem(Id),

        N = load_cfg_crown:lookup_crown_gem_cfg(CfgId, #crown_gem_cfg.sell_fragment),

        ?assertNot(is_gem_dressed(Id)),
        put(?pd_crown_mng, gb_trees:delete(Id, get(?pd_crown_mng))),
        event_eng:post(?ev_crown_exchange, {?ev_crown_exchange, 0}, 1),
        player:add_fragment(N)
    end,
    lists:foreach(Fun, IdList),
    daily_task_tgr:do_daily_task({?ev_crown_exchange, 0}, length(IdList)),
    ?player_send(crown_sproto:pkg_msg(?MSG_CROWN_GEM_SELL, {})),
    ok;

handle_client(_MSG, _) ->
    {error, unknown_msg}.

handle_msg(_FromMod, _Msg) ->
    {error, unknown_msg}.


release_skill(SkillID) ->
%%    List = util:get_pd_field(?pd_crown_used_skill, []),
%%%%    ?DEBUG_LOG("release skillid,List,ismember:~p",[{SkillID,List,lists:member(SkillID, List)}]),
%%    case lists:member(SkillID, List) of
%%        false ->
%%            phase_achievement_mng:do_pc(?PHASE_AC_HUANGGUAN_USE, 1),
%%            put(?pd_crown_used_skill, [SkillID | List]);
%%        true -> ok
%%    end,
    ok.

dress_skill(GemIds) ->
    ?DEBUG_LOG("GemIds----------------------------:~p",[GemIds]),
    SkillID = gem2skill(GemIds),
    ?ifdo(
        is_integer(SkillID),
        begin
            List = util:get_pd_field(?pd_crown_used_skill, []),
            case lists:member(SkillID, List) of
                false ->
                    phase_achievement_mng:do_pc(?PHASE_AC_HUANGGUAN_USE, 1),
                    put(?pd_crown_used_skill, [SkillID | List]);
                true -> ok
            end,
            skill_mng:add_skill(SkillID)
        end
    ).

undress_skill(QuondamGemIds) ->
    SkillID = gem2skill(QuondamGemIds),
    ?debug_log_crown("undress_skill ~p ~p", [QuondamGemIds, SkillID]),
    ?ifdo(is_integer(SkillID), skill_mng:del_skill(SkillID)).

%% GemIDS算出获得哪个技能(保证GemIids里的GemID都存在Gem数据)
gem2skill(GemIds) ->
    CrownSkillID = 
    com_lists:sum(fun({_Pos, Id}) ->
        Gem = mng_find_gem(Id),
%%        ?INFO_LOG("crown_gem:~p",[{Gem#crown_gem.cfg_id, #crown_gem_cfg.type}]),
        Type = load_cfg_crown:lookup_crown_gem_cfg(Gem#crown_gem.cfg_id, #crown_gem_cfg.type),
        case Type of
            1  -> 1;
            2 -> 10;
            3 -> 100
        end
    end, 
    GemIds),
%%    ?INFO_LOG("CrownSkillID:~p",[CrownSkillID]),
    load_cfg_crown:lookup_crown_skill_cfg(CrownSkillID, #crown_skill_cfg.skill_id).

attr_change(OldSats, SatList) ->
    case OldSats of
        ?none ->
            ignore;
        _ ->
            %player:sub_attr_amend(OldSats),
            OldAttr = attr_new:list_2_attr(OldSats),
            attr_new:player_sub_attr(OldAttr)
    end,
    case SatList of
        ?none ->
            ignore;
        _ ->
            SatAttr = attr_new:list_2_attr(SatList),
            attr_new:player_add_attr(SatAttr)
        %%player:add_attr_amend(SatList)
    end.

%% anger_skill() ->
%%     clear_anger(),
%%     anger_skill_effect(),
%%     ok.

%% anger_skill_effect() ->
%%     ok.

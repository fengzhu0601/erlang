%%%-------------------------------------------------------------------
%%% @author 余健
%%% @doc 玩家公会模块
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(guild_mng).

-include_lib("pangzi/include/pangzi.hrl").
%%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").

-include("day_reset.hrl").

-include("guild_define.hrl").
-include("achievement.hrl").
-include("load_phase_ac.hrl").
-include("load_cfg_guild.hrl").


-export([
    broadcast/1,                  % 公会聊天
    load_guild_data/0,           % 加载公会数据（上线时，或者被加入公会时）
    del_tech_attr/0,             % 退出公会，删除科技增加的属性
    add_tech_attr/2,             % 公会科技升级，增加属性
    get_guild_info/0,           % 获取公会信息
    get_guild_player_lv_and_exp_by_contribution/1
]).

-export([
    push_role_data/0,             % 推送公会中玩家变更信息
    push_guild_member_quit/3,    % 玩家离开公会推送信息给会长副会长
    push_guild_member_join/2,    % 玩家加入公会推送给会长副会长
    push_guild_member_position/2, %玩家职位变更推送给公会在线玩家
    push_guild_master_change/1,
    push_guild_saint_list/0
]).

-export([
    reset_guild_daily_task_count/0 %重置公会日常
]).



load_db_table_meta() ->
    [
        #db_table_meta{name = ?player_guild_member,
            fields = ?record_fields(?player_guild_member),
            shrink_size = 10,
            flush_interval = 10},

        #db_table_meta{name = ?player_guild_tech_buildings,
            fields = ?record_fields(?player_guild_tech_buildings),
            shrink_size = 10,
            flush_interval = 10},

        #db_table_meta{name = player_guild_is_join_guild,
            fields = ?record_fields(player_guild_is_join_guild),
            shrink_size = 10,
            flush_interval = 10},

        #db_table_meta{name = player_guild_count, % 重置
            fields = ?record_fields(player_guild_count),
            shrink_size = 10,
            flush_interval = 10},

        #db_table_meta{name = player_guild_saint_tab,
            fields = ?record_fields(player_guild_saint_tab),
            shrink_size = 10,
            flush_interval = 10}
    ].

create_mod_data(_SelfId) -> ok.

load_mod_data(_PlayerId) ->
    load_guild_data().

init_client() ->
    case ?is_join_guild() of
        true ->
            push_guild_saint_list(),
            guild_handle_client:handle_client({?MSG_GUILD_INFO, {}});
        false ->
            ?player_send(<<?MSG_GUILD_INFO, 0>>)
    end.

view_data(_Acc) ->
    case ?is_join_guild() of
        true ->
            {GuildName, BorderId, TotemId} = get_guild_info(),
            <<(byte_size(GuildName)):8, GuildName/binary, BorderId:8, TotemId:8>>;
        false ->
            <<0:8>>
    end.

get_guild_info() ->
    [Guild] = guild_service:lookup_tab(?guild_tab, get(?pd_guild_id)),
    {Guild#guild_tab.guild_name, Guild#guild_tab.border_id, Guild#guild_tab.totem_id}.

on_day_reset(_Player) ->
    util:set_pd_field(?pd_guild_boss_donate, 0),
    reset_guild_saint_list(),
    reset_guild_daily_task_count().

%% handle_frame(?frame_zero_clock) ->
%%     reset_guild_daily_task_count();

handle_frame(Frame) ->
    ?err({unknown_frame, Frame}).

handle_msg(_FromMod, {?position_change, ToPositionId}) ->
    ?ifdo(?is_join_guild(),
        put(?pd_guild_position, ToPositionId));

handle_msg(_FromMod, {?join_guild}) ->
    load_guild_data(),
    case ?is_join_guild() of
        true ->
            achievement_mng:do_ac(?gonghuixinxing),
            phase_achievement_mng:do_pc(?PHASE_AC_GONGHUI_JOIN, 1),
            guild_service:add_member_online();
%%      reset_guild_daily_task_count();
        false ->
            ok
    end,

%%     put(?pd_society_bufs, [1,2,3,4,5]),
%%     ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_SYNC_SOCIETY_BUFS, {[1,2,3,4,5]})),
    %% 离开公会重置场景进程玩家agent
    ?ifdo(get(?pd_scene_pid) =/= undefined,
        get(?pd_scene_pid) ! ?scene_mod_msg(scene_player, {update_agent_info, self(), get(?pd_career), 3, get_guild_info()})),
    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_PUSH_JOIN_GUILD, {}));

handle_msg(_FromMod, {?quit_guild}) ->
    put(?pd_guild_id, 0),
    guild_service:del_member_online(),
    del_tech_attr(),
    %% 离开公会重置场景进程玩家agent
    get(?pd_scene_pid) ! ?scene_mod_msg(scene_player, {update_agent_info, self(), get(?pd_career), 3, 0}),
    ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_PUSH_REMOVE_GUILD, {}));

handle_msg(_FromMod, {change_position}) ->
    push_role_data(), %% 会长转让 用协议201，前端是用202 协议处理，但协议已经找不到
    ok;

handle_msg(_FromMod, {update_gongxian_lv}) ->
    {PlayerGuildLv, PlayerGuildExp} = guild_mng:get_guild_player_lv_and_exp_by_contribution(get(?pd_guild_totle_contribution)),
    put(?pd_guild_lv, PlayerGuildLv),
    put(?pd_guild_exp, PlayerGuildExp),
    guild_mng:push_role_data();

handle_msg(_FromMod, Msg) ->
    ?err({unknown_msg, Msg}).

online() ->
    case ?is_join_guild() of
        true ->
            guild_service:add_member_online();
%%      case player:is_daliy_first_online() =:= ?false of
%%        true -> reset_guild_daily_task_count();
%%        false -> ok
%%      end;
        false -> ok
    end.

offline(_SelfId) ->
    ?ifdo(?is_join_guild(), guild_service:del_member_online()),
    ok.

save_data(_SelfId) ->
%%  ?INFO_LOG("guild save data"),
    ?ifdo(?is_join_guild(),
        update_guild_data()).

load_guild_data() ->
    PlayerId = get(?pd_id),
    case dbcache:load_data(?player_guild_member, PlayerId) of
        [] ->
            put(?pd_guild_id, 0);
        [#player_guild_member{guild_id = GuildId,
            player_position = PlayerGuildPosition,
            join_time = JoinTime,
            totle_exp = PlayerTotleGuildExp,
            lv = _,
            exp = _}] -> %在线，退会,加入公会的情况
            put(?pd_guild_id, GuildId),
            put(?pd_guild_position, PlayerGuildPosition),
            put(?pd_join_guild_time, JoinTime),
            put(?pd_guild_totle_contribution, PlayerTotleGuildExp),
            {PlayerGuildLv, PlayerGuildExp} = guild_mng:get_guild_player_lv_and_exp_by_contribution(PlayerTotleGuildExp),
            put(?pd_guild_lv, PlayerGuildLv),
            put(?pd_guild_exp, PlayerGuildExp),
%%      put(?pd_guild_daily_task_count, TypeNumList),


            %% 玩家每日升级公会的次数
            case dbcache:load_data(player_guild_count, PlayerId) of
                [] -> put(?pd_guild_daily_task_count, []);
                [GuildCount] -> put(?pd_guild_daily_task_count, GuildCount#player_guild_count.daily_task_count)
            end,

%%            ?INFO_LOG("update pd_guild_daily_task_count,~p", [get(?pd_guild_daily_task_count)]),

            %% 玩家是否离开过公会
            case dbcache:load_data(player_guild_is_join_guild, PlayerId) of
                [] -> put(?pd_guild_quit_guild_time, 0);
                [IsJoinGuild] -> put(?pd_guild_quit_guild_time, IsJoinGuild#player_guild_is_join_guild.quit_guild_times)
            end,

            %% 玩家公会科技建筑信息
            case dbcache:load_data(?player_guild_tech_buildings, PlayerId) of
                [] ->
                    put(?pd_guild_tech_items, []);
                [#player_guild_tech_buildings{tech_items = undefined}] ->
                    put(?pd_guild_tech_items, []);
                [#player_guild_tech_buildings{tech_items = TechItems}] ->
                    put(?pd_guild_tech_items, TechItems)
            end,

            %% 玩家圣物信息
            case dbcache:load_data(player_guild_saint_tab, PlayerId) of
                [] ->
                    AllSaint = load_cfg_guild_saint:get_all_saint_type_by_offer_lv(PlayerGuildLv),
                    GuildSaintList =
                        lists:foldl(
                            fun({_OfferLv, SaintId},Acc) ->
                                [{SaintId, 0} | Acc]
                            end,
                            [],
                            AllSaint
                        ),
                    put(?pd_guild_saint_list, GuildSaintList);
                [#player_guild_saint_tab{guild_saint_list = GuildSaintList}] ->
                    put(?pd_guild_saint_list, GuildSaintList)
            end
    end,
    ok.

%% 更新玩家的公会信息
update_guild_data() ->
    PlayerId = get(?pd_id),
    GuildId = get(?pd_guild_id),
    case dbcache:lookup(?player_guild_member, PlayerId) of
        [] -> ok;
        [_GuildMemberTab] ->
            GuildMemberInfo = #player_guild_member{player_id = PlayerId,
                guild_id = GuildId,
                player_position = get(?pd_guild_position),
                join_time = get(?pd_join_guild_time),
                totle_exp = get(?pd_guild_totle_contribution),
                lv = get(?pd_guild_lv),
                exp = get(?pd_guild_exp)},

            GuildTechInfo = #player_guild_tech_buildings{player_id = PlayerId,
                guild_id = GuildId,
                tech_items = get(?pd_guild_tech_items)},

            guild_service:update_guild_data_to_ets(?player_guild_member, GuildMemberInfo),

            DailyCount = #player_guild_count{
                player_id = PlayerId,
                daily_task_count = get(?pd_guild_daily_task_count)
            },
            guild_service:update_guild_data_to_ets(player_guild_count, DailyCount),

            guild_service:update_guild_data_to_ets(?player_guild_tech_buildings, GuildTechInfo),

            GuildSaintList = #player_guild_saint_tab{
                player_id = PlayerId,
                guild_saint_list = get(?pd_guild_saint_list)
            },
            guild_service:update_guild_data_to_ets(player_guild_saint_tab, GuildSaintList)

    end.

%%重置公会日常任务次数
reset_guild_daily_task_count() ->
    case ?is_join_guild() of
        true ->
            GuildId = get(?pd_guild_id),
            [#guild_buildings_tab{building_list = BuildingList}] = dbcache:lookup(?guild_buildings_tab, GuildId),
            TotleCount = load_cfg_guild:lookup_cfg(?guild_buildings_cfg, BuildingList),
            put(?pd_guild_daily_task_count, TotleCount),
            ?player_send(guild_sproto:pkg_msg(?PUSH_GUILD_BUILDING_ADD_EXP, {TotleCount}));
%%      JoinTime = com_time:sec_to_localtime(get(?pd_join_guild_time)),
%%      QuitTime = com_time:sec_to_localtime(get(?pd_guild_quit_guild_time)),
%%      case com_time:is_same_day(JoinTime, QuitTime) of
%%        true ->
%%          ok;
%%        false ->
%%          GuildId = get(?pd_guild_id),
%%          [#guild_buildings_tab{building_list = BuildingList}] = dbcache:lookup(?guild_buildings_tab, GuildId),
%%          TotleCount = load_cfg_guild:lookup_cfg(?guild_buildings_cfg, BuildingList),
%%          put(?pd_guild_daily_task_count, TotleCount),
%%          ?player_send(guild_sproto:pkg_msg(?PUSH_GUILD_BUILDING_ADD_EXP, {TotleCount}))
%%      end;
        false ->
            ok
    end.

%% 重置公会圣物
reset_guild_saint_list() ->
    case ?is_join_guild() of
        true ->
            GuildSaintList = get(?pd_guild_saint_list),
            NewGuildSaintList =
                lists:foldl(
                    fun({SaintId, _},Acc) ->
                        [{SaintId, 0} | Acc]
                    end,
                    [],
                    GuildSaintList
                ),
            put(?pd_guild_saint_list, NewGuildSaintList);
        false ->
            pass
    end.

%%lookup_cfg(?guild_tech_cfg) ->
%%    [lookup_guild_tech_cfg(Id) || Id <- lookup_all_guild_tech_cfg(#guild_tech_cfg.id)].
%%
%%lookup_cfg(?guild_member_lvup_cfg, Key) when is_integer(Key) ->
%%    MaxLv = lists:max(lookup_all_guild_member_lvup_cfg(#guild_member_lvup_cfg.lv)),
%%    #guild_member_lvup_cfg{exp = Exp} = lookup_guild_member_lvup_cfg(Key),
%%    #guild_member_lvup_cfg{exp = MaxExp} = lookup_guild_member_lvup_cfg(MaxLv),
%%    {MaxLv, MaxExp, Exp};
%%
%%lookup_cfg(?guild_tech_cfg, {TechType, Lv}) ->
%%    TechLvupCFG = lookup_cfg(?guild_tech_cfg),
%%    TechTypeList = [{LvCFG, RewardCFG, ConditionCFG, UpdateCostIDCFG} ||
%%        #guild_tech_cfg{tech_type_id = TypeCFG, lv = LvCFG, reward = RewardCFG, condition = ConditionCFG, update_cost = UpdateCostIDCFG}
%%            <- TechLvupCFG, TypeCFG =:= TechType],
%%    {MaxLv, _, _, _} = lists:max(TechTypeList),
%%    [{Reward, Condition, UpdateCostID}] = [{Reward1, Condition1, UpdateCost1} || {Lv1, Reward1, Condition1, UpdateCost1} <- TechTypeList, Lv1 =:= Lv],
%%    {MaxLv, Reward, Condition, UpdateCostID};
%%
%%lookup_cfg(?guild_tech_cfg, #guild_tech_cfg.tech_type_id) ->
%%    lookup_all_guild_tech_cfg(#guild_tech_cfg.tech_type_id).
%%
%%lookup_cfg(?guild_member_lvup_cfg, Lv, "member_lv") ->
%%    case lookup_guild_member_lvup_cfg(Lv) of
%%        none -> 0;
%%        #guild_member_lvup_cfg{member_lv = MemLv} ->
%%            MemLv
%%    end.

%% 广播一条消息给公会所有的在线玩家
broadcast(Msg) ->
    case get(?pd_guild_id) of
        0 -> ok;
        _GuildId ->
            [PlayerPid ! Msg || {_PlayerId, PlayerPid}
                <- guild_service:get_memeber_online()]
    end.

%% 玩家没公会了推消息会错
push_role_data() ->
    case get(?pd_guild_id) of
        0 -> ok;
        _GuildId ->
            push_guild_saint_list(),
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_PUSH_ROLEEXP, {get(?pd_guild_lv), get(?pd_guild_exp), get(?pd_guild_totle_contribution), get(?pd_guild_position)}))
    end.

push_guild_member_join(GuildId, MemberList) ->
    MsgBin = guild_sproto:pkg_msg(?MSG_GUILD_PUSH_GUILD_MEMBER_JOIN, {MemberList}),
    FunMap = fun(ElePlayerData) ->
        PlayerId = element(1, ElePlayerData),
        PlayerName = player:lookup_info(PlayerId, ?pd_name),
        guild_service:add_event(?GUILD_EVENT_TYPE_JOIN, GuildId, {PlayerId, PlayerName}),
        {integer_to_binary(PlayerId), PlayerName}
    end,
    PlayerNameList = lists:map(FunMap, MemberList),
    push_guild_member_change(GuildId, MsgBin, PlayerNameList, "join").

push_guild_member_quit(GuildId, {PlayerId, PlayerName}, State) ->
    MsgBin = guild_sproto:pkg_msg(?MSG_GUILD_PUSH_GUILD_MEMBER_QUIT, {PlayerId}),
    case State of
        "quit" -> 
            guild_service:add_event(?GUILD_EVENT_TYPE_QUIT, GuildId, {get(?pd_id), get(?pd_name)});
        "remove" -> 
            guild_service:add_event(?GUILD_EVENT_TYPE_REMOVE, GuildId, {PlayerId, PlayerName})
    end,
    push_guild_member_change(GuildId, MsgBin, [{integer_to_binary(PlayerId), PlayerName}], State).

push_guild_master_change(GuildId) ->
    [#guild_member_online_tab{player_list = PlayerOnlineList}] = guild_service:lookup_tab(?guild_member_online_tab, GuildId),
    ?INFO_LOG("push_guild_master_change :~p", [PlayerOnlineList]),
    FunMap = fun({_PlayerId, PlayerPid}) ->
        PlayerPid ! ?mod_msg(guild_mng, {change_position})
    end,
    lists:foreach(FunMap, PlayerOnlineList).

push_guild_member_position(GuildId, {PlayerId, PlayerName, PositionId}) ->
%%  MsgBin = guild_sproto:pkg_msg(?PUSH_GUILD_MEMBER_POSITION, {PlayerId, PositionId}),
    push_guild_member_change(GuildId, <<>>, [{integer_to_binary(PlayerId), PlayerName, PositionId}], "position").

push_guild_member_change(GuildId, MsgBin, _PlayerList, _MemberState) ->
    [#guild_member_online_tab{player_list = PlayerOnlineList}] = guild_service:lookup_tab(?guild_member_online_tab, GuildId),
    FunMap = fun({_PlayerId, PlayerPid}) ->
        case MsgBin of
            <<>> -> ok;
            MsgBin -> ?send_to_client(PlayerPid, MsgBin)
        end
    end,
    lists:foreach(FunMap, PlayerOnlineList).

    %% SystemMsgList = case MemberState of
    %%                     "quit" -> %玩家自己进程
    %%                         [{PlayerId, ?Language(2, PlayerName)} || {PlayerId, PlayerName} <- PlayerList];
    %%                     "remove" -> %会长进程
    %%                         [{PlayerId, ?Language(3, PlayerName)} || {PlayerId, PlayerName} <- PlayerList];
    %%                     "join" -> %会长进程
    %%                         [GuildTab] = guild_service:lookup_tab(?guild_tab, GuildId),
    %%                         [{PlayerId, ?Language(4, {GuildTab#guild_tab.guild_name, PlayerName})} || {PlayerId, PlayerName} <- PlayerList];
    %%                     "position" ->
    %%                         [{PlayerId, PlayerName, PositionId}] = PlayerList,
    %%                         PositionName = case PositionId of
    %%                                            ?GUILD_MASTER_POSITIONID -> <<"会长"/utf8>>;
    %%                                            ?GUILD_VICE_MASTER_POSTION -> <<"副会长"/utf8>>;
    %%                                            ?GUILD_MEMBER_POSTION -> <<"成员"/utf8>>
    %%                                        end,
    %%                         [{PlayerId, ?Language(5, {PlayerName, PositionName})}]
    %%                 end,
    %% [#guild_member_online_tab{player_list = PlayerOnlineList}] = guild_service:lookup_tab(?guild_member_online_tab, GuildId),

    %% ?INFO_LOG("player onine list:~p", [PlayerOnlineList]),
   %%  FunMap = fun({PlayerId, PlayerPid}) ->
   %%      case MsgBin of
   %%          <<>> -> ok;
   %%          MsgBin -> ?send_to_client(PlayerPid, MsgBin)
   %%      end
   %%      [case integer_to_binary(PlayerId) of
   %%           SelfPlayerId -> PlayerPid ! chat_mng:pack_chat_system(Msg1);
   %%           _ -> PlayerPid ! chat_mng:pack_chat_system(Msg2)
   %%      end || {SelfPlayerId, {Msg1, Msg2}} <- SystemMsgList]
   %%  end,
   %%  lists:foreach(FunMap, PlayerOnlineList).

del_tech_attr() ->
    TechItems = get(?pd_guild_tech_items),
    Fun = fun({TechId, TechLv}) ->
        {_MaxLv, Reward, _Condition, _UpdateCost} = load_cfg_guild:lookup_cfg(?guild_tech_cfg, {TechId, TechLv}),
        case Reward of
            0 -> ok;
            _ ->
                player:sub_attr_amend(Reward)
%%        case Data of
%%          {} -> attr:amend(Reward);
%%          Attr -> com_record:merge(fun(A, B) -> A + B end, Attr, attr:amend(Reward))
%%        end
        end
    end,
    lists:foreach(Fun, TechItems).
%%  case lists:foldl(Fun, {}, TechItems) of
%%    {} -> ok;
%%    Attrs -> player:sub_attr_amend(Attrs)
%%  end.

add_tech_attr(TachId, TechLv) ->
    % 不叠加
    if TechLv > 1 ->
        {_OMaxLv, OReward, _OCondition, _OUpdateCost} = load_cfg_guild:lookup_cfg(?guild_tech_cfg, {TachId, TechLv - 1}),
        case OReward of
            0 -> 0;
            _ -> player:sub_attr_amend(OReward)
        end;
        true -> ok
    end,
    {_MaxLv, Reward, _Condition, _UpdateCost} = load_cfg_guild:lookup_cfg(?guild_tech_cfg, {TachId, TechLv}),
    case Reward of
        0 -> 0;
        _ -> player:add_attr_amend(Reward)
    end.

push_guild_saint_list() ->
    case ?is_join_guild() of
        true ->
            GuildSaintList = get(?pd_guild_saint_list),
            PlayerLv = get(?pd_guild_lv),
            OpenList = load_cfg_guild_saint:get_all_saint_type_by_offer_lv(PlayerLv),
            NewGuildSaintList =
                lists:foldl(
                    fun({_Lv, SaintId},RetList) ->
                        case lists:keyfind(SaintId, 1, RetList) of
                            false ->
                                [{SaintId, 0} | RetList];
                            _ ->
                                RetList
                        end
                    end,
                    GuildSaintList,
                    OpenList
                ),
            put(?pd_guild_saint_list, NewGuildSaintList),
            ?player_send(guild_sproto:pkg_msg(?MSG_GUILD_SAINT_EXCHANGE_STATUS, {NewGuildSaintList}));
        false ->
            pass
    end.

get_guild_player_lv_and_exp_by_contribution( Contribution ) ->
    {Lv, Exp} = get_guild_player_lv_and_exp_by_contribution(1, 0, Contribution),
    {GuildLv, _} = guild_service:select_guild_lv(get(?pd_guild_id)),
    MaxGuildLv = misc_cfg:get_guild_max_lv(),
    if
        GuildLv =:= MaxGuildLv ->
            {Lv, Exp};
        Lv < GuildLv + 3 ->
            {Lv, Exp};
        true ->
            MaxLv = GuildLv + 2,
            NewExp = Contribution - get_total_exp_by_lv(1, MaxLv, 0),
            {MaxLv, NewExp}
    end.

get_guild_player_lv_and_exp_by_contribution(Lv, TotalExp, Contribution) ->
    #guild_member_lvup_cfg{exp = Exp} = load_cfg_guild:lookup_guild_member_lvup_cfg(Lv),
    NeedExp = TotalExp + Exp,
    if
        NeedExp > Contribution ->
            {Lv, Contribution - TotalExp};
        true ->
            get_guild_player_lv_and_exp_by_contribution(Lv + 1, NeedExp, Contribution)
    end.

get_total_exp_by_lv(Lv, MaxLv, TotalExp) ->
    if
        Lv > MaxLv ->
            TotalExp;
        true ->
            #guild_member_lvup_cfg{exp = Exp} = load_cfg_guild:lookup_guild_member_lvup_cfg(Lv),
            get_total_exp_by_lv(Lv+1, MaxLv, TotalExp + Exp)
    end.

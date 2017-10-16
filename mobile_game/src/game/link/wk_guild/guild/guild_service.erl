%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc 公会公共数据
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(guild_service).
-behaviour(gen_server).

-include("player.hrl").
-include("guild_define.hrl").

-include("inc.hrl").
-include_lib("pangzi/include/pangzi.hrl").
%-include_lib("config/include/config.hrl").
-include("load_cfg_guild.hrl").
-include("rank.hrl").





%% API
-export([
    select_guildList/2,       %获取公会列表
    select_guild_info/1, 
    get_guild_lv/0,
    select_guild_lv/1,
    select_guild_name/1,
    select_guild_rank/1,
    select_guild/1,           %获取单个公会信息
    lookup_tab/2,
    get_guild_boss/1,
    set_guild_boss/2,
    guild_data_init/3,
    insert_tab/2,
    delete_apply_player/2,    %申请加入工会
    guild_totle_num/2,        %计算公会总人数
    build_add_exp/3,
    build_update_exp/3,          %公会建筑增加贡献值
    addexp/5,
    get_memeber_online/0,     %获取公会在线成员列表
    get_memeber_online/1,
    add_member_online/0,      %公会成员上线（新加入公会）加入在线列表
    del_member_online/0,      %公会成员下线（退出公会）退出在线列表
    add_event/3,              %添加公会事件
    guild_boss_tm/0,
    guild_boss_reset/0,
    package_guild_for_rank/2,
    update_guild_data_to_ets/2,
    get_guild_player_total_count/1,
    get_guild_master/1,                 %% 获取公会会长Id
    get_guild_member_except_master/1,    %% 获取公会成员Id列表
    get_guild_name/1,
    guild_build_add_exp/2
]).

-export([
    start_link/0,
    zore_reset/0,             %重置玩家申请公会数据
    ets_add/1,
    ets_lookup/2,
    is_ets_match/2
]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {}).

-define(GUILD_BUILDING_ID, 1).          %公会大厅的默认配置ID
-define(GUILD_DEFAULT_MAX_NUMBER, 1).   %配置公会最大人数时，默认的key值

-define(HAS_GUILD, 0).           %已经拥有公会
-define(NO_APPLY_GUID, 1).       %没有申请入会
-define(JOIN_IN_THIS_GUID, 2).   %已经在该公会
-define(HAS_APPLY_GUILD, 3).     %已经申请入会

-define(GUILD_BOSS_TIMER_DT, 5000).
-define(GUILD_BOSS_RESET_TIMER_DT, 5000).


get_base_guild_id(GuildId) ->
    ServerInfo = global_data:get_server_info(),
    ServerId = 
    case maps:find(id, ServerInfo) of
        {ok, Id} when is_integer(Id) -> 
            Id;
        _ -> 
            0
    end,
    10000 - (GuildId - ((ServerId * 10000) + 1000)).

-spec select_guildList(integer(), integer()) -> TupleList when TupleList :: [Tuple], Tuple :: term().
select_guildList(PageStart, PageEnd) ->
    {_, _, GuildIdExpList} = ranking_lib:get_rank_order_page(PageStart, (PageEnd - PageStart) + 1, ?ranking_guild),
    package_guild(GuildIdExpList).

-spec select_guild(integer()) -> [] | {integer(), TupleList} when TupleList :: [Tuple], Tuple :: term().
select_guild(GuildId) ->
    case ranking_lib:get_rank_order(?ranking_guild, GuildId) of
        %out_rank -> 
        %    [];
        {0, 0} -> 
            [];
        {RankNum, _GuildTotleExp} ->
            [{TotemId, BorderId, GuildLv, Name, MasterName, MasterId, TotlePlayer, GuildId, IsApply}] = package_guild([{GuildId, 0}]),
            {RankNum, TotemId, BorderId, GuildLv, Name, MasterName, MasterId, TotlePlayer, GuildId, IsApply}
    end.

-spec select_guild_info(integer()) -> [] | tuple().
select_guild_info(GuildId) ->
    {GuildLv, GuildExp} = select_guild_lv(GuildId),
    RankNum_ = select_guild_rank(GuildId),
    [GuildTab] = lookup_tab(?guild_tab, GuildId),
    {
        {GuildTab#guild_tab.totem_id,GuildTab#guild_tab.border_id,GuildTab#guild_tab.guild_name,GuildId},
        {RankNum_,GuildLv,GuildExp,player:lookup_info(GuildTab#guild_tab.master_id, ?pd_name),GuildTab#guild_tab.master_id,GuildTab#guild_tab.totle_player,GuildTab#guild_tab.notice,GuildTab#guild_tab.notice_update_time}
    }.

get_guild_lv() ->
    [#guild_buildings_tab{building_list = BuildingList}] = dbcache:lookup(?guild_buildings_tab, get(?pd_guild_id)),
    case lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList) of
        false -> 
            0;
        {?GUILD_BUILDING_ID, Lv, _Exp} -> 
            Lv
    end.

select_guild_lv(GuildId) ->
    [#guild_buildings_tab{building_list = BuildingList}] = dbcache:lookup(?guild_buildings_tab, GuildId),
    case lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList) of
        false -> 
            {1, 0};
        {?GUILD_BUILDING_ID, BuildingLv, BuildingExp} -> 
            {BuildingLv, BuildingExp}
    end.

select_guild_name(PlayerId) ->
    case dbcache:lookup(?player_guild_member, PlayerId) of
        [] -> 
            <<>>;
        [#player_guild_member{guild_id = GuildId}] ->
            case dbcache:lookup(?guild_id_tab, GuildId) of
                [] -> 
                    <<>>;
                [#guild_id_tab{guild_name = GuildNameBin}] -> 
                    GuildNameBin
            end
    end.

select_guild_rank(GuildId) ->
    case ranking_lib:get_rank_order(?ranking_guild, GuildId) of
        %out_rank ->
        {0,0} -> 
            0;
        {RankNum, _GuildTotleExp} -> 
            RankNum
    end.

package_guild(GuildIdExpList) ->
    FunGuildInfo =
        fun({GuildId, _GUildTotleExp}) ->
            [#guild_tab{guild_name = GuildName, totem_id = TotemId, border_id = BorderId,master_id = MasterId,totle_player = TotlePlayer}] = lookup_tab(?guild_tab, GuildId),

            GuildLv = 
            case dbcache:lookup(?guild_buildings_tab, GuildId) of
                [] -> 
                    ?DEFAULT_GUILD_LV;
                [#guild_buildings_tab{building_list = BuildingList}] ->
                    case lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList) of
                        false -> 
                            ?DEFAULT_GUILD_LV;
                        {?GUILD_BUILDING_ID, BuildingLv, _BuildingExp} -> 
                            BuildingLv
                    end
            end,
            [MasterName] = player:lookup_info(MasterId, [?pd_name]),
            IsApply = 
            case get(?pd_guild_id) of
                GuildId -> 
                    ?JOIN_IN_THIS_GUID;
                0 ->
                    case ets_lookup(GuildId, #player_apply_tab.guild_id) of
                        [] -> 
                            ?NO_APPLY_GUID;
                        PlayerList -> 
                            ?if_else(lists:member(get(?pd_id), PlayerList), ?HAS_APPLY_GUILD, ?NO_APPLY_GUID)
                    end;
                _PdGuildId -> 
                    ?HAS_GUILD
            end,

            {TotemId, BorderId, GuildLv, GuildName, MasterName, MasterId, TotlePlayer, GuildId, IsApply}
        end,
    lists:map(FunGuildInfo, GuildIdExpList).

package_guild_for_rank(StartRank, GuildIdExpList) ->
    {_,GuildInfoList} =
        lists:foldl(
            fun({GuildId, _GUildTotleExp}, {Index, L}) ->
                [#guild_tab{guild_name = GuildName, totem_id = TotemId, border_id = BorderId,master_id = MasterId,totle_player = TotlePlayer}] = lookup_tab(?guild_tab, GuildId),

                GuildLv =
                    case dbcache:lookup(?guild_buildings_tab, GuildId) of
                        [] ->
                            ?DEFAULT_GUILD_LV;
                        [#guild_buildings_tab{building_list = BuildingList}] ->
                            case lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList) of
                                false ->
                                    ?DEFAULT_GUILD_LV;
                                {?GUILD_BUILDING_ID, BuildingLv, _BuildingExp} ->
                                    BuildingLv
                            end
                    end,
                [MasterName] = player:lookup_info(MasterId, [?pd_name]),

                {Index+1, [{ Index+1, GuildId, TotemId, BorderId, GuildLv, GuildName, MasterId, MasterName } | L]}
            end,
            {StartRank-1, []},
            GuildIdExpList),
    GuildInfoList.
    % FunGuildInfo =
    %     fun({GuildId, _GUildTotleExp}) ->
    %         RankNum = select_guild_rank(GuildId),
    %         [#guild_tab{guild_name = GuildName, totem_id = TotemId, border_id = BorderId,master_id = MasterId,totle_player = TotlePlayer}] = lookup_tab(?guild_tab, GuildId),

    %         GuildLv = 
    %         case dbcache:lookup(?guild_buildings_tab, GuildId) of
    %             [] -> 
    %                 ?DEFAULT_GUILD_LV;
    %             [#guild_buildings_tab{building_list = BuildingList}] ->
    %                 case lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList) of
    %                     false -> 
    %                         ?DEFAULT_GUILD_LV;
    %                     {?GUILD_BUILDING_ID, BuildingLv, _BuildingExp} -> 
    %                         BuildingLv
    %                 end
    %         end,
    %         [MasterName] = player:lookup_info(MasterId, [?pd_name]),

    %         { GuildId, RankNum, TotemId, BorderId, GuildLv, GuildName, MasterId, MasterName }
    %     end,
    % lists:map(FunGuildInfo, GuildIdExpList).

%% @doc 清空该公会的申请列表
delete_apply_player(clear, GuildId) ->
    ets:match_delete(?player_apply_tab, #player_apply_tab{guild_id = GuildId, _ = '_'});

%% @doc 清空该玩家申请的公会列表
delete_apply_player(clear_player_apply_info, PlayerId) ->
    ets:delete(?player_apply_tab, PlayerId);

%% @doc 某公会拒绝某玩家
delete_apply_player(PlayerId, GuildId) ->
    ets:delete_object(?player_apply_tab, #player_apply_tab{player_id = PlayerId, guild_id = GuildId}).

get_guild_player_total_count(GuildId) ->
    case lookup_tab(?guild_tab, GuildId) of
        [] ->
            0;
        [#guild_tab{totle_player=Count}] ->
            Count
    end.

%% @doc 退出公会，公会总人数-1
guild_totle_num(GuildId, Num) when Num < 0 ->
    case lookup_tab(?guild_tab, GuildId) of
        [] -> 
            {error, ?ERR_GUILD_NO_GUILD};
        [GuildTab] ->
            Count = max(GuildTab#guild_tab.totle_player + Num, 0),
            update_guild_data_to_ets(?guild_tab, GuildTab#guild_tab{totle_player = Count}),
            ok
    end;

%% @doc 加入公会，判断公会是否人数已满，没满+1
guild_totle_num(GuildId, Num) when Num > 0 ->
    [GuildTab] = lookup_tab(?guild_tab, GuildId),
    TotlePlayer = GuildTab#guild_tab.totle_player,
    [#guild_buildings_tab{building_list = BuildingList}] = dbcache:lookup(?guild_buildings_tab, GuildId),
    Lv = 
    case lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList) of
        false -> 
            ?DEFAULT_GUILD_LV;
        {?GUILD_BUILDING_ID, BuildingLv, _BuildingExp} -> 
            BuildingLv
    end,

    case load_cfg_guild:lookup_cfg(?guild_buildings_cfg, {?GUILD_BUILDING_ID, Lv}) of
        [] -> 
            {error, ?ERR_GUILD_NO_BUILDING_LVUPCFG};
        [{_LvCFG, _NeedExp, LvReword, _NeedGuildLv, _DailyTotleCount, _UpdateCost}] ->
            case lists:keyfind(?GUILD_DEFAULT_MAX_NUMBER, 1, LvReword) of
                false -> 
                    {error, ?ERR_GUILD_NO_BUILDING_LVUPCFG};
                {?GUILD_DEFAULT_MAX_NUMBER, Number} ->
                    if
                        Number >= (TotlePlayer + Num) ->
                            update_guild_data_to_ets(?guild_tab, GuildTab#guild_tab{totle_player = TotlePlayer + Num}),
                            ok;
                        true ->
                            {error, ?ERR_GUILD_MAX_NUM}
                    end
            end
    end.

%% @doc 公会建筑增加经验值
build_add_exp(BuildingTypeId, BuildingList, CostType) ->
    {BuildingTypeId, BuidlingTypeLv, BuildingTypeExp} = lists:keyfind(BuildingTypeId, 1, BuildingList),
    {MaxLv, MaxNeedExp, _LvCFG, NeedExp, _Reward, NeedGuildLv, _DailyTotleCount, UpdateCost} =
        load_cfg_guild:lookup_cfg(?guild_buildings_cfg, {max, BuildingTypeId, BuidlingTypeLv}),

    %% 验证限制条件
    ?ifdo((BuildingTypeId =/= ?GUILD_BUILDING_ID) and (NeedGuildLv > get_guild_lv()),
        ?return_err(?ERR_GUILD_LV_LESS_THEN_BUILDINGS)),

    ?ifdo((MaxLv =< BuidlingTypeLv) and (MaxNeedExp =< BuildingTypeExp),
        ?return_err(?ERR_GUILD_LV_MAX)),

    {AssetType, CoinCost, BuildAddExp} = case CostType of
                                             2 -> lists:keyfind(?PL_DIAMOND, 1, UpdateCost);
                                             1 -> lists:keyfind(?PL_MONEY, 1, UpdateCost);
                                             _ -> ?return_err(?ERR_GUILD_TYPE_IS_ERROR)
                                         end,
    {NewBuildingLv, NewBuildingExp} = addexp(MaxNeedExp, NeedExp, MaxLv, BuidlingTypeLv, (BuildingTypeExp + BuildAddExp)),
    if
        NewBuildingLv > BuidlingTypeLv ->
            [PlayerPid ! ?mod_msg(guild_mng, {update_gongxian_lv}) || {_PlayerId, PlayerPid} <- guild_service:get_memeber_online()];
        true ->
            pass
    end,
    %% 以前的【升级公会科技的时候，会升级公会大厅】
    %% NewBuildingList = case BuildingTypeId of
    %%                     ?GUILD_BUILDING_ID ->
    %%                       {lists:keystore(BuildingTypeId, 1, BuildingList, {BuildingTypeId, NewBuildingLv, NewBuildingExp}),
    %%                         {BuildingTypeId, NewBuildingLv, NewBuildingExp, NewBuildingLv, NewBuildingExp}};

    %%                     _ ->
    %%                       {_, BuildingDefaultLv, BuildingDefaultExp} = lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList),
    %%                       {MaxDefaultLv, MaxNeedDefaultExp, _, NeedDefaultExp, _, _, _, _} =
    %%                         load_cfg_guild:lookup_cfg(?guild_buildings_cfg, {max, ?GUILD_BUILDING_ID, BuildingDefaultLv}),

    %%                       {NewBuildingDefaultLv, NewBuildingDefaultExp} = addexp(MaxNeedDefaultExp, NeedDefaultExp, MaxDefaultLv, BuildingDefaultLv, (BuildingDefaultExp + BuildAddExp)),
    %%                       BuildingList1 = lists:keystore(BuildingTypeId, 1, BuildingList, {BuildingTypeId, NewBuildingLv, NewBuildingExp}),
    %%                       {lists:keystore(?GUILD_BUILDING_ID, 1, BuildingList1, {?GUILD_BUILDING_ID, NewBuildingDefaultLv, NewBuildingDefaultExp}),
    %%                         {BuildingTypeId, NewBuildingLv, NewBuildingExp, NewBuildingDefaultLv, NewBuildingDefaultExp}}
    %%
    %%                  end,
    %% 【升级公会科技的时候，不会升级公会大厅，各升级各的】
    {_, BuildingDefaultLv, BuildingDefaultExp} = lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList),
    NewBuildingList = {lists:keystore(BuildingTypeId, 1, BuildingList, {BuildingTypeId, NewBuildingLv, NewBuildingExp}),
        {BuildingTypeId, NewBuildingLv, NewBuildingExp, BuildingDefaultLv, BuildingDefaultExp}},

    {NewBuildingList, {AssetType, CoinCost, BuildAddExp}}.

%% 公会建筑直接增加经验
build_direct_add_exp(BuildingTypeId, BuildingList, BuildAddExp, GuildId) ->
    {BuildingTypeId, BuildingTypeLv, BuildingTypeExp} = lists:keyfind(BuildingTypeId, 1, BuildingList),
    {MaxLv, MaxNeedExp, _LvCFG, NeedExp, _Reward, _NeedGuildLv, _DailyTotleCount, _UpdateCost} =
        load_cfg_guild:lookup_cfg(?guild_buildings_cfg, {max, BuildingTypeId, BuildingTypeLv}),

    {NewBuildingLv, NewBuildingExp} = direct_add_exp(MaxNeedExp, NeedExp, MaxLv, BuildingTypeLv, (BuildingTypeExp + BuildAddExp)),

    if
        NewBuildingLv > BuildingTypeLv ->
            [PlayerPid ! ?mod_msg(guild_mng, {update_gongxian_lv}) || {_PlayerId, PlayerPid} <- guild_service:get_memeber_online(GuildId)];
        true ->
            pass
    end,

    NewBuildingList = lists:keystore(BuildingTypeId, 1, BuildingList, {BuildingTypeId, NewBuildingLv, NewBuildingExp}),
    NewBuildingList.

direct_add_exp(MaxExpCFG, ExpCFG, MaxLvCFG, Lv, AllExp) ->
    if
        AllExp < ExpCFG ->
            {Lv, AllExp};
        (AllExp >= ExpCFG) andalso (Lv < MaxLvCFG) ->
            NextLv = Lv + 1,
            if
                NextLv =:= MaxLvCFG ->
                    if
                        (AllExp - ExpCFG) >= MaxExpCFG -> {NextLv, MaxExpCFG};
                        true -> {NextLv, (AllExp - ExpCFG)}
                    end;
                true ->
                    {NextLv, (AllExp - ExpCFG)}
            end;
        Lv =:= MaxLvCFG ->
            if
                AllExp < MaxExpCFG ->
                    {Lv, AllExp};
                true -> {Lv, MaxExpCFG}
            end;
        Lv > MaxLvCFG -> {MaxLvCFG, MaxExpCFG}
    end.

addexp(MaxExpCFG, ExpCFG, MaxLvCFG, Lv, AllExp) ->
    if
        AllExp < ExpCFG ->
            {Lv, AllExp};
        (AllExp >= ExpCFG) andalso (Lv < MaxLvCFG) ->
            NextLv = Lv + 1,
            event_eng:post(?ev_guild_player_level, {?ev_guild_player_level, 0}, NextLv),
            if
                NextLv =:= MaxLvCFG ->
                    if
                        (AllExp - ExpCFG) >= MaxExpCFG -> {NextLv, MaxExpCFG};
                        true -> {NextLv, (AllExp - ExpCFG)}
                    end;
                true ->
                    {NextLv, (AllExp - ExpCFG)}
            end;
        Lv =:= MaxLvCFG ->
            if
                AllExp < MaxExpCFG ->
                    {Lv, AllExp};
                true -> {Lv, MaxExpCFG}
            end;
        Lv > MaxLvCFG -> {MaxLvCFG, MaxExpCFG}
    end.

build_update_exp(GuildId, NewBuildingList, BuildAddExp) ->
    [GuildTab] = lookup_tab(?guild_tab, GuildId),
    TotleExp = GuildTab#guild_tab.totle_exp + BuildAddExp,

    update_guild_data_to_ets(?guild_buildings_tab, #guild_buildings_tab{guild_id = GuildId, building_list = NewBuildingList}),
    update_guild_data_to_ets(?guild_tab, GuildTab#guild_tab{totle_exp = TotleExp}),

    case get(?pd_id) of
        ?undefined ->
            pass;
        _ ->
            add_event(?GUILD_EVENT_TYPE_ADDEXP_ID, GuildId, [])
    end,

    GuildLv = 
    case dbcache:lookup(?guild_buildings_tab, GuildId) of
        [] -> 
            ?DEFAULT_GUILD_LV;
        [#guild_buildings_tab{building_list = BuildingList}] ->
            case lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList) of
                false -> 
                    ?DEFAULT_GUILD_LV;
                {?GUILD_BUILDING_ID, BuildingLv, _BuildingExp} -> 
                    BuildingLv
            end
    end,
    N = {GuildLv, GuildTab#guild_tab.totle_player, get_base_guild_id(GuildId)},%% {公会等级,公会人数,公会ID}
    ranking_lib:update(?ranking_guild, GuildId, N),
    util:is_flush_rank_only_by_rankname(?ranking_guild, GuildId).
%%    ranking_lib:flush_rank_only_by_rankname(?ranking_guild).

%% 给公会加经验
guild_build_add_exp(GuildId, BuildAddExp) ->
    [#guild_buildings_tab{building_list = Buildings}] = lookup_tab(?guild_buildings_tab, GuildId),
    BuildingList =
        case lists:keyfind(1, 1, Buildings) of
            false -> [{1, ?PLAYER_GUILD_DEFAULT_LV, 0} | Buildings];
            _BuildingInfo -> Buildings
        end,
    NewBuildingList = build_direct_add_exp(1, BuildingList, BuildAddExp ,GuildId),

    guild_service:build_update_exp(GuildId, NewBuildingList, BuildAddExp).

add_event(Type, GuildId, Args) ->
    NowTime = com_time:now(),
    Content = case Type of
                  ?GUILD_EVENT_TYPE_ADDEXP_ID -> {get(?pd_id), get(?pd_name)};
                  ?GUILD_EVENT_TYPE_JOIN -> Args;
                  ?GUILD_EVENT_TYPE_REMOVE -> Args;
                  ?GUILD_EVENT_TYPE_QUIT -> Args;
                  ?GUILD_EVENT_TYPE_POSITION -> Args
              end,
    case dbcache:lookup(guild_event_tab, GuildId) of
        [] ->
            update_guild_data_to_ets(?guild_event_tab,
                #guild_event_tab{guild_id = GuildId, event_list = [{Type, Content, NowTime}]});
        [GuildEventTab] ->
            EventList = GuildEventTab#guild_event_tab.event_list,
            if
                length(EventList) == 100 ->
                    RObject = lists:reverse(tl(lists:keysort(3, EventList))),
                    update_guild_data_to_ets(?guild_event_tab,
                        GuildEventTab#guild_event_tab{event_list = [{Type, Content, NowTime} | RObject]});
                true ->
                    update_guild_data_to_ets(?guild_event_tab,
                        GuildEventTab#guild_event_tab{event_list = [{Type, Content, NowTime} | EventList]})
            end
    end.


get_memeber_online() ->
%%  ?INFO_LOG("guild id:~p",[get(?pd_guild_id)]),
    case dbcache:lookup(?guild_member_online_tab, get(?pd_guild_id)) of
        [] -> 
            [];
        [GuildMemberOnlineTab] -> 
            GuildMemberOnlineTab#guild_member_online_tab.player_list
    end.

get_memeber_online(GuildId) ->
    case dbcache:lookup(?guild_member_online_tab, GuildId) of
        [] -> 
            [];
        [GuildMemberOnlineTab] -> 
            GuildMemberOnlineTab#guild_member_online_tab.player_list
    end.

add_member_online() ->
    PlayerList = get_memeber_online(),
    NewPlayerList = 
    case lists:keyfind(get(?pd_id), 1, PlayerList) of
        false -> 
            [{get(?pd_id), self()} | PlayerList];
        {PlayerId, _PlayerPid} ->
            [{PlayerId, self()} | lists:keydelete(PlayerId, 1, PlayerList)]
    end,
    update_guild_data_to_ets(?guild_member_online_tab, #guild_member_online_tab{guild_id = get(?pd_guild_id), player_list = NewPlayerList}),
    ok.

del_member_online() ->
    case get_memeber_online() of
        [] -> 
            ok;
        PlayerList ->
            NewPlayerList = lists:keydelete(get(?pd_id), 1, PlayerList),
            update_guild_data_to_ets(?guild_member_online_tab, #guild_member_online_tab{guild_id = get(?pd_guild_id), player_list = NewPlayerList})
    end,
    ok.

%% 获取公会会长Id
get_guild_master(GuildId)->
    [GuildTab] = lookup_tab(?guild_tab, GuildId),
    GuildTab#guild_tab.master_id.

%% 获取公会的名字
get_guild_name(GuildId) ->
    [GuildTab] = lookup_tab(?guild_tab, GuildId),
    GuildTab#guild_tab.guild_name.

%% 获得公会成员Id
get_guild_member_except_master(GuildId) ->
    PlayerList = guild_service:lookup_tab(?player_guild_member, GuildId),
    MasterId = get_guild_master(GuildId),
    PlayerList -- [MasterId].

lookup_tab(?guild_tab, GuildId) ->
    [#guild_id_tab{guild_name = GuildNameBin}] = dbcache:lookup(?guild_id_tab, GuildId),
    dbcache:lookup(?guild_tab, GuildNameBin);

lookup_tab(?player_guild_member, GuildId) ->
    [#guild_player_association_tab{player_list = PlayerList}] = dbcache:lookup(?guild_player_association_tab, GuildId),
    PlayerList;

lookup_tab(Tab, Key) ->
    dbcache:lookup(Tab, Key).

update_guild_data_to_ets(Tab, Key) ->
    erase(Tab),
    dbcache:update(Tab, Key).

get_guild_boss(GuildId) ->
    case dbcache:lookup(?guild_boss_tab, GuildId) of
        [BossData] ->
            BossData;

        _ ->
            case lookup_tab(?guild_id_tab, GuildId) of
                [_Guild] -> #guild_boss{guild_id = GuildId};
                _E -> ret:error(no_guild)
            end
    end.

set_guild_boss(BossData, _Flag) ->
    update_guild_data_to_ets(?guild_boss_tab, BossData).

guild_data_init(GuildId, GenId, GuildNameBin) ->
    GuildPlayerAssociationTab = #guild_player_association_tab{guild_id = GuildId},
    GuildMemeberOnlineTab = #guild_member_online_tab{guild_id = GuildId},
    GuildEventTab = #guild_event_tab{guild_id = GuildId},
    GuildBossTab = #guild_boss{guild_id = GuildId},

    BuildingList = [{BuildingType, ?DEFAULT_GUILD_LV, 0} || BuildingType <- load_cfg_guild:lookup_cfg(?guild_buildings_cfg, #guild_buildings_cfg.building_type_id)],
    GuildBuildingsTab = #guild_buildings_tab{guild_id = GuildId, building_list = BuildingList},

    GuildIdTab = #guild_id_tab{guild_id = GuildId, guild_name = GuildNameBin},
    insert_tab(?guild_player_association_tab, GuildPlayerAssociationTab),
    insert_tab(?guild_member_online_tab, GuildMemeberOnlineTab),
    insert_tab(?guild_event_tab, GuildEventTab),
    insert_tab(?guild_buildings_tab, GuildBuildingsTab),
    insert_tab(?guild_id_tab, GuildIdTab),
    insert_tab(?guild_boss_tab, GuildBossTab),

    N = {?DEFAULT_GUILD_LV, 1, (10000-GenId)},%% {公会等级,公会人数,公会ID}

    ranking_lib:update(?ranking_guild, GuildId, N),
    %% TODO创建 一个公会，插入排序列表，重置排序。目前没有考虑公会个数大于1000个的情况
    util:is_flush_rank_only_by_rankname(?ranking_guild, GuildId),
%%    ranking_lib:flush_rank_only_by_rankname(?ranking_guild),
    ok.

insert_tab(TableName, TabRecord) ->
    dbcache:insert_new(TableName, TabRecord).

%%lookup_cfg(?guild_buildings_cfg) ->
%%    [lookup_guild_buildings_cfg(Id) || Id <- lookup_all_guild_buildings_cfg(#guild_buildings_cfg.id)].
%%
%%lookup_cfg(?guild_buildings_cfg, #guild_buildings_cfg.building_type_id) ->
%%    lookup_all_guild_buildings_cfg(#guild_buildings_cfg.building_type_id);
%%
%%lookup_cfg(?guild_shop_cfg, Key) ->
%%    lookup_guild_shop_cfg(Key);
%%
%%lookup_cfg(?guild_buildings_cfg, BuildingList) when is_list(BuildingList) ->
%%    BuildingsCFG = lookup_cfg(?guild_buildings_cfg),
%%    FunMap = fun({BuildingTypeId, BuildingLv, _BuildingExp}) ->
%%        [{Type, Count}] = [{BuildingType, DailyTotleCount} ||
%%            #guild_buildings_cfg{building_type_id = BuildingType, lv = Lv, daily_task_totlecount = DailyTotleCount}
%%                <- BuildingsCFG, BuildingType =:= BuildingTypeId, Lv =:= BuildingLv],
%%        {Type, Count}
%%    end,
%%    lists:map(FunMap, BuildingList);
%%
%%lookup_cfg(?guild_buildings_cfg, {BuildingType, BuildingLv}) ->
%%    [{LvCFG, NeedExp, Reward, NeedGuildLv, DailyTotleCount, UpdateCost}
%%        || #guild_buildings_cfg{building_type_id = BuildingTypeCFG, lv = LvCFG, need_exp = NeedExp,
%%        reward = Reward, need_guild_lv = NeedGuildLv, daily_task_totlecount = DailyTotleCount,
%%        update_cost = UpdateCost}
%%        <- lookup_cfg(?guild_buildings_cfg), BuildingTypeCFG =:= BuildingType, LvCFG =:= BuildingLv];
%%
%%lookup_cfg(?guild_buildings_cfg, {max, BuildingType, BuildingLv}) ->
%%    BuildingTypeList = [{LvCFG, NeedExp, Reward, NeedGuildLv, DailyTotleCount, UpdateCost}
%%        || #guild_buildings_cfg{building_type_id = BuildingTypeCFG, lv = LvCFG, need_exp = NeedExp,
%%        reward = Reward, need_guild_lv = NeedGuildLv, daily_task_totlecount = DailyTotleCount,
%%        update_cost = UpdateCost}
%%        <- lookup_cfg(?guild_buildings_cfg), BuildingTypeCFG =:= BuildingType],
%%    {MaxLv, MaxNeedExp, _MaxReward, _MaxNeedGuildLv, _MaxDailyTotleCount, _MaxUpdateCost} = lists:max(BuildingTypeList),
%%    [{LvCFG, NeedExp, Reward, NeedGuildLv, DailyTotleCount, UpdateCost}] =
%%        [{LvCFG_, NeedExp_, Reward_, NeedGuildLv_, DailyTotleCount_, UpdateCost_}
%%            || {LvCFG_, NeedExp_, Reward_, NeedGuildLv_, DailyTotleCount_, UpdateCost_}
%%            <- BuildingTypeList, LvCFG_ =:= BuildingLv],
%%    {MaxLv, MaxNeedExp, LvCFG, NeedExp, Reward, NeedGuildLv, DailyTotleCount, UpdateCost}.

zore_reset() ->
    ?MODULE ! zore_reset.

%% @doc 1.凌晨刷新申请公会数据
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    ranking_lib:reset_rank(?ranking_guild),% 服务器启动时清空公会排行信息

    case ets:tab2list(?guild_id_tab) of
        [] -> [];
        GuildIdTabList ->
            FunMap = fun(GuildIdTab) ->
                GuildId = GuildIdTab#guild_id_tab.guild_id,
                GuildName = GuildIdTab#guild_id_tab.guild_name,
                case dbcache:lookup(?guild_tab, GuildName) of
                    [] -> [];
                    [GuildTab] ->
                        %% ?DEBUG_LOG("GuildTab:~p", [GuildTab]),
                        GuildLv = 
                        case dbcache:lookup(?guild_buildings_tab, GuildId) of
                            [] -> 
                                ?DEFAULT_GUILD_LV;
                            [#guild_buildings_tab{building_list = BuildingList}] ->
                                case lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList) of
                                    false -> 
                                        ?DEFAULT_GUILD_LV;
                                    {?GUILD_BUILDING_ID, BuildingLv, _BuildingExp} -> 
                                        BuildingLv
                                end
                        end,
                        N = {GuildLv, GuildTab#guild_tab.totle_player, get_base_guild_id(GuildId)},%% {公会等级,公会人数,公会ID}
                        ranking_lib:update(?ranking_guild, GuildId, N)
                end
                     end,
            lists:foreach(FunMap, GuildIdTabList)
    end,

    %% 立刻刷新排行榜
    ranking_lib:flush_rank_only_by_rankname(?ranking_guild),
    %%  ?INFO_LOG("ranking_tab:~p", [dbcache:lookup(ranking_tab, ?ranking_guild)]),

    io:format("---------------------------------------------------- init guild !!! ----------~n"),
    timer_server:start(?GUILD_BOSS_TIMER_DT, {?MODULE, guild_boss_tm, []}),
    timer_server:start(?GUILD_BOSS_RESET_TIMER_DT, {?MODULE, guild_boss_reset, []}),

    ets:new(?player_apply_tab, [bag, ?named_table, ?public, {keypos, #player_apply_tab.player_id}, {?read_concurrency, ?true}, {?write_concurrency, ?true}]),
    {ok, #state{}, get_next_timeout()}.


guild_boss_tm() ->
    case ets:tab2list(?guild_id_tab) of
        [] -> [];
        GuildIdTabList ->
            FunMap =
                fun(GuildIdTab) ->
                    GuildId = GuildIdTab#guild_id_tab.guild_id,
                    guild_boss:compute_guild_boss_ret(GuildId, ?GUILD_BOSS_TIMER_DT, virtual_time:now())
                end,
            lists:foreach(FunMap, GuildIdTabList)
    end,
    timer_server:start(?GUILD_BOSS_TIMER_DT, {?MODULE, guild_boss_tm, []}).

guild_boss_reset() ->
    case ets:tab2list(?guild_id_tab) of
        [] ->
            [];
        GuildIdTabList ->
            guild_boss:try_all_reset_callcount(GuildIdTabList)
    end,
    timer_server:start(?GUILD_BOSS_RESET_TIMER_DT, {?MODULE, guild_boss_reset, []}).

ets_add(#player_apply_tab{guild_id=GuildId} = Record) ->
    ets:insert(?player_apply_tab, Record),
    guild_boss:sync_guild_apply(GuildId).








ets_lookup(Key, #player_apply_tab.player_id) -> ets:lookup(?player_apply_tab, Key);
ets_lookup(Key, #player_apply_tab.guild_id) ->
    case ets:match(?player_apply_tab, #player_apply_tab{player_id = '$1', guild_id = Key}) of
        [] -> [];
        PlayerList -> [I || [I] <- PlayerList]
    end.

is_ets_match(PlayerId, GuildId) ->
    ets:match(?player_apply_tab, #player_apply_tab{player_id = PlayerId, guild_id = GuildId}) =/= [].

handle_call({guild_boss, Request}, {FromPid, _}, State) ->
    Ret = guild_boss:on_request(Request, FromPid),
    {reply, Ret, State, player_eng:get_next_timeout()};

handle_call({guild_apply, Request}, {_FromPid, _}, State) ->
    ets_add(Request),
    {reply, ok, State, get_next_timeout()};




handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State, get_next_timeout()}.

handle_cast(_Msg, State) ->
    {noreply, State, get_next_timeout()}.

%% @doc 公会凌晨刷新数据。目前包含：1.清空入会申请数据
handle_info(zore_reset, State) ->
    ets:delete_all_objects(?player_apply_tab),
    {noreply, State, get_next_timeout()};

handle_info(timeout, State) ->
    %TimeAxle = timer_server:get_timeaxle(),
    timer_server:handle_min_timeout(),
    {noreply, State, get_next_timeout()};

handle_info(_Msg, State) ->
    {noreply, State, get_next_timeout()}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

load_db_table_meta() ->
    [

        #db_table_meta{name = ?guild_id_tab,
            fields = ?record_fields(?guild_id_tab),
            load_all = ?true,
            shrink_size = 10,
            flush_interval = 10},

        #db_table_meta{name = ?guild_tab,
            fields = ?record_fields(?guild_tab),
            load_all = ?true,
            shrink_size = 50,
            flush_interval = 10},

        #db_table_meta{name = ?guild_player_association_tab,
            fields = ?record_fields(?guild_player_association_tab),
            load_all = ?true,
            shrink_size = 10,
            flush_interval = 10},

        #db_table_meta{name = ?guild_member_online_tab,
            fields = ?record_fields(?guild_member_online_tab),
            load_all = ?true,
            shrink_size = 10,
            flush_interval = 10},

        #db_table_meta{name = ?guild_buildings_tab,
            fields = ?record_fields(?guild_buildings_tab),
            load_all = ?true,
            shrink_size = 10,
            flush_interval = 10},

        #db_table_meta{name = ?guild_event_tab,
            fields = ?record_fields(?guild_event_tab),
            load_all = ?true,
            shrink_size = 50,
            flush_interval = 10},

        #db_table_meta{name = ?guild_boss_tab,
            fields = ?record_fields(?guild_boss_tab),
            load_all = ?true,
            shrink_size = 50,
            flush_interval = 10}
    ].


get_next_timeout() ->
    %TimeAxle = timer_server:get_timeaxle(),
    Dt = timer_server:get_next_timeout_dt(),
    Dt.

get_guild_rank_info(GuildId) ->
    [#guild_tab{guild_name = GuildName, totem_id = TotemId, border_id = BorderId,master_id = MasterId,totle_player = TotlePlayer}] = lookup_tab(?guild_tab, GuildId),

                    GuildLv =
                        case dbcache:lookup(?guild_buildings_tab, GuildId) of
                            [] ->
                                ?DEFAULT_GUILD_LV;
                            [#guild_buildings_tab{building_list = BuildingList}] ->
                                case lists:keyfind(?GUILD_BUILDING_ID, 1, BuildingList) of
                                    false ->
                                        ?DEFAULT_GUILD_LV;
                                    {?GUILD_BUILDING_ID, BuildingLv, _BuildingExp} ->
                                        BuildingLv
                                end
                        end,
                    [MasterName] = player:lookup_info(MasterId, [?pd_name]),
    { GuildId, 0, TotemId, BorderId, GuildLv, GuildName, MasterId, MasterName }.

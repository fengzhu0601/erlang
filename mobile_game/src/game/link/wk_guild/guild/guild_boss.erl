%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 五月 2016 下午3:52
%%%-------------------------------------------------------------------
-module(guild_boss).
-author("clark").

%% API
-export
([
    get_boss_info/0
    , is_boss_open/1
    , can_action/2
    , action/2
    , sync_boss_info/0
    , sync_all_guild_member_msg/2
    , over_boss/4
    , compute_guild_boss_ret/3
    , get_boss_info/1
    , sync_boss_hp/0
    , sync_boss_hp/1
    , get_boss_damage_all_rank/1
    , get_compele_info/2
    , start_self_guild_boss_fight/0
    , is_guild_boss_fight/0
    , stop_self_guild_boss_fight/0
    , get_guild_boss_recordid/0
    , broadcast_mes/2
    , rank_data_guild_boss/3
    , try_all_reset_callcount/1
    , add_guild_contribution/1
    , sync_guild_apply/1
    , sync_self_apply/0
    , get_guild_master/2
]).

-export
([
    on_request/2
]).



-include("guild_define.hrl").
-include("player.hrl").
-include("inc.hrl").
-include("rank.hrl").
-include("system_log.hrl").
-include("achievement.hrl").


-define(do_guild_boss_fight, 'do_guild_boss_fight').



get_guild_master(GuildId, Position) ->
    Key = #player_guild_member
    {
        player_id='$1',            %玩家ID（一个玩家只能有一个公会）
        guild_id=GuildId,             %公会ID
        player_position=Position,      %用户职位ID
        join_time='_',            %加入时
        totle_exp='_',          %总贡献值
        lv='_',                 %在该公会达到的会员等级
        exp='_',                %在该等级得到的贡献值
        daily_task_count='_'   %日常提升贡献值剩余使用次数[{BuildingType:建筑类型, Num:次数}]
    },
    case ets:match(?player_guild_member, Key) of
        [] -> [];
        PlayerList -> [ Id || [Id] <- PlayerList ]
    end.


sync_guild_apply(GuildId) ->
    Len =
        case guild_service:ets_lookup(GuildId, #player_apply_tab.guild_id) of
            [] -> 0;
            PlayerIdList -> erlang:length(PlayerIdList)
        end,
    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_APPLY_UPDATE, {Len}),
    MasterList = get_guild_master(GuildId, ?GUILD_MASTER_POSITIONID),
    [ world:send_to_player_if_online(I, {?send_to_client, MsgBag}) || I <- MasterList],
    ViceMasterList = get_guild_master(GuildId, ?GUILD_VICE_MASTER_POSTION),
    [ world:send_to_player_if_online(I1, {?send_to_client, MsgBag}) || I1 <- ViceMasterList].


sync_self_apply() ->
    GuildId = util:get_pd_field(?pd_guild_id, 0),
    if
        GuildId > 0 ->
            Pos = get(?pd_guild_position),
            MyPlayerId = get(?pd_id),
            Can =
                if
                    Pos == ?GUILD_MASTER_POSITIONID -> true;
                    Pos == ?GUILD_VICE_MASTER_POSTION -> true;
                    true -> false
                end,
            if
                Can ->
                    case guild_service:ets_lookup(GuildId, #player_apply_tab.guild_id) of
                        [] ->
                            pass;

                        PlayerIdList ->
                            Len = erlang:length(PlayerIdList),
                            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_APPLY_UPDATE, {Len}),
                            % ?INFO_LOG("------------ ets_add PlayerIdList ------------ ~p", [{MyPlayerId, PlayerIdList, Len, MsgBag}]),
                            ?player_send(MsgBag)
                    end;

                true ->
                    pass
            end;

        true ->
            ok
    end.


rank_data_guild_boss(_StartPos, _Len, _RankLen) ->
    MyPlayerId = get(?pd_id),
    GuildId = get(?pd_guild_id),
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} ->
            DamageList = util:get_field(List, ?GUILD_BOSS_KEY_DAMAGE_RANK, []),

            [#player_guild_member{player_position = Pos}] = dbcache:lookup(?player_guild_member, MyPlayerId),
            [Car, Name, Level, Power] = player:lookup_info(MyPlayerId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
            RankItem =
                case util:get_field(DamageList, MyPlayerId, 0) of
                    {Sort, Damage} ->
                        {Sort, Car, MyPlayerId, Name, Level, Pos, Power, Damage};

                    _ ->
                        {0, Car, MyPlayerId, Name, Level, Pos, Power, 0}
                end,
            RetList =
                lists:foldl
                (
                    fun({DamangePlayerId, {Sort1, Damage1}}, RetTmp) ->
                        if
                            Damage1 > 0 ->
                                [#player_guild_member{player_position = Pos1}] = dbcache:lookup(?player_guild_member, DamangePlayerId),
                                [Car1, Name1, Level1, Power1] = player:lookup_info(DamangePlayerId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
                                [ {Sort1, Car1, DamangePlayerId, Name1, Level1, Pos1, Power1, Damage1} | RetTmp];

                            true ->
                                RetTmp
                        end
                    end,
                    [],
                    DamageList
                ),
%%             RetList1 = lists:reverse(RetList),
            {RankItem, erlang:length(RetList), RetList};

        _ ->
            ret:error(no_guild_boss)
    end.


try_all_reset_callcount(GuildIdTabList) ->
    {TempY, TempM, TempD} = virtual_time:date(),
    WeekDay = calendar:day_of_the_week(TempY,TempM,TempD),
    if
        1 == WeekDay ->
            case load_db_misc:get_guild_boss_reset_tm() of
                {TempY, TempM, TempD} ->
                    pass;

                _ ->
                    io:format("---------------- 周一重置召唤 ----------------~n"),
                    load_db_misc:set_guild_boss_reset_tm({TempY, TempM, TempD}),
                    FunMap =
                        fun(GuildIdTab) ->
                            GuildId = GuildIdTab#guild_id_tab.guild_id,
                            case guild_service:get_guild_boss(GuildId) of
                                #guild_boss{field = List} = Boss ->
                                    List1 = util:set_field(List, ?GUILD_BOSS_KEY_CALL_COUNT, 0),
                                    Boss1 = Boss#guild_boss{field = List1},
                                    guild_service:set_guild_boss(Boss1, guild_boss_reset);

                                _ ->
                                    pass
                            end
                        end,
                    lists:foreach(FunMap, GuildIdTabList)
            end;

        true ->
            pass
    end.



%% 献祭
on_request(#guild_boss_donate{ guild_id=GuildId, donate_val=AddVal }, _FromPid) ->
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} = Boss ->
            Exp = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_EXP, 0),
            Exp1 = Exp + AddVal,
            List1 = util:set_field(List, ?GUILD_BOSS_KEY_BOSS_EXP, Exp1),
            Boss1 = Boss#guild_boss{field = List1},
            guild_service:set_guild_boss(Boss1, guild_boss_donate),
            {ok, Boss1};

        _ ->
            ret:error(no_guild_boss)
    end;


%% 进阶
on_request(#guild_boss_phase{guild_id=GuildId}, _FromPid) ->
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} = Boss ->
            Id = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
            Exp = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_EXP, 0),
            Dt = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, 0),
            NeetExp = load_cfg_guild_boss:get_next_exp(Id),
            if
                Dt > 0 ->
                    ret:error(is_fighting);

                Exp >= NeetExp ->
                    case load_cfg_guild_boss:get_next_record_id(Id) of
                        0 ->
                            ret:error(no_next_boss);

                        NextId ->
                            List1 = util:set_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, NextId),
                            List2 = util:set_field(List1, ?GUILD_BOSS_KEY_BOSS_EXP, 0),
                            Boss1 = Boss#guild_boss{field = List2},
                            guild_service:set_guild_boss(Boss1, guild_boss_phase),
                            {ok, Boss1}
                    end;

                true ->
                    ret:error(no_boss_exp)
            end;

        _ ->
            ret:error(no_guild_boss)
    end;



%% 召唤
on_request(#guild_boss_call{guild_id=GuildId}, _FromPid) ->
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} = Boss ->
            BossDt = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, 0),
            if
                BossDt > 0 ->
                    {ok, Boss};

                true ->
                    CallCount = util:get_field(List, ?GUILD_BOSS_KEY_CALL_COUNT, 0),
                    CallLimit = load_cfg_guild_boss:lookup(summon_num, 0),
                    if
                        CallCount < CallLimit ->
                            RecordID = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
                            Hp = load_cfg_guild_boss:get_monster_hp(RecordID),
                            List1 = util:set_field(List, ?GUILD_BOSS_KEY_BOSS_HP, Hp),
                            List2 = util:set_field(List1, ?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, load_cfg_guild_boss:get_monster_dt(RecordID)),
                            List3 = util:set_field(List2, ?GUILD_BOSS_KEY_DAMAGE_TOTAL, []),
                            List4 = util:set_field(List3, ?GUILD_BOSS_KEY_DAMAGE_RANK, []),
                            List5 = util:set_field(List4, ?GUILD_BOSS_KEY_CALL_TIME, virtual_time:now()),
                            List6 = util:set_field(List5, ?GUILD_BOSS_KEY_CALL_COUNT, CallCount+1),
                            List7 = util:set_field(List6, ?GUILD_BOSS_KEY_BE_KILLED, 0),
                            Boss1 = Boss#guild_boss{field = List7},
                            guild_service:set_guild_boss(Boss1, guild_boss_call),
                            sync_all_boss_info(GuildId),
                            {ok, Boss1};

                        true ->
                            ret:error(no_guild_boss)
                    end
            end;

        _ ->
            ret:error(no_guild_boss)
    end;

%% 伤害
on_request(#guild_boss_damage{guild_id=GuildId, damage=Damage, killer_id=KillerId, record_id=Rd}, _FromPid) ->
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} = Boss ->
            Id = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
            %% 600秒后击杀bossId不会改变
            BossIsKilled = util:get_field(List, ?GUILD_BOSS_KEY_BE_KILLED, 0),
            if
                Rd == Id andalso BossIsKilled == 0 ->
                    Hp = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_HP, 0),
                    DamageRank = util:get_field(List, ?GUILD_BOSS_KEY_DAMAGE_TOTAL, []),
                    OldDamage = util:get_field(DamageRank, KillerId, 0),

                    Hp1 = erlang:max(0, Hp - Damage),
                    List1 = util:set_field(List, ?GUILD_BOSS_KEY_BOSS_HP, Hp1),
                    NewDamage = OldDamage + Damage,
                    DamageRank1 = util:set_field(DamageRank, KillerId, NewDamage),
                    List2 = util:set_field(List1, ?GUILD_BOSS_KEY_DAMAGE_TOTAL, DamageRank1),

                    Boss1 = Boss#guild_boss{field = List2},
                    guild_service:set_guild_boss(Boss1, guild_boss_damage),

                    % ?INFO_LOG("----------------------- BossCurHp ~p -----------------------",[Hp1]),
                    if
                        Hp1 =< 0 ->
                            ?INFO_LOG("---------- on kill  ------- GUILD_BOSS_KEY_BOSS_RECORD_ID ~p", [Id]),
                            over_boss(kill, GuildId, Id, KillerId);
                        true ->
                            pass
                    end,
                    {ok, Boss1};

                true ->
                    ret:error(error_guild_boss)
            end;

        _ ->
            ret:error(no_guild_boss)
    end;

%% 重置
on_request(#guild_boss_reset{guild_id=GuildId}, _FromPid) ->
    Boss = #guild_boss{guild_id = GuildId},
    guild_service:set_guild_boss(Boss, guild_boss_reset),
    {ok, Boss};




on_request(_Request, _FromPid) ->
    ok.


%% 获得某人结算信息
get_compele_info(PlayerId, GuildId) ->
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} ->
            RecordId = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
            DamageList = util:get_field(List, ?GUILD_BOSS_KEY_DAMAGE_RANK, []),
            {Sort, Damage} = util:get_field(DamageList, PlayerId, {0,0}),
            case player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level]) of
                [Car, Name, Level] ->
                    player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level]),
                    PrizeList = load_cfg_guild_boss:get_sort_prize(RecordId, Sort),
                    {Sort, Car, Name, Level, Damage, PrizeList};

                _Erro ->
                    ret:error(no_guild_boss)
            end;

        _ ->
            ret:error(no_guild_boss)
    end.


compele_guild_boss_prize(GuildId,KillerId) ->
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} ->
            RecordId = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
%%            KillerId = util:get_field(List, ?GUILD_BOSS_KEY_KILLER, 0),
            DamageList = util:get_field(List, ?GUILD_BOSS_KEY_DAMAGE_RANK, []),
            lists:foreach
            (
                fun({PlayerId, {Sort, _Damage}}) ->
                    %% [Name] =  player:lookup_info(PlayerId, [?pd_name]),
                    PrizeList = load_cfg_guild_boss:get_sort_prize(RecordId, Sort),
                    mail_mng:send_sysmail(PlayerId, ?S_MAIL_GUILD_BOSS_CHALLENGE, PrizeList),%% Boss挑战奖励人人有

                    if
                        KillerId == PlayerId ->
                            Prizelist1 = load_cfg_guild_boss:get_kill_prize(RecordId),
                            world:send_to_player_if_online(PlayerId, ?mod_msg(guild_handle_client, {shuijingzhongjiezhe})),
                            mail_mng:send_sysmail(PlayerId, ?S_MAIL_GUILD_BOSS_KILL, Prizelist1); %% 击杀奖励

                        true ->
                            pass
                    end,

                    %% 该bossId第一次被击杀
                    FirstKiller = load_db_guild_first_kill:get(RecordId, 0),
                    case FirstKiller of
                        0 ->
                            PrizeList2 = load_cfg_guild_boss:get_first_kill_prize(RecordId),
                            mail_mng:send_sysmail(PlayerId, ?S_MAIL_GUILD_BOSS_FIRST_KILL, PrizeList2), %% 首杀奖励
                            load_db_guild_first_kill:set(RecordId, PlayerId),
                            ok;

                        _ ->
                            pass
                    end
                end,
                DamageList
            );

        _ ->
            ret:error(no_guild_boss)
    end.


%% ---------------------------------------
get_boss_info() ->
    GuildId = get(?pd_guild_id),
    guild_service:get_guild_boss(GuildId).
get_boss_info(GuildId) ->
    guild_service:get_guild_boss(GuildId).

%% 能否献祭
can_action(?GUILD_BOSS_DONATE, {RecordId}) ->
    Donate = util:get_pd_field(?pd_guild_boss_donate, 0),
    NumLimit = load_cfg_guild_boss:lookup(immo_num, 0),
    if
        Donate < NumLimit ->
            case load_cfg_guild_boss:get_donate_consume(RecordId) of
                {error, Error} -> {error, Error};
                CostList -> game_res:can_del(CostList)
            end;

        true ->
            ret:error(no_donate_count)
    end;


%% 能否进阶
can_action(?GUILD_BOSS_PHASE, {RecordId}) ->
    case load_cfg_guild_boss:get_advance_consume(RecordId) of
        {error, Error} -> {error, Error};
        CostList -> game_res:can_del(CostList)
    end;

%% 公会boss召唤
can_action(?GUILD_BOSS_CALL, {RecordId}) ->
    Pos = get(?pd_guild_position),
    Can =
        if
            Pos == ?GUILD_MASTER_POSITIONID -> true;
            Pos == ?GUILD_VICE_MASTER_POSTION -> true;
            true -> false
        end,
    if
        Can ->
            case load_cfg_guild_boss:get_call_consume(RecordId) of
                {error, Error} -> {error, Error};
                CostList -> game_res:can_del(CostList)
            end;

        true ->
            ret:error(error_position)
    end;


%% 公会boss买活
can_action(?GUILD_BOSS_REVIVE, {RecordId}) ->
    case load_cfg_guild_boss:get_revive_consume(RecordId) of
        {error, Error} -> {error, Error};
        CostList -> game_res:can_del(CostList)
    end;

can_action(_ActionKey, _Args) ->
    ok.



%% 公会boss献祭
action(?GUILD_BOSS_DONATE, {RecordId}) ->
    Donate = util:get_pd_field(?pd_guild_boss_donate, 0),
    util:set_pd_field(?pd_guild_boss_donate, Donate+1),
    case load_cfg_guild_boss:get_donate_consume(RecordId) of
        {error, Error} -> {error, Error};
        CostList ->
            game_res:del(CostList, ?FLOW_REASON_GUILD_BOSS_DONATE),
            PrizeId = load_cfg_guild_boss:lookup(immo_prize, []),
            prize:prize(PrizeId, ?FLOW_REASON_GUILD_BOSS_DONATE),
            GuildTotalContribution = get(?pd_guild_totle_contribution),
            {PlayerLv, PlayerExp} = guild_mng:get_guild_player_lv_and_exp_by_contribution(GuildTotalContribution),
            put(?pd_guild_lv, PlayerLv),
            put(?pd_guild_exp, PlayerExp),
            guild_mng:push_role_data()
    end,
    ok;

%% 公会boss进阶
action(?GUILD_BOSS_PHASE, {RecordId}) ->
    case load_cfg_guild_boss:get_advance_consume(RecordId) of
        {error, Error} ->
            {error, Error};

        CostList ->
            game_res:del(CostList, ?FLOW_REASON_GUILD_BOSS_PHASE),
            PrizeId = load_cfg_guild_boss:lookup(advance_prize, []),
            prize:prize(PrizeId, ?FLOW_REASON_GUILD_BOSS_PHASE),
            GuildTotalContribution = get(?pd_guild_totle_contribution),
            {PlayerLv, PlayerExp} = guild_mng:get_guild_player_lv_and_exp_by_contribution(GuildTotalContribution),
            put(?pd_guild_lv, PlayerLv),
            put(?pd_guild_exp, PlayerExp),
            guild_mng:push_role_data()
    end,
    ok;

%% 公会boss召唤
action(?GUILD_BOSS_CALL, {RecordId}) ->
    case load_cfg_guild_boss:get_call_consume(RecordId) of
        {error, Error} ->
            {error, Error};

        CostList ->
            game_res:del(CostList, ?FLOW_REASON_GUILD_BOSS_CALL)
    end,
    ok;

%% 公会boss买活
action(?GUILD_BOSS_REVIVE, {RecordId}) ->
    case load_cfg_guild_boss:get_revive_consume(RecordId) of
        {error, Error} ->
            {error, Error};

        CostList ->
            game_res:del(CostList, ?FLOW_REASON_GUILD_BOSS_RELIVE)
    end,
    ok;



action(_ActionKey, _Args) ->
    ok.





%% 发送公告信息
broadcast_mes(GuildId, Notice) ->
    Pkg = chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM, {list_to_binary(Notice)}),
    guild_boss:sync_all_guild_member_msg(GuildId, Pkg),
    ok.

get_guild_boss_recordid() ->
    case guild_boss:get_boss_info() of
        #guild_boss{field = List} ->
            Id = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
            Id;
        _ ->
            0
    end.

sync_boss_info() ->
    case guild_boss:get_boss_info() of
        #guild_boss{field = List} ->
            Id = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
            Exp = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_EXP, 0),
            Hp = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_HP, 0),
            Challage = util:get_pd_field(?pd_guild_boss_challage, 0),
            Donate = util:get_pd_field(?pd_guild_boss_donate, 0),
            CallCount = util:get_field(List, ?GUILD_BOSS_KEY_CALL_COUNT, 0),
            BossEndDt = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, 0),
            BossEndTime = util:get_field(List, ?GUILD_BOSS_KEY_CALL_TIME, 0),
            BossEndTime1 = BossEndTime + BossEndDt,
            % ?INFO_LOG("call_ret ~p", [{BossEndTime, BossEndDt, BossEndTime1}]),
            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_INFO, {Id, Exp, Hp, BossEndTime1, Challage, Donate, CallCount}),
            ?player_send(MsgBag);

        _ ->
            error
    end.

sync_all_boss_info(GuildId) ->
    MemberList = guild_service:lookup_tab(?player_guild_member, GuildId),
    world:send_to_player_if_online(MemberList, ?mod_msg(guild_handle_client, {sync_guild_boss})).



sync_boss_hp() ->
    sync_boss_hp(false).




%% 获得某人伤害信息
get_damage_info_list(PlayerId, GuildId) ->
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} ->
            DamageList = util:get_field(List, ?GUILD_BOSS_KEY_DAMAGE_RANK, []),
            case util:get_field(DamageList, PlayerId, {0,0}) of
                {Sort, Damage} ->
                    [Car, Name] = player:lookup_info(PlayerId, [?pd_career, ?pd_name]),
                    Len = erlang:length(DamageList),
                    if
                        Len < 2 ->
                            [{Sort,Car,Name,Damage}];

                        true ->
                            if
                                1 == Sort ->
                                    {PlayerId2, {Sort2, Damage2}} = lists:nth(2, DamageList),
                                    [Car2, Name2] = player:lookup_info(PlayerId2, [?pd_career, ?pd_name]),
                                    [{Sort,Car,Name,Damage}, {Sort2,Car2,Name2,Damage2}];

                                true ->
                                    {PlayerId2, {Sort2, Damage2}} = lists:nth(1, DamageList),
                                    [Car2, Name2] = player:lookup_info(PlayerId2, [?pd_career, ?pd_name]),
                                    [{Sort2,Car2,Name2,Damage2}, {Sort,Car,Name,Damage}]
                            end
                    end
            end;


        _ ->
            ret:error(no_guild_boss)
    end.

get_boss_damage_all_rank(GuildId) ->
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} ->
            DamageList = util:get_field(List, ?GUILD_BOSS_KEY_DAMAGE_RANK, []),
            Ret =
                lists:foldl
                (
                    fun({PlayerId, {Sort, Damage}}, RetList)->
                        [Car, Name, Level, Power] = player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
                        [{Sort, Car, PlayerId, Name, Level, 1, Power, Damage}|RetList]
                    end,
                    [],
                    DamageList
                ),
            Ret;

        _ ->
            []
    end.


sync_boss_hp(SyncFlag) ->
    GuildId = get(?pd_guild_id),
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} ->
            Id = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
            Hp = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_HP, 0),
            Flag =
                if
                    Hp > 0 -> true;
                    true ->
                        if
                            SyncFlag -> true;
                            true -> false
                        end
                end,
            if
                Flag ->
                    RetList = get_damage_info_list(get(?pd_id), GuildId),
                    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_DAMAGE, {Id, Hp, RetList}),
                    ?player_send(MsgBag);

                true ->
                    pass
            end;

        _ ->
            ret:error(no_guild_boss)
    end.




sync_all_guild_member_msg(GuildId, Msg) ->
    MemberList = guild_service:lookup_tab(?player_guild_member, GuildId),
    world:send_to_player_if_online(MemberList, {?send_to_client, Msg}).

try_broadcast_boss_is_exist(GuildId, GuildBossLists) ->
    BoardcastNum = util:get_field(GuildBossLists, ?GUILD_BOSS_KEY_BOARDCAST, 0),
    case load_cfg_guild_boss:get_boss_exist_broadcast(BoardcastNum+1) of
        {TimeDt, BroadcastId} ->
            BossEndTime = util:get_field(GuildBossLists, ?GUILD_BOSS_KEY_CALL_TIME, 0),
            NowTime = virtual_time:now(),
            Dt = NowTime - BossEndTime,
            if
                Dt > TimeDt ->
%%                    guild_boss:sync_all_guild_member_chat(GuildId, BroadcastId, []),
                    GuildBossLists1 = util:set_field(GuildBossLists, ?GUILD_BOSS_KEY_BOARDCAST, BoardcastNum+1),
                    GuildBossLists1;

                true ->
                    GuildBossLists
            end;

        _ ->
            GuildBossLists
    end.


%% 计算公会BOSS结果
compute_guild_boss_ret(GuildId, _Dt, NowTime) ->
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} = Boss ->
            BossDt = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, 0),
            if
                BossDt > 0 ->
                    BossId = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
                    BossEndDt = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, 0),
                    BossEndTime = util:get_field(List, ?GUILD_BOSS_KEY_CALL_TIME, 0),
                    BossEndTime1 = BossEndTime + BossEndDt,

                    DamageRank = util:get_field(List, ?GUILD_BOSS_KEY_DAMAGE_TOTAL, []),
                    DamageRank1 = lists:keysort(2, DamageRank),
                    Len = erlang:length(DamageRank1),
                    {_T, DamageRank2} =
                        lists:foldl
                        (
                            fun({PlayerId, Damage}, {Num, RetList}) ->
                                {Num-1, [{PlayerId, {Num, Damage}} | RetList]}
                            end,
                            {Len, []},
                            DamageRank1
                        ),
                    DamageRank3 = lists:reverse(DamageRank2),
                    List2 = util:set_field(List, ?GUILD_BOSS_KEY_DAMAGE_RANK, DamageRank3),
                    List3 = try_broadcast_boss_is_exist(GuildId, List2),
                    Boss1 = Boss#guild_boss{field = List3},
                    guild_service:set_guild_boss(Boss1, compute_guild_boss_ret),


                    if
                        BossEndTime1 =< NowTime -> over_boss(time_out, GuildId, BossId, 0);
                        true -> pass
                    end;

                true ->
                    pass
            end;

        _ ->
            pass
    end.

stop_boss(GuildId, KillerId) ->
    if
        KillerId > 0 ->  compele_guild_boss_prize(GuildId, KillerId);
        true -> pass
    end,
    case guild_service:get_guild_boss(GuildId) of
        #guild_boss{field = List} = Boss ->
            CallTm = util:get_field(List, ?GUILD_BOSS_KEY_CALL_TIME, 0),
            RecordId = util:get_field(List, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, 0),
            BossDt = virtual_time:now() - CallTm,
            RecordId1 =
                if
                    KillerId > 0 ->
                        case load_cfg_guild_boss:get_uplvl_boss(RecordId, BossDt) of
                            0 -> RecordId;
                            NewRecordId -> NewRecordId
                        end;

                    true ->
                        RecordId
                end,
            List1 = util:set_field(List, ?GUILD_BOSS_KEY_BOSS_HP, 0),
            List2 = util:set_field(List1, ?GUILD_BOSS_KEY_BOSS_OVER_TIME_DT, 0),
            List3 = util:set_field(List2, ?GUILD_BOSS_KEY_BOSS_RECORD_ID, RecordId1),
            List4 = util:set_field(List3, ?GUILD_BOSS_KEY_KILLER, KillerId),
            List5 = util:set_field(List4, ?GUILD_BOSS_KEY_BE_KILLED, 1),
            Boss1 = Boss#guild_boss{field = List5},
            guild_service:set_guild_boss(Boss1, stop_boss),
            ok;

        _ ->
            pass
    end.



over_boss(time_out, GuildId, BossId, _Killer) ->
    ?INFO_LOG("time_out"),
    stop_boss(GuildId, 0),
    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_COMPELE, {BossId, 0, 0}),
    sync_all_guild_member_msg(GuildId, MsgBag),
    ok;

over_boss(kill, GuildId, BossId, Killer) ->
    compute_guild_boss_ret(GuildId, 0, virtual_time:now()),
    stop_boss(GuildId, Killer),
    MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_COMPELE, {BossId, Killer, 1}),
    sync_all_guild_member_msg(GuildId, MsgBag),
%%    ?INFO_LOG("kill bossId =--------------------------------- ~p", [BossId]),
    notice_system:first_kill_guild_boss(BossId, Killer, GuildId),
    notice_system:send_kill_guild_boss_notice(BossId, Killer, GuildId),     %% 下发kill公告到当前公会的玩家
    ok;



over_boss(_OverType, _GuildId, _BossId, _) ->
    ?INFO_LOG("boss is over").

%% -----------------------------------------------------------------

%% boss挑战功能在公会大厅达到特定等级后开放。
is_boss_open(GuildId) ->
    Lvl = guild_service:select_guild_lv(GuildId),
    if
        Lvl > 5 -> ret:ok();
        true -> ret:error(guild_lvl_error)
    end.


add_guild_contribution(Num) ->
    case get(?pd_guild_id) of
        0 -> ok;
        _GuildId ->
            OldVal = util:get_pd_field(?pd_guild_totle_contribution,0),
            util:set_pd_field(?pd_guild_totle_contribution, OldVal+Num),
            util:get_pd_field(?pd_guild_totle_contribution,0)
    end.
































start_self_guild_boss_fight() ->
    % ?INFO_LOG("--------------------------------- start_self_guild_boss_fight --------------------"),
    util:set_pd_field(?do_guild_boss_fight, 1),
    ok.


is_guild_boss_fight() ->
    case util:set_pd_field(?do_guild_boss_fight, 0) of
        1 -> true;
        _ -> false
    end.

stop_self_guild_boss_fight() ->
    util:del_pd_field(?do_guild_boss_fight),
    % ?INFO_LOG("--------------------------------- stop_self_guild_boss_fight --------------------"),
    case guild_boss:get_boss_info() of
        #guild_boss{field = BossList} ->
            PlayerId = get(?pd_id),
            GuildId = get(?pd_guild_id),
            MyBoss = guild_boss:get_compele_info(PlayerId, GuildId),
            BossList1 = util:get_field(BossList, ?GUILD_BOSS_KEY_DAMAGE_RANK, []),
            BossList2 = lists:sublist(BossList1, 1, 3),
            OtherPlayerList =
                lists:foldl
                (
                    fun({OtherPlayerId, _Tmp}, Ret) ->
                        OtherBoss = guild_boss:get_compele_info(OtherPlayerId, GuildId),
                        [OtherBoss | Ret]
                    end,
                    [],
                    BossList2
                ),
            MsgBag = guild_sproto:pkg_msg(?MSG_GUILD_BOSS_COMPELE_PRIZE, {1, MyBoss, OtherPlayerList}),
            ?player_send(MsgBag);

        _ ->
            error
    end,
    ok.



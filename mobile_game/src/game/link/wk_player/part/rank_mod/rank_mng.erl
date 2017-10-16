-module(rank_mng).

-include("inc.hrl").
-include("player.hrl").
-include("rank.hrl").
-include("handle_client.hrl").



-export([
    listen_lev/2,
    listen_power/2,
    get_gwgc_jifen/1
    % listen_friend_score/2,
    % rank_data/4
]).
-define(DISPLAY_RANK_LEN, 200).


get_gwgc_jifen(PlayerId) ->
    {_MyIndex, JiFen} = ranking_lib:get_rank_order(?ranking_gwgc, PlayerId),
    JiFen.




listen_lev(Id, Level) when Level > 0 ->
    ranking_lib:update(?ranking_level, Id, Level);
listen_lev(_Id, _Exp) -> ignore.

listen_power(Id, Power) when Power > 0 ->
    ranking_lib:update(?ranking_zhanli, Id, Power);
listen_power(_Id, _Power) -> ignore.

% listen_friend_score(Id, FScore) when FScore > 0 ->
%     ranking_lib:update(?ranking_friend_score, Id, FScore);
% listen_friend_score(_Id, _FScore) -> ignore.

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

handle_client(?MSG_RANK_LEV, {StartPos, Len}) ->
    {Size, StartRank, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_level, 100),
    RankInfos = rank_infos(?MSG_RANK_LEV, StartRank, Ranks, []),
    {MyIndex, _MyLev} = ranking_lib:get_rank_order(?ranking_level, get(?pd_id)),
    %?DEBUG_LOG("MyIndex--------:~p",[MyIndex]),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_LEV, {MyIndex, Size, RankInfos})),
    ok;
handle_client(?MSG_RANK_POWER, {StartPos, Len}) ->
    {Size, StartRank, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_zhanli, ?DISPLAY_RANK_LEN),
    RankInfos = rank_infos(?MSG_RANK_POWER,StartRank, Ranks, []),
    {MyIndex, _MyPower} = ranking_lib:get_rank_order(?ranking_zhanli, get(?pd_id)),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_POWER, {MyIndex, Size, lists:keysort(1,RankInfos)})),
    ok;

handle_client(?MSG_RANK_GWGC, {StartPos, Len}) ->
    %?DEBUG_LOG("StartPos-----:~p----Len----:~p",[StartPos, Len]),
    {Size, StartRank, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_gwgc, 201),
    %?DEBUG_LOG("Size----:~p---StartRank----:~p-----RankS---:~p",[Size, StartRank, Ranks]),
    RankInfos = rank_infos(?MSG_RANK_GWGC,StartRank, Ranks, []),
    %?DEBUG_LOG("RankInfos--------------------:~p",[RankInfos]),
    Id = get(?pd_id),
    {MyIndex, JiFen} = ranking_lib:get_rank_order(?ranking_gwgc, get(?pd_id)),
    [Car, Name, Level, Power] = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    MyData = {MyIndex, Car, Id, Name, Level, Power, JiFen},
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_GWGC, {MyData, Size, RankInfos})),
    ok;

%% 赏金任务排行
handle_client(?MSG_RANK_BOUNTY, {StartPos, Len}) ->
    %%?DEBUG_LOG("StartPos-----:~p----Len----:~p",[StartPos, Len]),
    {Size, StartRank, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_bounty, 10),
    %% ?DEBUG_LOG("Size----:~p---StartRank----:~p-----RankS---:~p",[Size, StartRank, Ranks]),
    RankInfos = rank_infos(?MSG_RANK_BOUNTY, StartRank, Ranks, []),
    %% ?DEBUG_LOG("RankInfos--------------------:~p",[RankInfos]),
    Id = get(?pd_id),
    {MyIndex, Liveness} = ranking_lib:get_rank_order(?ranking_bounty, get(?pd_id)),
    [Car, Name, Level, Power] = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    MyData = {MyIndex, Car, Id, Name, Level, Power, Liveness},
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_BOUNTY, {MyData, Size, lists:keysort(1,RankInfos)})),
    ok;

handle_client(?MSG_RANK_ARENA, {StartPos, Len}) ->
    {Size, StartRank, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_arena, ?DISPLAY_RANK_LEN),
    RankInfos = rank_infos(?MSG_RANK_ARENA,StartRank, Ranks, []),
    {MyIndex, _AC} = ranking_lib:get_rank_order(?ranking_arena, get(?pd_id)),
    {ArenaLev, ArenaCent} = arena_mng:my_arena_rank_info(),
    PkgMsg = {MyIndex, ArenaLev, ArenaCent, Size, RankInfos},
    %?player_send(rank_sproto:pkg_msg(?MSG_RANK_ARENA, {MyIndex,ArenaLev, ArenaCent, Size, RankInfos})),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_ARENA, PkgMsg)),
    ok;

handle_client(?MSG_RANK_ACCOMPLISHMENT, {StartPos, Len}) ->
    {Size, StartRank, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_ac, ?DISPLAY_RANK_LEN),
    %?DEBUG_LOG("Size------:~p--StartRank--:~p--RankS------:~p",[Size, StartRank, Ranks]),
    Id = get(?pd_id),
    RankInfos = rank_infos(?MSG_RANK_ACCOMPLISHMENT,StartRank, Ranks, []),
    [Car, Name, Level, Power]
        = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    {MyIndex, MyAc} = ranking_lib:get_rank_order(?ranking_ac, get(?pd_id)),
    MyData = {MyIndex, Car, Id, Name, Level, Power, MyAc},
    %?DEBUG_LOG("RankInfos---:~p---MyIndex--:~p",[RankInfos, MyIndex]),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_ACCOMPLISHMENT, {MyData, Size, RankInfos})),
    ok;



handle_client(?MSG_RANK_FRIEND, {StartPos, Len}) ->
    Id = get(?pd_id),
    {Size, StartRank, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_meili, ?DISPLAY_RANK_LEN),
    RankInfos = rank_infos(?MSG_RANK_FRIEND, StartRank, Ranks, []),
    {MyIndex, FScore} = ranking_lib:get_rank_order(?ranking_meili, Id, {0, 0}),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_FRIEND, {rank_info(?MSG_RANK_FRIEND, {Id, MyIndex, FScore}), Size, RankInfos})),
    ok;

%% 宠物排行榜 战力>品质>等级
handle_client(?MSG_RANK_PET_NEW, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_pet, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_PET_NEW, Res));

%% 坐骑排行榜
handle_client(?MSG_RANK_RIDE, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_ride, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_RIDE, Res));

    %% {Size, StartRank, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_ride, ?DISPLAY_RANK_LEN),
    %% RankInfos = rank_infos(?MSG_RANK_RIDE, StartRank, Ranks, []),
    %% Id = get(?pd_id),
    %% [Car, Name, Level] = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level]),
    %% {MyIndex, RidePower} = ranking_lib:get_rank_order(?ranking_ride, get(?pd_id)),
    %% MyData = {MyIndex, Car, Id, Name, Level, RidePower},
    %% ?player_send(rank_sproto:pkg_msg(?MSG_RANK_RIDE, {MyData, Size, RankInfos})),
    %% ok;

%% 套装排行榜,曾经获得过的件数
handle_client(?MSG_RANK_SUIT_NEW, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_suit_new, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_SUIT_NEW, Res));

    %% {Size, NIndex, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, RankType, RankLen),
    %% RankInfos = rank_infos(?MSG_RANK_SUIT_NEW, StartRank, Ranks, []),
    %% Id = get(?pd_id),
    %% [Car, Name, Level, Power] = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    %% {MyIndex, SuitNum} = ranking_lib:get_rank_order(?ranking_suit_new, get(?pd_id)),

    %% MyData = {MyIndex, Car, Id, Name, Level, Power, SuitNum},
    %% ?player_send(rank_sproto:pkg_msg(?MSG_RANK_SUIT_NEW, {MyData, Size, lists:keysort(1,RankInfos)})),
    %% ok;

handle_client(?MSG_RANK_GUILD, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_guild, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_GUILD, Res));

    %DefGuildInfo = {0, 0, 0, 0, <<>>, 0, <<>>, 0},
    %%     Res = rank_data( StartPos, Len, ?ranking_guild, ?DISPLAY_RANK_LEN ),
    %?player_send(rank_sproto:pkg_msg(?MSG_RANK_GUILD, {DefGuildInfo, 0, []})),
    %ok;

% handle_client(?MSG_RANK_FRIEND, {StartPos, Len}) ->
%     Id = get(?pd_id),
%     {Size, NIndex, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, ?ranking_friend_score, ?DISPLAY_RANK_LEN),
%     RankInfos = rank_infos(?MSG_RANK_FRIEND, Ranks, NIndex, []),
%     {MyIndex, FScore} = ranking_lib:get_rank_order(?ranking_friend_score, Id, {0, 0}),
%     ?player_send(rank_sproto:pkg_msg(?MSG_RANK_FRIEND, {rank_info(?MSG_RANK_FRIEND, {Id, MyIndex, FScore}), Size, RankInfos})),
%     ok;
% handle_client(?MSG_RANK_ACCOMPLISHMENT, {_StartPos, _Len}) ->
%     DefAccInfo = {0, 1, 0, <<>>, 0, 0, 0},
%     ?player_send(rank_sproto:pkg_msg(?MSG_RANK_ACCOMPLISHMENT, {DefAccInfo, 0, []})),
%     ok;

% handle_client(?MSG_RANK_SHENMO, {_StartPos, _Len}) ->
%     DefSMInfo = {0, 1, 0, <<>>, 0, 0, <<>>, 0, <<>>},
%     ?player_send(rank_sproto:pkg_msg(?MSG_RANK_SHENMO, {DefSMInfo, 0, []})),
%     ok;

handle_client(?MSG_RANK_DAILY_1, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_daily_1, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_DAILY_1, Res));

handle_client(?MSG_RANK_DAILY_2, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_daily_2, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_DAILY_2, Res));

handle_client(?MSG_RANK_DAILY_4, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_daily_4, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_DAILY_4, Res));

handle_client(?MSG_RANK_DAILY_5, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_daily_5, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_DAILY_5, Res));

%% 虚空深渊排行
handle_client(?MSG_RANK_ABYSS, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_abyss, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_ABYSS, Res));

handle_client(?MSG_RANK_SKY_KILL_MONSTER, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_sky_ins_kill_monster, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_SKY_KILL_MONSTER, Res));

handle_client(?MSG_RANK_SKY_KILL_PLAYER, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_sky_ins_kill_player, ?DISPLAY_RANK_LEN),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_SKY_KILL_PLAYER, Res));

handle_client(?MSG_RANK_SUIT, {StartPos, Len}) ->
    Res = rank_data(StartPos, Len, ?ranking_suit, 100),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_SUIT, Res));

handle_client(?MSG_RANK_GUILD_BOSS, {StartPos, Len}) ->
    Res = guild_boss:rank_data_guild_boss(StartPos, Len, 100),
    ?INFO_LOG("=========== MSG_RANK_GUILD_BOSS =========== ~p ",[Res]),
    ?player_send(rank_sproto:pkg_msg(?MSG_RANK_GUILD_BOSS, Res));

handle_client(_Mod, _Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [rank_sproto:to_s(_Mod), _Msg]),
    {error, unknown_msg}.

rank_infos(_Type, _Rank, [], Ret) ->
    Ret;

rank_infos(Type, Rank,[{Id,Val} | T], Ret) ->
    rank_infos(Type, Rank+1, T, [rank_info(Type, {Id, Rank, Val}) | Ret]).

rank_info(?MSG_RANK_ARENA, {Id, Index, _}) ->
    arena_mng:arena_rank_info({Id, Index});

rank_info(?MSG_RANK_POWER, {Id, Index, Power}) ->
    [Car, Name, Lev]
        = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level]),
    {Index, Car, Id, Name, Lev, Power};

rank_info(?MSG_RANK_GWGC, {Id, Index, JiFen}) ->
    [Car, Name, Lev, Power]
        = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    {Index, Car, Id, Name, Lev, Power, JiFen};

rank_info(?MSG_RANK_LEV, {Id, Index, _Exp}) ->
    [Car, Name, Power, Lev]
        = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_combat_power, ?pd_level]),
    {Index, Car, Id, Name, Lev, Power};

rank_info(?MSG_RANK_BOUNTY, {Id, Index, Liveness}) ->
    [Car, Name, Lev, Power]
        = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    {Index, Car, Id, Name, Lev, Power, Liveness};

rank_info(?MSG_RANK_SUIT_NEW, {Id, Index, SuitNum}) ->
    [Car, Name, Lev, Power]
        = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    {Index, Car, Id, Name, Lev, Power, SuitNum};

rank_info(?MSG_RANK_FRIEND, {Id, Index, FScore}) ->
    [Car, Name, Lev, Power]
        = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    {Index, Car, Id, Name, Lev, Power, FScore};

rank_info(?MSG_RANK_ACCOMPLISHMENT, {Id, Index, Val}) ->
    [Car, Name, Level, Power]
        = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    %?DEBUG_LOG("Index---:~p----Car---:~p---Name---:~p",[Index, Car, Name]),
    %?DEBUG_LOG("Id--:~p---Level--:~p--Power--:~p--Val--:~p",[Id,Level, Power, Val]),
    {Index, Car, Id, Name, Level, Power, Val};

rank_info(_Mod, _Msg) ->
    ?ERROR_LOG("未定义的榜单信息打包类型 ~w === ~w ", [_Mod, _Msg]),
    ?undefined.

rank_data(StartPos, Len, RankType, RankLen) when RankType =:= ?ranking_suit ->
    SelfPlayerId = get(?pd_id),
    {Size, NIndex, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, RankType, RankLen),
    {MyIndex, {MySuitNum, MyEquipNum, _MyPower}} = ranking_lib:get_rank_order(RankType, SelfPlayerId, {0, {0, 0, 0}}),
    {_NIndex, RankList} = lists:foldl(
        fun({PlayerId, {SuitNum, EquipNum, _Power}}, {Index, Data}) ->
                [Car, Name, Lev, Power1] = player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
                {Index + 1, [{Index, Car, PlayerId, Name, Lev, Power1, SuitNum, 4, SuitNum * 6 + EquipNum, 24} | Data]}
        end,
        {NIndex, []},
        Ranks
    ),
    % [Car, Name, Power, Lev] = player:lookup_info(SelfPlayerId, [?pd_career, ?pd_name, ?pd_combat_power, ?pd_level]),
    {MyIndex, MySuitNum, 4, MySuitNum * 6 + MyEquipNum, 24, Size, lists:reverse(RankList)};

rank_data(StartPos, Len, RankType, RankLen) when RankType =:= ?ranking_guild ->
    {Size, StartRank, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, RankType, RankLen),
    %% ?INFO_LOG("StartRank:~p", [StartRank]),
    %% ?INFO_LOG("Ranks:~p", [Ranks]),
    RankList = guild_service:package_guild_for_rank(StartRank, Ranks),
    MyData = get_self_guild_info(RankList),
    %% ?INFO_LOG("MyData:~p", [MyData]),
    {MyData, Size, lists:keysort(1,RankList)};

%% struct rank_info_guild_boss{
%% index:u8                        #排名
%% ,playerCarrer:player_carrer     #角色职业
%% ,playerId:player_id             #角色id
%% ,playerName:sstr                #角色名字
%% ,playerLev:player_level         #角色等级
%% ,player:u8                   #角色职位
%% ,playerPower:player_power       #角色战力
%% ,damage:u32                     #输出伤害
%% }
%%
%% myRank:rank_info_guild_boss
%% ,size:u8
%% ,ranks:list<RankInfo:rank_info_guild_boss>


%% 天空之城排行
rank_data(StartPos, Len, RankType, RankLen)
    when RankType =:= ?ranking_sky_ins_kill_player orelse RankType =:= ?ranking_sky_ins_kill_monster ->
    SelfPlayerId = get(?pd_id),
    {Size, NIndex, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, RankType, RankLen),
    Def = {0, 0},
    {MyIndex, MyRankInfo} = ranking_lib:get_rank_order(RankType, SelfPlayerId, Def),
    Fun = fun({PlayerId, KillCount}, {Index, Data}) ->
        [Car, Name, Lev] = player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level]),
        GuildName = guild_service:select_guild_name(PlayerId),
        {Index + 1, [{Index, Car, PlayerId, Name, Lev, GuildName, KillCount} | Data]}
          end,
    {_NIndex, RankList} = lists:foldl(Fun, {NIndex, []}, Ranks),
    [Car, Name, Lev] = player:lookup_info(SelfPlayerId, [?pd_career, ?pd_name, ?pd_level]),
    GuildName = guild_service:select_guild_name(SelfPlayerId),
    {{MyIndex, Car, SelfPlayerId, Name, Lev, GuildName, MyRankInfo}, Size, lists:reverse(RankList)};

%% 宠物排行
rank_data(StartPos, Len, RankType, RankLen) when RankType =:= ?ranking_pet ->
    SelfPlayerId = get(?pd_id),
    {Size, NIndex, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, RankType, RankLen),
    Def = {0, {0, 0, 0}},   %% {战力, 等级}
    [MyCar, MyName, MyLev, MyPower] = player:lookup_info(SelfPlayerId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    Fun =
        fun({Id, {PetPower, _, _}}, {Index, Data}) ->
            [Car, Name, Lev, Power] = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
            {Index + 1, [{Index, Car, Id,  Name, Lev, Power, PetPower} | Data]}
        end,
    {_NIndex, RankList} = lists:foldl(Fun, {NIndex, []}, Ranks),
    {MyIndex, MyRankInfo} = ranking_lib:get_rank_order(RankType, SelfPlayerId, Def),

    case MyRankInfo of
        {MyPetPower, _, _} ->
            {{ MyIndex, MyCar, SelfPlayerId, MyName, MyLev, MyPower, MyPetPower }, Size, lists:reverse(RankList) };
        _ ->
            {{ MyIndex, MyCar, SelfPlayerId, MyName, MyLev, MyPower, 0 }, Size, lists:reverse(RankList)}
    end;

%% 坐骑排行
rank_data(StartPos, Len, RankType, RankLen) when RankType =:= ?ranking_ride ->
    SelfId = get(?pd_id),
    {Size, NIndex, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, RankType, RankLen),
    Def = {0, {0, 0, 0}},   %% {总战力, 单个坐骑战力}
    [MyCar, MyName, MyLev, MyPower] = player:lookup_info(SelfId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    Fun =
        fun({Id, {AllRidePower, _, _}}, {Index, Data}) ->
            [Car, Name, Lev, Power] = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
            {Index + 1, [{Index, Car, Id, Name, Lev, Power, AllRidePower} | Data]}
        end,
    {_NIndex, RankList} = lists:foldl(Fun, {NIndex, []}, Ranks),
    {MyIndex, MyRankInfo} = ranking_lib:get_rank_order(RankType, SelfId, Def),

    case MyRankInfo of
        {MyAllRidePower, _, _} ->
            {{ MyIndex, MyCar, SelfId,  MyName, MyLev, MyPower, MyAllRidePower }, Size, lists:keysort(1,RankList)};
        _ ->
            {{ MyIndex, MyCar, SelfId,  MyName, MyLev, MyPower, 0 }, Size, lists:keysort(1,RankList)}
    end;

rank_data(StartPos, Len, RankType, RankLen) when RankType =:= ?ranking_suit_new ->
    SelfId = get(?pd_id),
    {Size, NIndex, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, RankType, RankLen),
    Def = {0, {0, 0, 0, 0}},   %% {套装数量,套装总战力,玩家等级,玩家战力}
    [MyCar, MyName, MyLev, MyPower] = player:lookup_info(SelfId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
    Fun =
        fun({Id, {SuitNum, _, _, _}}, {Index, Data}) ->
            [Car, Name, Lev, Power] = player:lookup_info(Id, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
            {Index + 1, [{Index, Car, Id, Name, Lev, Power, SuitNum} | Data]}
        end,
    {_NIndex, RankList} = lists:foldl(Fun, {NIndex, []}, Ranks),
    {MyIndex, MyRankInfo} = ranking_lib:get_rank_order(RankType, SelfId, Def),

    case MyRankInfo of
        {MySuitNum, _, _, _} ->
            {{ MyIndex, MyCar, SelfId,  MyName, MyLev, MyPower, MySuitNum }, Size, lists:keysort(1,RankList)};
        _ ->
            {{ MyIndex, MyCar, SelfId,  MyName, MyLev, MyPower, 0 }, Size, lists:keysort(1,RankList)}
    end;

rank_data(StartPos, Len, RankType, RankLen) ->
    SelfPlayerId = get(?pd_id),
    %%    {Size, NIndex, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, RankType, RankLen),
    {Size, NIndex, Ranks} = ranking_lib:get_rank_order_page(StartPos, Len, RankType),
    Def = 
    case RankType of
        ?ranking_abyss -> 
            {0, {0, 0, 0, 0}};
        _-> 
            {0, 0}
    end,

    {MyIndex, MyRankInfo} = ranking_lib:get_rank_order(RankType, SelfPlayerId, Def),

    Fun = fun
              ({PlayerId, { Score, _TotalLayer, EasyLayer, HardLayer }}, {Index, Data}) -> %排名有4个参数的情况，虚空深渊排序
                  [Car, Name, Lev, Power] = player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
                  {Index + 1, [{Index, Car, PlayerId, Name, Lev, Power, EasyLayer, HardLayer, Score} | Data]};
              ({PlayerId, {_TotleLayer, HardLayer, EasyLayer}}, {Index, Data}) -> %排名有3个参数的情况，虚空深渊排序
                  [Car, Name, Lev, Power] = player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
                  {Index + 1, [{Index, Car, PlayerId, Name, Lev, Power, EasyLayer, HardLayer, 0} | Data]};
              ({PlayerId, Rank}, {Index, Data}) -> %排名只有一个参数的情况
                  [Car, Name, Lev, Power] = player:lookup_info(PlayerId, [?pd_career, ?pd_name, ?pd_level, ?pd_combat_power]),
                  {Index + 1, [{Index, Car, PlayerId, Name, Lev, Power, Rank} | Data]}
          end,
    {_NIndex, RankList} = lists:foldl(Fun, {NIndex, []}, Ranks),
    [Car, Name, Power, Lev] = player:lookup_info(SelfPlayerId, [?pd_career, ?pd_name, ?pd_combat_power, ?pd_level]),
    case MyRankInfo of
        { MyScore, _Total, MyEasyLayer, MyHardLayer } ->
            {{MyIndex, Car, SelfPlayerId, Name, Lev, Power, MyEasyLayer, MyHardLayer, MyScore}, Size, lists:keysort(1,RankList)};
        MyRankInfo -> 
            {{MyIndex, Car, SelfPlayerId, Name, Lev, Power, MyRankInfo}, Size, lists:keysort(1,RankList)}
    end.

get_self_guild_info(Ranks) ->
    GuildId = get(?pd_guild_id),
    if
        ((GuildId =:= 0) orelse (GuildId =:= ?undefined)) ->
            {0,0, 0, 0, 0, <<>>, 0, <<>>};
        true ->
            case lists:keyfind(GuildId,2,Ranks) of
                ?false ->
                    {0,0, 0, 0, 0, <<>>, 0, <<>>};
                GuildInfo ->
                    GuildInfo
            end
    end.



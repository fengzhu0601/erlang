%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc Game
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(gm_mng).

-include("inc.hrl").
-include("player.hrl").
-include("gm_def.hrl").
-include("achievement.hrl").

-include("handle_client.hrl").
-include("main_ins_struct.hrl").
-include("load_course.hrl").
-include("item_new.hrl").
-include("system_log.hrl").

-export
([
    cmd_set_level/2
    , cmd_set_money/2
    , cmd_add_something/2
    , set_lev/1
    , add_res/1
]).

-define(ADD_MONEY, 10).     %% 添加金币
-define(ADD_DIAMOND, 11).     %% 添加钻石
-define(ADD_HONOR, 24).       %% 荣誉
-define(ADD_JINXING, 13).
-define(ADD_YINXING, 14).

%%副本解锁
-define(JGDL_SIMPLE,    [10011,10111,10211,10311,10411,10511]).
-define(JGDL_HARD,      [10021,10121,10221,10321,10421,10521]).
-define(JGDL_NIGHTMARE, [10031,10131,10231,10331,10431,10531]).

-define(LTZD_SIMPLE,    [10611,10711,10811,10911,11011,11111]).
-define(LTZD_HARD,      [10621,10721,10821,10921,11021,11121]).
-define(LTZD_NIGHTMARE, [10631,10731,10831,10931,11031,11131]).

-define(MGSL_SIMPLE,    [11211,11311,11411,11511,11611,12311]).
-define(MGSL_HARD,      [11221,11321,11421,11521,11621,12321]).
-define(MGSL_NIGHTMARE, [11231,11331,11431,11531,11631,12331]).

-define(YGBC_SIMPLE,    [11711,11811,11911,12011,12111,12211]).
-define(YGBC_HARD,      [11721,11821,11921,12021,12121,12221]).
-define(YGBC_NIGHTMARE, [11731,11831,11931,12031,12131,12231]).

handle_client({Pack, Arg}) ->
    case lists:keyfind(1, 1, my_ets:get(is_open_module, [])) of
        {1,1} ->
            handle_client(Pack, Arg);
        _ ->
            ?ERROR_LOG("GM SERVER IS OFF--------------------------------"),
            pass
    end.

handle_client(?MSG_GM_ADD, {MoneyType, Money}) ->
    ?DEBUG_LOG("MoneyType---:~p-----Money---:~p",[MoneyType, Money]),
    case MoneyType of
        ?ADD_MONEY -> 
            add_res([{?PL_MONEY, Money}]);
        1 -> 
            add_res([{?PL_MONEY, Money}]);
        ?ADD_DIAMOND ->
            recharge_reward_mng:update_recharge(Money),
            add_res([{?PL_DIAMOND, Money}])
    end,
    ?player_send(gm_sproto:pkg_msg(?MSG_GM_ADD, {0}));

%% 设置等级
handle_client(?MSG_GM_LEV, {Lev}) ->
    set_lev(Lev),
    ?player_send(gm_sproto:pkg_msg(?MSG_GM_LEV, {0}));

%% 添加接受任务
handle_client(?MSG_GM_TASK, {TaskId}) ->
    set_task(TaskId),
    ?player_send(gm_sproto:pkg_msg(?MSG_GM_TASK, {TaskId}));


%% 添加物品
handle_client(?MSG_GM_ADD_ITEM, {ItemBid, ItemCount, _Bind}) ->
    add_res({ItemBid, ItemCount}),
    ?player_send(gm_sproto:pkg_msg(?MSG_GM_ADD_ITEM, {0}));

%% 发送邮件
handle_client(?MSG_GM_MAIL, {INum, ANum}) ->
    ItemL = case INum > 0 of
                ?true ->
                    lists:duplicate(INum, {2003, 1});
                _ -> []
            end,
    AssetsL = case ANum > 0 of
                  ?true ->
                      lists:duplicate(ANum, {11, 1});
                  _ -> []
              end,
    mail_mng:send_sysmail(get(?pd_id), ?S_MAIL_TASK, ItemL, AssetsL);

handle_client(?MSG_GM_STRING_CMD, {StringBin}) ->
    ?INFO_LOG("MSG_GM_STRING_CMD:~p~n", [StringBin]),
    case cmd_parse(StringBin) of
        {error, Str} ->
            StrBin = list_to_binary(Str),
            ?player_send(<<?MSG_GM_ADD_ITEM:16, (byte_size(StrBin)), StrBin/binary>>);
        _ ->
            ?player_send(<<?MSG_GM_ADD_ITEM:16, 0, 0>>)
    end;

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [Mod, Msg]).

%% @doc 添加资源
add_res({ItemBid, ItemCount}) -> add_res([{ItemBid, ItemCount}]);
add_res({ItemBid, ItemCount, Bind}) ->
    ItemList = case lists:member(ItemBid, player_def:enum_special_item_id_all()) of
                   ?true -> [{ItemBid, ItemCount}];
                   _ -> [{ItemBid, ItemCount, Bind}]
               end,
    add_res(ItemList);

add_res(ItemList) ->
    game_res:set_res_reasion(<<"GM">>),
    case ItemList of
        [{?PL_MONEY, _}] ->
            game_res:try_give_ex(ItemList, ?FLOW_REASON_GM);
        [{?ADD_DIAMOND, _}] ->
            game_res:try_give_ex(ItemList, ?FLOW_REASON_GM);
        [{?ADD_HONOR, _}] ->
            game_res:try_give_ex(ItemList, ?FLOW_REASON_GM);
        [{?ADD_JINXING, _}] ->
            game_res:try_give_ex(ItemList, ?FLOW_REASON_GM);
        [{?ADD_YINXING, _}] ->
            game_res:try_give_ex(ItemList, ?FLOW_REASON_GM);
        [{?YUANSU_MOLI, _}] ->
            game_res:try_give_ex(ItemList, ?FLOW_REASON_GM);
        [{?GUANGAN_MOLI, _}] ->
            game_res:try_give_ex(ItemList, ?FLOW_REASON_GM);
        [{?MINGYUN_MOLI, _}] ->
            game_res:try_give_ex(ItemList, ?FLOW_REASON_GM);
        _ ->
            [{Id, Num}] = ItemList,
                if
                    Num > 99 ->
                        ?INFO_LOG("MAX 99~n"),
                        game_res:try_give_ex([{Id, Num}], ?FLOW_REASON_GM);
                    true ->
                        game_res:try_give_ex(ItemList, ?FLOW_REASON_GM)
                end
    end.



%% @doc 设置等级
set_lev(Lev) ->
    game_res:set_res_reasion(<<"GM">>),
    vip_new_mng:do_grow_jijin(Lev), %% TODO
    player:set_level(Lev).

%% @doc 接受任务
set_task(TaskID) ->
    game_res:set_res_reasion(<<"GM">>),
    task_system:gm_accept(TaskID).

%%通关指定章节副本
open_chap_room(List) ->
    lists:foreach(
        fun(Id) ->
            open_one_room(Id)
        end,
        List
    ).

%通关某一个副本
open_one_room(SceneId) ->
    MainMng = get(?pd_main_ins_mng),
    case gb_trees:lookup(SceneId, MainMng) of
        ?none -> %% first passed
            %?DEBUG_LOG("first pass main instance -----------------------"),
            put(?pd_main_ins_mng,
                gb_trees:insert(
                    SceneId,
                    #main_ins{
                        id = SceneId,
                        pass_time=30,
                        lianjicount=50,
                        shoujicount=1,
                        star=9,
                        fenshu=1000,
                        today_passed_times=1
                    },
                    MainMng
                ));
        {?value, #main_ins{pass_time=OldPassTime, lianjicount=LianjiCount, shoujicount=OldShoujiCount, star=Star, fenshu=FenShu, today_passed_times=Today}} ->
            %?DEBUG_LOG("update main instance info ------------------------"),
            NewFenshu = erlang:max(FenShu, 1000),
            put(?pd_main_ins_mng,
                gb_trees:update(
                    SceneId,
                    #main_ins{
                        id = SceneId,
                        pass_time= erlang:min(OldPassTime, 30),
                        lianjicount=erlang:max(LianjiCount, 50),
                        shoujicount=erlang:min(OldShoujiCount, 1),
                        star=erlang:max(Star, 9),
                        fenshu=NewFenshu,
                        today_passed_times=Today+1
                    },
                    MainMng
                ))
    end.

%% 通关所有普通副本
open_normal_room() ->
    ListNormal = [
        ?JGDL_SIMPLE, ?LTZD_SIMPLE, ?MGSL_SIMPLE, ?YGBC_SIMPLE
    ],
    lists:foreach(
        fun(List) ->
            open_chap_room(List)
        end,
        ListNormal
    ).

%% 打开指定副本关卡
open_room(SceneId) ->
    ?INFO_LOG("open_room:~p~n", [SceneId]),
    game_res:set_res_reasion(<<"GM">>),

    Lists = [
        ?JGDL_SIMPLE,?JGDL_HARD,?JGDL_NIGHTMARE,
        ?LTZD_SIMPLE,?LTZD_HARD,?LTZD_NIGHTMARE,
        ?MGSL_SIMPLE,?MGSL_HARD,?MGSL_NIGHTMARE,
        ?YGBC_SIMPLE,?YGBC_HARD,?YGBC_NIGHTMARE
    ],

    lists:foreach(
        fun(List) ->
            case lists:member(SceneId, List) of
                true ->
                    case List of
                        ?JGDL_SIMPLE ->
                            open_one_room(SceneId);
                        ?JGDL_HARD ->
                            %%解锁困难章节的条件
                            open_normal_room(),
                            open_one_room(11111),
                            %%解锁SceneId的前一个副本,怎么获取前一个副本呢?
                            case SceneId of
                                10021 ->
                                    ok;
                                    _ ->
                                        open_one_room(SceneId - 100)
                            end;
%%                            open_chap_room(List);
                        ?JGDL_NIGHTMARE ->
                            open_normal_room(),
                            open_one_room(12311),
                            case SceneId of
                                10031 ->
                                    ok;
                                _ ->
                                    open_one_room(SceneId - 100)
                            end;
%%                            open_chap_room(List);
                        ?LTZD_SIMPLE ->
                            open_chap_room(?JGDL_SIMPLE),
                            case SceneId of
                                10611 ->
                                    ok;
                                _ ->
                                    open_one_room(SceneId - 100)
                            end;
                        ?LTZD_HARD ->
                            %%解锁困难章节的条件
                            open_normal_room(),
                            open_one_room(12311),
                            %%先直接解锁整个章节吧
                            open_chap_room(?JGDL_HARD),
                            case SceneId of
                                10621 ->
                                    ok;
                                _ ->
                                    open_one_room(SceneId - 100)
                            end;
%%                            open_chap_room(List);
                        ?LTZD_NIGHTMARE ->
                            open_normal_room(),
                            open_one_room(12211),
                            open_chap_room(?JGDL_NIGHTMARE),
                            case SceneId of
                                10631 ->
                                    ok;
                                _ ->
                                    open_one_room(SceneId - 100)
                            end;
%%                            open_chap_room(List);
                        ?MGSL_SIMPLE ->
                            open_chap_room(?LTZD_SIMPLE),
                            case SceneId of
                                11211 ->
                                    ok;
                                12311 ->
                                    open_one_room(11611);
                                _ ->
                                    open_one_room(SceneId - 100)
                            end;
                        ?MGSL_HARD ->
                            open_normal_room(),
                            open_one_room(12211),
                            open_chap_room(?LTZD_HARD),
                            case SceneId of
                                11221 ->
                                    ok;
                                12231 ->
                                    open_one_room(11621);
                                _ ->
                                    open_one_room(SceneId - 100)
                            end;
%%                            open_chap_room(List);
                        ?MGSL_NIGHTMARE ->
                            open_normal_room(),
                            open_one_room(12211),
                            open_chap_room(?LTZD_NIGHTMARE),
                            case SceneId of
                                11231 ->
                                    ok;
                                12331 ->
                                    open_one_room(11631);
                                _ ->
                                    open_one_room(SceneId - 100)
                            end;
%%                            open_chap_room(List);
                        ?YGBC_SIMPLE ->
                            open_chap_room(?MGSL_SIMPLE),
                            case SceneId of
                                11711 ->
                                    ok;
                                _ ->
                                    open_one_room(SceneId - 100)
                            end;
                        ?YGBC_HARD ->
                            open_normal_room(),
                            open_one_room(12231),
                            open_chap_room(?MGSL_HARD),
                            case SceneId of
                                11721 ->
                                    ok;
                                _ ->
                                    open_one_room(SceneId - 100)
                            end;
%%                            open_chap_room(List);
                        ?YGBC_NIGHTMARE ->
                            open_normal_room(),
                            open_one_room(12231),
                            open_chap_room(?MGSL_NIGHTMARE),
                            case SceneId of
                                11731 ->
                                    ok;
                                _ ->
                                    open_one_room(SceneId - 100)
                            end
%%                            open_chap_room(List)
                    end;
                _ ->
                    ok
            end
        end,
        Lists
    ).
%%打开所有的副本关卡
open_all_room() ->
    ?INFO_LOG("open_all_room~n"),
    ?INFO_LOG("open_all_room~n"),
    ?INFO_LOG("open_all_room~n"),

    game_res:set_res_reasion(<<"GM">>),
    RoomList = [
        10011, 10111, 10211, 10311, 10411, 10511,
        10021, 10121, 10221, 10321, 10421, 10521,
        10031, 10131, 10231, 10331, 10431, 10531,

        10611, 10711, 10811, 10911, 11011, 11111,
        10621, 10721, 10821, 10921, 11021, 11121,
        10631, 10731, 10831, 10931, 11031, 11131,

        11211, 11311, 11411, 11511, 11611, 12311,
        11221, 11321, 11421, 11521, 11621, 12321,
        11231, 11331, 11431, 11531, 11631, 12331,

        11711, 11811, 11911, 12011, 12111, 12211,
        11721, 11821, 11921, 12021, 12121, 12221,
        11731, 11831, 11931, 12031, 12131, 12231,

        12411, 12511, 12611, 12711, 12811, 12911,
        12421, 12521, 12621, 12721, 12821, 12921,
        12431, 12531, 12631, 12731, 12831, 12931,

        13011, 13111, 13211, 13311, 13411, 13511,
        13021, 13121, 13221, 13321, 13421, 13521,
        13031, 13131, 13231, 13331, 13431, 13531
        ],
    lists:foreach(
        fun(Id) ->
            MainMng = get(?pd_main_ins_mng),
            case gb_trees:lookup(Id, MainMng) of
                ?none -> %% first passed
                    %?DEBUG_LOG("first pass main instance -----------------------"),
                    put(?pd_main_ins_mng,
                        gb_trees:insert(
                            Id,
                            #main_ins{
                                id = Id,
                                pass_time=30,
                                lianjicount=50,
                                shoujicount=1,
                                relivenum = 100,
                                star=9,
                                fenshu=1000,
                                today_passed_times=1
                            },
                            MainMng
                        ));

                {?value, #main_ins{pass_time=OldPassTime, lianjicount=LianjiCount, shoujicount=OldShoujiCount,relivenum = ReliveNum, star=Star, fenshu=FenShu, today_passed_times=Today}} ->
                    %?DEBUG_LOG("update main instance info ------------------------"),
                    NewFenshu = erlang:max(FenShu, 1000),
                    PassTime = erlang:min(OldPassTime, 30),
                    ShoujiCount = erlang:min(OldShoujiCount, 1),
                    NewStar = erlang:max(Star, 9),
                    NewReliveNum = erlang:max(ReliveNum, 100),
                    PrizeInfo = [],
                    LianJIPrize = [],
                    ShouJiPrize = [],
                    PassTimePrize = [],
                    put(?pd_main_ins_mng,
                        gb_trees:update(
                            Id,
                            #main_ins{
                                id = Id,
                                pass_time= PassTime,
                                lianjicount=erlang:max(LianjiCount, 50),
                                shoujicount=ShoujiCount,
                                relivenum = NewReliveNum,
                                star=NewStar,
                                fenshu=NewFenshu,
                                today_passed_times=Today+1
                            },
                            MainMng
                        ))
            end
        end,
        RoomList
    ),
    set_lev(60),
    task_system:gm_accept(16021),
%%    unlock_course_all_boss(),    %%打开战争学院中所有boss挑战列表
    ok.


-define(CMD_TYPE_ADD_GOODS, <<"add_items"/utf8>>). %添加
-define(CMD_TYPE_SET, <<"set"/utf8>>). %设置
-define(CMD_TYPE_ADD_ASSETS, <<"add_assets"/utf8>>).
-define(CMD_TYPE_ADD_LEVEL, <<"add_level"/utf8>>).
-define(CMD_TYPE_ADD_EXP, <<"add_exp"/utf8>>).
-define(CMD_TYPE_ADD_TASK, <<"add_task"/utf8>>).
-define(CMD_TYPE_ADD_SP, <<"add_sp"/utf8>>).
-define(CMD_TYPE_OPEN_ALL_ROOM, <<"open_all_room"/utf8>>).
-define(CMD_TYPE_OPEN_ROOM, <<"open_room"/utf8>>).
-define(CMD_TYPE_OPEN_GWGC, <<"open_gwgc"/utf8>>).
%-define(CMD_TYPE_ADD_TASK, <<"add_task_to"/utf8>>).
-define(CMD_OPEN_FISHING, <<"open_fishing"/utf8>>).
cmd_parse(StringBin) ->
    game_res:set_res_reasion(<<"GM">>),
    case binary:split(unicode:characters_to_binary(StringBin), <<$ >>, [global, trim]) of
        [?CMD_TYPE_ADD_ASSETS, TypeBin, CountBin] ->
            Count = binary_to_integer(CountBin),
            case binary_to_integer(TypeBin) of
                ?ADD_MONEY ->
                    achievement_mng:do_ac2(?jiacaiwanguan, 0, Count),
                    add_res([{?PL_MONEY, Count}]);
%%                     mail_mng:send_sysmail(64, ?S_MAIL_TASK, [], [{?PL_MONEY, 70000},{?PL_DIAMOND, 100}]);
%%                     add_res([{?PL_HONOUR, 1000}]),
%%                     add_res([{?PL_LONGWENS, 100}]);
%%                     achievement_mng:do_ac2(?jiacaiwanguan, 0, Count),
%%                     add_res([{?PL_MONEY, Count}]);
                ?ADD_DIAMOND ->
                    achievement_mng:do_ac2(?zuanshizhiwang, 0, Count),
                    %% vip_new_mng:up_vip_level(Count),
                    load_db_misc:init_emails(),
                    add_res([{?PL_DIAMOND, Count}])
            end,
            ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_SUCCESS, <<>>}));
        [?CMD_TYPE_ADD_GOODS, ItemBidBin, ItemNumBin, _IsBind] ->
            case do_add_cmd(binary_to_integer(ItemBidBin), binary_to_integer(ItemNumBin)) of
                ok ->
                    ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_SUCCESS, <<>>}));
                _ ->
                    pass
            end;
        [?CMD_TYPE_ADD_LEVEL, LevelBin] ->
            set_lev(binary_to_integer(LevelBin)),
            ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_SUCCESS, <<>>}));
        [?CMD_TYPE_ADD_EXP, ExpBin] ->
            AddExp = binary_to_integer(ExpBin),
            player:add_exp(AddExp),
            ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_SUCCESS, <<>>}));
        [?CMD_TYPE_ADD_TASK, TaskBin] ->
            set_task(binary_to_integer(TaskBin)),
            ?INFO_LOG("TASK:~p~n", [[?CMD_TYPE_ADD_TASK, TaskBin]]),
            ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_SUCCESS, <<>>}));
        [?CMD_TYPE_OPEN_ROOM, SceneIdBin] ->
            open_room(binary_to_integer(SceneIdBin)),
            ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_SUCCESS, <<>>}));
        [?CMD_TYPE_OPEN_ALL_ROOM] ->
            open_all_room(),
            ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_SUCCESS, <<>>}));
        [?CMD_TYPE_ADD_SP, TiLiBin] ->
            player:add_value(?pd_sp, binary_to_integer(TiLiBin)),
            ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_SUCCESS, <<>>}));
        [?CMD_TYPE_SET, CMD] ->
            case do_set_cmd(binary_to_integer(CMD)) of
                ok ->
                    ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_SUCCESS, <<>>}));
                _ ->
                    pass
            end;
        [?CMD_TYPE_OPEN_GWGC, IsOpenBin] ->
            ?DEBUG_LOG("IsOpenBin--------------------------:~p",[IsOpenBin]),
            IsOpen = binary_to_integer(IsOpenBin),
            if
                IsOpen =:= 1 ->
                    gongcheng_mng:start_activity();
                IsOpen =:= 0 ->
                    gongcheng_mng:stop_activity();
                true ->
                    pass 
            end;
        [?CMD_OPEN_FISHING, IsOpenBin] ->
            ?DEBUG_LOG("open_fishing--------------------------:~p",[IsOpenBin]),
            IsOpen = binary_to_integer(IsOpenBin),
            if
                IsOpen =:= 0 ->
                    diaoyu_mng:stop_activity();
                IsOpen =:= 1 ->
                    diaoyu_mng:start_activity(1);
                IsOpen =:= 2 ->
                    diaoyu_mng:start_activity(2);
                IsOpen =:= 3 ->
                    diaoyu_mng:start_activity(3);
                true ->
                    pass
            end;
        _Other ->
            ?ERROR_LOG("no this cmd:~p~n", [_Other]),
            {error, "no this cmd"}
    end.

do_add_cmd(ItemBid, ItemNum) ->
    game_res:set_res_reasion(<<"GM">>),
    add_res([{ItemBid, ItemNum}]),
    ok.

do_set_cmd(?GM_SET_DAILY_COUNT) ->
    game_res:set_res_reasion(<<"GM">>),
    daily_activity_mng:reset_clock(),
    ok;

do_set_cmd(?GM_SET_GUILD_COUNT) ->
    game_res:set_res_reasion(<<"GM">>),
    guild_mng:reset_guild_daily_task_count(),
    ok;

do_set_cmd(_Other) ->
    game_res:set_res_reasion(<<"GM">>),
    ?ERROR_LOG("no this cmd:~p~n", [_Other]),
    ?player_send(gm_sproto:pkg_msg(?MSG_GM_STRING_CMD, {?GM_NOT_FIND_TYPE, <<>>})).

%% 命令行加金币和等级
cmd_set_level(PlayerId,Lev) ->
    world:send_to_player(PlayerId, ?mod_msg(player_mng, {cmd_set_level, Lev})).

cmd_set_money(PlayerId,Money) ->
    world:send_to_player(PlayerId, ?mod_msg(player_mng, {cmd_set_money, Money})).

cmd_add_something(PlayerId,{ItemBid, ItemCount}) ->
    world:send_to_player(PlayerId, ?mod_msg(player_mng, {cmd_add_something, ItemBid, ItemCount})).

%% 解锁战争学院中的boss挑战列表
unlock_course_all_boss() ->
        case dbcache:load_data(?player_course_boss_tab, get(?pd_id)) of
            [Table = #player_course_boss_tab{count = Count, buy_count = BuyCount}] ->
                AllBossList = load_task_progress:get_all_unlock_course_boss(),

                AllBossList1 = lists:filter(fun(N) -> is_integer(N) end, AllBossList),
                ?INFO_LOG("Unlock course all boss AllBossList1 = ~p~n", [AllBossList1]),
                put(?pd_course_boss_list, AllBossList1),
                dbcache:update(?player_course_boss_tab, Table#player_course_boss_tab{courseind_list = AllBossList1}),
                PrizeList = title_service:get_course_boss_prize(AllBossList1),
                ?player_send(course_sproto:pkg_msg(?MSG_COURSE_BEST_PRIZE,{Count, BuyCount, PrizeList}));
            [] ->
                ?INFO_LOG("No bossList~n")
        end.


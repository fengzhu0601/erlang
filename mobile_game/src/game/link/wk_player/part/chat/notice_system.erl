%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 八月 2016 下午6:27
%%%-------------------------------------------------------------------
-module(notice_system).
-author("lan").

-include("player.hrl").
-include("game.hrl").
-include("inc.hrl").
-include("item_new.hrl").
-include("../equip_system/equip_mng_reply.hrl").
-include("load_db_misc.hrl").
-include("rank.hrl").

%% API
-export([
    send_player_level_strong/1
    , first_kill_guild_boss/3
    , send_arena_win_times_notice/1
    , send_kill_guild_boss_notice/3
    , send_black_shop_start_message/0
    , send_black_shop_end_message/0
    , double_prize_broadcast/1
    , double_prize_broadcast/2
    , double_prize_over/0
    , open_server_happy_over/0
    , nine_nine_prize_over/0
    , chongzhi_manjine_over/0
    , send_qianghua_level/3
    , send_guild_level_up_notice/2
    , send_call_guild_boss_notice/2
    , send_arena_rank_change_notice/1
    , send_arena_shutdown_notice/2
    , send_player_join_guild_notice/2
    , send_player_bounty_over/0
    , zhangli_king_rank_over/0
    , zuoqi_king_rank_over/0
    , pet_king_rank_over/0
    , suit_king_rank_over/0
    , shengyuan_king_rank_over/0
    , guild_king_rank_over/0
    , pet_jinjie_notice/2
    , zhanli_king_rank_up/2
    , ride_king_rank_up/2
    , pet_king_rank_up/2
    , suit_king_rank_up/2
    , shenyuan_king_rank_up/2
    , guild_king_rank_up/2
]).

-export([
    test/0,
    test_pet/0
]).

%% 以下定义的消息id来自配置表broadcast.txt中，每条协议在发送之前都做了判断，根据配置表中配置的id进行发送，没有配置相关id则不发


-define(QIANGHUA_LEVEL_OF_SEND_MESSAGE, 20).        %% 装备强化发送消息的限制等级

-define(arena_rand_broadcast_limit, 50).            %% 竞技场排名广播限制



%% new define
%% ------------------------------------------------------------------


-define(not_notice_type, 0). %% 不播放公告
-define(system_notice_type, 1).      %% 系统公告
-define(guild_notice_type, 2).      %% 工会公告

-define(STRONG_PLAYER_LEVEL, 40).     %% 玩家发送最强角色等级


-define(system_weihu_close_server_msg, 1).      %% 系统维护时通知消息， 消息类型为在时间到达之前每过一个时间段就发送一次
-define(guaiwu_gongcheng_start_time_mes_id, 2).            %% 怪物攻城活动开启
-define(shouwei_renyu_start_mes_id, 3).               %% 守卫人鱼活动开放
-define(sangnihao_start_mes_id, 4).                     %% 桑尼号活动开放
-define(shikoug_liefeng_start_mes_id, 5).               %% 时空裂缝活动开放
-define(guaiwu_gongcheng_start_mes_id, 6).           %% 怪物攻城已开起
-define(zuiqiang_power_mes_id, 9).                %% 最强战力
-define(first_kill_guild_boss_mes_id, 10).        %% 第一次杀死工会boss

-define(power_rank_chenghao_mes_id, 11).          %% 最强战力
-define(qianghua_succeed_send_mes_id, 14).        %% 强化成功的消息id
-define(arena_win_mes_1_id, 15).                    %% 竞技场人机模式连胜消息id
-define(arena_rank_change_mes_id, 16).            %% 竞技场人机模式排名前进时发送的消息id
-define(guild_boss_skill_mes_id, 17).             %% 公会boss被击杀
-define(guild_call_boss_mes_id, 18).              %% 玩家召唤公会boss的消息id
-define(guid_level_update_mes_id, 19).            %% 工会等级升级
-define(player_join_guild_mes_id, 20).              %% 玩家加入工会
-define(black_shop_start_mes_id, 21).             %% 黑市拍卖行开市
-define(black_shop_end_time_mes_id, 22).          %% 黑市拍卖行关市时间
-define(black_shop_close_mes_id, 23).             %% 黑市拍卖行开始休市
-define(shangjin_task_end_time_mes_id, 24).       %% 赏金任务结束时间
-define(open_server_happy_time_mes_id, 26).       %% 开服狂欢开始时间
-define(shangjin_task_start_time_mes_id, 27).     %% 赏金任务开始时间
-define(jiugongge_start_time_mes_id, 28).         %% 九宫格开始时间
-define(chongzhi_manjine_start_time_mes_id, 29).  %% 充值满金额开始时间
-define(zhanli_wangzhe_ranl_start_time_mes_id, 30). %% 战力王者开始时间
-define(zuoji_wangzhe_rank_start_time_mes_id, 31).  %% 坐骑王者开始时间
-define(pet_wangzhe_rank_start_time_mes_id, 32).    %% 宠物王者开始时间
-define(suit_wangzhe_rank_start_time_mes_id, 33).   %% 套装王者开始时间
-define(shenyuan_wangzhe_rank_start_time_mes_id, 34).   %% 深渊王者开始时间
-define(guild_wangzhe_rank_start_time_mes_id, 35).      %% 工会王者开始时间

-define(open_server_happy_over_mes_id, 42).             %% 开服狂欢活动结束
-define(shangjin_task_end_mes_id, 43).            %% 赏金任务已经结束
-define(nine_nine_prize_over_mes_id, 44).               %% 九宫格
-define(chongzhi_manjine_close_mes_id, 45).             %% 充值满金额结束
-define(zhanli_wangzhe_rank_close_mes_id, 46). %% 战力王者结束
-define(zuoji_wangzhe_rank_close_mes_id, 47).  %% 坐骑王者结束
-define(pet_wangzhe_rank_close_mes_id, 48).    %% 宠物王者结束
-define(suit_wangzhe_rank_close_mes_id, 49).   %% 套装王者结束
-define(shenyuan_wangzhe_rank_close_mes_id, 50).   %% 深渊王者结束
-define(guild_wangzhe_rank_end_time_mes_id, 51).      %% 工会王者结束
-define(pet_jinjie_mes_id, 52).                         %% 宠物进阶

-define(zhanli_wangzhe_rank_up, 55).              %% 战力王者排名提升
-define(zuoji_wangzhe_rank_up, 56).             %% 坐骑王者排名提升
-define(pet_wangzhe_rank_up, 57).               %% 宠物王者排名提升
-define(suit_wangzhe_rank_up, 58).              %% 套装王者排名提升
-define(shenyuan_wangzhe_rank_up, 59).          %% 深渊王者排名提升
-define(guild_wangzhe_rank_up, 60).             %% 公会王者排名提升

-define(arena_shutdown_mes_id, 61).             %% 竞技场连胜终结
-define(arena_win_mes_2_id, 62).                    %% 竞技场人机模式连胜消息id
-define(arena_win_mes_3_id, 63).                    %% 竞技场人机模式连胜消息id

%% 奖励翻倍公告id

%% 奖励翻倍无参数公告id
-define(double_prize_no_args_mes_id_list, [54,110,111,112,113,114,115,120,121,122,123,124,125]).
%% 奖励翻倍有参数公告id(参数是倒计时的秒数)
-define(double_prize_have_args_mes_id_list, [100,101,102,103,104,105]).

-define(double_prize_start_time_mes_id, 53).            %% 双倍奖励预开始时间

-define(prize_double_finish_fuben, 36).             %% 奖励翻倍完成副本
-define(prize_double_finish_day_task, 37).              %% 奖励翻倍完成每日任务
-define(prize_double_finish_ri_chang_task, 38).         %% 奖励翻倍完成日常活动
-define(prize_double_xukong_shengyuan, 39).             %% 奖励翻倍完成虚空深渊
-define(prize_double_start_mes_id, 40).                 %% 奖励翻倍任务开启
-define(prize_double_end_mes_id, 41).                   %% 奖励翻倍结束
-define(double_prize_opening_mes_id, 54).               %% 双倍奖励正在开始中的公告id

-define(strong_max_role_list, [{1, "最强战士"}, {2, "最强法师"}, {4, "最强骑士"}]).  %% [{角色id, 角色名称}]

%% down new -----------------------------------------------------------------------

test() ->
    world:broadcast(chat_mng:pack_chat_system(unicode:characters_to_binary("独孤求败"))).
%%    MesList = [{1, 1, unicode:characters_to_binary("独孤求败")}, {9, 1, unicode:characters_to_binary("天下第一剑")}],
%%    SendMes = {?power_rank_chenghao_mes_id, 0, MesList, [], []},
%%    send_message_by_type(?system_notice_type, SendMes).

test_pet() ->
    MesList = [{1,1,unicode:characters_to_binary("独孤求败"),0,0},{11, 5, integer_to_binary(11014001), 0,0},{12,1,integer_to_binary(0),0,0}],
    SendMes = {52, 2, [], [], MesList},
    send_message_by_type(?system_notice_type, SendMes).

%% 发送玩家最强战力的公告
send_player_level_strong(Level) ->
    case Level =:= ?STRONG_PLAYER_LEVEL of
        true ->
            Career = get(?pd_career),
            case lists:keyfind(Career, 1, ?strong_max_role_list) of
                {_Car, CareerName} ->
                    {Type1, _Type2} = load_cfg_broadcast:get_notice_type(?power_rank_chenghao_mes_id),
                    Name = get(?pd_name),
                    MesList = [{1, 1, Name}, {9, 1, unicode:characters_to_binary(CareerName)}],
                    SendMes = {?power_rank_chenghao_mes_id, 0, MesList, [], []},
                    send_message_by_type(Type1, SendMes);
                _ ->
                    ?ERROR_LOG("not find career :~p", [Career])
            end;
        _ ->
            pass
    end.


%% 工会首杀工会boss
first_kill_guild_boss(RecordId, _Killer, GuildId) ->
%%    ?INFO_LOG("11111111111111111111111111111111111"),
    case load_db_misc:get(?misc_first_kill_guild_boss, 0) of
        0 ->
%%            [Name] = player:lookup_info(Killer, [?pd_name]),
            GuildName = guild_service:get_guild_name(GuildId),
            BossId = load_cfg_guild_boss:get_monster_id(RecordId),
%%            ?INFO_LOG("GuildName = ~p", [GuildName]),
            MesList = [{3, 1, GuildName},{5, 3, integer_to_binary(BossId)}],
            SendMes = {?first_kill_guild_boss_mes_id, 0, MesList, [], []},
            {Type1, _Type2} = load_cfg_broadcast:get_notice_type(?first_kill_guild_boss_mes_id),
            send_message_by_type({Type1, GuildId}, SendMes),
            load_db_misc:set(?misc_first_kill_guild_boss, 1);
        _ ->
            pass
    end.


%% 发送竞技场连胜的消息公告(人机模式)
send_arena_win_times_notice(Times) ->
    case Times rem 10 =:= 0 of
        true ->
            MesId = if
                Times =< 30 -> ?arena_win_mes_1_id;
                Times =< 90 -> ?arena_win_mes_2_id;
                true -> ?arena_win_mes_3_id
            end,
            {Type1, _Type2} = load_cfg_broadcast:get_notice_type(MesId),
            Name = get(?pd_name),
            MesList = [{1, 1, Name}, {13, 1, integer_to_binary(Times)}],
            SendMes = {MesId, 0, MesList, [], []},
            send_message_by_type(Type1, SendMes);
        _ ->
            pass
    end.

%% 发送竞技场玩家排名前进时的公告（人机模式）
send_arena_rank_change_notice(NewRank) ->
    case NewRank =< ?arena_rand_broadcast_limit of
        true ->
            Name = get(?pd_name),
            MesList = [{1, 1, Name}, {7, 1, integer_to_binary(NewRank)}],
            SendMes = {?arena_rank_change_mes_id, 0, MesList, [], []},
            {Type1, _Type2} = load_cfg_broadcast:get_notice_type(?arena_rank_change_mes_id),
            send_message_by_type(Type1, SendMes);
        _ ->
            pass
    end.

send_arena_shutdown_notice(EnemyName, Times) ->
    case Times >= 10 of
        true ->
            {Type1, _Type2} = load_cfg_broadcast:get_notice_type(?arena_shutdown_mes_id),
            Name = get(?pd_name),
            MesList = [{1, 1, Name}, {1, 1, EnemyName}, {14, 1, integer_to_binary(Times)}],
            SendMes = {?arena_shutdown_mes_id, 0, MesList, [], []},
            send_message_by_type(Type1, SendMes);
        _ ->
            pass
    end.

%% 发送公会boss被击杀发送消息到当前公会成员
send_kill_guild_boss_notice(RecordId, _Killer, GuildId) when is_integer(RecordId) ->
%%    [Name] = player:lookup_info(Killer, [?pd_name]),
%%    ?INFO_LOG("222222222222222222222222222"),
    GuildName = guild_service:get_guild_name(GuildId),
    BossId = load_cfg_guild_boss:get_monster_id(RecordId),
%%    ?INFO_LOG("GuildName = ~p", [GuildName]),
    MesList = [{3, 1, GuildName},{5, 3, integer_to_binary(BossId)}],
    SendMes = {?guild_boss_skill_mes_id, 0, MesList, [], []},
    {Type1, _} = load_cfg_broadcast:get_notice_type(?guild_boss_skill_mes_id),
    send_message_by_type({Type1, GuildId}, SendMes);
send_kill_guild_boss_notice(_, _, _) -> pass.

%% 发送召唤公会boss公告到当前公会成员
send_call_guild_boss_notice(RecordId, Ret) when is_integer(RecordId) ->
    case Ret of
        0 ->
            Name = get(?pd_name),
            BossId = load_cfg_guild_boss:get_monster_id(RecordId),
            MesList = [{1, 1, Name}, {5, 3, integer_to_binary(BossId)}],
            SendMes = {?guild_call_boss_mes_id, 0, MesList, [], []},
            {Type, _} = load_cfg_broadcast:get_notice_type(?guild_call_boss_mes_id),
            send_message_by_type(Type, SendMes);
        _ ->
            pass
    end;
send_call_guild_boss_notice(_, _) -> pass.

%% 发送公会升级公告到本公会的所有成员
send_guild_level_up_notice(OldLevel, NewLevel) ->
    case NewLevel - OldLevel >= 1 of
        true ->
            MesList = [{4, 1, integer_to_binary(NewLevel)}],
            SendMes = {?guid_level_update_mes_id, 0, MesList, [], []},
            {Type, _} = load_cfg_broadcast:get_notice_type(?guid_level_update_mes_id),
            send_message_by_type(Type, SendMes);
        _ ->
            pass
    end.

%% 发送玩家加入公会的的公告到当前公会的所有成员
send_player_join_guild_notice(GuildId, PlayerId) ->
    Name = get_player_name(PlayerId),
    MesList = [{1, 1, Name}],
    SendMes = {?player_join_guild_mes_id, 0, MesList, [], []},
    {Type, _} = load_cfg_broadcast:get_notice_type(?player_join_guild_mes_id),
    send_message_by_type({Type, GuildId}, SendMes).

%% 黑市拍卖行开市了
send_black_shop_start_message() ->
    {Type, _} = load_cfg_broadcast:get_notice_type(?black_shop_start_mes_id),
    SendMes = {?black_shop_start_mes_id, 0, [],[],[]},
    send_message_by_type(Type, SendMes).

%% 黑市拍卖行开始休市
send_black_shop_end_message() ->
    {Type, _} = load_cfg_broadcast:get_notice_type(?black_shop_close_mes_id),
    SendMes = {?black_shop_close_mes_id, 0, [],[],[]},
    send_message_by_type(Type, SendMes).

%% 发送赏金任务活动结束
send_player_bounty_over() ->
    Msg = {?shangjin_task_end_mes_id, 0, [], [], []},
    {Type, _} = load_cfg_broadcast:get_notice_type(?shangjin_task_end_mes_id),
    send_message_by_type(Type, Msg).

%% 开服狂欢活动结束
open_server_happy_over() ->
    Msg = {?open_server_happy_over_mes_id, 0, [], [], []},
    {Type, _} = load_cfg_broadcast:get_notice_type(?open_server_happy_over_mes_id),
    send_message_by_type(Type, Msg).

%% 奖励翻倍活动开始
double_prize_broadcast(BroadCastId) ->
%%    ?INFO_LOG("BroadCastId = ~p", [BroadCastId]),
    case lists:member(BroadCastId, ?double_prize_no_args_mes_id_list) of
        true ->
            Msg = {BroadCastId, 0, [],[],[]},
            {Type, _} = load_cfg_broadcast:get_notice_type(BroadCastId),
            send_message_by_type(Type, Msg);
        _ ->
            ?INFO_LOG("unknown broadcast type: ~p", [BroadCastId]),
            pass
    end.

%% 双倍奖励开启的预告倒计时公告
double_prize_broadcast(BroadCastId, Sec) ->
%%    ?INFO_LOG("BroadId = ~p Sec = ~p", [BroadCastId, Sec]),
    case lists:member(BroadCastId, ?double_prize_have_args_mes_id_list) of
        true ->
            MesList = [{10, 4, integer_to_binary(Sec)}],
            SendMes = {BroadCastId, 0, MesList, [], []},
            {Type, _} = load_cfg_broadcast:get_notice_type(BroadCastId),
            send_message_by_type(Type, SendMes);
        _ ->
            ?ERROR_LOG("error broadcastId : ~p", [BroadCastId])
    end.





%% 奖励翻倍活动结束
double_prize_over() ->
    Msg = {?prize_double_end_mes_id, 0, [],[],[]},
    {Type, _} = load_cfg_broadcast:get_notice_type(?prize_double_end_mes_id),
    send_message_by_type(Type, Msg).

%% 九宫格任务已结束
nine_nine_prize_over() ->
    Msg = {?nine_nine_prize_over_mes_id, 0, [],[],[]},
    {Type, _} = load_cfg_broadcast:get_notice_type(?nine_nine_prize_over_mes_id),
    send_message_by_type(Type, Msg).

%% 充值满额
chongzhi_manjine_over() ->
    Mes = {?chongzhi_manjine_close_mes_id, 0, [],[],[]},
    {Type, _} = load_cfg_broadcast:get_notice_type(?chongzhi_manjine_close_mes_id),
    send_message_by_type(Type, Mes).

%% 战力王者结束
zhangli_king_rank_over() ->
    List = ranking_lib:get_top_3_info(?ranking_zhanli),
    {Type, _} = load_cfg_broadcast:get_notice_type(?zhanli_wangzhe_rank_close_mes_id),
    lists:foreach
    (
        fun({PlayerId, Rank}) ->
            Name = get_player_name(PlayerId),
            MesList = [{1, 1, Name}, {7, 1, integer_to_binary(Rank)}],
            SendMes = {?zhanli_wangzhe_rank_close_mes_id, 0, MesList, [],[]},
            send_message_by_type(Type, SendMes)
        end,
        List
    ).

%% 坐骑王者结束
zuoqi_king_rank_over() ->
    List = ranking_lib:get_top_3_info(?ranking_ride),
    {Type, _} = load_cfg_broadcast:get_notice_type(?zuoji_wangzhe_rank_close_mes_id),
    lists:foreach
    (
        fun({PlayerId, Rank}) ->
            Name = get_player_name(PlayerId),
            MesList = [{1, 1, Name}, {7, 1, integer_to_binary(Rank)}],
            SendMes = {?zuoji_wangzhe_rank_close_mes_id, 0, MesList, [],[]},
            send_message_by_type(Type, SendMes)
        end,
        List
    ).

%% 宠物王者
pet_king_rank_over() ->
    List = ranking_lib:get_top_3_info(?ranking_pet),
    {Type, _} = load_cfg_broadcast:get_notice_type(?pet_wangzhe_rank_close_mes_id),
    lists:foreach
    (
        fun({PlayerId, Rank}) ->
            Name = get_player_name(PlayerId),
            MesList = [{1, 1, Name}, {7, 1, integer_to_binary(Rank)}],
            SendMes = {?pet_wangzhe_rank_close_mes_id, 0, MesList, [],[]},
            send_message_by_type(Type, SendMes)
        end,
        List
    ).

%% 套装王者
suit_king_rank_over() ->
    List = ranking_lib:get_top_3_info(?ranking_suit_new),
    {Type, _} = load_cfg_broadcast:get_notice_type(?suit_wangzhe_rank_close_mes_id),
    lists:foreach
    (
        fun({PlayerId, Rank}) ->
            Name = get_player_name(PlayerId),
            MesList = [{1, 1, Name}, {7, 1, integer_to_binary(Rank)}],
            SendMes = {?suit_wangzhe_rank_close_mes_id, 0, MesList, [],[]},
            send_message_by_type(Type, SendMes)
        end,
        List
    ).

%% 深渊王者
shengyuan_king_rank_over() ->
    List = ranking_lib:get_top_3_info(?ranking_abyss),
    {Type, _} = load_cfg_broadcast:get_notice_type(?shenyuan_wangzhe_rank_close_mes_id),
    lists:foreach
    (
        fun({PlayerId, Rank}) ->
            Name = get_player_name(PlayerId),
            MesList = [{1, 1, Name}, {7, 1, integer_to_binary(Rank)}],
            SendMes = {?shenyuan_wangzhe_rank_close_mes_id, 0, MesList, [],[]},
            send_message_by_type(Type, SendMes)
        end,
        List
    ).

%% 公会王者
guild_king_rank_over() ->
    List = ranking_lib:get_top_3_info(?ranking_guild),
    {Type, _} = load_cfg_broadcast:get_notice_type(?guild_wangzhe_rank_end_time_mes_id),
    lists:foreach
    (
        fun({GuildId, Rank}) ->
            Name = guild_service:get_guild_name(GuildId),
            PetId = pet_new_mng:get_pet_id(),
            MesList = [{3, 1, Name},{11,1,integer_to_binary(PetId)}, {7, 1, integer_to_binary(Rank)}],
            SendMes = {?guild_wangzhe_rank_end_time_mes_id, 0, MesList, [],[]},
            send_message_by_type(Type, SendMes)
        end,
        List
    ).

%% 宠物进阶
pet_jinjie_notice(PetId, Jie) ->
    MesList = [{1,1,get(?pd_name),0,0},{11, 5, integer_to_binary(PetId), 0,0},{12,1,integer_to_binary(Jie),0,0}],
    SendMes = {?pet_jinjie_mes_id, 2, [], [], MesList},
    {Type, _} = load_cfg_broadcast:get_notice_type(?pet_jinjie_mes_id),
    send_message_by_type(Type, SendMes).

%% 战力王者排名
zhanli_king_rank_up(PlayerId, Rank) ->
    Name = get_player_name(PlayerId),
    MesList = [{1 , 1, Name}, {7, 1, integer_to_binary(Rank)}],
    SendMes = {?zhanli_wangzhe_rank_up, 0, MesList, [], []},
    {Type, _} = load_cfg_broadcast:get_notice_type(?zhanli_wangzhe_rank_up),
    send_message_by_type(Type, SendMes).

%% 坐骑王者排名
ride_king_rank_up(PlayerId, Rank) ->
    Name = get_player_name(PlayerId),
    MesList = [{1 , 1, Name}, {7, 1, integer_to_binary(Rank)}],
    SendMes = {?zuoji_wangzhe_rank_up, 0, MesList, [], []},
    {Type, _} = load_cfg_broadcast:get_notice_type(?zuoji_wangzhe_rank_up),
    send_message_by_type(Type, SendMes).

%% 宠物王者排名
pet_king_rank_up(PlayerId, Rank) ->
    Name = get_player_name(PlayerId),
    MesList = [{1 , 1, Name}, {7, 1, integer_to_binary(Rank)}],
    SendMes = {?pet_wangzhe_rank_up, 0, MesList, [], []},
    {Type, _} = load_cfg_broadcast:get_notice_type(?pet_wangzhe_rank_up),
    send_message_by_type(Type, SendMes).

%% 套装王者
suit_king_rank_up(PlayerId, Rank) ->
    Name = get_player_name(PlayerId),
    MesList = [{1 , 1, Name}, {7, 1, integer_to_binary(Rank)}],
    SendMes = {?suit_wangzhe_rank_up, 0, MesList, [], []},
    {Type, _} = load_cfg_broadcast:get_notice_type(?suit_wangzhe_rank_up),
    send_message_by_type(Type, SendMes).

%% 深渊王者
shenyuan_king_rank_up(PlayerId, Rank) ->
    Name = get_player_name(PlayerId),
    MesList = [{1 , 1, Name}, {7, 1, integer_to_binary(Rank)}],
    SendMes = {?shenyuan_wangzhe_rank_up, 0, MesList, [], []},
    {Type, _} = load_cfg_broadcast:get_notice_type(?shenyuan_wangzhe_rank_up),
    send_message_by_type(Type, SendMes).

%% 公会王者
guild_king_rank_up(GuildId, Rank) ->
%%    ?INFO_LOG("GuildId = ~p", [GuildId]),
    GuildName = guild_service:get_guild_name(GuildId),
%%    ?INFO_LOG("GuildName = ~p", [GuildName]),
    MesList = [{1 , 1, GuildName}, {7, 1, integer_to_binary(Rank)}],
    SendMes = {?guild_wangzhe_rank_up, 0, MesList, [], []},
    {Type, _} = load_cfg_broadcast:get_notice_type(?guild_wangzhe_rank_up),
    send_message_by_type(Type, SendMes).


%% 根据消息类型发送公告
send_message_by_type(Type, Message) ->
    case Type of
        ?not_notice_type ->
            pass;
        ?system_notice_type ->
            world_notice(Message);
        {?system_notice_type, _Guild} ->
            world_notice(Message);
        ?guild_notice_type ->
            guild_notice(Message);
        {?guild_notice_type, GuildId} ->
            guild_notice(GuildId, Message);
        _ ->
            ?ERROR_LOG("not find type:~p", [Type])
    end.


%% 全服公告
world_notice(Message) ->
    world:broadcast(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM_C, Message))).

%% 公会公告
guild_notice(Message) ->
    broadcast_by_guild(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM_C, Message))).

guild_notice(GuildId, Message) ->
    broadcast_by_guild(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM_C, Message)), GuildId).

%% 广播消息到当前公会成员
broadcast_by_guild(Msg) ->
    [spawn(fun() -> PlayerPid ! Msg end) || {_PlayerId, PlayerPid} <- guild_service:get_memeber_online()],
    ok.

%% 根据工会id发送到当前公会
broadcast_by_guild(Msg, GuildId) ->
    [spawn(fun() -> PlayerPid ! Msg end) || {_PlayerId, PlayerPid} <- guild_service:get_memeber_online(GuildId)],
    ok.


%% 通过玩家id获取玩家的名字
get_player_name(PlayerId) ->
    case player:lookup_info(PlayerId, [?pd_name]) of
        [Name] ->
            Name;
        _ ->
            <<>>
    end.
%% up new --------------------------------------------------------------------------------------------------------





%% 记录强化之前的装备强化等级
send_qianghua_level(BucketType, EquipId, ReplyNum) ->
    case equip_system:get_equip(BucketType, EquipId) of
        #item_new{bid = EquipBid} = Equip ->
            QhLevel = item_new:get_field(Equip, ?item_equip_qianghua_lev, 1),
            Quality = item_new:get_field(Equip, ?item_equip_quality, 1),
            Name = get(?pd_name),
            case ReplyNum =:= ?REPLY_MSG_EQUIP_QIANG_HUA_OK of
                true ->
                    if
                        QhLevel-1 >= ?QIANGHUA_LEVEL_OF_SEND_MESSAGE ->
                            case lists:member(?qianghua_succeed_send_mes_id, load_cfg_broadcast:get_all_broadcast_mes_id()) of
                                true ->
                                    MesList = [{1, 1, Name, 0, 0}, {2, 2, integer_to_binary(EquipBid), Quality, QhLevel}],
                                    world:broadcast(?to_client_msg(chat_sproto:pkg_msg(?MSG_CHAT_SYSTEM_C,
                                        {?qianghua_succeed_send_mes_id, 1, [], MesList})));
                                _ ->
                                    pass
                            end;
                        true ->
                            pass
                    end;
                _ ->
                  pass
            end
    end.












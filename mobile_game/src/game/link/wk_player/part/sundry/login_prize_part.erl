%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 处理玩家杂项的请求
%%% @end
%%% Created : 26. 六月 2015 上午2:51
%%%-------------------------------------------------------------------
-module(login_prize_part).
-author("clark").

%% API
-export([get_left_prize/2
    , init_zhuan_pan_prize/0
    , init_sign_prize/0
]).

-include("inc.hrl").
-include_lib("common/include/inc.hrl").
-include("player.hrl").
-include("handle_client.hrl").
-include("guild_def.hrl").
-include("load_lvl_prize.hrl").
-include("load_day_login_prize.hrl").
-include("player_data_db.hrl").
-include("item_bucket.hrl").
-include("month_reset.hrl").
-include("day_reset.hrl").
-include("system_log.hrl").

-define(LOGIN_SIGN, 1).             %% 签到
-define(LOGIN_SUPPLY_SIGN, 2).      %% 补签
-define(LOGIN_SUPPLY_SIGN_ALL, 3).  %% 全部补签

-define(REPLY_MSG_SIGN_OK, 0).      %% 签到成功
-define(REPLY_MSG_SIGN_1, 1).       %% 签到失败，钻石不足
-define(REPLY_MSG_SIGN_2, 2).       %% 签到失败,已经签到过
-define(REPLY_MSG_SIGN_3, 3).       %% 签到失败,没有补签日期
-define(REPLY_MSG_SIGN_4, 4).       %% 签到失败,错误签到类型
-define(REPLY_MSG_SIGN_255, 255).   %% 签到失败,请重试。重试失败，请联系GM


%% 月重置
on_month_reset(_SelfId) ->
    %% 刷新登陆奖励
%%    put(?pd_login_prize, #login_prize{give_count = 0, login_count = 1}),
%%    SignInfoList = create_sign_info_list(),
%%    put(?pd_login_prize, #login_prize_new{sign_info_list = SignInfoList}),
%%    io:format("on_month_reset:sign_info_list:~p", [SignInfoList]),
    init_sign_prize(),
    ok.

init_zhuan_pan_prize() ->
    Len = 8,
    Level = get(?pd_level),
%%    PrizeID = load_dial_prize:get_prize_of_lvl_area(Level),
    {Day, _Time} = calendar:local_time(),
    Week = calendar:day_of_the_week(Day),
    PrizeID = load_dial_prize:get_prize_of_lvl_area_and_week(Level,Week),
    %?DEBUG_LOG("Level--------PrizeId--------------:~p",[{Level, PrizeID}]),
    if
        PrizeID > 0 ->
            PrizeList = prize:get_random_prize(PrizeID),
            NewDialList = rand_prize_2_dial_prize(PrizeList, 1, Len),
            NewDialPrize = #dial_prize{dial_prize = NewDialList, dial_count = 0},
            %?DEBUG_LOG("NewDialPrize----------------:~p",[NewDialPrize]),
            NewDialPrize;
        true ->
            []
    end.

init_sign_prize() ->
    SignInfoList = create_sign_info_list(),
    put(?pd_login_prize, #login_prize_new{sign_info_list = SignInfoList}),
    get(?pd_login_prize).

%% 日重置
on_day_reset(_SelfId) ->
    attr_new:set(?pd_challenged_count, 0),
    attr_new:set(?pd_buy_challenged_count, 0),
    attr_new:set(?pd_room_prize_count, 0),
    attenuation:clear_attenuation_data(),
    arena_p2e:get_p2e_arena_info(),

    %% 刷新登陆奖励
    LoginPrize = get(?pd_login_prize),
%%    LoginGive = LoginPrize#login_prize.give_count,
%%    LoginCount = LoginPrize#login_prize.give_count,
%%    put(?pd_login_prize, #login_prize{give_count = LoginGive, login_count = LoginCount + 1}),
%%    NewLoginPrize = get(?pd_login_prize),
%%    ?INFO_LOG("======登陆奖励刷新:~p", [NewLoginPrize]),
    %% 推送登陆奖励
%%    ?player_send(login_prize_sproto:pkg_msg(?MSG_LOGIN_DAY_DATA_SC, {NewLoginPrize#login_prize.login_count, LoginPrize#login_prize.give_count})),
    ?player_send(login_prize_sproto:pkg_msg(?MSG_PUSH_SIGN_INFO, {com_time:day_of_the_month(), LoginPrize#login_prize_new.sign_info_list})),

    % 转盘抽奖重置
    Len = 8,
    Level = get(?pd_level),
    {Day, _Time} = calendar:local_time(),
    Week = calendar:day_of_the_week(Day),
    PrizeID = load_dial_prize:get_prize_of_lvl_area_and_week(Level,Week),
%%    PrizeID = load_dial_prize:get_prize_of_lvl_area(Level),
    if
        PrizeID > 0 ->
            PrizeList = prize:get_random_prize(PrizeID),
            NewDialList = rand_prize_2_dial_prize(PrizeList, 1, Len),
            NewDialPrize = #dial_prize{dial_prize = NewDialList, dial_count = 0},
            % ?DEBUG_LOG("on day reset -------------------:~p", [NewDialList]),
            put(?pd_dial_prize, NewDialPrize),
            DialPrizeList = player_base_data:get_net_dial_prize(NewDialList),
            DialTime = com_time:get_seconds_to_next_day() + com_time:now(),
            ?player_send(login_prize_sproto:pkg_msg(?MSG_ROLL_ITEM_DATA_SC, {DialTime, 0, DialPrizeList}));
        true ->
            ok
    end,
    ok.

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 等级奖励请求
handle_client(?MSG_LEVEL_REWARD_CS, {RequestLvl}) ->
    Cfg = load_lvl_prize:lookup_lvl_prize_cfg(RequestLvl),
    case Cfg of
        #lvl_prize_cfg{id = RequestLvl, state = State, prize_id = PrizeId} ->
            Val = attr_new:get_sink_state(State),
            if
                Val =< 0 ->
                    % ?DEBUG_LOG_COLOR(?color_yellow, "verify MSG_LEVEL_REWARD_CS ~p ~p", [State, PrizeId]),
                    %% 给奖励和做记录
                    prize:prize_mail(PrizeId, ?S_MAIL_LEVEL, ?FLOW_REASON_LEVEL_PRIZE),
                    attr_new:set_sink_state(State, 1),
                    ?player_send(login_prize_sproto:pkg_msg(?MSG_LEVEL_REWARD_CS, {}));
                true ->
                    ?return_err(?ERR_SINK_STATE)
            end;
        _Other ->
            ?return_err(?ERR_LOOKUP_LVL_PRIZE_CFG)
    end;

%% 登陆奖励请求
handle_client(?MSG_SIGNIN_REWARD_CS, {Dayth}) ->
    LoginPrizeData = get(?pd_login_prize),
    {{_, _, ServerDays}, {_, _, _}} = erlang:localtime(),
    CurLoginCount = LoginPrizeData#login_prize.login_count,
    CurGiveCount = LoginPrizeData#login_prize.give_count,
%%     ?ERROR_LOG("222~n"),
    if
        Dayth > CurGiveCount andalso Dayth =< ServerDays ->
            %% 补签天数 = 选取天数 - max(登陆天数, 已领天数)
            CostPosID = erlang:max(CurLoginCount + 1, CurGiveCount + 1),
            CostCount = Dayth - CostPosID,
            CostPrizeCfgs =
                if
                    CostCount >= 0 ->
                        load_day_login_prize:get_cfg_list(CostPosID, CostCount);
                    true ->
                        []
                end,
            NeedDiamond = lists:sum([CostCfg#day_login_prize_cfg.diamond || CostCfg <- CostPrizeCfgs]),
            % ?DEBUG_LOG_COLOR(?color_yellow, "diamond ~p", [[CostCount, get(?pd_diamond), NeedDiamond]]),
            case util:can([player_util:fun_is_more_and_no_negative(get(?pd_diamond), NeedDiamond)]) of
                true ->
                    %% 付费奖励
                    %% 扣钻石
                    game_res:try_del([{?PL_DIAMOND, NeedDiamond}], ?FLOW_REASON_LOGIN_PRIZE),
                    [prize:prize_mail(CostCfg#day_login_prize_cfg.prize_id, ?S_MAIL_DAILY_ATTENDANCE, ?FLOW_REASON_LOGIN_PRIZE) || CostCfg <- CostPrizeCfgs],
                    %% 免费奖励 ＝ min(登陆计数,选择天数), － 领奖计数
                    FreePosID = erlang:min(Dayth, CurLoginCount),
                    FreeCount = FreePosID - CurGiveCount,
                    if
                        FreeCount > 0 ->
                            FreePrizeCfgs = load_day_login_prize:get_cfg_list(CurGiveCount, FreeCount),
                            %% 免费奖励
                            [prize:prize(FreeCfg#day_login_prize_cfg.prize_id, ?FLOW_REASON_LOGIN_PRIZE) || FreeCfg <- FreePrizeCfgs];
                        true ->
                            ok
                    end,
                    %% 记录最新领奖时间(为免问题复杂，登陆天数也更新到最新的)
                    NewLoginCount = erlang:max(Dayth, CurLoginCount),
                    put(?pd_login_prize, #login_prize{login_count = NewLoginCount, give_count = Dayth}),
                    ?player_send(login_prize_sproto:pkg_msg(?MSG_SIGNIN_REWARD_CS, {NewLoginCount, Dayth}));
                _ ->
                    %% 钻石不足
                    ?return_err(?ERR_DIAMOND_NOT_ENOUGH),
                    ok
            end;
        true ->
            %% 非有效领取奖励的时间区
            ?DEBUG_LOG_COLOR(?color_yellow, "非有效领取奖励的时间区 ~p", [[CurGiveCount, Dayth, ServerDays]]),
            ?return_err(?ERR_ERROR_TIME),
            ok
    end;

%% 每日签到
handle_client(?MSG_SIGN, {SignType}) ->
    Ret = do_sign(SignType),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_SIGN_OK;
            {error, diamond_not_enough} -> ?REPLY_MSG_SIGN_1;
            {error, already_sign} -> ?REPLY_MSG_SIGN_2;
            {error, no_supply_sign} -> ?REPLY_MSG_SIGN_3;
            {error, err_type} -> ?REPLY_MSG_SIGN_4;
            _ -> ?REPLY_MSG_SIGN_255
        end,
    LoginPrizeData = get(?pd_login_prize),
    SignInfoList = LoginPrizeData#login_prize_new.sign_info_list,
    Today = com_time:day_of_the_month(),
    %% ?DEBUG_LOG("Today:~p", [Today]),
    %% ?DEBUG_LOG("SignInfoList:~p", [SignInfoList]),
    %% ?DEBUG_LOG("ReplyNum:~p", [ReplyNum]),
    ?player_send(login_prize_sproto:pkg_msg(?MSG_SIGN, {Today, SignInfoList, ReplyNum}));

%% 单日补签
handle_client(?MSG_SUPPLY_SIGN, {Day}) ->
    Ret = supply_sign_day(Day),
    ReplyNum =
        case Ret of
            ok -> ?REPLY_MSG_SIGN_OK;
            {error, diamond_not_enough} -> ?REPLY_MSG_SIGN_1;
            {error, already_sign} -> ?REPLY_MSG_SIGN_2;
            {error, no_supply_sign} -> ?REPLY_MSG_SIGN_3;
            {error, err_type} -> ?REPLY_MSG_SIGN_4;
            _ -> ?REPLY_MSG_SIGN_255
        end,
    LoginPrizeData = get(?pd_login_prize),
    SignInfoList = LoginPrizeData#login_prize_new.sign_info_list,
    Today = com_time:day_of_the_month(),
    %% ?DEBUG_LOG("Today:~p", [Today]),
    %% ?DEBUG_LOG("SignInfoList:~p", [SignInfoList]),
    %% ?DEBUG_LOG("ReplyNum:~p", [ReplyNum]),
    ?player_send(login_prize_sproto:pkg_msg(?MSG_SUPPLY_SIGN, {Today, SignInfoList, ReplyNum}));

%% 抽奖请求
handle_client(?MSG_ROLL_LOTTERY_CS, _Msg) ->
%%     ?INFO_LOG("抽奖请求"),
    DialPrize = get(?pd_dial_prize),
    DialCount = DialPrize#dial_prize.dial_count,
    DialPrzieList = DialPrize#dial_prize.dial_prize,
    Len = 8,
    Vip = attr_new:get_vip_lvl(),
    %NeedDiamond = load_vip_right:get_need_diamond(Vip, DialCount + 1),
    NeedDiamond = load_vip_new:get_vip_zhuan_pan_times_by_vip_level(Vip, DialCount + 1),
    Coditions =
        [
            player_util:fun_is_more_and_no_negative(Len, DialCount),
            player_util:fun_is_more_and_no_negative(get(?pd_diamond), NeedDiamond)
        ],
    case util:can(Coditions) of
        true ->
            ?DEBUG_LOG_COLOR(?color_yellow, "DialCount < Len ~p ~p", [DialCount, Len]),
            LeftIdList = get_left_prize(DialPrzieList, 1),
            PosId = com_util:rand(LeftIdList),
            {_Id, GoodsId, GoodsNum, _State} = lists:nth(PosId, DialPrzieList),

            %% 扣钻石
            game_res:try_del([{?PL_DIAMOND, NeedDiamond}], ?FLOW_REASON_ROLL_LOTTERY),

            %% 给物品
            game_res:try_give_ex([{GoodsId, GoodsNum}], ?S_MAIL_TURNTABLE, ?FLOW_REASON_ROLL_LOTTERY),

            %% 物品槽打标志
            NewData = {PosId, GoodsId, GoodsNum, 1},
            NewDialPrizeList = lists:keyreplace(PosId, 1, DialPrzieList, NewData),

            %% 次数+1
            NewDialCount = DialCount + 1,
            NewDialPrize = #dial_prize{dial_count = NewDialCount, dial_prize = NewDialPrizeList},

            %% 保存
            put(?pd_dial_prize, NewDialPrize),

            %% 回复
%%             ?INFO_LOG("抽奖请求 ~p~n", [{ {GoodsId, GoodsNum}, {PosId, 1}, {NewDialCount, PosId} }]),
            ?player_send(login_prize_sproto:pkg_msg(?MSG_ROLL_ITEM_UPDATE_SC, {PosId, 1})),
            ?player_send(login_prize_sproto:pkg_msg(?MSG_ROLL_LOTTERY_CS, {NewDialCount, PosId}));

        _ ->
            ?return_err(?ERR_DIAMOND_NOT_ENOUGH)
    end.

get_left_prize([], _Id) -> [];
get_left_prize([Head | TailList], Id) ->
    {_, _, _, State} = Head,
    if
        State =< 0 ->
            [Id | get_left_prize(TailList, Id + 1)];
        true ->
            get_left_prize(TailList, Id + 1)
    end.


rand_prize_2_dial_prize([], Index, Limit) ->
    if
        Index =< Limit ->
            [{Index, 0, 0, 0} | rand_prize_2_dial_prize([], Index + 1, Limit)];
        true ->
            []
    end;
rand_prize_2_dial_prize([Head | TailList], Index, Limit) ->
    if
        Index =< Limit ->
            case Head of
                {ItemBid, ItemNum} ->
                    [{Index, ItemBid, ItemNum, 0} | rand_prize_2_dial_prize(TailList, Index + 1, Limit)];
                _ ->
                    [{Index, 0, 0, 0} | rand_prize_2_dial_prize(TailList, Index + 1, Limit)]
            end;
        true ->
            []
    end.

create_sign_info_list() ->
    LocalTime = erlang:localtime(),
    {{Year,Month,_},_} = LocalTime,
    Days = calendar:last_day_of_the_month(Year, Month),
    lists:zip(lists:seq(1,Days), lists:duplicate(Days, 0)).


do_sign(SignType) ->
    LoginPrizeData = get(?pd_login_prize),
    SignInfoList = LoginPrizeData#login_prize_new.sign_info_list,
    Today = com_time:day_of_the_month(),
    case SignType of
        %% 签到
        ?LOGIN_SIGN ->
            {Today, IsSign} = lists:keyfind(Today, 1, SignInfoList),
            case IsSign of
                0 ->
                    Key = util:get_the_YMD_of_day(),
                    #day_login_prize_cfg{id = _CfgId, prize_id = PrizeId} = load_day_login_prize:lookup_day_login_prize_cfg(Key),
                    prize:prize_mail(PrizeId, ?S_MAIL_DAILY_ATTENDANCE, ?FLOW_REASON_SIGN_PRIZE),
                    %% ?DEBUG_LOG("SignInfoList1:~p", [SignInfoList]),
                    NewSignInfoList = lists:keyreplace(Today, 1, SignInfoList, {Today, 1}),
                    put(?pd_login_prize, #login_prize_new{sign_info_list = NewSignInfoList}),
                    ok;
                _ ->
                    {error, already_sign}
            end;
        %% 补签
        ?LOGIN_SUPPLY_SIGN ->
            case lists:keyfind(0,2,SignInfoList) of
                {Day, 0} ->
                    Key = util:get_the_YMD_of_day(Day),
                    #day_login_prize_cfg{id = _CfgId, prize_id = PrizeId, diamond = Diamond} =
                        load_day_login_prize:lookup_day_login_prize_cfg(Key),
                    case game_res:can_del([{?PL_DIAMOND, Diamond}]) of
                        {error, Error} -> {error, Error};
                        _ ->
                            game_res:del([{?PL_DIAMOND, Diamond}], ?FLOW_REASON_SIGN),
                            prize:prize_mail(PrizeId, ?S_MAIL_DAILY_ATTENDANCE, ?FLOW_REASON_SIGN_PRIZE),
                            NewSignInfoList = lists:keyreplace(Day, 1, SignInfoList, {Day, 1}),
                            put(?pd_login_prize, #login_prize_new{sign_info_list = NewSignInfoList}),
                            ok
                    end;
                false ->
                    {error, no_supply_sign}
            end;
        %% 全部补签
        ?LOGIN_SUPPLY_SIGN_ALL ->
            %% 1.获得当天以前所有的未签到日期
            UnsignDayList = get_all_unsign_day(Today, SignInfoList),
            %% 2.获取的所有的prizeId列表和Diamond列表
            AllUnsignCfgList = get_all_unsign_cfg(UnsignDayList),
            NeedDiamond = lists:sum([CostCfg#day_login_prize_cfg.diamond || CostCfg <- AllUnsignCfgList]),
            %% 3.设置所有的日期为签到标志
            case game_res:can_del([{?PL_DIAMOND, NeedDiamond}]) of
                {error, Error} -> {error, Error};
                _ ->
                    game_res:del([{?PL_DIAMOND, NeedDiamond}], ?FLOW_REASON_SIGN),
                    [prize:prize_mail(CostCfg#day_login_prize_cfg.prize_id, ?S_MAIL_DAILY_ATTENDANCE, ?FLOW_REASON_SIGN_PRIZE) || CostCfg <- AllUnsignCfgList],
                    NewSignInfoList = set_sign_info_list(UnsignDayList,SignInfoList),
                    put(?pd_login_prize, #login_prize_new{sign_info_list = NewSignInfoList}),
                    ok
            end;
        _ ->
            {error, err_type}
    end.

get_all_unsign_day(Today,SignInfoList) ->
    UnsignDayList =
        lists:foldl(
            fun({Day,Status}, Acc) ->
                if
                    Day < Today andalso Status =:= 0 ->
                        [Day | Acc];
                    true ->
                        Acc
                end
            end,
            [],
            SignInfoList),
    UnsignDayList.

get_all_unsign_cfg(UnsignDayList) ->
    AllUnsignCfgList =
        lists:foldl(
            fun(Day, Acc) ->
                Key = util:get_the_YMD_of_day(Day),
                Cfg = load_day_login_prize:lookup_day_login_prize_cfg(Key),
                [Cfg | Acc]
            end,
            [],
            UnsignDayList
        ),
    AllUnsignCfgList.

set_sign_info_list(UnsignDayList, SignInfoList) ->
    lists:foldl(
        fun(Day, Acc) ->
            lists:keyreplace(Day, 1, Acc, {Day, 1})
        end,
        SignInfoList,
        UnsignDayList
    ).

%% 单日补签
supply_sign_day(Day) ->
    LoginPrizeData = get(?pd_login_prize),
    SignInfoList = LoginPrizeData#login_prize_new.sign_info_list,
    case lists:keyfind(Day,1,SignInfoList) of
        {Day, 0} ->
            Key = util:get_the_YMD_of_day(Day),
            #day_login_prize_cfg{id = _CfgId, prize_id = PrizeId, diamond = Diamond} =
                load_day_login_prize:lookup_day_login_prize_cfg(Key),
            case game_res:can_del([{?PL_DIAMOND, Diamond}]) of
                {error, Error} -> {error, Error};
                _ ->
                    game_res:del([{?PL_DIAMOND, Diamond}], ?FLOW_REASON_SIGN),
                    prize:prize_mail(PrizeId, ?S_MAIL_DAILY_ATTENDANCE, ?FLOW_REASON_SIGN_PRIZE),
                    NewSignInfoList = lists:keyreplace(Day, 1, SignInfoList, {Day, 1}),
                    put(?pd_login_prize, #login_prize_new{sign_info_list = NewSignInfoList}),
                    ok
            end;
        _ ->
            {error, already_sign}
    end.

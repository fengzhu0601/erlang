%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 八月 2015 下午3:57
%%%-------------------------------------------------------------------
-module(game_res).
-author("clark").

%% API
-export(
[
    get_bucket/1
    , can_give/1
    , can_give/2
    , give/2
    , give/3
    %, try_give/2
    %, try_give/3

    , can_del/1
    , del/2
    , try_del/2

    %, can_give_ex/1
    %, can_give_ex/2
    , give_ex/2
    , give_ex/3
    , try_give_ex/2
    , try_give_ex/3
    , set_res_reasion/1
    , do_extra_something_by_buckettype/3
]).


-include("inc.hrl").
-include("item.hrl").
-include("load_item.hrl").
-include("item_bucket.hrl").
-include("bucket_interface.hrl").
-include("load_phase_ac.hrl").
-include("player.hrl").
-include("achievement.hrl").

-define(pd_is_add_boss_card, pd_is_add_boss_card).


set_res_reasion(Reasion) ->
    attr_new:set(?pd_temp_res_change_reasion, Reasion).

get_bucket(BucketType) ->
    case BucketType of
        ?BUCKET_TYPE_BAG ->
            attr_new:get(?pd_goods_bucket);
        ?BUCKET_TYPE_DEPOT ->
            attr_new:get(?pd_depot_bucket);
        ?BUCKET_TYPE_EQM ->
            attr_new:get(?pd_equip_bucket);
        _ ->
            {error, unknown_type}
    end.

% try_give(GoodsList, Reason) -> try_give(GoodsList, nil, Reason).
% try_give(GoodsList, MailInfo, Reason) ->
%     case can_give(GoodsList, MailInfo) of
%         {error, Error} ->
%             {error, Error};
%         _ ->
%             give(GoodsList, MailInfo, Reason)
%     end.
try_give_ex(GoodsList, Reason) -> try_give_ex(GoodsList, nil, Reason).
try_give_ex(GoodsList, MailInfo, Reason) ->
    case can_give(GoodsList, MailInfo) of
        {error, Error} ->
            {error, Error};
        _ ->
            give_ex(GoodsList, MailInfo, Reason)
    end.



% can_give_ex(GoodsList) ->
%     can_give_ex(GoodsList, nil).
% can_give_ex(GoodsList, MailInfo) ->
%     can_give(GoodsList, MailInfo).

%% 能否给到背包里,, 能给则给，否则有邮件信息则发邮件[{Bid,Num}|TailList]
can_give(GoodsList) -> 
    can_give(GoodsList, nil).
can_give(GoodsList, MailInfo) ->
    ZipGoodsList = zip_goods_list(GoodsList),
    case MailInfo of
        nil ->
            %% 只要空间足就能发送， 配置表错误属于另一种错误，不在这里处理
            GoodsBucket = attr_new:get(?pd_goods_bucket),
            LeftSize = goods_bucket:get_empty_size(GoodsBucket),
            NeedLen = get_need_lenght(ZipGoodsList),
            if
                LeftSize >= NeedLen ->
                    ret:ok();
                true -> 
                    ret:error(no_enough_size) %%% !!!有优化空间
            end;
        _ ->
            %% 邮件发送无限制
            ret:ok()
    end.



%% 给到背包里, 能给则给，否则有邮件信息则发邮件
%% [{Bid,Num},[{Bid,Num,BuildParList}]|TailList]
give(GoodsList, Reason) -> 
    give_goods(GoodsList, nil, true, Reason).
give(GoodsList, MailInfo, Reason) -> 
    give_goods(GoodsList, MailInfo, true, Reason).
%% give_ex(GoodsList) -> give_goods(GoodsList, nil, false).
%% give_ex(GoodsList, MailInfo) -> give_goods(GoodsList, MailInfo, false).

%% give_ex == give
give_ex(GoodsList, Reason) -> 
    give_goods(GoodsList, nil, true, Reason).
give_ex(GoodsList, MailInfo, Reason) -> 
    give_goods(GoodsList, MailInfo, true, Reason).

%------------------------------------------------------------------------------------------------------------------------------------------dsl start
give_goods(GoodsList, MailInfo, GiveCanMerge, Reason) ->
    ZipGoodsList = zip_goods_list(GoodsList),
    GoodsBucket = attr_new:get(?pd_goods_bucket),
    SuitIdList = api:get_suitid_list(),
    goods_bucket:begin_sync(GoodsBucket),
    attr_new:begin_sync_attr(),
    {NewBucket, ReturnGoodsList} = do_give_goods(GoodsBucket, GiveCanMerge, [], ZipGoodsList, MailInfo, Reason),
    attr_new:end_sync_attr(),
    case NewBucket of
        error ->
            ?ERROR_LOG("give_goods error ~p", [{GoodsList, GoodsBucket, ReturnGoodsList}]),
            goods_bucket:end_sync(GoodsBucket),
            honest_user_mng:is_change_suit_prize_state(),
            NewSuitIdList = api:get_suitid_list(),
            do_suit_log(SuitIdList, NewSuitIdList),
            handle_add_boss_card(),
            error;
        _ ->
            goods_bucket:end_sync(NewBucket),
            honest_user_mng:is_change_suit_prize_state(),
            NewSuitIdList = api:get_suitid_list(),
            do_suit_log(SuitIdList, NewSuitIdList),
            handle_add_boss_card(),
            notify_player_new_item(ReturnGoodsList),
            ReturnGoodsList
    end.

do_give_goods(Bucket, _, ReturnGoodsList, [], _MailInfo, _Reason) ->
    ret:data2(Bucket, ReturnGoodsList);
do_give_goods(Bucket, GiveCanMerge, ReturnGoodsList, ZipGoodsList, MailInfo, Reason) ->
    EmptySize = goods_bucket:get_empty_size(Bucket),
    NewList = get_overlap_goods_list(ZipGoodsList),
    case NewList of
        [] ->
            ret:data2(Bucket, ReturnGoodsList);
        [{Goods}|T] when is_record(Goods, item_new) ->
            if
                EmptySize > 0 ->
                    %% 获得的是套装，更新套装排行榜
                    impact_ranking_list_handle_client:update_new_suit_ranking_list(Goods),
                    {NewBucket, NewGoods} = goods_bucket:add(Bucket, item_by_id, {Goods}),
                    add_goods_do_extra_something(Goods#item_new.bid, Goods#item_new.quantity),
                    handle_add_good(Goods#item_new.bid, Goods#item_new.quantity, [], Goods),
                    do_give_goods(NewBucket, GiveCanMerge, [NewGoods|ReturnGoodsList], T, MailInfo, Reason);
                true ->
                     if
                        MailInfo =/= nil ->
                            Bid = Goods#item_new.bid,
                            case goods_bucket:isnt_buf_goods(Bid) of
                                ok ->
                                    %% 更新套装排行榜
                                    impact_ranking_list_handle_client:update_new_suit_ranking_list(Goods),
                                    mail_mng:send_sysmail(attr_new:get(?pd_id), MailInfo, ZipGoodsList),
                                    ret:data2(Bucket, ZipGoodsList);
                                _ ->
                                    {error, left_items}
                            end;
                        true ->
                            {error, left_items}
                    end
            end;
        [{Bid, Num}|T] ->
            do_give_goods(Bucket, GiveCanMerge, ReturnGoodsList, [{Bid, Num, []}|T], MailInfo, Reason);
        [{Bid, Num, BuildParList}|T] ->
            NeedBuild = 
            case GiveCanMerge of
                false ->
                    true;
                _ ->
                    goods_bucket:can_add(Bucket, any_by_bid, {Bid, Num})
            end,
            case NeedBuild of
                {1, Lt, Mt} ->
                    %?DEBUG_LOG("Lt-----:~p------Mt----:~p",[Lt, Mt]),
                    %?DEBUG_LOG("Bid----:~p----Num---:~p-----NeedBuild----:~p",[Bid, Num, NeedBuild]),
                    {NewBucket, NewGoods} = goods_bucket:add(Bucket, any_by_bid, {Bid, Lt}),
                    add_goods_do_extra_something(Bid, Num),
                    NewT = 
                    if
                        Mt =/= 0 ->
                            [{Bid,Mt}|T];
                        true ->
                            T
                    end,
                    do_give_goods(NewBucket, GiveCanMerge, [NewGoods|ReturnGoodsList], NewT, MailInfo, Reason);
                _ ->
                    NeedLen = get_need_lenght([{Bid, Num}]),
                    if
                        EmptySize > 0 orelse NeedLen =:= 0 ->
                            case entity_factory:build(Bid, Num, BuildParList, Reason) of
                                {error, Error} ->
                                    {error, Error};
                                {ok, _ZiChanCount} ->
                                    do_give_goods(Bucket, GiveCanMerge, ReturnGoodsList, T, MailInfo, Reason);
                                #item_new{} = Goods ->
                                    % ?DEBUG_LOG("Goods--------------------------:~p",[Goods]),
                                    {NewBucket, NewGoods} = goods_bucket:add(Bucket, item_by_id, {Goods}),
                                    add_goods_do_extra_something(Goods#item_new.bid, Goods#item_new.quantity),
                                    %% 更新套装排行榜
                                    impact_ranking_list_handle_client:update_new_suit_ranking_list(Goods),
                                    case Num =:= 1 of                                                   %% 如果装备的个数不为0则个数减1之后重新开始递归
                                        true ->
                                            do_give_goods(NewBucket, GiveCanMerge, [NewGoods|ReturnGoodsList], T, MailInfo, Reason);
                                        _ ->
                                            case load_item:get_overlap(Bid) =:= 1 of
                                                false ->
                                                    do_give_goods(NewBucket, GiveCanMerge, [NewGoods|ReturnGoodsList], T, MailInfo, Reason);
                                                _ ->
                                                    do_give_goods(NewBucket, GiveCanMerge, [NewGoods|ReturnGoodsList], [{Bid, Num - 1, BuildParList}|T], MailInfo, Reason)
                                            end
                                    end;
                                _ ->
                                    {error, unknown_type}
                            end;
                        true ->
                            add_goods_do_send_mail(Bucket, ZipGoodsList, MailInfo)
                    end
            end
    end.

do_extra_something_by_buckettype(?BUCKET_TYPE_BAG, Goods, IsDo) ->
    Count = Goods#item_new.quantity,
    NewCount = 
    case IsDo of
        1 ->
            Count;
        0 ->
            -Count
    end,
    %daily_task_tgr:do_daily_task({?ev_get_item, Goods#item_new.bid}, NewCount);
    add_goods_do_extra_something(Goods#item_new.bid, NewCount);

do_extra_something_by_buckettype(_T, _, _) ->
    ?INFO_LOG("add_goods_do_extra_something_by_buckettype--------------errtype:~p",[_T]).

add_goods_do_extra_something(AddBid, BidNum) ->
    %BidNum = Goods#item_new.quantity,
    #item_attr_cfg{quality = Qua, type = Type, lev=Lev} = load_item:get_item_cfg(AddBid),

    achievement_mng:do_ac2(?angguishisi, AddBid, BidNum),
    achievement_mng:do_ac2(?shanguangchuanqi, AddBid, BidNum),
    if
        Type =:= 1 ->
            if
                Lev =:= 10 ->
                    achievement_mng:do_ac2(?yuelaiyueda, 0, BidNum);
                true ->
                    pass
            end,
            achievement_mng:do_ac2(?baoshishoucangjia, 0, BidNum),
            achievement_mng:do_ac2(?shanshanbaoshi, 0, BidNum);
        Type > 100 andalso Qua =:= 5 ->
            achievement_mng:do_ac2(?bilvzhengcheng, 0, BidNum);
        true -> ok
    end,
    daily_task_tgr:do_daily_task({?ev_get_item, AddBid}, BidNum),
    event_eng:post(?ev_get_item, {?ev_get_item, AddBid}, BidNum).

add_goods_do_send_mail(Bucket, ItemList, MailInfo) ->
    if
        MailInfo =/= nil ->
            %% 发邮件
            mail_mng:send_sysmail(attr_new:get(?pd_id), MailInfo, ItemList),
            ret:data2(Bucket, ItemList);
        true ->
            {error, left_items}
    end.


get_overlap_goods_list(List) ->
    L =
        lists:foldl(
            fun
                ({Goods}, RetList) ->
                    [{Goods} | RetList];
                ({Bid, Num}, RetList) ->
                    [{B, N} || {B, N} <- get_overlap_item_list(Bid, Num), N =/= 0] ++ RetList;
                ({Bid, Num, Res}, RetList) ->
                    RList = get_overlap_item_list(Bid, Num),
                    [{B, N, Res} || {B, N} <- RList, N =/= 0] ++ RetList
            end,
            [],
            List
        ),
    lists:reverse(L).

get_overlap_item_list(Bid, Num) ->
    case lists:keymember(Bid, 1, ?ASSET) of
        true ->
            [{Bid, Num}];
        _ ->
            OverLap = load_item:get_overlap(Bid),
            lists:duplicate((Num div OverLap), {Bid, OverLap}) ++ [{Bid, Num rem OverLap}]
    end.

do_suit_log(SuitIdList, NewSuitIdList) ->
    lists:foreach(
        fun({{SuitId, Level}, List}) ->
                case length(List) =:= 6 of
                    true ->
                        case lists:keyfind({SuitId, Level}, 1, SuitIdList) of
                            {{SuitId, Level}, OldList} ->
                                case length(OldList) < 6 of
                                    true ->
                                        system_log:info_suit_log(SuitId, Level);
                                    _ ->
                                        ignore
                                end;
                            _ ->
                                system_log:info_suit_log(SuitId, Level)
                        end;
                    _ ->
                        ignore
                end
        end,
        NewSuitIdList
    ).

notify_player_new_item(NewGoodsList) ->
    try
        ItemList = lists:foldl(
            fun(Goods, RetList) ->
                    case is_record(Goods, item_new) of
                        true ->
                            [Goods#item_new.id | RetList];
                        _ ->
                            case Goods of
                                {NewGoods} when is_record(NewGoods, item_new) ->
                                    [NewGoods#item_new.id | RetList];
                                _ ->
                                    RetList
                            end
                    end
            end,
            [],
            NewGoodsList
        ),
        ?player_send(item_sproto:pkg_msg(?MSG_ITEM_NEW_ITEM, {ItemList}))
    catch
        E:R ->
            ?ERROR_LOG("E:~p, R:~p, NewGoodsList:~p", [E, R, NewGoodsList])
    end.



%% 能否扣除物品[{Bid,Num}, {by_bid, {bid,num}}, {by_id,{GoodsID, num}]
can_del(GoodsList) ->
    DoCanDel =
        fun
            (_ThisFun, _Bucket, []) -> ret:ok();
            (ThisFun, Bucket, [{by_bid, {Bid, Num}} | TailList]) ->
                case lists:keymember(Bid, 1, ?ASSET) of
                    true ->
                        case entity_factory:can_sub_prop(Bid, Num) of
                            {error, _Other} -> ret:error(cant_del);
                            _ -> ThisFun(ThisFun, Bucket, TailList)
                        end;
                    false ->
                        case goods_bucket:can_del(Bucket, any_by_bid, {Bid, Num}) of
                            {error, Error} -> {error, Error};
                            _ -> ThisFun(ThisFun, Bucket, TailList)
                        end;
                    _ -> ret:error(unknow_type)
                end;
            (ThisFun, Bucket, [{by_id, {GoodsID}} | TailList]) ->
                ThisFun(ThisFun, Bucket, [{by_id, {GoodsID, -1}} | TailList]);
            (ThisFun, Bucket, [{by_id, {GoodsID, Num}} | TailList]) ->
                case goods_bucket:can_del(Bucket, item_by_id, {GoodsID, Num}) of
                    {error, Error} -> {error, Error};
                    _ -> ThisFun(ThisFun, Bucket, TailList)
                end;
            (ThisFun, Bucket, [{Bid, Num} | TailList]) ->
                ThisFun(ThisFun, Bucket, [{by_bid, {Bid, Num}} | TailList])
        end,
    ZipGoodsList = zip_goods_list(GoodsList),
    GoodsBucket = attr_new:get(?pd_goods_bucket),
    DoCanDel(DoCanDel, GoodsBucket, ZipGoodsList).


%% 扣除物品[{bid,num}|{by_bid, {bid,num}}|{by_id,{GoodsID, num}]
del(GoodsList, Reason) ->
    DoDel =
        fun
            (_ThisFun, Bucket, GivedGoodsListRet, []) -> ret:data2(Bucket, GivedGoodsListRet);
            (ThisFun, Bucket, GivedGoodsListRet, [{by_bid, {Bid, Num}} | TailList]) ->
                case lists:keymember(Bid, 1, ?ASSET) of
                    true ->
                        entity_factory:sub_prop(Bid, Num, Reason),
                        handle_del_good(Bid, Num, {}),
                        ThisFun(ThisFun, Bucket, GivedGoodsListRet, TailList);
                    false ->
                        daily_task_tgr:do_daily_task({?ev_get_item, Bid}, -Num),
                        event_eng:post(?ev_get_item, {?ev_get_item, Bid}, -Num),
                        {NewBucket, Goods} = goods_bucket:del(Bucket, any_by_bid, {Bid, Num}),
                        handle_del_good(Bid, Num, Goods),
                        NewGivedGoodsListRet = [Goods | GivedGoodsListRet],
                        ThisFun(ThisFun, NewBucket, NewGivedGoodsListRet, TailList);
                    _ ->
                        ret:error(unknow_type)
                end;
            (ThisFun, Bucket, GivedGoodsListRet, [{by_id, {GoodsID}} | TailList]) ->
                ThisFun(ThisFun, Bucket, GivedGoodsListRet, [{by_id, {GoodsID, -1}} | TailList]);
            (ThisFun, Bucket, GivedGoodsListRet, [{by_id, {GoodsID, Num}} | TailList]) ->
                {NewBucket, Goods} = goods_bucket:del(Bucket, item_by_id, {GoodsID, Num}),
                Bid = Goods#item_new.bid,
                handle_del_good(Bid, Num, Goods),
                daily_task_tgr:do_daily_task({?ev_get_item, Bid}, -Num),
                event_eng:post(?ev_get_item, {?ev_get_item, Bid}, -Num),
                NewGivedGoodsListRet = [Goods | GivedGoodsListRet],
                ThisFun(ThisFun, NewBucket, NewGivedGoodsListRet, TailList);
            (ThisFun, Bucket, GivedGoodsListRet, [{Bid, Num} | TailList]) ->
                ThisFun(ThisFun, Bucket, GivedGoodsListRet, [{by_bid, {Bid, Num}} | TailList])
        end,
    ZipGoodsList = zip_goods_list(GoodsList),
    GoodsBucket = attr_new:get(?pd_goods_bucket),
    goods_bucket:begin_sync(GoodsBucket),
    attr_new:begin_sync_attr(),
    Ret = DoDel(DoDel, GoodsBucket, [], ZipGoodsList),
    {NewGoodsBucket, NewGoodsList} = Ret,
    attr_new:end_sync_attr(),
    goods_bucket:end_sync(NewGoodsBucket),
    ret:data2(NewGoodsBucket, NewGoodsList),
%%     消费日志
    % system_log:info_pay_log(),
    honest_user_mng:is_change_suit_prize_state(),
    ok.


%% 扣除物品[{by_bid, {bid,num}}|{by_id,{GoodsID, num}]
%% -spec try_del( [Item] ) -> ok | {error, Error::term()} when Item::{by_bid, {Bid::integer(), Num::integer()}}|Item::{by_id, {Bid, Num}}.
try_del(GoodsList, Reason) ->
    case can_del(GoodsList) of
        ok ->
            del(GoodsList, Reason),
            ret:ok();
        {error, Error} -> {error, Error}
    end.


%% ------------------
%% private
%% ------------------
%% 整理需要的物品列表
zip_goods_list(GoodsList) ->
    NewGoodList = do_zip_goods_list([], GoodsList),
    lists:keysort(1, NewGoodList).
%%    lists:reverse(NewGoodList).

do_zip_goods_list(RetList, []) -> RetList;
do_zip_goods_list(RetList, [X | TailList]) ->
    case X of
        #item_new{} ->
            NewRetList = [{X} | RetList],
            do_zip_goods_list(NewRetList, TailList);
        _ ->
            NewRetList = [X | RetList],
            do_zip_goods_list(NewRetList, TailList)
    end;
do_zip_goods_list(List1, List2) ->
    ?ERROR_LOG("error arg List1:~p, List2:~p", [List1, List2]).

% get_need_lenght(GivedGoodsList) ->
%     GetNeedLenght =
%         fun
%             (_ThisFun, [], RetInt) -> 
%                 RetInt;
%             (ThisFun, [{_Goods} | GivedGoodsList1], RetInt) -> 
%                 ThisFun(ThisFun, GivedGoodsList1, RetInt + 1);
%             (ThisFun, [{Bid, Num} | GivedGoodsList1], RetInt) ->
%                 ThisFun(ThisFun, [{Bid, Num, []} | GivedGoodsList1], RetInt);
%             (ThisFun, [{Bid, Num, ParList} | GivedGoodsList1], RetInt) ->
%                 case lists:keymember(Bid, 1, ?ASSET) of
%                     true ->
%                         ThisFun(ThisFun, GivedGoodsList1, RetInt);
%                     false ->
%                         case Num =:= 1 of
%                             true ->
%                                 ThisFun(ThisFun, GivedGoodsList1, RetInt + 1);
%                             _ ->
%                                 case load_item:get_overlap(Bid) =:= 1 of
%                                     false ->
%                                         ThisFun(ThisFun, GivedGoodsList1, RetInt + 1);
%                                     _ ->
%                                         ThisFun(ThisFun, [{Bid, Num - 1, ParList} | GivedGoodsList1], RetInt + 1)
%                                 end
%                         end
%                 end
%         end,
%     GetNeedLenght(GetNeedLenght, GivedGoodsList, 0).
%% 获得实际需要的位置空间
get_need_lenght(GivedGoodsList) ->
    lists:foldl(
        fun
            ({#item_new{}}, RetCount) ->
                RetCount + 1;
            ({Bid, Num}, RetCount) ->
                get_item_need_size(Bid, Num) + RetCount;
            ({Bid, Num, _}, RetCount) ->
                get_item_need_size(Bid, Num) + RetCount
        end,
        0,
        GivedGoodsList
    ).

get_item_need_size(Bid, Num) ->
    case lists:keymember(Bid, 1, ?ASSET) of
        true ->
            0;
        _ ->
            OverLap = load_item:get_overlap(Bid),
            util:ceil(Num / OverLap)
    end.

handle_del_good(Bid, BidNum, Goods) ->
    try
        handle_del_good_(Bid, BidNum, Goods)
    catch
        E:R -> ?DEBUG_LOG("handle del good error:~p", [{E, R}])
    end.

handle_del_good_(Bid, BidNum, Goods) ->
    % ?DEBUG_LOG("handle del :~p", [{Bid, BidNum, Goods}]),
    case lists:keymember(Bid, 1, ?ASSET) of
        true ->
            if
                (Bid =:= ?PL_DIAMOND) ->
                    system_log:info_pay_log(BidNum);
                true -> ok
            end;
        false ->
            ID = Goods#item_new.id,
            #item_attr_cfg{quality = Qua, type = Type} = load_item:get_item_cfg(Bid),
            % 统计日志
            ItemNumBefore = api:get_player_item_count(Bid),
            system_log:info_use_item_log(Bid, Type, ItemNumBefore, Qua, ID, 0),
            system_log:info_item_trend_log(Type, ItemNumBefore, Qua,
                (ItemNumBefore - Qua), ID, 0),
            ok
    end.

handle_add_good(Bid, BidNum, BuildPar, Goods) ->
    try
        handle_add_good_(Bid, BidNum, BuildPar, Goods)
    catch
        E:R -> ?DEBUG_LOG("handle add good error:~p", [{E, R, erlang:get_stacktrace()}])
    end.


handle_add_good_(Bid, BidNum, BuildPar, Goods) ->
    case Goods of
        #item_new{id = ID} ->
            Bid = Goods#item_new.bid,
            %BidNum = Goods#item_new.quantity,
            #item_attr_cfg{quality = Qua, type = Type} = load_item:get_item_cfg(Bid),

            % 统计日志
            ItemNumBefore = api:get_player_item_count(Bid),
            system_log:info_get_item_log(Bid, Type, ItemNumBefore, Qua, ID, 0),
            system_log:info_item_trend_log(Type, ItemNumBefore, Qua,
                (ItemNumBefore + Qua), ID, 0),
            if % 添加钻石卡
                Qua =:= 4 andalso Type =:= 7 ->
                    put(?pd_is_add_boss_card, 1),
                    phase_achievement_mng:do_pc(?PHASE_AC_ZUANSHI_KA, BidNum);
                Type =:= 7 ->
                    put(?pd_is_add_boss_card, 1);
                true -> ok
            end;
        _ ->
            if 
                Bid =:= ?PL_MONEY ->
                    %achievement_mng:do_ac2(?jiacaiwanguan, 0, BidNum);
                    pass;
                (Bid =:= ?PL_DIAMOND) andalso BuildPar =:= [] ->
                    Diamond = attr_new:get(?pd_diamond),
                    %achievement_mng:do_ac2(?zuanshizhiwang, 0, BidNum),
                    system_log:info_free_give_diamond(Diamond, BidNum, 0),
                    add_diamond;
                (Bid =:= ?PL_DIAMOND) andalso BuildPar =:= [pay] ->
%%                    ?DEBUG_LOG("add pay diamond : ~p", [BidNum]),
                    add_paydiamond;
                true -> ok
            end,
            ok
    end.

handle_add_boss_card() ->
    case get(?pd_is_add_boss_card) of
        1 ->
            put(?pd_is_add_boss_card, 0),
            phase_achievement_mng:do_pc(?PHASE_AC_KAPAI_BOSS_QUALITY_KA, 10000, api:get_card_boss_quality_count());
        _ ->
            put(?pd_is_add_boss_card, 0),
            pass
    end.

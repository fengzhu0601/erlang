%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 七月 2015 上午11:00
%%%-------------------------------------------------------------------
-module(time_bucket).
-author("clark").
-extends(goods_bucket).


%% API
-export
([
    new_bucket/5,
    restore_bucket/1,
    can_add_page/1,
    add_page/1,
    can_start_add_page_timer/1,
    start_add_page_timer/1,
    handle_msg/2, %倒計時消息回調
    get_cfg_id/1
]).

-include("inc.hrl").
-include("bucket_interface.hrl").
-include("item_bucket.hrl").
-include("player_def.hrl").
-include("achievement.hrl").




new_bucket(ID, SaveKey, TempKey, UserType, Size) ->
    GoodsBucket = goods_bucket:new_bucket(ID, SaveKey, TempKey, UserType, Size),
    NewBucket = setelement(#bucket_interface.type, GoodsBucket, ?time_bucket_type),
    goods_bucket:set_field(NewBucket, ?unlick_time_limit, 0).


restore_bucket(Bucket = #bucket_interface{}) ->
    UnlickTime = goods_bucket:get_field(Bucket, ?unlick_time_limit, 0),
    NowTime = virtual_time:now(),
    if
        UnlickTime == 0 -> 
            ret:ok();
        UnlickTime =< NowTime ->
            NewBucket = add_page(Bucket),
            BucketUseType = goods_bucket:get_use_type(NewBucket),
            goods_bucket:save(NewBucket),
            goods_mng:send_bucket_unlock(BucketUseType, 0);
        true ->
            Dt = UnlickTime - NowTime,
            BucketUseType = goods_bucket:get_use_type(Bucket),
            TimerID = usetype_2_timetype(BucketUseType),
            timer_eng:start_tmp_timer(TimerID, ?MICOSEC_PER_SECONDS * Dt, ?MODULE, {unlock_msg, BucketUseType}),
            goods_mng:send_bucket_unlock(BucketUseType, Dt)
    end,
    ret:ok().


can_start_add_page_timer(Bucket = #bucket_interface{}) ->
    BucketUseType = goods_bucket:get_use_type(Bucket),
    TimerID = usetype_2_timetype(BucketUseType),
    case timer_eng:read_timer(TimerID) of
        none -> ret:ok();
        _ -> ret:error(unlock_ing)
    end.

get_cfg_id(Bucket = #bucket_interface{}) ->
    NowBucketSize = goods_bucket:get_field(Bucket, ?goods_bucket_size),
    CfgId = (NowBucketSize div ?bucket_page_size),
    CfgId.

start_add_page_timer(Bucket = #bucket_interface{}) ->
    BucketUseType = goods_bucket:get_use_type(Bucket),
    TimerID = usetype_2_timetype(BucketUseType),
    NowBucketSize = goods_bucket:get_field(Bucket, ?goods_bucket_size),
    CfgId = (NowBucketSize div ?bucket_page_size),
    case load_unlock:lookup_unlock_cfg(TimerID, CfgId) of
        #unlock_cfg{open_time = Time} ->
            NeedTime = ?MICOSEC_PER_SECONDS * (Time),
            UnLuck = virtual_time:now() + Time,
            NewBucket1 = goods_bucket:set_field(Bucket, ?unlick_time_limit, UnLuck),
            goods_bucket:save(NewBucket1),
            timer_eng:start_tmp_timer(TimerID, NeedTime, ?MODULE, {unlock_msg, BucketUseType}),
            Time;
        _ -> ret:error(failed_in_unlock_timer)
    end.

stop_add_page_timer(Bucket = #bucket_interface{}) ->
    BucketUseType = goods_bucket:get_use_type(Bucket),
    TimerID = usetype_2_timetype(BucketUseType),
    timer_eng:cancel_timer(TimerID),
    NewBucket1 = goods_bucket:set_field(Bucket, ?unlick_time_limit, 0),
    NewBucket1.

can_add_page(Bucket = #bucket_interface{}) ->
    MaxSinkNum = 80,
    Size = goods_bucket:get_field(Bucket, ?goods_bucket_size),
    if
        MaxSinkNum =< Size -> ret:error(already_max_size);
        true -> ret:ok()
    end.

add_page(Bucket = #bucket_interface{}) ->
    NowBucketSize = goods_bucket:get_field(Bucket, ?goods_bucket_size),
    CfgId = NowBucketSize div ?bucket_page_size,
    BucketUseType = goods_bucket:get_use_type(Bucket), %1, 2
    BucketTimeType = usetype_2_timetype(BucketUseType),
    Bucket1 = stop_add_page_timer(Bucket),
    case load_unlock:lookup_unlock_cfg(BucketTimeType, CfgId) of
        #unlock_cfg{unlock_num = UnlockNum} ->
            NewBucketSize = NowBucketSize + UnlockNum,
            NewBucketSize1 = min(?bucket_max_size, NewBucketSize),
            NewBucket1 = goods_bucket:set_field(Bucket1, ?goods_bucket_size, NewBucketSize1),
            NewBucket2 = goods_bucket:set_field(NewBucket1, ?unlick_time_limit, 0),
            goods_bucket:save(NewBucket2),
            NewBucket2;
        _ ->
            ret:error(failed_in_unlock)
    end.


%% -----------------------
%% private
%% -----------------------
usetype_2_timetype(UseType) ->
    case UseType of
        1 -> pd_bag;
        2 -> pd_depot;
        _ -> 0
    end.

%% %% 被动解锁
handle_msg(_FromMod, {unlock_msg, BucketUseType}) ->
    Bucket = case BucketUseType of
                 ?BUCKET_TYPE_BAG -> attr_new:get(?pd_goods_bucket);
                 ?BUCKET_TYPE_DEPOT -> attr_new:get(?pd_depot_bucket);
                 _ -> {error, unknown_type}
             end,
    case Bucket of
        {error, Error} -> {error, Error};
        _ ->
            add_page(Bucket),
            if
                BucketUseType =:= 1 ->
                    achievement_mng:do_ac2(?beibaodaren, 0, 1);
                BucketUseType =:= 2 ->
                    achievement_mng:do_ac2(?cangkudaren, 0, 1)
            end,
            goods_mng:send_bucket_unlock(BucketUseType, 0)
    end;


handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).




%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 卡牌变身
%%%
%%% @end
%%% Created : 08. 三月 2016 上午11:23
%%%-------------------------------------------------------------------
-module(shapeshift_mng).
-author("fengzhu").

-include("inc.hrl").
-include("player.hrl").
-include("load_item.hrl").
-include("load_cfg_card.hrl").
-include("load_phase_ac.hrl").
-include("../part/wonderful_activity/bounty_struct.hrl").


%% API
-export
([
    can_shapeshift/2                       %%能否变身
    , start_shapeshift_effect/2            %%开启变身
    , stop_shapeshift_effect/0             %%关闭变身
    , try_restore_shapeshift/0             %%尝试恢复变身
    , use_card/1                           %%使用变身卡牌
    , on_shapeshift_effect_time/1          %%变身定时器的回调
]).

-define(shapeshift_timer, '@shapeshift_timer@').
%%-define(shapeshift_end_time, '@shapeshift_end_time@').

can_shapeshift(CardId, EndTime) ->
    CurTime = util:get_now_second(0),
    if
        CurTime < EndTime ->
            true;
        true ->
            false
    end.

start_shapeshift_effect(CardId, EndTime) ->
    attr_new:set(?pd_shapeshift_data, CardId),
    attr_new:set(?pd_shapeshift_end_time, EndTime),
    %% 开启变身效果定时器
    CurTime = util:get_now_second(0),
    Args = [],
    if
        CurTime < EndTime ->
            Dt = EndTime - CurTime,
            Ret = timer_server:start(Dt * 1000, {?MODULE, on_shapeshift_effect_time, [Args]}),
            attr_new:set(?shapeshift_timer, Ret),
            %%　同步数据到前端
            Career = attr_new:get(?pd_career, []),
            scene_mng:send_msg({?msg_update_shapeshift_data, get(?pd_idx), CardId, Career}),
            ?player_send(player_sproto:pkg_msg(?MSG_DRESS_SHAPESHIFT, {CardId})),
            case load_cfg_card:lookup_item_card_attr_cfg(CardId) of
                #item_card_attr_cfg{buffs = Buffs} ->
                    lists:foreach(
                        fun(BuffId) ->
                            equip_buf:take_on_buf2(BuffId,EndTime)
                        end,
                        Buffs
                    );
                _ -> ok
            end,
            ok;
        true ->
            on_shapeshift_effect_time(Args),
            ok
    end.

stop_shapeshift_effect() ->
    CardID = attr_new:get(?pd_shapeshift_data, 0),
    case load_cfg_card:lookup_item_card_attr_cfg(CardID) of
        #item_card_attr_cfg{buffs = Buffs} ->
            lists:foreach(
                fun(BuffId) ->
                    equip_buf:take_off_buf2(BuffId)
                end,
                Buffs
            );
        _ -> ok
    end,
    attr_new:set(?pd_shapeshift_data, 0),
    attr_new:set(?pd_shapeshift_end_time, 0),
    %% 关闭变身效果定时器
    case attr_new:get(?shapeshift_timer, nil) of
        nil -> ok;
        Ret ->
            timer_server:stop(Ret),
            attr_new:set(?shapeshift_timer, nil)
    end,
    %%　同步数据到前端
    Career = attr_new:get(?pd_career, []),
    scene_mng:send_msg({?msg_update_shapeshift_data, get(?pd_idx), 0, Career}),
    ?player_send(player_sproto:pkg_msg(?MSG_DRESS_SHAPESHIFT, {0})),
    ok.

on_shapeshift_effect_time(_Args) ->
    ok = stop_shapeshift_effect(),
    ok.

%% 尝试恢复变身效果
try_restore_shapeshift() ->
    CardID = attr_new:get(?pd_shapeshift_data, 0),
    if
        CardID =:= 0 ->
            ok;
        true ->
            EndTime = attr_new:get(?pd_shapeshift_end_time, 0),
            case can_shapeshift(CardID, EndTime) of
                false ->
                    attr_new:set(?pd_shapeshift_data, 0),
                    ok;
                true ->
                    ok = start_shapeshift_effect(CardID, EndTime),
                    ok
            end
    end.

%% 使用变身卡
use_card(Bid) ->
    case load_cfg_card:lookup_item_card_attr_cfg(Bid) of
        #item_card_attr_cfg{time = Time} ->
            stop_shapeshift_effect(),
            CurTime = util:get_now_second(0),
            EndTime = Time + CurTime,
            case can_shapeshift(Bid, EndTime) of
                false ->
                    ok;
                true ->
                    ok = start_shapeshift_effect(Bid, EndTime),
                    ride_mng:getoff_normal_ride_for_shapeshift(),
                    mount_tgr:getoff_ride_for_shapeshift(),
                    bounty_mng:do_bounty_task(?BOUNTY_TASK_SHAPESHIFT, 1),
                    %% 卡牌变身次数
                    phase_achievement_mng:do_pc(?PHASE_AC_KAPIA_BIANSHEN, 1),
                    card_new_mng:use_card(Bid),
                    ok
            end;
        _ ->
            false
    end.

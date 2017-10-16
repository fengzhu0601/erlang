%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zlb
%%% @doc 卡牌大师
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(card_mng).

%-include_lib("pangzi/include/pangzi.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").

%%-include("card.hrl").
-include("card_mng_reply.hrl").
-include("load_cfg_card.hrl").
-include("load_phase_ac.hrl").
-include("system_log.hrl").

-define(pd_card_this_rand_item, pd_card_this_rand_item). %存储当前随机到的道具

handle_frame(_) -> ok.


create_mod_data(_SelfId) ->
    ok.

load_mod_data(_PlayerId) ->
    ok.

init_client() ->
    ignore.

view_data(Msg) ->
    Msg.

online() -> ok.

offline(_PlayerId) ->
    ok.
save_data(_) -> ok.

handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_CARD) of
        ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
        ?true -> handle_client(Pack, Arg)
    end.

handle_client(?MSG_CARD_AWARD, {ItemTpL}) ->  %% 抽奖
%%     ?INFO_LOG("?MSG_CARD_AWARD1 ~p",[{ItemTpL}]),
    {ReplyNum, ATpL} = case card_award(ItemTpL) of
                           {ok, AddItemTpL} ->
                               {?REPLY_MSG_CARD_AWARD_OK, AddItemTpL};
                           {error, Reason} ->
                               Rp = if
                                        Reason =/= not_enough ->
                                            ?REPLY_MSG_CARD_AWARD_1;
                                        ?true ->
                                            ?REPLY_MSG_CARD_AWARD_255
                                    end,
                               {Rp, []}
                       end,
%%     ?INFO_LOG("?MSG_CARD_AWARD ~p",[{ReplyNum, ATpL}]),
    ?player_send(card_sproto:pkg_msg(?MSG_CARD_AWARD, {ReplyNum, ATpL})),
    ok;
handle_client(?MSG_CARD_AWARD_INFO, {}) ->  %% 获取奖励公告列表
    PageL = card_svr:lookup_award_infos(),
    ?player_send(card_sproto:pkg_msg(?MSG_CARD_AWARD_INFO, {PageL})),
    ok;

%% 广播公告
handle_client(?MSG_CARD_BROADCAST_NOTICE, {}) ->
    case put(?pd_card_this_rand_item, ?undefined) of
        ?undefined -> ok;
        AddItemTpL ->
            world:broadcast(?to_client_msg(card_sproto:pkg_msg(?MSG_CARD_BROADCAST_NOTICE, {get(?pd_id), get(?pd_name), AddItemTpL})))
    end;

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [Mod, Msg]).

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

card_award(ItemTpL) ->
    case load_cfg_card:lookup_card_cfg(ItemTpL) of
        #card_cfg{quality = _Qua, prize_id = PrizeId} ->
            %% ?INFO_LOG("card_award PrizeId ~p",[PrizeId]),
            case game_res:try_del(ItemTpL, ?FLOW_REASON_CARD_TURN) of
                ok ->
                    case prize:prize_mail(PrizeId, ?S_MAIL_CARD_AWARD, ?FLOW_REASON_CARD_TURN) of
                        AddItemTpL when is_list(AddItemTpL) ->
                            %% 卡牌抽奖次数
                            phase_achievement_mng:do_pc(?PHASE_AC_KAPAI_CHOUJING, 1),

                            %% ?INFO_LOG("card_award AddItemTpL ~p",[AddItemTpL]),
                            SelfId = get(?pd_id),
                            Name = get(?pd_name),
                            card_svr:add_award_info(SelfId, Name, AddItemTpL),
                            put(?pd_card_this_rand_item, AddItemTpL),
                            {ok, AddItemTpL};
                        {error, _AddReason} ->
                            {error, add_fail}
                    end;
                {error, _Reason} ->
                    {error, not_enough}
            end;
        _ -> {error, not_found_cfg}
    end.





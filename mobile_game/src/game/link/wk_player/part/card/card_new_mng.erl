%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. 十二月 2016 上午10:31
%%%-------------------------------------------------------------------
-module(card_new_mng).
-author("fengzhu").

-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("card_new_struct.hrl").


%% API
-export([
    init_card_list/0
    , use_card/1
]).

load_db_table_meta() ->
    [
        #db_table_meta
        {
            name = ?player_card_new_tab,
            fields = ?record_fields(?player_card_new_tab),
            shrink_size = 1,
            flush_interval = 3
        }
    ].

create_mod_data(PlayerId) ->
    CardList = init_card_list(),
    BountyTab =
        #player_card_new_tab
        {
            id = PlayerId,
            card_list = CardList
        },
    case dbcache:insert_new(?player_card_new_tab, BountyTab) of
        ?true ->
            ok;
        ?false ->
            ?ERROR_LOG("player ~p create new player_equip_goods_table error mode ~p", [PlayerId, ?MODULE])
    end,
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?player_card_new_tab, PlayerId) of
        [] ->
            ?INFO_LOG("player ~p not find player_bounty_tab mode ~p", [PlayerId, ?MODULE]),
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_card_new_tab{card_list = CardList}] ->
            ?pd_new(?player_card_list, CardList)
    end.

init_client() ->
    ignore.

view_data(Msg) ->
    Msg.

online() -> ok.

offline(_PlayerId) ->
    ok.
save_data(_) -> ok.

handle_msg(FromMod, Msg) ->
    ?ERROR_LOG("~p recv a unknown msg ~p from ~p", [?pname(), Msg, FromMod]).

handle_frame(_) -> ok.

handle_client({Pack, Arg}) ->
    case task_open_fun:is_open(?OPEN_CARD) of
        ?false -> ?return_err(?ERR_NOT_OPEN_FUN);
        ?true -> handle_client(Pack, Arg)
    end.


handle_client(?MSG_CARD_NEW_INFO, {}) ->
    push_card_list_info();

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [Mod, Msg]).


init_card_list() ->
    CardIdList = load_cfg_card:get_all_card_id(),
    lists:foldl(
        fun(CardId, Acc) ->
            MaxTimes = load_cfg_card:get_activation_num_by_id(CardId),
            [{CardId, 0, MaxTimes,0} | Acc]
        end,
        [],
        CardIdList
    ).

use_card(CardId) ->
    CardList = get(?player_card_list),
    {CardId, CurNum, MaxNum, IsActivation} = lists:keyfind(CardId, 1, CardList),
    case IsActivation of
        0 ->
            NewCardList =
                if
                    CurNum+1 >= MaxNum ->
%%                        addAttr(),
                        lists:keystore(CardId, 1, CardList, {CardId, MaxNum, MaxNum, 1});
                    true ->
                        lists:keystore(CardId, 1, CardList, {CardId, CurNum+1, MaxNum, IsActivation})
                end,
            put(?player_card_list, NewCardList),
            push_card_list_info();
        _ ->
            pass
    end.

push_card_list_info() ->
    NewCardList =
        lists:foldl(
            fun({CardId, CurNum, MaxNum, _},Acc) ->
                [{CardId, CurNum, MaxNum} | Acc]
            end,
            [],
            get(?player_card_list)
        ),
    ?player_send(card_new_sproto:pkg_msg(?MSG_CARD_NEW_INFO, { NewCardList })).

%% 获取卡牌技能修改集
get_card_skill_modify_id_list() ->
    %% 计算卡牌技能的修改集
    CardList = get(?player_card_list),
    CardSkillCfgList =
        lists:foldl
        (
            fun({CardId, _, _, IsActivation}, AccList) ->
                case IsActivation of
                    1 ->
                        case load_cfg_card:get_activation_buffs_by_id(CardId) of
                            CfgId when is_integer(CfgId) andalso CfgId =/= 0 ->
                                [CfgId | AccList];
                            _ ->
                                AccList
                        end;
                    _ ->
                        AccList
                end
            end,
            [],
            CardList
        ).

%% 还原卡牌属性
restore_card() ->
    NewCrownSkillModifyList = get_card_skill_modify_id_list(),
%%    update_crown_skill_modify_attr([], NewCrownSkillModifyList),
    ok.
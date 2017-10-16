%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 六月 2015 下午5:21
%%%-------------------------------------------------------------------
-module(player_data_db).
-author("clark").

%% API
-export(
[
    get_pay_order_list/0,
    del_pay_order_list/1,
    pushback_order/2,
    push_payment_order/3,
    update_order/2,
    update_order_by_id/2,
    new_bucket_db_record/2,
    lookup_info/3,
    lookup_attr/3,
    lookup_equip/2,
    lookup_skills/1,
    update_pc_prize/1,
    update_level_prize_times/0,
    add_suit_prize_times/0,
    reduce_suit_prize_times/0
]).

-include("inc.hrl").
-include("player_data_db.hrl").
-include_lib("pangzi/include/pangzi.hrl").
-include("player.hrl").
-include("item_bucket.hrl").
-include("load_spirit_attr.hrl").
-include("load_career_attr.hrl").
-include("achievement.hrl").
-include("scene.hrl").
-include("skill_struct.hrl").

%% 数据库建表(表不存在时进行)
load_db_table_meta() ->
    [
        #?db_table_meta
        {
            name = ?player_platform_id_tab,
            fields = ?record_fields(?player_platform_id_tab),
            shrink_size = 10,
            flush_interval = 2 %% dirty
        },

        #?db_table_meta
        {
            name = ?account_tab,
            fields = ?record_fields(?account_tab),
            shrink_size = 20,
            flush_interval = 0
        },

        #?db_table_meta
        {
            name = ?player_client_data_tab,
            fields = ?record_fields(?player_client_data_tab),
            shrink_size = 20,
            flush_interval = 3 %%
        },

        #?db_table_meta
        {
            name = ?player_tab,
            fields = ?record_fields(?player_tab),
            defualt_values = #?player_tab{},
            shrink_size = 20,
            flush_interval = 3
        },

        #?db_table_meta
        {
            name = ?player_name_tab,
            fields = ?record_fields(?player_name_tab),
            load_all = true,
            shrink_size = 200,
            flush_interval = 4
        },

        #?db_table_meta
        {
            name = ?player_attr_tab,
            fields = ?record_fields(?player_attr_tab),
            shrink_size = 20,
            flush_interval = 4
        },

        #?db_table_meta
        {
            name = ?player_misc_tab,
            fields = ?record_fields(?player_misc_tab),
            shrink_size = 20,
            flush_interval = 4
        },

        #?db_table_meta
        {
            name = ?player_data_tab,
            fields = ?record_fields(?player_data_tab),
            shrink_size = 10,
            flush_interval = 4
        },

        %% 玩家已装备物品
        #?db_table_meta
        {
            name = ?player_equip_tab,
            fields = ?record_fields(player_backet_tab),
            record_name = player_backet_tab,
            shrink_size = 1,
            flush_interval = 3
        },

        %% 玩家镜像
        #?db_table_meta
        {
            name = ?player_attr_image_tab,
            fields = ?record_fields(player_attr_image_tab),
            record_name = player_attr_image_tab,
            shrink_size = 20,
            flush_interval = 3
        },

        #?db_table_meta
        {
            name = ?account_prize_tab,
            fields = ?record_fields(account_prize_tab),
            record_name = account_prize_tab,
            shrink_size = 20,
            flush_interval = 0
        }
    ].



update_pc_prize(JieDuan) ->
    AccountName = get(?pd_user_id),
    case dbcache:load_data(?account_prize_tab, AccountName) of
        [] ->
            dbcache:insert_new(?account_prize_tab, #account_prize_tab{account_name = AccountName, phase_list = [{JieDuan, 1}]});
        [#account_prize_tab{phase_list = List} = Tab] ->
            NewList = case lists:keyfind(JieDuan, 1, List) of
                ?false ->
                    [{JieDuan, 1} | List];
                {_, Count} ->
                    lists:keyreplace(JieDuan, 1, List, {JieDuan, Count + 1})
            end,
            dbcache:update(?account_prize_tab, Tab#account_prize_tab{account_name = AccountName, phase_list=NewList})
    end.


get_pay_order_list() ->
    Ret = get(?pd_pay_orders),
    Ret#pay_orders.pay_orders.


%% 这个方法好像有点问题
% do_del_pay_order_list([], _Count, _Id) -> [];
% do_del_pay_order_list([Head | TailList], Count, Id) ->
%     if
%         Count == Id ->
%             do_del_pay_order_list(TailList, Count + 1, Id);
%         true ->
%             [Head | do_del_pay_order_list(TailList, Count + 1, Id)]
%     end.
del_pay_order_list(Id) ->
    Orders = get(?pd_pay_orders),
    OrdersList = get_pay_order_list(),
    Count =
        case lists:keyfind(Id, 1, OrdersList) of
            false ->
                Orders#pay_orders.total_orders_count;
            _ ->
                Orders#pay_orders.total_orders_count - 1
        end,
%%    NewOrdersList = do_del_pay_order_list(OrdersList, 1, Id),
    NewOrdersList = lists:keydelete(Id, 1, OrdersList),
    put(?pd_pay_orders, #pay_orders{total_orders_count = Count, pay_orders = NewOrdersList}).

pushback_order(RMB, State) ->
    CurDay = com_time:now(),
    Orders = get(?pd_pay_orders),
    Count = Orders#pay_orders.total_orders_count + 1,
    CurOrderList = Orders#pay_orders.pay_orders,
    %% 订单号
    NewOrder = 
    case CurOrderList of
       [] ->
           {Count, RMB, CurDay, State};
       _ ->
           [FirstOrderList | _] = CurOrderList,
           {EndId, _, _, _} = FirstOrderList,
           {EndId + 1, RMB, CurDay, State}
   end,
    NewOrderList = [NewOrder | CurOrderList],
    put(?pd_pay_orders, #pay_orders{total_orders_count = Count, pay_orders = NewOrderList}),
    NewOrder.

push_payment_order(Billno, RMB, State) ->
    CurDay = com_time:now(),
    Orders = get(?pd_pay_orders),
    Count = Orders#pay_orders.total_orders_count + 1,
    OrderId = Billno,
    CurOrderList = Orders#pay_orders.pay_orders,
    %% 订单号
    NewOrder = {OrderId, RMB, CurDay, State},
    NewOrderList = [NewOrder | CurOrderList],
    put(?pd_pay_orders, #pay_orders{total_orders_count = Count, pay_orders = NewOrderList}),
    NewOrder.

update_order_by_id(Billno, State) ->
    Orders = get(?pd_pay_orders),
    OrdersList = get_pay_order_list(),
    case lists:keyfind(Billno, 1, OrdersList) of
        false ->
            ok;
        Order ->
            {Id, RMB, CurDay, _OState} = Order,
            NewOrdersList = lists:keyreplace(Id, 1, OrdersList, {Id, RMB, CurDay, State}),
            put(?pd_pay_orders, Orders#pay_orders{pay_orders = NewOrdersList})
    end.

update_order(Order, State) ->
    {Id, RMB, CurDay, _OState} = Order,
    Orders = get(?pd_pay_orders),
    OrdersList = get_pay_order_list(),
    NewOrdersList = lists:keyreplace(Id, 1, OrdersList, {Id, RMB, CurDay, State}),
    put(?pd_pay_orders, Orders#pay_orders{pay_orders = NewOrdersList}).



new_bucket_db_record(PlayeID, Bucket) ->
    #player_backet_tab{id = PlayeID, bucket = Bucket}.



lookup_info(PlayerId, Keys, Def) when is_list(Keys) ->
    case dbcache:lookup(?player_tab, PlayerId) of
        [] -> [Def];
        [Info] ->
            lists:foldr(
                fun
                    (?pd_name, Acc) ->
                        [Info#player_tab.name | Acc];
                    (?pd_name_pkg, Acc) ->
                        [<<?pkg_sstr(Info#player_tab.name)>> | Acc];
                    (?pd_level, Acc) ->
                        [Info#player_tab.level | Acc];
                    (?pd_career, Acc) ->
                        [Info#player_tab.career | Acc];
                    (?pd_exp, Acc) ->
                        [Info#player_tab.exp | Acc];
                    (?pd_item_id, Acc) ->
                        [Info#player_tab.item_id | Acc];
                    (?pd_longwens, Acc) ->
                        [Info#player_tab.longwens | Acc];
                    (?pd_combat_power, Acc) ->
                        [Info#player_tab.combat_power | Acc];
                    (?pd_scene_id, Acc) ->
                        case scene_mng:lookup_player_scene_id_if_online(PlayerId) of
                            offline ->
                                [Info#player_tab.scene_id | Acc];
                            SceneId ->
                                [SceneId | Acc]
                        end;
                    (_X, Acc) ->
                        [none | Acc]
                end,
                [],
                Keys)
    end.

lookup_attr(PlayerId, Keys, Def) when is_list(Keys) ->
    case dbcache:lookup(?player_attr_image_tab, PlayerId) of
        [] ->
            Def;
        [#player_attr_image_tab{attr_new = OAttr}] ->
            Attr = player_base_data:change_old_attr(OAttr),
            lists:foldr(
                fun
                    (?pd_hp, Acc) ->
                        [Attr#attr.hp | Acc];
                    (?pd_sp, Acc) ->
                        [Attr#attr.sp | Acc];
                    (?pd_mp, Acc) ->
                        [Attr#attr.mp | Acc];
                    (?pd_attr, Acc) ->
                        [Attr | Acc];
                    (_X, Acc) ->
                        [none | Acc]
                end,
                [],
                Keys)
    end.

lookup_equip(PlayerId, Def) ->
    case dbcache:load_data(?player_equip_tab, PlayerId) of
        [EqmBucketTab] ->
            Bucket = EqmBucketTab#player_backet_tab.bucket,
            BucketInfo = goods_bucket:get_info(Bucket),
            [BucketInfo#bucket_info.items];
        [] ->
            Def
    end.

get_dressed_skill_list(RetList, []) -> RetList;
get_dressed_skill_list(RetList, [{_, SkillID} | TailList]) -> get_dressed_skill_list([SkillID | RetList], TailList).
get_long_wens_list(LongWen) when is_list(LongWen) -> LongWen;
get_long_wens_list(_LongWen) -> [].
lookup_skills(PlayerId) ->
    case dbcache:lookup(?player_skill_tab, PlayerId) of
        [#player_skill_tab{skills = _Mng, long_wens = LongWenList, dressed_skills = Dressed, dress_group_id = _DressGroupId}] ->
            SkillList = get_dressed_skill_list([], Dressed),
            LongWens = get_long_wens_list(LongWenList),
%%             ?INFO_LOG("get_skills ~p",[{Mng, LongWenList, Dressed, DressGroupId}]),
            {SkillList, LongWens};
        _ ->
%%             ?ERROR_LOG("get_skills error ~p",[{PlayerId}]),
            {[], []}
    end.

update_level_prize_times() ->
    AccountName = get(?pd_user_id),
    case dbcache:load_data(?account_prize_tab, AccountName) of
        [] ->
            dbcache:insert_new(?account_prize_tab, #account_prize_tab{account_name = AccountName, level_prize_state = 1});
        [#account_prize_tab{level_prize_state = Times} = Tab] ->
            dbcache:update(?account_prize_tab, Tab#account_prize_tab{level_prize_state = Times + 1})
    end.

add_suit_prize_times() ->
    AccountName = get(?pd_user_id),
    case dbcache:load_data(?account_prize_tab, AccountName) of
        [] ->
            dbcache:insert_new(?account_prize_tab, #account_prize_tab{account_name = AccountName, suit_prize_state = 1});
        [#account_prize_tab{suit_prize_state = Times} = Tab] ->
            dbcache:update(?account_prize_tab, Tab#account_prize_tab{suit_prize_state = Times + 1})
    end.

reduce_suit_prize_times() ->
    AccountName = get(?pd_user_id),
    case dbcache:load_data(?account_prize_tab, AccountName) of
        [] ->
            ignore;
        [#account_prize_tab{suit_prize_state = Times} = Tab] ->
            dbcache:update(?account_prize_tab, Tab#account_prize_tab{suit_prize_state = max(Times - 1, 0)})
    end.
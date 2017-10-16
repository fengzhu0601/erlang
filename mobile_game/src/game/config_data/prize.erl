%% coding: utf-8
-module(prize).


-include_lib("config/include/config.hrl").
-include_lib("common/include/com_log.hrl").

-include("inc.hrl").
-include("player.hrl").

-export
([
    prize/2, 
    prize_mail/3,
    get_prize/1,
    get_prize_checkcmd/2,
    get_prize_item_tuples/1,
    get_prize_tuples/1, % 获取prize表goods字段的数据
    get_random_prize/1,
    get_random/1,
    is_can_prize/1,
    %get_course_prize/1,
    get_itemlist_by_prizeid/1,
    send_prize_of_itemlist/3,
    is_rd_prize/2,
    prize_mail_2/4,
    double_items/2
]).

-export([
    build_items/1,
    get_item_count_of_type_on_prize_list/2
]).

-type  prize_item() :: {ItemId :: integer(), Count :: pos_integer()} |
{ItemId :: integer(), Count :: pos_integer(), Bind :: pos_integer()} |
{rd_prize, RdPrizeId :: integer(), Count :: pos_integer()} |
{rd_prize, RdPrizeId :: integer(), Count :: pos_integer(), Bind :: pos_integer()}.


-record(prize_cfg, {
    id = 0,    %% 奖励id
    goods = [] %% [item()] | {random, Min, Max, [random_item()]}
    %% item() :: {ItemId :: integer(), Count::integer()} | 默认为绑定
    %%                      {ItemId :: integer(), Count::integer(), Bind::integer()} |
    %%                      {rd_prize, RdPizeId::integer()} 随机奖励物品部分
    %%
    %%     random_item()    {Probo::integer(), ItemId :: integer(), Count::integer()} |  默认为绑定
    %%                      {Probo::integer(), ItemId :: integer(), Count::integer(), Bind::integer()} |
    %%                      {Probo::integer(), rd_prize, RdPizeId::integer()}  随即奖励物品部分
}).

-record(lev_prize_cfg, {
    id = 0,
    lev = 0,
    content = []
}).

-record(rd_prize_cfg, {
    id = 0,
    num = 1,
    random_type = 1,
    career_prize_1 = [],
    career_prize_2 = [],
    career_prize_3 = [],
    career_prize_4 = []
}).

-define(CARRER_ALL, [?C_ZS, ?C_FS, ?C_SS, ?C_QS]).  %% 所有职业列表

get_item_count_of_type_on_prize_list(Type, List) ->
    case lists:keyfind(Type, 1, List) of
        ?false ->
            ?none;
        {_, Count} ->
            Count
    end.

is_can_prize(PrizeId) when is_integer(PrizeId) ->
    case lookup_prize_cfg(PrizeId) of
        ?none ->
            ?false;
        #prize_cfg{goods = GoodsList} ->
            ItemTpL = build_items(GoodsList),
            case game_res:can_give(ItemTpL, nil) of
                {error, _Other} ->
                    ?false;
                _ ->
                    ?true
            end
    end.

%% @spec prize(PrizeId) -> [{ItemBid, Count}] | {error, Reason}
%% @doc  获取奖励
prize(PrizeId, Reason) when is_integer(PrizeId) ->
    case lookup_prize_cfg(PrizeId) of
    ?none ->
        [];
    #prize_cfg{goods=GoodsList} ->
        ItemTpL = build_items(GoodsList),
        case game_res:try_give_ex(ItemTpL, Reason) of
            {error, Other} -> 
                {error, Other};
            _ -> 
                ItemTpL
        end
    end.

%% @spec prize_mail(PrizeId, SysInfo)-> [{ItemBid, Count}] | {error, Reason}
%% 奖励如果背包满，则用邮件发送
%% @doc  获取奖励
prize_mail(PrizeId, SysInfo, Reason) when is_integer(PrizeId) ->
    case lookup_prize_cfg(PrizeId) of
        ?none ->
            case PrizeId of
                0 -> pass;  
                _ -> ?ERROR_LOG("player ~p get prize ~p but can not find", [?pname(), PrizeId])
            end,
            [];
        #prize_cfg{goods = GoodsList} ->
            ItemTpL = build_items(GoodsList),
%%             ?INFO_LOG("prize_mail ~p", [ItemTpL]),
            case game_res:try_give_ex(ItemTpL, SysInfo, Reason) of
                {error, Other} -> {error, Other};
                _ -> ItemTpL
            end
    end.
%% ----------------------------------------------------产出翻倍------------------start
prize_mail_2(ActivityId, PrizeId, SysInfo, Reason) when is_integer(PrizeId) ->
    %?DEBUG_LOG("ActivityId--------------------------:~p",[ActivityId]),
    case lookup_prize_cfg(PrizeId) of
        ?none ->
            [];
        #prize_cfg{goods = GoodsList} ->
            ItemTpL = build_items(GoodsList),
            %?DEBUG_LOG("ItemTpL----------------------:~p",[ItemTpL]),
            NewItemTpl = 
            case double_prize_server:is_double_prize(ActivityId) of
                ?true ->
                    case load_double_prize:get_double_type_and_fanbei(ActivityId) of
                        ?none ->
                            ItemTpL;
                        DoubleList ->
                            %?DEBUG_LOG("DoubleList---------:~p", [DoubleList]),
                            double_items(ItemTpL, DoubleList)
                    end;
                ?false ->
                    ItemTpL
            end,
            %?DEBUG_LOG("NewItemTpl---------------:~p",[NewItemTpl]),
            game_res:try_give_ex(NewItemTpl, SysInfo, Reason),
            NewItemTpl
    end.

double_items(ActivityId, ItemList) when is_integer(ActivityId) ->
    case double_prize_server:is_double_prize(ActivityId) of
        ?true ->
            %?DEBUG_LOG("ActivityId---:~p-----ItemList-----:~p",[ActivityId, ItemList]),
            double_items(ItemList, load_double_prize:get_double_type_and_fanbei(ActivityId));
        ?false ->
            ItemList
    end;
double_items(ItemList, ?none) ->
    ItemList;
double_items(ItemList, DoubleList) ->
    double_items_(ItemList, DoubleList, []).
double_items_([], _, List) ->
    List;
double_items_([H|T], DoubleList, List) ->
    %?DEBUG_LOG("goodsid---------------------:~p",[element(1,H)]),
    NewList =
    case load_item:get_type(element(1, H)) of
        {_, _} ->
            %?DEBUG_LOG("GAN-------------------------"),
            [H|List];
        Type ->
            NewType = min(Type, 100),
            %?DEBUG_LOG("NewType-----:~p-----DoUBLElIST-----:~p",[NewType,DoubleList]),
            case lists:keyfind(NewType, 1, DoubleList) of
                ?false ->
                    [H|List];
                {_, D} ->
                    case H of
                        {A, B, C} ->
                            [{A, trunc(B*D), C}|List];
                        {A, B} ->
                            [{A, trunc(B*D)}|List];
                        _ ->
                            List
                    end
            end
    end,
    double_items_(T, DoubleList, NewList).
%% ----------------------------------------------------产出翻倍------------------end



is_rd_prize(PrizeId, Tag) ->
    case lookup_prize_cfg(PrizeId) of
        ?none ->
            ?true;
        #prize_cfg{goods = GoodsList} ->
            util:is_tag_on_list(GoodsList, Tag)
    end.

get_itemlist_by_prizeid(PrizeId) ->
     case lookup_prize_cfg(PrizeId) of
        ?none ->
            [];
        #prize_cfg{goods = GoodsList} ->
            build_items(GoodsList)
    end.
% get_course_prize(PrizeId) ->
%     case lookup_prize_cfg(PrizeId) of
%         ?none ->
%             ?none;
%         #prize_cfg{goods = GoodsList} ->
%             build_items(lists:nth(1, GoodsList))
%     end.

send_prize_of_itemlist(ItemTpL, SysInfo, Reason) ->
    case game_res:try_give_ex(ItemTpL, SysInfo, Reason) of
        {error, Other} -> {error, Other};
        _ -> ItemTpL
    end.

% send_course_prize(PrizeId, SysInfo) when is_integer(PrizeId) ->
%     case lookup_prize_cfg(PrizeId) of
%         ?none ->
%             [];
%         #prize_cfg{goods = GoodsList} ->
%             ItemTpL = build_items(lists:delete(lists:nth(1,GoodsList), GoodsList)),
%             case game_res:try_give_ex(ItemTpL, SysInfo) of
%                 {error, Other} -> {error, Other};
%                 _ -> ItemTpL
%             end
%     end.

%% @spec get_prize(PrizeId) -> {ok, Assets, ItemL} | {error, Reason}
%% @doc 获取生成物品列表
get_prize(PrizeId) when is_integer(PrizeId) ->
    case lookup_prize_cfg(PrizeId) of
        ?none ->
            ?ERROR_LOG("player ~p get prize ~p but can not find", [?pname(), PrizeId]),
            {ok, []};
        #prize_cfg{goods = GoodsList} ->
            ItemTpL = build_items(GoodsList),
            {ok, ItemTpL}
    end.

%% 获取奖励的物品列表 [{ItemBid, Count}| {ItemBid, Count, Bind}]
get_prize_item_tuples(PrizeId) ->
    case lookup_prize_cfg(PrizeId) of
        ?none ->
            ?ERROR_LOG("player ~p get prize ~p but can not find", [?pname(), PrizeId]),
            [];
        #prize_cfg{goods = GoodsList} ->
            build_items(GoodsList)
    end.

get_prize_tuples(PrizeId) ->
    case lookup_prize_cfg(PrizeId) of
        ?none ->
            ?ERROR_LOG("player ~p get prize ~p but can not find", [?pname(), PrizeId]),
            [];
        #prize_cfg{goods = GoodsList} ->
            GoodsList
    end.

-spec build_items([prize_item()]) -> _.
%% @spec build_items(ItemList) -> [#item{}]
%% @doc 生成物品
build_items({career, CarrerPrizeL}) ->
    case lists:keyfind(get(?pd_career), 1, CarrerPrizeL) of
        {_, CarrerPrize} ->
            build_items(CarrerPrize);
        _E ->
            ?ERROR_LOG("玩家职业id对应的数据错误~w", [_E]),
            []
    end;
build_items({random, Min, Max, RandomGoodList}) ->
    random_items(Min, Max, RandomGoodList);
build_items({lev_prize, LevPrize}) ->
    case lookup_lev_prize_cfg({LevPrize, get(?pd_level)}) of
        #lev_prize_cfg{content = Content} ->
            build_items(Content);
        _ ->
            ?ERROR_LOG("等级奖励错误:~p, ~p", [LevPrize, get(?pd_level)]),
            []
    end;
build_items(ItemList) when is_list(ItemList) ->
    NewItemList = lists:flatten([I || I <- lists:map(fun(Item) -> build_item(Item) end, ItemList)]),
    [I || I <- NewItemList, element(1, I) /= 0 andalso element(2, I) /= 0].

%% @doc 过滤宠物经验值的情况
build_item({?PL_PEARL, _}) -> {0, 1};

%% @doc 过滤宠物默契度的情况
build_item({?PL_PET_TACIT, _}) -> {0, 1};

build_item({rand, ItemId, {Rand1, Rand2}}) ->
    ItemNum = com_util:random(Rand1, Rand2),
    {ItemId, ItemNum};
build_item({ItemId, Count}) when is_integer(ItemId) ->
    {ItemId, Count};
build_item({ItemId, Count, Bind}) when is_integer(ItemId) ->
    {ItemId, Count, Bind};
build_item({rd_prize, RpPrize}) ->
    case lookup_rd_prize_cfg(RpPrize) of
        #rd_prize_cfg{id = Id, num = {I, M}, random_type = Type, career_prize_1 = Prize1, career_prize_2 = Prize2, career_prize_3 = Prize3, career_prize_4 = Prize4} ->
            PrizeList = case get(?pd_career) of
                1 -> Prize1;
                2 -> Prize2;
                3 -> Prize3;
                4 -> Prize4;
                _ -> Prize1
            end,
            case PrizeList of
                [{1000, 0, 0}] ->
                    {0, 1};
                _ ->
                    case Type of
                        1 -> com_util:probo_random(PrizeList, 1000);
                        2 ->
                            case PrizeList of
                                [] ->
                                    {0, 1};
                                _ ->
                                    R = case I =:= M of
                                        true -> I;
                                        _ -> api:random_min_to_max(I, M)
                                    end,
                                    case length(PrizeList) < R of
                                        true ->
                                            ?ERROR_LOG("error, bad prize length, rd_prize_id:~p, prize:~p, num:~p", [Id, PrizeList, R]),
                                            {0, 1};
                                        _ ->
                                            util:get_val_by_weight(PrizeList, R)
                                    end
                            end
                    end
            end;
        _ -> {0, 1}
    end.


%% @spec random_items(Min, Max, RandomGoodList) -> BuildItemArg
%% @doc  创建物品的参数
random_items(Min, Max, RandomGoodList) ->
    {OutItems, DropItems} =
        lists:foldl(fun({RdItem, Probo}, {Out, Drop}) ->
            R = random:uniform(1000),
            if R =< Probo ->
                {[RdItem | Out], Drop};
                true ->
                    {Out, [RdItem | Drop]}
            end
        end,
            {[], []},
            RandomGoodList),
    OL = length(OutItems),
    BL =
        if OL < Min ->
            OutItems + lists:sublist(DropItems, Min - OL);
            OL > Max ->
                com_util:rand_more(OutItems, Max);
            true ->
                OutItems
        end,
    ?debug_log_player("RandL ~w------~w=========~w", [RandomGoodList, OutItems, BL]),
    build_items(BL).

get_prize_checkcmd(CmdId, PrizeId) ->
    ?check(is_exist_prize_cfg(PrizeId), "command[~p] prizeId  ~p 没有找到", [CmdId, PrizeId]).

%% @doc
-spec get_random_prize(PrizeId :: integer()) -> [] | [{ItemBid :: integer(), ItemNum :: integer()}].
get_random_prize(PrizeId) ->
    case lookup_rd_prize_cfg(PrizeId) of
        #rd_prize_cfg{
            random_type = Type,
            num=Num, 
            career_prize_1=Prize1, 
            career_prize_2=Prize2, 
            career_prize_3=Prize3, 
            career_prize_4=Prize4} ->
            PrizeList = case get(?pd_career) of
                1 -> Prize1;
                2 -> Prize2;
                3 -> Prize3;
                4 -> Prize4;
                ?undefined ->
                    ?WARN_LOG( "not find your career, default career id:~p~n", [ 1 ] ),
                    Prize1
            end,
            case PrizeList of
                [{1000, 0, 0}] ->
                    [];
                _ ->
                    case Type of
                        1 -> 
                            [com_util:probo_random(PrizeList, 1000)];
                        2 ->
                            NewPrizeList = [{ItemInfo, {0, Pro}} || {ItemInfo, Pro} <- PrizeList],
                            [ItemInfo || {ItemInfo, _Pro} <- com_util:random_more(Num, NewPrizeList)]
                    end
            end;
        _ -> 
            []
    end.

-spec get_random(PrizeId :: integer()) -> [] | [{ItemBid :: integer(), ItemNum :: integer(), Pro :: integer()}].
get_random(PrizeId) ->
    case lookup_prize_cfg(PrizeId) of
        ?none ->
            ?ERROR_LOG("player ~p get prize ~p but can not find", [?pname(), PrizeId]),
            {error, not_cfg};
        #prize_cfg{goods = GoodsList} ->
            FunMap = fun({Item, ItemNum}) -> {Item, ItemNum, 100};
                ({Item, ItemNum, ItemBind}) -> {Item, ItemNum, ItemBind}
            end,
            lists:map(FunMap, build_items(GoodsList))
    end.

load_config_meta() ->
    [
        #config_meta{
            record = #prize_cfg{},
            fields = record_info(fields, prize_cfg),
            file = "prize.txt",
            keypos = #prize_cfg.id,
            rewrite = fun change_prize/1,
            verify = fun verify/1
        },

        #config_meta{
            record = #rd_prize_cfg{},
            fields = record_info(fields, rd_prize_cfg),
            file = "rd_prize.txt",
            keypos = #rd_prize_cfg.id,
            rewrite = fun change_rand_prize/1,
            verify = fun verify/1
        },

        #config_meta{
            record = #lev_prize_cfg{},
            fields = record_info(fields, lev_prize_cfg),
            file = "lev_prize.txt",
            keypos = [#lev_prize_cfg.id, #lev_prize_cfg.lev],
            verify = fun verify/1
        }
    ].


change_prize(_) ->
    NewCfgList =
    ets:foldl(fun({_, Cfg}, FAcc) ->
        NCfg = do_change_prize(Cfg),
        [NCfg| FAcc]
    end, 
    [],
    prize_cfg),
    NewCfgList.

do_change_prize(#prize_cfg{id = Id, goods = Goods} = PCfg) ->
    NGoods = do_change_prize_1(Id, Goods),
    PCfg#prize_cfg{goods = NGoods}.

do_change_prize_1(Id, {random, Min, Max, RandomIL}) ->
    RandomIL1 = 
    lists:foldr(fun({Per, ItemId, Count}, AccIn) when is_integer(ItemId) ->
                    [{{ItemId, Count}, Per} |AccIn];
                ({Per, ItemId, Count, Bind}, AccIn) when is_integer(ItemId) ->
                    [{{ItemId, Count, Bind}, Per} |AccIn];
                ({Per, rd_prize, RdPrizeId}, AccIn) ->
                    [{{rd_prize, RdPrizeId} , Per}| AccIn]
    end,
    [],
    RandomIL),
    {TR, TRL} = com_util:probo_build(RandomIL1),
    ?check(TR == 1000, "prize.txt [~w] RandomIL 权重和不为1000 ~w", [Id, RandomIL]),
    {random, Min, Max, TRL};
do_change_prize_1(Id, {carrer, CarrerPrizeL})-> 
    {carrer, [{Carrer, do_change_prize_1(Id, CarrerPrize)}||{Carrer, CarrerPrize} <-CarrerPrizeL]};
do_change_prize_1(_Id, Goods)-> 
    Goods.

change_rand_prize(_Arg) ->
    NewCfgList =
        ets:foldl(fun({_, Cfg}, FAcc) ->
            case Cfg#rd_prize_cfg.random_type of
                1 ->
                    Fun = fun(ItemPer) ->
                        ItemPer1 = lists:foldr(
                            fun({Per, ItemId, Count}, Acc) ->
                                [{{ItemId, Count}, Per} | Acc];
                                ({Per, ItemId, Count, Bind}, Acc) ->
                                    [{{ItemId, Count, Bind}, Per} | Acc]
                            end, [], ItemPer),
                        {TP, TItemPers} = com_util:probo_build(ItemPer1),
                        ?check(((TP == 1000) orelse (TItemPers =:= [])), "rand_prize.txt [~w] 物品随机 权重和不为1000 ~w", [Cfg#rd_prize_cfg.id, ItemPer1]),
                        TItemPers
                    end,
                    PrizeCareer1 = Fun(Cfg#rd_prize_cfg.career_prize_1),
                    PrizeCareer2 = Fun(Cfg#rd_prize_cfg.career_prize_2),
                    PrizeCareer3 = Fun(Cfg#rd_prize_cfg.career_prize_3),
                    PrizeCareer4 = Fun(Cfg#rd_prize_cfg.career_prize_4),
                    [Cfg#rd_prize_cfg{career_prize_1 = PrizeCareer1, career_prize_2 = PrizeCareer2, career_prize_3 = PrizeCareer3, career_prize_4 = PrizeCareer4} | FAcc];
                2 ->
                    Fun = fun(ItemPer) ->
                        ItemPer1 = lists:foldr
                        (
                            fun
                                ({Per, ItemId, Count}, Acc) -> [{{ItemId, Count}, Per} | Acc];
                                ({Per, ItemId, Count, Bind}, Acc) -> [{{ItemId, Count, Bind}, Per} | Acc]
                            end,
                            [],
                            ItemPer
                        ),
                        {_TP, TItemPers} = com_util:probo_build(ItemPer1),
                        TItemPers
                    end,
                    PrizeCareer1 = Fun(Cfg#rd_prize_cfg.career_prize_1),
                    PrizeCareer2 = Fun(Cfg#rd_prize_cfg.career_prize_2),
                    PrizeCareer3 = Fun(Cfg#rd_prize_cfg.career_prize_3),
                    PrizeCareer4 = Fun(Cfg#rd_prize_cfg.career_prize_4),
                    [Cfg#rd_prize_cfg{career_prize_1 = PrizeCareer1, career_prize_2 = PrizeCareer2, career_prize_3 = PrizeCareer3, career_prize_4 = PrizeCareer4} | FAcc]
            end
        end, [], rd_prize_cfg),
    NewCfgList.


check_probo(Id, Probo) ->
    ?check(com_util:is_valid_uint_max(Probo, 1000), "prize.txt [~p] 无效出现概率 ~p 必须>=0 =<1000", [Id, Probo]).

check_goods(Id, {career, CarrerPrizeL}) when is_list(CarrerPrizeL) ->
    CL = lists:foldl(fun({Carrer, Goods}, AccIn) ->
        check_goods({Id, Carrer}, Goods),
        lists:delete(Carrer, AccIn)
    end, ?CARRER_ALL, CarrerPrizeL),
    ?check(CL =:= [], "prize.txt [~w] 职业~w没有配置", [Id, CL]);


check_goods(Id, {random, Min, Max, RandomGoodList}) when is_list(RandomGoodList) ->
    RL = length(RandomGoodList),
    ?check(Min =< RL andalso Max =< RL andalso Min =< Max, "prize.txt [~w] 无效随机数量 ~w ~w ~w", [Id, Min, Max, RL]),
    lists:foreach(fun({{ItemId, Count}, Probo}) when is_integer(ItemId) ->
        check_probo(Id, Probo),
        ?check(load_item:check_normal_item(ItemId), "prize.txt [~w] 中包含的奖励物品[~w]不存在", [Id, ItemId]),
        ?check(com_util:is_valid_uint64(Count), "prize.txt [~w] 中包含的奖励物品数量[~w]无效", [Id, Count]);
        ({{ItemId, Count, Bind}, Probo}) when is_integer(ItemId) ->
            check_probo(Id, Probo),
            ?check(load_item:check_normal_item(ItemId), "prize.txt [~w] 中包含的奖励物品[~w]不存在", [Id, ItemId]),
            ?check(com_util:is_valid_uint64(Count), "prize.txt [~w] 中包含的奖励物品数量[~w]无效", [Id, Count]),
            ?check(com_util:is_valid_cli_bool(Bind), "prize.txt [~w] 中包含的奖励物品绑定属性[~w]无效", [Id, Bind]);
        ({{rd_prize, RdPrize}, Probo}) ->
            check_probo(Id, Probo),
            ?check(prize:is_exist_rd_prize_cfg(RdPrize), "prize.txt [~w] 中包含的随即奖励id[~w]不存在", [Id, RdPrize])
    end, RandomGoodList);

check_goods(_Id, {lev_prize, _LevPrize}) ->
    ok;

check_goods(Id, GoodsList) when is_list(GoodsList) ->
    lists:foreach(fun({ItemId, Count}) when is_integer(ItemId) ->
        ?check(load_item:check_normal_item(ItemId), "prize.txt [~w] 中包含的奖励物品[~w]不存在", [Id, ItemId]),
        ?check(com_util:is_valid_uint64(Count), "prize.txt [~w] 中包含的奖励物品数量[~w]无效", [Id, Count]);
        ({ItemId, Count, Bind}) when is_integer(ItemId) ->
            ?check(load_item:check_normal_item(ItemId), "prize.txt [~w] 中包含的奖励物品[~w]不存在", [Id, ItemId]),
            ?check(com_util:is_valid_uint64(Count), "prize.txt [~w] 中包含的奖励物品数量[~w]无效", [Id, Count]),
            ?check(com_util:is_valid_cli_bool(Bind), "prize.txt [~w] 中包含的奖励物品绑定属性[~w]无效", [Id, Bind]);
        ({rd_prize, RdPrize}) ->
            ?check(prize:is_exist_rd_prize_cfg(RdPrize), "prize.txt [~w] 中包含的随即奖励id[~w]不存在", [Id, RdPrize])
    end, GoodsList).
verify(#prize_cfg{id = Id, goods = Goods}) ->
    check_goods(Id, Goods);

verify(#rd_prize_cfg{id = Id, random_type = Type, career_prize_1 = ItemPer1, career_prize_2 = ItemPer2, career_prize_3 = ItemPer3, career_prize_4 = ItemPer4}) ->
    ?check(Type =:= 1 orelse Type =:= 2, "rd_prize.txt [~w] 中随机类型[~w]不存在", [Id, Type]),
    Fun = fun(ItemPer) ->
        lists:foreach(fun({{ItemId, Count}, _Per}) ->
            ?check(load_item:check_normal_item(ItemId) orelse ItemId =:= 0, "rd_prize.txt [~w] 中包含的奖励物品[~w]不存在", [Id, ItemId]),
            ?check(com_util:is_valid_uint64(Count), "rd_prize.txt [~w] 中包含的奖励物品数量[~w]无效", [Id, Count]),
%%                     ?check(com_util:is_valid_uint_max(Per, 1000), "rd_prize.txt [~w] 无效出现概率 ~w 必须>=0 =<1000", [Id, Per]),
            ok;
            ({{ItemId, Count, Bind}, _Per}) ->
                ?check(load_item:check_normal_item(ItemId) orelse ItemId =:= 0, "rd_prize.txt [~w] 中包含的奖励物品[~w]不存在", [Id, ItemId]),
                ?check(com_util:is_valid_uint64(Count), "rd_prize.txt [~w] 中包含的奖励物品数量[~w]无效", [Id, Count]),
                ?check(com_util:is_valid_cli_bool(Bind), "rd_prize.txt [~w] 中包含的奖励物品绑定属性[~w]无效", [Id, Bind]),
%%                     ?check(com_util:is_valid_uint_max(Per, 1000), "rd_prize.txt [~p] 无效出现概率 ~p 必须>=0 =<1000", [Id, Per]),
                ok
        end, ItemPer)
    end,
    Fun(ItemPer1),
    Fun(ItemPer2),
    Fun(ItemPer3),
    Fun(ItemPer4),
    ok;

verify(#lev_prize_cfg{}) ->
    ok;

verify(_R) ->
    ?ERROR_LOG("prize 配置　~p 错误格式", [_R]),
    exit(bad).



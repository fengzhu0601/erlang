%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%% 用于外围查询的杂项接口(是否写到这里面的标准就是这里面的接口删了也不会影响游戏业务的进行)
%%% @end
%%% Created : 16. 十一月 2015 下午8:49
%%%-------------------------------------------------------------------
-module(api).
-author("lan").

%% API
-export
([
    gem_num_full/0
    ,same_suit/0
    ,newbie_equip_open/0
    ,newbie_equip_close/0
    ,get_suit_equip_infos/1                 %%获得身上套装的ID,等级,个数
    ,get_suit_equip_list/0
    ,get_suit_equip_lists/1
    ,get_suit_equip_list_by_id/2
    ,get_suit_num/1
    ,getMax/2
    ,getMin/2
    ,is_take_equip/0
    ,is_first_arena/0
    ,mail_full_alarm/0                      %%邮箱容量报警
    ,player_is_in_normalRoom/1              %根据玩家ID是否在城镇
    ,player_is_in_arenaScene/1
    ,get_equip_change_list/1                %%获取装备 特效修改集
    ,get_efts_list/1
    ,player_is_Vip/0                        %% 判断玩家是否为VIP玩家
    ,random_min_to_max/2
    ,send_color_equip_count/0
    ,get_equip_qhlvl_count/0
    ,record_he_cheng_attr_begin/1
    ,record_he_cheng_attr_end/1
    ,send_he_cheng_equip_count/0
    ,get_friends_count/0
    ,get_card_boss_quality_count/0
    ,get_bag_page_count/0
    ,get_player_suit_info/0
    ,is_suit/1
    ,get_player_item_count/1
    ,sync_phase_prize_data/0
    ,get_suitid_list/0
    ,get_bag_grid_num/0
    ,get_depot_grid_num/0
    ,get_suit_count/0
]).

%% 用于开服狂欢的装备接口
-export([
    get_a_suit_count/0
    ,get_color_equip_count/1
    ,get_equip_qianghua_level_count/1
]).

-include("inc.hrl").
-include("item_bucket.hrl").
%% -include("bucket_interface.hrl").
-include("item.hrl").
-include("player.hrl").
-include("load_item.hrl").
-include("player_data_db.hrl").
-include("friend_struct.hrl").
-include("load_phase_ac.hrl").
-include("equip.hrl").
-include("rank.hrl").

-define(MAIL_MAX_SIZE, 20). %% 邮件最大容量
-define(pd_record_he_cheng_attr, pd_record_he_cheng_attr).  %% 记录装备合成时的前后属性
-define(pd_hecheng_color_equip, pd_hecheng_color_equip).


%% %
%% handle_msg(_FromMod, {?pd_close_server_time_over}) -> on_time();
%% handle_msg(_FromMod, _Msg) -> ok.

%% view_data(Acc) -> Acc.
%% online() -> ok.
%% handle_frame(_Frame) -> ok.

%%判断装备的宝石是否已满
gem_num_full() ->
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    GoodsList = goods_bucket:get_goods(BagBucket),
    Ret =
        lists:foldl
        (
            fun(#item_new{} = Item, Acc) ->
                case Acc of
                    ?FALSE ->
                        ?FALSE;
                    _ ->
                        Num = item_equip:get_gem_cur_size(Item),
%%                        ?INFO_LOG("Num = ~p", [Num]),
                        MiscList = item_new:get_field(Item, ?item_use_data),
                        GemRet =
                            case lists:keyfind(?item_equip_epic_gem, 1, MiscList) of
                                {_Key, GemId} when GemId =/= 0 andalso GemId =/= 1 ->
                                    true;
                                _ ->
                                    false
                            end,
                        if
                            Num >= 5 andalso GemRet ->
                                ?TRUE;
                            true ->
                                ?FALSE
                        end
                end
            end,
            ?TRUE,
            GoodsList
        ),
    case length(GoodsList) == 0 of
        true ->
            ?FALSE;
        _ ->
            Ret
    end.

%% 套装之神判断
same_suit() ->
    EqmBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    SuitList = goods_bucket:get_goods(EqmBucket),
    Ret = lists:foldl
    (
        fun(#item_new{} = Item, {Acc,Count}) ->
            SuitID = item_new:get_field(Item, ?item_equip_suit_id),
            if
                SuitID =:= 0 ->
                    {Acc, Count};
                -1 == Acc ->
                    {SuitID, Count+1};
                true ->
                    if
                        SuitID == Acc andalso SuitID =/= 0 ->
                            {Acc, Count+1};
                        true ->
                            {-2, Count}
                    end
            end
        end,
        {-1,0},
        SuitList
    ),
    {R, C} = Ret,
    if
        R >= 0 andalso C == 6 -> ?TRUE;
        true -> ?FALSE
    end.

%%新手装备、特效、属性引导
newbie_equip_open() ->
    Career = get(?pd_career),
    EffList = load_equip_change:get_effList(Career),
    EquipList = load_equip_change:get_equipList(Career),
    CfgId = load_equip_change:get_attrId(Career),
    Attr1 = case load_spirit_attr:lookup_attr(CfgId) of
        ?none ->
            ?err(none_cfg);
        Attr ->
            Attr
    end,
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_EFFECT_CHANGE, {EffList})),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ATTR_CHANGE, {?r2t(Attr1)})),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_AVATAR_CHANGE, {Career,EquipList})).

%%新手装备、特效、属性引导完毕
newbie_equip_close() ->
    EffList = [0,0],
    EquipList = [0,0,0,0,0,0,0,0,0,0],
    Career = get(?pd_career),
    PlayerAttr = attr_new:get_oldversion_attr(),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_EFFECT_CHANGE, {EffList})),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ATTR_CHANGE, {?r2t(PlayerAttr)})),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_AVATAR_CHANGE, {Career, EquipList})).


%%
getMax(A,B) ->
    if
        A > B -> A;
        true -> B
    end.
getMin(A,B) ->
    if
        A > B -> B;
        true -> A
    end.

%%获取套装list
get_suit_equip_list() ->
    SuitEquip =
        fun
            (_ThisFun, [], ResultList) -> ResultList;
            (ThisFun, [Equip | TailList],ResultList) ->
                SuitId = item_new:get_field(Equip, ?item_equip_suit_id),
                % ?INFO_LOG("SuitId,       ~p", [SuitId]),
                if
                    SuitId == 0 -> false ; %% 0 is no suit
                    true ->
                        [Equip | ResultList]
                end,
                ThisFun(ThisFun, TailList, [Equip | ResultList])
        end,
    EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    EquipList = goods_bucket:get_goods(EquipBucket),
    SuitEquip(SuitEquip, EquipList, []).

%%
get_suit_equip_lists(SuitList) ->
    SuitList1 = [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1001],
    SuitList2 = [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1002],
    SuitList3 = [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1003],
    SuitList4 = [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1004],
    SuitList5 = [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1005],
    SuitList6 = [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1006],
    SuitList7 = [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1007],
    SuitList8 = [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1008],
    SuitList9 = [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1009],
    SuitList10= [X || X <- SuitList,item_new:get_field(X, ?item_equip_suit_id) == 1010],
	  [SuitList1,SuitList2,SuitList3,SuitList4,SuitList5,SuitList6,SuitList7,SuitList8,SuitList9,SuitList10].

%%得到某一套套装列表
get_suit_equip_list_by_id(List,Id) ->
    _SuitList = [X || X <- List,item_new:get_field(X, ?item_equip_suit_id) == Id].


%%获得套装Id，套装有效个数，套装等级
get_suit_equip_infos(SuitList) ->
    %%?INFO_LOG("get_suit_equip_infos....."),
    %%?INFO_LOG("get_suit_equip_infos....."),
    %%?INFO_LOG("SuitList,       ~p", [SuitList]),
	%%  {1001,2,10}.
    _Ret = lists:foldl
    (
        fun(#item_new{} = Item, {Acc, Lev, Count}) ->
            SuitID = item_new:get_field(Item, ?item_equip_suit_id), %%获取装备的套装ID
            %%SuitLV = item_new:get_field(Item, ?item_equip_qianghua_lev),%%获取装备的套装等级Lv
            %%Bid = item_new:get_bid(Item),
            %%Cfg = load_item:get_item_cfg(Bid),
            %%SuitLV = Cfg#item_attr_cfg.lev,
            #item_attr_cfg{lev = SuitLV} = load_item:get_item_cfg(Item#item_new.bid),%%bid获取装备的套装等级Lv
            if
                -1 == Acc ->
                    % ?INFO_LOG("LV   ~p", [SuitLV]),
                    {SuitID, getMax(Lev,SuitLV),Count + 1};
                true ->
                    if
                        SuitID == Acc ->
                            {SuitID, getMax(Lev,SuitLV),Count + 1};
                        true ->
                            {SuitID, Lev, Count}
                    end
            end
        end,
        {-1,1,0},
        SuitList
    ).

get_suit_num(Ret) ->
    {R,L,C} = Ret,
    %%SuitCount = ?suit_num(C),
    SuitCount = if
                    C >= 6 -> 6;
                    C >= 4 -> 4;
                    C >= 2 -> 2;
                    true -> 0
                end,
    {R,L,SuitCount}.

%%判断玩家是没穿装备
is_take_equip() ->
    EqmBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    EquipList = goods_bucket:get_goods(EqmBucket),
    case erlang:length(EquipList) of
        0 -> true;
        _ -> false
    end.

%是否为首次竞技
is_first_arena() ->
    IS = attr_new:get(?pd_is_first_arena),
    ?INFO_LOG("is_first_arena ~p",[IS]),
    attr_new:get(?pd_is_first_arena, 0).

%邮箱容量报警
mail_full_alarm() ->
    Size = gb_trees:size(get(?pd_mail_mng)),
    if
        Size > ?MAIL_MAX_SIZE ->
            player_log_service:add_crash_log(get(?pd_id), get(?pd_name), ?mail_full);
        true ->
            ?INFO_LOG("mail max size ~p",[?MAIL_MAX_SIZE]),
            ?INFO_LOG("mail current size ~p",[Size]),
            ok
    end.

%根据玩家ID判断他是否在城镇
player_is_in_normalRoom(PlayerId) ->
    SceneId = scene_mng:lookup_player_scene_id_if_online(PlayerId),
    SceneType = load_cfg_scene:get_scene_type(SceneId),
    ?if_else(SceneType =:= ?SC_TYPE_NORMAL, ?TRUE, ?FALSE).

player_is_in_arenaScene(PlayerId) ->
    SceneId = scene_mng:lookup_player_scene_id_if_online(PlayerId),
    SceneType = load_cfg_scene:get_scene_type(SceneId),
    ?if_else(SceneType =:= ?SC_TYPE_ARENA, ?TRUE, ?FALSE).

%% 玩家登录时获取装备列表
get_equip_change_list(PlayerId) ->
    RetList = case player:lookup_info(PlayerId, ?pd_equip) of
        EquipList when is_list(EquipList) ->
            lists:foldl
            (
                fun({_,Bid,_,_,_,_,_,_,_,_,List,_,_,_,_,_,_,_}, Acc) ->
                    case is_list(List) of
                        true ->
                            [Bid] ++ Acc;
                        _ ->
                            Acc
                    end
                end,
                [],
                EquipList
            );
        _ ->
            []
    end,
    ListNum = length(RetList),
    RetList ++ lists:duplicate(10 - ListNum, 0).

%% 玩家登录时获取特效列表
get_efts_list(PlayerId) ->
    EftsList = case dbcache:lookup(?player_data_tab, PlayerId) of
        [#player_data_tab{field_data = FieldData}] ->
            case lists:keyfind(?pd_player_efts_list, 1, FieldData) of
                {?pd_player_efts_list, List} ->
                    List;
                _ ->
                    []
            end;
        _ ->
            []
    end,
    EftsList1 = case is_list(EftsList) of
        true ->
            lists:foldl(
                fun
                    ({_Id, EftList}, Acc) ->
                        EftList ++ Acc;
                    (_, Acc) ->
                        Acc
                end,
                [],
                EftsList
            );
        _ ->
            []
    end,
    EftsList2 = lists:foldl(
        fun
            ({_Bid, EftList}, Acc) ->
                EftList ++ Acc;
            (_, Acc) ->
                Acc
        end,
        [],
        EftsList1
    ),

    Role = case player:lookup_info(PlayerId, [?pd_career]) of
        [R] ->
            R;
        _ ->
            0
    end,
    %% 获取强化特效
    EftsList3 = case dbcache:load_data(?player_equip_goods_tab, PlayerId) of
         [#player_equip_goods_tab{qianghu_list = QHList}] ->
             QHLevel = util:get_field(QHList, 10, 0),
             case load_equip_expand:get_part_qianghua_effect(Role, 10, QHLevel) of
                 EFList when is_list(EFList) ->
                     EFList;
                 _ ->
                     []
             end;
         _ ->
             []
     end,
    EftsList3 ++ EftsList2.

%% 判断玩家是否为VIP玩家
player_is_Vip() ->
    Vip = attr_new:get_vip_lvl(),
    if
        Vip =:= 0 ->
            ?false;
        true ->
            ?true
    end.




%% 随机一个Min到Max的数
random_min_to_max(Min, Max) ->
    Value = Max - Min + 1,
    Result = random:uniform(Value),
    Result + Min - 1.

%% 发送玩家穿戴相应颜色的装备件数
send_color_equip_count() ->
    phase_achievement_mng:do_pc(?PHASE_AC_ADD_BLUE_EQUIP, ?equip_blue, get_color_equip_count(?equip_blue)),
    phase_achievement_mng:do_pc(?PHASE_AC_ADD_ZISE_EQUIP, ?equip_purple, get_color_equip_count(?equip_purple)),
    phase_achievement_mng:do_pc(?PHASE_AC_ADD_CHENGSE_EQUIP, ?equip_orange, get_color_equip_count(?equip_orange)),
    phase_achievement_mng:do_pc(?PHASE_AC_ADD_LVSE_EQUIP, ?equip_green, get_suit_count()).

%% 获取玩家穿在身上某一品质（颜色）的装备数量
get_color_equip_count(EquipColor) ->
    EqmBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    EquipList = goods_bucket:get_goods(EqmBucket),
    EqmQlyL = misc_cfg:get_equip_qualily(),
    Count =
        lists:foldl
        (
            fun(#item_new{field = List}, Acc) ->
                case lists:keyfind(?item_equip_extra_prop_list, 1, List) of
                    {_, AttrExtraList} ->
                        case lists:keyfind(?EQM_ATTR_JD,1,AttrExtraList) of
                            {_, List1} ->
                                case lists:keyfind(length(List1), 2, EqmQlyL) of
                                    {Id, _} ->
                                        if
                                            Id =:= EquipColor -> Acc+1;
                                            true -> Acc
                                        end;
                                    _ ->
                                        Acc
                                end;
                            _ ->
                                Acc
                        end;
                    _ ->
                        Acc
                end
            end,
            0,
            EquipList
        ),
    Count.

get_suit_count() ->
    EqmBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    SuitList = goods_bucket:get_goods(EqmBucket),
    RetList = lists:filter
    (
        fun(#item_new{} = Item) ->
            SuitId = item_new:get_field(Item, ?item_equip_suit_id),
            SuitId =/=0
        end,
        SuitList
    ),
    length(RetList).

%% 获取玩家拥有一整套套装的数量
get_a_suit_count() ->
    EqmBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    Count1 =
        case EqmBucket of
            ?undefined ->               %% 當新玩家註冊賬號時裝備的數據庫還沒有創建
                0;
            _ ->
                SuitList = goods_bucket:get_goods(EqmBucket),

                %% 得到背包中的物品列表
                BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
                BagEquipList = goods_bucket:get_goods(BagBucket),

                %% 获取仓库中的物品列表
                DeBucket = game_res:get_bucket(?BUCKET_TYPE_DEPOT),
                DeEquipList = goods_bucket:get_goods(DeBucket),

                SuitIdCountList =
                    lists:foldl
                    (
                        fun(#item_new{type = Type} = Item, AccList) ->
                            SuitId = item_new:get_field(Item, ?item_equip_suit_id),
                            case SuitId =/= 0 of
                                true ->
                                    case lists:keyfind(SuitId, 1, AccList) of
                                        {_SuitId, PList} ->
                                            case lists:member(Type, PList) of
                                                true ->
                                                    AccList;
                                                _ ->
                                                    lists:keyreplace(SuitId, 1, AccList, {SuitId, [Type | PList]})
                                            end;
                                        _ ->
                                            [{SuitId, [Type]} | AccList]
                                    end;
                                _ ->
                                    AccList
                            end
                        end,
                        [],
                        SuitList ++ BagEquipList ++ DeEquipList
                    ),
                length(lists:filter(fun({_, TypeList}) -> erlang:length(TypeList) >= 6 end, SuitIdCountList))
        end,
    ?INFO_LOG("Count = ~p", [Count1]),
    Count1.



%% 获取背包或仓库中等级大于10级的装备个数
get_equip_qhlvl_count() ->
    %% 获取玩家已经装备的物品列表
    EqmBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    EqmEquipList = goods_bucket:get_goods(EqmBucket),

    %% 得到背包中的物品列表
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    BagEquipList = goods_bucket:get_goods(BagBucket),

    %% 获取仓库中的物品列表
    DeBucket = game_res:get_bucket(?BUCKET_TYPE_DEPOT),
    DeEquipList = goods_bucket:get_goods(DeBucket),

    Count =
        lists:foldl
        (
            fun(#item_new{field = List}, Acc) ->
                case lists:keyfind(?item_equip_qianghua_lev, 1, List) of
                    {_, Lvl} ->
                        if
                            Lvl >= 10 -> Acc+1;
                            true -> Acc
                        end ;
                    _ ->
                        Acc
                end
            end,
            0,
            EqmEquipList ++ BagEquipList ++ DeEquipList
        ),
    Count.

record_he_cheng_attr_begin(EquipItem) ->
    put(?pd_record_he_cheng_attr, EquipItem).

record_he_cheng_attr_end(EquipItem) ->
    OldItem = attr_new:get(?pd_record_he_cheng_attr, EquipItem),
    AttrList1 = OldItem#item_new.field,
    AttrList2 = EquipItem#item_new.field,
    record_he_cheng_attr(AttrList1, AttrList2, ?equip_blue),
    record_he_cheng_attr(AttrList1, AttrList2, ?equip_purple),
    record_he_cheng_attr(AttrList1, AttrList2, ?equip_orange).

record_he_cheng_attr(OldAttrList, NewAttrList, EquipColor) ->
    EqmQlyL = misc_cfg:get_equip_qualily(),

    %% 判断合成之前主装备是否时紫色装备
    Ret1 =
        case lists:keyfind(?item_equip_extra_prop_list, 1, OldAttrList) of
            {_, AttrExtraList1} ->
                case lists:keyfind(?EQM_ATTR_JD, 1, AttrExtraList1) of
                    {_, List1} ->
                        case lists:keyfind(length(List1), 2, EqmQlyL) of
                            {Id1, _} ->
                                if
                                    Id1 < EquipColor -> ?true;
                                    true -> ?false
                                end;
                            _ ->
                                ?false
                        end;
                    _ ->
                        ?false
                end;
            _ ->
                ?false
        end,

    %% 判断合成之后主装备是否时紫色装备
    Ret2 =
        case lists:keyfind(?item_equip_extra_prop_list, 1, NewAttrList) of
            {_, AttrExtraList2} ->
                case lists:keyfind(?EQM_ATTR_JD, 1, AttrExtraList2) of
                    {_, List2} ->
                        case lists:keyfind(length(List2), 2, EqmQlyL) of
                            {Id2, _} ->
                                if
                                    Id2 =:= EquipColor -> ?true;
                                    true -> ?false
                                end;
                            _ ->
                                ?false
                        end;
                    _ ->
                        ?false
                end;
            _ ->
                ?false
        end,

    case Ret1 =:= ?true andalso Ret2 =:= ?true of      %% 判断合成之前为非紫色，合成之后为紫色
        true ->
            List = attr_new:get(?pd_hecheng_color_equip, []),
            put(?pd_hecheng_color_equip, [EquipColor|List]);
        _ ->
            pass
    end.

send_he_cheng_equip_count() ->
    case attr_new:get(?pd_hecheng_color_equip, []) of
        List when is_list(List) ->
            lists:foreach
            (
                fun(Colour) ->
                    ?INFO_LOG("send_he_cheng_equip_count ~p", [Colour]),
                    if
                        Colour =:= ?equip_blue ->
                            phase_achievement_mng:do_pc(?PHASE_AC_EQUIP_HECHENG_BLUE, 1);
                        Colour =:= ?equip_purple ->
                            phase_achievement_mng:do_pc(?PHASE_AC_EQUIP_HECHENG_ZISE, 1);
                        Colour =:= ?equip_orange ->
                            phase_achievement_mng:do_pc(?PHASE_AC_EQUIP_HECHENG_CHENGSE, 1);
                        true ->
                            pass
                    end
                end,
            List
            ),
            put(?pd_hecheng_color_equip, []);
        _ ->
            pass
    end.


%% 获取好友的数量
get_friends_count() ->
    PlayerId = get(?pd_id),
    case friend_mng:lookup_fp(PlayerId) of
        #friend_private{friend_ids = List} ->
            erlang:length(List);
        _ ->
            0
    end.

%% 获取不同品质的卡牌数量
get_card_boss_quality_count() ->

    %% 获取背包中的物品列表
    BagEqmBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    BagItemList = goods_bucket:get_goods(BagEqmBucket),
    %% 获取仓库中的物品列表
    DeEqmBucket = game_res:get_bucket(?BUCKET_TYPE_DEPOT),
    DeItemList = goods_bucket:get_goods(DeEqmBucket),

    AllItemList = BagItemList ++ DeItemList,

    CardBidList =
        lists:foldl
        (
            fun(#item_new{bid = Bid, type = Type}, Acc) ->
                case Type =:= ?val_item_type_card of
                    true ->
                        case lists:keyfind(Bid, 1, Acc) of
                            false ->
                                Class = load_cfg_card:get_item_card_attr_cfg_class(Bid),
                                [{Bid,Class}|Acc];
                            _ ->
                                Acc
                        end;
                    _ ->
                        Acc
                end
            end,
            [],
            AllItemList
        ),

    ClassList = lists:map(fun(Bid) -> load_cfg_card:get_item_card_attr_cfg_class(Bid) end, load_cfg_card:get_all_card_id()),
    ClassList1 = lists:usort(ClassList),

    Count =
        lists:foldl
        (
            fun(Class, Acc) ->
                List = lists:filter(fun({_Bid, Class1}) -> Class =:= Class1 end, CardBidList),
                case length(List) >= 4 of
                    true -> Acc+1;
                    _ -> Acc
                end
            end,
            0,
            ClassList1
        ),
    Count.



%% 获取背包的页数
get_bag_page_count() ->
    Bucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    TotalSize = goods_bucket:get_field(Bucket, ?goods_bucket_size, 0),
    TotalSize div ?bucket_page_size.

%% 获取背包的格子数
get_bag_grid_num() ->
    Bucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    TotalSize = goods_bucket:get_field(Bucket, ?goods_bucket_size, 0),
    TotalSize.

%% 获取仓库的格子数
get_depot_grid_num() ->
    Bucket = game_res:get_bucket(?BUCKET_TYPE_DEPOT),
    TotalSize = goods_bucket:get_field(Bucket, ?goods_bucket_size, 0),
    TotalSize.

%% 获取玩家套装信息（包括背包，仓库，身上）
get_player_suit_info() ->
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    DepotBucket = game_res:get_bucket(?BUCKET_TYPE_DEPOT),
    EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    SuitList = lists:foldl(
        fun(Equip, RetList) ->
                SuitId = item_new:get_field(Equip, ?item_equip_suit_id),
                case SuitId =/= 0 of
                    true ->
                        [Equip | RetList];
                    _ ->
                        RetList
                end
        end,
        [],
        goods_bucket:get_goods(BagBucket) ++ goods_bucket:get_goods(DepotBucket) ++ goods_bucket:get_goods(EquipBucket)
    ),
    SuitList1 = get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1001, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    SuitList2 = get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1002, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    SuitList3 = get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1003, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    SuitList4 = get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1004, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    SuitList5 = get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1005, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    SuitList6 = get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1006, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    SuitList7 = get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1007, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    SuitList8 = get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1008, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    SuitList9 = get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1009, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    SuitList10= get_unique_bid([X#item_new.bid || X <- SuitList, item_new:get_field(X, ?item_equip_suit_id) == 1010, load_equip_expand:get_equip_cfg_level(X#item_new.bid) == 30]),
    [
        list_to_tuple(SuitList1), list_to_tuple(SuitList2), list_to_tuple(SuitList3), list_to_tuple(SuitList4), list_to_tuple(SuitList5),
        list_to_tuple(SuitList6), list_to_tuple(SuitList7), list_to_tuple(SuitList8), list_to_tuple(SuitList9), list_to_tuple(SuitList10)
    ].

get_unique_bid(List) ->
    lists:foldl(
        fun(Bid, TeamList) ->
                case lists:member(Bid, TeamList) of
                    true ->
                        TeamList;
                    _ ->
                        [Bid | TeamList]
                end
        end,
        [],
        List
    ).

%% 判断装备是否是套装
is_suit(Item) ->
    case is_record(Item, item_new) of
        true ->
            case lists:keyfind(?item_equip_quality, 1, Item#item_new.field) of
                {_, Quality} ->
                    case Quality =:= ?suit_quality of
                        true -> ?true;
                        _ -> ?false
                    end;
                _ ->
                    ?false
            end;
        _ ->
            ?false
    end.

%% 获取某一种物品的数量
get_player_item_count(Bid) ->
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    DepotBucket = game_res:get_bucket(?BUCKET_TYPE_DEPOT),
    EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    lists:foldl(
        fun(Item, Num) ->
                case Item#item_new.bid =:= Bid of
                    true ->
                        Item#item_new.quantity + Num;
                    _ ->
                        Num
                end
        end,
        0,
        goods_bucket:get_goods(BagBucket) ++ goods_bucket:get_goods(DepotBucket) ++ goods_bucket:get_goods(EquipBucket)
    ).

%% 同步阶段奖励的数据（用于党背包内的数据发生变化的时候）
sync_phase_prize_data() ->
    phase_achievement_mng:do_pc(?PHASE_AC_KAPAI_BOSS_QUALITY_KA, 10000, get_card_boss_quality_count()),
    phase_achievement_mng:do_pc(?PHASE_AC_EQUIP_QIANGHUA, 10, api:get_equip_qhlvl_count()).

get_suitid_list() ->
    BagBucket = game_res:get_bucket(?BUCKET_TYPE_BAG),
    DepotBucket = game_res:get_bucket(?BUCKET_TYPE_DEPOT),
    EquipBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    SuitList = lists:foldl(
        fun(Equip, RetList) ->
                SuitId = item_new:get_field(Equip, ?item_equip_suit_id),
                case SuitId =/= 0 of
                    true ->
                        [Equip | RetList];
                    _ ->
                        RetList
                end
        end,
        [],
        goods_bucket:get_goods(BagBucket) ++ goods_bucket:get_goods(DepotBucket) ++ goods_bucket:get_goods(EquipBucket)
    ),
    lists:foldl(
        fun(X, RetList) ->
                case item_new:get_field(X, ?item_equip_suit_id) of
                    0 ->
                        RetList;
                    SuitId ->
                        Level = load_equip_expand:get_equip_cfg_level(X#item_new.bid),
                        case lists:keyfind({SuitId, Level}, 1, RetList) of
                            {{SuitId, Level}, List} ->
                                case lists:member(X#item_new.bid, List) of
                                    true ->
                                        RetList;
                                    _ ->
                                        lists:keyreplace({SuitId, Level}, 1, RetList, {{SuitId, Level}, [X#item_new.bid | List]})
                                end;
                            _ ->
                                [{{SuitId, Level}, [X#item_new.bid]} | RetList]
                        end
                end
        end,
        [],
        SuitList
    ).

%% 获取已经穿上的装备满足强化等级的数量
get_equip_qianghua_level_count(QHLevel) ->
    EqmBucket = game_res:get_bucket(?BUCKET_TYPE_EQM),
    EquipList = goods_bucket:get_goods(EqmBucket),

    Count =
        lists:foldl
        (
            fun(#item_new{} = Item, AccCount) ->
                QHLvl = item_new:get_field(Item, ?item_equip_qianghua_lev, 0),
                case QHLvl >= QHLevel of
                    true -> AccCount + 1;
                    _ -> AccCount
                end
            end,
            0,
            EquipList
        ),
    Count.



%%% @author zl
%%% @doc 用户进程
%%%
%%% @end
%%%-------------------------------------------------------------------

%% TODO link scene scene crash

-module(player).


-include("inc.hrl").
-include("player.hrl").
-include("scene.hrl").
-include("player_data_db.hrl").
-include("load_spirit_attr.hrl").
-include("item_bucket.hrl").
-include("load_career_attr.hrl").
-include("achievement.hrl").
-include("load_phase_ac.hrl").
-include("system_log.hrl").
-include("../../wk_open_server_happy/open_server_happy.hrl").

%% 查询玩家基本信息, for all process
-export([
    lookup_info/2,
    lookup_info/3,
    lookup_view_data/1,
    lookup_misc/2,
    lookup_misc/3
]).

%% 只能角色进程自己调用
-export(
[
    init_misc/1,
    set_misc/3
]).

%% API
-export([
    is_level_enough/1,
    get_attr/0,
    set_attr/1,
    add_attr_by_sats/1,
    add_attr_amend/1,
    add_attr/1,
    sub_attr_by_sats/1,
    sub_attr_amend/1,
    sub_attr/1,
    add_attr_and_not_notify/1,
    sub_attr_and_not_notify/1,
  %% check value info

    add_exp/1,
    add_pearl/1, 
    cast_pearl/1, 
    cost_pearl_if_enough/1, 
    add_long_wen/1, 
    cast_long_wen/1, 
    cost_long_wen_if_enough/1,
    add_money/1, 
    cost_money/1, 
    cost_money_if_enough/1, 
    add_fragment/1, 
    cost_fragment/1, 
    cost_fragment_if_enough/1,


    add_value/2,
    cost_value/2, 
    cost_value_if_enough/2,

    is_daliy_first_online/0,

    get_online_passed_time/0,
    get_passed_time_since_lasttime_offline/1,

    pack_view_data/0,
    get_player_view_info/1,
    %%add_blood_checkcmd/2,

    update_view_data/2,

    set_full_hp/0,
    set_full_mp/0,
    player_send/1,
    notify_data_changed/2,
    set_level/1,
    %%,get_combat_power/1


    direct_update_player_data/4

]).

%% e.g -> player:direct_update_player_data(player_tab, 100010001000002,#player_tab.sp,90).
direct_update_player_data(Tab, Id, Key, Val) ->
    %?DEBUG_LOG("Tab, Id, Key, Val---------------------:~p",[{Tab, Id, Key, Val}]),
    case mnesia:dirty_read(Tab, Id) of
        [] ->
            pass;
        [D] ->
            %?DEBUG_LOG("D-------------------------:~p",[D]),
            OldV = element(Key, D),
            %?DEBUG_LOG("OldV-----------------------:~p",[OldV]),
            NewD = erlang:setelement(Key, D, erlang:max(0, OldV+Val)),
            %?DEBUG_LOG("NewD-----------------------:~p",[NewD]),
            mnesia:dirty_write(Tab, NewD)
    end.


player_send(Data) when is_binary(Data)->
    case get(?pd_socket) of
        robot_socket ->
            pass;
        _ ->
            case catch player_eng:tcp_send(Data) of
                ok ->
                    ok;
                __Why ->
                    <<CmdId:16, _/binary>> = Data,
                    ?DEBUG_LOG("send msg failed ~p CmdId= ~p ", [__Why, proto_info:to_s(CmdId)])
            end
            % (fun() -> not is_list(Data) andalso not is_binary(Data) andalso throw({send_data_error_type, Data}),
            %     %?DEBUG_LOG("Data---------------------------:~p",[Data]),
            %     case catch player_eng:tcp_send(Data) of
            %         ok ->
            %             ok;
            %         __Why ->
            %             <<CmdId:16, _/binary>> = Data,
            %             ?DEBUG_LOG("send msg failed ~p CmdId= ~p ", [__Why, proto_info:to_s(CmdId)])
            %     end
            %     end()
            % )
    end;
player_send(_O) ->
    ?ERROR_LOG("player_send err data---------------------------:~p",[_O]).


lookup_info(PlayerId, KeyOrS) ->
    lookup_info(PlayerId, KeyOrS, ?none).

-spec lookup_info(player_id(), Keys, Def :: _) -> InfoValue when
    Keys :: [Key],
    Key :: ?pd_name | ?pd_name_pkg | ?pd_level | ?pd_career |
    ?pd_scene_id | ?pd_attr,
    InfoValue :: [_].

lookup_info(PlayerId, Key, Def) when is_atom(Key) ->
    [V] = lookup_info(PlayerId, [Key], Def),
    V;
lookup_info(PlayerId, Keys, Def) when is_list(Keys) ->
    case dbcache:lookup(?player_tab, PlayerId) of
        [] -> 
            [Def];
        [Info] ->
            lists:foldr(fun
                (?pd_honour, Acc) -> [Info#player_tab.honour | Acc];
                (?pd_name, Acc) -> [Info#player_tab.name | Acc];
                (?pd_name_pkg, Acc) -> [<<?pkg_sstr(Info#player_tab.name)>> | Acc];
                (?pd_level, Acc) -> [Info#player_tab.level | Acc];
                (?pd_career, Acc) -> [Info#player_tab.career | Acc];
                (?pd_exp, Acc) -> [Info#player_tab.exp | Acc];
                (?pd_item_id, Acc) -> [Info#player_tab.item_id | Acc];
                (?pd_longwens, Acc) -> [Info#player_tab.longwens | Acc];
                (?pd_combat_power, Acc) ->
                    case dbcache:lookup(?player_attr_image_tab, PlayerId) of
                        [#player_attr_image_tab{attr_new = PAttr}] ->
                            Pow = attr_new:get_combat_power(PAttr),
                            [Pow | Acc];
                        [] ->
                            [0 | Acc]
                    end;
                (?pd_equip, Acc) ->
                    case dbcache:load_data(?player_equip_tab, PlayerId) of
                        [EqmBucketTab] ->
                            % ?DEBUG_LOG("EqmBucketTab-----------------:~p",[EqmBucketTab]),
                            Bucket = EqmBucketTab#player_backet_tab.bucket,
                            case Bucket of
                                ?undefined ->
                                    [Def|Acc];
                                _ ->
                                    BucketInfo = goods_bucket:get_info(Bucket),
                                    EqmList = BucketInfo#bucket_info.items,
                                    [EqmList | Acc]
                            end;
                        [] ->
                            [Def | Acc]
                    end;
                (?pd_scene_id, Acc) ->
                    case scene_mng:lookup_player_scene_id_if_online(PlayerId) of
                        offline ->
                            [Info#player_tab.scene_id | Acc];
                        SceneId ->
                            [SceneId | Acc]
                    end;
                (?pd_hp, Acc) ->
                    case dbcache:lookup(?player_attr_image_tab, PlayerId) of
                        [#player_attr_image_tab{attr_new = PAttr}] ->
                            #attr{hp = Hp} = PAttr,
                            [Hp | Acc];
                        [] ->
                            [Def | Acc]
                    end;
                (?pd_attr, Acc) ->
                    case dbcache:lookup(?player_attr_image_tab, PlayerId) of
                        [#player_attr_image_tab{attr_new = PAttr}] ->
                            Attr = PAttr,
                            [Attr | Acc];
                        [] ->
                            [Def | Acc]
                    end;
                (_X, Acc) ->
                    Acc
            end,
            [],
            Keys)
    end.
%% lookup_info(PlayerId, Keys, Def) when is_list(Keys) ->
%%     case dbcache:lookup(?player_tab, PlayerId) of
%%         [] -> [Def];
%%         [Info] ->
%%             lists:foldr(
%%                 fun
%%                     (?pd_honour, Acc) -> [Info#player_tab.honour | Acc];
%%                     (?pd_name, Acc) -> [Info#player_tab.name | Acc];
%%                     (?pd_name_pkg, Acc) -> [<<?pkg_sstr(Info#player_tab.name)>> | Acc];
%%                     (?pd_level, Acc) -> [Info#player_tab.level | Acc];
%%                     (?pd_career, Acc) -> [Info#player_tab.career | Acc];
%%                     (?pd_exp, Acc) -> [Info#player_tab.exp | Acc];
%%                     (?pd_item_id, Acc) -> [Info#player_tab.item_id | Acc];
%%                     (?pd_longwens, Acc) -> [Info#player_tab.longwens | Acc];
%%                     (?pd_combat_power, Acc) -> [Info#player_tab.combat_power | Acc];
%%                     (?pd_equip, Acc) ->
%% %%                         ?INFO_LOG("lookup_info ~p", [{?player_equip_tab, PlayerId}]),
%%                         case dbcache:load_data(?player_equip_tab, PlayerId) of
%%                             [EqmBucketTab] ->
%%                                 Bucket = EqmBucketTab#player_backet_tab.bucket,
%%                                 BucketInfo = goods_bucket:get_info(Bucket),
%%                                 EqmList = BucketInfo#bucket_info.items,
%%                                 [EqmList | Acc];
%%                             [] ->
%%                                 [Def | Acc]
%%                         end;
%%                     (?pd_hp, Acc) ->
%%                         case dbcache:lookup(?player_attr_tab, PlayerId) of
%%                             [PAttr] ->
%%                                 #attr{hp = Hp} = player_base_data:get_attr(PAttr),
%%                                 [Hp | Acc];
%%                             [] -> [Def | Acc]
%%                         end;
%%                     (?pd_scene_id, Acc) ->
%%                         case scene_mng:lookup_player_scene_id_if_online(PlayerId) of
%%                             offline ->
%%                                 [Info#player_tab.scene_id | Acc];
%%                             SceneId ->
%%                                 [SceneId | Acc]
%%                         end;
%%                     (?pd_attr, Acc) ->
%%                         case dbcache:lookup(?player_attr_tab, PlayerId) of
%%                             [PAttr] ->
%%                                 Attr = player_base_data:get_attr(PAttr),
%%                                 [Attr | Acc];
%%                             [] -> [Def | Acc]
%%                         end;
%%                     (_X, Acc) ->
%%                         Acc
%%                 end,
%%                 [],
%%                 Keys)
%%     end.


%% 初始化杂项表数据
init_misc(Tree) ->
    Now = com_time:now(),
    gb_trees:insert(?pd_misc_mail_time, Now, Tree).

%% 查询杂项表内容
lookup_misc(PlayerId, Key) ->
    lookup_misc(PlayerId, Key, ?undefined).

lookup_misc(PlayerId, Key, Def) ->
    case dbcache:lookup(?player_misc_tab, PlayerId) of
        [#player_misc_tab{val = Tree}] ->
            case gb_trees:lookup(Key, Tree) of
                {value, Val} -> 
                    Val;
                _ -> 
                    Def
            end;
        _ ->
            Def
    end.

%% 设置杂项表数据
set_misc(PlayerId, Key, Val) ->
    case dbcache:lookup(?player_misc_tab, PlayerId) of
        [PMisc = #player_misc_tab{val = Tree}] ->
            NTree = gb_trees:enter(Key, Val, Tree),
            dbcache:update(?player_misc_tab, PMisc#player_misc_tab{val = NTree});
        _ ->
            ?ERROR_LOG("player_misc_tab not found ~w", [PlayerId]),
            exit(not_found)
    end.

add_attr_by_sats(Sats) when is_list(Sats) ->
    NewAttr = attr:add_by_sats(Sats, get(?pd_attr)),
    set_attr(NewAttr).

add_attr(Attr) ->
    NewAttr = attr:add(Attr, get(?pd_attr)),
    set_attr(NewAttr).

sub_attr_by_sats(Sats) when is_list(Sats) ->
    NewAttr = attr:sub_by_sats(Sats, get(?pd_attr)),
    set_attr(NewAttr).

-spec add_attr_amend(#attr{}) -> NewAttr :: #attr{}.
add_attr_amend(AttrId) when is_integer(AttrId) ->
    Attr = attr:get_base_attr(AttrId),
    add_attr_amend(Attr);
add_attr_amend(Attr) ->
    BodyAttr = get(?pd_attr),
    NewAttr = attr:add_amend(Attr, BodyAttr),
    %?debug_log_scene("Body ~w======== Add ~w===========New~w", [BodyAttr, Attr, NewAttr]),
    set_attr(NewAttr).

add_attr_and_not_notify(Attr) ->
    NewAttr = attr:add_amend(Attr, get(?pd_attr)),
    update_attr(NewAttr).

sub_attr_and_not_notify(Attr) ->
    NewAttr = attr:sub(get(?pd_attr), Attr),
    update_attr(NewAttr).

%% @doc 减少属性
-spec sub_attr_amend(#attr{}) -> NewAttr :: #attr{}.
sub_attr_amend(Attr) ->
    NewAttr = attr:sub_amend(Attr, get(?pd_attr)),
    set_attr(NewAttr).

sub_attr(Attr) ->
    NewAttr = attr:sub(get(?pd_attr), Attr),
    set_attr(NewAttr).

%% @doc 获取角色属性信息
get_attr() ->
    get(?pd_attr).

%% @doc 保存角色属性信息
set_attr(Attr) ->
    %%update_combat_power(New), %% TODO
    put(?pd_attr, Attr),
    %%     NewPower = attr:get_combat_power(Attr),
    Attr1 = attr_new:get_oldversion_attr(),
    NewPower = attr_new:get_combat_power(Attr1),

    put(?pd_combat_power, NewPower),
    scene_mng:send_msg({?msg_update_attr, get(?pd_idx), Attr1}),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ATTR_CHANGE, {?r2t(Attr1)})),
    %%notify_data_changed(?PL_COMBAT_POWER, NewPower),
    notify_data_changed(?pd_combat_power, NewPower),
    ok.

update_attr(Attr) ->
    put(?pd_attr, Attr),
    ok.

sync_player_attr_to_client() ->
    Attr1 = attr_new:get_oldversion_attr(),
    NewPower = attr_new:get_combat_power(Attr1),
    put(?pd_combat_power, NewPower),
    open_server_happy_mng:sync_task(?ZHANLI_VAL, NewPower),
    scene_mng:send_msg({?msg_update_attr, get(?pd_idx), Attr1}),
    ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_ATTR_CHANGE, {?r2t(Attr1)})),
    notify_data_changed(?pd_combat_power, NewPower),
    ok.


%% 血回满
set_full_hp() ->
    MaxHp = attr_new:get_attr_item(?pd_attr_max_hp),
    set_value(?pd_hp, MaxHp).


set_full_mp() ->
    MaxMp = attr_new:get_attr_item(?pd_attr_max_mp),
    set_value(?pd_mp, MaxMp).
    % set_value(?pd_mp, (get(?pd_attr))#attr.mp).
    % todo.

%%%% value OP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



-type value_pd() :: ?pd_pearl | ?pd_money | ?pd_diamond | ?pd_fragment.

add_pearl(Val) ->
    add_value(?pd_pearl, Val).

cast_pearl(Val) ->
    cost_value(?pd_pearl, Val).

cost_pearl_if_enough(Val) ->
    cost_value_if_enough(?pd_pearl, Val).

add_long_wen(Val) ->
    add_value(?pd_long_wen, Val).

cast_long_wen(Val) ->
    cost_value(?pd_long_wen, Val).

cost_long_wen_if_enough(Val) ->
    cost_value_if_enough(?pd_long_wen, Val).

add_money(Val) ->
    add_value(?pd_money, Val).

cost_money(Val) ->
    cost_value(?pd_money, Val).

cost_money_if_enough(Val) ->
    cost_value_if_enough(?pd_money, Val).

add_fragment(Val) ->
    add_value(?pd_fragment, Val).

cost_fragment(Val) ->
    cost_value(?pd_fragment, Val).

cost_fragment_if_enough(Val) ->
    cost_value_if_enough(?pd_fragment, Val).

%% @doc 数值属性更改函数
-spec add_value(value_pd(), non_neg_integer()) -> non_neg_integer().
add_value(pd_exp_per, Per) ->
    Lev = get(?pd_level),
    Career = get(?pd_career),
    case load_career_attr:lookup_role_cfg({Career, Lev}) of
        ?none -> 
            get(?pd_exp);
        #role_cfg{level_up_exp = LevUpExp} ->
            Exp = com_util:ceil((LevUpExp * Per) / 100),
            add_value(pd_exp, Exp),
            Exp
    end;

add_value(pd_exp, V) ->
    add_exp(V);
add_value(Which, V) ->
    ?assert(is_atom(Which)),
    N = erlang:get(Which) + V,
    erlang:put(Which, N),
    ?debug_log_player("add assets type ~w val ~w addval ~w", [Which, N, V]),
    notify_data_changed(Which, N),

    case Which of
        ?pd_money ->
            achievement_mng:do_ac2(?jiacaiwanguan, 0, V);
        ?pd_diamond ->
            achievement_mng:do_ac2(?zuanshizhiwang, 0, V);
        _ -> 
            ok
    end,
    N.

-spec cost_value(value_pd(), non_neg_integer()) -> non_neg_integer().
cost_value(Which, V) ->
    ?assert(is_atom(Which)),
    N = erlang:max(0, erlang:get(Which) - V),
    erlang:put(V, N),
    notify_data_changed(Which, N),
    N.

-spec set_value(value_pd(), non_neg_integer()) -> non_neg_integer().
set_value(Which, V) ->
    ?assert(is_atom(Which)),
    erlang:put(Which, V),
    notify_data_changed(Which, V).



-spec cost_value_if_enough(value_pd(), non_neg_integer()) -> not_enough | non_neg_integer().
cost_value_if_enough(Which, V) ->
    ?assert(is_atom(Which)),
    ?debug_log_player("cost type ~w val ~w subval ~w", [Which, get(Which), V]),
    case erlang:get(Which) - V of
        N when N < 0 ->
            not_enough;
        N ->
            erlang:put(Which, N),
            notify_data_changed(Which, N),
            case Which of
                ?PL_MONEY ->
                    achievement_mng:do_ac2(?jiacaiwanguan, 0, V);
                ?PL_DIAMOND ->
                    achievement_mng:do_ac2(?zuanshizhiwang, 0, V);
                _ -> 
                    ok
            end,
            N
    end.

set_level(Level) ->
    Career = get(?pd_career),
    Lev = get(?pd_level),
    Level1 = erlang:min(Lev + Level, misc_cfg:get_max_lev()),
    if
        Lev < Level1 ->
            NewLev = Lev + 1,
            #role_cfg{level_up_exp = LevUpExp, attr = OldAttrId} = load_career_attr:lookup_role_cfg({Career, Lev}),
            case load_career_attr:lookup_role_cfg({Career, NewLev}) of
                ?none ->
                    put(?pd_exp, LevUpExp),
                    notify_data_changed(?pd_exp, LevUpExp),
                    LevUpExp;
                #role_cfg{attr = NewAttrId} ->
                    put(?pd_exp, 0),
                    attr_new:set(?pd_level, NewLev),
                    notify_data_changed(?pd_level, NewLev),
                    levelup(Lev, OldAttrId, NewAttrId)
            end,
            friend_mng:level_up(),
            Level > 1 andalso set_level(Level - 1);
        true ->
            Lev
    end.




is_level_enough(Level) ->
    get(?pd_level) >= Level.

%%  TODO:临时屏蔽，做一个暂时能用的
%set_level(NewLevel) ->
%    CfgL = erlang:get(?pd_career) * 1000 + NewLevel,
%    Exp = hero:level_up_exp(CfgL),
%    add_exp(Exp).


%% @doc 在scene场景操作
%% -spec add_hp(integer()) -> _.
%% add_hp(V) ->
%%     ?debug_log_player("player add hp ~p", [V]),
%%     scene_mng:send_msg({?msg_add_hp, get(?pd_idx), V}).


%% @doc 在scene场景操作
%% -spec del_hp(integer() | float()) -> _.
%% del_hp(V) ->
%%     scene_mng:send_msg({?msg_del_hp, get(?pd_idx), V}).

add_exp(0) -> get(?pd_exp);
add_exp(Add) ->
    add_exp__(Add, Add).


add_exp__(Add, Total) ->
    Lev = get(?pd_level),
    Career = get(?pd_career),
    New = get(?pd_exp) + Add,

    case load_career_attr:lookup_role_cfg({Career, Lev}) of
        ?none -> %% max level
            ?ERROR_LOG("can not occured"),
            get(?pd_exp);
        #role_cfg{level_up_exp = LevUpExp, attr = OldAttrId} ->
            if 
                New < LevUpExp ->
                    put(?pd_exp, New),
                    notify_data_changed(?pd_exp, New),
                    sync_player_attr_to_client(),
                    New;
                true -> %% upLevel
                    NewLev = Lev + 1,
                    case load_career_attr:lookup_role_cfg({Career, NewLev}) of
                        ?none -> %% add to full oo
                            put(?pd_exp, LevUpExp),
                            notify_data_changed(?pd_exp, LevUpExp),
                            LevUpExp;
                        #role_cfg{attr = NewAttrId} ->
                            put(?pd_exp, 0),
                            NewLev1 = min(NewLev, misc_cfg:get_max_lev()),
                            attr_new:set(?pd_level, NewLev1),
                            notify_data_changed(?pd_level, NewLev1),
                            levelup(Lev, OldAttrId, NewAttrId),
                            achievement_mng:do_ac2(?zishenwanjia, 0, 1),

                            add_exp__(New - LevUpExp, Total)
                    end
            end
    end.

levelup(OldLevel, OldAttrId, NewAttrId) ->
    phase_achievement_mng:do_pc(?PHASE_AC_LEVEL, 1),
    add_long_wen_by_level(OldLevel+1),
    vip_new_mng:do_grow_jijin(OldLevel+1),
    %% notice_system:send_player_level_strong(OldLevel+1),
    open_server_happy_mng:sync_task(?LEVEL_UP, OldLevel+1),
    honest_user_mng:is_change_level_prize_state(OldLevel + 1),
    case robot_new:is_robot(get(?pd_id)) of
        true ->
            robot_fsm:robot_level_up(OldLevel + 1);
        _ ->
            ignore
    end,

    [Mod:handle_frame({?frame_levelup, OldLevel}) || Mod <- ?all_player_eng_mods()],
    [Mod:handle_frame({?frame_levelup, OldLevel}) || Mod <- ?all_player_logic_mods()],

    PlayerAttr = player:get_attr(),
    NPlayerAttr = attr:sub_amend(OldAttrId, PlayerAttr),
    FPlayerAttr = attr:add_amend(NewAttrId, NPlayerAttr),
    %set_attr(FPlayerAttr), %% dsl
    update_attr(FPlayerAttr),
    dbcache:update_element(?player_tab, get(?pd_id), {#player_tab.level, get(?pd_level)}),
    ok.


notify_data_changed(Which, Val) ->
    case player_def:special_item_id_to_i(Which) of
        badarg ->
            ok;  %% badarg 说明不需要发送给前端
        Type ->
            ?player_send(player_sproto:pkg_msg(?MSG_PLAYER_DATA_CHANGED, {Type, Val})),
            notify_scene_if_need(Type, Val)
    end.


notify_scene_if_need(Type, Value) ->
    if 
        Type =:= ?PL_HP orelse Type =:= ?PL_MP ->
            scene_mng:send_msg({?msg_update_view_data, get(?pd_idx), Type, Value, nil});
        true ->
            ok
    end.

update_view_data(Type, V) ->
    ViewData = if
        Type =:= ?PL_LEVEL -> nil;
        ?true -> nil
    end,
    scene_mng:send_msg({?msg_update_view_data, get(?pd_idx), Type, V, ViewData}),
    ok.

lookup_view_data(_PlayerId) ->
    %% TODO
    todo.


%%% player_mods  end
is_daliy_first_online() ->
    com_time:is_same_day(erlang:get(?pd_last_logout_time)).


%% TODO 统一所有的view data 分开更新
pack_view_data() ->
    Acc = <<(get(?pd_id)):64, (get(?pd_name_pkg))/binary, (get(?pd_career)), (get(?pd_level))>>,
    TitleBin = title_mng:view_data(Acc),
    GuildBin = guild_mng:view_data(Acc),
    EquipBin = equip_system:get_takeon_equips_list(),
    <<Acc/binary, TitleBin/binary, GuildBin/binary, EquipBin/binary>>.

get_player_view_info(PlayerId) ->
    Acc = 
    case player:lookup_info(PlayerId, [?pd_name, ?pd_level, ?pd_career]) of
        [Name, Level, Career] ->
            <<PlayerId:64, ?pkg_sstr(Name), Career, Level>>;
        _ ->
            <<PlayerId:64, ?pkg_sstr(<<"xxx">>), 1, 20>>
    end,
    TitleBin = <<0:16>>,
    GuildBin = <<0:8>>,
    EquipBin = <<0:32, 0:32, 0:32, 0:32, 0:32, 0:32, 0:32, 0:32, 0:32, 0:32>>,
    <<Acc/binary, TitleBin/binary, GuildBin/binary, EquipBin/binary>>.

%% @doc 得到上线以后经过的时间 秒
%% INLINE
get_online_passed_time() ->
    com_time:now() - get(?pd_last_online_time).


%% @doc 获取用户自从上一次下线到现在的时间（单位：秒）。
get_passed_time_since_lasttime_offline(PlayerId) ->
    SelfPlayerId = get(?pd_id),
    case PlayerId of
        SelfPlayerId ->
            com_time:now() - get(?pd_last_logout_time);
        _ ->
            [Player] = dbcache:lookup(?player_tab, PlayerId),
            com_time:now() - Player#player_tab.last_logout_time
    end.

%% @doc  主角升级根据配置获得龙纹
add_long_wen_by_level(MyLevel) ->
    [MinLev, MaxLev, Num,LeveInter] = misc_cfg:get_longwen_huoqu(),
    DiffLevel = (MyLevel - MinLev) rem LeveInter,
    if
        MyLevel >= MinLev andalso MyLevel =< MaxLev andalso DiffLevel =:= 0 ->
            %%      add_long_wen(Num),
            ExtraLongHunCount = load_vip_new:get_long_wen_num_by_vip_level(get(?pd_vip)),
            game_res:try_give_ex([{?LONGWEN_COST_ID, Num+ExtraLongHunCount}], ?FLOW_REASON_ROLE_LEVELUP),
            ok;
        true ->
            ok
    end.

%%----------------------------------------------------
%% @doc 邮件系统
%% @end
%%----------------------------------------------------

-module(mail_mng).

-include_lib("pangzi/include/pangzi.hrl").
%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("item.hrl").
-include("item_new.hrl").
-include("item_bucket.hrl").
-include("handle_client.hrl").
-include("game.hrl").
-include("load_cfg_mail.hrl").
-include("mail.hrl").
-include("system_log.hrl").

-export([
    send_sysmail/3, 
    send_sysmail/4,
    send_mail/4,
    test_send/1,
    update_offline_mail/2,
    split_assets/2
]).

-define(MTS_UNREAD, 1). %% 未读
-define(MTS_READED, 2). %% 已读

-define(MTS_UNTAKE, 1).   %% 附件未提取
-define(MTS_TAKE, 2).   %% 附件已提取

-define(MMIME_LEN_MAX, 6).  %% 单封邮件附件最大数



%%-record(mail_sys_cfg,
%%{id = 0
%%    , expirt_day = 1
%%    , title = <<>>
%%    , content = <<>>
%%}).
load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?player_mail_tab,
            fields = ?record_fields(?player_mail_tab),
            shrink_size = 10,
            flush_interval = 5
        },

        #db_table_meta{
            name = ?offline_mail_tab,
            fields = ?record_fields(?offline_mail_tab),
            shrink_size = 10,
            flush_interval = 5
        }
    ].


-record(mail, {id = exit(need_id), %%mail_id
    from_id = 0,   %% 当该id为0的时候为系统邮件
    from = <<>>,   %% Name/binary
    to = <<>>,
    cdate,
    auto_delete_sec = 0, %% 0 is never 自动删除的时间
    subject = <<>>,
    body = <<>>,
    sys_info = 0,       %% 系统邮件信息，通过配置表读
    items = [],
    assets = [],
    ex_state = ?MTS_UNTAKE,       %% 附件提取状态 1未提取 2已提取
    state = ?MTS_UNREAD           %% 邮件状态     1未读   2已读
}).


%% {10,1,1},{11,2,1},{12,3,1},{13,4,1},{14,5,1},{16,6,1},{21,7,1},{23,8,1},{24,9,1},{25,10,1},{27,11,1},{28,12,1},{29,13,1},{41,14,1},{104,15,1}
test_send(PlayerId) ->
    world:send_to_player(PlayerId,?mod_msg(mail_mng, {gm_mail, PlayerId, <<"3">> ,<<"3">>, 1451446789, [{10,99999,1},{11,99999,1}]})).




%% 拆分物品和资产
split_assets([], {ITps, ATps}) -> {ITps, ATps};
split_assets([Tp | ItemTps], {ITps, ATps}) ->
    case Tp of
        {ItemBid, _Count} when ItemBid =< 1000 ->
            split_assets(ItemTps, {ITps, [Tp | ATps]});
        {ItemBid, Count, _IsBind} when ItemBid =< 1000 ->
            split_assets(ItemTps, {ITps, [{ItemBid, Count} | ATps]});
        _ ->
            split_assets(ItemTps, {[Tp | ITps], ATps})
    end.

%% 发送系统邮件
%% ItemTps = [#item{} | {ItemBid, Count} | {ItemBid, Count, Bind}]
send_sysmail(_To, _SysInfo, []) ->
    pass;
send_sysmail(To, SysInfo, ItemTps) ->
    %?DEBUG_LOG("sys_info------------------------:~p",[SysInfo]),
    %?DEBUG_LOG("ItemTps1111-------------------:~p",[ItemTps]),
    {Items, Assets} = split_assets(ItemTps, {[], []}),
    %?DEBUG_LOG("items---------1---------------------:~p",[Items]),
    send_sysmail(To, SysInfo, Items, Assets).

send_sysmail(To, SysInfo, ItemTps0, Assets) ->
    ItemTps =
        case erlang:is_list(ItemTps0) of
            true -> ItemTps0;
            _ -> [ItemTps0]
        end,
    % ?DEBUG_LOG("ItemTps------------------:~p",[ItemTps]),
    % ?DEBUG_LOG("Assets--------------------------:~p",[Assets]),
    Items =
    lists:foldr(fun(NewTp, AccIn) ->
            %NewTp = Tp,
            case is_record(NewTp, item_new) of
                ?true ->
                    [NewTp | AccIn];
                _ ->
                    NewTp1 =
                    if
                        is_list(NewTp) ->
                            NewTp;
                        true ->
                            [NewTp]
                    end,
                    lists:foldl(fun
                            ({Bid, Num}, IL) ->
                                case entity_factory:build(Bid, Num, [], ?FLOW_REASON_MAIL) of
                                    {ok, _Error} ->
                                        IL;
                                    {error, _Error} ->
                                        %?ERROR_LOG("send_sysmail Error ~p", [{Error, Bid, Num}]),
                                        IL;
                                    ItemL ->
                                        [ItemL | IL]
                                end;
                            ({Bid, Num, _IsBind}, IL) ->
                                Overlap = load_item:get_overlap(Bid),
                                if
                                    Overlap == 1 ->
                                        email_build(Bid, Num, IL);
                                    true ->
                                        case entity_factory:build(Bid, Num, [], ?FLOW_REASON_MAIL) of
                                            {ok, _Error} ->
                                                IL;
                                            {error, _Error} ->
                                                % ?ERROR_LOG("send_sysmail Error ~p", [{Error, Bid, Num}]),
                                                IL;
                                            ItemL ->
                                                [ItemL | IL]
                                        end
                                end;
                            (_X, IL) ->
                                %?ERROR_LOG("send_sysmail error111 ~p", [{X, IL}]),
                                IL
                    end,
                    AccIn,
                    NewTp1)
            end
    end,
    [],
    ItemTps),
    %?DEBUG_LOG("Items----------2------------------:~p",[Items]),
    ILen = length(Items),
    ALen = length(Assets),
    %?DEBUG_LOG("ILen---------:~p-----ALen-----:~p",[ILen, ALen]),
    if
        ILen > ?MMIME_LEN_MAX ->
            {MailItems, TailItems} = lists:split(?MMIME_LEN_MAX, Items),
            Mail = mail_new_sysmail(To, SysInfo, MailItems, []),
            send_mail(Mail),
            send_sysmail(To, SysInfo, TailItems, Assets);
        ILen + ALen > ?MMIME_LEN_MAX ->
            {MailAssets, TailAssets} = lists:split(?MMIME_LEN_MAX - ILen, Assets),
            Mail = mail_new_sysmail(To, SysInfo, Items, MailAssets),
            send_mail(Mail),
            send_sysmail(To, SysInfo, [], TailAssets);
        ?true ->
            if
                Items =:= [] andalso Assets =:= [] ->
                    ?DEBUG_LOG("=======empty email!!!========="),
                    pass;
                true ->
                    Mail = mail_new_sysmail(To, SysInfo, Items, Assets),
                    send_mail(Mail)
            end
    end.

send_mail(To, SysId, Content, ItemTps) ->
    #mail_sys_cfg{expirt_day = ExpirtDay, title = Title} = load_cfg_mail:lookup_mail_sys_cfg(SysId),
    {Items, Assets} = split_assets(ItemTps, {[], []}),
    Time = ExpirtDay * ?SECONDS_PER_DAY,
    mail_new(0, ?Language(6, 0), To, Time, Title, Content, SysId, Items, Assets).

gm_send_mail(AccpetId, Title, Content, Expirtdate, ItemList) ->
    {ItemTps, Assets} = split_assets(ItemList, {[], []}),
    Items = 
    lists:foldr(fun
            (Tp, AccIn) ->
                NewTp = Tp,
                case is_record(NewTp, item_new) of
                    ?true ->
                        [NewTp | AccIn];
                    _ ->
                        NewTp1 =
                            if
                                is_list(NewTp) ->
                                    NewTp;
                                true ->
                                    [NewTp]
                            end,
                        lists:foldl(
                            fun
                                ({Bid, Num}, IL) ->
                                    case entity_factory:build(Bid, Num, [], ?FLOW_REASON_MAIL) of
                                        {ok, _Error} ->
                                            IL;
                                        {error, Error} ->
                                            ?ERROR_LOG("send_sysmail Error ~p", [{Error, Bid, Num}]),
                                            IL;
                                        ItemL ->
                                            [ItemL | IL]
                                    end;
                                ({Bid, Num, _IsBind}, IL) ->
                                    case entity_factory:build(Bid, Num, [], ?FLOW_REASON_MAIL) of
                                        {ok, _Error} ->
                                            IL;
                                        {error, Error} ->
                                            ?ERROR_LOG("send_sysmail Error ~p", [{Error, Bid, Num}]),
                                            IL;
                                        ItemL ->
                                            [ItemL | IL]
                                    end;
                                (X, IL) ->
                                    ?ERROR_LOG("send_sysmail error111 ~p", [{X, IL}]),
                                    IL
                            end,
                            AccIn,
                            NewTp1)
                end
        end,
        [],
        ItemTps),
    % ?DEBUG_LOG("ItemTps-------:~p------Assets----:~p--------ItemS------:~p",[ItemTps, Assets, Items]),
    Mail = mail_new(0, <<"系统"/utf8>>, AccpetId, Expirtdate, Title, Content, 0, Items, Assets),
    % ?DEBUG_LOG("Mail---------------------------------:~p",[Mail]),
    put(?pd_mail_mng, gb_trees:insert(Mail#mail.id, Mail, get(?pd_mail_mng))),
    Pkg = pack_mail(Mail),
    system_log:info_get_mail(0, com_time:now(), Title, Content),
    do_attach_log(0, Title, Items ++ Assets),
    ?player_send(mail_sproto:pkg_msg(?MSG_MAIL_NEW, {Pkg})).

%% 系统邮件
mail_new_sysmail(To, SysInfo, Items, Assets) ->
    #mail_sys_cfg{expirt_day = ExpirtDay, title = Title, content = Content} = load_cfg_mail:lookup_mail_sys_cfg(SysInfo),
    Time = ExpirtDay * ?SECONDS_PER_DAY,
    mail_new(0, <<"系统"/utf8>>, To, Time, Title, Content, SysInfo, Items, Assets).
%mail_new_sysmail(To, ExpirtDay, Subject, Body, Items, Assets) ->
%    mail_new(0, <<"系统"/utf8>>, To, ExpirtDay, Subject, Body, Items, Assets).

mail_new(FromId, From, To, ExpirtDay, Subject, Body, SysInfo, Items, Assets) ->
    % ILen = length(Items),
    % ALen = length(Assets),
    % if
    %     ILen + ALen > ?MMIME_LEN_MAX -> %% 附件数超过最大数量
    %         error;
    %     true ->
            Now = com_time:now(),
            #mail{id = erlang:phash2({Now, erlang:make_ref(), To})
                , from_id = FromId
                , from = From
                , to = To
                , auto_delete_sec = ExpirtDay
                , cdate = Now
                , subject = Subject
                , body = Body
                , sys_info = SysInfo
                , items = Items
                , assets = Assets
            }.
    % end.

send_mail(Mail) ->
    world:send_to_player_any_state(Mail#mail.to, ?mod_msg(mail_mng, {send_mail, Mail})).



pack_mail(#mail{id = Id, from_id = FId, from = FName, subject = Sub, body = Body, cdate = CDate, auto_delete_sec = DelSec,
    items = Items, assets = Assets, ex_state = ExSta, state = Sta, sys_info = _SysInfo}) ->
    {Id, FId, FName, Sub, Body, CDate, DelSec, [goods_bucket:get_sink_info(Item, 0) || Item <- Items], Assets, ExSta, Sta}.

handle_client({Pack, Arg}) ->
    handle_client(Pack, Arg).

%% 读取所有邮件
handle_client(?MSG_MAIL_LOAD_ALL, {}) ->
    MailL = gb_trees:values(get(?pd_mail_mng)),
    MailL2 = lists:keysort(#mail.cdate, MailL),
    MailL3 = [pack_mail(Mail) || Mail <- MailL2],
    ?debug_log_mail("load all ~w", [MailL3]),
    PlayerId = get(?pd_id),
    MailTime = player:lookup_misc(PlayerId, ?pd_misc_mail_time),
    Pkg = mail_sproto:pkg_msg(?MSG_MAIL_LOAD_ALL, {MailL3, MailTime}),
    ?player_send(Pkg);

%% 阅读邮件
handle_client(?MSG_MAIL_READ, {MailId}) ->
    case gb_trees:lookup(MailId, get(?pd_mail_mng)) of
        ?none ->
            ?err(not_mail);
        {?value, M} ->
            ?if_(M#mail.state =:= ?MTS_UNREAD,
                put(?pd_mail_mng, gb_trees:update(MailId,
                    M#mail{state = ?MTS_READED},
                    get(?pd_mail_mng)))),
            ok
    end;

%% 删除邮件
handle_client(?MSG_MAIL_DELETE, {MailIds}) ->
    MailInfo = get(?pd_mail_mng),
    NMailInfo = lists:foldl(fun(MailId, AccIn) ->
        gb_trees:delete_any(MailId, AccIn)
    end, MailInfo, MailIds),
    put(?pd_mail_mng, NMailInfo),
    ?player_send(mail_sproto:pkg_msg(?MSG_MAIL_PUSH_DELETE, {MailIds}));

%% 提取附件
handle_client(?MSG_MAIL_GET_PRIZE, {MailId}) ->
    ReplyNum = case gb_trees:lookup(MailId, get(?pd_mail_mng)) of
                   ?none -> ?GET_PRIZE_1;   %% 邮件不存在
                   {?value, #mail{items = [], assets = []}} ->
                       ?GET_PRIZE_2;         %% 附件为空
                   {?value, #mail{items = Items, assets = Assets}} ->
                       GoodsList = Assets ++ Items,
                       game_res:set_res_reasion(<<"Mail">>),
                       case game_res:try_give_ex(GoodsList, ?FLOW_REASON_MAIL) of
                           {error, _AddReason} -> %% 背包满
                               ?debug_log_mail("get prize error ~w", [_AddReason]),
                               ?GET_PRIZE_3;
                           _ -> %% 提取附件成功
                               put(?pd_mail_mng, gb_trees:delete_any(MailId, get(?pd_mail_mng))),
                               ?player_send(mail_sproto:pkg_msg(?MSG_MAIL_PUSH_DELETE, {[MailId]})),
                               ?GET_PRIZE_OK
                       end
               end,
    ?player_send(mail_sproto:pkg_msg(?MSG_MAIL_GET_PRIZE, {ReplyNum}));

%% 一键提取附件
handle_client(?MSG_MAIL_ONE_KEY_GET_PRIZE, {}) ->
    MailL = gb_trees:values(get(?pd_mail_mng)),
    MailL2 = lists:keysort(#mail.cdate, MailL),
    EMailId = case one_key_get_prize(MailL2, []) of
                  ok -> 0;      %% 提取附件成功
                  {error, _AddReason, EndMailId} ->
                      ?debug_log_mail("one key get prize error ~w", [_AddReason]),
                      EndMailId
              end,
    ?player_send(mail_sproto:pkg_msg(?MSG_MAIL_ONE_KEY_GET_PRIZE, {EMailId}));

%% 更新邮件新旧时间戳
handle_client(?MSG_MAIL_NEW_TIME, {}) ->
    Now = com_time:now(),
    PlayerId = get(?pd_id),
    player:set_misc(PlayerId, ?pd_misc_mail_time, Now),
    ok;

handle_client(Mod, Msg) ->
    ?ERROR_LOG("no known msg Mod:~p Msg:~p", [mail_sproto:to_s(Mod), Msg]).

handle_msg(_FromMod, {send_mail, Mail}) ->
    put(?pd_mail_mng, gb_trees:insert(Mail#mail.id, Mail, get(?pd_mail_mng))),

    system_log:info_get_mail(0, com_time:now(), Mail#mail.subject, Mail#mail.body),
    do_attach_log(0, Mail#mail.subject, Mail#mail.items ++ Mail#mail.assets),

    % api:mail_full_alarm(),

    Pkg = pack_mail(Mail),
%%     ?INFO_LOG("statr ======================== "),
%%    ?INFO_LOG("send ~w", [Pkg]),
    ?player_send(mail_sproto:pkg_msg(?MSG_MAIL_NEW, {Pkg})),
%%     case Mail#mail.items of
%%         [] -> ok;
%%         _ -> ?player_send( mail_sproto:pkg_msg(?MSG_MAIL_NEW, {Pkg}))
%%     end,
%%     ?INFO_LOG("end ========================== "),
    ok;

handle_msg(_, {gm_mail, Id, Title, Content, EndTime, ItemList}) ->
    % ?DEBUG_LOG("gm_mail------------------------"),
    gm_send_mail(Id, Title, Content, EndTime, ItemList);

handle_msg(_, {gwgc_mail, Id, MailInfo, ItemList}) ->
    %?DEBUG_LOG("Id----:~p------ITELIst---:~p",[Id, ItemList]),
    send_sysmail(Id, MailInfo, ItemList);

handle_msg(_, {arena_phase_ranking_prize, Id, MailInfo, ItemList}) ->
    send_sysmail(Id, MailInfo, ItemList);

handle_msg(_, {weekly_rank_prize_mail, Id, MailInfo, ItemList}) ->
    send_sysmail(Id, MailInfo, ItemList);

handle_msg(_FromMod, _Msg) ->
    {error, <<"unknown msg">>}.

handle_frame(_) -> ok.

% create_offline_mail(PlayerId) ->
%     case dbcache:insert_new(?offline_mail_tab, #?offline_mail_tab{id=PlayerId}) of
%         ?true ->
%             ok;
%         ?false ->
%             ?ERROR_LOG("create mod data offline_mail_tab alread exists ")
%     end.

create_mod_data(SelfId) ->
    case dbcache:insert_new(?player_mail_tab,#player_mail_tab{id = SelfId, mng = []}) of
        ?true ->
             ok;
        ?false ->
            ?ERROR_LOG("create mod data alread exists ")
    end,
    case dbcache:insert_new(?offline_mail_tab, #?offline_mail_tab{id=SelfId}) of
        ?true ->
            ok;
        ?false ->
            ?ERROR_LOG("create mod data offline_mail_tab alread exists ")
    end,
    ok.

load_mod_data(PlayerId) ->
    case dbcache:load_data(?offline_mail_tab, PlayerId) of
        [] ->
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
            %create_offline_mail(PlayerId);
        _ ->
            pass
    end,
    case dbcache:load_data(?player_mail_tab, PlayerId) of
        [] ->
            ?ERROR_LOG("player ~p can not find data ~p mode", [PlayerId, ?MODULE]),
            create_mod_data(PlayerId),
            load_mod_data(PlayerId);
        [#player_mail_tab{mng = _Mng}] ->
            Mng = auto_delete_expirt_mail(_Mng),
            ?pd_new(?pd_mail_mng, gb_trees:from_orddict(Mng))
    end.

init_client() ->
    PlayerId = get(?pd_id),
    List = 
    case dbcache:lookup(?offline_mail_tab, PlayerId) of
        [] ->
            [];
        [#?offline_mail_tab{mail_list=MailList}] ->
            % ?DEBUG_LOG("MailList--------------------------:~p",[MailList]),
            MailList
    end,
    Pid = self(),
    %?DEBUG_LOG("List----------------------:~p",[List]),
    %List = load_db_misc:get_emails(PlayerId),
    lists:foreach(fun(Msg) ->
        Pid ! Msg
    end,
    List),
    %load_db_misc:set_emails(PlayerId, []),
    dbcache:update(?offline_mail_tab, #?offline_mail_tab{id=PlayerId, mail_list=[]}),
    ok.

view_data(Pkg) -> Pkg.

save_data(PlayerId) ->
    dbcache:update(?player_mail_tab, #?player_mail_tab{id = PlayerId, mng = gb_trees:to_list(get(?pd_mail_mng))}),
    ok.

online() -> unsed.

offline(_PlayerId) ->
    ok.

update_offline_mail(PlayerId, Msg) ->
    case dbcache:lookup(?offline_mail_tab, PlayerId) of
        [] ->
            pass;
        [#?offline_mail_tab{mail_list = List}] ->
            dbcache:update(?offline_mail_tab, #?offline_mail_tab{id = PlayerId, mail_list = [Msg | List]})
    end.


one_key_get_prize([], DelMailIds) ->
    ?player_send(mail_sproto:pkg_msg(?MSG_MAIL_PUSH_DELETE, {DelMailIds})),
    ok;
one_key_get_prize([M = #mail{id = Id, items = Items, assets = Assets} | ML] = MailList, DelMailIds) ->
    GoodsList = get_mail_list_item_list(MailList),
    case game_res:can_give(GoodsList) of
        ok ->
            case game_res:try_give_ex(Items ++ Assets, ?FLOW_REASON_MAIL) of
                {error, AddReason} ->
                    {error, AddReason, M#mail.id};
                _ ->
                    put(?pd_mail_mng, gb_trees:delete_any(Id, get(?pd_mail_mng))),
                    one_key_get_prize(ML, [Id | DelMailIds])
            end;
        {error, _} ->
            {error, no_enough_size, M#mail.id}
    end.


auto_delete_expirt_mail(TupleList) ->
    Now = com_time:now(),
    lists:foldr(fun({Id, Mail = #mail{cdate = CDate, auto_delete_sec = ASec}}, AccIn) ->
        if
            Now > CDate + ASec, ASec /= 0 -> %% 超时删除
                AccIn;
            true -> %% 未到时间不能删除,或者永久不删除
                [{Id, Mail} | AccIn]
        end
    end, [], TupleList).

get_mail_list_item_list(MailList) ->
    Fun =
        fun(_, []) -> [];
            (F, [#mail{items = Items, assets = Assets}|T]) ->
                Items ++ Assets ++ F(F, T)
        end,
    List = Fun(Fun, MailList),
    List.

do_attach_log(_, _, []) -> ok;
do_attach_log(SendId, MailName, [{ItemId, ItemCount} | ResList]) ->
    system_log:info_mail_attach(SendId, MailName, ItemId, ItemCount),
    do_attach_log(SendId, MailName, ResList);
do_attach_log(SendId, MailName, [#item_new{bid = ItemId, quantity = ItemCount} | ResList]) ->
    system_log:info_mail_attach(SendId, MailName, ItemId, ItemCount),
    do_attach_log(SendId, MailName, ResList).

%%----------------------------------------------------
%% config 部分
%%load_config_meta() ->
%%    [
%%        #config_meta{record = #mail_sys_cfg{},
%%            fields = ?record_fields(mail_sys_cfg),
%%            file = "mail_sys.txt",
%%            keypos = #mail_sys_cfg.id,
%%            verify = fun verify/1}
%%
%%    ].
%%
%%
%%verify(#mail_sys_cfg{id = Id, expirt_day = ExpirtDay, title = Title, content = Content}) ->
%%    ?check(com_util:is_valid_uint8(ExpirtDay), "mail_sys.txt id(~w) expirt_day (~w) is error!", [Id, ExpirtDay]),
%%    ?check(erlang:is_binary(Title), "mail_sys.txt id(~w) title(~s) is error!", [Id, Title]),
%%    ?check(erlang:is_binary(Content), "mail_sys.txt id(~w) content(~s) is error!", [Id, Content]),
%%    ok;
%%verify(_R) ->
%%    ?ERROR_LOG("item ~p 无效格式", [_R]),
%%    exit(bad).


email_build(Bid, 1, IL) ->
    case entity_factory:build(Bid, 1, [], ?FLOW_REASON_MAIL) of
        {ok, _Error} ->
            IL;
        {error, _Error} ->
            % ?ERROR_LOG("send_sysmail Error ~p", [{Error, Bid, Num}]),
            IL;
        ItemL ->
            [ItemL | IL]
    end;

email_build(Bid, Num, IL) ->
    case entity_factory:build(Bid, Num, [], ?FLOW_REASON_MAIL) of
        {ok, _Error} ->
            IL;
        {error, _Error} ->
            % ?ERROR_LOG("send_sysmail Error ~p", [{Error, Bid, Num}]),
            IL;
        ItemL ->
            NIL = [ItemL | IL],
            email_build(Bid, Num - 1, NIL)
    end.

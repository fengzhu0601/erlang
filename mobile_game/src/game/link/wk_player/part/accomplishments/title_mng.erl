-module(title_mng).

%%-include_lib("config/include/config.hrl").

-include("inc.hrl").
-include("player.hrl").
-include("player_mod.hrl").
-include("handle_client.hrl").
-include("title.hrl").
-include("load_cfg_title.hrl").
-define(player_titles_tab, player_titles_tab).

-export([
    add_title/1
    %lookup_global_title/0 %查找
]).

%load_config_meta() ->
%    [
%        #config_meta{record = #title_cfg{},
%            fields = ?record_fields(title_cfg),
%            file = "title.txt",
%            keypos = #title_cfg.id,
%            groups = [#title_cfg.type],
%            verify = fun verify_title_cfg/1}
%    ].
%
%verify_title_cfg(_) -> ok.

create_mod_data(_SelfId) -> ok.

load_mod_data(_PlayerId) ->
    case title_service:get_title(get(?pd_id)) of
        [] ->
            GlobalTitleList = load_cfg_title:lookup_global_title(),
            case lists:member(attr_new:get(?pd_attr_cur_title, -1), GlobalTitleList) of
                true -> 
                    put(?pd_attr_cur_title, 0);
                false -> 
                    ok
            end,
            FunFoldl = fun(GlobalTitleId, TitleList) ->
                case lists:member(GlobalTitleId, TitleList) of
                    true -> 
                        lists:delete(GlobalTitleId, TitleList);
                    false -> 
                        TitleList
                end
            end,
            put(?pd_attr_titles, lists:foldl(FunFoldl, attr_new:get(?pd_attr_titles), GlobalTitleList));
        GlobalTitleList ->
            FunFoldl = fun(GlobalTitleId, TitleList) ->
                case lists:member(GlobalTitleId, TitleList) of
                    true -> 
                        TitleList;
                    false -> 
                        [GlobalTitleId | TitleList]
                end
            end,
            NewTitleList = lists:foldl(FunFoldl, attr_new:get(?pd_attr_titles), GlobalTitleList),
            put(?pd_attr_titles, NewTitleList),
            case lists:member(get(?pd_attr_cur_title), NewTitleList) of
                true -> 
                    ok;
                false -> 
                    put(?pd_attr_cur_title, 0)
            end
    end.

init_client() ->
    ?player_send(titles_sproto:pkg_msg(?PUSH_MSG_TITLE_INFO, {attr_new:get(?pd_attr_cur_title), attr_new:get(?pd_attr_titles)})). % 获取已经得到的称号

view_data(_) -> <<(attr_new:get(?pd_attr_cur_title)):16>>.

online() -> ok.%1.穿上称号 2.称号放在背包

offline(_SelfId) -> ok.
save_data(_) -> ok.
handle_frame(_) -> todo.

handle_msg(_FromMod, {del_old_global_title_id, OldTitleId}) ->
    CurTitle = attr_new:get(?pd_attr_cur_title),
    if
        CurTitle =:= OldTitleId ->
            take_off_title(OldTitleId),
            put(?pd_attr_titles, lists:delete(OldTitleId, attr_new:get(?pd_attr_titles))),
            ?player_send(titles_sproto:pkg_msg(?PUSH_MSG_ADD_TITLE, {?del_title, OldTitleId}));
        true -> ok
    end;

handle_msg(_FromMod, {add_global_title_id, TitleId}) ->
    AllTitles = attr_new:get(?pd_attr_titles),
    case lists:member(TitleId, AllTitles) of
        true -> ok;
        ?false ->
            attr_new:set(?pd_attr_titles, [TitleId | AllTitles]),
            ?player_send(titles_sproto:pkg_msg(?PUSH_MSG_ADD_TITLE, {?add_title, TitleId}))
    end;

handle_msg(_FromMod, {add_rank_title_id, TitleId}) ->
    AllTitles = attr_new:get(?pd_attr_titles),
    case lists:member(TitleId, AllTitles) of
        true -> ok;
        ?false ->
            attr_new:set(?pd_attr_titles, [TitleId | AllTitles]),
            ?player_send(titles_sproto:pkg_msg(?PUSH_MSG_ADD_TITLE, {?add_title, TitleId}))
    end;

handle_msg(_FromMod, _) -> ?err(notmatch).

handle_client({Pack, Arg}) -> handle_client(Pack, Arg).

%% 穿戴称号。 1直接穿上称号。2已经穿上称号替换
handle_client(?MSG_TITLE_CHANGE_TITLE, {TitleId}) ->
    case can_take_tile(TitleId) of
        true ->
            take_title(TitleId),
            %% 穿上称号通知场景进程玩家agent
            get(?pd_scene_pid) ! ?scene_mod_msg(scene_player, {update_agent_info, self(), get(?pd_career), 2, TitleId}),
            ?player_send(titles_sproto:pkg_msg(?MSG_TITLE_CHANGE_TITLE, {get(?pd_attr_cur_title)}));
        false ->
            ?return_err(?ERR_TITLE_NOT_EXIST)
    end;

handle_client(_Msg, _Arg) ->
    {error, unknown_msg}.

%% 完成成就
%% 完成任务
%% 特殊事件（全区第一....）
add_title(TitleId) when TitleId > 0 ->
    NowTitles = get(?pd_attr_titles),
    case lists:member(TitleId, NowTitles) of
        true -> ok;
        false ->
            attr_new:set(?pd_attr_titles, [TitleId | NowTitles]),
            ?player_send(titles_sproto:pkg_msg(?PUSH_MSG_ADD_TITLE, {?add_title, TitleId}))
    end;
add_title(_TitleId) ->
    pass.

%% 能否穿上称号
can_take_tile(TitleId) ->
    case lists:member(TitleId, attr_new:get(?pd_attr_titles)) of
        true -> true;
        _ -> false
    end.

%% 穿上称号
take_title(TitleId) ->
    attr_new:begin_sync_attr(),
    case get(?pd_attr_cur_title) of
        0 -> ok;
        CurTitleId ->
            CurTitleCFG = load_cfg_title:lookup_title_cfg(CurTitleId),
            attr_new:player_sub_attr_by_id(CurTitleCFG#title_cfg.attr_id)
    end,
    TitleCFG = load_cfg_title:lookup_title_cfg(TitleId),
    attr_new:player_add_attr_by_id(TitleCFG#title_cfg.attr_id),
    attr_new:set(?pd_attr_cur_title, TitleId),
    attr_new:end_sync_attr().

take_off_title(TitleId) ->
    attr_new:begin_sync_attr(),
    case TitleId of
        0 -> ok;
        CurTitleId ->
            CurTitleCFG = load_cfg_title:lookup_title_cfg(CurTitleId),
            attr_new:player_sub_attr_by_id(CurTitleCFG#title_cfg.attr_id)
    end,
    attr_new:set(?pd_attr_cur_title, 0),
    attr_new:end_sync_attr().

%lookup_global_title() ->
%    lookup_group_title_cfg(#title_cfg.type, ?global_title_type).

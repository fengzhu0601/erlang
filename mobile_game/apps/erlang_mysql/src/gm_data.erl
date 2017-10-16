-module(gm_data).




-export([
    %get_player_info_by_page/3,
    %get_player_base_info_by_id/1,
    %get_player_freeze_info_by_page/2,
    %get_player_gag_info_by_page/2,
    %get_player_internal_info_by_page/2,
    %get_player_broadcast_info_by_page/2,
    get_broadcast_info/0,
    %get_online_player_count/2,
    %get_online_account_count/2,
    %get_total_pay/2,
    %get_create_player_count/2,
    get_re_account_count/2,
    get_all_player_id/0,
    like/2,
    get_player_id_list/2
]).

% -export([
%     get_platformid_and_worldid/1
% ]).

-include ("gm.hrl").

-define(DEFAULT_PAGE_COUNT, 20).
%% 目前默认只取出30条匹配的数据
-define(SQL_LIKE_DATA(TabName, TabColumnName, Value, Len),
    <<"SELECT * FROM `",TabName/binary,"` WHERE ",TabColumnName/binary," LIKE '%",Value/binary,"%'LIMIT 0, ",Len/binary,";">>).



like(TabName, Value) ->
    like( TabName, Value, 10).

like( TabName, Value, Len ) ->
    TabNameBin = all_to_binary(TabName),
    TabColumnNameBin = all_to_binary(name),
    ValueBin = all_to_binary(Value),
    LenBin = all_to_binary(Len),
    Sql = ?SQL_LIKE_DATA( TabNameBin, TabColumnNameBin, ValueBin, LenBin ),
    D = db_mysql:execute_raw_sql(Sql),
    %io:format("D-----------------:~p~n",[D]),
    D.

all_to_binary( Binary ) when is_binary(Binary) -> Binary;
all_to_binary( Atom ) when is_atom(Atom) -> list_to_binary(atom_to_list( Atom ));
all_to_binary( Str ) when is_list(Str) -> list_to_binary( Str );
all_to_binary( Integer ) when is_integer(Integer) -> integer_to_binary( Integer );
all_to_binary( _Other ) -> <<"arg_error">>.


get_all_player_id() ->
    Sql = "select id from player",
    D = db_mysql:execute_raw_sql(Sql),
    lists:flatten(D).


get_player_id_list(Offset, Count) ->
    Sql = lists:concat(["select id from player order by id limit ",Offset,",",Count]),
    db_mysql:execute_raw_sql(Sql).

% get_platformid_and_worldid(L2) ->
%     RequestData = http_json:encode_molin_data(L2),
%     WorldID = 
%     case lists:keyfind("WorldID", 1, RequestData) of
%         false ->
%             ?WORLD_ID;
%         {_, Wid} ->
%             ?binary_to_int(Wid)
%     end,
%     PlatFormID = 
%     case lists:keyfind("PlatformID", 1, RequestData) of
%         false ->
%             ?PLATFORM_ID;
%         {_, PfId} ->
%             ?binary_to_int(PfId)
%     end,
%     {PlatFormID, WorldID}.

% get_page(Page) when Page >= 0 ->
%     if
%         Page =:= 0; Page =:= 1 ->
%             {0*?DEFAULT_PAGE_COUNT, 1*?DEFAULT_PAGE_COUNT};
%         true ->
%             {(Page - 1)*?DEFAULT_PAGE_COUNT, Page * ?DEFAULT_PAGE_COUNT}
%     end.

% get_player_info_by_page(Page,PlatFormId, WorldId) ->
%     Sql = lists:concat(["select * from player where platform_id=",PlatFormId," and server_id=", WorldId]),
%     {A, B} = get_page(Page),
%     D = db_mysql:select_limit(Sql, A, B),
%     io:format("D--------------------------:~p~n",[D]),
%     D.

% get_player_base_info_by_id(PlayerId) ->
%     case db_mysql:select_row(player, "*", [{player_id, PlayerId}]) of
%         [] ->
%             false;
%         PlayerInfor ->
%             io:format("PlayerInfor--------------------------:~p~n",[PlayerInfor]),
%             PlayerInfor
%     end.

% get_player_freeze_info_by_page(PlatFormId, WorldId) ->
%     case db_mysql:select_row(player_freeze, "*", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
%         [] ->
%             [];
%         [D] ->
%             io:format("freeze--------------------------:~p~n",[D]),
%             D
%     end.


% get_player_gag_info_by_page(PlatFormId, WorldId) ->
%     case db_mysql:select_row(player_jinyan, "*", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
%         [] ->
%             [];
%         [D] ->
%             io:format("player_jinyan--------------------------:~p~n",[D]),
%             D
%     end.

% get_player_internal_info_by_page(PlatFormId, WorldId) ->
%     case db_mysql:select_row(player_neibuzhanghao, "*", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
%         [] ->
%             [];
%         [D] ->
%             io:format("player_neibuzhanghao--------------------------:~p~n",[D]),
%             D
%     end.


% get_player_broadcast_info_by_page(PlatFormId, WorldId) ->
%     case db_mysql:select_row(system_broadcast, "*", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
%         [] ->
%             [];
%         [Count] ->
%             Count
%     end.

get_broadcast_info() ->
    NowTime = com_time:timestamp_sec(),
    Sql = lists:concat(["select * from system_broadcast where ", NowTime, " between start_time and end_time"]),
    D = db_mysql:execute_raw_sql(Sql),
    io:format("get_broadcast_info--------------------------:~p~n",[D]),
    D.

% get_online_player_count(PlatFormId, WorldId) ->
%     case db_mysql:select_row(online_player, "player_count", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
%         [] ->
%             false;
%         [Count] ->
%             io:format("player_count--------------------------:~p~n",[Count]),
%             Count
%     end.
% get_online_account_count(PlatFormId, WorldId) ->
%     case db_mysql:select_row(online_player, "account_count", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
%         [] ->
%             false;
%         [Count] ->
%             io:format("account_count--------------------------:~p~n",[Count]),
%             Count
%     end.

% get_total_pay(PlatFormId, WorldId) ->
%     Sql = lists:concat(["select sum(chongzhi_count) from pay_player where platform_id=",PlatFormId," and server_id=", WorldId]),
%     db_mysql:execute_raw_sql(Sql).

% get_create_player_count(PlatFormId, WorldId) ->
%     case db_mysql:select_row(server_data, "create_player_count", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
%         [] ->
%             false;
%         [Count] ->
%             io:format("create_player_count--------------------------:~p~n",[Count]),
%             Count
%     end.

get_re_account_count(PlatFormId, WorldId) ->
    case db_mysql:select_row(server_data, "re_account_count", [{platform_id, PlatFormId}, {server_id, WorldId}]) of
        [] ->
            false;
        [Count] ->
            io:format("re_account_count--------------------------:~p~n",[Count]),
            Count
    end.
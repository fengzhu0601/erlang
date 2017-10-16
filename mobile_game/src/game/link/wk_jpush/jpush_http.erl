%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 七月 2016 下午5:31
%%%-------------------------------------------------------------------
-module(jpush_http).
-author("fengzhu").

%% API
-export([
    jpush_send/0
    , http_get/1
    , jpush_send_msg/1
]).

-include("inc.hrl").

%% 本地地址
%%-define(AUTH_URL, "http://127.0.0.1/push_example.php").
%%-define(AUTH_URL, "http://192.168.0.254/push_example.php").

%% 内网地址
-define(AUTH_URL, "http://192.168.0.142/jpush_push_PHP_server/push_example.php").

%%-define(AUTH_URL, "http://115.159.144.222/push_example.php").

jpush_send() ->
%%    URL = ?AUTH_URL ++ "?openid=" ++ binary_to_list(Openid) ++ "&token=" ++ binary_to_list(AccessToken),
    URL = get_auth_url(),
    Ret = http_get(URL),%%    Ret = http_get(?AUTH_URL),
%%    ?INFO_LOG("url:~p", [URL]),
    ?INFO_LOG("ret:~p", [Ret]).
%%    list_to_atom(Ret).

%% %% TimeList [[time1,time2,...],[desc1,desc2,...]]
%% jpush_schedule_send(TimeList) ->
%%     _URL = ?AUTH_URL ++ "?timelist=" ++ binary_to_list(TimeList),
%%     ok.

http_get(Url) ->
    %% ErrCode = 200是成功
    httpc:request(get, {Url, []}, [], []).

jpush_send_msg(Msg) ->
    URL = get_auth_url() ++ "?msg=" ++ binary_to_list(unicode:characters_to_binary(Msg)),
    Ret = http_get(URL),
    ?INFO_LOG("ret:~p", [Ret]).

get_auth_url() ->
    Ip = my_ets:get(ip, "127.0.0.1"),
    Url = "http://" ++ Ip ++ "/jpush_push_PHP_server/push_example.php",
    Url.



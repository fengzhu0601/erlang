%%%-------------------------------------------------------------------
%%% @author hank
%%% @copyright (C) 2016, <SANTI>
%%% @doc  qq 接入验证
%%%
%%% @end
%%% Created : 15. Apr 2016 2:59 PM
%%%-------------------------------------------------------------------
-module(auth_qq).
-author("hank").

%% API
-export([auth/5,
    auth2/2,
    http_get/1]).

-include("inc.hrl").


-record(auth_qq_request, {
    appid,
    openid,
    userip = <<"">>,
    openkey
}).

-define(AUTH_QQ_URL, "http://msdktest.qq.com/auth/verify_login/?").

-define(AUTH_URL, "http://115.159.144.222/auth_qq_state.php").

%
% doc http://wiki.dev.4g.qq.com/v2/ZH_CN/router/index.html#!index.md#1.概述
%
auth(Appid, AppKey, AccessToken, Openid, IP) ->
%%    Appid = "100703379",
%%    AppKey = "4578e54fb3a1bd18e0681bc1c734514e",
%%    AccessToken = "977B5EA1393844F3F7D718394BEFF3FF",
%%    Openid = "0436D81315D5A58138FC861CEEB51CA8",

    Ts = com_time:timestamp_sec(),

    Sig = com_md5:md5(AppKey ++ integer_to_list(Ts)),

    Para = "timestamp=" ++ integer_to_list(Ts) ++ "&appid="
        ++ Appid ++ "&sig=" ++ Sig ++ "&openid=" ++ Openid ++ "&encode=1",

    Body = #auth_qq_request{appid = list_to_binary(Appid),
        openid = list_to_binary(Openid),
        openkey = list_to_binary(AccessToken),
        userip = list_to_binary(IP)},

    PostJson = rfc4627:from_record(Body, auth_qq_request, record_info(fields, auth_qq_request)),

    URL = ?AUTH_QQ_URL ++ Para,

    ?INFO_LOG("body:~p, request:~p", [rfc4627:encode(PostJson), URL]),

    Ret = http_post(URL, rfc4627:encode(PostJson)),

    {ok, Result, _} = rfc4627:decode(Ret),
    % sucess "{ "msg" : "..." , "ret":0 }" error ret : -xxx
    ?INFO_LOG("ret:~p, ~p ", [Ret, rfc4627:get_field(Result, "ret")]),
    case rfc4627:get_field(Result, "ret") of
        {ok, 0} ->
            ok;
        _ -> error
    end.



http_post(Url, Body) ->
    {ok, {{NewVersion, 200, NewReasonPhrase}, NewHeaders, NewBody}} =
        httpc:request(post, {Url, [], [], Body}, [], []),
    NewBody.


auth2(Openid, AccessToken) ->
%%    Openid = "0436D81315D5A58138FC861CEEB51CA8",
%%    AccessToken = "977B5EA1393844F3F7D718394BEFF3FF",
    URL = ?AUTH_URL ++ "?openid=" ++ binary_to_list(Openid) ++ "&token=" ++ binary_to_list(AccessToken),
    Ret = http_get(URL),
    ?INFO_LOG("url:~p", [URL]),
    ?INFO_LOG("ret:~p", [Ret]),
    list_to_atom(Ret).

http_get(Url) ->
    {ok, {{_NewVersion, 200, _NewReasonPhrase}, _NewHeaders, NewBody}} =
        httpc:request(get, {Url, []}, [], []),
    NewBody.




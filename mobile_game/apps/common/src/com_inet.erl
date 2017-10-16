%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 网络有关函数
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_inet).
-export([get_addr/1,
         get_addr_str/1,
         get_addr_str/0
        ]).

%% lo, eth0
%%
-spec get_addr(string()) -> none |  inte:ip_address().
get_addr(Interface) when is_list(Interface) ->
    case inet:getifaddrs() of
        {ok, Interfaces} ->
            case proplists:get_value(Interface, Interfaces, none) of
                none -> none;
                Info ->
                    proplists:get_value(addr, Info)
            end
    end.

get_addr_str(Interface) ->
    case get_addr(Interface) of
        none ->
            none;
        Addr ->
            inet_parse:ntoa(Addr)
    end.

%% 默认是主机的外网地址
get_addr_str() ->
    case inet:getif() of
        {'error', _} ->
            none;
        {ok, XX} ->
            {Ip, _, _} = hd(XX),
            inet_parse:ntoa(Ip)
    end.

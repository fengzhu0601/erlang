%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(lc_listener_sup).

-behaviour(supervisor).

%% API.
-export([start_listener/5,
         stop_listener/1]).

%% Internal
-export([start_link/1]).

%% supervisor.
-export([init/1]).

-include("../../common/include/com_log.hrl").

-export_type([new_socket_owner/0]).
%% 返回新socket  controlling_process 的进程pid
-type new_socket_owner() :: fun((port()) -> {ok, pid()}).

-record(info, {ref,
               n_acc,
               port,
               opts,
               func }).

%% @doc 开启一个监听进程组.
-spec start_listener(atom(),
                     non_neg_integer(),
                     net:port_number(),
                     gen_tcp:listen_option(),
                     new_socket_owner()
                    ) -> {ok, pid()}.
start_listener(Ref, NbAcceptors, Port, TCPOptions, Func) ->
    {ok, _Pid}=supervisor:start_child(lc_sup,
                                      {{lc_sup,Ref},
                                       {?MODULE, start_link, [#info{ref=Ref,
                                                                    n_acc=NbAcceptors,
                                                                    port=Port,
                                                                    opts=TCPOptions,
                                                                    func=Func}]},
                                       transient,
                                       5,
                                       supervisor,
                                       [?MODULE]
                                      }).

%% @doc Stop a listener identified by Ref
%% Note that stopping the listener will close all currently running.
-spec stop_listener(atom()) -> ok | {error, not_found}.
stop_listener(Ref) ->
    case supervisor:terminate_child(lc_sup, {lc_sup, Ref}) of
        ok ->
            _ = supervisor:delete_child(lc_sup, {lc_sup, Ref});
        {error, Reason} ->
            {error, Reason}
    end.


start_link(Info=#info{}) ->
    supervisor:start_link({local,Info#info.ref},?MODULE, Info).

%% supervisor.
init(#info{ref=Ref, n_acc=NbAcceptors, port=Port, opts=TCPOptions, func=Func}) ->
    {ok, LSocket} = gen_tcp:listen(Port, TCPOptions),
    ?INFO_LOG("~p Listening port [~p] open [~p] acceptors", [Ref, Port, NbAcceptors]),
    Procs=
        [{{acceptor, Ref, N},
          {lc_acceptor, start_link, [LSocket, Func]},
          permanent,
          brutal_kill,
          worker,
          []} || N <- lists:seq(1, NbAcceptors)],
    {ok, {{one_for_one, 5, 5}, Procs}}.

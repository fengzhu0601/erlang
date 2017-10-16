%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 十月 2015 下午3:01
%%%-------------------------------------------------------------------
-module(event_server).
-author("clark").


-behaviour(gen_server).

%% API
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([
    start_link/1,
    start_link/2,
    sub_info/2,
    unsub_info/1,
    sub_call/2,
    unsub_call/1,
    sub_terminate/1,
    unsub_terminate/0
]).


-include("event_server.hrl").


-define(call_evt(EvtID),        {'@call_evt@', EvtID}).
-define(cast_evt(EvtID),        {'@cast_evt@', EvtID}).
-define(info_evt(EvtID),        {'@info_evt@', EvtID}).
-define(terminate_evt(EvtID),   {'@terminate_evt@', EvtID}).
-define(code_change_evt(EvtID), {'@code_change_evt@', EvtID}).


start_link({Name, Mod, CfgArgs}, DynamicArgs) ->
    gen_server:start_link({local, Name}, ?MODULE, [Mod, CfgArgs, DynamicArgs], []).

start_link({Name, Mod, CfgArgs}) ->
    gen_server:start_link({local, Name}, ?MODULE, [Mod, CfgArgs], []).

init([Mod, CfgArgs]) ->
    Mod:init(CfgArgs);
init([Mod, CfgArgs, DynamicArgs]) ->
    Mod:init(CfgArgs, DynamicArgs).

sub_info(EvtID, {Mod, Callback}) ->
    case erlang:get(?info_evt(EvtID)) of
        undefined ->
            erlang:put(?info_evt(EvtID), {Mod, Callback});
        _ ->
            erlang:put(?info_evt(EvtID), {Mod, Callback})
    end.
unsub_info(EvtID) ->
    erlang:put(?info_evt(EvtID), undefined).



sub_call(EvtID, {Mod, Callback}) ->
    case erlang:get(?call_evt(EvtID)) of
        undefined ->
            erlang:put(?call_evt(EvtID), {Mod, Callback});
        _ ->
            erlang:put(?call_evt(EvtID), {Mod, Callback})
    end.
unsub_call(EvtID) ->
    erlang:put(?call_evt(EvtID), undefined).



sub_terminate({Mod, Callback}) ->
    case erlang:get(?terminate_evt(1)) of
        undefined ->
            erlang:put(?terminate_evt(1), {Mod, Callback});
        _ ->
            erlang:put(?terminate_evt(1), {Mod, Callback})
    end.
unsub_terminate() ->
    erlang:put(?terminate_evt(1), undefined).




%% ---------------------------------------------
%% protected
%% ---------------------------------------------
handle_call({EvtID, Args}, From, State) ->
    case erlang:get(?call_evt(EvtID)) of
        {Mod, Call} ->
            Mod:Call(Args, From, State);
        _ ->
            ?call_reply({ok, nil}, State)
    end;
handle_call(Request, From, State) ->
    ?call_reply(ok, State).



handle_info({EvtID, Args}, State) ->
    case erlang:get(?info_evt(EvtID)) of
        {Mod, Call} ->
            Mod:Call(Args, State);
        _ ->
            ?info_noreply(State)
    end;
handle_info(Info, State) ->
    ?info_noreply(State).




terminate(Reason, State) ->
    case erlang:get(?terminate_evt(1)) of
        {Mod, Call} ->
            Mod:Call(Reason, State);
        _ ->
            ok
    end,
    ok.




code_change(OldVsn, State, Extra) ->
    {ok, State}.



handle_cast(_Request, State) ->
    ?cast_noreply(State).



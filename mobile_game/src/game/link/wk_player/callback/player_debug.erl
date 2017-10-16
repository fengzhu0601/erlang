%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(player_debug).

%% callback from player_eng
-export([call/2]).

-include("inc.hrl").
-include("player.hrl").


%% CTX
-record(?MODULE, {pid
}).

-define(CTX, ?MODULE).

%% debug
-export([
    attach/1,
    show_pd/0,
    show_pd/1,
    %%show_pd_pid/1,
    %%show_pd_pid/2,
    apply/3,
    h/0
]).


%% @doc for debug get a process context
attach(IdOrList) ->
    case get_pid(IdOrList) of
        ?nonproc ->
            ?nonproc;
        Pid ->
            put(debug_ctx, #?CTX{pid = Pid}),
            ok
    end.

%% @doc show help info
h() ->
    io:format(
        "~n ================ player_debug help info ===================~n"
        "you can call the cmd/3 exec a debug cmd ~n"
        "command list~n"
        "[1] show_pd~n"
        "\t args: none for all process_dict, or a process_dict name~n"
        "\t e.g. Ctx:cmd(1). cmd(show_pd). cmd(1, pd_id, Ctx)~n"
        "[2] call~n"
        "\t args: FMA~n"
        "\t e.g. Ctx:cmd(2, [F,M,A], Ctx). ~n"
        "~n", []).

show_pd() -> show_pd(all).
show_pd(Key) -> send_msg(show_pd, Key).


%%show_pd_pid(Pid) ->
%%show_pd_pid(Pid, all).


apply(M, F, A) ->
    send_msg(apply, [M, F, A]).


get_pid(Id) when is_list(Id) ->
    Pid = erlang:list_to_pid(Id),
    case erlang:is_process_alive(Pid) of
        false -> nonproc;
        true -> Pid
    end;
get_pid(Id) when is_integer(Id) ->
    case world:get_player_pid(Id) of
        ?none ->
            nonproc;
        Pid ->
            Pid
    end.

send_msg(Cmd, Arg) ->
    case get(debug_ctx) of
        ?undefined ->
            io:format("you must call attack/1 first!");
        #?CTX{pid = Pid} ->
            gen_server:call(Pid, {debug_msg, Cmd, Arg})
    end.


call(show_pd, Arg) ->
    case Arg of
        all ->
            erlang:get();
        Key ->
            erlang:get(Key)
    end;

call(apply, [M, F, A]) ->
    com_util:safe_apply(M, F, A);

call(Cmd, Args) ->
    ?ERROR_LOG("unkonw deubg cmd ~p args ~p", [Cmd, Args]),
    ok.


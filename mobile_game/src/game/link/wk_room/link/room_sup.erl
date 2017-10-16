-module(room_sup).
-behaviour(supervisor).
-author("clark").

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------
-export
([
    init/1
    , terminate/2
]).




%% ===================================================================
%% Supervisor callbacks
%% ===================================================================
init([_RootArgs, _RunArgs]) ->
    io:format("=============== my_sup init ~p ~p ===============~n", [_RootArgs, _RunArgs]),
    {
        ok,
        {
            {simple_one_for_one, 5, 10},
            [
                otp_util:com_wk_link_declaration(room_scene, [])
            ]
        }
    }.

terminate(_Reason, _State) ->
    ok.





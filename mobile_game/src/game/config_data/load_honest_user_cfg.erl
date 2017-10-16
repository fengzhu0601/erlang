-module(load_honest_user_cfg).

%% API
-export([
   
]).

-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_honest_user_cfg.hrl").

load_config_meta() ->
    [
        #config_meta{
            record = #honest_user_cfg{},
            fields = ?record_fields(honest_user_cfg),
            file = "honest_user.txt",
            keypos = #honest_user_cfg.id,
            verify = fun verify_phase_ac/1
        }
    ].


verify_phase_ac(
    #honest_user_cfg{
        id = Id
        % prize_test1 = PT1,
        % prize_test2 = PT2,
        % prize_test3 = PT3
    }) ->
    ?check(Id > 0, "task.txt [~p] id  无效!", [Id]),
    % ?check(prize:is_exist_prize_cfg(PT1), "task.txt中， [~p] prize: ~p 配置无效。", [Id, PT1]),
    % ?check(prize:is_exist_prize_cfg(PT2), "task.txt中， [~p] prize: ~p 配置无效。", [Id, PT2]),
    % ?check(prize:is_exist_prize_cfg(PT3), "task.txt中， [~p] prize: ~p 配置无效。", [Id, PT3]),
    ok.
-module(com_mod_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).


%% Supervisor callbacks
-export([init/1]).


-include("event_server.hrl").


start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).


%% @doc 开启各个功能模块
init([]) ->
    {
        ok,
        {
            {one_for_one, 1, 2},
            [
                ?CHILD(safe_ets, worker, [])
                , ?CHILD(com_prog, worker, [])
                , ?CHILD(world, worker, [])                 % depend prog
                %, ?CHILD(timer_manager, worker, [])         % 活动管理器
                , ?CHILD(timer_trigger_server, worker, [])
                , ?CHILD(double_prize_server, worker, [])
                %, ?CHILD(mall_server, worker, [])
                , ?CHILD(main_instance_rank_server, worker, [])
                , ?CHILD(team_svr, worker, [])
%%                , ?CHILD(jpush_service, worker, [])

                ,{ jpush_service, {jpush_service, start_link, []}, temporary, 2000, worker, [jpush_service]
    }
                , ?CHILD(team_server, worker, [])
                , ?CHILD(arena_server, worker, [])
                , ?CHILD_WORKER(event_server, server_res_eng, server_res_eng, [])
                , ?CHILD(auction_new_svr, worker, [])
                , ?CHILD(friend_gift_svr, worker, [])
                , ?CHILD(ranking_lib, worker, [])
                , ?CHILD(card_svr, worker, [])
                , ?CHILD(guild_service, worker, [])         %公会公共数据
                %, ?CHILD(pet_global_server, worker, [])     %宠物公共模块，维护变成宠物蛋的数据
                , ?CHILD(camp_service, worker, [])          %神魔系统公共数据
                , ?CHILD(sky_service, worker, [])           %天空之城公共数据
                , ?CHILD(title_service, worker, [])         %维护公共称号
                % , ?CHILD(bounty_server, worker, [])         %赏金任务数据
                , ?CHILD(abyss_server, worker, [])          %虚空深渊排行奖励
                , ?CHILD(impact_ranking_list_service, worker, [])          %开服冲榜数据
                , ?CHILD(player_log_service, worker, [])    %玩家进程crash日志存储
                , ?CHILD(msg_service, worker, [])
                , ?CHILD(payment_confirm, worker, [])
                , ?CHILD(nine_lottery_server, worker, [])
                %, ?CHILD(gwgc_server, worker, [])
                , ?CHILD_WORKER(event_server, info_log, info_log, [])
                , ?CHILD(guild_mining_server, worker, [])      %公会挖矿
                % , ?CHILD_WORKER(event_server, mobile_link, mobile_link, [])
            ]
        }
    }.

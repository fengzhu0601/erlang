%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 六月 2015 下午6:30
%%%-------------------------------------------------------------------
-module(load_cfg_guild_boss).
-author("clark").

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("item.hrl").
-include("load_cfg_guild_boss.hrl").



%% API
-export
([
    lookup/2
    , get_monster_id/1
    , get_next_record_id/1
    , get_monster_hp/1
    , get_donate_consume/1
    , get_advance_consume/1
    , get_next_exp/1
    , get_call_consume/1
    , get_uplvl_boss/2
    , get_revive_consume/1
    , get_sort_prize/2
    , get_kill_prize/1
    , get_first_kill_prize/1
    , get_monster_dt/1
    , get_monster_immo_exp/1
    , get_boss_exist_broadcast/1
]).






load_config_meta() ->
    [
        #config_meta
        {
            record = #society_misc_cfg{},
            fields = record_info(fields, society_misc_cfg),
            file = "society_misc.txt",
            keypos = #society_misc_cfg.id,
            verify = fun verify/1
        },

        #config_meta
        {
            record = #guild_boss_cfg{},
            fields = record_info(fields, guild_boss_cfg),
            file = "guild_boss.txt",
            keypos = #guild_boss_cfg.id,
            verify = fun verify/1
        },

        #config_meta
        {
            record = #guild_boss_sort_prize_cfg{},
            fields = record_info(fields, guild_boss_sort_prize_cfg),
            file = "guild_boss_sort_prize.txt",
            keypos = #guild_boss_sort_prize_cfg.id,
            all = [#guild_boss_sort_prize_cfg.id],
            verify = fun verify/1
        }
    ].


% -define(guild_boss_prize(RecordId), {"@guild_boss_prize@", RecordId}).





verify(#society_misc_cfg{id = _Id}) ->
    ok;

verify(#guild_boss_cfg{id = Id, guild_prize = GPrizeId, kill_prize = KPrizeId, first_kill_prize = FKPrizeId, advance_consume = _AC}) ->
%%     io:format("------------------------ guild_boss_cfg ~p ------------------------~n", [Id]),
    ?check(prize:is_exist_prize_cfg(GPrizeId) orelse GPrizeId =:= 0, "guild_boss_cfg.txt id[~w] guild_prize 无效! ", [Id]),
    ?check(prize:is_exist_prize_cfg(KPrizeId) orelse KPrizeId =:= 0, "guild_boss_cfg.txt id[~w] kill_prize 无效! ", [Id]),
    ?check(prize:is_exist_prize_cfg(FKPrizeId) orelse FKPrizeId =:= 0, "guild_boss_cfg.txt id[~w] first_kill_prize无效! ", [Id]),
%%     ?check(cost:is_exist_cost_cfg(AC), "guild_boss_cfg.txt id[~w] advance_consume! ", [Id]),
    ok;

verify(#guild_boss_sort_prize_cfg{bossid = RecordId, rank_num = _RN, prize = Prize}) ->
    ?check(prize:is_exist_prize_cfg(Prize) orelse Prize =:= 0, "guild_boss_sort_prize_cfg.txt id[~w] guild_prize 无效! ", [RecordId]),
    % case my_ets:get(?guild_boss_prize(RecordId), []) of
    %     [] ->
    %         my_ets:set(?guild_boss_prize(RecordId), [{RN, Prize}]);

    %     List ->
    %         List1 = [{RN, Prize} | List],
    %         my_ets:set(?guild_boss_prize(RecordId), List1)
    % end,
    ok;

verify(_) ->
    ok.


%% --------------------------------
lookup(Id, Default) ->
    case lookup_society_misc_cfg(Id) of
        #society_misc_cfg{data = D} -> D;
        _ -> Default
    end.

get_monster_immo_exp(RecordId) ->
    case lookup_guild_boss_cfg(RecordId) of
        #guild_boss_cfg{immo_exp = Dt} -> Dt;
        _ -> 0
    end.

get_monster_dt(RecordId) ->
    case lookup_guild_boss_cfg(RecordId) of
        #guild_boss_cfg{challenge_time = Dt} -> Dt;
        _ -> 0
    end.

get_monster_id(RecordId) ->
    case lookup_guild_boss_cfg(RecordId) of
        #guild_boss_cfg{monsterid = Id} -> Id;
        _ -> 0
    end.

get_donate_consume(_RecordId) ->
    Tmp = load_cfg_guild_boss:lookup(immo_consume, 0),
    ?INFO_LOG("get_donate_consume ~p", [Tmp]),
    case Tmp of
        0 -> ret:error(not_found_cost);
        CostID -> load_cost:get_cost_list(CostID)
    end.

get_advance_consume(RecordId) ->
    case lookup_guild_boss_cfg(RecordId) of
        #guild_boss_cfg{advance_consume = CostID} -> load_cost:get_cost_list(CostID);
        _ -> ret:error(not_found_cost)
    end.

get_call_consume(_RecordId) ->
    Tmp = load_cfg_guild_boss:lookup(summon_consume, 0),
    ?INFO_LOG("get_call_consume ~p", [Tmp]),
    case Tmp of
        0 -> ret:error(not_found_cost);
        CostID -> load_cost:get_cost_list(CostID)
    end.

get_revive_consume(_RecordId) ->
    Tmp = load_cfg_guild_boss:lookup(revive_consume, 0),
    ?INFO_LOG("get_call_consume ~p", [Tmp]),
    case Tmp of
        0 -> ret:error(not_found_cost);
        CostID -> load_cost:get_cost_list(CostID)
    end.

get_next_record_id(RecordId) ->
    case lookup_guild_boss_cfg(RecordId) of
        #guild_boss_cfg{advance_monster = Id} -> Id;
        _ -> 0
    end.

get_next_exp(RecordId) ->
    case lookup_guild_boss_cfg(RecordId) of
        #guild_boss_cfg{exp = Exp} -> Exp;
        _ -> 9999999999
    end.

get_monster_hp(RecordId) ->
    MonsterId = get_monster_id(RecordId),
    case load_scene_monster:get_monster_hp(MonsterId) of
        Hp when is_integer(Hp) -> Hp;
        _ -> 0
    end.
    % case get_monster_id(RecordId) of
    %     MonsterId -> load_scene_monster:get_monster_hp(MonsterId);
    %     _ -> 0
    % end.



get_uplvl_boss(RecordId, Dt) ->
    case lookup_guild_boss_cfg(RecordId) of
        #guild_boss_cfg{levelup_time = MstList} ->
            lists:foldl
            (
                fun
                    ({DtCfg, MonsterId}, Ret) ->
                        if
                            Dt =< DtCfg ->
                                MonsterId;
                            true ->
                                Ret
                        end
                end,
                0,
                MstList
            );
        _ ->
            0
    end.

get_kill_prize(RecordId) ->
    case lookup_guild_boss_cfg(RecordId) of
        #guild_boss_cfg{kill_prize = KillPrizeId} ->
            {ok, PrizeList} = prize:get_prize(KillPrizeId),
            PrizeList;

        _ ->
            []
    end.

get_first_kill_prize(RecordId) ->
    case lookup_guild_boss_cfg(RecordId) of
        #guild_boss_cfg{first_kill_prize = FirstKillPrizeId} ->
            {ok, PrizeList} = prize:get_prize(FirstKillPrizeId),
            PrizeList;

        _ ->
            []
    end.

get_sort_prize(RecordId, Sort) ->
    {PrizeId, _} = lists:foldl(
        fun(Id, {TempPrize, IsEnd}) ->
                case IsEnd of
                    true ->
                        {TempPrize, IsEnd};
                    _ ->
                        case lookup_guild_boss_sort_prize_cfg(Id) of
                            #guild_boss_sort_prize_cfg{bossid = BossId, rank_num = [Min, Max], prize = Prize} ->
                                case BossId =:= RecordId andalso Sort >= Min andalso Sort =< Max of
                                    true ->
                                        {Prize, true};
                                    _ ->
                                        {TempPrize, false}
                                end;
                            _ ->
                                {TempPrize, false}
                        end
                end
        end,
        {0, false},
        lookup_all_guild_boss_sort_prize_cfg(#guild_boss_sort_prize_cfg.id)
    ),
    {ok, PrizeList} = prize:get_prize(PrizeId),
    %% ?INFO_LOG("PrizeId:~p, PrizeList:~p", [PrizeId, PrizeList]),
    % List = my_ets:get(?guild_boss_prize(RecordId), []),
    % PrizeId = lists:foldl
    %     (fun({[Min, Max], CurPrizeId}, RetPrizeId) ->
    %             if
    %                 0 =/= RetPrizeId ->
    %                     RetPrizeId;
    %                 true ->
    %                     if
    %                         Sort >= Min andalso Sort =< Max -> CurPrizeId;
    %                         true -> RetPrizeId
    %                     end
    %             end
    %         end,
    %         0,
    %         List
    %     ),
    % ?INFO_LOG("PrizeId ~p", [PrizeId]),
    % {ok, PrizeList} = prize:get_prize(PrizeId),
    PrizeList.


get_boss_exist_broadcast(Num) ->
    case lookup(boss_broadcast, 0) of
        0 -> nil;
        TimeList ->
            Len = erlang:length(TimeList),
            if
                Num > Len -> nil;
                true ->lists:nth(Num, TimeList)
            end
    end.
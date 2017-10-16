-module(load_double_prize).

%% API
-export([
    get_double_type_and_fanbei/1,
    get_double_prize_activity_end_time/2,
    get_double_prize_xun_huan_time/1,
    get_double_type_and_fanbei_of_arean/1
]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_double_prize_cfg.hrl").

% get_start_activity_time_by_id(ActivityId) ->
%     case lookup_double_prize_cfg(ActivityId) of
%         ?none ->
%             0;
%         #double_prize_cfg{yugao_activity = T1, start_activity=T2} ->
%             CurWeekDay = com_time:day_of_the_week(),
%             case lists:keyfind(CurWeekDay, 1, L) of
%                 ?false ->
%                     1;
%                 {_, D} ->
%                     case lists:keyfind(0, 1, D) of
%                         ?false ->
%                             1;
%                         {_, B} ->
%                             B
%                     end
%             end
%     end.

get_double_prize_activity_end_time(ActivityId, Week) ->
    case lookup_double_prize_cfg(ActivityId) of
        ?none ->
            ?none;
        #double_prize_cfg{end_activity = L} ->
            case lists:keyfind(Week, 1, L) of
                false ->
                    ?none;
                {_,H,M,S,_} ->
                    {H,M,S}
            end
    end.

get_double_prize_xun_huan_time(ActivityId) ->
    case lookup_double_prize_cfg(ActivityId) of
        #double_prize_cfg{circulation_time = T} when T > 0 ->
            T;
        _ ->
            ?none
    end.


get_double_type_and_fanbei_of_arean(ActivityId) ->
    case lookup_double_prize_cfg(ActivityId) of
        ?none ->
            1;
        #double_prize_cfg{double_type_and_fanbei = L} ->
            CurWeekDay = com_time:day_of_the_week(),
            case lists:keyfind(CurWeekDay, 1, L) of
                ?false ->
                    1;
                {_, D} ->
                    case lists:keyfind(0, 1, D) of
                        ?false ->
                            1;
                        {_, B} ->
                            B
                    end
            end
    end.

get_double_type_and_fanbei(ActivityId) ->
    ?DEBUG_LOG("1-----------------------------"),
    case lookup_double_prize_cfg(ActivityId) of
        ?none ->
            ?none;
        #double_prize_cfg{double_type_and_fanbei = L} ->
            CurWeekDay = com_time:day_of_the_week(),
            case lists:keyfind(CurWeekDay, 1, L) of
                ?false ->
                    ?none;
                {_, D} ->
                    D
            end
    end.


load_config_meta() ->
    [
        #config_meta{
            record = #double_prize_cfg{},
            fields = ?record_fields(double_prize_cfg),
            file = "double_prize.txt",
            keypos = #double_prize_cfg.id,
            verify = fun verify/1}
    ].


verify(#double_prize_cfg{id = Id, double_activity_id = DoubleActivityId, double_type_and_fanbei = Dtaf}) ->
    ?check(DoubleActivityId > 0, "double_prize.txt中， [~p] double_activity_id~p 配置无效。", [Id, DoubleActivityId]),
    ?check(is_list(Dtaf), "double_prize.txt中， [~p] double_type_and_fanbei~p 配置无效。", [Id, Dtaf]),
    ok.
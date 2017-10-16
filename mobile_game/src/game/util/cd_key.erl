%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 八月 2016 下午2:17
%%%-------------------------------------------------------------------
-module(cd_key).
-author("fengzhu").

-include("load_cfg_cd_key_rule.hrl").

%% API
-export([
    generate_cd_key/0
    , get_rule_list/1
    , generate_string/3
    , generate_cd_key/1
]).

%% 生成一个CD-KEY
generate_cd_key() ->
    All_parts = load_cfg_cd_key_rule:get_all_cd_key_rule_id(), %% [1,2,3]
    CD_KEY =
        lists:foldl(
            fun(Part, Acc)->
                #cd_key_rule{length = Length, range = Range} = load_cfg_cd_key_rule:lookup_cd_key_rule(Part),
                RuleList = get_rule_list(Range),
                Str = generate_string(RuleList, Length, []),
                Acc ++ Str
            end,
            [],
            All_parts
        ),
    Key = lists:concat(CD_KEY),
    Time = calendar:datetime_to_gregorian_seconds(calendar:universal_time())-719528*24*3600,
    Time16 = erlang:integer_to_list(Time, 16),
    lists:append(Key, Time16).

generate_cd_key(X) ->
    All_parts = load_cfg_cd_key_rule:get_all_cd_key_rule_id(), %% [1,2,3]
    CD_KEY =
        lists:foldl(
            fun(Part, Acc)->
                #cd_key_rule{length = Length, range = Range} = load_cfg_cd_key_rule:lookup_cd_key_rule(Part),
                RuleList = get_rule_list(Range),
                Str = generate_string(RuleList, Length, []),
                Acc ++ Str
            end,
            [],
            All_parts
        ),
    Key = lists:concat(CD_KEY),
    Time = calendar:datetime_to_gregorian_seconds(calendar:universal_time())-719528*24*3600,
    Time16 = erlang:integer_to_list(Time, 16),
    NewTime16 = lists:append(erlang:integer_to_list(X, 16), lists:sublist(Time16,2,erlang:length(Time16)-1)),
    lists:append(Key, NewTime16).

%% 随机生成一个字符串
generate_string(_RuleList, Length, Result) when Length =:= 0 ->
    Result;

generate_string(RuleList, Length, Result) ->
    Index = random:uniform(length(RuleList)),
    Element = lists:nth(Index, RuleList),
    generate_string(RuleList, Length - 1, Result ++ [Element] ).

%% 设置随机库
get_rule_list(Range) ->
    lists:foldr(
        fun(Key, Acc) ->
            case Key of
                ?range1 ->
                    lists:append(?Sa_z, Acc);
                ?range2 ->
                    lists:append(?SA_Z, Acc);
                ?range3 ->
                    lists:append(?S0_9, Acc);
                _ ->
                    Acc
            end
        end,
        [],
        Range
    ).


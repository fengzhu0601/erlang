%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 八月 2016 下午3:03
%%%-------------------------------------------------------------------
-module(load_cfg_cd_key_rule).
-author("fengzhu").


-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_cd_key_rule.hrl").

%% API
-export([
    get_all_cd_key_rule_id/0
    , get_all_cd_key_pt_id/0
    , create_cd_key_by_config/0
    , create_cd_key_by_config/1
    , spawn_create_cd_key_by_config/1
]).

load_config_meta() ->
    [
        #config_meta{record = #cd_key_rule{},
            fields = ?record_fields(cd_key_rule),
            file = "cd_key_rule.txt",
            keypos = #cd_key_rule.id,
            all = [#cd_key_rule.id],
            verify = fun verify_cd_key_rule/1},

        #config_meta{record = #cd_key_pt{},
            fields = ?record_fields(cd_key_pt),
            file = "cd_key_pt.txt",
            keypos = #cd_key_pt.id,
            all = [#cd_key_pt.id],
            verify = fun verify_cd_key_pt/1}
    ].

verify_cd_key_rule(#cd_key_rule{id = Id, length = Length, range = Range}) ->
    ?check(is_integer(Id), "cd_key_rule.txt id[~w] 无效! ", [Id]),
    ?check(is_integer(Length), "cd_key_rule.txt length[~w] 无效! ", [Length]),
    ?check(is_list(Range), "cd_key_rule.txt range[~w] 无效! ", [Range]).

verify_cd_key_pt(#cd_key_pt{id = Id, platform = Platform, server = Server, duration = Duration, prize_id = PrizeId, usetimes = UseTimes, type = Type, sum = Sum}) ->
    ?check(is_integer(Id), "cd_key_pt.txt id[~w] 无效! ", [Id]),
    ?check(is_integer(Platform), "cd_key_pt.txt platform[~w] 无效! ", [Platform]),
    ?check(is_integer(Server), "cd_key_pt.txt server[~w] 无效! ", [Server]),
    ?check(is_integer(Duration), "cd_key_pt.txt duration[~w] 无效! ", [Duration]),
    ?check(is_integer(PrizeId), "cd_key_pt.txt prizeId[~w] 无效! ", [PrizeId]),
    ?check(is_integer(UseTimes), "cd_key_pt.txt usetimes[~w] 无效! ", [UseTimes]),
    ?check(is_integer(Type), "cd_key_pt.txt type[~w] 无效! ", [Type]),
    ?check(is_integer(Sum), "cd_key_pt.txt sum[~w] 无效! ", [Sum]).


get_all_cd_key_rule_id() ->
    lookup_all_cd_key_rule(#cd_key_rule.id).

get_all_cd_key_pt_id() ->
    lookup_all_cd_key_pt(#cd_key_pt.id).

create_cd_key_by_config() ->
    IdList = get_all_cd_key_pt_id(),
    lists:foreach(
        fun(PtId) ->
            #cd_key_pt{id = _Id, platform = Platform, server = Server, duration = Duration, prize_id = PrizeId, usetimes = UseTimes, type = Type, sum = Sum} = lookup_cd_key_pt(PtId),
            op_player:create_new_cd_key_to_mysql(Platform,Server,Duration,PrizeId,UseTimes, Type,Sum)
        end,
        IdList
    ).
create_cd_key_by_config(PtId) ->
    #cd_key_pt{id = _Id, platform = Platform, server = Server, duration = Duration, prize_id = PrizeId, usetimes = UseTimes, type = Type, sum = Sum} = lookup_cd_key_pt(PtId),
    op_player:create_new_cd_key_to_mysql(Platform,Server,Duration,PrizeId,UseTimes, Type,Sum).

spawn_create_cd_key_by_config(PtId) ->
    #cd_key_pt{id = _Id, platform = Platform, server = Server, duration = Duration, prize_id = PrizeId, usetimes = UseTimes, type = Type, sum = Sum} = lookup_cd_key_pt(PtId),
    if
        Sum > 1000 ->
            NewSum = Sum div 1000,
            [spawn( fun() -> op_player:create_new_cd_key_to_mysql(Platform,Server,Duration,PrizeId,UseTimes, Type,1000, X) end)
                || X <- lists:seq(1, NewSum)];
        true ->
            spawn( fun() -> op_player:create_new_cd_key_to_mysql(Platform,Server,Duration,PrizeId,UseTimes, Type,Sum) end )
    end.

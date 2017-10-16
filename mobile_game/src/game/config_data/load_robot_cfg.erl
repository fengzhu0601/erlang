%%%-------------------------------------------------------------------
%%% @author dsl
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(load_robot_cfg).

%% API
-export([
	get_robot_list/0,
    get_robot_cfg_level/1,
    get_robot_cfg_job/1,
    get_robot_cfg_equip_list/1,
    get_robot_level/1,
    get_robot_job/1,
    get_robot_equip_list/3,
    get_robot_equip_list/2,

    %% robot_cfg_new
    get_random_robot_name/0,
    get_level_cfg/1
	]).


-include("inc.hrl").
-include("load_robot_cfg.hrl").
-include_lib("config/include/config.hrl").

load_config_meta() ->
    [
        #config_meta{
            record = #robot_cfg{},
            fields = ?record_fields(robot_cfg),
            file = "robot.txt",
            keypos = #robot_cfg.id,
            all = [#robot_cfg.id],
            verify = fun verify/1
        },

        #config_meta{
            record = #robot_name_cfg{},
            fields = ?record_fields(robot_name_cfg),
            file = "robot_name.txt",
            keypos = #robot_name_cfg.id,
            all = [#robot_name_cfg.id],
            verify = fun verify/1
        },

        #config_meta{
            record = #robot_new_cfg{},
            fields = ?record_fields(robot_new_cfg),
            file = "robot_new.txt",
            keypos = #robot_new_cfg.id,
            all = [#robot_new_cfg.id],
            verify = fun verify/1
        }
    ].


verify(#robot_cfg{id = Id, first_name = _FirstName, last_name = _LastName}) ->
    ?check(is_integer(Id), "robot.txt中， [~p] id: ~p 配置无效。", [Id, Id]);
verify(#robot_name_cfg{}) ->
    ok;
verify(#robot_new_cfg{}) ->
    ok.

get_robot_list() ->
	lookup_all_robot_cfg(#robot_cfg.id).

%% 获取机器人的配置等级
get_robot_cfg_level(Id) ->
    case lookup_robot_cfg(Id) of
        #robot_cfg{level = Level} -> Level;
        _ -> ret:error(unknown_id)
    end.

%% 获取机器人的配置职业
get_robot_cfg_job(Id) ->
    case lookup_robot_cfg(Id) of
        #robot_cfg{job = Job} -> Job;
        _ -> ret:error(unknown_id)
    end.

%% 获取机器人的配置装备列表
get_robot_cfg_equip_list(Id) ->
    case lookup_robot_cfg(Id) of
        #robot_cfg{equip_list = EquipList} -> EquipList;
        _ -> ret:error(unknown_id)
    end.

%% 获取机器人的随机等级，如果配置表中写明则以配置表为主
get_robot_level(Id) ->
    case get_robot_cfg_level(Id) of
        {rand, [Min, Max]} -> get_robot_level(Max, Min);
        Level -> Level
    end.

get_robot_level(Max, Min) ->
    [Lev] = com_util:rand_more(lists:seq(Min, Max), 1),
    Lev.

%% 获取机器人的随机职业，如果配置表中写明则以配置表为主
get_robot_job(Id) when is_integer(Id) ->
    case get_robot_cfg_job(Id) of
        {rand, JobList} -> get_robot_job(JobList);
        Job -> Job
    end;

get_robot_job(JobList) when is_list(JobList) ->
    [Job] = com_util:rand_more(JobList, 1),
    Job.

%% 获取机器人的随机装备列表，如果配置表中写明则以配置表为主
get_robot_equip_list(Id, Job, Level) ->
    case get_robot_cfg_equip_list(Id) of
        {rand, _} -> get_robot_equip_list(Job, Level);
        EquipList -> EquipList
    end.

get_robot_equip_list(Job, Level) ->
    AllEquipBidList  = load_equip_expand:get_all_equip_bid_list(),  %%  从装备的配置表中读取所有装备的bid

    %% 筛选出所有符合条件的bid列表
    EquipBidList =
        lists:foldl
        (
            fun
                (Bid, Acc) ->
                    CfgLev = load_equip_expand:get_equip_cfg_level(Bid),
                    CfgType = load_equip_expand:get_equip_cfg_type(Bid),
                    CfgJob = load_equip_expand:get_equip_cfg_job(Bid),
                    Ret = lists:member(CfgType, Acc),
                    Ret1 =
                        case Ret of
                            true -> false;
                            _ -> true
                        end,
                    case Level >= CfgLev andalso Job =:= CfgJob andalso Ret1 of
                        true ->
                            [Bid|Acc];
                        _ -> Acc
                    end
            end,
        [],
        AllEquipBidList
        ),
    [RandNum] = com_util:rand_more(lists:seq(1,8), 1),
    EquipBidListLen = length(EquipBidList),
    RandEquipBidList =
        case EquipBidListLen < RandNum of
            true ->
                EquipBidList;
            _ ->
                com_util:rand_more(EquipBidList, RandNum)
        end,
    RandEquipBidList.


%% ============================================================
%% robot_cfg_new
%% ============================================================
get_random_robot_name() ->
    IdList = lookup_all_robot_name_cfg(#robot_name_cfg.id),
    {FirstNameList, LastNameList} = lists:foldl(
        fun(Id, {TempFList, TempLList}) ->
                case lookup_robot_name_cfg(Id) of
                    #robot_name_cfg{first_name = FName, last_name = LName} ->
                        {[FName | TempFList], [LName | TempLList]};
                    _ ->
                        {TempFList, TempLList}
                end
        end,
        {[], []},
        IdList
    ),
    Length1 = length(FirstNameList),
    Length2 = length(LastNameList),
    RandomNum1 = random:uniform(Length1),
    RandomNum2 = random:uniform(Length2),
    FirstName = lists:nth(RandomNum1, FirstNameList),
    LastName = lists:nth(RandomNum2, LastNameList),
    list_to_binary(binary_to_list(FirstName) ++ binary_to_list(LastName)).

get_level_cfg(Level) ->
    IdList = lookup_all_robot_new_cfg(#robot_new_cfg.id),
    NewIdList = lists:filter(
        fun(Id) ->
                Cfg = lookup_robot_new_cfg(Id),
                [MinL, MaxL] = Cfg#robot_new_cfg.level,
                MinL =< Level andalso Level =< MaxL
        end,
        IdList
    ),
    case NewIdList of
        [NewId] ->
            lookup_robot_new_cfg(NewId);
        _ ->
            none
    end.
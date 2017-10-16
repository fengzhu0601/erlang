%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 怪物技能管理器
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(monster_skill_mng).

-include("inc.hrl").

-include("scene.hrl").
-include("skill_struct.hrl").
-include("scene_agent.hrl").
-include("scene_monster.hrl").


-export([init/2,
    uninit/1,
    get_releaseable_skill/3,
    release_skill/2
]).


-export([handle_timer/2]).

%% use this is for min use memory
-define(pd_skill_pool, '@skill_pool@').
-define(pd_m_skill_mng(__Idx), {'@m_skill_mng@', __Idx}).

-record(mng, {exec = [], %%将要释放的
    ready = [] %% cd read 的当exec 为空时,赋值给exec
}).

skill_pool_get(SkillId) ->
    case erlang:get({?pd_skill_pool, SkillId}) of
        ?undefined ->
            #skill_cfg{cd = Cd, release_range = RR} = load_cfg_skill:lookup_skill_cfg(SkillId),
            ?pd_new({?pd_skill_pool, SkillId}, {RR, Cd, SkillId}),
            {RR, Cd, SkillId};
        Info ->
            Info
    end.


%% TODO Skill list -> tuple
init(_Idx, #monster_cfg{skills = []}) ->
    ok; %% 某些类型的怪物没有技能
init(Idx, #monster_cfg{skills = Skills}) ->
    {IdList, _} = lists:unzip(Skills),
    Mng = #mng{exec = com_lists:sort_desc([skill_pool_get(SkillId) || SkillId <- IdList])},
    ?debug_log_scene_monster("monster ~p init skill_mng ~p", [Idx, Mng]),
    put(?pd_m_skill_mng(Idx), Mng).


uninit(Idx) ->
    erase(?pd_m_skill_mng(Idx)).

release_skill(Idx, _SkillId) ->
    #mng{exec = [{D, Cd, SkillId} | Other], ready = Ready} = Mng = get(?pd_m_skill_mng(Idx)),
    %%if cd less than 0.5 sec not del
    %%TODO check not repeat element

    ?assert(_SkillId =:= SkillId),

    case Cd >= 500 of
        true ->
            _ = scene_eng:start_timer(Cd, ?MODULE, {skill_cd, Idx, SkillId}),
            if Other =:= [] ->
                put(?pd_m_skill_mng(Idx), Mng#mng{exec = Ready, ready = []});
                true ->
                    put(?pd_m_skill_mng(Idx), Mng#mng{exec = Other})
            end;
        false ->
            if Other =:= [] ->
                put(?pd_m_skill_mng(Idx), Mng#mng{exec = [{D, Cd, SkillId} | Ready], ready = []});
                true ->
                    put(?pd_m_skill_mng(Idx), Mng#mng{exec = Other, ready = [{D, Cd, SkillId} | Ready]})
            end
    end.



%% 获得可以释放的技能, 如果有则返回对应的skillId和新的ｍｎｇ，
%% 如果没有能拿到当前释放距离的，就返回一个可以释放技能的释放距离
-spec get_releaseable_skill(idx(), _, _) -> ?none | {not_in_range, _, _} | {ok, Skillid :: _}.
get_releaseable_skill(Idx, MyPos, EnemyPos) ->
    case get(?pd_m_skill_mng(Idx)) of
        ?undefined -> %% 没有技能
            ?none;
        Mng ->
            get_releaseable_skill__(Idx, MyPos, EnemyPos, Mng)
    end.

get_releaseable_skill__(Idx, {X, Y}, {Ex, Ey}, Mng) ->
    case Mng of
        #mng{exec = [], ready = Ready} ->
            case Ready of
                [] ->
                    ?debug_log_scene_monster("idx ~p skill is empty", [Idx]),
                    ?none;
                _ ->
                    get_releaseable_skill__(Idx,
                        {X, Y},
                        {Ex, Ey},
                        Mng#mng{exec = com_lists:sort_desc(Ready), ready = []})
            end;
        #mng{exec = [{{RRangeMin, RRangeMax}, _Cd, SkillId} = _X | _Other], ready = _Ready} = Mng ->
            Xv = move_xv(Ex, X, RRangeMin, RRangeMax),
            Yv = Ey - Y,

            if Xv =:= 0 andalso Yv =:= 0 ->
                {ok, SkillId};
                true ->
                    case room_map:is_walkable(Idx, X + Xv, Ey) of
                        true ->
                            {not_in_range, Xv, Yv};
                        false ->
                            {ok, SkillId}
                    end

            end
    end.

move_xv(Ex, X, RRangeMin, RRangeMax) ->
    ?assert(RRangeMin =< RRangeMax),

    Dis = Ex - X,
    if Dis > 0 ->
        if Dis >= RRangeMax ->
            Dis - RRangeMax;
            Dis < RRangeMin ->
                Dis - RRangeMin; %% -xxx
            true -> %% in range
                0
        end;
        true ->
            if -Dis >= RRangeMax ->
                Dis + RRangeMax;
                -Dis < RRangeMin ->
                    Dis + RRangeMin; %% -xxx
                true ->
                    0
            end
    end.



handle_timer(_Ref, {skill_cd, Idx, SkillId}) ->
    ?assert(Idx < 0),
    case ?get_agent(Idx) of
        ?undefined -> ok;
        _A ->
            ?debug_log_scene_monster("monster ~p skill ~p cd ready", [Idx, SkillId]),
            case get(?pd_m_skill_mng(Idx)) of
                #mng{exec = []} -> %% first ready skill
                    put(?pd_m_skill_mng(Idx), #mng{exec = [skill_pool_get(SkillId)]}),
                    ?debug_log_scene_monster("idx ~p skill ~p ready", [Idx, SkillId]);
                Mng ->
                    put(?pd_m_skill_mng(Idx), Mng#mng{ready = [skill_pool_get(SkillId) | Mng#mng.ready]})
            end
    end;
handle_timer(_Ref, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

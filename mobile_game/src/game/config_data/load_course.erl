-module(load_course).

%% API
-export([
    get_course_ins_id/1,
    get_course_prize/1,
    get_course_state_id/1,
    get_course_complete_conditions/1,
    get_boss_challenge_id/1,
    get_course_type/1,
    is_display_of_boss/1,
    get_course_type2/1
]).


-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_course.hrl").


is_display_of_boss(Id) ->
    case lookup_boss_challenge_cfg(Id) of
        #boss_challenge_cfg{is_display=1} ->
            ?true;
        _ ->
            ?false
    end.

get_course_complete_conditions(Id) ->
    case lookup_boss_challenge_cfg(Id) of
        ?none ->
            ?false;
        #boss_challenge_cfg{complete_conditions=List} ->
            List
    end.

get_course_ins_id(Id) ->
    case lookup_course_cfg(Id) of
        ?none ->
            ?false;
        #course_cfg{instance_id = InSid} ->
            InSid
    end.

get_course_prize(Id) ->
    case lookup_course_cfg(Id) of
        ?none ->
            0;
        #course_cfg{prize_id=PrizeId} ->
            PrizeId
    end.

get_course_state_id(Id) ->
    case lookup_course_cfg(Id) of
        ?none ->
            ?false;
        #course_cfg{state_id=StateId} ->
            StateId
    end.

get_course_type(Id) ->
    case lookup_boss_challenge_cfg(Id) of
        ?none ->
            ?false;
        #boss_challenge_cfg{type=Type} ->
            Type
    end.

get_course_type2(Id) ->
    case lookup_course_cfg(Id) of
        ?none ->
            ?false;
        #course_cfg{type=Type} ->
            Type
    end.


get_boss_challenge_id(Id) ->
    case lookup_boss_challenge_cfg(Id) of
        ?none ->
            ?false;
        #boss_challenge_cfg{ins_id=InSid} ->
            {?true, InSid}
    end.

load_config_meta() ->
    [
        #config_meta{record = #course_cfg{},
            fields = ?record_fields(course_cfg),
            file = "course.txt",   
            keypos = #course_cfg.id,
            verify = fun verify/1},
        #config_meta{record = #boss_challenge_cfg{},
            fields = ?record_fields(boss_challenge_cfg),
            file = "boss_challenge.txt",   
            keypos = #boss_challenge_cfg.id,
            verify = fun verify2/1}
    ].



verify(#course_cfg{id = Id,career=Job, prize_id=PrizeId,instance_id=InSid}) ->
    ?check( player_def:is_valid_career(Job), "course.txt id (~w) Job ~w error!", [Id, Job]),
    ?check(prize:is_exist_prize_cfg(PrizeId) orelse PrizeId =:= 0, "course.txt prize_id[~w] 无效! ", [PrizeId]),
    ?check(load_cfg_scene:is_exist_scene_cfg(InSid), "course.txt instance_id[~w] 无效! ", [InSid]),
    ok.

verify2(#boss_challenge_cfg{id=Id, ins_id=InSid, prize_list=PrizeLIst}) ->
    lists:foreach(fun(PrizeId) ->
        ?check(prize:is_exist_prize_cfg(PrizeId) orelse PrizeId =:= 0, "boss_challenge.txt Id[~w] de prize_id[~w] 无效! ", [Id, PrizeId])
    end,
    PrizeLIst),
    ?check(load_cfg_scene:is_exist_scene_cfg(InSid), "boss_challenge.txt ins_id[~w] 无效! ", [InSid]),
    ok.




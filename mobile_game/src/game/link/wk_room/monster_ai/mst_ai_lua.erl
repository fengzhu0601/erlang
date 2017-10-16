%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 五月 2016 上午7:43
%%%-------------------------------------------------------------------
-module(mst_ai_lua).
-author("clark").

%% API
-export
([
    get_monster_cfg/1
    , get_monster_skills/1
    , get_monster_rand_skill/1
    , init/0
    , uninit/0
    , build_lua_stack/0
    , init_ai_part/2
    , uninit_ai_part/1
    , on_ai_evt/3
    , update_stack/1
]).



-include("scene_msg_sign.hrl").
-include("player.hrl").
-include("room_system.hrl").


-define(room_ai_tab,                '@room_ai_tab@').
-define(room_lua_base_stack,        '@room_lua_base_stack@').



init() ->
%%     AiTab = get_ai_tab(),
%%     util:set_pd_field(?room_ai_tab, AiTab),
%%
%%     BaseStack = build_lua_stack(),
%%     util:set_pd_field(?room_lua_base_stack, BaseStack),

    ok.

uninit() ->
%%     util:del_pd_field(?room_ai_tab),
%%     util:del_pd_field(?room_lua_base_stack),
    ok.

update_stack(BaseStack) ->
    util:set_pd_field(?room_lua_base_stack, BaseStack).


init_ai_part(Idx, MonsterId) ->
%%     case util:get_pd_field(?room_lua_base_stack, nil) of
%%         nil ->
%%             pass;
%%
%%         Stack ->
%%             luerl:call_function([build_ai_part], [Idx, MonsterId], Stack)
%%     end,
    ok.

uninit_ai_part(Idx) ->
%%     case util:get_pd_field(?room_lua_base_stack, nil) of
%%         nil ->
%%             pass;
%%
%%         Stack ->
%%             luerl:call_function([release_ai_part], [Idx], Stack)
%%     end,
    ok.

on_ai_evt(Idx, EvtId, EvtArgs) ->
%%     case pl_util:is_dizzy(Idx) of
%%         ok ->
%%             pass;
%%
%%         _ ->
%%             case util:get_pd_field(?room_lua_base_stack, nil) of
%%                 nil ->
%%                     pass;
%%
%%                 Stack ->
%%                     luerl:call_function([on_ai_evt], [Idx, EvtId, EvtArgs], Stack)
%%             end
%%     end,
    ok.

get_ai_tab() ->
    New = luerl:init(),
    {ok, [FileRet]} = luerl:evalfile("./data/ai_lua/monster1.lua", New),
    FileRet.


get_monster_tab_field(MonsterId, Key) ->
    case util:get_pd_field(?room_ai_tab, nil) of
        nil ->
            nil;

        AiTab ->
            case lists:keyfind(MonsterId, 1, AiTab) of
                false ->
                    nil;

                {_Key, Args} ->
                    case lists:keyfind(Key, 1, Args) of
                        false ->
                            nil;

                        {_, Val} ->
                            Val
                    end
            end
    end.

get_monster_skills(MonsterId) ->
    get_monster_tab_field(MonsterId, <<"skills">>).

%% get_monster_rand_skill(MonsterId) ->
%%     SkillList = get_monster_tab_field(MonsterId, <<"skills">>),
%%     [Item1 | _Tail1] = SkillList,
%%     {_x, [Skill1 | _SkillTail]} = Item1,
%%     {_, SkillSegment} = Skill1,
%%     trunc(SkillSegment*10+1).

get_monster_rand_skill(MonsterId) ->
    case util:get_pd_field(?room_lua_base_stack, nil) of
        nil ->
            0;

        Stack ->
            {[Segment,Skill], _} = luerl:call_function([get_rand_skill], [MonsterId], Stack),
%%             io:format("rand_skill ~p~n", [{Segment,Skill}]),
            Segment1 = trunc(Segment),
            Skill1 = trunc(Skill),
            {Segment1, Skill1}
    end.

get_monster_cfg(MonsterId) ->
    case get_monster_tab_field(MonsterId, <<"normal">>) of
        nil ->
            nil;

        Id0 when is_number(Id0) ->
            Id = trunc(Id0),
            BaseStack = util:get_pd_field(?room_lua_base_stack, nil),
            {_, New2}= luerl:dofile("./data/ai_lua/" ++ integer_to_list(Id) ++ ".lua", BaseStack),
            {Result, _} = luerl:call_function([get_ai_args], [], New2),
            [Lists] = Result,
            Lists;

        Id1 ->
            BaseStack = util:get_pd_field(?room_lua_base_stack, nil),
            {_, New2}= luerl:dofile("./data/ai_lua/" ++ binary:bin_to_list(Id1) ++ ".lua", BaseStack),
            {Result, _} = luerl:call_function([get_ai_args], [], New2),
            [Lists] = Result,
            Lists
    end.


build_lua_stack() ->
    St0 = luerl:init(),
    St1 = erlang_api:install(St0),
    St1.

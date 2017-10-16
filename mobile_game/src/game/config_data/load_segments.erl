%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 十一月 2015 下午3:45
%%%-------------------------------------------------------------------
-module(load_segments).
-author("clark").

%% API
-export
([
    get_emits/1
]).



-include("inc.hrl").
-include_lib("config/include/config.hrl").
-include("load_scene_monster.hrl").
-include("load_segments.hrl").



load_config_meta() ->
    [
        #config_meta
        {
            record = #segments_cfg{},
            fields = ?record_fields(segments_cfg),
            file = "segments.txt",
            keypos = #segments_cfg.id,
            verify = fun verify/1
        }
    ].


verify(#segments_cfg{}) ->
    ok.

get_first_segmentid(RetList, []) ->
    RetList;
get_first_segmentid(RetList, [{_, ID}|Taillist]) ->
    get_first_segmentid( [ID|RetList], Taillist).


get_emits(SegmentId) ->
    case lookup_segments_cfg(SegmentId) of
        #segments_cfg{ emits = Emits } ->
            get_first_segmentid([], Emits);
        _ ->
            []
    end.
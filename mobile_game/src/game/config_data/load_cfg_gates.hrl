%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 三月 2016 下午9:23
%%%-------------------------------------------------------------------
-author("lan").
-define(pd_offset_gate_msg, pd_offset_gate_msg).

-record(scene_gates_cfg,
{
    id
    ,client_name
    ,sceneId
    ,position
    ,height
    ,limitLevel
    ,outOffset
    ,approachArea
    ,enterArea
%%     ,last_city_point
    ,effect
    ,link_type
    ,target
}).
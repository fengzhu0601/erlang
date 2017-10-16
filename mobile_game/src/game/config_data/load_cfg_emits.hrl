%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2015 下午5:03
%%%-------------------------------------------------------------------
-author("clark").


-record(emits_cfg,
{
    id
    , delay = 0
    , offset = {0,0,0}
    , speed = {0,0,0}
    , time = 0
    , trigger_type
    , trigger_depth
    , attack_interval = 0
    , attack_skill = 0
    , trigger_condition
    , trigger_datas
    , radius
}).


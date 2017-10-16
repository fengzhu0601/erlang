%%%-------------------------------------------------------------------
%%% @author lan
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 五月 2016 下午5:07
%%%-------------------------------------------------------------------
-author("lan").

-record(punchs_cfg,
{
    id,
    level,
    rate,
    type        %% 打孔器类型
}).

-define(PUNCH_NORMAL_TYPE,1).   %% 普通打孔器
-define(PUNCH_EPIC_TYPE,2).     %% 史诗打孔器

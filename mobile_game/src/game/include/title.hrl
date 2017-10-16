%%%-------------------------------------------------------------------
%%% @author yujian
%%% @doc
%%%-------------------------------------------------------------------
-define(title_global_data, title_global_data).
-define(title_global_data_default_id, 1).

%-define(global_title_type, 0). %全局称号的类型type


% -define(player_max_power, player_max_power). %最大战力称号ID
% -define(player_max_power_by_career_1, player_max_power_by_career_1). %战士最大战力称号ID
% -define(player_max_power_by_career_2, player_max_power_by_career_2). %法师最大战力称号ID
% -define(player_max_power_by_career_3, player_max_power_by_career_3). %弓箭手最大战力称号ID
% -define(player_max_power_by_career_4, player_max_power_by_career_4). %盾士最大战力称号ID

% %% @doc 称号名称和排行榜名称的映射
% -define(ALL_GLOBAL_TITLES, [{?player_max_power, ?ranking_power},
%     {?player_max_power_by_career_1, ?ranking_career_1_power},
%     {?player_max_power_by_career_2, ?ranking_career_2_power},
%     {?player_max_power_by_career_3, ?ranking_career_3_power},
%     {?player_max_power_by_career_4, ?ranking_career_4_power}]).

-define(add_title, 1). %获得称号
-define(del_title, 2). %失去称号

%% @doc 记录全局称号
-record(title_global_data, {
    id,
    title_list = [], %[{title_key,player_id}]
    old_title_list = []
}).

%%-record(title_cfg, {id = 0,
%%    type = 0,
%%    title_server_name = 0,
%%    level = 0,
%%    attr_id = 0}).
-define(player_status_tab, player_status_tab).
-record(player_status_tab, {
	id,
	list = []
}).
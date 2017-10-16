%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 四月 2016 下午5:50
%%%-------------------------------------------------------------------
-author("clark").



-record(rule_porsche_state,
{
    key         = nil,      %% 当前配置的唯一索引
    state_id    = 0,        %% 状态ID
    evt_list    = []        %% 事件列表
}).


-record(rule_porsche_event,
{
    key         = nil,      %% 当前配置的唯一索引
    evt_id      = 0,        %% 事件ID
    times       = 1,        %% 触发次数
    can         = [],       %% 条件
    true        = [],       %% 动作
    false       = []        %% 动作
}).


-record(rule_porsche_can,
{
    key         = nil,      %% 当前配置的唯一索引
    func        = nil,      %% 函数
    par         = []        %% 参数
}).


-record(rule_porsche_do,
{
    type        = nil,
    key         = nil,      %% 当前配置的唯一索引
    func        = nil,      %% 函数
    par         = []        %% 参数
}).
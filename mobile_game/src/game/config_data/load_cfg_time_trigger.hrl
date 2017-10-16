-record(time_trigger_cfg,{
    id,
    activity_id,
    week,
    is_end,
    time,         %% 触发时间
    broadcast_rule,
    command,       %% 触发命令
    broadcast_id
}).

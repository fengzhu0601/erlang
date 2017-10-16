%% @doc 功能开放配置表
-record(open_fun_cfg, {
    id = 0,
    sinks = 0,
    task_trigger = [],
    limit_level = 0,
    limit_main_task = 0,
    limit_chapter = 0
}).
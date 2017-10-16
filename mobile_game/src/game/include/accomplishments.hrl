% %% achievement_status
% -define(achievement_status_begin, 1).
% -define(achievement_status_underway, 2).
% -define(achievement_status_end, 3).


% -define(ACHIEVEMENT_MAIN_INS_ID, 100000). %成就表中id大于10w的就是副本成就

% -record(achievement_cfg, {id=0,
%                             event=0,
%                             type_id=0,
%                             max_value=[],
%                             reward=[],
%                             title=[]}).


% -define(VER_CUR, 1).
% -record(accomplishments, {id               = 0  %% 玩家id
%                             ,ver             = 0  %% 结构版本号
%                             ,achievements		   = [] %% [#achievement{},..]
%                             ,main_ins_achievements  = [] %副本成就 [#achievement{}]
% }).

% -record(achievement, {id=0,
%                         type=0,
%                         type_id=0,
%                         type_value=0,%该星级下已经完成的进度
%                         level=0, %第几星级
%                         status=0,
%                         reward=0}).

% -define(ins_start_init_acc, ins_start_init_acc). %副本初始化时，初始化成就信息
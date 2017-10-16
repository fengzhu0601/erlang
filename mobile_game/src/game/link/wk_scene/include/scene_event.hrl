-ifdef(SCENE_EVENT_HRL).
-else.
-define(SCENE_EVENT_HRL, 1).

% 玩家事件定义
-define(PLAYER_ENTER_SCENE, 10001).     % 进入场景
-define(PLAYER_MOVEING, 10002).         % 玩家移动
-define(PLAYER_KILL_MONSTER, 10003).    % 击杀怪物

-endif.

-ifndef(__TYPE_HRL).
-define(__TYPE_HRL, 1).

-type msg_id() :: non_neg_integer().
-type mod_id() :: non_neg_integer().
-type player_id() :: neg_integer().
-type scene_cfg_id() :: neg_integer().

-type scene_id() :: scene_cfg_id() | %% noraml
{scene_cfg_id(), pseudo} | %% 虚拟场景, 竞技场使用
{scene_cfg_id(), scene_main_ins, Scene3Id :: {single, player_id()}} | %% 单人副本
{scene_cfg_id(), scene_main_ins, Scene3Id :: {team, RoomId :: pos_integer()}}. %% 组队副本

-type map_point() :: {neg_integer(), neg_integer()}.

-endif.

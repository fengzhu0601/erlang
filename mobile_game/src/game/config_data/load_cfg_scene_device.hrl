%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc 场景机关设备
%%%
%%% @end
%%% Created : 05. 一月 2016 下午4:00
%%%-------------------------------------------------------------------
-author("fengzhu").

-record(scene_device_cfg,
{
  scene_id
  , id
  , position %%{X,Y}
  , range %% 防守范围{X, Y}
  , interval %%释放间隔
  , hit_times = ?none %% 自身受伤害次数
  , skill_id %% 技能id
  , release_times = ?infinity %% 释放的次数
  , release_delay = 0 %% msec
  , hit_per %% 伤害半分比
}).

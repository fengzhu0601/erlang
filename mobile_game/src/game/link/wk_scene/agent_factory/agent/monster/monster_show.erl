%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(monster_show).

%%
%%-include_lib("config/include/config.hrl").
%%
%%-include("inc.hrl").
%%-include("scene.hrl").
%%-include("scene_monster.hrl").
%%
%%-export([random_show_id/1]).
%%
%%-record(monster_show_cfg, {id,
%%    daily %% 毫秒
%%}).
%%
%%-record(monster_show_group_cfg,
%%{
%%    id,
%%    shows %% [monster_show_cfg.id]
%%}).
%%
%%
%%random_show_id(ShowGroup) ->
%%    #monster_show_cfg{id = Id, daily = Daily} =
%%        com_list:random_element(lookup_monster_show_group_cfg(ShowGroup, #monster_show_group_cfg.shows)),
%%    {Id, Daily}.
%%
%%
%%
%%load_config_meta() ->
%%    [
%%        #config_meta{record = #monster_show_cfg{},
%%            fields = ?record_fields(monster_show_cfg),
%%            file = "monster_random_show.txt",
%%            keypos = #monster_show_cfg.id,
%%            verify = fun verify/1}
%%        ,
%%        #config_meta{record = #monster_show_group_cfg{},
%%            fields = ?record_fields(monster_show_group_cfg),
%%            file = "monster_random_show_group.txt",
%%            keypos = #monster_show_group_cfg.id,
%%            verify = fun verify/1}
%%    ].
%%
%%
%%verify(#monster_show_cfg{id = Id, daily = Daily}) ->
%%    ?check(?is_pos_integer(Id), "monster_random_show.txt [~p] id 无效 ", [Id]),
%%    ?check(?is_pos_integer(Daily) andalso Daily >= 100, "monster_random_show.txt [~p] daily ~p 无效 ", [Id, Daily]),
%%    ok;
%%
%%verify(#monster_show_group_cfg{id = Id, shows = _ShowList}) ->
%%    ?check(?is_pos_integer(Id), "monster_random_show.txt [~p] id 无效 ", [Id]),
%%
%%
%%
%%    ok;
%%
%%
%%verify(_R) ->
%%    ?ERROR_LOG("monster_group.txt ~p 配置　错误格式", [_R]),
%%    exit(bad).

%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 七月 2015 上午10:32
%%%-------------------------------------------------------------------
-module(player_mods_manager).
-author("clark").

%% API
-export([
    create_mods/1
    , load_eng_mods/1 %% 加载引擎模块
    , load_logic_mods/1 %% 加载逻辑模块
    , init_client/0
    , online/0
    , offline/1
    , save_data/1
    ,houtai_create_mods/1
]).

-export([vip_level_up/1]).


-include("inc.hrl").
-include("player.hrl").


houtai_create_mods(PlayerId) ->
    [Mod:create_mod_data(PlayerId) || Mod <- ?all_player_eng_mods()],
    [Mod:create_mod_data(PlayerId) || Mod <- ?all_player_logic_mods()],
    ok.



create_mods(PlayerId) ->
    [Mod:create_mod_data(PlayerId) || Mod <- ?all_player_eng_mods()],
    [Mod:create_mod_data(PlayerId) || Mod <- ?all_player_logic_mods()],
    ok.


load_eng_mods(PlayerId) ->
    [
        begin
%%            ?INFO_LOG("load_logic_mods ~p ", [Mod]),
            Mod:load_mod_data(PlayerId),
%%            ?INFO_LOG("load_logic_mods ~p ok", [Mod]),
            ok
        end
        || Mod <- ?all_player_eng_mods()
    ],
    ok.


load_logic_mods(PlayerId) ->
    [
        begin
            % ?INFO_LOG("load_logic_mods ~p ", [{Mod, get(pd_create_time)}]),
            Mod:load_mod_data(PlayerId),
            % ?INFO_LOG("load_logic_mods ~p ok", [{Mod, get(pd_create_time)}]),
            ok
        end
        || Mod <- ?all_player_logic_mods()
    ],
    ok.

init_client() ->
    player_eng:tcp_send_cork(
        fun() ->
                [
                    begin
                        Mod:init_client(),
                        ok
                    end
                    || Mod <- ?all_player_logic_mods()
                ]
        end
    ),
    ok.


online() ->
    _ = [Mod:online() || Mod <- ?all_player_eng_mods()],
    _ = [Mod:online() || Mod <- ?all_player_logic_mods()],
    ok.


offline(PlayerId) ->
    _ = [Mod:offline(PlayerId) || Mod <- ?all_player_logic_mods()],
    _ = [Mod:offline(PlayerId) || Mod <- ?all_player_eng_mods()],
    ok.

save_data(PlayerId) ->
    _ = [Mod:save_data(PlayerId) || Mod <- ?all_player_logic_mods()],
    _ = [Mod:save_data(PlayerId) || Mod <- ?all_player_eng_mods()],
    ok.

vip_level_up(OldLevel) ->
    [Mod:handle_frame({?frame_vip_levelup, OldLevel}) || Mod <- ?all_player_logic_mods()].




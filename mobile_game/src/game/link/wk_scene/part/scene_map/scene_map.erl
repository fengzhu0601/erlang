%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc 地图，地图坐标点在图标中配置
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(scene_map).

%%-include_lib("config/include/config.hrl").

-include("inc.hrl").

-include("scene.hrl").
-include("scene_mod.hrl").
-include("load_cfg_scene_map.hrl").
-include("load_cfg_scene.hrl").

%% API
-export([is_walkable/1
    , is_walkable/2
    , map_is_walkable/2
    , map_is_walkable/3
]).

-export([
]).


%%-record(map_cfg, {
%%    id,
%%    width :: neg_integer(),    %% block count
%%    height :: neg_integer(),
%%    unwalkable_points :: [],
%%    safe_points :: [map_point()] %% 不可伤害点,
%%}).


init(#scene_cfg{map_source = MapId}) ->
    Map = load_cfg_scene_map:lookup_map_cfg(MapId),
    MapW = Map#map_cfg.width,
    MapH = Map#map_cfg.height,
    ?pd_new(?pd_map_id, MapId),
    ?pd_new(?pd_map_width, MapW),
    ?pd_new(?pd_map_height, MapH),

    _ = init_block_container(MapW, MapH),

    ok.

uninit(_) -> ok.


handle_msg(Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

handle_timer(_, Msg) ->
    ?ERROR_LOG("unknown msg ~p", [Msg]).

-define(pd_map_block_count, pd_map_block_count). %% 地图划分的block 的数量

%% 初始化视野容器
%% @private Map Width , Map Hight
init_block_container(MapW, MapH) ->
    %% block 编号从0开始
    WBc = MapW div ?BLOCK_W + if MapW rem ?BLOCK_W =/= 0 -> 1; true -> 0 end,
    HBc = MapH div ?BLOCK_H + if MapH rem ?BLOCK_H =/= 0 -> 1; true -> 0 end,
    BlockCount = WBc * HBc,
    erlang:put(?pd_map_block_count, {BlockCount, WBc, HBc}),
%%     ?DEBUG_LOG("init block is ~p ~p ~p ~p", [WBc, HBc, MapW, MapH]),

    %% FIXME BUG
    %% not shuld call this, but has same bug, out of map rang, fix it
    map_aoi:init(WBc, HBc),

    %%scene_aoi:init(WBc-1, HBc-1),

    ok.


%%load_config_meta() ->
%%    [
%%        #config_meta{record = #map_cfg{},
%%            fields = record_info(fields, map_cfg),
%%            file = none,
%%            keypos = #map_cfg.id,
%%            rewrite = fun parse_map_file/1,
%%            verify = fun verify/1}
%%    ].


map_is_walkable(MapId, X, Y) -> MapId:is_walkable(X, Y).
map_is_walkable(MapId, {X, Y}) -> MapId:is_walkable(X, Y).

?INLINE(is_walkable, 1).
is_walkable({X, Y, _}) -> (get(?pd_map_id)):is_walkable(X, Y);
is_walkable({X, Y}) -> (get(?pd_map_id)):is_walkable(X, Y).
?INLINE(is_walkable, 2).
is_walkable(X, Y) -> (get(?pd_map_id)):is_walkable(X, Y).


%%%% atom aaww -> map_block_aaww
%%rewrite_map_id(Name) when is_list(Name) ->
%%    erlang:list_to_atom(Name).


%%parse_map_file(_) ->
%%    {ok, Path} = application:get_env(config_file_path),
%%    Path1 = Path ++ "map/",
%%    {ok, FileList_} = file:list_dir(Path1),
%%    MapFileList = [_File || _File <- FileList_, lists:suffix(".grid", _File)],
%%    %%?DEBUG_LOG("map fils ~p", [MapFileList]),
%%    F = fun(MapFile, Acc) ->
%%        BlockFile = Path1 ++ MapFile,
%%        case file:read_file(BlockFile) of
%%            {error, enoent} ->
%%                ?ERROR_LOG("can not find map block file ~p~n", [BlockFile]),
%%                exit(bad);
%%            {ok, <<Width:16, Height:16, UnwalkableCount:16, Left1/bytes>>} ->
%%
%%                {Unwalkable, <<InvulnerableCount:16, Left2/bytes>>} =
%%                    case parse_pos(UnwalkableCount, Left1) of
%%                        error ->
%%                            ?INFO_LOG("UnwalkableCount Left1 ~p", [{UnwalkableCount, byte_size(Left1) / 4}]),
%%                            ?ERROR_LOG("parse_map_file ~p", [{Width, Height, UnwalkableCount}]),
%%                            {0, <<>>};
%%                        {Pos, Bs} ->
%%%%                                    ?INFO_LOG("UnwalkableCount ~p",[{list:lenght(Pos), Bs}]),
%%                            {Pos, Bs}
%%                    end,
%%                {SafePs, <<>>} = parse_pos(InvulnerableCount, Left2),
%%
%%                %%?DEBUG_LOG("map ~p 不可行走点 Count ~p 安全点 Count ~p ", [MapFile, UnwalkableCount, InvulnerableCount]),
%%                [_Id | _] = string:tokens(MapFile, "."),
%%                Id = rewrite_map_id(_Id),
%%                build_is_walkable_beam(Id, Width, Height, Unwalkable),
%%
%%                [#map_cfg{
%%                    id = Id,
%%                    width = Width,
%%                    height = Height,
%%                    unwalkable_points = Unwalkable,
%%                    safe_points = SafePs} | Acc]
%%        end
%%    end,
%%
%%    %% 编译为查询函数
%%    lists:foldl(F,
%%        [],
%%        MapFileList).
%%
%%verify(#map_cfg{id = Id, unwalkable_points = Up, safe_points = Sp}) ->
%%    ?check(erlang:is_list(Up), "bad map cfg [~p]", [Id]),
%%    ?check(erlang:is_list(Sp), "bad map cfg [~p]", [Id]),
%%    ok.

%%parse_pos(N, Bs) ->
%%    parse_pos(N, Bs, []).
%%parse_pos(0, Bs, Ps) ->
%%    {lists:reverse(Ps), Bs};
%%parse_pos(N, <<X:16, Y:16, Bs/bytes>>, Ps) ->
%%    parse_pos(N - 1, Bs, [{X, Y} | Ps]);
%%parse_pos(N, Bs, _Ps) ->
%%    ?INFO_LOG("parse_pos ~p", [{N, Bs}]),
%%    error.

%%%% export is_walkable/2
%%%% export unwalkable_points/0
%%build_is_walkable_beam(Id, Width, Height, UnwalkableList) ->
%%    Beam = smerl:new(Id),
%%    IsWalkableFn = lists:foldr(fun({X, Y}, Acc) ->
%%        lists:flatten(io_lib:format("is_walkable(~p, ~p) -> false;~n", [X, Y])) ++
%%        Acc
%%    end,
%%        lists:flatten(io_lib:format("is_walkable(X, Y) -> X >= 0 andalso X < ~p andalso Y >=0 andalso Y < ~p~n.", [Width, Height])),
%%        UnwalkableList),
%%
%%    UnwalkablePointFn = lists:flatten(io_lib:format("unwalkable_point() -> ~p .~n", [UnwalkableList])),
%%
%%    case smerl:add_func(Beam, IsWalkableFn) of
%%        {ok, Beam1} ->
%%            {ok, Beam2} = smerl:add_func(Beam1, UnwalkablePointFn),
%%            case smerl:compile(Beam2) of
%%                ok ->
%%                    ok;
%%                _E ->
%%                    ?ERROR_LOG("compile ~p ~p", [Id, _E]),
%%                    exit(bad)
%%            end;
%%    %%smerl:to_src(Beam1, atom_to_list(Id) ++ ".erl");
%%    %%env:development(ok=smerl:to_src(NewFormat, atom_to_list(Mod) ++ ".erl")); %% TODO env
%%        E ->
%%            ?ERROR_LOG("compile ~p ~p", [Id, E])
%%    end.



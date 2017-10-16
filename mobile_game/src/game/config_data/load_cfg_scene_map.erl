%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 一月 2016 下午12:21
%%%-------------------------------------------------------------------
-module(load_cfg_scene_map).
-author("fengzhu").

%% API
-export([]).

-include_lib("config/include/config.hrl").
-include("inc.hrl").
-include("load_cfg_scene_map.hrl").

load_config_meta() ->
  [
    #config_meta{record = #map_cfg{},
      fields = record_info(fields, map_cfg),
      file = none,
      keypos = #map_cfg.id,
      rewrite = fun parse_map_file/1,
      verify = fun verify/1}
  ].

parse_map_file(_) ->
  {ok, Path} = application:get_env(config_file_path),
  Path1 = Path ++ "map/",
  {ok, FileList_} = file:list_dir(Path1),
  MapFileList = [_File || _File <- FileList_, lists:suffix(".grid", _File)],
  %%?DEBUG_LOG("map fils ~p", [MapFileList]),
  F = fun(MapFile, Acc) ->
    BlockFile = Path1 ++ MapFile,
    case file:read_file(BlockFile) of
      {error, enoent} ->
        ?ERROR_LOG("can not find map block file ~p~n", [BlockFile]),
        exit(bad);
      {ok, <<Width:16, Height:16, UnwalkableCount:16, Left1/bytes>>} ->

        {Unwalkable, <<InvulnerableCount:16, Left2/bytes>>} =
          case parse_pos(UnwalkableCount, Left1) of
            error ->
              ?INFO_LOG("UnwalkableCount Left1 ~p", [{UnwalkableCount, byte_size(Left1) / 4}]),
              ?ERROR_LOG("parse_map_file ~p", [{Width, Height, UnwalkableCount}]),
              {0, <<>>};
            {Pos, Bs} ->
%%                                    ?INFO_LOG("UnwalkableCount ~p",[{list:lenght(Pos), Bs}]),
              {Pos, Bs}
          end,
        {SafePs, <<>>} = parse_pos(InvulnerableCount, Left2),

        %%?DEBUG_LOG("map ~p 不可行走点 Count ~p 安全点 Count ~p ", [MapFile, UnwalkableCount, InvulnerableCount]),
        [_Id | _] = string:tokens(MapFile, "."),
        Id = rewrite_map_id(_Id),
        build_is_walkable_beam(Id, Width, Height, Unwalkable),

        [#map_cfg{
          id = Id,
          width = Width,
          height = Height,
          unwalkable_points = Unwalkable,
          safe_points = SafePs} | Acc]
    end
      end,

  %% 编译为查询函数
  lists:foldl(F,
    [],
    MapFileList).

verify(#map_cfg{id = Id, unwalkable_points = Up, safe_points = Sp}) ->
  ?check(erlang:is_list(Up), "bad map cfg [~p]", [Id]),
  ?check(erlang:is_list(Sp), "bad map cfg [~p]", [Id]),
  ok.

parse_pos(N, Bs) ->
  parse_pos(N, Bs, []).
parse_pos(0, Bs, Ps) ->
  {lists:reverse(Ps), Bs};
parse_pos(N, <<X:16, Y:16, Bs/bytes>>, Ps) ->
  parse_pos(N - 1, Bs, [{X, Y} | Ps]);
parse_pos(N, Bs, _Ps) ->
  ?INFO_LOG("parse_pos ~p", [{N, Bs}]),
  error.

%% atom aaww -> map_block_aaww
rewrite_map_id(Name) when is_list(Name) ->
  erlang:list_to_atom(Name).

%% export is_walkable/2
%% export unwalkable_points/0
build_is_walkable_beam(Id, Width, Height, UnwalkableList) ->
  Beam = smerl:new(Id),
  IsWalkableFn = lists:foldr(fun({X, Y}, Acc) ->
    lists:flatten(io_lib:format("is_walkable(~p, ~p) -> false;~n", [X, Y])) ++
    Acc
                             end,
    lists:flatten(io_lib:format("is_walkable(X, Y) -> X >= 0 andalso X < ~p andalso Y >=0 andalso Y < ~p~n.", [Width, Height])),
    UnwalkableList),

  UnwalkablePointFn = lists:flatten(io_lib:format("unwalkable_point() -> ~p .~n", [UnwalkableList])),

  case smerl:add_func(Beam, IsWalkableFn) of
    {ok, Beam1} ->
      {ok, Beam2} = smerl:add_func(Beam1, UnwalkablePointFn),
      case smerl:compile(Beam2) of
        ok ->
          ok;
        _E ->
          ?ERROR_LOG("compile ~p ~p", [Id, _E]),
          exit(bad)
      end;
    %%smerl:to_src(Beam1, atom_to_list(Id) ++ ".erl");
    %%env:development(ok=smerl:to_src(NewFormat, atom_to_list(Mod) ++ ".erl")); %% TODO env
    E ->
      ?ERROR_LOG("compile ~p ~p", [Id, E])
  end.
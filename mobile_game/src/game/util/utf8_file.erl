%%%-------------------------------------------------------------------
%%% @author clark
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. 十二月 2015 下午11:06
%%%-------------------------------------------------------------------
-module(utf8_file).
-author("clark").

%% API
-author("clark").

%% API
-export
([
    open_utf8_file/1
    ,close_file/1
    ,write_list/2
]).




open_utf8_file(FilePath) ->
    file:open( FilePath, [append, write,  {encoding, utf8}] ).

close_file(Device) ->
    file:close(Device).

write_list(Device, [_Item|TailList]) ->
    % io:format(Device, "~p",[Item]),
    do_write_list(Device, TailList, 0).





%% -----------------------------------------------------
%% private
%% -----------------------------------------------------
do_write_list(Device, [], _Value) ->
    io:format(Device, "~n", []);
do_write_list(Device, [Item|TailList], _Value) when is_number(Item) orelse is_integer(Item) orelse is_float(Item) ->
    io:format(Device, "|~p",[Item]),
    do_write_list(Device, TailList, _Value);
do_write_list(Device, [Item|TailList], 0) when is_list(Item) ->
    io:format(Device, "~ts",[unicode:characters_to_binary(Item)]),
    do_write_list(Device, TailList, 1);
do_write_list(Device, [Item|TailList], 1) when is_list(Item) ->
    io:format(Device, "|~ts",[unicode:characters_to_binary(Item)]),
    do_write_list(Device, TailList, 1);
do_write_list(Device, [Item|TailList], _Value) ->
    io:format(Device, "|~ts",[Item]),
    do_write_list(Device, TailList, _Value).

%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc file 标准库的扩充
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_file).

-export([read_line_foreach/2,
         read_line_foreach/3,
         list_dir_filter/2,
         dir_match_suffix_files/2
        ]).


%% @doc call func with each lines.
%% e.g. {ok, F} =file:open("f.txt", [read]),
%%      read_line_foreach(fun(_Num, Line) -> io:format("~s",[Line]") end, F),
%%      ok =file:close(F)
-spec read_line_foreach(Func, IoDevice) -> ok | {error, Reason::term()} when
      IoDevice :: file:io_device(),
      Func :: fun((LineNum, Line) -> ok),
      LineNum :: non_neg_integer(),
      Line :: list() | binary().
read_line_foreach(Func, IoDevice) ->
    read_line_foreach__(1, Func, IoDevice).
read_line_foreach__(LineNum, Func, IoDevice) ->
    case file:read_line(IoDevice) of
        {ok, Line} ->
            Func(LineNum, Line),
            read_line_foreach__(LineNum+1, Func, IoDevice);
        eof ->
            ok;
        {error, Reason} ->
            {error, Reason}
    end.

%% @doc 用于传入参数
-spec read_line_foreach(Func, IoDevice, Param) -> ok | {error, Reason::term()} when
      IoDevice :: file:io_device(),
      Func :: fun((LineNum, Line, Param) -> ok),
      Param :: term(),
      LineNum:: non_neg_integer(),
      Line :: list() | binary().
read_line_foreach(Func, IoDevice, Param) ->
    read_line_foreach__(1, Func, IoDevice, Param).

read_line_foreach__(LineNum, Func, IoDevice, Param) ->
    case file:read_line(IoDevice) of
        {ok, Line} ->
            Func(LineNum, Line, Param),
            read_line_foreach__(LineNum+1, Func, IoDevice, Param);
        eof ->
            ok;
        {error, Reason} ->
            {error, Reason}
    end.

%% @doc 返回一个指定目录,pred 为true 的files
-spec list_dir_filter(Pred, Dir::file:name_all()) -> [file:filename()] | {error, _} when
      Pred :: fun((_) -> boolean()).
list_dir_filter(F, Dir) ->
    case file:list_dir(Dir) of
        {ok, ALLFiles} ->
            lists:filter(F, ALLFiles);
        E ->
            E
    end.

%% @doc 返回一个指定目录所有文件
%% e.g. dir_match_suffix_files(".", ".txt")

-spec dir_match_suffix_files(Dir::file:name_all(), string()) -> [file:filename()] | {error, _}.
dir_match_suffix_files(Dir, Suffix) ->
    list_dir_filter(fun(File) ->
                            lists:suffix(Suffix, File)
                    end,
                    Dir).

%%==========================================================================
%% Internal func
%%==========================================================================

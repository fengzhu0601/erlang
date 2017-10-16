-ifndef(COM_LOG_HRL_).
-define(COM_LOG_HRL_, 1).

-include("com_define.hrl").

-define(LOG_CALL, io:format).

%% R16 suport color term
-define(color_none   , "\e[m").
-define(color_red    , "\e[1m\e[31m").
-define(color_yellow , "\e[1m\e[33m").
-define(color_green  , "\e[0m\e[32m").
-define(color_black  , "\e[0;30m").
-define(color_blue   , "\e[0;34m").
-define(color_purple , "\e[0;35m").
-define(color_cyan   , "\e[0;36m").
-define(color_white  , "\e[0;37m").


%% background hilight
-define(bak_blk,"\e[40m").   %% Black - Background
-define(bak_red,"\e[41m").   %% Red
-define(bak_grn,"\e[42m").   %% Green
-define(bak_ylw,"\e[43m").   %% Yellow
-define(bak_blu,"\e[44m").   %% Blue
-define(bak_pur,"\e[45m").   %% Purple
-define(bak_cyn,"\e[46m").   %% Cyan
-define(bak_wht,"\e[47m").   %% White

-ifdef(env_product).

-define(DEBUG_LOG(MSG), ok).
-define(DEBUG_LOG(FMT, ARGS), ok).

-define(DEBUG_LOG_COLOR(COLOR, MSG),  ok).
-define(DEBUG_LOG_COLOR(COLOR, FMT, ARGS),  ok).

-define(NODE_INFO_LOG(D), ok).
-define(NODE_INFO_LOG(F,D), ok).
-define(NODE_ERROR_LOG(D), ok).
-define(NODE_ERROR_LOG(F,D), ok).

-define(WARN_LOG(D), ok).
-define(WARN_LOG(F, D), ok).
-define(INFO_LOG(D), ok).
-define(INFO_LOG(F, D), ok).
-define(ERROR_LOG(D), ok).
-define(ERROR_LOG(F, D), ok).


%%-define(WARN_LOG(D), lager:warning(D)).
%%-define(WARN_LOG(F, D), lager:warning(F, D)).
%%-define(INFO_LOG(D), lager:info(D)).
%%-define(INFO_LOG(F, D), lager:info(F, D)).
%%-define(ERROR_LOG(D), lager:error(D)).
%%-define(ERROR_LOG(F, D), lager:error(F, D)).


-else.

%-define(DEBUG_LOG(MSG),       ?LOG_CALL("~p [DEBUG] [~tp] ~s:~B "  MSG"~n", [self(), ?pname(), ?FILE, ?LINE ])).
%-define(DEBUG_LOG(FMT, ARGS), ?LOG_CALL("~p [DEBUG] [~tp] ~s:~B "  FMT"~n", [self(), ?pname(), ?FILE, ?LINE | ARGS])).

%-define(DEBUG_LOG_COLOR(COLOR, MSG),       ?LOG_CALL(COLOR "~p ~w[DEBUG] [~tp] ~s:~B "  MSG"~n"?color_none, [self(), com_time:timestamp_msec(),?pname(), ?FILE, ?LINE ])).
%-define(DEBUG_LOG_COLOR(COLOR, FMT, ARGS), ?LOG_CALL(COLOR "~p ~w[DEBUG] [~tp] ~s:~B "  FMT"~n"?color_none, [self(), com_time:timestamp_msec(),?pname(), ?FILE, ?LINE | ARGS])).

-define(DEBUG_LOG(MSG),       ?LOG_CALL("~p ~w[DEBUG] [~tp] ~s:~B"  MSG"~n", [self(), calendar:local_time(),?pname(), ?FILE, ?LINE ])).
-define(DEBUG_LOG(FMT, ARGS), ?LOG_CALL("~p ~w[DEBUG] [~tp] ~s:~B"  FMT"~n", [self(), calendar:local_time(),?pname(), ?FILE, ?LINE | ARGS])).

-define(DEBUG_LOG_COLOR(COLOR, MSG),       ?LOG_CALL(COLOR "~p ~w[DEBUG] [~tp] ~s:~B "  MSG"~n"?color_none, [self(), calendar:local_time(),?pname(), ?FILE, ?LINE ])).
-define(DEBUG_LOG_COLOR(COLOR, FMT, ARGS), ?LOG_CALL(COLOR "~p ~w[DEBUG] [~tp] ~s:~B "  FMT"~n"?color_none, [self(), calendar:local_time(),?pname(), ?FILE, ?LINE | ARGS])).

-define(NODE_INFO_LOG(MSG),         com_log:info_trace(0, MSG)).
-define(NODE_INFO_LOG(FMT, ARGS),   com_log:info_trace(0, FMT, ARGS)).
-define(NODE_ERROR_LOG(MSG),         com_log:info_trace(1, MSG)).
-define(NODE_ERROR_LOG(FMT, ARGS),   com_log:info_trace(1, FMT, ARGS)).

-define(INFO_LOG(MSG),       ?LOG_CALL(?color_green"~p [INFO] [~s:~b] "  MSG"~n"?color_none, [calendar:local_time(),?FILE, ?LINE])).
-define(INFO_LOG(FMT, ARGS), ?LOG_CALL(?color_green"~p [INFO] [~s:~b] "  FMT"~n"?color_none, [calendar:local_time(),?FILE, ?LINE | ARGS])).
-define(WARN_LOG(MSG),       ?LOG_CALL(?color_yellow"~p [WARN] [~s:~b] "  MSG"~n"?color_none, [calendar:local_time(),?FILE, ?LINE])).
-define(WARN_LOG(FMT, ARGS), ?LOG_CALL(?color_yellow"~p [WARN] [~s:~b] "  FMT"~n"?color_none, [calendar:local_time(),?FILE, ?LINE | ARGS])).
-define(ERROR_LOG(MSG),       ?LOG_CALL(?color_red"~p [ERROR] [~s:~B] "  MSG"~n"?color_none, [calendar:local_time(),?FILE, ?LINE])).
-define(ERROR_LOG(FMT, ARGS), ?LOG_CALL(lists:append([?color_red, "~p [ERROR] [~s:~B] ",FMT,"~n", ?color_none]), [calendar:local_time(),?FILE, ?LINE | ARGS])).



-endif. %% release

-define(check(Bool, Fmt, Arg), (fun() -> 
                                        case (Bool) of
                                            true -> true; 
                                            false -> ?ERROR_LOG(Fmt, Arg), 
                                                     case os:type() of
                                                         {unix,_} -> true;
                                                         _ ->
                                                             erlang:exit(bad_cfg) 
                                                     end
                                        end
                                end)()).


-endif.

-module(os_util).

%-export([]).
%-compile(export_all).

%%%
%%% API Functions
%%%
%get_local_ips()->
%case inet:getif() of
%{ok,IFs}->
%SortedIFs = lists:sort(fun(IP1,IP2)->
%{{I1,I2,I3,I4},_,_} = IP1,
%{{J1,J2,J3,J4},_,_} = IP2,
%if I1 =:= 192 -> true;
%J1 =:= 192 -> false;
%I1 =:= 127 -> true;
%J1 =:= 127 -> false;
%I1 < J1 -> true;
%I1 > J1 -> false;
%I2 < J2 -> true;
%I2 > J2 -> false;
%I3 < J3 -> true;
%I3 > J3 -> false;
%I4 < J4 -> true;
%I4 > J4 -> false;
%true-> false
%end
%end, IFs),
%lists:map(fun(IfConfig)->
%case IfConfig of
%{{192,168,I3,I4},_,_}-> "192.168." ++ integer_to_list(I3) ++"." ++ integer_to_list(I4);
%{{127,0,0,I4},_,_}->"127.0.0." ++ integer_to_list(I4);
%{{10,I2,I3,I4},_,_}->str_util:sprintf("10.~p.~p.~p", [I2,I3,I4]);
%{{I1,I2,I3,I4},_,_}->str_util:sprintf("~p.~p.~p.~p", [I1,I2,I3,I4])
%end
%end,SortedIFs);
%_->[]
%end.
%get_localip()->
%case get_localips() of
%[]->[];
%[IP|_]-> IP
%end.

%%%
%%% Local Functions
%%%
%run_exe(CmdLine)->
%run_exe(CmdLine,prompt).

%run_exe(CmdLine,noprompt)->
%cmd_ansync(CmdLine);
%run_exe(CmdLine,_)->
%slogger:msg("~s~n",[CmdLine]),
%cmd_ansync(CmdLine).


%wait_exe(CmdLine)->
%wait_exe(CmdLine,prompt).

%wait_exe(CmdLine,noprompt)->
%os:cmd(CmdLine);

%wait_exe(CmdLine,_)->
%slogger:msg("~s~n",[CmdLine]),
%os:cmd(CmdLine).


%run_erl(Hiden,Name,Host,MnesiaDir,SmpEnable,Wait,Option)->
%CommandLine = get_erl_cmd(Hiden,Name,Host,MnesiaDir,SmpEnable,Wait,Option),
%case Wait of
%wait->
%wait_exe(CommandLine);
%nowait->
%run_exe(CommandLine)
%end.

%run_erl(Hiden,Name,MnesiaDir,SmpEnable,Wait,Option)->
%CommandLine = get_erl_cmd(Hiden,Name,get_localip(),MnesiaDir,SmpEnable,Wait,Option),
%case Wait of
%wait->
%wait_exe(CommandLine);
%nowait->
%run_exe(CommandLine)
%end.

%linux_erl(Hiden,Name,Host,MnesiaDir,SmpEnable,Wait,Option)->
%CommandLine = get_erl_cmd(Hiden,Name,Host,MnesiaDir,SmpEnable,Wait,Option),
%linux_run(CommandLine,Wait).

%win_erl(Hiden,Name,Host,MnesiaDir,SmpEnable,Wait,Option)->
%CommandLine = get_erl_cmd(Hiden,Name,Host,MnesiaDir,SmpEnable,Wait,Option),
%win_run(CommandLine,Wait).

%sure_module(Module)->
%case code:is_loaded(Module) of
%false-> code:load_file(Module);
%_->nothing
%end.

%sure_dir_module(Dir)->
%code:add_patha(Dir),
%Files =  filelib:wildcard(filename:absname_join(Dir, "*.beam")),
%lists:foreach(fun(File)->
%Module = filename:rootname(filename:basename(File)),
%sure_module(Module)
%end, Files).

%os_wait(N) when is_integer(N)->
%CmdLine =  case os:type() of
%{win32,nt}->
%str_util:sprintf("ping 127.0.0.1 -n ~p", [N]);
%_-> str_util:sprintf("sleep ~p", [N])
%end,
%os:cmd(CmdLine);
%os_wait(_)->
%slogger:msg("error wait input").

%stop_single_node(Prefix,SNode,Ip)->
%Node = str_util:make_node(Prefix ++ SNode,Ip),
%rpc:cast(Node, init, stop, []),
%io:format("stopping the node ~p ~n",[Node]),
%os_wait(1).

%get_running_cookie()->
%case file:consult(?COOKIE_FILE) of
%{error,_Reason}->undefined;
%{ok,[Entries]} ->
%case lists:keyfind(?COOKIE_CAT, 1, Entries) of
%{_,CookieCatgri}->
%case lists:keyfind(?COOKIE_KEY, 1, CookieCatgri) of
%false->
%case file:consult(CookieCatgri) of
%{error,_}->undefined;
%{ok,[SubEntries]}->
%case lists:keyfind(?COOKIE_KEY, 1, SubEntries) of
%false-> undefined;
%{_,Cookie}-> Cookie
%end
%end;
%{_,Cookie}-> Cookie
%end;
%false->
%undefined
%end
%end.


%stop_evm(OptFile)->
%[First|_] = OptFile,
%NewOptFile =  if is_list(First) -> First;
%true->OptFile
%end,
%Cookie = get_running_cookie(),
%erlang:set_cookie(node(), Cookie),
%case file:consult(NewOptFile) of
%{error,Reason}->
%io:format("Error:~p [~p]~n",[Reason,NewOptFile]);
%{ok,[RunOptions]}->
%{_,NodesOption} = lists:keyfind(nodes, 1, RunOptions),
%PreFix = case lists:keyfind(prefix, 1, RunOptions) of
%false->"";
%{_,PreFix1} -> PreFix1
%end,
%lists:foreach(fun(RunOpt)->
%{SNode,Ip,_,_,_} = RunOpt,
%case match_ip(Ip) of
%true->stop_single_node(PreFix,SNode,Ip);
%_-> nothing
%end
%end,lists:reverse(NodesOption) ),
%os_wait(1)
%end.

%match_ip(GiveIp)->
%case inet:getif() of
%{ok,IFs}->
%lists:any(fun(IF)->
%{{IP1,IP2,IP3,IP4},_,_}=IF,
%IpStr = integer_to_list(IP1) ++[$.]
%++ integer_to_list(IP2) ++ [$.]
%++ integer_to_list(IP3) ++ [$.]
%++ integer_to_list(IP4),
%IpStr =:= GiveIp
%end, IFs);
%_-> false
%end.


%linux_run(CmdLine,Wait)->
%case os:type() of
%{win32,nt}->
%OutPrompt = str_util:sprintf("windows does not run:~p~n",[CmdLine]),
%io:format(OutPrompt);
%_->
%case Wait of
%wait -> wait_exe(CmdLine);
%_-> run_exe(CmdLine)
%end
%end.

%win_run(CmdLine,Wait)->
%case os:type() of
%{win32,nt}->
%case Wait of
%wait -> wait_exe(CmdLine);
%_-> run_exe(CmdLine)
%end;
%_->
%OutPrompt = str_util:sprintf("linux does not run:~p~n",[CmdLine]),
%io:format(OutPrompt)
%end.


%%% Hiden -> hiden | normal
%%% Name  -> NodeName
%%% Host  -> Ip
%%% MnesiaDir -> Mnesi Dir
%%% SmpEnable -> smp | nosmp
%%% Wait   ->  wait | nowait
%%% Option -> " -s module function args"
%get_erl_cmd(Hiden,Name,Host,MnesiaDir,SmpEnable,Wait,Option)->
%HidenOption = case Hiden of
%hiden-> " -noshell -noinput ";
%normal->""
%end,
%NameOption = case Name of
%[]-> "";
%_ -> str_util:sprintf(" -name ~s@~s ",[Name,Host])
%end,

%DBOption   = case MnesiaDir of
%[]-> "";
%_ -> str_util:sprintf(" -mnesia dir '\"~s\"' ", [MnesiaDir])
%end,

%SMPOption  = case SmpEnable of
%smp ->
%"";
%nosmp->
%case os:type() of
%{win32,nt}-> " ";
%_-> " -smp disable "
%end
%end,

%ExeCmd = case os:type() of
%{win32,nt}->
%case Wait of
%wait ->
%"start erl.exe ";
%nowait ->
%case Hiden of
%hiden-> "erl.exe";
%normal-> "start cmd.exe /k erl.exe "
%end
%end;
%_->
%"erl +P 100000 +K true "
%end,

%TailOption = case os:type() of
%{win32,nt}->
%"";
%_->
%case Wait of
%wait -> "";
%nowait ->
%" > /dev/null 2>&1&"
%end
%end,

%lists:append([ExeCmd, HidenOption ,NameOption,DBOption , SMPOption , Option , TailOption]).


%%% Executes the given command in the default shell for the operating system.
%-spec cmd_ansync(Command) -> atom() when
%Command :: atom() | io_lib:chars().
%cmd_ansync(Cmd) ->
%CurPid = self(),
%Fun = fun()->do_cmd_ansync(Cmd,CurPid) end,
%proc_lib:spawn(Fun),
%receive
%ok-> ok;
%_->error
%end.

%-spec cmd_ansync(Command,TimeOut) -> atom() when
%Command :: atom() | io_lib:chars(),
%TimeOut :: integer().

%cmd_ansync(Cmd,infinit) ->
%CurPid = self(),
%Fun = fun()->do_cmd_ansync(Cmd,CurPid) end,
%proc_lib:spawn(Fun),
%receive
%ok-> ok;
%_->error
%end;
%cmd_ansync(Cmd,TimeOut) ->
%CurPid = self(),
%Fun = fun()->do_cmd_ansync(Cmd,CurPid) end,
%proc_lib:spawn(Fun),
%receive
%ok-> ok;
%_->error
%after TimeOut->
%timeout
%end.

%do_cmd_ansync(Cmd,MonitorPid) ->
%validate(Cmd),
%case os:type() of
%{unix, _} ->
%unix_cmd(Cmd,MonitorPid);
%{win32, Wtype} ->
%Command = case {os:getenv("COMSPEC"),Wtype} of
%{false,windows} -> lists:concat(["command.com /c", Cmd]);
%{false,_} -> lists:concat(["cmd /c", Cmd]);
%{Cspec,_} -> lists:concat([Cspec," /c",Cmd])
%end,
%Port = open_port({spawn, Command}, [stream, in, eof, hide]),
%MonitorPid ! ok,
%get_data(Port, []);
%%% VxWorks uses a 'sh -c hook' in 'vxcall.c' to run os:cmd.
%vxworks ->
%Command = lists:concat(["sh -c '", Cmd, "'"]),
%Port = open_port({spawn, Command}, [stream, in, eof]),
%MonitorPid ! ok,
%get_data(Port, [])
%end.

%unix_cmd(Cmd,MonitorPid) ->
%Tag = make_ref(),
%{Pid,Mref} = erlang:spawn_monitor(
%fun() ->
%process_flag(trap_exit, true),
%Port = start_port(),
%erlang:port_command(Port, mk_cmd(Cmd)),
%MonitorPid ! ok,
%exit({Tag,unix_get_data(Port)})
%end),
%receive
%{'DOWN',Mref,_,Pid,{Tag,Result}} ->
%Result;
%{'DOWN',Mref,_,Pid,Reason} ->
%exit(Reason)
%end.



%%% The -s flag implies that only the positional parameters are set,
%%% and the commands are read from standard input. We set the
%%% $1 parameter for easy identification of the resident shell.
%%%
%-define(SHELL, "/bin/sh -s unix:cmd 2>&1").
%-define(PORT_CREATOR_NAME, os_cmd_port_creator).

%%%
%%% Serializing open_port through a process to avoid smp lock contention
%%% when many concurrent os:cmd() want to do vfork (OTP-7890).
%%%
%-spec start_port() -> port().
%start_port() ->
%Ref = make_ref(),
%Request = {Ref,self()},
%{Pid, Mon} = case whereis(?PORT_CREATOR_NAME) of
%undefined ->
%spawn_monitor(fun() ->
%start_port_srv(Request)
%end);
%P ->
%P ! Request,
%M = erlang:monitor(process, P),
%{P, M}
%end,
%receive
%{Ref, Port} when is_port(Port) ->
%erlang:demonitor(Mon, [flush]),
%Port;
%{Ref, Error} ->
%erlang:demonitor(Mon, [flush]),
%exit(Error);
%{'DOWN', Mon, process, Pid, _Reason} ->
%start_port()
%end.


%start_port_srv(Request) ->
%%% We don't want a group leader of some random application. Use
%%% kernel_sup's group leader.
%{group_leader, GL} = process_info(whereis(kernel_sup),
%group_leader),
%true = group_leader(GL, self()),
%process_flag(trap_exit, true),
%StayAlive = try register(?PORT_CREATOR_NAME, self())
%catch
%error:_ -> false
%end,
%start_port_srv_handle(Request),
%case StayAlive of
%true -> start_port_srv_loop();
%false -> exiting
%end.

%start_port_srv_handle({Ref,Client}) ->
%Reply = try open_port({spawn, ?SHELL},[stream]) of
%Port when is_port(Port) ->
%(catch port_connect(Port, Client)),
%unlink(Port),
%Port
%catch
%error:Reason ->
%{Reason,erlang:get_stacktrace()}
%end,
%Client ! {Ref,Reply}.


%start_port_srv_loop() ->
%receive
%{Ref, Client} = Request when is_reference(Ref),
%is_pid(Client) ->
%start_port_srv_handle(Request);
%_Junk ->
%ignore
%end,
%start_port_srv_loop().


%%%
%%%  unix_get_data(Port) -> Result
%%%
%unix_get_data(Port) ->
%unix_get_data(Port, []).

%unix_get_data(Port, Sofar) ->
%receive
%{Port,{data, Bytes}} ->
%case eot(Bytes) of
%{done, Last} ->
%lists:flatten([Sofar|Last]);
%more  ->
%unix_get_data(Port, [Sofar|Bytes])
%end;
%{'EXIT', Port, _} ->
%lists:flatten(Sofar)
%end.



%%%
%%% eot(String) -> more | {done, Result}
%%%
%eot(Bs) ->
%eot(Bs, []).

%eot([4| _Bs], As) ->
%{done, lists:reverse(As)};
%eot([B| Bs], As) ->
%eot(Bs, [B| As]);
%eot([], _As) ->
%more.

%%%
%%% mk_cmd(Cmd) -> {ok, ShellCommandString} | {error, ErrorString}
%%%
%%% We do not allow any input to Cmd (hence commands that want
%%% to read from standard input will return immediately).
%%% Standard error is redirected to standard output.
%%%
%%% We use ^D (= EOT = 4) to mark the end of the stream.
%%%
%mk_cmd(Cmd) when is_atom(Cmd) ->               % backward comp.
%mk_cmd(atom_to_list(Cmd));
%mk_cmd(Cmd) ->
%%% We insert a new line after the command, in case the command
%%% contains a comment character.
%io_lib:format("(~s\n) </dev/null; echo  \"\^D\"\n", [Cmd]).

%validate(Atom) when is_atom(Atom) ->
%ok;
%validate(List) when is_list(List) ->
%validate1(List).

%validate1([C|Rest]) when is_integer(C), 0 =< C, C < 256 ->
%validate1(Rest);
%validate1([List|Rest]) when is_list(List) ->
%validate1(List),
%validate1(Rest);
%validate1([]) ->
%ok.

%get_data(Port, Sofar) ->
%receive
%{Port, {data, Bytes}} ->
%get_data(Port, [Sofar|Bytes]);
%{Port, eof} ->
%Port ! {self(), close},
%receive
%{Port, closed} ->
%true
%end,
%receive
%{'EXIT',  Port,  _} ->
%ok
%after 1 ->                             % force context switch
%ok
%end,
%lists:flatten(Sofar)
%end.

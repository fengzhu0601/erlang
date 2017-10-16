%% Description: TODO: Add description to run_option
-module(run_option).
                                                %-compile(export_all).

                                                %get_options(File)->
                                                %case file:consult(File) of
                                                %{error,Reason}->
                                                %io:format("~p~n",[Reason]),
                                                %[];
                                                %{ok,[RunOptions]}->
                                                %RunOptions
                                                %end.

                                                %get_opt_nodes(Options)->
                                                %case lists:keyfind(nodes, 1, Options) of
                                                %false-> undefined;
                                                %{_,NodesOption}->NodesOption
                                                %end.
                                                %get_opt_import_nodes(Options)->
                                                %case lists:keyfind(import_nodes, 1, Options) of
                                                %false-> undefined;
                                                %{_,NodesOption}->NodesOption
                                                %end.
                                                %get_opt_tool_nodes(Options)->
                                                %case lists:keyfind(tool_nodes, 1, Options) of
                                                %false-> undefined;
                                                %{_,NodesOption}->NodesOption
                                                %end.
                                                %get_opt_common(Options)->
                                                %case lists:keyfind(common_option, 1, Options) of
                                                %false-> undefined;
                                                %{_,ComOpt}->ComOpt
                                                %end.

                                                %get_opt_beam_dir(Options)->
                                                %case lists:keyfind(beam_dir, 1, Options) of
                                                %false-> "";
                                                %{_,BeamDir}->BeamDir
                                                %end.

                                                %get_db_dir(Options)->
                                                %case lists:keyfind(nodes, 1, Options) of
                                                %false-> undefined;
                                                %{_,NodesOption}->
                                                %Nodes = lists:filter(fun(NodeOpt)->
                                                %{_,_,DBDir,_,_}=NodeOpt,
                                                %DBDir=/=[]
                                                %end,NodesOption),
                                                %case Nodes of
                                                %[]-> [];
                                                %[{_,_,DBDir,_,_}|_]-> DBDir
                                                %end
                                                %end.
                                                %get_opt_prefix(Options)->
                                                %case lists:keyfind(prefix, 1, Options) of
                                                %false-> "";
                                                %{_,Prefix}->Prefix
                                                %end.

                                                %get_opt_gm_port(Options)->
                                                %case lists:keyfind(gm_port, 1, Options) of
                                                %false-> 0;
                                                %{_,GmPort}->GmPort
                                                %end.

                                                %get_opt_ip_ports(Options)->
                                                %case lists:keyfind(ip_ports, 1, Options) of
                                                %false-> [];
                                                %{_,IpPorts}->IpPorts
                                                %end.

                                                %get_ip_list(Options)->
                                                %case lists:keyfind(nodes, 1, Options) of
                                                %false-> [];
                                                %{_,NodesOption}->
                                                %lists:map(fun(NodeOpt)->
                                                %{_,Ip,_,_,_} = NodeOpt,
                                                %Ip
                                                %end, NodesOption)
                                                %end.

%%get_useable_ips(Options)->
%%IpList = run_option:get_ip_list(Options),
%%MyIpList = os_util:get_localips(),
%%lists:filter(fun(IpStr)->
%%lists:member(IpStr,IpList)
%%end,MyIpList).

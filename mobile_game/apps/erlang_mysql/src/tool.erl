-module(tool).

-export([
	ip/1,
	sort/1,
	for/3,
	to_atom/1,
	to_list/1,
	to_binary/1,
	to_integer/1,
	to_bool/1,
	to_tuple/1,
	get_type/2,
	is_string/1,
	is_string/2,
	md5/1,
	ceil/1,
	floor/1,
	subatom/2,
	sleep/1,
	list_to_hex/1,
	combine_lists/2,
	get_process_info_and_zero_value/1,
	get_process_info_and_large_than_value/2,
	get_msg_queue/0,
	get_memory/0,
	get_heap/1,
	substr_utf8/2,
	substr_utf8/3,
	get_processes/0,
	list_to_term/1,
	ip_str/1,
	remove_string_black/1,
	split_string_to_intlist/1,
	split_string_to_intlist/3,
	intlist_to_string/1,
	change_list_to_string/1,
	date_to_unix/1,
	unix_to_date/1,
	substitute/2,
    get_unix_time/0,
    timestamp_to_datetime/1,
    term_to_bitstring/1,
    bitstring_to_term/1,
    get_dict_data/2,
    check_data/2,
    pin_id/2,
    make_player_id/3,
	un_playerid/1,
	do_send_after/3,
	cancel_sendafter/1,
	get_remain_of_timer/1
]).

-define(UNIX_BASE_TICK, 62167132800 - 32 * 60 * 60).

pin_id(Num1, Num2) ->
	list_to_integer(integer_to_list(Num1) ++ integer_to_list(Num2)).

do_send_after(MsTime, Msg, Timerref) ->
	cancel_sendafter(Timerref),
	S = erlang:send_after(MsTime, self(), Msg),
	put(Timerref, S).

cancel_sendafter(S)  when is_list(S) ->
	[cancel_sendafter(Timerref) || Timerref <- S];

%% 取消sendafter
cancel_sendafter(S) ->
    case erase(S) of
      	undefined ->
        	pass;
      	Timerref ->
        	erlang:cancel_timer(Timerref)
    end.

get_remain_of_timer(Timerref) ->
	case get(Timerref) of
		undefined ->
			0;
		S ->
			erlang:read_timer(S)
	end.


%% @doc get IP address string from Socket
ip(Socket) ->
	{ok, {IP, _Port}} = inet:peername(Socket),
	{Ip0,Ip1,Ip2,Ip3} = IP,
	list_to_binary(integer_to_list(Ip0)++"."++integer_to_list(Ip1)++"."++integer_to_list(Ip2)++"."++integer_to_list(Ip3)).


%% @doc quick sort
sort([]) ->
	[];
sort([H|T]) -> 
	sort([X||X<-T,X<H]) ++ [H] ++ sort([X||X<-T,X>=H]).

%% for
for(Max,Max,F)->[F(Max)];
for(I,Max,F)->[F(I)|for(I+1,Max,F)].


%% @doc convert float to string,  f2s(1.5678) -> 1.57
f2s(N) when is_integer(N) ->
	integer_to_list(N) ++ ".00";
f2s(F) when is_float(F) ->
	[A] = io_lib:format("~.2f", [F]),
	A.

%% @doc convert other type to atom
to_atom(Msg) when is_atom(Msg) -> 
	Msg;
to_atom(Msg) when is_binary(Msg) -> 
	list_to_atom2(binary_to_list(Msg));
to_atom(Msg) when is_list(Msg) -> 
	list_to_atom2(Msg);
to_atom(_) -> 
	throw(other_value).  %%list_to_atom("").

%% @doc convert other type to list
to_list(Msg) when is_list(Msg) -> 
	Msg;
to_list(Msg) when is_atom(Msg) -> 
	atom_to_list(Msg);
to_list(Msg) when is_binary(Msg) -> 
	binary_to_list(Msg);
to_list(Msg) when is_integer(Msg) -> 
	integer_to_list(Msg);
to_list(Msg) when is_float(Msg) -> 
	f2s(Msg);
to_list(Msg) when is_tuple(Msg) ->
	tuple_to_list(Msg);
to_list(_) ->
	throw(other_value).

%% @doc convert other type to binary
to_binary(Msg) when is_binary(Msg) -> 
	Msg;
to_binary(Msg) when is_atom(Msg) ->
	list_to_binary(atom_to_list(Msg));
%%atom_to_binary(Msg, utf8);
to_binary(Msg) when is_list(Msg) -> 
	list_to_binary(Msg);
to_binary(Msg) when is_integer(Msg) -> 
	list_to_binary(integer_to_list(Msg));
to_binary(Msg) when is_float(Msg) -> 
	list_to_binary(f2s(Msg));
to_binary(Msg) when is_tuple(Msg) ->
	list_to_binary(tuple_to_list(Msg));
to_binary(_Msg) ->
	throw(other_value).

%% @doc convert other type to integer
-spec to_integer(Msg :: any()) -> integer().
to_integer(Msg) when is_integer(Msg) -> 
	Msg;
to_integer(Msg) when is_binary(Msg) ->
	Msg2 = binary_to_list(Msg),
	list_to_integer(Msg2);
to_integer(Msg) when is_list(Msg) -> 
	list_to_integer(Msg);
to_integer(Msg) when is_float(Msg) -> 
	round(Msg);
to_integer(_Msg) ->
	throw(other_value).

to_bool(D) when is_integer(D) ->
	D =/= 0;
to_bool(D) when is_list(D) ->
	length(D) =/= 0;
to_bool(D) when is_binary(D) ->
	to_bool(binary_to_list(D));
to_bool(D) when is_boolean(D) ->
	D;
to_bool(_D) ->
	throw(other_value).

%% @doc convert other type to tuple
to_tuple(T) when is_tuple(T) -> T;
to_tuple(T) when is_list(T) -> 
	list_to_tuple(T);
to_tuple(T) -> {T}.

%% @doc get data type {0=integer,1=list,2=atom,3=binary}
get_type(DataValue,DataType)->
	case DataType of
		0 ->
			DataValue2 = binary_to_list(DataValue),
			list_to_integer(DataValue2);
		1 ->
			binary_to_list(DataValue);
		2 ->
			DataValue2 = binary_to_list(DataValue),
			list_to_atom(DataValue2);
		3 -> 
			DataValue
	end.

%% @spec is_string(List)-> yes|no|unicode  
is_string([]) -> yes;
is_string(List) -> is_string(List, non_unicode).

is_string([C|Rest], non_unicode) when C >= 0, C =< 255 -> is_string(Rest, non_unicode);
is_string([C|Rest], _) when C =< 65000 -> is_string(Rest, unicode);
is_string([], non_unicode) -> yes;
is_string([], unicode) -> unicode;
is_string(_, _) -> no.

ceil(X) ->
	T = trunc(X),
	if 
		X - T == 0 ->
			T;
		true ->
			if
				X > 0 ->
					T + 1;
				true ->
					T
			end			
	end.

floor(X) ->
	T = trunc(X),
	if 
		X - T == 0 ->
			T;
		true ->
			if
				X > 0 ->
					T;
				true ->
					T-1
			end
	end.

%% subatom
subatom(Atom,Len)->	
	list_to_atom(lists:sublist(atom_to_list(Atom),Len)).

sleep(Msec) ->
	receive
		after Msec ->
			true
	end.

md5(S) ->        
	Md5_bin =  erlang:md5(S), 
	Md5_list = binary_to_list(Md5_bin), 
	lists:flatten(list_to_hex(Md5_list)). 

list_to_hex(L) -> 
	lists:map(fun(X) -> int_to_hex(X) end, L). 

int_to_hex(N) when N < 256 -> 
	[hex(N div 16), hex(N rem 16)]. 
hex(N) when N < 10 -> 
	$0+N; 
hex(N) when N >= 10, N < 16 ->      
	$a + (N-10).

list_to_atom2(List) when is_list(List) ->
	case catch(list_to_existing_atom(List)) of
		{'EXIT', _} -> erlang:list_to_atom(List);
		Atom when is_atom(Atom) -> Atom
	end.

combine_lists(L1, L2) ->
	Rtn = 
		lists:foldl(
		  fun(T, Acc) ->
				  case lists:member(T, Acc) of
					  true ->
						  Acc;
					  false ->
						  [T|Acc]
				  end
		  end, lists:reverse(L1), L2),
	lists:reverse(Rtn).

get_process_info_and_zero_value(InfoName) ->
	PList = erlang:processes(),
	ZList = lists:filter( 
			  fun(T) -> 
					  case erlang:process_info(T, InfoName) of 
						  {InfoName, 0} -> false; 
						  _ -> true 	
					  end
			  end, PList ),
	ZZList = lists:map( 
			   fun(T) -> {T, erlang:process_info(T, InfoName), erlang:process_info(T, registered_name)} 
			   end, ZList ),
	[ length(PList), InfoName, length(ZZList), ZZList ].

get_process_info_and_large_than_value(InfoName, Value) ->
	PList = erlang:processes(),
	ZList = lists:filter( 
			  fun(T) -> 
					  case erlang:process_info(T, InfoName) of 
						  {InfoName, VV} -> 
							  if VV >  Value -> true;
								 true -> false
							  end;
						  _ -> true 	
					  end
			  end, PList ),
	ZZList = lists:map( 
			   fun(T) -> {T, erlang:process_info(T, InfoName), erlang:process_info(T, registered_name)} 
			   end, ZList ),
	[ length(PList), InfoName, Value, length(ZZList), ZZList ].

get_msg_queue() ->
	io:fwrite("process count:~p~n~p value is not 0 count:~p~nLists:~p~n", 
			  get_process_info_and_zero_value(message_queue_len) ).

get_memory() ->
	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n", 
			  get_process_info_and_large_than_value(memory, 1048576) ).

%% get_memory(Value) ->
%% 	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n", 
%% 				get_process_info_and_large_than_value(memory, Value) ).
%% 
%% get_heap() ->
%% 	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n", 
%% 				get_process_info_and_large_than_value(heap_size, 1048576) ).

get_heap(Value) ->
	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n", 
			  get_process_info_and_large_than_value(heap_size, Value) ).

get_processes() ->
	io:fwrite("process count:~p~n~p value is large than ~p count:~p~nLists:~p~n",
			  get_process_info_and_large_than_value(memory, 0) ).


list_to_term(String) ->
	{ok, T, _} = erl_scan:string(String++"."),
	case erl_parse:parse_term(T) of
		{ok, Term} ->
			Term;
		{error, Error} ->
			Error
	end.


substr_utf8(Utf8EncodedString, Length) ->
	substr_utf8(Utf8EncodedString, 1, Length).
substr_utf8(Utf8EncodedString, Start, Length) ->
	ByteLength = 2*Length,
	Ucs = xmerl_ucs:from_utf8(Utf8EncodedString),
	Utf16Bytes = xmerl_ucs:to_utf16be(Ucs),
	SubStringUtf16 = lists:sublist(Utf16Bytes, Start, ByteLength),
	Ucs1 = xmerl_ucs:from_utf16be(SubStringUtf16),
	xmerl_ucs:to_utf8(Ucs1).

ip_str(IP) ->
	case IP of
		{A, B, C, D} ->
			lists:concat([A, ".", B, ".", C, ".", D]);
		{A, B, C, D, E, F, G, H} ->
			lists:concat([A, ":", B, ":", C, ":", D, ":", E, ":", F, ":", G, ":", H]);
		Str when is_list(Str) ->
			Str;
		_ ->
			[]
	end.

remove_string_black(L) ->
	F = fun(S) ->
				if S == 32 -> [];
				   true -> S
				end
		end,
	Result = [F(lists:nth(I,L)) || I <- lists:seq(1,length(L))],
	lists:filter(fun(T) -> T =/= [] end,Result).

split_string_to_intlist(SL) ->
	if SL =:= undefined ->
		   [];
	   true ->
		   split_string_to_intlist(SL, "|", ",")
	end.

split_string_to_intlist(SL, Split1, Split2) ->
	NewSplit1 = to_list(Split1),
	NewSplit2 = to_list(Split2),
	SList = string:tokens(to_list(SL), NewSplit1),
	F = fun(X,L) -> 
				case string:tokens(X, NewSplit2) of
					[M,N] ->
						{V1,_} = string:to_integer(M),
						{V2,_} = string:to_integer(N), 
						[{V1,V2}|L];
					
					[M,N,O] ->
						{V1,_} = string:to_integer(M),
						{V2,_} = string:to_integer(N),
						{V3,_} = string:to_integer(O),
						[{V1,V2,V3}|L];
					[M,N,O,P] ->
						{V1,_} = string:to_integer(M),
						{V2,_} = string:to_integer(N),
						{V3,_} = string:to_integer(O),
						{V4,_} = string:to_integer(P),
						[{V1,V2,V3,V4}|L];
					[M,N,O,P,I] ->
						{V1,_} = string:to_integer(M),
						{V2,_} = string:to_integer(N),
						{V3,_} = string:to_integer(O),
						{V4,_} = string:to_integer(P),
						{V5,_} = string:to_integer(I),
						[{V1,V2,V3,V4,V5}|L];
					[M,N,O,P,Q,I] ->
						{V1,_} = string:to_integer(M),
						{V2,_} = string:to_integer(N),
						{V3,_} = string:to_integer(O),
						{V4,_} = string:to_integer(P),
						{V5,_} = string:to_integer(Q),
						{V6,_} = string:to_integer(I),
						[{V1,V2,V3,V4,V5,V6}|L];
					[M] ->
						{V1,_} = string:to_integer(M),
						[{V1}|L];
					_ ->
						L
				end 
		end,
	lists:foldr(F,[],SList).


intlist_to_string(List) ->
	F = fun({Type,Value}, [[_|Acce], String]) ->     
				if
					erlang:length(Acce) =:= 0 ->
						String1 = lists:concat([Type, ',', Value]),
						String2 = string:concat(String, String1),
						[Acce, String2];
					
					true ->
						String1 = lists:concat([Type, ',', Value, '|']),
						String2 = string:concat(String, String1),
						[Acce, String2]
				end
		end,
	[_, FinalString] = lists:foldl(F, [List, ""], List),
	FinalString.

change_list_to_string(List) ->
	F = fun({Type,Value}, [[_|Acce], String]) ->     
				if
					erlang:length(Acce) =:= 0 ->
						String1 = lists:concat([Type, '|', Value]),
						String2 = string:concat(String, String1),
						[Acce, String2];
					
					true ->
						String1 = lists:concat([Type, '|', Value, ',']),
						String2 = string:concat(String, String1),
						[Acce, String2]
				end
		end,
	[_, FinalString] = lists:foldl(F, [List, ""], List),
	FinalString.

date_to_unix(Date) ->
	Dates = string:tokens(Date, "-"),
	{Year, Month, Day} = tool:to_tuple(Dates),
	IYear = to_integer(Year),
	IMonth = to_integer(Month),
	IDay = to_integer(Day),
	Tick = calendar:datetime_to_gregorian_seconds({{IYear, IMonth, IDay}, {0, 0, 0}}),
	UnixTick = Tick - ?UNIX_BASE_TICK,
	UnixTick.


%% @doc  re:replace("abcd","c","[&]",[{return,list}]).
substitute(Subject,Replacement) when is_list(Replacement) ->
	[Acc|_] = Replacement,
	substitute(Subject,Acc);

substitute(Subject,Replacement) ->
	re:replace(Subject, "{}", Replacement,[{return,list}]).
	

unix_to_date(Tick) ->
	calendar:gregorian_seconds_to_datetime(Tick + 62167132800 + 32 * 60 * 60).

%获取时间戳
get_unix_time() ->
    Time=calendar:universal_time(),
    datetime_to_timestamp(Time).

% 时间转时间戳，格式：{{2013,11,13}, {18,0,0}}
datetime_to_timestamp(DateTime) ->
    calendar:datetime_to_gregorian_seconds(DateTime) - calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}).

% 时间戳转时间
timestamp_to_datetime(Timestamp) ->
    calendar:gregorian_seconds_to_datetime(Timestamp + calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}})).

%当前时间格式
%{{Year, Month, Day}, {Hour, Minite, Second}} = calendar:local_time().
%{{2013,11,13},{20,10,10}}


%% 存
term_to_bitstring(Term) ->
    list_to_bitstring(term_to_string(Term)).

term_to_string(Term) ->
    io_lib:format("~w", [Term]).
%% 取
bitstring_to_term(BitString) -> 
    string_to_term(binary_to_list(BitString)).

string_to_term(String) ->
    case erl_scan:string(String ++ ".") of
        {ok, Tokens, _} -> erl_parse:parse_term(Tokens);
        {error, Err, _} -> {error, Err};
        Err -> {error, Err}
    end.

get_dict_data(Key, Default) ->
	case get(Key) of
		undefined ->
			Default;
		Value ->
			Value
	end.
check_data(undefined, Default) ->
	Default;
check_data(Data, _Default) when Data >= 0 ->
	Data;
check_data(_Data, Default) ->
	Default.



make_player_id(PlatformId, ServerId, PlayerId) ->
    SIndex = "1",
    SPlatformId = make_platformid(PlatformId),
    SServerId = make_serverid(ServerId),
    SPlayerId = make_playerid(PlayerId),
    Id = SIndex ++ SPlatformId ++ SServerId ++ SPlayerId,
    list_to_integer(Id).

make_platformid(PlatformId) ->
    P = integer_to_list(PlatformId),
    Psize = length(P),
    if
        Psize =:= 4 ->
            P;
        Psize =:= 3 ->
            "0" ++ P;
        Psize =:= 2 ->
            "00" ++ P;
        Psize =:= 1 ->
            "000" ++ P;
        true ->
            "0001"
    end.


make_serverid(ServerId) ->
    S = integer_to_list(ServerId),
    Size = length(S),
    if
        Size =:= 4 ->
            S;
        Size =:= 3 ->
            "0" ++ S;
        Size =:= 2 ->
            "00" ++ S;
        Size =:= 1 ->
            "000" ++ S;
        true ->
            "0001"
    end.

make_playerid(PlayerId) ->
    S = integer_to_list(PlayerId),
    Size = length(S),
    if
        Size =:= 6 ->
            S;
        Size =:= 5 ->
            "0" ++ S;
        Size =:= 4 ->
            "00" ++ S;
        Size =:= 3 ->
            "000" ++ S;
        Size =:= 2 ->
            "0000" ++ S;
        Size =:= 1 ->
            "00000" ++ S;
        true ->
            "000001"
    end.

un_playerid(PlayerId) ->
    PlatformId = PlayerId div 10000000000 rem 10000,
    ServerId = PlayerId div 1000000 rem 10000,
    Id = PlayerId rem 1000000,
    {PlatformId, ServerId, Id}.
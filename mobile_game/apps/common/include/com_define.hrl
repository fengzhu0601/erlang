-ifndef(COM_DEFINE_HRL).
-define(COM_DEFINE_HRL,true).

-define(atomic, atomic).
-define(undefined,undefined).
-define(true, true).
-define(false, false).
-define(nil, nil).
-define(error,error).
-define(none,none).
-define(next,next).
-define(break,break).
-define(nonproc, nonproc).
-define(badarg,badarg).
-define(yes,yes).
-define(reply, reply).
-define(noreply, noreply).
-define(normal,normal).
-define(protected, protected).
-define(private, private).
-define(public, public).
-define(write_concurrency, write_concurrency).
-define(read_concurrency, read_concurrency).
-define(keypos, keypos).
-define(value, value).
-define(infinity, infinity).
-define(named_table, named_table).
-define(end_of_table, '$end_of_table').
-define(attributes, attributes).
-define(behaviour, behaviour).
-define(set, set).
-define(ordered_set, ordered_set).
-define(disc_only_copies, disc_only_copies).
-define(disc_copies, disc_copies).
-define(latin1, latin1).
-define(shutdown, shutdown).
-define(not_enough, not_enough).
-define(key_exists, key_exists).
-define(mail_full, mail_full).




%%----------------------------------------------------
%% TIME
-define(MICOSEC_PER_SECONDS, 1000).  %% ms   -> sec
-define(SECONDS_PER_MINUTE, 60).     %% sec  -> min
-define(MICOSEC_PER_MINUTE, 60000).  %% ms   -> min
-define(MINUTES_PER_HOUR, 60).       %% min  -> hour
-define(SECONDS_PER_HOUR, 3600).     %% sec  -> hour
-define(SECONDS_PER_DAY, 86400).     %% sec  -> day

%%----------------------------------------------------
-define(INLINE(Name, Arg), -compile({inline, [Name/Arg]})).

%-select all [{'$1', [], ['$1']}]
%-define(pd_init)

-define(FALSE, 0).
-define(TRUE, 1).
-define(IS_BOOLEN(__N), ((__N) =:= ?TRUE orelse (__N =:= ?FALSE))).

-define(K, 1024).
-define(M, 1048576). %% 1024 * 1024

%% @doc if Condition is true exec Exp, else return ok.
-define(ifdo(Condition, Exp), case Condition of  true-> Exp; false -> ok end).
-define(ifdo(Condition, Exp1, Exp2), case Condition of  true-> Exp1, Exp2; false -> ok end).
-define(ifdo(Condition, Exp1, Exp2, Exp3), case Condition of  true-> Exp1, Exp2, Exp3; false -> ok end).
-define(ifdo(Condition, Exp1, Exp2, Exp3, Exp4), case Condition of  true-> Exp1, Exp2, Exp3, Exp4; false -> ok end).
-define(ifdo(Condition, Exp1, Exp2, Exp3, Exp4, Exp5), case Condition of  true-> Exp1, Exp2, Exp3, Exp4, Exp5; false -> ok end).





-define(if_(Condition, Exp), if Condition -> (Exp); true -> ok end).
-define(if_(Condition, _Exp1, _Exp2), if Condition -> _Exp1, _Exp2; true -> ok end).
-define(if_(Condition, _Exp1, _Exp2, _Exp3), if Condition -> _Exp1, _Exp2, _Exp3; true -> ok end).
-define(if_(Condition, _Exp1, _Exp2, _Exp3, _Exp4), if Condition -> _Exp1, _Exp2, _Exp3, _Exp4; true -> ok end).
-define(if_(Condition, _Exp1, _Exp2, _Exp3, _Exp4, _Exp5), if Condition -> _Exp1, _Exp2, _Exp3, _Exp4, _Exp5; true -> ok end).
-define(if_(Condition, _Exp1, _Exp2, _Exp3, _Exp4, _Exp5, _Exp6), if Condition -> _Exp1, _Exp2, _Exp3, _Exp4, _Exp5, _Exp6; true -> ok end).


-define(if_undefined(Condition, Exp), case Condition of ?undefined -> (Exp); _ -> ok end).
-define(if_else(Condition, Exp, Else), case begin Condition end of  true-> (Exp); false -> (Else) end).

-define(open_trap_exit(), (process_flag(trap_exit, true))).

%% for com_record
-define(recrod_put_pd(R, Name), com_record:put_pd_fields(R, record_info(fields, Name))).
-define(recrod_get_pd(Name), com_record:get_pd_fields(Name, record_info(fields, Name))).

-define(make_record_fields(Name), [Name] ++ record_info(fields, Name)).

%% pipe for elixir |
%%-define(pipe(_1,_2), _2())

-define(random(N), rand:uniform(N)).

-define(pname(), (com_process:get_name())).
-define(ptype(), (com_process:get_type())).

-define(tcp_send(Socket, Bin), gen_tcp:send(Socket, Bin)).

-define(tcp_send_and_close(Socket, Bin), ok=gen_tcp:send(Socket, Bin), ok=gen_tcp:close(Socket)).

-define(send_after_self(Time, Msg), erlang:send_after((Time), self(), Msg)).

-define(record_fields(Name), record_info(fields, Name)).
-define(record_size(Name), record_info(size, Name)).

-define(fmt(Str, Args), lists:flatten(io_lib:format(Str, Args))).

%% process dirc op
-define(pd_new_struct_data(Key, Data, Record),
	com_record:update_old_data(Key, Data, Record)
	).
-define(pd_new(Key, Data), ?undefined=erlang:put(Key, Data)).
-define(pd_new(Key, Data, DefaultVal), 
		case Data of 
			?undefined -> 
				?undefined=erlang:put(Key, DefaultVal); 
			_ -> 
				?undefined=erlang:put(Key, Data) 
		end).

%%-define(pd_list_new(Key), ?pd_new(Key,[])).
%%-define(pd_list_push_front(Key, Member), erlang:put(Key, [Member | erlang:get(Key)])).
%%-define(pd_list_clean(Key), erlang:put(Key, [])).


%% type convert
-define(i2l(__I), integer_to_list(__I)).
-define(a2l(__A), atom_to_list(__A)).
-define(a2b(__A), atom_to_binary(__A, ?latin1)).
-define(b2l(__L), binary_to_list(__L)).
-define(l2b(__L), list_to_binary(__L)).
-define(l2i(__L), list_to_integer(__L)).
-define(l2t(__L), list_to_tuple(__L)).
-define(l2a(__L), list_to_atom(__L)).
-define(t2l(__T), tuple_to_list(__T)).
-define(i2b(__L), integer_to_binary(__L)).
-define(b2i(__L), binary_to_integer(__L)).

%% groud
-define(is_pos_integer(_I), (is_integer(_I) andalso _I > 0)).

%% remove record name
-define(r2t(__R), erlang:delete_element(1, __R)).

%% binary
-define(pkg_u16(Data), (Data):16).
-define(pkg_u32(Data), (Data):32).
-define(pkg_u64(Data), (Data):64).
-define(pkg_sstr(Data), (erlang:byte_size(Data)), (Data)/binary).
-define(pkg_str(Data), (erlang:byte_size(Data)):16, (Data)/binary).
-define(pkg_binary(B), (B)/binary).

-define(unpkg_u16(Data), Data:16).
-define(unpkg_u32(Data), Data:32).
-define(unpkg_u64(Data), Data:64).
-define(unpkg_str(L,N), L:16, N:L/binary).
-define(unpkg_sstr(L,N), L:8, N:L/binary).

%% -> {error, Why} | _.
-define(safe_element(_Index, _Tuple), case catch element(_Index, _Tuple) of {'EXIT', {__R, _}} -> {error, __R}; __N -> __N end).

%% TYPE LIMIT
-define(MIN_CHAR ,(-128)).
-define(MAX_CHAR,	127).

-define(MAX_UINT8,  255).
-define(MAX_UINT16, 65535).
-define(MAX_UINT32, 4294967295).
-define(MAX_UINT64,	18446744073709551615).

-define(MIN_INT16, (-32768)).
-define(MAX_INT16, 	32767).

-define(MIN_INT32, (-?MAX_INT32- 1)).
-define(MAX_INT32, 2147483647).


%% =========== logic =======================================
-define(MAX_SERVER_COUNT, 2500).
-define(ONLINE, 1).
-define(OFFLINE, 0).

-endif.

-module(com_md5).
-export([md5/1,
         md5bin/1,
         md5int/1,
         list_to_hex/1]).

%% ====================================================================
%% API functions
%% ====================================================================

-spec md5(atom()|
          integer()|
          list()|
          binary()) -> list().
md5(Atom) when erlang:is_atom(Atom)->
    md5(erlang:atom_to_binary(Atom,utf8));

md5(Int) when erlang:is_integer(Int)->
    md5(erlang:list_to_binary(erlang:integer_to_list(Int)));

md5(List) when erlang:is_list(List)->
    md5(erlang:list_to_binary(List));

md5(Data) ->
    Md5_bin =  erlang:md5(Data),
    Md5_list = binary_to_list(Md5_bin),
    lists:flatten(list_to_hex(Md5_list)).

md5bin(Data) ->
    << <<(element(X+1, {$0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$a,$b,$c,$d,$e,$f}))>> || <<X:4>> <= erlang:md5(Data) >>.

md5int(Data) when is_binary(Data) ->
    binary:decode_unsigned(erlang:md5(Data)).


-spec list_to_hex(list()) -> [integer()].
list_to_hex(L) ->
    lists:flatten(lists:map(fun(X) -> int_to_hex(X) end, L)).


%% ====================================================================
%% Internal functions
%% ====================================================================
-spec int_to_hex(integer()) -> [integer(), ...].
int_to_hex(N) when N < 256 ->
    [hex(N div 16), hex(N rem 16)].

-spec hex(integer()) -> integer().
hex(N) when N < 10 ->
    $0+N;

hex(N) when N >= 10, N < 16 ->
    $a + (N-10).

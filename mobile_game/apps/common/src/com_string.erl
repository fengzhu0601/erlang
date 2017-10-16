%%encoding:utf8
%% @doc  字符串常用操作
-module(com_string).

-export([sprintf/2,make_node/2,make_node_str/2,split_node/1,make_socket_str/1,make_ipaddress_str/1]).
-export([
         string_to_term/1,
         term_to_string/1,
         datetime_to_string/1,
         datetime_to_short_string/1,
         string_to_print_term/1,
         token_str/2,
         replace/3,
         utf_length/1
        ]).
-export([make_int_str/2,make_int_str/1]).
-export([upper_first_char/1]).
-export([escape_uri/1,binary_to_hexstring/1]).
-export([my_list_to_atom/1]).

my_list_to_atom(String)->
    try
        erlang:list_to_existing_atom(String)
    catch
        _E:_R ->
            erlang:list_to_atom(String)
    end.

make_int_str(Int)->
    make_int_str(0,Int).
make_int_str(LenNum,Int)->
    Str = integer_to_list(Int),
    StrLen = string:len(Str),
    NeedAdd = LenNum - StrLen,
    if
        NeedAdd > 0->
            lists:foldl(fun(_,AccStr)->
                                string:concat("0",AccStr)
                        end,Str,lists:seq(1, NeedAdd));
        true->
            Str
    end.

sprintf(Format,Data)->
    lists:flatten(io_lib:format(Format, Data)).

string_to_term(String)->
    case erl_scan:string(String++".") of
        {ok,Tokens,_}->
            case erl_parse:parse_term(Tokens) of
                {ok,Term}->
                    Term;
                _->
                    {}
            end;
        _->
            {}
    end.

term_to_string(Term)->
    lists:flatten(io_lib:format("~w", [Term])).

upper_first_char(String)->
    [First|Left] = String,
    NewFirst = string:to_upper(First),
    [NewFirst]++Left.

string_to_print_term(String)->
    lists:foldl(fun(C,Str0)->
                        case C of
                            $"-> Str0 ++ [$\\,$"];
                            _-> Str0 ++ [C]
                        end
                end, [], String).


datetime_to_string(DateTime)->
    {{Y,Mon,D},{H,Min,S}}=DateTime,
    sprintf("~p-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",[Y,Mon,D,H,Min,S]).

datetime_to_short_string(DateTime)->
    {{Y,Mon,D},{H,Min,S}}=DateTime,
    sprintf("~p~2..0w~2..0w~2..0w~2..0w~2..0w",[Y,Mon,D,H,Min,S]).
make_node_str(SName,Ip) when is_list(SName) and is_list(Ip)->
    SName ++ "@" ++ Ip;
make_node_str(SName,Ip) when is_atom(SName)and is_list(Ip)->
    make_node_str(atom_to_list(SName),Ip);
make_node_str(SName,Ip) when is_atom(SName)and is_atom(Ip)->
    make_node_str(atom_to_list(SName),atom_to_list(Ip));
make_node_str(_,_)->
    [].


make_node(SName,Ip) when is_list(SName) and is_list(Ip)->
    list_to_atom(SName ++ "@" ++ Ip);

make_node(SName,Ip) when is_atom(SName)and is_list(Ip)->
    make_node(atom_to_list(SName),Ip);

make_node(SName,Ip) when is_atom(SName)and is_atom(Ip)->
    make_node(atom_to_list(SName),atom_to_list(Ip));
make_node(_,_)->
    ''.

split_node(Node) when is_list(Node)->
    [SName,Host] = string:tokens(Node,"@"),
    {SName,Host};
split_node(Node) when is_atom(Node)->
    split_node(atom_to_list(Node));
split_node(_)->
    {}.

make_socket_str(Socket)->
    case inet:peername(Socket) of
        {error, _ } -> [];
        {ok,{Address,_Port}}->
            make_ipaddress_str(Address)
    end.

make_ipaddress_str({A1,A2,A3,A4})->
    string:join([   integer_to_list(A1),
                    integer_to_list(A2),
                    integer_to_list(A3),
                    integer_to_list(A4)], ".").

token_str(String,TokenStr)->
    Len = string:len(TokenStr),
    case string:str(String,TokenStr) of
        0->[String];
        1->
            LeftString = string:sub_string(String,Len+1),
            token_str(LeftString,TokenStr);
        I->
            FirstString = string:sub_string(String,1,I-1),
            LeftString = string:sub_string(String,I+Len),
            [FirstString|token_str(LeftString,TokenStr)]
    end.

replace(String,TokenStr,NewString)->
    SplitStrings = token_str(String,TokenStr),
    string:join(SplitStrings,NewString).

utf_length( StringBin ) ->
    byte_size(StringBin).

escape_uri(S) when is_list(S) ->
    escape_uri(unicode:characters_to_binary(S));
escape_uri(<<C:8, Cs/binary>>) when C >= $a, C =< $z ->
    [C] ++ escape_uri(Cs);
escape_uri(<<C:8, Cs/binary>>) when C >= $A, C =< $Z ->
    [C] ++ escape_uri(Cs);
escape_uri(<<C:8, Cs/binary>>) when C >= $0, C =< $9 ->
    [C] ++ escape_uri(Cs);
escape_uri(<<C:8, Cs/binary>>) when C == $. ->
    [C] ++ escape_uri(Cs);
escape_uri(<<C:8, Cs/binary>>) when C == $- ->
    [C] ++ escape_uri(Cs);
escape_uri(<<C:8, Cs/binary>>) when C == $_ ->
    [C] ++ escape_uri(Cs);
escape_uri(<<C:8, Cs/binary>>) ->
    escape_byte(C) ++ escape_uri(Cs);
escape_uri(<<>>) ->
    "".

escape_byte(C) ->
    "%" ++ hex_octet(C).

hex_octet(N) when N =< 9 ->
    [$0 + N];
hex_octet(N) when N > 15 ->
    hex_octet(N bsr 4) ++ hex_octet(N band 15);
hex_octet(N) ->
    [N - 10 + $A].

binary_to_hexstring(<<>>)->
    "";
binary_to_hexstring(Bin) when is_binary(Bin)->
    <<Byte:8,LefBin/binary>> = Bin,
    integer_to_hexstring(Byte) ++ binary_to_hexstring(LefBin);
binary_to_hexstring(_)->
    "".

integer_to_hexstring(Byte)->
    Str = erlang:integer_to_list(Byte,16),
    case length(Str) of
        1-> "0"++ Str;
        _-> Str
    end.

%% File    : hello.erl
%% Purpose : Brief demonstration of Luerl basics.
%% Use     $ erlc hello.erl && erl -pa ./ebin -s hello run -s init stop -noshell
%% Or      $ make hello

-module(hello).
-export([run/0]).

run() ->
    io:format("---------- hello ----------\n"),


    % execute a string
    luerl:do("print(\"Hello, Robert(o)!\")"),

    io:format("1 ---------- hello ----------\n"),

    % execute a file
    New = luerl:init(),
    {ok, New1} = luerl:evalfile("./hello2-10.lua", New),
    io:format("2 ---------- hello ---------- ~p \n", [New1]),

%%     % separately parse, then execute
%%     State0 = luerl:init(),
%%     {ok, Chunk, State1} = luerl:load("print(\"Hello, Chunk!\")", State0),
%%     {_Ret, _NewState} = luerl:do(Chunk, State1),

    done.

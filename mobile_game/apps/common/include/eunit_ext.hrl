-ifndef(EUNIT_EXT_HRL).
-define(EUNIT_EXT_HRL,1).
-include_lib("eunit/include/eunit.hrl").

%%% @doc extend eunit
-define(Assert2(BoolExpr, Fmt, List),
        ((fun() ->
                  case (BoolExpr) of
                      true -> ok;
                      _X ->
                          io:format(Fmt, List),
                          ?assert(BoolExpr)
                  end
          end)())).

-define(Assert(BoolExpr, String),
        ((fun() ->
                  case (BoolExpr) of
                      true -> ok;
                      _X ->
                          io:format(String),
                          ?assert(BoolExpr)
                  end
          end)())).

-define(AssertNot(BoolExpr, String), ?Assert((not (BoolExpr)), String)).
-define(AssertNot2(BoolExpr, Fmt, List), ?Assert2((not (BoolExpr)), Fmt, List)).

-define(AssertEqual(Expect, Expr, String),
        ((fun() ->
                  case (Expr) of
                      Expect -> ok;
                      _X ->
                          io:format(String),
                          ?assertEqual(Expect, Expr)
                  end
          end)())).


-define(AssertEqual2(Expect, Expr, Fmt, List),
        ((fun() ->
                  case (Expr) of
                      Expect -> ok;
                      _X ->
                          io:format(Fmt, List),
                          ?assertEqual(Expect, Expr)
                  end
          end)())).

-define(AssertNotEqual(Unexpected, Expr, String),
        ((fun() ->
                  case (Expr) of
                      Unexpected->
                          io:format(String),
                          ?assertNotEqual(Unexpected, Expr);
                      _ ->
                          ok
                  end
          end)())).



-define(AssertNotEqual2(Unexpected, Expr, Fmt, List),
        ((fun() ->
                  case (Expr) of
                      Unexpected ->
                          io:format(Fmt, List),
                          ?assertNotEqual(Unexpected, Expr);
                      _ ->
                          ok
                  end
          end)())).

-endif.

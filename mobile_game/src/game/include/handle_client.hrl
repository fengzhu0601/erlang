-behaviour(handle_client).
-export([handle_client/1]).

-define(defer_except_badmatch(__FnBody), handle_client:defer_exception_badmatch(fun() -> __FnBody end)).
-define(defer_except_badmatch_clean(), handle_client:defer_exception_badmatch_clean()).


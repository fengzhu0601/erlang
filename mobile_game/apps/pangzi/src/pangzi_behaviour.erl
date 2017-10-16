%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc db_mode behaviour definiton.
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(pangzi_behaviour).


-define(no_pangzi_behaviour, 1).
-include("../include/pangzi.hrl").

%%% @doc behaviour 需要实现的就口
-callback load_db_table_meta() -> [pangzi:db_table_meta()].

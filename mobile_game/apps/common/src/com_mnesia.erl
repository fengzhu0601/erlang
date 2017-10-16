%%% coding:utf-8
%%%-------------------------------------------------------------------
%%% @author zl
%%% @doc mnesia tools func.
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(com_mnesia).

-export([table_size/1,
         get_all_tables/0,
         is_exist_table/1
        ]).


table_size(Table) ->
    mnesia:table_info(Table, size).

%% @doc get all table names.
%% -> [atom()]
get_all_tables() ->
    mnesia:system_info(tables).

is_exist_table(Table) ->
    lists:member(Table, get_all_tables()).

%%-------------------------------------------------------------------
%%% @author wcg
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 四月 2015 4:07 PM
%%%-------------------------------------------------------------------
-module(pet_global_server).

-include_lib("pangzi/include/pangzi.hrl").
-include("inc.hrl").

-include("pet.hrl").

-behaviour(gen_server).


-export([start_link/0
    , add_pet/1  %添加一个宠物蛋信息
    , del_pet/1  %移除一个宠物蛋信息
    , get_pet/1  %获取宠物蛋信息
]).

-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-record(state, {}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

load_db_table_meta() ->
    [
        #db_table_meta{
            name = ?pet_global_tab,
            fields = ?record_fields(?pet_global_tab),
            shrink_size = 10,
            flush_interval = 5}
    ].

init(_) ->
    {ok, #state{}}.

handle_call({add_pet, Pet}, _From, State) ->
    Reply = dbcache:insert_new(?pet_global_tab, #player_pet_egg_tab{pet_id = Pet#pet.id, pet_info = Pet}),
    {reply, Reply, State};

handle_call({del_pet, PetId}, _From, State) ->
    Reply = dbcache:delete(?pet_global_tab, PetId),
    {reply, Reply, State};

handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

add_pet(Pet) ->
    gen_server:call(?MODULE, {add_pet, Pet}).

del_pet(PetId) ->
    gen_server:call(?MODULE, {del_pet, PetId}).

get_pet(PetId) ->
    case dbcache:lookup(?pet_global_tab, PetId) of
        [] -> [];
        [Pet] -> Pet#player_pet_egg_tab.pet_info
    end.
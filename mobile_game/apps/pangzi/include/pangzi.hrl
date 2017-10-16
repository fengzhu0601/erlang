-ifndef(PERSISTENCE_LIB_HRL).
-define(PERSISTENCE_LIB_HRL, 1).

-define(db_table_meta, db_table_meta).


%% @doc db table 信息
%% @doc 持久化元信息
%%
-record(db_table_meta,
        {name = erlang:exit(need_field) :: atom(),  %% table 名称,要和存入的record同名，并且record的第一个field必须是主键
         type = set :: set | ordered_set , %% TODO 支持bag
         %%keypos = erlang:exit(need_keypos), %% 由于numsia 写死了是第一个属性 所以定死keypos 为第一个属性
         fields = erlang:exit(need_field) ::list(), %% recrod_info(field, table),
         record_name :: atom(), %% 当ｎａｍｅ　和使用的recrode 不同名时必须指定使用的ｒｅｃｏｒｄ的ｎａｍｅ
         flush_interval =1 :: non_neg_integer()  , %% TODO  0 是支持直接写 %% 每次时就化数据的时间间隔 单位minues
         kv = false ::boolean(),
         defualt_values :: tuple(), %% 如果指定kv 必须设置此项, =#table{}
         %%   易于Rom的更新，但是会消耗一些额外的空间，
         %%   如果制定kv
         load_all = false :: boolean(), %% 是否启动是加载所有数据
         index = [], %% filde name 如果开启kv 模式则不能设置index
         shrink_size, %%erlang:exit(need_shrink_size),  %% 当表大于此MB时试着shrink cache
         shrink_interval = 30,  %% 每次shrink的时间间隔, 分钟
         init :: fun() %% 在第一次创建表的时候调用
        }).

%%-export_type([db_table_meta/0]).
-type db_table_meta() :: #db_table_meta{}.

-define(pangzi_behaviour,  pangzi_behaviour).

-ifndef(no_pangzi_behaviour).
%% @doc db behavior
-behaviour(?pangzi_behaviour).
-export([load_db_table_meta/0]).
-endif.


-endif.

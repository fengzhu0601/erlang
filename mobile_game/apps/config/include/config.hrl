-ifndef(CONFIG_HRL).
-define(CONFIG_HRL, 1).


%% 1. < 
%%index2itemtps(Index) when Index =< 0  ->
    %%undefined;
%%index2itemtps(Index) when Index =< 1 ->
    %%[{21726,2},{23088,4},{23057,10}];
%%index2itemtps(Index) when Index =< 2 ->
    %%[{21725,2},{23088,4},{23057,10}];
%%index2itemtps(Index) when Index =< 3 ->
    %%[{22713,3},{23088,3},{23057,8}];
%%index2itemtps(Index) when Index =< 4 ->
    %%[{22713,2},{23088,2},{23057,6}];


%%3.
%%## 多field key
%%   [#xx.type, #xx,level]
%%   实际上row为2tuple key，record

%% @doc 配置信息
%% ets 名和 record 的名字相同
-record(config_meta,
        {record = erlang:exit(need_record)       :: tuple(),  %% 映射为的record类型
         name, %% 默认为record 的名字
         fields = erlang:exit(need_fields), %% pos, or [Pos]
         file  = erlang:exit(need_file)         :: none |  {Dir::string(), FileSuffix::string()},
                           %% 如果配置是由摸个目录下多个文件组成的,文件名是一个隐士id
                           %% 这里配置目录的名字,
                           %% 这时会自动导出一个lookup_file_XXX/1(SpaceKey)
                           %% e.g. file={"monster", ".txt"}, monster/*.txt
                           %% then the verity is a fun(FileId, Row)

         keypos = erlang:exit(need_keypos),
         rewrite, %% ->fun(_) -> [NewConfigRow]      %% 在load 所有数据后verify之前调用 , 不能更改key值一般用来对原有数据修改
         verify = erlang:exit(need_verify)        :: config:config_verify_fun(),

         all = [], %% 需要得到一个fields的所有配置 使用lookup_all_XX/1 查询
         groups = [], %%  field_pos 会生成 lookup_group_XX/2 -> [key]
         %% TODO none_value %% lookup_xxx 没有找的时返回的值

         %%unqiue

         is_compile = false %% 是否把config 编译为erlang 格式
        }).


-define(config_behavior, config).

-ifndef(no_config_transform).

-behaviour(?config_behavior).
-compile({parse_transform, config}).
%% config_behavior callback
-export([load_config_meta/0]).

-endif.




-endif.

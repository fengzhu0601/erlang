%%%-------------------------------------------------------------------
%%% @author fengzhu
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 八月 2016 下午3:03
%%%-------------------------------------------------------------------
-author("fengzhu").

%% cd_key规则
-record(cd_key_rule, {
    id = 0,           %% cd_key的组成部分
    length = 0,       %% cd_key每部分的组成长度
    range = 0        %% cd_key的取值范围
}).

%% cd_key
-record(cd_key_pt, {
    id = 0,
    platform = 0,   %% cd_key的使用平台
    server = 0,     %% cd_key的使用服务器
    duration = 0,   %% cd_key的有效时间(单位：天)
    prize_id = 0,    %% cd_key对应的奖励id
    usetimes = 0,   %% cd_key使用次数
    type = 0,       %% 类型
    sum = 0        %% cd_key的生成个数
}).

-define(range1, 1). %% Sa_z
-define(range2, 2). %% SA_Z
-define(range3, 3). %% S0_9

-define(Sa_z,
    ["a","b","c","d","e","f","g","h","i","j","k","l","m",
        "n","o","p","q","r","s","t","u","v","w","x","y","z"]
).

-define(SA_Z,
    ["A","B","C","D","E","F","G","H","I","J","K","L","M",
        "N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
).

-define(S0_9,
    ["0","1","2","3","4","5","6","7","8","9"]
).

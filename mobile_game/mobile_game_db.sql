CREATE DATABASE /*!32312 IF NOT EXISTS*/`fengzhu` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `fengzhu`;
#####################################################################################################################
#游戏玩家  1#
create table account(
    id int unsigned not null auto_increment primary key,
    account_id int unsigned not null default 0 comment '玩家帐号ID',
    player_id longtext comment '多个玩家ID',
    password varchar(64) not null default '888888' comment'玩家密码',
    player_statue tinyint unsigned not null default 1 comment'角色状态1正常 0锁定',
    account_statue tinyint unsigned not null default 1 comment'帐号状态1正常 0锁定',
    real_time int unsigned not null comment'创建时间',
    login_ip varchar(15) not null default '000.000.000' comment'登录ip',
    platform_id int unsigned not null default 1 comment'平台ID',
    account_name varchar(64) not null comment'帐号名字'
)engine=innodb default charset=utf8 comment'游戏玩家表';

#玩家角色  2# 
create table player(
    id bigint unsigned not null primary key comment'主键or角色ID',
    server_id int unsigned not null comment'区服',
    name varchar(30) not null comment'角色名称',
    job tinyint unsigned not null comment'职业',
    level int unsigned not null default 1 comment'角色等级',
    cur_exp bigint unsigned not null default 0 comment'经验',
    zuanshi_num bigint unsigned not null default 0 comment'钻石',
    jinbi_num bigint unsigned not null default 0 comment'金币',
    chongzhi_zuanshi bigint unsigned not null default 0 comment'充值的总钻石',
    cost_zuanshi bigint unsigned not null default 0 comment'消耗的总钻石',
    comb_power int unsigned not null default 0 comment'战斗力',
    family_id int unsigned not null default 0 comment'家族ID',
    create_time int unsigned not null default 0 comment'创建时间',
    vip_level tinyint unsigned not null default 0 comment'角色VIP等级',
    platform_id int unsigned not null default 1 comment'平台ID'
)engine=innodb default charset=utf8 comment'玩家表';



#封禁帐号列表  3#
create table account_tab(
    id bigint unsigned not null primary key,
    account_id int unsigned not null comment '帐号ID',
    time int unsigned not null comment'封停时间',
    info varchar(255) not null default '无' comment'描述',
    name varchar(30) not null comment'操作人',
    make_time int unsigned not null comment'操作时间',
    platform_id int unsigned not NULL default 1 comment'平台ID',
    server_id int unsigned not null default 1 comment'区服'
)engine=innodb default charset=utf8 comment'封禁帐号列表';

#封禁角色列表  4#
create table player_freeze(
    id bigint unsigned not null primary key comment '角色ID',
    time int unsigned not null comment'封停时间',
    info varchar(255) not null default '无' comment'描述',
    name varchar(30) not null comment'操作人',
    make_time int unsigned not null comment'操作时间',
    platform_id int unsigned not null default 1 comment'平台ID',
    server_id int unsigned not null default 1 comment'区服'
)engine=innodb default charset=utf8 comment'封禁角色列表';

#禁言列表  5#
create table player_jinyan(
    id bigint unsigned not null primary key comment '角色ID',
    time int unsigned not null comment'禁言时间',
    info varchar(255) not null default '无' comment'描述',
    name varchar(30) not null comment'操作人',
    make_time int unsigned not null comment'操作时间',
    platform_id int unsigned not null default 1 comment'平台ID',
    server_id int unsigned not null default 1 comment'区服'
)engine=innodb default charset=utf8 comment'禁言列表';

#内部帐号列表  6#
create table player_neibuzhanghao(
    id bigint unsigned not null primary key comment '角色ID',
    info varchar(255) not null default '无' comment'描述',
    name varchar(30) not null comment'操作人',
    make_time int unsigned not null comment'操作时间',
    platform_id int unsigned not null default 1 comment'平台ID',
    server_id int unsigned not null default 1 comment'区服'
)engine=innodb default charset=utf8 comment'内部帐号列表';

#系统广播列表  7#
create table system_broadcast(
    id int unsigned not null primary key,
    xuhao varchar(255) not null comment '序号',
    start_time int unsigned not null comment'开始时间',
    end_time int unsigned not null comment'结束时间',
    interval_time int unsigned not null comment'时间间隔',
    type tinyint unsigned not null default 1 comment '广播类型',
    title varchar(255) not null default '无' comment '标题',
    content varchar(255) not null default '无' comment '内容',
    platform_id int unsigned not null default 1 comment'平台ID',
    server_id int unsigned not null default 1 comment'区服'
)engine=innodb default charset=utf8 comment'系统广播列表';

#实时在线玩家列表  8#
create table online_player(
    id int unsigned not null primary key,
    platform_id int unsigned not null default 1 comment'平台ID',
    server_id int unsigned not null default 1 comment'区服',
    player_count int unsigned not null default 0 comment'在线人数',
    account_count int unsigned not null default 0 comment'在线帐号人数'
)engine=innodb default charset=utf8 comment'实时在线玩家列表';

#充值玩家列表  9#
create table pay_player(
    id bigint unsigned not null primary key comment '角色ID',
    platform_id int unsigned not null default 1 comment'平台ID',
    server_id int unsigned not null default 1 comment'区服',
    chongzhi_count bigint unsigned not null default 0 comment'充值数量'
)engine=innodb default charset=utf8 comment'充值玩家列表';

#玩家注册帐号数量和创建角色数量和总充值数量列表  10#
create table server_data(
    id int unsigned not null primary key,
    platform_id int unsigned not null default 1 comment'平台ID',
    server_id int unsigned not null default 1 comment'区服',
    re_account_count int unsigned not null default 0 comment'注册帐号的数量',
    create_player_count int unsigned not null default 0 comment'创建角色的数量'
)engine=innodb default charset=utf8 comment'玩家注册帐号数量和创建角色数量和充值总数量列表';

#游戏服节点  11#
create table game_server_nodes(
    id int unsigned not null primary key,
    platform_id int unsigned not null default 1 comment'平台ID',
    platform_name varchar(30) not null default '墨麟' comment'平台名称',
    server_id int unsigned not null default 1 comment'区服ID',
    server_name varchar(30) not null default '龙之起源测试1区' comment'区服名称',
    node varchar(30) not null default '000.000.000' comment'节点名',
    ip varchar(15) not null default '000.000.000' comment'IP',
    game_prot int unsigned not null  comment'game PROT',
    gm_prot int unsigned not null  comment'gm PROT',
    time int unsigned not null comment'开服的时间'
)engine=innodb default charset=utf8 comment'游戏服节点';

# 后台物品表 12#
create table gm_goods(
    id int unsigned not null auto_increment primary key,
    bid int unsigned not null comment'物品bid',
    name varchar(30) not null comment'物品名字',
    type int unsigned not null comment'物品表'
)engine=innodb default charset=utf8 comment'后台物品表';

# CD_KEY表 13#
create table cd_keys(
    cd_key varchar(24) not null primary key unique comment'CD_KEY',
    platform_id int unsigned not null comment'平台ID',
    server_id int unsigned not null comment'区服ID',
    type int unsigned not null comment'类型',
    prize_id int unsigned not null comment'奖励ID',
    use_times int not null comment'可使用次数',
    create_time int unsigned not null comment'创建时间',
    deadline int unsigned not null comment'截止时间'
)engine=innodb default charset=utf8 comment'CD_KEY表';




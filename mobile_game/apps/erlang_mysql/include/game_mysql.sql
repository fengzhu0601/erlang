CREATE DATABASE /*!32312 IF NOT EXISTS*/`webdb2` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `webdb2`;
#####################################################################################################################
#游戏玩家  1#
CREATE TABLE account(
    id int unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
    account_id int unsigned NOT NULL COMMENT '玩家帐号ID',
    player_id int unsigned NOT NULL DEFAULT 0 COMMENT '玩家ID',
    PASSWORD VARCHAR(64) NOT NULL DEFAULT '888888' COMMENT'玩家密码',
    player_statue tinyint unsigned NOT NULL DEFAULT 1 COMMENT'角色状态1正常 0锁定',
    account_statue tinyint unsigned NOT NULL DEFAULT 1 COMMENT'帐号状态1正常 0锁定',
    real_time int unsigned NOT NULL COMMENT'创建时间',
    login_ip VARCHAR(15) NOT NULL DEFAULT '000.000.000' COMMENT'登录ip'
)ENGINE=INNODB DEFAULT CHARSET=utf8 COMMENT'游戏玩家表';

#玩家角色  2#
CREATE TABLE player(
    id int unsigned not null AUTO_INCREMENT PRIMARY KEY comment'主键',
    server_id int unsigned not null comment'区服',
    player_id int unsigned not null comment'角色ID',
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
    vip_level tinyint unsigned not null default 0 comment'角色VIP等级'
)engine=innodb default charset=utf8 comment'玩家表';



#封禁帐号列表  3#
create table account_tab(
    id int unsigned not null auto_increment primary key,
    account_id int unsigned not null comment '帐号ID',
    time int unsigned not null comment'封停时间',
    info varchar(255) not null default '无' comment'描述',
    name varchar(30) not null comment'操作人',
    make_time int unsigned not null comment'操作时间'
)engine=innodb default charset=utf8 comment'封禁帐号列表';

#封禁角色列表  4#
create table player_freeze(
    id int unsigned not null auto_increment primary key,
    player_id int unsigned not null comment '角色ID',
    time int unsigned not null comment'封停时间',
    info varchar(255) not null default '无' comment'描述',
    name varchar(30) not null comment'操作人',
    make_time int unsigned not null comment'操作时间'
)engine=innodb default charset=utf8 comment'封禁角色列表';

#禁言列表  5#
create table player_jinyan(
    id int unsigned not null auto_increment primary key,
    player_id int unsigned not null comment '角色ID',
    time int unsigned not null comment'禁言时间',
    info varchar(255) not null default '无' comment'描述',
    name varchar(30) not null comment'操作人',
    make_time int unsigned not null comment'操作时间'
)engine=innodb default charset=utf8 comment'禁言列表';

#内部帐号列表  6#
create table player_neibuzhanghao(
    id int unsigned not null auto_increment primary key,
    player_id int unsigned not null comment '角色ID',
    info varchar(255) not null default '无' comment'描述',
    name varchar(30) not null comment'操作人',
    make_time int unsigned not null comment'操作时间'
)engine=innodb default charset=utf8 comment'内部帐号列表';

#系统广播列表  6#
create table system_broadcast(
    id int unsigned not null auto_increment primary key,
    xuhao varchar(255) not null comment '序号',
    start_time int unsigned not null comment'开始时间',
    end_time int unsigned not null comment'结束时间',
    interval_time int unsigned not null comment'时间间隔',
    type tinyint unsigned not null default 1 comment '广播类型',
    title varchar(255) not null default '无' comment '标题',
    content varchar(255) not null default '无' comment '内容'
)engine=innodb default charset=utf8 comment'系统广播列表';
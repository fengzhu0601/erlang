REBAR = ./rebar
ALL_MODS_NAME = src/auto/defs/mod_name_def.hrl


DATE=`date +%F_%H_%M`
FILE = "mobile_game_${DATE}.tar.gz"

compile:
	@$(REBAR) compile

rebuild:
	make clean && make

clean:
	@$(REBAR) clean

gen_sys_log:
	@if [ ! -e src/include/sys_debug_log_enable.hrl ] ; then touch src/include/sys_debug_log_enable.hrl; fi
	@priv/tools/gen_log

def:
	@priv/tools/gen_defs && make

msg:
	@priv/tools/gen_proto && make

upmsg:
	cd src/proto; svn ci -m'ci'; cd -

gen:
	@rm -rf src/auto/defs/*
	@rm -rf src/auto/proto/*
	@priv/tools/gen_defs
	@priv/tools/gen_proto
	@priv/tools/gen_module_define
	@priv/tools/gen_robot_proto

upalione:
	rm -f git_version
	echo ${DATE} > git_version
	tar -czf $(FILE) apps/*/ebin apps/esqlite/priv apps/esqlite/c_src ebin priv/etc data git_version startup.sh
	scp $(FILE) one@120.24.100.174:~/game/version/

upalione_and_no_cfg:
	rm -f git_version
	echo ${DATE} > git_version
	tar -czf $(FILE) apps/*/ebin apps/esqlite/priv apps/esqlite/c_src ebin priv/etc git_version startup.sh
	scp $(FILE) one@120.24.100.174:~/game/version/

up142:
	rm -f git_version
	echo ${DATE} > git_version
	tar -czf $(FILE) apps/*/ebin apps/esqlite/priv apps/esqlite/c_src ebin priv/etc data git_version startup.sh
	scp $(FILE) santi_server@192.168.0.142:~/version/

rar:
	echo ${ABC}
	@cp game_list/win.config priv/etc/sys.config
	tar -czf  hand_game.tar.gz ebin win.bat win_robot.bat priv apps/*/ebin data lua
	cd _msg; svn up; mv ../hand_game.tar.gz  ./ ; svn ci -m'ci' ; cd -

tar_database:
	tar -czf  database_temp.tar.gz Database/*

update_database_174_2:
	scp one@120.24.100.174:/home/one/game/run/port4999/database_temp.tar.gz ~/server


all: $(ALL_MODS_NAME) compile


## --------------------------------------------------
## private
mk_dir:
	@if [ -d $(dir) ]; \
	then \
		echo "mkdir $(dir) ok"; \
	else \
		mkdir $(dir); \
		echo "mkdir $(dir) ok"; \
	fi;


cp_server_list:
	@cp game_list/Makefile_remote $(dest_dir)/Makefile
	@cp game_list/ali_s1.10.169.102.22.config $(dest_dir)/
	@cp game_list/ali_s1.10.170.156.59.config $(dest_dir)/
	@cp game_list/ali_s2.10.170.156.59.config $(dest_dir)/
	@cp game_list/share_142.192.168.0.142.config $(dest_dir)/
	@cp game_list/share_142_2.192.168.0.142.config $(dest_dir)/
	@cp game_list/qq.115.159.144.222.config $(dest_dir)/

cp_new_server_list:
	@cp game_list/Makefile_remote $(dest_dir)/Makefile
	@cp -ax game_list/'$(dirip)' $(dest_dir)/

cp_code:
	@make mk_dir dir=$(dest_dir)
	@make mk_dir dir=$(dest_dir)/priv
	@cp -ax apps/*/ebin $(dest_dir)/
	@cp -ax apps/esqlite/priv $(dest_dir)/
	@cp -ax apps/esqlite/c_src $(dest_dir)/
	@cp -ax ebin $(dest_dir)/
	@cp -ax priv/etc $(dest_dir)/priv
	@cp -ax lua $(dest_dir)/lua

cp_data:
	@cp -ax data $(dest_dir)

dest_dir=../mobile_game
node='s1@192.168.0.95'
st_erl:
	@echo "start server $(node)"
	cd $(dest_dir) && \
	erl  \
	+pc unicode \
	+P 2000000 \
	-smp enable \
	+K true \
	-pa apps/*/ebin \
	-pa ebin \
	-config priv/etc/sys.config \
	-s mobile_game_cmd start \
	-setcookie dragon_cookie \
	-name $(node)


st_robot:
	@echo "start robot $(node)"
	make compile
	erl \
	+swt medium \
	+sbwt none \
	+a 400 \
	+A 50 \
	-smp auto \
	-setcookie cookie123 \
	-pa apps/*/ebin \
	-pa ebin \
	+K true \
	+pc unicode \
	+P 10240000 \
	-config priv/etc/robot_sys.config \
	-name tt@client \
	-s mobile_game_cmd start_robot_app


## 打包版本
tar_version:
	@echo "tar_version"
	@make tar_code_src
	@rm -rf tar_version_temp
	@make mk_dir dir=tar_version_temp
	@tar -czf tar_version_temp/game.tar.gz \
	apps/*/ebin \
	apps/esqlite/priv \
	apps/esqlite/c_src \
	ebin \
	priv/etc \
	data
	## @make cp_server_list dest_dir=tar_version_temp
	@make cp_new_server_list dest_dir=tar_version_temp dirip=$(ip)
	@make mk_dir dir=temp
	@tar -czf temp/version_${DATE}.tar.gz tar_version_temp
	@rm -rf tar_version_temp

tar_code:
	@echo "tar_code"
	@make mk_dir dir=temp
	@tar -czf temp/code_${DATE}.tar.gz \
	apps/*/ebin \
	apps/esqlite/priv \
	apps/esqlite/c_src \
	lua \
	ebin
	@make tar_code_src

tar_code_src:
	@echo "tar_code_src"
	@make mk_dir dir=temp_src
	@tar -czf temp_src/code_src_${DATE}.tar.gz \
	apps/esqlite/priv \
	apps/esqlite/c_src \
	apps/*/src \
	priv \
	data \
	src

tar_data:
	@echo "tar_data"
	@make mk_dir dir=temp
	@tar -czf temp/data_${DATE}.tar.gz data


## ---------------------------
## 本地热更新
hot:
	@echo "compile server $(svr)"
	@cp -ax game_list/'$(svr).$(ip).config' release/'$(svr)@$(ip)'/game/priv/etc/sys.config
	@$(REBAR) compile
	make cp_code dest_dir=release/'$(svr)@$(ip)'/game


## 本地开启服务器
st:
	@$(REBAR) compile
	@make mk_dir dir=release
	@make mk_dir dir=release/'$(svr)@$(ip)'
	@rm -rf release/'$(svr)@$(ip)'/game
	make cp_code dest_dir=release/'$(svr)@$(ip)'/game
	make cp_data dest_dir=release/'$(svr)@$(ip)'/game
	cp -ax game_list/'$(svr).$(ip).config' release/'$(svr)@$(ip)'/game/priv/etc/sys.config
	cp Makefile release/'$(svr)@$(ip)'/game/
	make st_erl dest_dir=release/'$(svr)@$(ip)'/game node='$(svr)@$(ip)'

## 发布142
cm_version_142:
	make tar_version ip=192.168.0.142
	scp temp/version_${DATE}.tar.gz santi_server@192.168.0.142:~/version/


## 热更新代码
cm_hot_code_142:
	make tar_code
	scp temp/code_${DATE}.tar.gz santi_server@192.168.0.142:~/version/

## 热更新配置表
cm_hot_data_142:
	make tar_data
	scp temp/data_${DATE}.tar.gz santi_server@192.168.0.142:~/version/

## 下载数据库
update_database_142:
	scp santi_server@192.168.0.142:~/run/tar_version_temp/${svr}_database_2015-12-30_17_47.tar.gz ~/server

## 发布阿里
cm_version_ali:
	make tar_version ip=120.25.95.142
	scp temp/version_${DATE}.tar.gz one@120.25.95.142:~/game/version/

cm_version_qq:
	make tar_version ip=115.159.144.222
	scp temp/version_${DATE}.tar.gz ubuntu@115.159.144.222:~/game/version/

cm_version_ali_old:
	make tar_version ip=120.24.100.174
	scp temp/version_${DATE}.tar.gz one@120.24.100.174:~/game/version/


## 在指定节点创建mnesia
start_mnesia:
	erl \
	+pc unicode \
	+P 50000 \
	-smp enable \
	+K true \
	-pa apps/*/ebin \
	-pa ebin \
	-config priv/etc/sys.config \
	-s mobile_game_cmd start_pangzi \
	-setcookie dragon_cookie \
	-name $(node)
   
## 复制所有表到指定mnesia
copy_data:
	@mv ../Database/Mnesia.game/LATEST.LOG ../Database/
	@mv ../Database/Mnesia.game/schema.DAT ../Database/
	@cp -fr ../Database1/* ../Database/
	@mv -f ../Database/LATEST.LOG ../Database/Mnesia.game/
	@mv -f ../Database/schema.DAT ../Database/Mnesia.game/
	@echo "===========>copy database complete<==========="


st_95:
	make st svr=s1 ip='192.168.0.95'
st_142:
	make st svr=share_142 ip='192.168.0.142'
st_ali_1:
	make st svr=ali_s1 ip='10.170.156.59'

hot_95:
	make hot svr=s1 ip='192.168.0.95'

st_xiaodong:
	make st svr=xiaodong ip='192.168.0.236'

st_qq:
	make st svr=qq ip='115.159.144.222'

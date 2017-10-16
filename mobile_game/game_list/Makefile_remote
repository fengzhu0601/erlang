
DATE=`date +%F_%H_%M`

del_game:
	@echo "del_game server: $(svr)"
	@rm -rf $(svr)/game

del_all_game:
	@echo "del_all_game server"
	@rm -rf 'ali_s1@120.25.95.142'/game
	@rm -rf 'ali_s2@120.25.95.142'/game
	@rm -rf 's1@192.168.0.95'/game
	@rm -rf 's2@192.168.0.95'/game
	@rm -rf 'share_142@192.168.0.142'/game
	@rm -rf 'share_142_2@192.168.0.142'/game
	@rm -rf win/game
	@rm -rf xiaodong/game
	@rm -rf fengzhu/game

cp_game:
	@echo "build server: $(svr)"
	@make mk_dir dir=$(svr)
	@make mk_dir dir=$(svr)/game
	@tar -xzvf game.tar.gz -C $(svr)/game

mk_dir:
	@if [ -d $(dir) ]; \
	then \
		echo "exits $(dir)"; \
	else \
		mkdir $(dir); \
		echo "mkdir $(dir)"; \
	fi;

st:
	@echo "start server: $(svr)"
	@echo $(svr)@server > $(svr)/node_info
	@cp $(cfg) $(svr)/game/priv/etc/sys.config
	@cp Makefile $(svr)/game
	cd $(svr)/game && \
	erl  \
	+pc unicode \
	+P 50000 \
	-smp enable \
	+K true \
	-pa apps/*/ebin \
	-pa ebin \
	-config priv/etc/sys.config \
	-s mobile_game_cmd \
	-setcookie dragon_cookie \
	-name $(svr)

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

cm_data:
	@echo "cm_data server: $(svr)"
	@tar -xzvf game.tar.gz -C $(svr)/game


compress_database:
	@echo "up_database server: $(svr)"
	tar -czf $(svr)_database_${DATE}.tar.gz $(svr)/Database/* $(svr)/node_info


st_ali_1_old:
	make cp_game svr='ali_s1@10.169.102.22'
	make st cfg='ali_s1.10.169.102.22.config' svr='ali_s1@10.169.102.22'

st_ali_1:
	make cp_game svr='ali_s1@10.170.156.59'
	make st cfg='ali_s1.10.170.156.59.config' svr='ali_s1@10.170.156.59'


st_share_142:
	make cp_game svr='share_142@192.168.0.142'
	make st cfg='share_142.192.168.0.142.config' svr='share_142@192.168.0.142'

st_qq:
	make cp_game svr='qq@115.159.144.222'
	make st cfg='qq.115.159.144.222.config' svr='qq@115.159.144.222'
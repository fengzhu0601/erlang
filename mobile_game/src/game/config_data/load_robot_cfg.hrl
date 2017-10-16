-record(robot_cfg, {
    id,             %id
    first_name,
    last_name,
    level,
    job,
    equip_list
}).

-record(robot_name_cfg, {
	id,
	first_name,
	last_name
}).

-record(robot_new_cfg, {
	id,
	level,
	equip_num,
	equip_level,
	equip_quality,
	equip_qh_level,
	gem_num,
	gem_quality,
	pet,
	skill_level,
	gain_exp,
	state_list,
	online_time,
	offline_time,
	delete_role
}).
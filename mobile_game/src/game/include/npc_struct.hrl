-record(npc_cfg,
{	id,
    scene_id, %% config id
    x, 
    y, %% npc 坐标
    can_challenge=0
}).

-record(guaiwu_gc_npc_cfg,
{
	id,
	num=[],
	coordinate_m=[],
	coordinate_b=[],
	npc_list=[],
	boss_list=[]
}).
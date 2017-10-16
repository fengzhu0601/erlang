
SetAIType(AITypes.normal)

Radiuses =
{
    strollRadius = 40,
    chaseRadius = 40,
    chaseSpeed = {1.1, 1.2}
}

SetRadiuses(Radiuses)

AIDecisions =
{
--召唤小怪
	{ denefit = 6, mutex = 11, events = { {type = "hprank", rank = 75}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
	{ denefit = 7, mutex = 12, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
	{ denefit = 8, mutex = 13, events = { {type = "hprank", rank = 20}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
--使用骨针技能的特殊条件
	{ denefit = 9, mutex = 14, events = {}, conditions = {CheckLifeTime(20)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 10, mutex = 15, events = {}, conditions = {CheckLifeTime(50)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 11, mutex = 16, events = {}, conditions = {CheckLifeTime(80)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 12, mutex = 17, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 13, mutex = 18, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 14, mutex = 19, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 15, mutex = 20, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 16, mutex = 21, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 17, mutex = 22, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 18, mutex = 23, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 19, mutex = 24, events = {}, conditions = {CheckLifeTime(330)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 20, mutex = 25, events = {}, conditions = {CheckLifeTime(360)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 21, mutex = 26, events = {}, conditions = {CheckLifeTime(390)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},
	{ denefit = 22, mutex = 27, events = {}, conditions = {CheckLifeTime(420)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},				
	{ denefit = 23, mutex = 28, events = {}, conditions = {CheckLifeTime(450)}, actions = {{ action = DoCastSkill(311114), number = 1, time = 0}}},	
--超过450秒，攻击力提升200%；
	{ denefit = 24, mutex = 29, events = {}, conditions = {CheckLifeTime(452)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50001}), number = 1}}},
--5秒没有受击释放骨针技能	
	{ denefit = 25, mutex = 30, events = {}, conditions = {CheckLastHitTime(5)}, actions = {{ action = DoCastSkill(311114,DoMoveInstant(GetPlayerFrontPos(2))), number = 1}}},

	{ denefit = 26, mutex = 31, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 27, mutex = 32, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 28, mutex = 33, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 29, mutex = 34, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 30, mutex = 35, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 31, mutex = 36, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 32, mutex = 37, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 33, mutex = 38, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 34, mutex = 39, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50013}), number = 1}}},

    { denefit = 35, mutex = 40, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1102101,1}}, 1, 0, {50015}), number = 1}}}
}

LoadConfig(AIDecisions)

--111横扫；112爪击；113喷毒；114骨刺；
ChangeSkillRank(75,{{311111,15},{311112,30},{311113,20},{311114,35}})
ChangeSkillRank(50,{{311111,5},{311112,20},{311113,20},{311114,55}})

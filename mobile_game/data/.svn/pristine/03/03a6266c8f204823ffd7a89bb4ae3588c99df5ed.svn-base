
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
	{ denefit = 6, mutex = 5, events = { {type = "hprank", rank = 75}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
	{ denefit = 7, mutex = 6, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
	{ denefit = 8, mutex = 7, events = { {type = "hprank", rank = 20}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
--使用骨针技能的特殊条件
	{ denefit = 9, mutex = 8, events = {}, conditions = {CheckLifeTime(20)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
	{ denefit = 10, mutex = 9, events = {}, conditions = {CheckLifeTime(50)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
	{ denefit = 11, mutex = 10, events = {}, conditions = {CheckLifeTime(80)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
	{ denefit = 12, mutex = 11, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
	{ denefit = 13, mutex = 12, events = {}, conditions = {CheckLifeTime(160)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
	{ denefit = 14, mutex = 13, events = {}, conditions = {CheckLifeTime(200)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
	{ denefit = 15, mutex = 14, events = {}, conditions = {CheckLifeTime(260)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
	{ denefit = 16, mutex = 15, events = {}, conditions = {CheckLifeTime(320)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
	{ denefit = 17, mutex = 16, events = {}, conditions = {CheckLifeTime(380)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
	{ denefit = 18, mutex = 17, events = {}, conditions = {CheckLifeTime(440)}, actions = {{ action = DoCastSkill(311104), number = 1, time = 0}}},
--6秒没有受击释放骨针技能
	{ denefit = 19, mutex = 18, events = {}, conditions = {CheckLastHitTime(6)}, actions = {{ action = DoCastSkill(311104,DoMoveInstant(GetPlayerFrontPos(2))), number = 1}}},

	{ denefit = 20, mutex = 19, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 21, mutex = 20, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 22, mutex = 21, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 23, mutex = 22, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 24, mutex = 23, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 25, mutex = 24, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 26, mutex = 25, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 27, mutex = 26, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 28, mutex = 27, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50012}), number = 1}}},

    { denefit = 29, mutex = 28, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1101101,1}}, 1, 0, {50015}), number = 1}}}
	
}

LoadConfig(AIDecisions)

--101横扫；102爪击；103喷毒；104骨刺；
ChangeSkillRank(70,{{311101,25},{311102,60},{311103,0},{311104,15}})
ChangeSkillRank(40,{{311101,25},{311102,45},{311103,0},{311104,30}})
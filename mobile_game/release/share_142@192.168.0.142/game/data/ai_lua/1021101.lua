
SetAIType(AITypes.normal)

Radiuses =
{
    strollRadius = 20,
    chaseRadius = 20,
    chaseSpeed = {1.1, 1.2}
}

SetRadiuses(Radiuses)

AIDecisions =
{
    { denefit = 11, mutex = 6, events = { {type = "getup",  skillid = 0, count = 15, time = 20}}, conditions = {}, actions = {{ action = DoCastSkill(301403), number = 1 }}},
	-- { denefit = 12, mutex = 7, events = { {type = "hprank", rank = 60}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
	-- { denefit = 14, mutex = 9, events = { {type = "hprank", rank = 20}}, conditions = {}, actions = {{ action = DoRunAway(), number = 1 }}},
	{ denefit = 13, mutex = 8, events = { {type = "hprank", rank = 70}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 14, mutex = 9, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 15, mutex = 10, events = { {type = "hprank", rank = 20}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 16, mutex = 11, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 17, mutex = 12, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 18, mutex = 13, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 19, mutex = 14, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 20, mutex = 15, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 21, mutex = 16, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 22, mutex = 17, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 23, mutex = 18, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 24, mutex = 19, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50012}), number = 1}}},

    { denefit = 25, mutex = 20, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1021101,1}}, 1, 0, {50015}), number = 1}}}
}

LoadConfig(AIDecisions)

ChangeAttackRank(60,70)
ChangeAttackRank(30,90)

ChangeSkillRank(30, {{301401,40},{301402,0},{301403,60}})
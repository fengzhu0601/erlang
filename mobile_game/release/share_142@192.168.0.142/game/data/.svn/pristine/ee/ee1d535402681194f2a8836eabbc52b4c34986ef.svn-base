
SetAIType(AITypes.normal)

Radiuses =
{
    strollRadius = 40,
    chaseRadius = 40,
    chaseSpeed = {1.3, 1.8}
}

SetRadiuses(Radiuses)

AIDecisions =
{
    { denefit = 10, mutex = 5, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCastSkill(300423), number = 1 }}},
	-- { denefit = 11, mutex = 6, events = { {type = "hprank", rank = 70}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    -- { denefit = 12, mutex = 7, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    -- { denefit = 13, mutex = 8, events = { {type = "hprank", rank = 20}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 14, mutex = 9, events = { {type = "hitted", skillId = 0, count = 5, time = 10}}, conditions = {CheckMonsterHpRank(40)}, actions = {{ action = DoRunAway(2, {1.8, 1.8}), number = 1,time = 2 }, { action = DoCastSkill(300422, SendEventToMonster({{1033100,1}}, 1, 3, {50002})), number = 1 }}},
    { denefit = 16, mutex = 11, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 17, mutex = 12, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 18, mutex = 13, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 19, mutex = 14, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 20, mutex = 15, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 21, mutex = 16, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 22, mutex = 17, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 23, mutex = 18, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 24, mutex = 19, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50014}), number = 1}}},

    { denefit = 25, mutex = 20, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1033100,1}}, 1, 0, {50015}), number = 1}}}
}

LoadConfig(AIDecisions)

ChangeAttackRank(60,90)
ChangeAttackRank(30,100)

--421劈砍；422三连坐；423回血；425打嗝；
-- ChangeSkillRank(100,{{300421,60},{300422,40},{300423,0},{300425,0}})
ChangeSkillRank(70,{{300421,40},{300422,40},{300423,0},{300425,20}})
ChangeSkillRank(40,{{300421,15},{300422,50},{300423,0},{300425,35}})
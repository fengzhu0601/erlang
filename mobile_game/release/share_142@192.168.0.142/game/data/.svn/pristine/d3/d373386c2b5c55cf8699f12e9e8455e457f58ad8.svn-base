
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
    { denefit = 10, mutex = 5, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCastSkill(300413), number = 1 }}},
    -- { denefit = 11, mutex = 6, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 12, mutex = 7, events = { {type = "hitted", skillId = 0, count = 5, time = 10}}, conditions = {CheckMonsterHpRank(40)}, actions = {{ action = DoRunAway(2, {1.8, 1.8}, DoCastSkill(300412)), number = 1 , rank = 50}}},
    { denefit = 16, mutex = 11, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 17, mutex = 12, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 18, mutex = 13, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 19, mutex = 14, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 20, mutex = 15, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 21, mutex = 16, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 22, mutex = 17, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 23, mutex = 18, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 24, mutex = 19, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50013}), number = 1}}},

    { denefit = 25, mutex = 20, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1032100,1}}, 1, 0, {50015}), number = 1}}}
}

LoadConfig(AIDecisions)



ChangeAttackRank(60,80)
ChangeAttackRank(30,100)


--411劈砍；412三连坐；413回血；415打嗝；
-- ChangeSkillRank(100,{{300411,60},{300412,40},{300413,0},{300415,0}})
ChangeSkillRank(70,{{300411,40},{300412,40},{300413,0},{300415,20}})
ChangeSkillRank(40,{{300411,15},{300412,50},{300413,0},{300415,35}})
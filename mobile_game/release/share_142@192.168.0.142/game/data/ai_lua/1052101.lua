
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
    { denefit = 10, mutex = 5, events = { {type = "hitted", skillId = 0, count = 20, time = 20}}, conditions = {}, actions = {{ action = DoCastSkill(310612,DoMoveInstant(GetPlayerBehinePos(2))), number = 1 }}},
    { denefit = 11, mutex = 6, events = { {type = "hprank", rank = 70}}, conditions = {}, actions = {{ action = DoCastSkill(310615), number = 1 }}},
    { denefit = 12, mutex = 7, events = { {type = "hprank", rank = 40}}, conditions = {}, actions = {{ action = DoCastSkill(310615), number = 1 }}},
    { denefit = 13, mutex = 8, events = { {type = "hprank", rank = 10}}, conditions = {}, actions = {{ action = DoCastSkill(310615), number = 1 }}},
    { denefit = 16, mutex = 11, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 17, mutex = 12, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 18, mutex = 13, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 19, mutex = 14, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 20, mutex = 15, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 21, mutex = 16, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 22, mutex = 17, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 23, mutex = 18, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50013}), number = 1}}},
    { denefit = 24, mutex = 19, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50013}), number = 1}}},

    { denefit = 25, mutex = 20, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1052101,1}}, 1, 0, {50015}), number = 1}}}
}

LoadConfig(AIDecisions)

ChangeAttackRank(60,70)
ChangeAttackRank(30,90)

--611挥剑；612十字斩；613能量拳；615光柱；
ChangeSkillRank(70, {{310611,40},{310612,20},{310613,20},{310615,20}})
ChangeSkillRank(40, {{310611,40},{310612,30},{310613,20},{310615,10}})
ChangeSkillRank(10, {{310611,40},{310612,40},{310613,10},{310615,10}})
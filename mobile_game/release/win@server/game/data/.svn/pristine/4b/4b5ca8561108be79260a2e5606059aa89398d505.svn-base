SetAIType(AITypes.normal)

Radiuses =
{
    strollRadius = 50,
    chaseRadius = 50,
    chaseSpeed = {1.1, 1.4}
}

SetRadiuses(Radiuses)

AIDecisions =
{
    { denefit = 10, mutex = 5, events = {{ type = "hitted", skillId = 0, count = 5, time = 60 }}, conditions = {}, actions = {{ action = DoCastSkill(301924), rank = 30, number = 1 }}},
    { denefit = 11, mutex = 6, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 1, {50007,50008}), number = 1}}},
    { denefit = 16, mutex = 11, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 17, mutex = 12, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 18, mutex = 13, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 19, mutex = 14, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 20, mutex = 15, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 21, mutex = 16, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 22, mutex = 17, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 23, mutex = 18, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 24, mutex = 19, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50014}), number = 1}}},

    { denefit = 25, mutex = 20, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1233100,1}}, 1, 0, {50015}), number = 1}}}
}

LoadConfig(AIDecisions)

ChangeSkillRank(50, {{300121,15},{300122,20},{300123,15},{300124,50},{300125,0}})
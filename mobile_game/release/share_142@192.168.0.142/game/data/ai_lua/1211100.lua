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
    { denefit = 10, mutex = 5, events = {}, conditions = {CheckLifeTime(10)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 11, mutex = 6, events = {}, conditions = {CheckLifeTime(50)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 12, mutex = 7, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 13, mutex = 8, events = {}, conditions = {CheckLifeTime(130)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 14, mutex = 9, events = {}, conditions = {CheckLifeTime(170)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 15, mutex = 10, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 16, mutex = 11, events = {}, conditions = {CheckLifeTime(250)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 17, mutex = 12, events = {}, conditions = {CheckLifeTime(290)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 18, mutex = 13, events = {}, conditions = {CheckLifeTime(330)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 19, mutex = 14, events = {}, conditions = {CheckLifeTime(370)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 20, mutex = 15, events = {}, conditions = {CheckLifeTime(410)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},
    { denefit = 21, mutex = 16, events = {}, conditions = {CheckLifeTime(450)}, actions = {{ action = DoCastSkill(302406), number = 1 }}},

    { denefit = 22, mutex = 17, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 23, mutex = 18, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 24, mutex = 19, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 25, mutex = 20, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 26, mutex = 21, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 27, mutex = 22, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 28, mutex = 23, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 29, mutex = 24, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 30, mutex = 25, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50012}), number = 1}}},

    { denefit = 31, mutex = 25, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1211100,1}}, 1, 0, {50015}), number = 1}}}
}

LoadConfig(AIDecisions)

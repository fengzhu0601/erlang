SetAIType(AITypes.normal)

SetLocalized(true)    --设置固定不可行走追击

Radiuses =
{
    strollRadius = 0,
    chaseRadius = 0,
    chaseSpeed = {1.5, 2.0}
}

SetRadiuses(Radiuses)

AIDecisions =
{
    -- { denefit = 13, mutex = 8, events = { {type = "hprank", rank = 100}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 14, mutex = 9, events = { {type = "hprank", rank = 85}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 15, mutex = 10, events = { {type = "hprank", rank = 70}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 16, mutex = 11, events = { {type = "hprank", rank = 55}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 17, mutex = 12, events = { {type = "hprank", rank = 40}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 18, mutex = 13, events = { {type = "hprank", rank = 25}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 19, mutex = 14, events = {}, conditions = {CheckIsDead()}, actions = {{ action = DoResetMapData(MapPoint(45, 15), 5, 4, true), number = 1 }}},
    { denefit = 16, mutex = 11, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 17, mutex = 12, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 18, mutex = 13, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 19, mutex = 14, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 20, mutex = 15, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 21, mutex = 16, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 22, mutex = 17, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 23, mutex = 18, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50014}), number = 1}}},
    { denefit = 24, mutex = 19, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50014}), number = 1}}},

    { denefit = 25, mutex = 20, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1083101,1}}, 1, 0, {50015}), number = 1}}}
}

LoadConfig(AIDecisions)

--爪击
SetDistanceEvent(5, 6, 1, DoCastSkill(310921))
--近身地刺
SetDistanceEvent(3, 7, 1, DoCastSkill(310924))
--远程地刺
SetDistanceEvent(30, 5, 1, DoCastSkill(310925))
SetAIType(AITypes.normal)

Radiuses =
{
    strollRadius = 20,
    chaseRadius = 20,
    chaseSpeed = {1.2, 1.5}
}

SetRadiuses(Radiuses)

AIDecisions =
{
    { denefit = 10, mutex = 5, events = { {type = "hitted", skillId = 0, count = 5, time = 20}}, conditions = {}, actions = {{ action = DoCastSkill(300203), number = 1 }}},
    { denefit = 11, mutex = 6, events = { {type = "getup", skillId = 0, count = 4, time = 20}}, conditions = {},  actions = {{ action = DoCastSkill(300204), number = 1 }}},
    { denefit = 13, mutex = 8, events = { {type = "hprank", rank = 70}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 14, mutex = 9, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 15, mutex = 10, events = { {type = "hprank", rank = 30}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 16, mutex = 11, events = {}, conditions = {CheckLifeTime(30)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 17, mutex = 12, events = {}, conditions = {CheckLifeTime(60)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 18, mutex = 13, events = {}, conditions = {CheckLifeTime(90)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 19, mutex = 14, events = {}, conditions = {CheckLifeTime(120)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 20, mutex = 15, events = {}, conditions = {CheckLifeTime(150)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 21, mutex = 16, events = {}, conditions = {CheckLifeTime(180)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 22, mutex = 17, events = {}, conditions = {CheckLifeTime(210)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 23, mutex = 18, events = {}, conditions = {CheckLifeTime(240)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50012}), number = 1}}},
    { denefit = 24, mutex = 19, events = {}, conditions = {CheckLifeTime(270)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50012}), number = 1}}},

    { denefit = 25, mutex = 20, events = {}, conditions = {CheckLifeTime(300)}, actions = {{ action = SendEventToMonster({{1011100,1}}, 1, 0, {50015}), number = 1}}}
}

LoadConfig(AIDecisions)


ChangeSkillRank(30, {{300201,40},{300202,20},{300203,20},{300204,20}})

--[[
SetAttackInfo({ count = 5, time = 20, number = 1, action = DoCastSkill(300202) })
SetNormalHittedInfo({ count = 5, time = 20, number = 1, action = DoCastSkill(300203) })
SetSkillAttackInfos({                                                                           
     {skillId = 300201, hasCd = true, count = 3, time = 0, number = 1, action = DoCastSkill(300202) },    
     {skillId = 300202, hasCd = false, count = 3, time = 10, number = 3, action = DoCastSkill(300203) }
      })

SetSpecialHittedInfos({
    { skillInfos = { {jobId = 1, skillId = 100111 }, {jobId = 2, skillId = 100211 } }, hasCd = true, count = 5, time = 0, number = 1, action = DoCastSkill(300204)},	
    { skillInfos = { {jobId = 1, skillId = 100112 }, {jobId = 2, skillId = 100214 } }, hasCd = true, count = 5, time = 0, number = 1, action = DoCastSkill(300204)}
    })

SetHpRankInfos({                  
    { rank = 25, hasCd = false, number = 1, action = DoCastSkill(300204) }
    })
]]
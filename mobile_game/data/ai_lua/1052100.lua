
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
    { denefit = 10, mutex = 5, events = { {type = "hitted", skillId = 0, count = 15, time = 20}}, conditions = {}, actions = {{ action = DoCastSkill(300612), number = 1 }}},
    { denefit = 11, mutex = 6, events = { {type = "hprank", rank = 70}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 12, mutex = 7, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}},
    { denefit = 13, mutex = 8, events = { {type = "hprank", rank = 20}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 }}}
}

LoadConfig(AIDecisions)

ChangeAttackRank(60,70)
ChangeAttackRank(30,90)

ChangeSkillRank(30, {{300611,10},{300612,60},{300613,30}})
SetAIType(AITypes.normal)

Radiuses =
{
    strollRadius = 50,
    chaseRadius = 50,
    chaseSpeed = {1.1, 1.4}
}

SetRadiuses(Radiuses)


-- AIDecisions =
-- {
--     { denefit = 10, mutex = 5, events = { {type = "attack", skillId = 0, count = 1, time = 10}}, conditions = {}, actions = {{ action = DoCastSkill(201711, SendEventToMonster({{1082101,1}}, 1, 0, {50005})), number = 1 }}}
-- }

-- LoadConfig(AIDecisions)
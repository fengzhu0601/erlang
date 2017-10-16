SetAIType(AITypes.normal)

Radiuses =
{
    strollRadius = 50,
    chaseRadius = 50,
    chaseSpeed = {1.3, 1.5}
}

SetRadiuses(Radiuses)



-- AIDecisions =
-- {
--     { denefit = 10, mutex = 5, events = {}, conditions = {CheckLifeTime(1)}, actions = {{ action = DoRunAndKillSelf(MapPoint(40, 15), SendEventToMonster({{1081101,1}}, 1, 3, {50004})), number = 1 }}}
-- }

-- LoadConfig(AIDecisions)

SetSingleActionInfo("run", {position = MapPoint(40, 16), width = 1, height = 1}, DoDeadImmediately("die", SendEventToMonster({{1081101,1}}, 1, 1, {50005})))
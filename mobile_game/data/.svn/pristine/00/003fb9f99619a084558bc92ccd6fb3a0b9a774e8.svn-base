SetAIType(AITypes.normal)

Radiuses =
{
    strollRadius = 50,
    chaseRadius = 50,
    chaseSpeed = {1.1, 1.4}
}

SetLocalized(true)    --设置固定不可行走追击

SetRadiuses(Radiuses)

AIDecisions =
{
    { denefit = 10, mutex = 5, events = {}, conditions = {CheckLifeTime(1)}, actions = {{ action = SendEventToMonster({{4000901,1}}, 1, 1, {41}), number = 1}}}
}

LoadConfig(AIDecisions)
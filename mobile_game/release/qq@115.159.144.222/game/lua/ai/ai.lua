------------------------------------------------------
--设置的基本信息
------------------------------------------------------


--erlang_api.print("hello lua")


--注册杀死所有的怪，比如新手引导，杀死全部的怪物,参数 ev 为字符串
--e.g: RegisterKillAll("rookie_kill_all")
function RegisterKillAll(ev)
    print("error in RegisterKillAll")
    -- 不用实现
end

function SetSingleActionInfo(Args1, Args2, Args3)
    print("SetSingleActionInfo unsport")
end

function MapPoint(X, Y)
    return {X, Y}
end

function SetMoveAble(Flag)    --是否可移动
    print("SetMoveAble unsport")
end

function SetSkillEndAndKillSelf(Flag)    --是否可移动
    print("SetSkillEndAndKillSelf unsport")
end

function SetOnce(Flag)    --是否可移动
    print("SetOnce unsport")
end

function ChangeAttackRank(Args1, Args2)    --是否可移动
    print("ChangeAttackRank unsport")
end

function ChangeSkillRank(Args1, Args2)    --是否可移动
    print("ChangeSkillRank unsport")
end









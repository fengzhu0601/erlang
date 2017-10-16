


AITypes =
{
	normal 	= 1,		-- 代表普通ai和boss ai
	thing 	= 2,		-- 代表物件ai
	machine = 3,		-- 代表机关ai
	toggle 	= 4,		-- 代表开关类型机关ai
}









tmp_ai_args = {}


--设置AI类型
--参数说明： aiType， ai类型,目前支持4个类型
--AITypes.normal 代表普通ai和boss ai
--AITypes.thing 代表物件ai
--AITypes.machine 代表机关ai
--AITypes.toggle 代表开关类型机关ai
--e.g: SetAIType(AITypes.normal)
function SetAIType(eAITypes)
	tmp_ai_args.ai_type = eAITypes
end



--设置闲逛，追击，警戒距离，追击速度, 特别说明：因为之前没有警戒范围，为了与之前版本兼容所以如果不配警戒范围，警戒范围直接等于追击范围
--参数说明:radiuses
--e.g:
--[[
local Radiuses =
{
    strollRadius = 20,
    chaseRadius = 20,
    alertRadius = 10,
    chaseSpeed = {1.5, 2.0}
}
SetRadiuses(Radiuses)
]]
function SetRadiuses(Radiuses)
	erlang_api.print("----------------- SetRadiuses --------------")
	tmp_ai_args.strollRadius 	= Radiuses.strollRadius			-- 闲逛
	tmp_ai_args.chaseRadius 	= Radiuses.chaseRadius			-- 追击
	tmp_ai_args.chaseSpeed 		= Radiuses.chaseSpeed			-- 追击速度
	if nil == Radiuses.alertRadius then							-- 警戒
		tmp_ai_args.alertRadius = Radiuses.chaseRadius
	else
		tmp_ai_args.alertRadius = Radiuses.alertRadius
	end
end



---------------------------------------------------------------------
--配置的特殊ai
---------------------------------------------------------------------
--加载设置的特殊ai
--参数说明：AIDecisions 是一个数组

--[[
AIDecisions =
{
    { denefit = 10, mutex = 5, events = { {type = "hitted", skillId = 0, count = 3, time = 20}}, conditions = {}, actions = {{ action = DoCastSkill(300102), number = 1, time = 0}}},
    { denefit = 11, mutex = 6, events = { {type = "getup", skillId = 0, count = 4, time = 20}}, conditions = {},  actions = {{ action = DoCastSkill(300103), number = 1 , time = 0}}},
    { denefit = 12, mutex = 7, events = { {type = "attack", skillId = 300101, count = 3, time = 0}}, conditions = {},  actions = {{ action = DoCastSkill(300102), number = 1 , time = 0}}},
    { denefit = 13, mutex = 8, events = { {type = "hprank", rank = 70}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 , time = 0}}},
    { denefit = 14, mutex = 9, events = { {type = "hprank", rank = 50}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 , time = 0}}},
    { denefit = 15, mutex = 10, events = { {type = "hprank", rank = 20}}, conditions = {}, actions = {{ action = DoCallMonster(), number = 1 , time = 0}}}
}
]]

-- local decision = { denefit = 10, mutex = 5, events = { {type = "hitted", skillId = 0, count = 3, time = 20}}, conditions = {}, actions = {{ action = DoCastSkill(300102), number = 1 }}}
-- denefit 权益
-- mutex 互斥
-- events 事件  数据类型：数组
-- event 说明：
-- type 目前支持4种类型："hitted", "getup", "hprank", "attack"
-- skillId 代表被攻击的技能Id或者是主动攻击的技能Id,如果填0，则表示所有的被击和主动攻击都计算
-- count 代表被击或者攻击次数
-- time 时间间隔，被击和主动攻击的时间间隔
-- conditions 条件 数据类型：数组
-- 以上check开头的方法都可以结合配
-- actions 触发的事件 数据类型：数组
-- action 触发的事件，Do和Send开头的方法
-- number 触发的次数
-- time 与下一个事件的时间间隔，如果是0，表示和前一个一起触发
-- 特别说明：events和conditions 不能同时为空， actions 也不能为空
-- 如果events和conditions 同时达成条件，则选denefit高的执行，如果denefit一样，则选mutex高的执行，如果有多条denefit和mutex的值相同，那就从满足条件的decision里随机选一个


function LoadConfig(AIDecisions)
	tmp_ai_args.decisions = AIDecisions
end



function get_ai_args()
	return tmp_ai_args
end



function get_ai_args_tmp()
	local t_copy = {}
	util_deepcopy(t_copy, tmp_ai_args)
	return t_copy
end













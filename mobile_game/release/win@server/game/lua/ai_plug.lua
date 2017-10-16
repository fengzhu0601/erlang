--
-- Created by IntelliJ IDEA.
-- User: clark
-- Date: 16-5-12
-- Time: 下午6:21
-- To change this template use File | Settings | File Templates.
--




ai_plug =
{
    LUA_EVT_HIT 	    = 1,	    -- 受击 {skillid, hp}
    LUA_EVT_GET_UP 	    = 2,	    -- 起身
    LUA_EVT_HP 	        = 3,	    -- 血量变化
    LUA_EVT_ATTACK 	    = 4,	    -- 攻击
    LUA_EVT_FRAME       = 5,        -- 帧事件
    LUA_EVT_MONSTER     = 6,        -- 怪物事件
}


function in_time(data, CfgDt)
    local now_tm = os.time()
    local Dt = now_tm - data.last_time
    data.last_time = now_tm
    if Dt <= CfgDt then
        return true
    else
        return false
    end
end

function is_me(Idx)
    local MyIdx = get_cur_idx()
    if Idx ~= MyIdx then
        return false
    else
        return true
    end
end




-- 受连击事件
function ai_plug.create_hit_evt(Item)
    local public = {}
    -- 技能
    -- 达成次数
    -- 有效计数的间隔时间
    local cfg = { type = "hitted", skillId = Item.skillId, count = Item.count, time = Item.time, evt_id = ai_plug.LUA_EVT_HIT }
    local data = { last_time = 0, count = 0 }
    public.type = cfg.type
    function public.on_evt(Idx, EvtId, EvtArgs)
        if cfg.evt_id ~= EvtId then
            return false
        end

        if true ~= is_me(Idx) then
            return false
        end

        if cfg.skillId ~= EvtArgs[1] and 0 ~= cfg.skillId then
            return false
        end

        if in_time(data, cfg.time) then
            data.count = data.count + 1
        else
            data.count = 0
        end

        if data.count >= cfg.count then
            data.count = 0
            return true
        else
            return false
        end
    end

    return public
end

-- 血量变化事件
function ai_plug.create_hp_evt(Item)
    local public = {}
    local cfg = { type = "hprank", rank = Item.rank, evt_id = ai_plug.LUA_EVT_HP }
    local data = {}
    public.type = cfg.type
    function public.on_evt(Idx, EvtId, EvtArgs)
        if cfg.evt_id ~= EvtId then
            return false
        end

        local MyIdx = get_cur_idx()
        if Idx ~= MyIdx then
            return false
        end

        return true
    end

    return public
end

-- 起身事件(服务器无起身动作)
function ai_plug.create_getup_evt(Item)
    local public = {}
    local cfg = { type = "getup", skillid = Item.skillId, count = Item.count, time = Item.time, evt_id = ai_plug.LUA_EVT_GET_UP }
    local data = {}
    public.type = cfg.type
    function public.on_evt(Idx, EvtId, EvtArgs)
        return false
    end

    return public
end

-- 连击事件
function ai_plug.create_attack_evt(Item)
    local public = {}
    local cfg = { type = "attack", skillId = Item.skillId, count = Item.count, time = Item.time, evt_id = ai_plug.LUA_EVT_ATTACK }
    local data = { last_time = 0, count = 0 }
    public.type = cfg.type
    function public.on_evt(Idx, EvtId, EvtArgs)
        if cfg.evt_id ~= EvtId then
            return false
        end

        if true ~= is_me(Idx) then
            return false
        end

        if cfg.skillId ~= EvtArgs[1] and 0 ~= cfg.skillId then
            return false
        end

        if in_time(data, cfg.time) then
            data.count = data.count + 1
        else
            data.count = 0
        end

        if data.count >= cfg.count then
            data.count = 0
            return true
        else
            return false
        end

        return true
    end

    return public
end


function ai_plug.create_base_can()
    local public = {}
    function public.can(Idx, EvtId, EvtArgs)
        print("can unsport")
        return false
    end

    return public
end




--检测buff,
--参数说明：tag 配置表里的ID对应的buff的Id
--e.g:CheckBuffTag(1)
function CheckBuffTag(tag)
    local function do_create()
        local can_plug = ai_plug.create_base_can()
        function can_plug.can(Idx, EvtId, EvtArgs)
            print("CheckBuffTag unsupport")
            return false
        end

        return can_plug
    end

    return do_create
end

--检测最近玩家buff
--参数说明：同上
--e.g:CheckPlayerBuffTag(1)
function CheckPlayerBuffTag(tag)
    local function do_create()
        local can_plug = ai_plug.create_base_can()
        function can_plug.can(Idx, EvtId, EvtArgs)
            print("CheckPlayerBuffTag unsupport")
            return false
        end

        return can_plug
    end

    return do_create
end

--检测怪物血量
--参数说明：rank 血量比例， 满血是100%，
--e.g:CheckMonsterHpRank(50) 检测怪物是不是小于50%的血量
function CheckMonsterHpRank(Rank)
    local function do_create()
        local can_plug = ai_plug.create_base_can()
        function can_plug.can(Idx, EvtId, EvtArgs)
            local MyIdx = get_cur_idx()
            if 1 == erlang_api.check_hp_rank(MyIdx, Rank) then
                return true
            else
                return false
            end
            return false
        end

        return can_plug
    end

    return do_create
end

--检测玩家血量
--参数说明：同上
--e.g:CheckPlayerHpRank(50) 检测玩家的血量是否是小于50%
function CheckPlayerHpRank(Rank)
    local function do_create()
        local can_plug = ai_plug.create_base_can()
        function can_plug.can(Idx, EvtId, EvtArgs)
            if 1 == erlang_api.check_hp_rank(0, Rank) then
                return true
            else
                return false
            end
            return false
        end

        return can_plug
    end

    return do_create
end

--检测怪物是否已经死亡
function CheckIsDead()
    local function do_create()
        local can_plug = ai_plug.create_base_can()
        function can_plug.can(Idx, EvtId, EvtArgs)
            return false
        end

        return can_plug
    end

    return do_create
end

--检测生存时间
--参数说明：time从出生到现在 生存时间,单位是秒
--e.g:CheckLifeTime(30) 检查怪物生存的时间超过30秒
function CheckLifeTime(Time)
    local function do_create()
        local can_plug = ai_plug.create_base_can()
        function can_plug.can(Idx, EvtId, EvtArgs)
            --            print("CheckLifeTime can")
            local MyIdx = get_cur_idx()
            local BornTime = g_ai_part_set[MyIdx].born_time
            local Dt = os.time() - BornTime
            if Dt >= Time then
                --                print("CheckLifeTime true")
                return true
            else
                --                print("CheckLifeTime false")
                return false
            end
        end

        return can_plug
    end

    return do_create
end



--------------------------------------
function ai_plug.create_action(Item)
    local public = {}
    local cfg = { action = Item.action, number = Item.number }
    public.count = 0
    function public.do_case()
        if nil ~= cfg.action then
            cfg.action()
        end
        public.count = public.count + 1
    end

    function public.can_do()
        if public.count <= cfg.number or cfg.number <= 0 then
            return true
        else
            return false
        end
    end

    return public
end


--隐藏怪物
--参数说明：cb 隐藏的回调，即是隐藏后做什么事件，可为空
--e.g:DoHide()
function DoHide(cb)
    local function do_case()
        print(" DoHide is unsupport ")
    end

    return do_case
end

--显示怪物
--参数说明：cb 显示的回调，即是显示后做什么事件，可为空
--e.g:DoShow()
function DoShow(cb)
    local function do_case()
        print(" DoShow is unsupport ")
    end

    return do_case
end


function GetPlayerBehinePos(num)
    local function do_case()
        local MyIdx = get_cur_idx()
        --        print(" GetPlayerBehinePos ")
        local AA, BB = erlang_api.get_player_behine_pos(MyIdx, num)
        --        print("kkk ", util_t2s(AA))
        return { AA, BB }
    end

    return do_case
end

function GetPlayerFrontPos(num)
    local function do_case()
        local MyIdx = get_cur_idx()
        --        print(" GetPlayerFrontPos ")
        local AA, BB = erlang_api.get_player_front_pos(MyIdx, num)
        return { AA, BB } -- {X,Y}
    end

    return do_case
end

--瞬移
--参数说明：pos 瞬移的位置
-- cb 瞬移的回调，即是瞬移后做什么事件，可为空
--  GetPlayerFrontPos,GetPlayerBehinePos
--e.g:DoMoveInstant(GetPlayerBehinePos(3)) 瞬移到玩家后面的3个格子的位置
function DoMoveInstant(pos, cb)
    --    print(" DoDeadImmediately is unsupport ")
    --    return nil
    local function do_case()
        local MyIdx = get_cur_idx()
        print(" DoMoveInstant ")
        local MyPos = pos()
        erlang_api.do_move_instance(MyIdx, MyPos[1], MyPos[2])
    end

    return do_case
end

--立即死亡
--参数说明：die 是立即死亡的动作 一般是: "die", 可为空
-- cb 死亡的回调，即是死亡后做什么事件，可为空
--e.g:DoDeadImmediately()
function DoDeadImmediately(die, cb)
    --    print(" DoDeadImmediately is unsupport ")
    local function do_create()
        local can_plug = ai_plug.create_base_can()
        function can_plug.can(Idx, EvtId, EvtArgs)
            local MyIdx = get_cur_idx()
            erlang_api.do_die(MyIdx)
            return true
        end

        return can_plug
    end

    return do_create
end

--逃跑到某个点后自杀
--参数说明：pos 逃跑到的点
--cb 死亡的回调，即是死亡后做什么事件，可为空
--e.g:DoRunAndKillSelf(MapPoint(50, 15)) 逃跑到点 50， 15位置后死亡
function DoRunAndKillSelf(pos, cb)
    --    print(" DoRunAndKillSelf is unsupport ")
    local function do_create()
        local can_plug = ai_plug.create_base_can()
        function can_plug.can(Idx, EvtId, EvtArgs)
            --            local MyIdx = get_cur_idx()
            --            erlang_api.do_die_pos(Idx,pos)
            return true
        end

        return can_plug
    end

    return do_create
end

--逃跑
--参数说明：cb 逃跑的回调，即是逃跑后做什么事件，可为空
--特别说明：逃跑的位置会根据怪物当前的位置，背对玩家逃跑，逃跑的点会在怪物的追击距离之外
--e.g:DoRunAway()
function DoRunAway(time, speedInfo, cb)
    print(" DoRunAway ")
    local function do_create()
        local MyIdx = get_cur_idx()
        erlang_api.run_away(MyIdx)
        return true
    end
    return do_case
end

--释放技能
--参数说明： skillId，要释放的技能ID
-- cb 释放技能的回调，即是释放技能后做什么事件，可为空
--特别说明：skillId必须是monster.lua里配的技能之一
--e.g: DoCastSkill(10001), 释放10001的技能
function DoCastSkill(skillId, cb)
    local function do_case()
        print(" DoCastSkill  ")
        local MyIdx = get_cur_idx()
        erlang_api.do_cast_skill(MyIdx,skillId)
        return true
    end
    return do_case
end

--召唤怪物 丢了个事件给场景
--参数说明：tag 第几波, 可为空
--cb 召唤的回调，即是召唤后做什么事件，可为空
--e.g:DoCallMonster()
function DoCallMonster(tag, cb)
    local do_call_count = 0
    local function do_case()
        if do_call_count < 1 then
            do_call_count = 1
            erlang_api.update_stack()
            local MyIdx = get_cur_idx()
            erlang_api.call_monsters(MyIdx)
--            if nil ~= cb then
--                cb()
--            end
        end
    end

    return do_case
end



---------------------------------------------------------------
-- 以上为boss ai相应的配置的文档说明
-- 有不理解的，及时与农进侠沟通
-- 特此说明
---------------------------------------------------------------

--2016年4月11日更新
--功能说明：重新设置地图是否可以行走
--计算方法说明：以point为中心，以width为半长，以height为半宽的矩形
--参数说明：point 地图点，如MapPoint(20, 20)
--width，区域的半长
--height，区域的半宽
--isWalkable, 时候可以行走，true表示抗议行走，false表示不可以行走
--特别说明：point的z必须是0，如果不是0，程序将会强制转换成0
--e.g:DoResetMapData(MapPoint(10, 15), 1, 5, false) 设置以点(10,15)为中心，长度为3，宽度为11的区域不可行走
function DoResetMapData(point, width, height, isWalkable)
    local function do_case()
        erlang_api.set_map_data(point[1], point[2], width, height, isWalkable)
    end
    return do_case
end


-----------------------------------------------------------------
-- 触发的事件
-----------------------------------------------------------------

--设置在怪物周围的信息
--参数说明：radius 设置距离
-- time 设置时间
-- count 设置响应次数
-- cb 设置事件，设置触发的事件
--e.g:SetDistanceEvent(5, 10, 1, DoCastSkill(1000)) 说明：玩家处在距离怪物5个格子的距离的时间超过10秒，将会触发1000技能 1次
function SetDistanceEvent(radius, time, count, cb)
    local function do_case()
        -- 从使用情况看 这个函数是特殊实现的， 不是放在AI状态机里的
        print(" SetDistanceEvent is unsupport ")
    end

    return do_case
end


-- 给玩家发送一个事件，当前只支持添加buff
-- 参数：eventType 目前只可以为 1 代表是添加buff
-- delay 是延迟触发的时间，即：接收到消息后多少秒开始触发, 0代表立即触发
-- datas 是数组，为buff id, 格式{buffid1, buffid2, ...}
-- e.g:SendEventToPlayer(1, 10, {buffid1, buffid2,...})
function SendEventToPlayer(eventType, delay, datas)
    local function do_case()
        if eventType == 1 then
            for i, buf_id in pairs(datas) do
                erlang_api.add_player_buf(delay, buf_id)
            end
        end
    end

    return do_case
end

-- 给怪物发送一个事件，目前只支持buff 给当前指定ID的count个随机挑的怪物加上{buffid1, buffid2...}
-- 参数说明：monsterIdInfos 是一个数组，对应的是怪物的Id，以及数量，格式 {{monsterId, count}, {monsterId, count}, ...}
-- eventType 目前只能是1，代表加buff
-- delay 是延迟触发的时间，即：接收到消息后多少秒开始触发, 0代表立即触发
-- datas  是数组，为buff id, 格式{buffid1, buffid2, ...}
-- e.g:SendEventToMonster({{monsterId1, 3}, {monsterId2, 2}, ...}, 1, 3, {buffId1, buffId2, ...})
function SendEventToMonster(monsterIdInfos, eventType, time, datas)
    local function do_case()
        if eventType == 1 then
            for i, monsters in pairs(monsterIdInfos) do
                for j, buf_id in pairs(datas) do
                    erlang_api.add_buf(monsters[1], monsters[2], time, buf_id)
                end
            end
        end
    end

    return do_case
end



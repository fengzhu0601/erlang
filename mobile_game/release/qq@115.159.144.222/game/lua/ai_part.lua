



AIDecisions =
{
    {
        denefit = 10, mutex = 5,
        events =
        {
            { type = "hprank", rank = 70 }
        },
        conditions = {CheckLifeTime(1)},
        actions =
        {
            { action = SendEventToMonster({{4002001,1}}, 1, 1, {41}), number = 1 }
        }
    },
    {
        denefit = 16, mutex = 11,
        events = {},
        conditions = {CheckLifeTime(30)},
        actions =
        {
            { action = SendEventToMonster({{1001100,1}}, 1, 0, {50012}), number = 1 }
        }
    },
}


AI_Evt_Type =
{
    ["hitted"] 	= ai_plug.create_hit_evt,	    -- 受击
    ["getup"] 	= ai_plug.create_getup_evt,	    -- 起身
    ["hprank"] 	= ai_plug.create_hp_evt,	    -- 血量变化
    ["attack"] 	= ai_plug.create_attack_evt,	-- 攻击
}





ai_part = {}


function ai_part.create(MonsterId)
    local public = {}
    local private = {}

    public.born_time = os.time()
    function private.init()
        if nil == G_MonsterTab[MonsterId] then
            print("G_MonsterTab " .. MonsterId .. " Cfg is nil")
            return false
        end


        local Path = "./data/ai_lua/" .. G_MonsterTab[MonsterId].normal .. ".lua"
--        print("path", Path)
        erlang_api.loadfile(Path)
        private.ai_data = get_ai_args_tmp()


        if nil == private.ai_data.decisions then
            private.ai_data.decisions = {}
        end
        for i, v in pairs(private.ai_data.decisions) do
            local tmp = {}
            for m, n in pairs(v.events) do
                if nil == AI_Evt_Type[n.type] then
                    print("evt unsport " .. n.type)
                else
                    tmp[m] = AI_Evt_Type[n.type](n)
                end
            end
            v.events = tmp

            local tmp = {}
            for m, n in pairs(v.conditions) do
                tmp[m] = n()
            end
            v.conditions = tmp

            local tmp = {}
            for m, n in pairs(v.actions) do
                tmp[m] = ai_plug.create_action(n)
            end
            v.actions = tmp
        end

--        print("Cfg.decisions", util_t2s(private.ai_data.conditions))
        return true
    end

    function private.can_evts(Idx, EvtId, EvtArgs, Evts)
--        print("can_evts 1 " .. EvtId )
        for i, v in pairs(Evts) do
--            print("can_evts 2 " .. v.type )
            if true ~= v.on_evt(Idx, EvtId, EvtArgs) then
                return false
            end
        end
--        print("can_evts true")
        return true
    end

    function private.can_conditions(Idx, EvtId, EvtArgs, Conditions)
--        print("can_conditions")
        for i, v in pairs(Conditions) do
            if true ~= v.can(Idx, EvtId, EvtArgs) then
                return false
            end
        end
        return true
    end

    function private.get_true_case_count(TrueActions)
        for i, v in pairs(TrueActions) do
            if v.can_do() then
                return true
            end
        end
        return false
    end

    function private.true_case(Idx, EvtId, EvtArgs, TrueActions)
        for i, v in pairs(TrueActions) do
            v.do_case()
        end
    end


    function public.on_monster_evt(Idx, EvtId, EvtArgs)
        local Cfg = private.ai_data
        if nil == Cfg then
            print("Cfg is nil")
            return nil
        end
        if nil == Cfg.decisions then
            print("Cfg.decisions is nil")
            return nil
        end

        local mutex_map = {}
        for i, v in pairs(Cfg.decisions) do
            if
                private.get_true_case_count(v.actions)
                and private.can_evts(Idx, EvtId, EvtArgs, v.events)
                and private.can_conditions(Idx, EvtId, EvtArgs, v.conditions)
            then
                if nil == mutex_map[v.mutex] then
                    mutex_map[v.mutex] = {v.denefit, v.actions}
                else
                    if mutex_map[v.mutex][1] < v.denefit then
                        mutex_map[v.mutex] = {v.denefit, v.actions}
                    end
                end
            end
        end
        for i, v in pairs(mutex_map) do
            private.true_case(Idx, EvtId, EvtArgs, v[2])
        end
    end

    if true == private.init() then
        return public
    else
        return nil
    end
end

my_idx = nil

function set_cur_idx(Idx)
    my_idx = Idx
end

function get_cur_idx()
    return my_idx
end

function build_ai_part(Idx, MonsterId)
    print("--------------- build_ai_part ---------------")
    g_ai_part_set[Idx] = ai_part.create(MonsterId)
    erlang_api.update_stack()

    get_rand_skill(MonsterId)
end

function release_ai_part(Idx)
    print("--------------- release_ai_part ---------------")
    g_ai_part_set[Idx] = nil
    erlang_api.update_stack()
end

function on_ai_evt(Idx, EvtId, EvtArgs)
--    print("--------------- on_ai_evt --------------- " .. Idx .. " " .. EvtId )
--    print("--------------- on_ai_evt --------------- " .. Idx .. " " .. EvtId .. " " .. util_t2s(EvtArgs) )
    for i, v in pairs(g_ai_part_set) do
        set_cur_idx(i)
        v.on_monster_evt(Idx, EvtId, EvtArgs)
        set_cur_idx(nil)
    end
    erlang_api.update_stack()
end

function get_rand_skill(MonsterId)
--    print("get_rand_skill ", util_t2s(G_MonsterTab[MonsterId]) )
    local function do_get_rand_skill()
        local Cfg = G_MonsterTab[MonsterId]
        if nil ~= Cfg then
            local Rand = math.random(0, Cfg.skills_ex_sum)
            for i, v in pairs(Cfg.skills_ex) do
                if Rand <= Cfg.skills_ex[i][2] then
                    return Cfg.skills_ex[i][1]
                end
            end
            return Cfg.skills_ex[1][1]
        else
            return 0
        end
    end

    local Skill = do_get_rand_skill()
    return Skill*10+1, Skill
end

return g_ai_part_set



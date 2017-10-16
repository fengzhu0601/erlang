



print("======================== main.lua ======================")
g_ai_part_set = {}


-- engine
erlang_api.loadfile("./lua/util.lua")
erlang_api.loadfile("./lua/ai_plug.lua")
erlang_api.loadfile("./lua/ai_part.lua")
erlang_api.loadfile("./lua/ai/ai.lua")
erlang_api.loadfile("./lua/ai/ai_api.lua")
G_MonsterTab = erlang_api.loadfile("./data/ai_lua/monster1.lua")

math.randomseed(os.clock()*10000)

for i, MonsterCfg in pairs(G_MonsterTab) do
    local Sum = 0
    local skill_tab = {}
    for j, k in pairs(MonsterCfg.skills) do
        Sum = Sum + k[2]
        skill_tab[j] = {k[1], Sum}
    end
    MonsterCfg.skills_ex = skill_tab
    MonsterCfg.skills_ex_sum = Sum
end
erlang_api.update_stack()

--
--
--print("------ build_ai_part s --------")
--build_ai_part(1, 1001100)
--on_ai_evt(1, 1, {})
--release_ai_part(1)
----on_ai_evt(1, 1, {})
--print("------ release_ai_part e --------")
--
--
--

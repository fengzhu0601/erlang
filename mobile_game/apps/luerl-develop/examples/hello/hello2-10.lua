-- File     : hello2-10.lua
-- Purpose  : Returning lua dicts
-- See      : ./examples/hello/hello2.erl

-- return
-- {
--     a=1,
--     b=2,
--     c={3,'Hello World!'}
-- }

return
{
	{
		state_id = 1, 			-- AI的状态ID, ID的值是策划自定义的,用于定位策划想要的AI表现,例如 逃跑状态时的AI, 狂暴状态时的AI, 攻击状态时的AI
		desc = "敌对状态",		-- 注释
		Events = 				-- 驱动AI运行的事件队列
		{
			{
				events = 10008, 								-- 事件ID, 此例 怪物处于休闲状态的事件
				handle_items =
				{
					{													-- 事件处理项
						matux = 1,										-- 互斥码, 如果当数值为0时,无互斥对象；否则会与此事件处理队列里同样互斥码的事件处理项互斥（只能执行其中的唯一一条）
						benefit = 0,									-- 利益值,当数值大于0时为玩家指定, 当数值=-1时,为程序自动计算
						times = 0,										-- 有效次数,当处理项有效执行times次,此事件处理项不再执行
						conditions =
						{												-- 条件,需要全部条件通过才执行true_case动作, 否则执行false_case动作, 为空时表示通过
							{ "is_cd", 				{2000} },				-- 功能名,参数。 此例：is_cd 是否CD完成
							{ "is_near_player_x", 	{0,3} },				-- 功能名,参数。 此例：is_near_player_x 是否离最近玩家的X距离在[0,3]之间
							{ "is_near_player_y",	{0,2} },				-- 功能名,参数。 此例：is_near_player_y 是否离最近玩家的Y距离在[0,2]之间
						},
						true_case =
						{
							{ "skill", 				{2002011} },			-- 使用技能2002011, 后面宜扩展接口 self_skill：使用自身技能。 这样不用仅因为技能ID不同而要配N份AI出来。
						},
						false_case =
						{
							{ "move_to_near_player", 	{} },	-- 走向最近玩家
						}
					},
					{
						matux = 1,										-- 互斥码, 注意, 在此例中与上一项的互斥码相同, 所以只能执行一个, 他们要嘛执行上面那项追打处量, 要嘛就是逃离。
						benefit = 0,
						times = 0,
						conditions =
						{
							{ "is_hp", 				{20} },				-- 是否血量掉到20%以下
						},
						true_case =
						{
							{ "set_state", 			{2} },			-- 切换到AI状态2
						},
						false_case = {}
					},
				}
			}
		},
	},
	{
		state_id = 2,
		desc = "变身前的对白",
		Events =
		{
			{
				events = 10006, 							-- 事件ID, 此例 进入状态事件
				handle_items =
				{
					{
						matux = 1,
						benefit = 0,
						times = 0,
						conditions = {},
						true_case =
						{
							{ "add_buf",  {1} },				-- 添加无敌buf
							{ "speak",  {60000} },			-- 说60000号的对白（变身之类的）
							{ "timer",  {2000, 1000} },		-- 隔2000毫秒后,丢出策划自定义事件1000 自定义事件只能成当前状态生效
						},
						false_case = {}
					},
				}
			},
			{
				events = 1000, 							-- 事件ID, 此例 用户事件
				handle_items =
				{
					{
						matux = 1,
						benefit = 0,
						times = 0,
						conditions = {},
						true_case =
						{
							{ "set_state", {3} },			-- 切换到AI状态3
						},
						false_case = {}
					},
				}
			}
		},
	},
	{
		state_id = 3,
		desc = "狂暴状态AI",
		Events =
		{
			{
				events = 10006, 							-- 事件ID, 此例 进入状态事件
				handle_items =
				{
					{
						matux = 1,
						benefit = 0,
						times = 0,
						conditions = {},
						true_case =
						{
							{ "skill", {12345} },			-- 施放暴风雪技能
							{ "timer", {2000, 1000} },		-- 隔2000毫秒后,丢出策划自定义事件1000
						},
						false_case = {}
					},
				}
			},
			{
				events = 1000, 							-- 事件ID, 此例 用户事件
				handle_items =
				{
					{
						matux = 1,
						benefit = 0,
						times = 0,
						conditions = {},
						true_case =
						{
							{ "skill", 	{9000} },				-- 施放全面战争技能
							{ "timer", 	{2000, 1000} },		-- 隔2000毫秒后,丢出策划自定义事件1000（此处构成循环,每2000毫秒放一次全面战争技能）
						},
						false_case = {}
					},
				}
			},
		},
	}
}






-record(buff_cfg, {
    id = 0,       %bufID
    % client_name = <<>> ,      %名字
    type = 0,   %BUFF类型（1标记buff，2属性buff、3移动变速buff、4间隔性生效buff（无受击表现）、5伤害buff（有受击表现）、6buff组
    tag = 0,     %状态标记（1无敌、2霸体、3眩晕、4冰冻、5免伤、6定身、7沉默）
    attr_type = 0,     %%属性加成类型（1千分比、2具体值
    attrs = [],     %属性值([{attrid，value},....]value可以配置负数，表示减少
    break_by_bati = 0,     %是否可以被霸体清除（1是，0否,伤害buff会被霸体\无敌清除）
    move_speed = 0,     %移动变速比率(千分比，可以配负数）
    interval = 0,     %生效间隔(每隔多少毫秒生效一次，只针对血和蓝，为0代表1次）
    damage = [],     %伤害值[非数组形式是固定值伤害，数组形式是转属性伤害（折算类型（属性值1，伤害值2）
                  % ,作用效果[（普通伤害1，火2，冰3，雷4），数值）]
    passive_info = [], %被动效果[生效判定（1攻击生效，2受击生效）、折算类型（属性值1，伤害值2）
                % 、折算比例、折算者（1攻击方，2受击方）作用者（1攻击方，2受击方)
                % 、附加效果（1ap，火2，冰3，雷4，HP5，mp6）））]
    prop_type = 0, %折算属性类型[属性ID(如果是伤害则不需要填写属性id)]
    pile = 0,      %叠加类型（1=时间叠加，2=效果叠加）
    emitid = 0,    %释放物ID
    reset_skill_id = 0, %重置对应技能的CD
    rate_info = [],   % 怪物类型千分比效果[{怪物类型1，怪物类型2····}，比例]（小怪=0，boss=1，精英怪=2）
    haloid = 0,
    convert_trage,
    value = 0,
    prob = 0,     %生效概率(千分比）
    time = 0, %BUFF持续时间(毫秒）
    skill_bind = 0,
    sub_buffs = [],     %buff子集[{buffid,delay},.....]delay毫秒
    class = []     %buff归属（[归属组、等级、最大叠加次数](加减速组1、定身组2）没有的可为空
}).


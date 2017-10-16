

function util_t2s(obj)
    local lua = ""
    local t = type(obj)
    if t == "number" then
        lua = lua .. obj
    elseif t == "boolean" then
        lua = lua .. tostring(obj)
    elseif t == "string" then
        lua = lua .. string.format("%q", obj)
    elseif t == "table" then
        lua = lua .. "{"
        for k, v in pairs(obj) do
            lua = lua .. "[" .. util_t2s(k) .. "]=" .. util_t2s(v) .. ","
        end
        local metatable = getmetatable(obj)
        if metatable ~= nil and type(metatable.__index) == "table" then
            for k, v in pairs(metatable.__index) do
                lua = lua .. "[" .. util_t2s(k) .. "]=" .. util_t2s(v) .. ","
            end
        end
        lua = lua .. "}"
    elseif t == "nil" then
        return nil
    else
--        error("can not serialize a " .. t .. " type.")
        return "function_type"
    end
    return lua
end


function util_s2t(lua)
    local t = type(lua)
    if t == "nil" or lua == "" then
        return nil
    elseif t == "number" or t == "string" or t == "boolean" then
        lua = tostring(lua)
    else
        error("can not unserialize a " .. t .. " type.")
    end
    lua = "return " .. lua
    local func = loadstring(lua)
    if func == nil then
        return nil
    end
    return func()
end


function util_deepcopy(tDest, tSrc)
    for key, value in pairs(tSrc) do
        if type(value) == "table" then
            tDest[key] = {}
            util_deepcopy(tDest[key], value)
        else
            tDest[key]=value
        end
    end
end


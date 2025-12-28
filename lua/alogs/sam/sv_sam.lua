if not sam then
    ErrorNoHalt("[alogs] " .. (alogs.lang.sam_not_found or "sam not found") .. "\n")
    return
end

local function extract_targets(result)
    if not result or not result[1] then return nil end
    
    local targets = result[1]
    
    if istable(targets) and #targets > 0 then
        return targets
    elseif IsValid(targets) and targets:IsPlayer() then
        return {targets}
    end
    
    return nil
end

local function extract_reason(result, arg_index)
    if result and result[arg_index] then
        return tostring(result[arg_index])
    end
    return ""
end

local function extract_duration(result, arg_index)
    if result and result[arg_index] then
        return tonumber(result[arg_index]) or 0
    end
    return 0
end

hook.Add("SAM.RanCommand", "alogs_capture", function(ply, cmd_name, args, cmd, result)
    if alogs.is_excluded(cmd_name) then return end
    
    local targets = extract_targets(result)
    local reason = ""
    local duration = 0
    
    if cmd_name == "ban" or cmd_name == "banid" then
        duration = extract_duration(result, 2)
        reason = extract_reason(result, 3)
    elseif cmd_name == "kick" then
        reason = extract_reason(result, 2)
    elseif cmd_name == "jail" then
        duration = extract_duration(result, 2)
        reason = extract_reason(result, 3)
    elseif cmd_name == "mute" or cmd_name == "gag" then
        duration = extract_duration(result, 2)
        reason = extract_reason(result, 3)
    elseif cmd_name == "setrank" or cmd_name == "setrankid" then
        reason = extract_reason(result, 2)
        duration = extract_duration(result, 3)
    else
        for i = 2, table.maxn(result) do
            if result[i] and type(result[i]) == "string" then
                reason = result[i]
                break
            end
        end
    end
    
    alogs.add_log(ply, cmd_name, targets, reason, duration)
end)
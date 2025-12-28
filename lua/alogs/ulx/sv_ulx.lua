if not ulx then
    ErrorNoHalt("[alogs] " .. (alogs.lang.ulx_not_found or "ulx not found") .. "\n")
    return
end

local function extract_targets_ulx(targets)
    if not targets then return nil end
    
    if istable(targets) and #targets > 0 then
        return targets
    elseif IsValid(targets) and targets:IsPlayer() then
        return {targets}
    end
    
    return nil
end

local original_fancyLogAdmin = ulx.fancyLogAdmin

function ulx.fancyLogAdmin(calling_ply, format, ...)
    original_fancyLogAdmin(calling_ply, format, ...)
    
    if alogs.is_excluded then
        local args = {...}
        local cmd_name = ""
        local targets = nil
        local reason = ""
        local duration = 0
        
        if format:find("slapped") then
            cmd_name = "slap"
            targets = extract_targets_ulx(args[1])
            if args[2] then duration = tonumber(args[2]) or 0 end
        elseif format:find("whipped") then
            cmd_name = "whip"
            targets = extract_targets_ulx(args[1])
            if args[2] then duration = tonumber(args[2]) or 0 end
            if args[3] then reason = tostring(args[3]) end
        elseif format:find("slayed") then
            cmd_name = "slay"
            targets = extract_targets_ulx(args[1])
        elseif format:find("silently slayed") then
            cmd_name = "sslay"
            targets = extract_targets_ulx(args[1])
        elseif format:find("kicked") then
            cmd_name = "kick"
            targets = extract_targets_ulx(args[1])
            if args[2] then reason = tostring(args[2]) end
        elseif format:find("banned") and format:find("permanently") then
            cmd_name = "ban"
            targets = extract_targets_ulx(args[1])
            duration = 0
            if args[3] then reason = tostring(args[3]) end
        elseif format:find("banned") then
            cmd_name = "ban"
            targets = extract_targets_ulx(args[1])
            if args[2] then
                local time_str = tostring(args[2])
                duration = tonumber(time_str:match("%d+")) or 0
            end
            if args[3] then reason = tostring(args[3]) end
        elseif format:find("unbanned") then
            cmd_name = "unban"
            if args[1] then reason = tostring(args[1]) end
        elseif format:find("jailed") then
            cmd_name = "jail"
            targets = extract_targets_ulx(args[1])
            if args[2] then duration = tonumber(args[2]) or 0 end
        elseif format:find("unjailed") then
            cmd_name = "unjail"
            targets = extract_targets_ulx(args[1])
        elseif format:find("muted") and not format:find("unmuted") then
            cmd_name = "mute"
            targets = extract_targets_ulx(args[1])
        elseif format:find("unmuted") then
            cmd_name = "unmute"
            targets = extract_targets_ulx(args[1])
        elseif format:find("gagged") and not format:find("ungagged") then
            cmd_name = "gag"
            targets = extract_targets_ulx(args[1])
        elseif format:find("ungagged") then
            cmd_name = "ungag"
            targets = extract_targets_ulx(args[1])
        elseif format:find("froze") then
            cmd_name = "freeze"
            targets = extract_targets_ulx(args[1])
        elseif format:find("unfroze") then
            cmd_name = "unfreeze"
            targets = extract_targets_ulx(args[1])
        elseif format:find("granted god mode") then
            cmd_name = "god"
            targets = extract_targets_ulx(args[1])
        elseif format:find("revoked god mode") then
            cmd_name = "ungod"
            targets = extract_targets_ulx(args[1])
        elseif format:find("set the hp") then
            cmd_name = "hp"
            targets = extract_targets_ulx(args[1])
            if args[2] then duration = tonumber(args[2]) or 0 end
        elseif format:find("set the armor") then
            cmd_name = "armor"
            targets = extract_targets_ulx(args[1])
            if args[2] then duration = tonumber(args[2]) or 0 end
        elseif format:find("cloaked") and not format:find("uncloaked") then
            cmd_name = "cloak"
            targets = extract_targets_ulx(args[1])
        elseif format:find("uncloaked") then
            cmd_name = "uncloak"
            targets = extract_targets_ulx(args[1])
        elseif format:find("brought") then
            cmd_name = "bring"
            targets = extract_targets_ulx(args[1])
        elseif format:find("teleported to") then
            cmd_name = "goto"
            targets = extract_targets_ulx(args[1])
        elseif format:find("transported") then
            cmd_name = "send"
            targets = extract_targets_ulx(args[1])
        elseif format:find("teleported") and args[1] then
            cmd_name = "teleport"
            targets = extract_targets_ulx(args[1])
        elseif format:find("noclip") then
            cmd_name = "noclip"
            targets = extract_targets_ulx(args[1])
        end
        
        if cmd_name ~= "" and not alogs.is_excluded(cmd_name) then
            alogs.add_log(calling_ply, cmd_name, targets, reason, duration)
        end
    end
end
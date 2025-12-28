alogs.logs = alogs.logs or {}

function alogs.can_access(ply)
    if not IsValid(ply) then return false end
    
    local usergroup = ply:GetUserGroup()
    
    for _, group in ipairs(alogs.conf.allowed_usergroups) do
        if usergroup == group then
            return true
        end
    end
    
    return false
end

function alogs.is_excluded(cmd)
    for _, excluded in ipairs(alogs.conf.excluded_cmds) do
        if cmd == excluded then
            return true
        end
    end
    return false
end

function alogs.is_special(cmd)
    for _, special in ipairs(alogs.conf.special_cmds) do
        if cmd == special then
            return true
        end
    end
    return false
end

function alogs.format_targets(targets)
    if not targets or targets == "" then return "none" end
    
    if istable(targets) then
        local names = {}
        for _, ply in ipairs(targets) do
            if IsValid(ply) and ply:IsPlayer() then
                table.insert(names, ply:Name())
            end
        end
        return table.concat(names, ", ")
    end
    
    return tostring(targets)
end

if SERVER then
    util.AddNetworkString("alogs_open_menu")
    util.AddNetworkString("alogs_request_logs")
    util.AddNetworkString("alogs_send_logs")
    util.AddNetworkString("alogs_delete_log")
    
    AddCSLuaFile("ui/cl_ui.lua")
    
    function alogs.add_log(admin, cmd, targets, reason, duration)
        if alogs.is_excluded(cmd) then return end
        
        local admin_name = "console"
        local admin_sid = "console"
        
        if IsValid(admin) and admin:IsPlayer() then
            admin_name = admin:Name()
            admin_sid = admin:SteamID()
        end
        
        local targets_str = alogs.format_targets(targets)
        local timestamp = os.time()
        
        alogs.db.add_log(admin_name, admin_sid, cmd, targets_str, reason or "", duration or 0, timestamp)
    end
    
    net.Receive("alogs_request_logs", function(_, ply)
        if not alogs.can_access(ply) then return end
        
        local filter_type = net.ReadString()
        local filter_value = net.ReadString()
        local page = net.ReadUInt(16)
        local special_only = net.ReadBool()
        
        alogs.db.get_logs(filter_type, filter_value, page, special_only, function(logs, total)
            net.Start("alogs_send_logs")
            net.WriteTable(logs)
            net.WriteUInt(total, 32)
            net.WriteUInt(page, 16)
            net.Send(ply)
        end)
    end)
    
    net.Receive("alogs_delete_log", function(_, ply)
        if not alogs.can_access(ply) then return end
        
        local log_id = net.ReadUInt(32)
        alogs.db.delete_log(log_id)
    end)
    
    hook.Add("PlayerSay", "alogs_chat_command", function(ply, text)
        text = string.lower(string.Trim(text))
        
        for _, cmd in ipairs(alogs.conf.commands) do
            if text == string.lower(cmd) then
                if alogs.can_access(ply) then
                    net.Start("alogs_open_menu")
                    net.Send(ply)
                end
                return ""
            end
        end
    end)
    
    timer.Create("alogs_cleanup", 86400, 0, function()
        alogs.db.cleanup_old_logs(alogs.conf.cleanup_days)
    end)
end

if CLIENT then
    include("ui/cl_ui.lua")
    
    net.Receive("alogs_open_menu", function()
        alogs.request_logs("", "", 1, false, function(logs, total, page)
            if alogs.ui and alogs.ui.open then
                alogs.ui.open()
            else
                chat.AddText(Color(255, 50, 50), "[alogs] ", Color(255, 255, 255), "UI not loaded")
            end
        end)
    end)
    
    function alogs.request_logs(filter_type, filter_value, page, special_only, callback)
        alogs.ui = alogs.ui or {}
        alogs.ui.current_callback = callback
        
        net.Start("alogs_request_logs")
        net.WriteString(filter_type or "")
        net.WriteString(filter_value or "")
        net.WriteUInt(page or 1, 16)
        net.WriteBool(special_only or false)
        net.SendToServer()
    end
    
    net.Receive("alogs_send_logs", function()
        local logs = net.ReadTable()
        local total = net.ReadUInt(32)
        local page = net.ReadUInt(16)
        
        if alogs.ui and alogs.ui.current_callback then
            alogs.ui.current_callback(logs, total, page)
        end
    end)
    
    function alogs.delete_log(log_id)
        net.Start("alogs_delete_log")
        net.WriteUInt(log_id, 32)
        net.SendToServer()
    end
end
alogs.ui = alogs.ui or {}
alogs.ui.frame = nil
alogs.ui.current_page = 1
alogs.ui.total_pages = 1
alogs.ui.current_filter_type = ""
alogs.ui.current_filter_value = ""
alogs.ui.current_special_only = false

local function format_duration(minutes)
    if minutes == 0 then
        return alogs.lang.duration_permanent
    end
    
    local days = math.floor(minutes / 1440)
    local hours = math.floor((minutes % 1440) / 60)
    local mins = minutes % 60
    
    if days > 0 then
        if hours > 0 then
            return string.format("%dd %dh", days, hours)
        else
            return string.format("%dd", days)
        end
    elseif hours > 0 then
        if mins > 0 then
            return string.format("%dh %dm", hours, mins)
        else
            return string.format("%dh", hours)
        end
    else
        return string.format("%dm", mins)
    end
end

local function create_log_list(parent, special_only)
    local container = vgui.Create("DPanel", parent)
    container:Dock(FILL)
    
    local filter_panel = vgui.Create("DPanel", container)
    filter_panel:Dock(TOP)
    filter_panel:SetTall(35)
    filter_panel:DockMargin(3, 3, 3, 3)
    
    local filter_type = vgui.Create("DComboBox", filter_panel)
    filter_type:SetPos(3, 3)
    filter_type:SetSize(100, 25)
    filter_type:SetValue(alogs.lang.filter_by)
    filter_type:AddChoice(alogs.lang.filter_admin)
    filter_type:AddChoice(alogs.lang.filter_cmd)
    filter_type:AddChoice(alogs.lang.filter_target)
    
    local filter_entry = vgui.Create("DTextEntry", filter_panel)
    filter_entry:SetPos(108, 3)
    filter_entry:SetSize(150, 25)
    filter_entry:SetPlaceholderText(alogs.lang.search_placeholder)
    
    local search_btn = vgui.Create("DButton", filter_panel)
    search_btn:SetPos(263, 3)
    search_btn:SetSize(60, 25)
    search_btn:SetText(alogs.lang.search)
    search_btn.DoClick = function()
        alogs.ui.current_page = 1
        alogs.ui.current_filter_type = filter_type:GetValue()
        alogs.ui.current_filter_value = filter_entry:GetValue()
        alogs.ui.current_special_only = special_only
        
        local filter_type_value = alogs.ui.current_filter_type
        if filter_type_value == alogs.lang.filter_by then
            filter_type_value = ""
        elseif filter_type_value == alogs.lang.filter_admin then
            filter_type_value = "admin"
        elseif filter_type_value == alogs.lang.filter_cmd then
            filter_type_value = "cmd"
        elseif filter_type_value == alogs.lang.filter_target then
            filter_type_value = "target"
        end
        
        alogs.request_logs(
            filter_type_value,
            alogs.ui.current_filter_value,
            alogs.ui.current_page,
            special_only,
            function(logs, total, page)
                if IsValid(container) and IsValid(container.logs_list) then
                    container.logs_list:populate(logs)
                    container.pagination:update(total)
                end
            end
        )
    end
    
    local clear_btn = vgui.Create("DButton", filter_panel)
    clear_btn:SetPos(328, 3)
    clear_btn:SetSize(60, 25)
    clear_btn:SetText(alogs.lang.clear)
    clear_btn.DoClick = function()
        filter_type:SetValue(alogs.lang.filter_by)
        filter_entry:SetValue("")
        alogs.ui.current_page = 1
        alogs.ui.current_filter_type = ""
        alogs.ui.current_filter_value = ""
        
        alogs.request_logs("", "", 1, special_only, function(logs, total, page)
            if IsValid(container) and IsValid(container.logs_list) then
                container.logs_list:populate(logs)
                container.pagination:update(total)
            end
        end)
    end
    
    local logs_list = vgui.Create("DListView", container)
    logs_list:Dock(FILL)
    logs_list:DockMargin(3, 0, 3, 3)
    logs_list:SetMultiSelect(false)
    
    logs_list:AddColumn(alogs.lang.col_id):SetFixedWidth(35)
    logs_list:AddColumn(alogs.lang.col_admin):SetFixedWidth(100)
    logs_list:AddColumn(alogs.lang.col_cmd):SetFixedWidth(80)
    logs_list:AddColumn(alogs.lang.col_targets):SetFixedWidth(120)
    logs_list:AddColumn(alogs.lang.col_date):SetFixedWidth(110)
    logs_list:AddColumn(alogs.lang.col_reason)
    logs_list:AddColumn(alogs.lang.col_duration):SetFixedWidth(70)
    
    logs_list.OnRowRightClick = function(s, line_id, line)
        local menu = DermaMenu()
        
        menu:AddOption(alogs.lang.menu_copy, function()
            local text = string.format(
                alogs.lang.copy_format,
                line:GetValue(2),
                line:GetValue(3),
                line:GetValue(4),
                line:GetValue(5),
                line:GetValue(6),
                line:GetValue(7)
            )
            SetClipboardText(text)
        end)
        
        menu:Open()
    end
    
    function logs_list:populate(logs)
        self:Clear()
        
        for _, log in ipairs(logs) do
            local date = os.date("%d/%m/%Y %H:%M", tonumber(log.timestamp))
            local duration = tonumber(log.duration) or 0
            local duration_str = format_duration(duration)
            
            local reason = log.reason
            if not reason or reason == "" or reason == "none" then
                reason = "--"
            end
            
            self:AddLine(
                log.id,
                log.admin_name,
                log.cmd,
                log.targets,
                date,
                reason,
                duration_str
            )
        end
    end
    
    container.logs_list = logs_list
    
    local pagination = vgui.Create("DPanel", container)
    pagination:Dock(BOTTOM)
    pagination:SetTall(30)
    pagination:DockMargin(3, 0, 3, 3)
    
    pagination.prev_btn = vgui.Create("DButton", pagination)
    pagination.prev_btn:Dock(LEFT)
    pagination.prev_btn:SetWide(80)
    pagination.prev_btn:DockMargin(0, 0, 3, 0)
    pagination.prev_btn:SetText(alogs.lang.btn_prev)
    pagination.prev_btn.DoClick = function()
        if alogs.ui.current_page > 1 then
            alogs.ui.current_page = alogs.ui.current_page - 1
            
            local filter_type_value = alogs.ui.current_filter_type
            if filter_type_value == alogs.lang.filter_by then
                filter_type_value = ""
            elseif filter_type_value == alogs.lang.filter_admin then
                filter_type_value = "admin"
            elseif filter_type_value == alogs.lang.filter_cmd then
                filter_type_value = "cmd"
            elseif filter_type_value == alogs.lang.filter_target then
                filter_type_value = "target"
            end
            
            alogs.request_logs(
                filter_type_value,
                alogs.ui.current_filter_value,
                alogs.ui.current_page,
                special_only,
                function(logs, total, page)
                    if IsValid(container) and IsValid(container.logs_list) then
                        container.logs_list:populate(logs)
                        container.pagination:update(total)
                    end
                end
            )
        end
    end
    
    pagination.page_label = vgui.Create("DLabel", pagination)
    pagination.page_label:Dock(FILL)
    pagination.page_label:SetContentAlignment(5)
    pagination.page_label:SetText(alogs.lang.page_info:format(1, 1, 0))
    pagination.page_label:SetTextColor(Color(0, 0, 0))
    
    pagination.next_btn = vgui.Create("DButton", pagination)
    pagination.next_btn:Dock(RIGHT)
    pagination.next_btn:SetWide(80)
    pagination.next_btn:DockMargin(3, 0, 0, 0)
    pagination.next_btn:SetText(alogs.lang.btn_next)
    pagination.next_btn.DoClick = function()
        if alogs.ui.current_page < alogs.ui.total_pages then
            alogs.ui.current_page = alogs.ui.current_page + 1
            
            local filter_type_value = alogs.ui.current_filter_type
            if filter_type_value == alogs.lang.filter_by then
                filter_type_value = ""
            elseif filter_type_value == alogs.lang.filter_admin then
                filter_type_value = "admin"
            elseif filter_type_value == alogs.lang.filter_cmd then
                filter_type_value = "cmd"
            elseif filter_type_value == alogs.lang.filter_target then
                filter_type_value = "target"
            end
            
            alogs.request_logs(
                filter_type_value,
                alogs.ui.current_filter_value,
                alogs.ui.current_page,
                special_only,
                function(logs, total, page)
                    if IsValid(container) and IsValid(container.logs_list) then
                        container.logs_list:populate(logs)
                        container.pagination:update(total)
                    end
                end
            )
        end
    end
    
    function pagination:update(total)
        alogs.ui.total_pages = math.max(1, math.ceil(total / 30))
        self.page_label:SetText(alogs.lang.page_info:format(alogs.ui.current_page, alogs.ui.total_pages, total))
    end
    
    container.pagination = pagination
    container.special_only = special_only
    
    function container:load_data()
        alogs.ui.current_page = 1
        alogs.ui.current_filter_type = ""
        alogs.ui.current_filter_value = ""
        
        alogs.request_logs("", "", 1, special_only, function(logs, total, page)
            if IsValid(self) and IsValid(self.logs_list) then
                self.logs_list:populate(logs)
                self.pagination:update(total)
            end
        end)
    end
    
    return container
end

function alogs.ui.open()
    if IsValid(alogs.ui.frame) then
        alogs.ui.frame:Remove()
        alogs.ui.frame = nil
    end
    
    alogs.ui.current_page = 1
    alogs.ui.current_filter_type = ""
    alogs.ui.current_filter_value = ""
    alogs.ui.current_special_only = false
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(800, 500)
    frame:Center()
    frame:SetTitle(alogs.lang.menu_title)
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()
    frame:SetSizable(true)
    frame:SetMinWidth(600)
    frame:SetMinHeight(400)
    
    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40))
        
        local credits = alogs.conf.credits
        draw.SimpleText("v" .. credits.version .. " | " .. credits.license, "DermaDefault", 10, h - 18, Color(150, 150, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    local main_container = vgui.Create("DPanel", frame)
    main_container:Dock(FILL)
    main_container:DockMargin(5, 5, 5, 25)
    
    local sidebar = vgui.Create("DPanel", main_container)
    sidebar:Dock(LEFT)
    sidebar:SetWide(150)
    sidebar:DockMargin(0, 0, 5, 0)
    
    local content = vgui.Create("DPanel", main_container)
    content:Dock(FILL)
    
    local divider = vgui.Create("DPanel", main_container)
    divider:SetWide(5)
    divider:SetPos(sidebar:GetWide(), 0)
    divider:SetCursor("sizewe")
    
    local dragging = false
    local drag_start_x = 0
    local sidebar_start_width = 0
    
    divider.OnMousePressed = function(self, keyCode)
        if keyCode == MOUSE_LEFT then
            dragging = true
            drag_start_x = gui.MouseX()
            sidebar_start_width = sidebar:GetWide()
        end
    end
    
    divider.OnMouseReleased = function(self, keyCode)
        if keyCode == MOUSE_LEFT then
            dragging = false
        end
    end
    
    divider.Think = function(self)
        if dragging then
            local mouse_x = gui.MouseX()
            local delta = mouse_x - drag_start_x
            local new_width = math.Clamp(sidebar_start_width + delta, 100, 300)
            sidebar:SetWide(new_width)
        end
    end
    
    local tab_all = vgui.Create("DButton", sidebar)
    tab_all:Dock(TOP)
    tab_all:SetTall(40)
    tab_all:DockMargin(3, 3, 3, 3)
    tab_all:SetText(alogs.lang.tab_all)
    tab_all:SetIcon("icon16/page_white_text.png")
    
    local tab_special = vgui.Create("DButton", sidebar)
    tab_special:Dock(TOP)
    tab_special:SetTall(40)
    tab_special:DockMargin(3, 3, 3, 3)
    tab_special:SetText(alogs.lang.tab_special)
    tab_special:SetIcon("icon16/shield.png")
    
    local credits_label = vgui.Create("DLabel", sidebar)
    credits_label:Dock(BOTTOM)
    credits_label:SetTall(20)
    credits_label:DockMargin(5, 5, 5, 5)
    credits_label:SetText(alogs.conf.credits.author)
    credits_label:SetTextColor(Color(100, 100, 100))
    credits_label:SetContentAlignment(7)
    
    local content_all = create_log_list(content, false)
    content_all:SetVisible(true)
    
    local content_special = create_log_list(content, true)
    content_special:SetVisible(false)
    
    local current_tab = tab_all
    
    local function switch_tab(tab, content_panel, is_special)
        current_tab = tab
        content_all:SetVisible(not is_special)
        content_special:SetVisible(is_special)
        
        tab_all:SetToggle(not is_special)
        tab_special:SetToggle(is_special)
        
        if content_panel.load_data then
            content_panel:load_data()
        end
    end
    
    tab_all.DoClick = function()
        switch_tab(tab_all, content_all, false)
    end
    
    tab_special.DoClick = function()
        switch_tab(tab_special, content_special, true)
    end
    
    tab_all:SetToggle(true)
    
    alogs.ui.frame = frame
    
    content_all:load_data()
end
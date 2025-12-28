require("mysqloo")

alogs.db = alogs.db or {}
alogs.db.connection = nil
alogs.db.use_mysql = alogs.conf.use_mysql
alogs.db.queue = {}

local function log_error(err)
    ErrorNoHalt("[alogs] " .. alogs.lang.db_error .. ": " .. tostring(err) .. "\n")
end

local function log_msg(msg)
    MsgC(Color(255, 50, 50), "[alogs] ", Color(255, 255, 255), msg .. "\n")
end

local function get_table_name()
    local prefix = string.lower(alogs.conf.adminmod or "sam")
    return prefix .. "_alogs_logs"
end

function alogs.db.init()
    if alogs.db.use_mysql then
        alogs.db.init_mysql()
    else
        alogs.db.init_sqlite()
    end
end

function alogs.db.init_sqlite()
    local table_name = get_table_name()
    
    sql.Query(string.format("CREATE TABLE IF NOT EXISTS %s (id INTEGER PRIMARY KEY AUTOINCREMENT, admin_name TEXT, admin_sid TEXT, cmd TEXT, targets TEXT, reason TEXT, duration INTEGER, timestamp INTEGER)", table_name))
    sql.Query(string.format("CREATE INDEX IF NOT EXISTS idx_%s_timestamp ON %s(timestamp)", table_name, table_name))
    sql.Query(string.format("CREATE INDEX IF NOT EXISTS idx_%s_cmd ON %s(cmd)", table_name, table_name))
    sql.Query(string.format("CREATE INDEX IF NOT EXISTS idx_%s_admin_sid ON %s(admin_sid)", table_name, table_name))
    
    log_msg(alogs.lang.db_sqlite_init)
end

function alogs.db.init_mysql()
    if not alogs.conf.use_mysql then
        alogs.db.init_sqlite()
        return
    end
    
    if not mysqloo then
        log_error(alogs.lang.db_mysql_not_found)
        alogs.db.use_mysql = false
        alogs.db.init_sqlite()
        return
    end
    
    local conf = alogs.mysql_conf
    
    alogs.db.connection = mysqloo.connect(conf.host, conf.user, conf.pass, conf.db, conf.port)
    
    function alogs.db.connection:onConnected()
        log_msg(alogs.lang.db_mysql_connected)
        
        local table_name = get_table_name()
        
        local q = alogs.db.connection:query(string.format([[
            CREATE TABLE IF NOT EXISTS %s (
                id INT AUTO_INCREMENT PRIMARY KEY,
                admin_name VARCHAR(255),
                admin_sid VARCHAR(64),
                cmd VARCHAR(64),
                targets TEXT,
                reason TEXT,
                duration INT,
                timestamp INT,
                INDEX idx_timestamp (timestamp),
                INDEX idx_cmd (cmd),
                INDEX idx_admin_sid (admin_sid)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]], table_name))
        
        function q:onSuccess()
            for _, queued in ipairs(alogs.db.queue) do
                queued()
            end
            alogs.db.queue = {}
        end
        
        function q:onError(err)
            log_error(err)
        end
        
        q:start()
    end
    
    function alogs.db.connection:onConnectionFailed(err)
        log_error(alogs.lang.db_mysql_failed .. ": " .. err)
        alogs.db.use_mysql = false
        alogs.db.init_sqlite()
    end
    
    alogs.db.connection:connect()
end

function alogs.db.escape(str)
    str = tostring(str)
    
    if alogs.db.use_mysql and alogs.db.connection then
        return "'" .. alogs.db.connection:escape(str) .. "'"
    else
        return sql.SQLStr(str)
    end
end

function alogs.db.query(q, callback)
    if alogs.db.use_mysql then
        if not alogs.db.connection or alogs.db.connection:status() ~= mysqloo.DATABASE_CONNECTED then
            table.insert(alogs.db.queue, function()
                alogs.db.query(q, callback)
            end)
            return
        end
        
        local query = alogs.db.connection:query(q)
        
        function query:onSuccess(data)
            if callback then
                callback(data or {})
            end
        end
        
        function query:onError(err)
            log_error(err)
        end
        
        query:start()
    else
        local result = sql.Query(q)
        if result == false then
            log_error(sql.LastError())
        elseif callback then
            callback(result or {})
        end
    end
end

function alogs.db.add_log(admin_name, admin_sid, cmd, targets, reason, duration, timestamp)
    local table_name = get_table_name()
    
    local q = string.format(
        "INSERT INTO %s (admin_name, admin_sid, cmd, targets, reason, duration, timestamp) VALUES (%s, %s, %s, %s, %s, %d, %d)",
        table_name,
        alogs.db.escape(admin_name),
        alogs.db.escape(admin_sid),
        alogs.db.escape(cmd),
        alogs.db.escape(targets),
        alogs.db.escape(reason),
        duration,
        timestamp
    )
    
    alogs.db.query(q)
end

function alogs.db.get_logs(filter_type, filter_value, page, special_only, callback)
    page = page or 1
    local offset = (page - 1) * 30
    local table_name = get_table_name()
    
    local where = ""
    
    if special_only then
        local special_cmds = {}
        for _, cmd in ipairs(alogs.conf.special_cmds) do
            table.insert(special_cmds, alogs.db.escape(cmd))
        end
        where = " WHERE cmd IN (" .. table.concat(special_cmds, ",") .. ")"
    end
    
    if filter_type ~= "" and filter_value ~= "" then
        local filter_clause = ""
        
        if filter_type == "admin" then
            filter_clause = "admin_name LIKE " .. alogs.db.escape("%" .. filter_value .. "%")
        elseif filter_type == "cmd" then
            filter_clause = "cmd LIKE " .. alogs.db.escape("%" .. filter_value .. "%")
        elseif filter_type == "target" then
            filter_clause = "targets LIKE " .. alogs.db.escape("%" .. filter_value .. "%")
        elseif filter_type == "date" then
            local date_start = tonumber(filter_value) or 0
            local date_end = date_start + 86400
            filter_clause = string.format("timestamp >= %d AND timestamp < %d", date_start, date_end)
        end
        
        if where == "" then
            where = " WHERE " .. filter_clause
        else
            where = where .. " AND " .. filter_clause
        end
    end
    
    local count_q = string.format("SELECT COUNT(*) as total FROM %s%s", table_name, where)
    
    alogs.db.query(count_q, function(count_result)
        local total = 0
        if count_result and count_result[1] then
            total = tonumber(count_result[1].total) or 0
        end
        
        local logs_q = string.format(
            "SELECT * FROM %s%s ORDER BY timestamp DESC LIMIT 30 OFFSET %d",
            table_name,
            where,
            offset
        )
        
        alogs.db.query(logs_q, function(logs)
            callback(logs or {}, total)
        end)
    end)
end

function alogs.db.delete_log(log_id)
    local table_name = get_table_name()
    local q = string.format("DELETE FROM %s WHERE id = %d", table_name, log_id)
    alogs.db.query(q)
end

function alogs.db.cleanup_old_logs(days)
    local cutoff = os.time() - (days * 86400)
    local table_name = get_table_name()
    local q = string.format("DELETE FROM %s WHERE timestamp < %d", table_name, cutoff)
    
    alogs.db.query(q, function()
        log_msg(alogs.lang.db_cleanup:format(days))
    end)
end

hook.Add("Initialize", "alogs_db_init", function()
    timer.Simple(1, function()
        alogs.db.init()
    end)
end)
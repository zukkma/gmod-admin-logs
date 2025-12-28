--[[

MIT License

Copyright (c) 2025 @zuk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]

alogs = alogs or {}
alogs.version = "1.0.0"
alogs.lang = {}

local function load_language()
    local lang_file = "alogs/lang/" .. (alogs.conf.language or "english") .. ".lua"
    
    if not file.Exists(lang_file, "LUA") then
        lang_file = "alogs/lang/english.lua"
    end
    if SERVER then
        alogs.lang = AddCSLuaFile(lang_file) or {}
    end
    alogs.lang = include(lang_file) or {}
end

local function load(path)
    local files, folders = file.Find("alogs/" .. path .. "/*", "LUA")
    
    for _, folder in ipairs(folders) do
        load(path .. "/" .. folder)
    end
    
    for _, f in ipairs(files) do
        local prefix = string.sub(f, 1, 3)
        local full_path = "alogs/" .. path .. "/" .. f
        
        if prefix == "sh_" then
            if SERVER then AddCSLuaFile(full_path) end
            include(full_path)
        elseif prefix == "sv_" and SERVER then
            include(full_path)
        elseif prefix == "cl_" and CLIENT then
            include(full_path)
        end
    end
end

local function load_adminmod()
    if not SERVER then return end
    
    local adminmod = string.lower(alogs.conf.adminmod or "sam")
    
    if adminmod == "sam" then
        if sam then
            include("alogs/sam/sv_sam.lua")
        else
            ErrorNoHalt("[alogs] SAM is set as adminmod but not found!\n")
        end
    elseif adminmod == "ulx" then
        if ulx then
            include("alogs/ulx/sv_ulx.lua")
        else
            ErrorNoHalt("[alogs] ULX is set as adminmod but not found!\n")
        end
    else
        ErrorNoHalt("[alogs] Invalid adminmod specified: " .. adminmod .. "\n")
    end
end

if SERVER then
    AddCSLuaFile("alogs/config.lua")
    include("alogs/database/mysql.lua")
end

include("alogs/config.lua")
load_language()
load("core")
load("database")
load_adminmod()

if SERVER then
    MsgC(Color(255, 50, 50), "[alogs] ", Color(255, 255, 255), alogs.lang.loaded:format(alogs.version) .. "\n")
    MsgC(Color(255, 50, 50), "[alogs] ", Color(255, 255, 255), "Using " .. string.upper(alogs.conf.adminmod or "SAM") .. " as admin mod\n")
    
    timer.Simple(2, function()
        http.Fetch("https://raw.githubusercontent.com/zukkma/gmod-admin-logs/refs/heads/main/version",
            function(body)
                local latest_version = string.Trim(body)
                
                if latest_version ~= alogs.version then
                    MsgC(Color(255, 50, 50), "[alogs] ", Color(255, 255, 255), alogs.lang.outdated_version:format(latest_version) .. "\n")
                else
                    MsgC(Color(50, 255, 50), "[alogs] ", Color(255, 255, 255), alogs.lang.uptodate:format(latest_version) .. "\n")
                end
            end,
            function(error)
            end
        )
    end)
end
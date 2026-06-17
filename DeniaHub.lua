local _BUILD_VERSION = "1.0"
local _BUILD_BRAND = "DeniaHub"

local _SAFE = {}
do
    _SAFE.pcall    = pcall
    _SAFE.type     = type
    _SAFE.tostring = tostring
    _SAFE.tonumber = tonumber
    _SAFE.rawget   = rawget
    _SAFE.rawset   = rawset
    _SAFE.select   = select
    _SAFE.pairs    = pairs
    _SAFE.ipairs   = ipairs
    _SAFE.next     = next
    _SAFE.unpack   = unpack or table.unpack
    _SAFE.error    = error
    _SAFE.setmetatable = setmetatable
    _SAFE.getmetatable = getmetatable

    _SAFE.string_sub    = string.sub
    _SAFE.string_byte   = string.byte
    _SAFE.string_char   = string.char
    _SAFE.string_format = string.format
    _SAFE.string_len    = string.len
    _SAFE.string_find   = string.find
    _SAFE.string_rep    = string.rep
    _SAFE.string_lower  = string.lower
    _SAFE.string_upper  = string.upper
    _SAFE.string_gsub   = string.gsub
    _SAFE.string_match  = string.match
    _SAFE.string_gmatch = string.gmatch

    _SAFE.math_floor  = math.floor
    _SAFE.math_random = math.random
    _SAFE.math_abs    = math.abs
    _SAFE.math_max    = math.max
    _SAFE.math_min    = math.min
    _SAFE.math_huge   = math.huge

    _SAFE.os_time  = os.time
    _SAFE.os_clock = os.clock

    _SAFE.table_insert = table.insert
    _SAFE.table_remove = table.remove
    _SAFE.table_concat = table.concat
    _SAFE.table_sort   = table.sort

    _SAFE.task_spawn = task.spawn
    _SAFE.task_wait  = task.wait
    _SAFE.task_defer = task.defer
    _SAFE.task_delay = task.delay

    _SAFE.game = game
    _SAFE.workspace = workspace

    _SAFE.pcall(function()
        if getgenv then _SAFE.getgenv = getgenv end
        if iscclosure then _SAFE.iscclosure = iscclosure end
        if islclosure then _SAFE.islclosure = islclosure end
        if getrawmetatable then _SAFE.getrawmetatable = getrawmetatable end
        if hookfunction then _SAFE.hookfunction = hookfunction end
        if newcclosure then _SAFE.newcclosure = newcclosure end
    end)

    local _bootClean = true
    _SAFE.pcall(function()
        if _SAFE.iscclosure then
            local criticals = { _SAFE.pcall, _SAFE.type, _SAFE.tostring, _SAFE.rawget, _SAFE.pairs, _SAFE.ipairs, _SAFE.next, _SAFE.select }
            for _, fn in _SAFE.ipairs(criticals) do
                if not _SAFE.iscclosure(fn) then _bootClean = false end
            end
        end
    end)

    if not _bootClean then
        warn("[DeniaHub] Anti-hook bootstrap: hooks detected at load time!")
    end

    if _SAFE.getgenv then _SAFE.getgenv()._SAFE = _SAFE end
end

local _modules = {}

_modules["security"] = function()
    local Security = {}
    local Utils = nil
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")

    local _violations = {}
    local _violationCount = 0
    local _degraded = false

    local function _s(bytes)
        local chars = {}
        for i = 1, #bytes do chars[i] = string.char(bytes[i]) end
        return table.concat(chars)
    end

    local _STR = {
        request = _s({114,101,113,117,101,115,116}),
        http_request = _s({104,116,116,112,95,114,101,113,117,101,115,116}),
        namecall = _s({95,95,110,97,109,101,99,97,108,108}),
        index = _s({95,95,105,110,100,101,120}),
        C_source = _s({91,67,93}),
    }

    local function _isHooked(func)
        if type(func) ~= "function" then return true end
        if iscclosure and not iscclosure(func) then return true end
        if islclosure and islclosure(func) then return true end
        if debug and debug.info then
            local s, source = pcall(debug.info, func, "s")
            if s and source and source ~= _STR.C_source then return true end
        end
        return false
    end

    local function _getCriticalFunctions()
        local criticals = {}
        local checks = { {pcall,"pcall"},{type,"type"},{tostring,"tostring"},{rawget,"rawget"},{rawset,"rawset"} }
        for _, item in ipairs(checks) do
            if item[1] then table.insert(criticals, item) end
        end
        if string then
            if string.sub then table.insert(criticals, {string.sub,"string.sub"}) end
            if string.byte then table.insert(criticals, {string.byte,"string.byte"}) end
        end
        if os and os.time then table.insert(criticals, {os.time,"os.time"}) end
        pcall(function()
            table.insert(criticals, {HttpService.JSONEncode,"HttpService.JSONEncode"})
            table.insert(criticals, {HttpService.JSONDecode,"HttpService.JSONDecode"})
        end)
        pcall(function()
            if getgenv then
                local genv = getgenv()
                local reqFunc = genv[_STR.request] or genv[_STR.http_request]
                if reqFunc then table.insert(criticals, {reqFunc,"NetworkHandler"}) end
            end
        end)
        return criticals
    end

    function Security.checkFunctionIntegrity()
        local violations = {}
        local criticals = _getCriticalFunctions()
        for _, item in ipairs(criticals) do
            if item[1] and _isHooked(item[1]) then table.insert(violations, item[2]) end
        end
        return #violations == 0, violations
    end

    function Security._checkMetamethods()
        local clean = true
        pcall(function()
            if not getrawmetatable then return end
            local gameMt = getrawmetatable(game)
            if gameMt then
                local ncHook = rawget(gameMt, _STR.namecall)
                if ncHook and islclosure and islclosure(ncHook) then clean = false end
            end
        end)
        return clean
    end

    function Security._recordViolation(category, detail)
        _violationCount = _violationCount + 1
        table.insert(_violations, {category=category, detail=detail or "", time=os.time()})
    end

    function Security.getViolationCount() return _violationCount end
    function Security.isDegraded() return _degraded end

    local function _silentDegrade(reason)
        if _degraded then return end
        _degraded = true
        task.spawn(function()
            task.wait(math.random(10, 30))
            pcall(function() if getgenv then getgenv().DeniaShuttingDown = true end end)
        end)
    end

    function Security.runFullScan()
        local allClean = true
        local reasons = {}
        local funcOk, funcViolations = Security.checkFunctionIntegrity()
        if not funcOk then
            allClean = false
            for _, v in ipairs(funcViolations) do
                Security._recordViolation("function_hooked", v)
                table.insert(reasons, "Hooked: " .. v)
            end
        end
        if not Security._checkMetamethods() then
            allClean = false
            Security._recordViolation("metamethod_hooked", "Metamethods tampered")
            table.insert(reasons, "Metamethod hook detected")
        end
        return allClean, reasons
    end

    function Security.startHeartbeat()
        task.spawn(function()
            task.wait(math.random(30, 60))
            while true do
                task.wait(math.random(45, 120))
                pcall(function() if getgenv and getgenv().DeniaShuttingDown then return end end)
                local clean, reasons = Security.runFullScan()
                if not clean and not _degraded then _silentDegrade(table.concat(reasons, "; ")) end
            end
        end)
    end

    function Security.getSafeRequestFunction()
        local reqFunc = nil
        pcall(function()
            if getgenv then
                local env = getgenv()
                reqFunc = env[_STR.request] or env[_STR.http_request]
            end
        end)
        if not reqFunc then reqFunc = request or http_request or (syn and syn.request) or (http and http.request) end
        if reqFunc and _isHooked(reqFunc) then
            Security._recordViolation("hooked_request", "HTTP request function hooked")
            local fallbacks = {request, http_request, syn and syn.request, http and http.request}
            for _, fb in ipairs(fallbacks) do if fb and not _isHooked(fb) then return fb end end
            _silentDegrade("All HTTP functions hooked")
            return nil
        end
        return reqFunc
    end

    function Security.init(utilsModule)
        Utils = utilsModule
        local clean, reasons = Security.runFullScan()
        print(clean and "[DeniaHub-Security] [+] Initial scan: CLEAN" or "[DeniaHub-Security] [!] Initial issues: " .. #reasons)
        return clean
    end

    return Security
end

_modules["utils"] = function()
    local Utils = {}
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local lp = Players.LocalPlayer

    Utils.ROOT_FOLDER = "DeniaHub"
    Utils.DATA_FOLDER = "DeniaHub/Data"
    Utils.IMAGES_FOLDER = "DeniaHub/Assets/Images"
    Utils.SOUNDS_FOLDER = "DeniaHub/Assets/Sounds"
    Utils.API_BASE = "https://keyserver.nexusdevs.fun"
    Utils.KEY_FILE = "DeniaHub/Data/DeniaKey.nxs"
    Utils.STATS_FILE = "DeniaHub/Data/DeniaStats.nxs"
    Utils.CLIENT_VERSION = "1.0"
    Utils.AUTH_URL = Utils.API_BASE
    Utils.SAVE_INTERVAL = 10
    Utils._statsLastSaved = 0
    Utils._statsDirty = false
    Utils._statsCache = nil
    Utils._bankaiSound = nil
    Utils.BANKAI_FILE = "DeniaHub/Assets/Sounds/bankai.mp3"
    Utils.LOGO_FILE = "DeniaHub/Assets/Images/DeniaLogo.png"
    Utils.BANKAI_URL = "https://raw.githubusercontent.com/Ryu-Dev-here/assetsfora/main/bankai.mp3"
    Utils.LOGO_URL = "https://i.imgur.com/YOURLOGOID.png"

    function Utils.httpPost(url, body, headers)
        headers = headers or {}
        headers["Content-Type"] = headers["Content-Type"] or "application/json"
        local requestFn = request or http_request or (http and http.request) or (syn and syn.request)
        if requestFn then
            local ok, response = pcall(requestFn, {
                Url = url, Method = "POST", Headers = headers,
                Body = (type(body) == "string") and body or HttpService:JSONEncode(body),
            })
            if ok and response then return response end
        end
        local ok2, response2 = pcall(function()
            return HttpService:RequestAsync({
                Url = url, Method = "POST", Headers = headers,
                Body = (type(body) == "string") and body or HttpService:JSONEncode(body),
            })
        end)
        if ok2 and response2 then return response2 end
        return nil
    end

    function Utils.initFolders()
        pcall(function()
            local mk = makefolder or function() end
            local isf = isfolder or function() return false end
            for _, folder in ipairs({Utils.ROOT_FOLDER, Utils.DATA_FOLDER, "DeniaHub/Assets", Utils.IMAGES_FOLDER, Utils.SOUNDS_FOLDER}) do
                if not isf(folder) then mk(folder) end
            end
        end)
    end
    Utils.initFolders()

    local ENCRYPT_KEY = "45b090e9af3bd54b67216a6d6a8e40bf66eba58cb4adc4286d97ff92137d1bdf"
    local NXS_HEADER, NXS_VERSION, NXS_SEP = "NXS", 2, "|"
    local FNV_OFFSET, FNV_PRIME = 2166136261, 16777619

    local function fnv1aHash(data)
        local hash = FNV_OFFSET
        for i = 1, #data do
            hash = bit32.bxor(hash, data:byte(i))
            hash = bit32.band(hash * FNV_PRIME, 0xFFFFFFFF)
        end
        return string.format("%08X", hash)
    end

    local function xorEncrypt(data, key)
        local result = {}
        for i = 1, #data do
            result[i] = string.char(bit32.bxor(data:byte(i), key:byte(((i-1) % #key) + 1)))
        end
        return table.concat(result)
    end

    local function toHex(str)
        local hex = {}
        for i = 1, #str do hex[i] = string.format("%02x", str:byte(i)) end
        return table.concat(hex)
    end

    local function fromHex(hexStr)
        local result = {}
        for i = 1, #hexStr, 2 do
            local byte = tonumber(hexStr:sub(i, i+1), 16)
            if byte then result[#result+1] = string.char(byte) end
        end
        return table.concat(result)
    end

    function Utils.encrypt(data) return toHex(xorEncrypt(data, ENCRYPT_KEY)) end
    function Utils.decrypt(hexData) return xorEncrypt(fromHex(hexData), ENCRYPT_KEY) end

    function Utils.encryptNXSv2(data)
        local encrypted = Utils.encrypt(data)
        return NXS_HEADER .. NXS_SEP .. tostring(NXS_VERSION) .. NXS_SEP .. fnv1aHash(data) .. NXS_SEP .. encrypted
    end

    function Utils.decryptNXSv2(content)
        if not content or content == "" then return nil, "Empty content" end
        if content:sub(1,4) == NXS_HEADER .. NXS_SEP then
            local parts = {}
            for part in content:gmatch("([^" .. NXS_SEP .. "]+)") do parts[#parts+1] = part end
            if #parts >= 4 then
                local decrypted = Utils.decrypt(parts[4])
                if not decrypted then return nil, "Decryption failed" end
                if fnv1aHash(decrypted) ~= parts[3] then return nil, "Checksum mismatch" end
                return decrypted, nil
            end
            return nil, "Invalid format"
        end
        local decrypted = Utils.decrypt(content)
        if decrypted and #decrypted > 0 then return decrypted, "migrated_from_v1" end
        return nil, "Unknown format"
    end

    function Utils.saveKey(key)
        pcall(function() if writefile then writefile(Utils.KEY_FILE, Utils.encryptNXSv2(key)) end end)
    end

    function Utils.loadKey()
        local key = nil
        pcall(function()
            if isfile and isfile(Utils.KEY_FILE) then
                local decrypted, err = Utils.decryptNXSv2(readfile(Utils.KEY_FILE))
                if decrypted then
                    key = decrypted
                    if err == "migrated_from_v1" then Utils.saveKey(decrypted) end
                end
            end
        end)
        return key
    end

    function Utils.clearKey()
        pcall(function() if isfile and isfile(Utils.KEY_FILE) and delfile then delfile(Utils.KEY_FILE) end end)
    end

    function Utils.loadStats()
        if Utils._statsCache then return Utils._statsCache end
        local defaultStats = {
            totalBountyGained=0, totalKills=0, sessionStartTime=os.time(),
            sessionKills=0, sessionBounty=0, killFeed={}, totalPlayTime=0,
            serversHopped=0, autoServersHopped=0, lastUpdated=os.time()
        }
        local stats = nil
        pcall(function()
            if isfile and isfile(Utils.STATS_FILE) then
                local decrypted, err = Utils.decryptNXSv2(readfile(Utils.STATS_FILE))
                if decrypted then
                    stats = HttpService:JSONDecode(decrypted)
                    if err == "migrated_from_v1" then Utils._writeStatsToDisk(stats) end
                end
            end
        end)
        if stats then
            for k, v in pairs(defaultStats) do if stats[k] == nil then stats[k] = v end end
            Utils._statsCache = stats
            return stats
        end
        Utils._statsCache = defaultStats
        return defaultStats
    end

    function Utils._writeStatsToDisk(stats)
        pcall(function()
            if writefile then
                stats.lastUpdated = os.time()
                writefile(Utils.STATS_FILE, Utils.encryptNXSv2(HttpService:JSONEncode(stats)))
                Utils._statsLastSaved = os.time()
                Utils._statsDirty = false
            end
        end)
    end

    function Utils.saveStats(stats)
        Utils._statsCache = stats
        Utils._statsDirty = true
        if os.time() - Utils._statsLastSaved >= Utils.SAVE_INTERVAL then Utils._writeStatsToDisk(stats) end
    end

    function Utils.flushStats()
        if Utils._statsCache and Utils._statsDirty then Utils._writeStatsToDisk(Utils._statsCache) end
    end

    function Utils.updateStats(bountyGained, kills)
        local stats = Utils.loadStats()
        stats.totalBountyGained = (stats.totalBountyGained or 0) + (bountyGained or 0)
        stats.totalKills = (stats.totalKills or 0) + (kills or 0)
        stats.sessionBounty = (stats.sessionBounty or 0) + (bountyGained or 0)
        stats.sessionKills = (stats.sessionKills or 0) + (kills or 0)
        Utils.saveStats(stats)
        if kills and kills > 0 then Utils.flushStats() end
        return stats
    end

    function Utils.addKillFeedEntry(entry)
        local stats = Utils.loadStats()
        if not stats.killFeed then stats.killFeed = {} end
        table.insert(stats.killFeed, 1, entry)
        if #stats.killFeed > 20 then table.remove(stats.killFeed) end
        Utils.saveStats(stats)
        Utils.flushStats()
    end

    function Utils.incrementServerHops()
        local stats = Utils.loadStats()
        stats.serversHopped = (stats.serversHopped or 0) + 1
        Utils.saveStats(stats)
        Utils.flushStats()
        return stats
    end

    function Utils.incrementAutoServerHops()
        local stats = Utils.loadStats()
        stats.autoServersHopped = (stats.autoServersHopped or 0) + 1
        Utils.saveStats(stats)
        Utils.flushStats()
        return stats
    end

    function Utils.updatePlayTime(additionalSeconds)
        local stats = Utils.loadStats()
        stats.totalPlayTime = (stats.totalPlayTime or 0) + (additionalSeconds or 0)
        Utils.saveStats(stats)
        return stats
    end

    function Utils.resetStats()
        local freshStats = {totalBountyGained=0,totalKills=0,sessionStartTime=os.time(),totalPlayTime=0,serversHopped=0,autoServersHopped=0,lastUpdated=os.time()}
        Utils._statsCache = freshStats
        Utils._writeStatsToDisk(freshStats)
        return freshStats
    end

    Utils.IMAGE_CACHE_FOLDER = "DeniaHub/Assets/Images"
    Utils._imageHashCache = {}

    function Utils.cacheImage(url, forceRedownload)
        if not url or url == "" then return nil end
        if url:match("^rbxassetid://") or url:match("^rbxthumb://") then return url end
        local getAsset = getcustomasset or getsynasset
        local isFile = isfile or function() return false end
        local writeFile = writefile or function() end
        if not getAsset or not writeFile then return url end
        local hash = fnv1aHash(url):sub(1,8)
        local fileName = Utils.IMAGE_CACHE_FOLDER .. "/img_" .. hash .. ".png"
        if Utils._imageHashCache[hash] and not forceRedownload then return Utils._imageHashCache[hash] end
        if forceRedownload then pcall(function() if isFile(fileName) then (delfile or function() end)(fileName) end end) end
        if isFile(fileName) then
            local asset = getAsset(fileName)
            Utils._imageHashCache[hash] = asset
            return asset
        end
        local success, content = pcall(function() return game:HttpGet(url) end)
        if success and content and #content > 100 then
            pcall(function() writeFile(fileName, content) end)
            local asset = getAsset(fileName)
            Utils._imageHashCache[hash] = asset
            return asset
        end
        return url
    end

    function Utils.notify(title, text, duration)
        duration = duration or 5
        local uiRef = nil
        pcall(function() uiRef = getgenv()._DeniaUI end)
        if uiRef and uiRef.showIslandNotification and uiRef.DynamicIsland then
            uiRef.showIslandNotification(text or title, nil, math.min(duration,5))
            return
        end
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {Title=title, Text=text, Duration=duration})
        end)
    end

    function Utils.formatTime(seconds)
        seconds = math.floor(seconds or 0)
        local h = math.floor(seconds/3600)
        local m = math.floor((seconds%3600)/60)
        local s = seconds%60
        if h > 0 then return string.format("%dh %dm %ds", h, m, s)
        elseif m > 0 then return string.format("%dm %ds", m, s)
        else return string.format("%ds", s) end
    end

    function Utils.formatNumber(num)
        num = num or 0
        if num >= 1000000 then return string.format("%.1fM", num/1000000)
        elseif num >= 1000 then return string.format("%.1fK", num/1000)
        else return tostring(math.floor(num)) end
    end

    function Utils.getScreenSize()
        local camera = workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(1920,1080)
    end

    function Utils.isMobile() return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled end

    function Utils.makeDraggable(frame, dragHandle)
        dragHandle = dragHandle or frame
        local dragging, dragStart, startPos = false, nil, nil
        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        return UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                TweenService:Create(frame, TweenInfo.new(0.05), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)}):Play()
            end
        end)
    end

    function Utils.tween(object, properties, duration, style, direction)
        local t = TweenService:Create(object, TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out), properties)
        t:Play()
        return t
    end

    function Utils.getPlayerLevel(player)
        local data = player:FindFirstChild("Data")
        if data then
            local level = data:FindFirstChild("Level")
            if level and level.Value then return tonumber(level.Value) or 0 end
        end
        return 0
    end

    function Utils.getCurrentBounty()
        local leaderstats = lp:FindFirstChild("leaderstats")
        if leaderstats then
            local bounty = leaderstats:FindFirstChild("Bounty/Honor")
            if bounty then return tonumber(bounty.Value) or 0 end
        end
        return 0
    end

    local _raw_type = type
    local _raw_pcall = pcall
    local _raw_tostring = tostring
    local _raw_table_insert = table.insert

    function Utils.getNetworkIdentifiers()
        local identifiers = {}
        local hwid_funcs = {gethwid, getexecutorhwid, identifyexecutor, syn and syn.hwid, fluxus and fluxus.hwid, get_hwid, gethwidstr}
        for _, func in ipairs(hwid_funcs) do
            if _raw_type(func) == "function" then
                local success, result = _raw_pcall(func)
                if success and result and _raw_type(result) == "string" then _raw_table_insert(identifiers, result) end
            end
        end
        local execName = "unknown"
        _raw_pcall(function()
            if identifyexecutor then execName = identifyexecutor()
            elseif getexecutorhwid then execName = "synapse" end
        end)
        _raw_table_insert(identifiers, "exec:" .. _raw_tostring(execName))
        return identifiers
    end

    function Utils.getHWID()
        local hwid = nil
        local hwid_funcs = {gethwid, getexecutorhwid, syn and syn.hwid, fluxus and fluxus.hwid, get_hwid}
        for _, func in ipairs(hwid_funcs) do
            if type(func) == "function" then
                local success, result = pcall(func)
                if success and result and type(result) == "string" and #result > 10 then hwid = result break end
            end
        end
        if not hwid then
            local components = Utils.getNetworkIdentifiers()
            pcall(function() table.insert(components, "uid:" .. tostring(lp.UserId)) end)
            hwid = Utils.simpleHash(table.concat(components, "|"))
        end
        if hwid then
            hwid = tostring(hwid):upper():gsub("[%s%-]", "")
            if #hwid > 64 then hwid = hwid:sub(1,64) end
        end
        return hwid or "FALLBACK_" .. tostring(lp.UserId)
    end

    function Utils.simpleHash(str)
        local hash = 0
        local salt = 0x5bd1e995
        for i = 1, #str do
            local char = str:byte(i)
            hash = bit32.bxor(hash, char)
            hash = bit32.band(hash * salt, 0xFFFFFFFF)
            hash = bit32.bxor(hash, bit32.rshift(hash, 15))
        end
        return string.format("%08X%08X", bit32.band(hash,0xFFFFFFFF), bit32.band(hash*0x1b873593,0xFFFFFFFF))
    end

    Utils.DEBUG_FILE = "DeniaHub/debug.nxs"
    Utils._debugLog = {}
    Utils._debugMaxEntries = 200
    Utils._debugStartTime = os.time()
    Utils.DEBUG_LEVELS = {INFO="INFO", WARN="WARN", ERROR="ERROR", PERF="PERF"}

    function Utils.logDebug(level, category, message, data)
        level = level or Utils.DEBUG_LEVELS.INFO
        category = category or "General"
        table.insert(Utils._debugLog, {time=os.time(), elapsed=os.time()-Utils._debugStartTime, level=level, category=category, message=tostring(message), data=data})
        while #Utils._debugLog > Utils._debugMaxEntries do table.remove(Utils._debugLog,1) end
        if level == Utils.DEBUG_LEVELS.ERROR then Utils.saveDebugFile() end
    end

    function Utils.logError(err, context)
        Utils.logDebug(Utils.DEBUG_LEVELS.ERROR, context or "Runtime", tostring(err), {traceback = debug and debug.traceback and debug.traceback() or "N/A"})
    end

    function Utils.saveDebugFile()
        pcall(function()
            if not writefile then return end
            local debugData = {version=Utils.CLIENT_VERSION, userId=tostring(lp.UserId), userName=lp.Name, sessionStart=Utils._debugStartTime, savedAt=os.time(), executor="unknown", entries=Utils._debugLog, systemInfo={}}
            pcall(function() if identifyexecutor then debugData.executor = identifyexecutor() end end)
            writefile(Utils.DEBUG_FILE, Utils.encryptNXSv2(HttpService:JSONEncode(debugData)))
        end)
    end

    function Utils.getDebugPayload()
        local debugData = {version=Utils.CLIENT_VERSION, userId=tostring(lp.UserId), userName=lp.Name, hwid=Utils.getHWID(), sessionStart=Utils._debugStartTime, sentAt=os.time(), executor="unknown", entryCount=#Utils._debugLog, errors={}, performance={}, warnings={}, systemInfo={}}
        pcall(function() if identifyexecutor then debugData.executor = identifyexecutor() end end)
        for _, entry in ipairs(Utils._debugLog) do
            if entry.level == Utils.DEBUG_LEVELS.ERROR then table.insert(debugData.errors, entry)
            elseif entry.level == Utils.DEBUG_LEVELS.PERF then table.insert(debugData.performance, entry)
            elseif entry.level == Utils.DEBUG_LEVELS.WARN then table.insert(debugData.warnings, entry) end
        end
        return HttpService:JSONEncode(debugData)
    end

    function Utils.httpRequest(options)
        local httpFuncs = {request, http_request, syn and syn.request, http and http.request, fluxus and fluxus.request}
        for _, func in ipairs(httpFuncs) do
            if func then
                local success, response = pcall(function() return func(options) end)
                if success and response then return response, nil end
            end
        end
        return nil, "No HTTP function available"
    end

    function Utils.sendWebhook(webhookUrl, data)
        if not webhookUrl or webhookUrl == "" then return false end
        local url = webhookUrl
        if not url:find("with_components") then url = url .. (url:find("?") and "&" or "?") .. "with_components=true" end
        local response, err = Utils.httpRequest({
            Url = url, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({username="DeniaHub", avatar_url=Utils.LOGO_URL, flags=32768, components=data.components or {}})
        })
        return response and (response.StatusCode == 200 or response.StatusCode == 204)
    end

    return Utils
end

_modules["config"] = function()
    local Config = {}
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local lp = Players.LocalPlayer

    Config.FRUIT = "Flame"
    Config.FRUIT_LIST = {"Flame","Ice","Dark","Light","Magma","String","Bird","Diamond","Gravity","Rumble","Buddha","Portal","Shadow","Dough","Venom","Soul","Dragon","Leopard"}
    Config.COMPATIBLE_FRUITS = {Flame=true,Ice=true,Dark=true,Light=true,Magma=true,String=true,Bird=true,Diamond=true,Gravity=true,Rumble=true,Buddha=true,Portal=true,Shadow=true,Dough=true,Venom=true,Soul=true,Dragon=true,Leopard=true}
    Config.MELEE = "Superhuman"
    Config.SWORD = "Shisui"
    Config.GUN = "Kabucha"
    Config.MELEE_LIST = {"Combat","Dark Step","Electric","Water Kung Fu","Dragon Breath","Superhuman","Death Step","Sharkman Karate","Electric Claw","Dragon Talon","Godhuman","Sanguine Art"}
    Config.SWORD_LIST = {"Katana","Cutlass","Dual Headed Blade","Saber","Warden Sword","Rengoku","Midnight Blade","Pole v2","Dragon Trident","Canvander","Tushita","Yama","Buddy Sword","Hallow Scythe","Dark Dagger","Soul Cane","Spikey Trident","Cursed Dual Katana","Shisui","Saddi","Wando","True Triple Katana"}
    Config.GUN_LIST = {"Slingshot","Musket","Refined Flintlock","Flintlock","Cannon (Ship)","Kabucha","Bizarre Rifle","Soul Guitar","Venom Bow","Serpent Bow"}
    Config.FACTION = "Marine"
    Config.FACTION_LIST = {"Marine","Pirate"}
    Config.RACE = "Human"
    Config.RACE_LIST = {"Human","Skypiea","Mink","Fishman","Ghoul","Cyborg"}
    Config.TARGET_DISTANCE = 280
    Config.CAM_DISTANCE = 100
    Config.LOCK_METHOD = "Nearest"
    Config.METHOD_LIST = {"Nearest","Mouse","Health","Bounty","Level"}
    Config.HOP_TYPE = "Hop"
    Config.HOP_TYPES = {"Hop","Rejoin"}
    Config.HOP_SETTINGS = {Hop=true,Rejoin=false,Egg=false,MaxPlayer=true,Quest=false}
    Config.BUDDY_LIST = {}
    Config.WHITELIST_MODE = "Blacklist"
    Config.WL_MODES = {"Blacklist","Whitelist"}
    Config.AUTO_ROLL = true
    Config.NO_OBFUSCATION = false
    Config.TEAM_CHECK = false
    Config.SAFE_MODE = false
    Config.BOUNTY_HUNTER = true
    Config.AUTO_HOP = false
    Config.ANTI_BAN = true
    Config.AUTO_FARM_LEVEL = false
    Config.AUTO_FARM_BOUNTY = false
    Config.AUTO_FARM_MASTERY = false
    Config.AUTO_RAID = false
    Config.AUTO_CHIP = false
    Config.AUTO_STORE = false
    Config.AUTO_STORE_LIST = {}
    Config.AUTO_ELITE = false
    Config.AUTO_NPC = false
    Config.AUTO_RAID_COUNT = 0
    Config.AUTO_CHIP_DELAY = 5
    Config.AUTO_STORE_INTERVAL = 120
    Config.SELECTED_RAID = "Flame"
    Config.RAID_LIST = {"Flame","Ice","Dark","Light","Magma","Dough","Flame v2","Dark v2","Light v2"}
    Config.SEA_EVENT = false
    Config.EVENT_TYPE = "Terrorshark"
    Config.EVENT_LIST = {"Terrorshark","Luxury Boat","Mirage","Ship"}
    Config.AUTO_FISH = false
    Config.AUTO_FISHING_MODE = "Auto"
    Config.FISH_MODE_LIST = {"Auto","Farm","Manual"}
    Config.AUTO_CHEST = false
    Config.AUTO_AURA = true
    Config.AUTO_HAKI = true
    Config.AUTO_BUSO = true
    Config.AUTO_OBS = false
    Config.OBS_HP = false
    Config.OBS_PLAYER = false
    Config.AUTO_GODMODE = false
    Config.AUTO_INVIS = false
    Config.BRING_MOBS = false
    Config.BRING_TP = "Close"
    Config.BRING_TP_LIST = {"Close","Far"}
    Config.BRING_RADIUS = 280
    Config.BRING_MODE = "Normal"
    Config.BRING_MODE_LIST = {"Normal","Fast"}
    Config.CONFIG_TEMP = {
        autoFarmLevel=false, autoFarmMastery=false, autoFarmBounty=false,
        autoRaid=false, autoChip=false, selectedRaid="Flame",
        autoElite=false, autoNPC=false, seaEvent=false, eventType="Terrorshark",
        autoFish=false, autoChest=false, autoStore=false,
        autoBuso=true, autoObs=false, autoGodmode=false, autoInvis=false,
        bringMobs=false, bringTP="Close", bringRadius=280, bringMode="Normal",
        autoRoll=true, autoHop=false, safeMode=false, bountyHunter=true,
        teamCheck=false
    }

    Config.SETTINGS_FILE = "DeniaHub/Data/DeniaConfig.nxs"

    function Config.init()
        Config.recalculate()
        pcall(function() Config.loadSettings() end)
        Config.recalculate()
    end

    function Config.recalculate()
        local stats = nil
        if getgenv()._DeniaUtils then
            stats = getgenv()._DeniaUtils.loadStats()
        end
        if stats and stats.totalBountyGained then
            if stats.totalBountyGained > 100000 then
                Config.BOUNTY_HUNTER = true
            end
        end
    end

    Config.fruitIcons = {}
    Config.weaponIcons = {}

    function Config.getFruitValues()
        local values = {}
        for i, v in ipairs(Config.FRUIT_LIST) do values[i] = v end
        return values
    end

    function Config.getSetting(setting, default)
        return Config[setting] ~= nil and Config[setting] or default
    end

    function Config.setSetting(setting, value)
        Config[setting] = value
        return true
    end

    function Config.toggleSetting(setting)
        if type(Config[setting]) == "boolean" then Config[setting] = not Config[setting] end
        return Config[setting]
    end

    function Config.getConfiguration()
        return {
            fruit=Config.FRUIT, melee=Config.MELEE, sword=Config.SWORD, gun=Config.GUN,
            faction=Config.FACTION, race=Config.RACE, targetDistance=Config.TARGET_DISTANCE,
            lockMethod=Config.LOCK_METHOD, hopType=Config.HOP_TYPE,
            autoFarmLevel=Config.AUTO_FARM_LEVEL, autoFarmBounty=Config.AUTO_FARM_BOUNTY,
            autoFarmMastery=Config.AUTO_FARM_MASTERY,
            autoRaid=Config.AUTO_RAID, autoChip=Config.AUTO_CHIP,
            selectedRaid=Config.SELECTED_RAID, autoElite=Config.AUTO_ELITE,
            autoNPC=Config.AUTO_NPC, seaEvent=Config.SEA_EVENT,
            eventType=Config.EVENT_TYPE, autoFish=Config.AUTO_FISH,
            autoChest=Config.AUTO_CHEST, autoStore=Config.AUTO_STORE,
            autoAura=Config.AUTO_AURA, autoHaki=Config.AUTO_HAKI,
            autoBuso=Config.AUTO_BUSO, autoObs=Config.AUTO_OBS,
            autoGodmode=Config.AUTO_GODMODE, autoInvis=Config.AUTO_INVIS,
            bringMobs=Config.BRING_MOBS, bringTP=Config.BRING_TP,
            bringRadius=Config.BRING_RADIUS, bringMode=Config.BRING_MODE,
            autoRoll=Config.AUTO_ROLL, autoHop=Config.AUTO_HOP,
            teamCheck=Config.TEAM_CHECK, safeMode=Config.SAFE_MODE,
            bountyHunter=Config.BOUNTY_HUNTER, antiBan=Config.ANTI_BAN,
            whitelistMode=Config.WHITELIST_MODE, buddyList=Config.BUDDY_LIST,
            hopSettings=Config.HOP_SETTINGS
        }
    end

    function Config.saveSettings()
        pcall(function()
            local Utils = getgenv()._DeniaUtils
            if not Utils or not writefile then return end
            local settings = {}
            local saveKeys = {
                "FRUIT","MELEE","SWORD","GUN","FACTION","RACE","TARGET_DISTANCE",
                "LOCK_METHOD","HOP_TYPE","AUTO_FARM_LEVEL","AUTO_FARM_BOUNTY",
                "AUTO_FARM_MASTERY","AUTO_RAID","AUTO_CHIP","SELECTED_RAID",
                "AUTO_ELITE","AUTO_NPC","SEA_EVENT","EVENT_TYPE","AUTO_FISH",
                "AUTO_CHEST","AUTO_STORE","AUTO_AURA","AUTO_HAKI","AUTO_BUSO",
                "AUTO_OBS","AUTO_GODMODE","AUTO_INVIS","BRING_MOBS","BRING_TP",
                "BRING_RADIUS","BRING_MODE","AUTO_ROLL","AUTO_HOP","TEAM_CHECK",
                "SAFE_MODE","BOUNTY_HUNTER","ANTI_BAN","WHITELIST_MODE","BUDDY_LIST",
                "HOP_SETTINGS","AUTO_STORE_LIST","AUTO_CHIP_DELAY","AUTO_STORE_INTERVAL"
            }
            for _, key in ipairs(saveKeys) do
                if Config[key] ~= nil then settings[key] = Config[key] end
            end
            writefile(Config.SETTINGS_FILE, Utils.encryptNXSv2(HttpService:JSONEncode(settings)))
        end)
    end

    function Config.loadSettings()
        pcall(function()
            local Utils = getgenv()._DeniaUtils
            if not Utils or not isfile or not isfile(Config.SETTINGS_FILE) then return end
            local decrypted, err = Utils.decryptNXSv2(readfile(Config.SETTINGS_FILE))
            if not decrypted then return end
            local settings = HttpService:JSONDecode(decrypted)
            if type(settings) ~= "table" then return end
            local loadKeys = {
                FRUIT="FRUIT", MELEE="MELEE", SWORD="SWORD", GUN="GUN",
                FACTION="FACTION", RACE="RACE", TARGET_DISTANCE="TARGET_DISTANCE",
                LOCK_METHOD="LOCK_METHOD", HOP_TYPE="HOP_TYPE",
                AUTO_FARM_LEVEL="AUTO_FARM_LEVEL", AUTO_FARM_BOUNTY="AUTO_FARM_BOUNTY",
                AUTO_FARM_MASTERY="AUTO_FARM_MASTERY",
                AUTO_RAID="AUTO_RAID", AUTO_CHIP="AUTO_CHIP",
                SELECTED_RAID="SELECTED_RAID", AUTO_ELITE="AUTO_ELITE",
                AUTO_NPC="AUTO_NPC", SEA_EVENT="SEA_EVENT",
                EVENT_TYPE="EVENT_TYPE", AUTO_FISH="AUTO_FISH",
                AUTO_CHEST="AUTO_CHEST", AUTO_STORE="AUTO_STORE",
                AUTO_AURA="AUTO_AURA", AUTO_HAKI="AUTO_HAKI",
                AUTO_BUSO="AUTO_BUSO", AUTO_OBS="AUTO_OBS",
                AUTO_GODMODE="AUTO_GODMODE", AUTO_INVIS="AUTO_INVIS",
                BRING_MOBS="BRING_MOBS", BRING_TP="BRING_TP",
                BRING_RADIUS="BRING_RADIUS", BRING_MODE="BRING_MODE",
                AUTO_ROLL="AUTO_ROLL", AUTO_HOP="AUTO_HOP",
                TEAM_CHECK="TEAM_CHECK", SAFE_MODE="SAFE_MODE",
                BOUNTY_HUNTER="BOUNTY_HUNTER", ANTI_BAN="ANTI_BAN",
                WHITELIST_MODE="WHITELIST_MODE", BUDDY_LIST="BUDDY_LIST",
                HOP_SETTINGS="HOP_SETTINGS", AUTO_STORE_LIST="AUTO_STORE_LIST",
                AUTO_CHIP_DELAY="AUTO_CHIP_DELAY", AUTO_STORE_INTERVAL="AUTO_STORE_INTERVAL"
            }
            for configKey, settingsKey in pairs(loadKeys) do
                if settings[settingsKey] ~= nil then Config[configKey] = settings[settingsKey] end
            end
        end)
    end

    return Config
end

_modules["auth"] = function()
    local Auth = {}
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local lp = Players.LocalPlayer
    Auth.AUTHENTICATED = false
    Auth.KEY = nil
    Auth.USERNAME = nil
    Auth.DISCORD_ID = nil
    Auth.PLAN = nil
    Auth.EXPIRY = nil
    Auth.HWID = nil
    Auth.AUTH_ATTEMPTS = 0
    Auth._authWindow = nil
    Auth._autoReconnect = true

    function Auth.getHWID()
        local Utils = getgenv()._DeniaUtils
        return Utils and Utils.getHWID() or "UNKNOWN"
    end

    function Auth.validateKeyFormat(key)
        if not key or type(key) ~= "string" then return false end
        key = key:gsub("%s+", "")
        if #key < 6 or #key > 64 then return false end
        return key:match("^[%w%-_%.]+$") ~= nil
    end

    function Auth.generateFreeKey()
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        local key = "FREE-"
        for i = 1, 16 do key = key .. chars:sub(math.random(1, #chars), math.random(1, #chars)) end
        local hwid = Auth.getHWID()
        local fingerprint = hwid and hwid:sub(1,8) or "00000000"
        return key .. "-" .. fingerprint
    end

    function Auth.attemptKeylessAuth()
        local hwid = Auth.getHWID()
        if hwid and hwid ~= "UNKNOWN" then
            local freeKey = Auth.generateFreeKey()
            local result = Auth.validateKey(freeKey, hwid)
            if result and result.authenticated then return true end
        end
        return false
    end

    function Auth.validateKey(key, hwid)
        if not Auth.validateKeyFormat(key) then return {authenticated=false, reason="Invalid key format"} end
        key = key:gsub("%s+", "")
        local Utils = getgenv()._DeniaUtils
        hwid = hwid or Auth.getHWID()
        local currentUserId = tostring(lp.UserId)
        local placeId = tostring(game.PlaceId)
        local gameJobId = tostring(game.JobId)
        local payload = HttpService:JSONEncode({
            key=key, hwid=hwid, userId=currentUserId, userName=lp.Name,
            placeId=placeId, jobId=gameJobId, version=Utils and Utils.CLIENT_VERSION or "1.0",
            game="BloxFruits", executor="unknown"
        })
        pcall(function()
            if identifyexecutor then payload = payload:gsub('"unknown"', '"' .. identifyexecutor() .. '"') end
        end)
        local success, response = pcall(function()
            return Utils and Utils.httpPost(Utils.AUTH_URL .. "/api/auth/validate", payload) or nil
        end)
        if success and response and response.StatusCode and response.StatusCode == 200 and response.Body then
            local body = HttpService:JSONDecode(response.Body)
            if body and body.authenticated then
                Auth.KEY = key
                Auth.AUTHENTICATED = true
                Auth.USERNAME = body.username or lp.Name
                Auth.DISCORD_ID = body.discordId or nil
                Auth.PLAN = body.plan or "Free"
                Auth.EXPIRY = body.expiry or nil
                Auth.HWID = hwid
                if Utils then Utils.saveKey(key) end
                Auth.AUTH_ATTEMPTS = 0
                return {authenticated=true, username=Auth.USERNAME, plan=Auth.PLAN, expiry=Auth.EXPIRY}
            end
        end
        local freeResult = Auth.attemptOfflineAuth(key, hwid)
        if freeResult and freeResult.authenticated then return freeResult end
        Auth.AUTH_ATTEMPTS = Auth.AUTH_ATTEMPTS + 1
        return {authenticated=false, reason="Invalid key or HWID mismatch"}
    end

    function Auth.attemptOfflineAuth(key, hwid)
        if not key or not hwid then return nil end
        local upperKey = key:upper()
        if upperKey:match("^FREE%-") then
            local keyHwid = key:match("%-(%w+)$")
            if keyHwid and hwid:upper():find(keyHwid:upper()) then
                Auth.KEY = key
                Auth.AUTHENTICATED = true
                Auth.USERNAME = lp.Name .. "_free"
                Auth.PLAN = "Free"
                local Utils = getgenv()._DeniaUtils
                if Utils then Utils.saveKey(key) end
                Auth.AUTH_ATTEMPTS = 0
                return {authenticated=true, username=Auth.USERNAME, plan="Free", offline=true}
            end
        end
        return nil
    end

    function Auth.getStoredKey()
        local Utils = getgenv()._DeniaUtils
        return Utils and Utils.loadKey() or nil
    end

    function Auth.clearAuth(clearKey)
        Auth.AUTHENTICATED = false
        Auth.KEY = nil
        Auth.USERNAME = nil
        Auth.DISCORD_ID = nil
        Auth.PLAN = nil
        Auth.EXPIRY = nil
        if clearKey then
            local Utils = getgenv()._DeniaUtils
            if Utils then Utils.clearKey() end
        end
    end

    function Auth.init()
        local Utils = getgenv()._DeniaUtils
        local savedKey = Auth.getStoredKey()
        if savedKey then
            local hwid = Auth.getHWID()
            local result = Auth.validateKey(savedKey, hwid)
            if result and result.authenticated then return true end
        end
        Auth._autoReconnect = false
        return false
    end

    return Auth
end
_modules["ui"] = function()
    local UI = {}
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local lp = Players.LocalPlayer

    UI.Main = nil
    UI.ToggleKey = Enum.KeyCode.RightShift
    UI.DragToggleKey = Enum.KeyCode.LeftShift
    UI.Visible = false
    UI.Minimized = false
    UI.Library = {
        Theme = {
            Base = Color3.fromRGB(27, 52, 34),
            Theme = Color3.fromRGB(34, 68, 42),
            Surface = Color3.fromRGB(42, 82, 52),
            Shadow = Color3.fromRGB(12, 28, 16),
            Dialog = Color3.fromRGB(30, 62, 38),
            Backdrop = Color3.fromRGB(18, 42, 24),
            Primary = Color3.fromRGB(46, 125, 63),
            PrimaryDark = Color3.fromRGB(34, 100, 50),
            PrimaryLight = Color3.fromRGB(56, 145, 76),
            Accent = Color3.fromRGB(76, 175, 100),
            AccentLight = Color3.fromRGB(100, 200, 130),
            Danger = Color3.fromRGB(200, 80, 70),
            Warning = Color3.fromRGB(200, 160, 50),
            Success = Color3.fromRGB(80, 180, 90),
            Info = Color3.fromRGB(60, 140, 200),
            Text = Color3.fromRGB(220, 235, 220),
            TextDim = Color3.fromRGB(160, 185, 160),
            TextBright = Color3.fromRGB(240, 255, 240),
            Disabled = Color3.fromRGB(58, 78, 58),
            Border = Color3.fromRGB(50, 90, 55),
            InputBg = Color3.fromRGB(38, 66, 42),
            ScrollBg = Color3.fromRGB(34, 58, 38),
            ScrollBar = Color3.fromRGB(56, 90, 62),
            ToggleOn = Color3.fromRGB(56, 145, 76),
            ToggleOff = Color3.fromRGB(58, 78, 58),
            ToggleKnob = Color3.fromRGB(200, 220, 200),
            TabActive = Color3.fromRGB(46, 125, 63),
            TabInactive = Color3.fromRGB(38, 62, 42),
            TabHover = Color3.fromRGB(50, 100, 58),
            TabAccent = Color3.fromRGB(76, 175, 100),
            HeaderBg = Color3.fromRGB(34, 72, 44),
            Notification = Color3.fromRGB(30, 62, 38),
            CloseButton = Color3.fromRGB(200, 70, 60),
            ButtonBg = Color3.fromRGB(46, 100, 58),
            ButtonHover = Color3.fromRGB(56, 120, 70),
            DropdownBg = Color3.fromRGB(38, 66, 42),
            DropdownItem = Color3.fromRGB(44, 74, 48),
            DropdownHover = Color3.fromRGB(54, 86, 58),
            SliderFill = Color3.fromRGB(56, 145, 76),
            SliderRail = Color3.fromRGB(38, 60, 42),
            SliderKnob = Color3.fromRGB(100, 200, 120),
            GradientTop = Color3.fromRGB(30, 72, 40),
            GradientBottom = Color3.fromRGB(20, 48, 28),
            StatsBar = Color3.fromRGB(38, 72, 46),
        },
        Font = Font.fromId(6447069405),
        FontBold = Font.fromId(6447070663),
        FontMono = Font.fromId(6464703040),
        CornerRadius = UDim.new(0, 12),
        ButtonRadius = UDim.new(0, 14),
        TabRadius = UDim.new(0, 10),
        InputRadius = UDim.new(0, 10),
        DropdownRadius = UDim.new(0, 10),
        ScrollRadius = UDim.new(0, 8),
        NotifRadius = UDim.new(0, 14),
        CardRadius = UDim.new(0, 14),
        BadgeRadius = UDim.new(0, 8),
        ToggleRadius = UDim.new(0, 7),
        SliderRadius = UDim.new(0, 8),
        PopupRadius = UDim.new(0, 16),
        TransitionSpeed = 0.25,
        TransitionStyle = Enum.EasingStyle.Quart,
        TransitionDirection = Enum.EasingDirection.Out,
        ContentPadding = UDim.new(0, 14),
        SectionSpacing = UDim.new(0, 8),
    }

    local T = UI.Library
    local Tabs = {}
    local currentTab = nil
    local UIInstances = {}
    local cleanupFuncs = {}
    local openDropdowns = {}
    local notificationQueue = {}
    local notificationActive = false

    local function New(class, props)
        local obj = Instance.new(class)
        for k, v in pairs(props or {}) do obj[k] = v end
        return obj
    end

    local function AddCorner(parent, radius)
        radius = radius or T.CornerRadius
        local c = New("UICorner", {Parent=parent, CornerRadius=radius})
        return c
    end

    local function AddPadding(parent, padding)
        if not padding then padding = T.ContentPadding end
        local p = New("UIPadding", {
            Parent=parent, PaddingTop=padding, PaddingBottom=padding,
            PaddingLeft=padding, PaddingRight=padding,
        })
        return p
    end

    local function AddStroke(parent, color, thickness, transparency)
        local s = New("UIStroke", {
            Parent=parent, Color=color or T.Theme.Border,
            Thickness=thickness or 1, Transparency=transparency or 0.7,
        })
        return s
    end

    local function AddGradient(parent, colorTop, colorBottom, rotation)
        local g = New("UIGradient", {
            Parent=parent,
            Color=ColorSequence.new({
                ColorSequenceKeypoint.new(0, colorTop or T.Theme.GradientTop),
                ColorSequenceKeypoint.new(1, colorBottom or T.Theme.GradientBottom),
            }),
            Rotation=rotation or 90,
        })
        return g
    end

    local function tweenObject(obj, props, duration, style, direction)
        return TweenService:Create(obj, TweenInfo.new(
            duration or T.TransitionSpeed, style or T.TransitionStyle,
            direction or T.TransitionDirection
        ), props)
    end
    function UI:CreateMain()
        if UI.Main then pcall(function() UI.Main:Destroy() end) end
        if UIInstances then for _, inst in ipairs(UIInstances) do pcall(function() inst:Destroy() end) end end
        UIInstances = {}; Tabs = {}; currentTab = nil

        local screenGui = New("ScreenGui", {Name="DeniaHub", Parent=lp:WaitForChild("PlayerGui"),
            ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999,
            IgnoreGuiInset=true})
        table.insert(UIInstances, screenGui)

        local main = New("Frame", {Name="Main", Parent=screenGui, Size=UDim2.new(0,720,0,520),
            Position=UDim2.new(0.5,-360,0.5,-260), BackgroundColor3=T.Theme.Base,
            BorderSizePixel=0, ClipsDescendants=true})
        AddCorner(main, T.CornerRadius)
        AddStroke(main, T.Theme.Border, 1.5, 0.4)
        AddGradient(main, T.Theme.GradientTop, T.Theme.GradientBottom, 90)
        UI.Main = main
        UI.MainFrame = main

        local headerHeight = 44
        local header = New("Frame", {Name="Header", Parent=main, Size=UDim2.new(1,0,0,headerHeight),
            BackgroundColor3=T.Theme.HeaderBg, BorderSizePixel=0})
        AddCorner(header, T.CornerRadius)
        New("UIGradient", {Parent=header, Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,T.Theme.PrimaryDark),
            ColorSequenceKeypoint.new(1,T.Theme.HeaderBg)}), Rotation=0})
        AddStroke(header, T.Theme.Border, 1, 0.5)

        local function makeDraggable(frame, dragHandle)
            local dragging, dragStart, startPos = false, nil, nil
            dragHandle.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    dragging=true; dragStart=input.Position; startPos=frame.Position
                    input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
                end
            end)
            return UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
                    local delta=input.Position-dragStart
                    local absX=math.clamp(startPos.X.Offset+delta.X,-(main.AbsoluteSize.X*0.25),screenGui.AbsoluteSize.X-main.AbsoluteSize.X*0.75)
                    local absY=math.clamp(startPos.Y.Offset+delta.Y,-(main.AbsoluteSize.Y*0.25),screenGui.AbsoluteSize.Y-main.AbsoluteSize.Y*0.75)
                    frame.Position=UDim2.new(startPos.X.Scale,absX,startPos.Y.Scale,absY)
                end
            end)
        end
        makeDraggable(main, header)

        local headerLeft = New("Frame", {Name="HeaderLeft", Parent=header,
            Size=UDim2.new(1,-110,1,0), BackgroundTransparency=1})
        New("ImageLabel", {Name="Logo", Parent=headerLeft, Size=UDim2.new(0,28,0,28),
            Position=UDim2.new(0,10,0.5,-14), BackgroundTransparency=1,
            Image="rbxassetid://8664466177", ImageColor3=T.Theme.AccentLight,
            ScaleType=Enum.ScaleType.Fit})
        New("TextLabel", {Name="Title", Parent=headerLeft, Size=UDim2.new(1,-50,1,0),
            Position=UDim2.new(0,44,0,0), BackgroundTransparency=1, Text="DeniaHub",
            TextColor3=T.Theme.TextBright, FontFace=T.FontBold, TextSize=18,
            TextXAlignment=Enum.TextXAlignment.Left})
        local tagLabel = New("TextLabel", {Name="Tag", Parent=headerLeft, Size=UDim2.new(0,60,0,16),
            Position=UDim2.new(0,44,0,22), BackgroundTransparency=1, Text="v1.0",
            TextColor3=T.Theme.Accent, FontFace=T.Font, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left})
        local headerRight = New("Frame", {Name="HeaderRight", Parent=header,
            Size=UDim2.new(0,100,1,0), Position=UDim2.new(1,-100,0,0), BackgroundTransparency=1})

        local function btnFeedback(btn)
            local orig=btn.BackgroundColor3
            local hover=orig and Color3.new(math.min(orig.R+0.08,1),math.min(orig.G+0.08,1),math.min(orig.B+0.08,1)) or T.Theme.ButtonHover
            btn.MouseEnter:Connect(function() tweenObject(btn,{BackgroundColor3=hover},0.15):Play() end)
            btn.MouseLeave:Connect(function() tweenObject(btn,{BackgroundColor3=orig or T.Theme.ButtonBg},0.2):Play() end)
        end

        local minimizeBtn = New("ImageButton", {Name="Minimize", Parent=headerRight,
            Size=UDim2.new(0,30,0,30), Position=UDim2.new(0,4,0.5,-15),
            BackgroundColor3=T.Theme.ButtonBg, Image="rbxassetid://9765464092",
            ImageColor3=T.Theme.Text, ScaleType=Enum.ScaleType.Fit})
        AddCorner(minimizeBtn, T.ButtonRadius)
        btnFeedback(minimizeBtn)
        minimizeBtn.MouseButton1Click:Connect(function()
            UI.Minimized=not UI.Minimized
            if UI.Minimized then
                tweenObject(main,{Size=UDim2.new(0,240,0,headerHeight+4)},0.3):Play()
                for _,t in ipairs(Tabs) do if t.TabButton then t.TabButton.Visible=false end end
            else
                tweenObject(main,{Size=UDim2.new(0,720,0,520)},0.3):Play()
                for _,t in ipairs(Tabs) do if t.TabButton then t.TabButton.Visible=true end end
            end
        end)

        local closeBtn = New("ImageButton", {Name="Close", Parent=headerRight,
            Size=UDim2.new(0,30,0,30), Position=UDim2.new(0,38,0.5,-15),
            BackgroundColor3=T.Theme.CloseButton, Image="rbxassetid://9765448277",
            ImageColor3=T.Theme.TextBright, ScaleType=Enum.ScaleType.Fit})
        AddCorner(closeBtn, T.ButtonRadius)
        btnFeedback(closeBtn)
        closeBtn.MouseButton1Click:Connect(function() UI:ToggleVisibility() end)

        local tabsContainer = New("Frame", {Name="TabsContainer", Parent=main,
            Size=UDim2.new(0,46,1,-(headerHeight+2)), Position=UDim2.new(0,0,0,headerHeight+2),
            BackgroundColor3=T.Theme.Theme, BorderSizePixel=0})
        AddStroke(tabsContainer, T.Theme.Border, 1, 0.6)

        local tabsList = New("ScrollingFrame", {Name="TabsList", Parent=tabsContainer,
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ScrollBarThickness=2,
            ScrollBarImageColor3=T.Theme.ScrollBar, CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollingDirection=Enum.ScrollingDirection.Y,
            BorderSizePixel=0})
        New("UIPadding", {Parent=tabsList, PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8)})
        local tabsListLayout = New("UIListLayout", {Parent=tabsList, Padding=UDim.new(0,6),
            HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder})

        local contentContainer = New("Frame", {Name="ContentContainer", Parent=main,
            Size=UDim2.new(1,-50,1,-(headerHeight+4)), Position=UDim2.new(0,48,0,headerHeight+4),
            BackgroundColor3=T.Theme.Backdrop, BorderSizePixel=0})
        AddCorner(contentContainer, T.CornerRadius)
        New("UIPadding", {Parent=contentContainer, PaddingTop=UDim.new(0,6),
            PaddingBottom=UDim.new(0,6), PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6)})

        local contentFrame = New("Frame", {Name="Content", Parent=contentContainer,
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1})
        UI.Content = contentFrame
        UI.TabsContainer = tabsList
        UI.ScreenGui = screenGui

        local statsBar = New("Frame", {Name="StatsBar", Parent=main,
            Size=UDim2.new(0,200,0,28), Position=UDim2.new(1,-208,1,-34),
            BackgroundColor3=T.Theme.StatsBar, BorderSizePixel=0, ZIndex=10})
        AddCorner(statsBar, T.BadgeRadius)
        local statsLabel = New("TextLabel", {Name="StatsText", Parent=statsBar,
            Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,6,0,0), BackgroundTransparency=1,
            Text="Bounty: 0 | Kills: 0", TextColor3=T.Theme.AccentLight,
            FontFace=T.Font, TextSize=12, TextXAlignment=Enum.TextXAlignment.Center})
        UI.StatsLabel = statsLabel

        if UserInputService.TouchEnabled then
            local closeCorner = New("ImageButton", {Parent=screenGui, Size=UDim2.new(0,50,0,50),
                Position=UDim2.new(1,-60,0,10), BackgroundColor3=T.Theme.Primary,
                Image="rbxassetid://8664466177", ImageColor3=T.Theme.TextBright,
                ScaleType=Enum.ScaleType.Fit})
            AddCorner(closeCorner, UDim.new(1,0))
            AddStroke(closeCorner, T.Theme.Accent, 2, 0.3)
            btnFeedback(closeCorner)
            closeCorner.MouseButton1Click:Connect(function() UI:ToggleVisibility() end)
            UI.MobileToggle = closeCorner
        end

        UI.TabsListLayout = tabsListLayout
        UI.Header = header
        return main
    end

    function UI:applyButtonFeedback(btn)
        local orig=btn.BackgroundColor3
        local hover=orig and Color3.new(math.min(orig.R+0.08,1),math.min(orig.G+0.08,1),math.min(orig.B+0.08,1)) or T.Theme.ButtonHover
        btn.MouseEnter:Connect(function() tweenObject(btn,{BackgroundColor3=hover},0.15):Play() end)
        btn.MouseLeave:Connect(function() tweenObject(btn,{BackgroundColor3=orig or T.Theme.ButtonBg},0.2):Play() end)
    end
    function UI:createTextButton(text, parent, callback, size)
        size=size or UDim2.new(1,-12,0,34)
        local btn = New("TextButton", {Name=text, Parent=parent, Size=size,
            BackgroundColor3=T.Theme.ButtonBg, Text=text, TextColor3=T.Theme.TextBright,
            FontFace=T.FontBold, TextSize=14, BorderSizePixel=0, AutoButtonColor=false})
        AddCorner(btn, T.ButtonRadius)
        AddStroke(btn, T.Theme.Border, 1, 0.6)
        btn.MouseButton1Click:Connect(function()
            if callback then local s,e=pcall(callback)
                if not s and getgenv()._DeniaUtils then getgenv()._DeniaUtils.logError(e,"Button:"..text) end end
        end)
        local orig=T.Theme.ButtonBg
        btn.MouseEnter:Connect(function() tweenObject(btn,{BackgroundColor3=T.Theme.ButtonHover},0.15):Play() end)
        btn.MouseLeave:Connect(function() tweenObject(btn,{BackgroundColor3=orig},0.2):Play() end)
        return btn
    end

    function UI:CreateTab(name, icon, order)
        order=order or #Tabs+1
        local tabData={Name=name, Icon=icon, Order=order, Container=nil, TabButton=nil, Sections={}, Elements={}}
        local btn = New("ImageButton", {Name=name.."Tab", Parent=UI.TabsContainer,
            Size=UDim2.new(0,34,0,34), BackgroundColor3=T.Theme.TabInactive,
            Image=icon or "", ImageColor3=T.Theme.TextDim, ScaleType=Enum.ScaleType.Fit,
            BorderSizePixel=0, LayoutOrder=order})
        AddCorner(btn, T.TabRadius)
        AddStroke(btn, T.Theme.Border, 1, 0.7)
        local indicator = New("Frame", {Name="Indicator", Parent=btn,
            Size=UDim2.new(0,3,0.6,0), Position=UDim2.new(0,0,0.2,0),
            BackgroundColor3=T.Theme.Accent, BorderSizePixel=0, Visible=false})
        AddCorner(indicator, UDim.new(0,2))
        tabData.Indicator=indicator; tabData.TabButton=btn
        btn.MouseEnter:Connect(function() if currentTab~=tabData then tweenObject(btn,{BackgroundColor3=T.Theme.TabHover},0.15):Play() end end)
        btn.MouseLeave:Connect(function() if currentTab~=tabData then tweenObject(btn,{BackgroundColor3=T.Theme.TabInactive},0.2):Play() end end)
        btn.MouseButton1Click:Connect(function() UI:SelectTab(tabData) end)

        local container = New("ScrollingFrame", {Name=name.."Container", Parent=UI.Content,
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ScrollBarThickness=4,
            ScrollBarImageColor3=T.Theme.ScrollBar, CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollingDirection=Enum.ScrollingDirection.Y,
            BorderSizePixel=0, Visible=false})
        AddCorner(container, T.ScrollRadius)
        New("UIPadding", {Parent=container, PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,16),
            PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8)})
        local containerLayout = New("UIListLayout", {Parent=container, Padding=UDim.new(0,10),
            SortOrder=Enum.SortOrder.LayoutOrder})
        tabData.Container=container; tabData.ContainerLayout=containerLayout
        table.insert(Tabs, tabData)
        if not currentTab then UI:SelectTab(tabData) end
        return tabData
    end

    function UI:SelectTab(tabData)
        if currentTab then
            if currentTab.TabButton then tweenObject(currentTab.TabButton,{BackgroundColor3=T.Theme.TabInactive,ImageColor3=T.Theme.TextDim},0.2):Play() end
            if currentTab.Indicator then currentTab.Indicator.Visible=false end
            if currentTab.Container then currentTab.Container.Visible=false end
        end
        currentTab=tabData
        if tabData.TabButton then tweenObject(tabData.TabButton,{BackgroundColor3=T.Theme.TabActive,ImageColor3=T.Theme.AccentLight},0.2):Play() end
        if tabData.Indicator then tabData.Indicator.Visible=true end
        if tabData.Container then tabData.Container.Visible=true; tabData.Container.CanvasPosition=Vector2.new(0,0) end
    end

    function UI:Section(tab, name, order)
        order=order or 1
        local sectionFrame = New("Frame", {Name=name.."Section", Parent=tab.Container,
            Size=UDim2.new(1,0,0,0), BackgroundColor3=T.Theme.Surface,
            BorderSizePixel=0, ClipsDescendants=true, LayoutOrder=order})
        AddCorner(sectionFrame, T.CardRadius)
        AddStroke(sectionFrame, T.Theme.Border, 1, 0.65)
        New("UIGradient", {Parent=sectionFrame, Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,T.Theme.Surface),
            ColorSequenceKeypoint.new(1,T.Theme.Base)}), Rotation=90})

        local headerBar = New("Frame", {Name="SectionHeader", Parent=sectionFrame,
            Size=UDim2.new(1,0,0,34), BackgroundColor3=T.Theme.Theme, BorderSizePixel=0})
        AddCorner(headerBar, T.CardRadius)
        New("UIClip", {Parent=headerBar})
        New("TextLabel", {Name="SectionTitle", Parent=headerBar, Size=UDim2.new(1,-20,1,0),
            Position=UDim2.new(0,14,0,0), BackgroundTransparency=1, Text=name,
            TextColor3=T.Theme.AccentLight, FontFace=T.FontBold, TextSize=16,
            TextXAlignment=Enum.TextXAlignment.Left})

        local sectionContent = New("Frame", {Name="SectionContent", Parent=sectionFrame,
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,36), BackgroundTransparency=1})
        New("UIPadding", {Parent=sectionContent, PaddingTop=UDim.new(0,4),
            PaddingBottom=UDim.new(0,8), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)})
        local sectionLayout = New("UIListLayout", {Parent=sectionContent, Padding=UDim.new(0,6),
            SortOrder=Enum.SortOrder.LayoutOrder})

        local sectionData={Frame=sectionFrame, Header=headerBar, Content=sectionContent,
            Layout=sectionLayout, Elements={}}
        local function updateSize()
            local totalHeight=38
            for _,child in ipairs(sectionContent:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible then totalHeight=totalHeight+child.AbsoluteSize.Y+6 end end
            sectionFrame.Size=UDim2.new(1,0,0,totalHeight)
        end
        sectionContent.ChildAdded:Connect(function() updateSize() end)
        sectionContent.ChildRemoved:Connect(function() updateSize() end)
        sectionData.Update=updateSize
        tab.Sections[name]=sectionData
        table.insert(tab.Elements, sectionData)
        return sectionData
    end
    function UI:Toggle(tab, section, configKey, displayName, defaultState, order)
        order=order or 1
        local state=defaultState
        if getgenv()._DeniaConfig and getgenv()._DeniaConfig[configKey]~=nil then state=getgenv()._DeniaConfig[configKey] end
        local row = New("Frame", {Name=displayName.."Toggle", Parent=section.Content,
            Size=UDim2.new(1,0,0,36), BackgroundTransparency=1, LayoutOrder=order})
        New("TextLabel", {Name="Label", Parent=row, Size=UDim2.new(1,-56,1,0),
            BackgroundTransparency=1, Text=displayName, TextColor3=T.Theme.Text,
            FontFace=T.Font, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left})
        local toggleBg = New("Frame", {Name="ToggleBg", Parent=row,
            Size=UDim2.new(0,44,0,22), Position=UDim2.new(1,-50,0.5,-11),
            BackgroundColor3=state and T.Theme.ToggleOn or T.Theme.ToggleOff, BorderSizePixel=0})
        AddCorner(toggleBg, T.ToggleRadius)
        AddStroke(toggleBg, T.Theme.Border, 1, 0.5)
        local toggleKnob = New("Frame", {Name="Knob", Parent=toggleBg,
            Size=UDim2.new(0,18,0,18), Position=UDim2.new(0,state and 24 or 2,0.5,-9),
            BackgroundColor3=T.Theme.ToggleKnob, BorderSizePixel=0})
        AddCorner(toggleKnob, UDim.new(1,0))
        local interactive = New("ImageButton", {Name="Interactive", Parent=row,
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, AutoButtonColor=false})
        local function updateToggle(newState)
            state=newState
            tweenObject(toggleBg,{BackgroundColor3=state and T.Theme.ToggleOn or T.Theme.ToggleOff},0.2):Play()
            tweenObject(toggleKnob,{Position=UDim2.new(0,state and 24 or 2,0.5,-9)},0.2):Play()
            if getgenv()._DeniaConfig then
                getgenv()._DeniaConfig[configKey]=state
                if getgenv()._DeniaConfig.saveSettings then getgenv()._DeniaConfig.saveSettings() end
            end
        end
        interactive.MouseButton1Click:Connect(function() updateToggle(not state) end)
        interactive.MouseEnter:Connect(function()
            tweenObject(toggleBg,{BackgroundColor3=state and T.Theme.PrimaryLight or Color3.fromRGB(68,90,68)},0.15):Play() end)
        interactive.MouseLeave:Connect(function()
            tweenObject(toggleBg,{BackgroundColor3=state and T.Theme.ToggleOn or T.Theme.ToggleOff},0.2):Play() end)
        row._update=updateToggle
        section.Update()
        return row
    end

    function UI:Dropdown(tab, section, configKey, displayName, options, default, order)
        order=order or 1
        local selected=default or (options and options[1]) or "None"
        local row = New("Frame", {Name=displayName.."Dropdown", Parent=section.Content,
            Size=UDim2.new(1,0,0,66), BackgroundTransparency=1, LayoutOrder=order})
        New("TextLabel", {Name="Label", Parent=row, Size=UDim2.new(1,0,0,20),
            BackgroundTransparency=1, Text=displayName, TextColor3=T.Theme.Text,
            FontFace=T.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
        local dropdownBtn = New("TextButton", {Name="DropdownBtn", Parent=row,
            Size=UDim2.new(1,0,0,38), Position=UDim2.new(0,0,0,20),
            BackgroundColor3=T.Theme.DropdownBg, Text=selected, TextColor3=T.Theme.TextBright,
            FontFace=T.Font, TextSize=14, BorderSizePixel=0, ClipsDescendants=true, AutoButtonColor=false})
        AddCorner(dropdownBtn, T.InputRadius)
        AddStroke(dropdownBtn, T.Theme.Border, 1, 0.6)
        New("TextLabel", {Name="Arrow", Parent=dropdownBtn, Size=UDim2.new(0,20,1,0),
            Position=UDim2.new(1,-24,0,0), BackgroundTransparency=1, Text="?",
            TextColor3=T.Theme.Accent, FontFace=T.Font, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Center})

        local dropdownFrame = New("Frame", {Name="DropdownList", Parent=row,
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,62),
            BackgroundColor3=T.Theme.DropdownBg, BorderSizePixel=0, ClipsDescendants=true,
            Visible=false, ZIndex=20})
        AddCorner(dropdownFrame, T.DropdownRadius)
        AddStroke(dropdownFrame, T.Theme.Border, 1, 0.5)
        local listLayout = New("UIListLayout", {Parent=dropdownFrame, Padding=UDim.new(0,2),
            SortOrder=Enum.SortOrder.LayoutOrder})

        local function populateList()
            for _,child in ipairs(dropdownFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
            for _,opt in ipairs(options) do
                local optBtn = New("TextButton", {Name=opt, Parent=dropdownFrame,
                    Size=UDim2.new(1,-4,0,32), Position=UDim2.new(0,2,0,0),
                    BackgroundColor3=(opt==selected) and T.Theme.DropdownHover or T.Theme.DropdownItem,
                    Text=opt, TextColor3=(opt==selected) and T.Theme.AccentLight or T.Theme.Text,
                    FontFace=T.Font, TextSize=13, BorderSizePixel=0, AutoButtonColor=false})
                AddCorner(optBtn, T.BadgeRadius)
                optBtn.MouseButton1Click:Connect(function()
                    selected=opt; dropdownBtn.Text=opt; dropdownFrame.Visible=false
                    tweenObject(dropdownFrame,{Size=UDim2.new(1,0,0,0)},0.15):Play()
                    if getgenv()._DeniaConfig then
                        getgenv()._DeniaConfig[configKey]=opt
                        if getgenv()._DeniaConfig.saveSettings then getgenv()._DeniaConfig.saveSettings() end
                    end
                    populateList()
                end)
                optBtn.MouseEnter:Connect(function() tweenObject(optBtn,{BackgroundColor3=T.Theme.DropdownHover},0.1):Play() end)
                optBtn.MouseLeave:Connect(function() tweenObject(optBtn,{BackgroundColor3=(opt==selected) and T.Theme.DropdownHover or T.Theme.DropdownItem},0.15):Play() end)
            end
            local listHeight=math.min(#options*34,200)
            dropdownFrame.Size=dropdownFrame.Visible and UDim2.new(1,0,0,listHeight) or UDim2.new(1,0,0,0)
        end

        dropdownBtn.MouseButton1Click:Connect(function()
            local newVis=not dropdownFrame.Visible; dropdownFrame.Visible=newVis
            if newVis then dropdownFrame.ZIndex=50; populateList()
                tweenObject(dropdownFrame,{Size=UDim2.new(1,0,0,math.min(#options*34,200))},0.2):Play()
            else tweenObject(dropdownFrame,{Size=UDim2.new(1,0,0,0)},0.15):Play() end
        end)

        UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                local pos=UserInputService.GetMouseLocation and UserInputService:GetMouseLocation() or Vector2.new(0,0)
                local absPos=dropdownFrame.AbsolutePosition; local absSize=dropdownFrame.AbsoluteSize
                local rowAbs=row.AbsolutePosition; local rowSize=row.AbsoluteSize
                local inRow=pos.X>=rowAbs.X and pos.X<=rowAbs.X+rowSize.X and pos.Y>=rowAbs.Y and pos.Y<=rowAbs.Y+rowSize.Y
                local inDropdown=dropdownFrame.Visible and pos.X>=absPos.X and pos.X<=absPos.X+absSize.X and pos.Y>=absPos.Y and pos.Y<=absPos.Y+absSize.Y
                if not inRow and not inDropdown and dropdownFrame.Visible then
                    dropdownFrame.Visible=false; tweenObject(dropdownFrame,{Size=UDim2.new(1,0,0,0)},0.15):Play() end
            end
        end)

        row._setValue=function(val) selected=val; dropdownBtn.Text=val; populateList() end
        row._getValue=function() return selected end
        section.Update()
        return row
    end
    function UI:Slider(tab, section, configKey, displayName, min, max, default, suffix, order, step)
        order=order or 1; step=step or 1
        local value=default or min; local dragging=false
        local row = New("Frame", {Name=displayName.."Slider", Parent=section.Content,
            Size=UDim2.new(1,0,0,52), BackgroundTransparency=1, LayoutOrder=order})
        New("TextLabel", {Name="Label", Parent=row, Size=UDim2.new(1,-80,0,20),
            BackgroundTransparency=1, Text=displayName, TextColor3=T.Theme.Text,
            FontFace=T.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
        local valueLabel = New("TextLabel", {Name="Value", Parent=row,
            Size=UDim2.new(0,70,0,20), Position=UDim2.new(1,-74,0,0), BackgroundTransparency=1,
            Text=tostring(value)..(suffix or ""), TextColor3=T.Theme.Accent,
            FontFace=T.FontBold, TextSize=13, TextXAlignment=Enum.TextXAlignment.Right})
        local railBg = New("Frame", {Name="Rail", Parent=row, Size=UDim2.new(1,0,0,6),
            Position=UDim2.new(0,0,0,28), BackgroundColor3=T.Theme.SliderRail, BorderSizePixel=0})
        AddCorner(railBg, T.SliderRadius)
        local fill = New("Frame", {Name="Fill", Parent=railBg,
            Size=UDim2.new((value-min)/(max-min),0,1,0),
            BackgroundColor3=T.Theme.SliderFill, BorderSizePixel=0})
        AddCorner(fill, T.SliderRadius)
        local knob = New("Frame", {Name="Knob", Parent=railBg,
            Size=UDim2.new(0,14,0,14), Position=UDim2.new((value-min)/(max-min),-7,0.5,-7),
            BackgroundColor3=T.Theme.SliderKnob, BorderSizePixel=0})
        AddCorner(knob, UDim.new(1,0))
        AddStroke(knob, T.Theme.Accent, 2, 0.3)
        local interactive = New("ImageButton", {Name="Interactive", Parent=row,
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, AutoButtonColor=false, ZIndex=10})
        local function updateSlider(inputPos)
            local railAbs=railBg.AbsolutePosition; local railSize=railBg.AbsoluteSize.X
            local relX=math.clamp(inputPos.X-railAbs.X,0,railSize)
            local ratio=relX/railSize; value=math.round((min+ratio*(max-min))/step)*step
            value=math.clamp(value,min,max)
            fill.Size=UDim2.new(ratio,0,1,0); knob.Position=UDim2.new(ratio,-7,0.5,-7)
            valueLabel.Text=tostring(value)..(suffix or "")
            if getgenv()._DeniaConfig then getgenv()._DeniaConfig[configKey]=value end
        end
        interactive.MouseButton1Down:Connect(function(input) dragging=true; updateSlider(input.Position) end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then updateSlider(input.Position) end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                if dragging then dragging=false
                    if getgenv()._DeniaConfig and getgenv()._DeniaConfig.saveSettings then getgenv()._DeniaConfig.saveSettings() end end
            end
        end)
        row._setValue=function(nv) value=math.clamp(nv,min,max); updateSlider({Position=Vector2.new(railBg.AbsolutePosition.X+(value-min)/(max-min)*railBg.AbsoluteSize.X,0)}) end
        row._getValue=function() return value end
        section.Update()
        return row
    end

    function UI:Button(tab, section, displayName, callback, order, size)
        order=order or 1
        local btn=self:createTextButton(displayName, section.Content, callback, size or UDim2.new(1,0,0,38))
        btn.LayoutOrder=order; btn.BackgroundColor3=T.Theme.ButtonBg
        section.Update()
        return btn
    end

    function UI:Label(tab, section, text, order, color)
        order=order or 1
        local label = New("TextLabel", {Name="Label", Parent=section.Content,
            Size=UDim2.new(1,0,0,22), BackgroundTransparency=1, Text=text,
            TextColor3=color or T.Theme.Text, FontFace=T.Font, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=order, RichText=true})
        section.Update()
        return label
    end

    function UI:Separator(tab, section, order)
        order=order or 1
        local sep = New("Frame", {Name="Separator", Parent=section.Content,
            Size=UDim2.new(1,-4,0,1), Position=UDim2.new(0,2,0,0),
            BackgroundColor3=T.Theme.Border, BorderSizePixel=0, LayoutOrder=order})
        section.Update()
        return sep
    end

    function UI:TextBox(tab, section, configKey, displayName, placeholder, default, order)
        order=order or 1; local value=default or ""
        local row = New("Frame", {Name=displayName.."Input", Parent=section.Content,
            Size=UDim2.new(1,0,0,60), BackgroundTransparency=1, LayoutOrder=order})
        New("TextLabel", {Name="Label", Parent=row, Size=UDim2.new(1,0,0,20),
            BackgroundTransparency=1, Text=displayName, TextColor3=T.Theme.Text,
            FontFace=T.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
        local box = New("TextBox", {Name="Input", Parent=row, Size=UDim2.new(1,0,0,34),
            Position=UDim2.new(0,0,0,22), BackgroundColor3=T.Theme.InputBg, Text=value,
            TextColor3=T.Theme.TextBright, FontFace=T.Font, TextSize=14,
            PlaceholderText=placeholder or "", PlaceholderColor3=T.Theme.TextDim,
            BorderSizePixel=0, ClearTextOnFocus=false})
        AddCorner(box, T.InputRadius); AddStroke(box, T.Theme.Border, 1, 0.6)
        box.FocusLost:Connect(function(enterPressed)
            value=box.Text
            if getgenv()._DeniaConfig then getgenv()._DeniaConfig[configKey]=value
                if getgenv()._DeniaConfig.saveSettings then getgenv()._DeniaConfig.saveSettings() end end
        end)
        row._getValue=function() return value end; row._setValue=function(v) value=v; box.Text=v end
        section.Update()
        return row
    end

    function UI:Keybind(tab, section, configKey, displayName, defaultKey, order)
        order=order or 1; local currentKey=defaultKey or Enum.KeyCode.RightShift; local listening=false
        local row = New("Frame", {Name=displayName.."Keybind", Parent=section.Content,
            Size=UDim2.new(1,0,0,40), BackgroundTransparency=1, LayoutOrder=order})
        New("TextLabel", {Name="Label", Parent=row, Size=UDim2.new(1,-100,1,0),
            BackgroundTransparency=1, Text=displayName, TextColor3=T.Theme.Text,
            FontFace=T.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left})
        local keyBtn = New("TextButton", {Name="KeyButton", Parent=row,
            Size=UDim2.new(0,90,0,30), Position=UDim2.new(1,-94,0.5,-15),
            BackgroundColor3=T.Theme.ButtonBg, Text=currentKey.Name,
            TextColor3=T.Theme.TextBright, FontFace=T.FontBold, TextSize=12,
            BorderSizePixel=0, AutoButtonColor=false})
        AddCorner(keyBtn, T.ButtonRadius); AddStroke(keyBtn, T.Theme.Border, 1, 0.6)
        local function setKey(kc) currentKey=kc; keyBtn.Text=kc.Name
            if getgenv()._DeniaConfig then getgenv()._DeniaConfig[configKey]=kc end end
        keyBtn.MouseButton1Click:Connect(function() listening=true; keyBtn.TextColor3=T.Theme.Accent; keyBtn.Text="..."
            local conn; conn=UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType==Enum.UserInputType.Keyboard then listening=false; setKey(input.KeyCode); keyBtn.TextColor3=T.Theme.TextBright; conn:Disconnect()
                elseif input.UserInputType==Enum.UserInputType.Touch then listening=false; keyBtn.TextColor3=T.Theme.TextBright; conn:Disconnect() end
            end)
        end)
        keyBtn.MouseEnter:Connect(function() tweenObject(keyBtn,{BackgroundColor3=T.Theme.ButtonHover},0.15):Play() end)
        keyBtn.MouseLeave:Connect(function() tweenObject(keyBtn,{BackgroundColor3=T.Theme.ButtonBg},0.2):Play() end)
        row._getKey=function() return currentKey end; row._setKey=setKey
        section.Update()
        return row
    end
    function UI:CreateNotification(title, message, duration, style)
        duration=duration or 4; style=style or "info"
        table.insert(notificationQueue, {title=title, message=message, duration=duration, style=style})
        if not notificationActive then UI:ShowNextNotification() end
    end

    function UI:ShowNextNotification()
        if #notificationQueue==0 then notificationActive=false; return end
        notificationActive=true
        local data=table.remove(notificationQueue,1)
        local notif = New("Frame", {Name="Notification", Parent=UI.ScreenGui,
            Size=UDim2.new(0,340,0,0), Position=UDim2.new(1,-360,0,20),
            BackgroundColor3=T.Theme.Notification, BorderSizePixel=0,
            ClipsDescendants=true, ZIndex=100})
        AddCorner(notif, T.NotifRadius); AddStroke(notif, T.Theme.Border, 1.5, 0.4)
        New("UIGradient", {Parent=notif, Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,T.Theme.Notification),
            ColorSequenceKeypoint.new(1,T.Theme.Base)}), Rotation=90})
        local accentColor=data.style=="success" and T.Theme.Success or data.style=="error" and T.Theme.Danger or data.style=="warning" and T.Theme.Warning or T.Theme.Info
        local accentLine = New("Frame", {Name="Accent", Parent=notif, Size=UDim2.new(0,4,1,-4),
            Position=UDim2.new(0,2,0,2), BackgroundColor3=accentColor, BorderSizePixel=0})
        AddCorner(accentLine, UDim.new(0,2))
        New("TextLabel", {Name="Title", Parent=notif, Size=UDim2.new(1,-20,0,22),
            Position=UDim2.new(0,14,0,6), BackgroundTransparency=1, Text=data.title or "DeniaHub",
            TextColor3=T.Theme.TextBright, FontFace=T.FontBold, TextSize=14,
            TextXAlignment=Enum.TextXAlignment.Left})
        New("TextLabel", {Name="Message", Parent=notif, Size=UDim2.new(1,-20,0,18),
            Position=UDim2.new(0,14,0,28), BackgroundTransparency=1, Text=data.message or "",
            TextColor3=T.Theme.TextDim, FontFace=T.Font, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true})
        local notifSize=50+math.max(0,#(data.message or ""));
        notif.Size=UDim2.new(0,340,0,math.min(notifSize,100))
        notif.Position=UDim2.new(1,-360,0,-notifSize-10)
        local t1 = tweenObject(notif,{Position=UDim2.new(1,-360,0,20)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
        t1:Play()
        task.delay(data.duration,function()
            local t2 = tweenObject(notif,{Position=UDim2.new(1,-360,0,-notifSize-10),BackgroundTransparency=1},0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
            t2:Play()
            task.wait(0.35)
            pcall(function() notif:Destroy() end)
            UI:ShowNextNotification()
        end)
    end

    function UI:ToggleVisibility()
        UI.Visible=not UI.Visible
        if UI.Main then UI.Main.Visible=UI.Visible end
        if UI.MobileToggle then UI.MobileToggle.Visible=not UI.Visible end
    end

    function UI:UpdateStatsText()
        local Utils=getgenv()._DeniaUtils
        if not Utils then return end
        local stats=Utils.loadStats()
        if stats and UI.StatsLabel then
            UI.StatsLabel.Text = string.format("Bounty: %s | Kills: %d | Hopped: %d",
                Utils.formatNumber(stats.totalBountyGained or 0),
                stats.totalKills or 0, stats.serversHopped or 0)
        end
    end

    function UI:Init()
        self:CreateMain()
        local statsConn = RunService.Heartbeat:Connect(function()
            if UI.Visible and UI.StatsLabel then UI:UpdateStatsText() end
        end)
        table.insert(cleanupFuncs, statsConn)
        local toggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==UI.ToggleKey then
                UI:ToggleVisibility()
            end
        end)
        table.insert(cleanupFuncs, toggleConn)
    end

    function UI:Cleanup()
        for _,conn in ipairs(cleanupFuncs) do pcall(function() conn:Disconnect() end) end
        cleanupFuncs={}
        for _,inst in ipairs(UIInstances) do pcall(function() inst:Destroy() end) end
        UIInstances={}; UI.Main=nil
    end

    return UI
end
_modules["main"] = function()
    local Main = {}
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Workspace = game:GetService("Workspace")
    local lp = Players.LocalPlayer
    local Config = getgenv()._DeniaConfig
    local Utils = getgenv()._DeniaUtils
    local UI = getgenv()._DeniaUI

    Main.Running = false
    Main.Paused = false
    Main.CurrentTarget = nil
    Main.FarmMode = "Bounty"
    Main.LoopConnections = {}
    Main.AttackCooldown = {}
    Main.SkillCooldowns = {}
    Main.LastAttackTime = 0
    Main.TargetScanInterval = 1
    Main.LastTargetScan = 0
    Main.BringConnection = nil
    Main.CurrentBotTarget = nil
    Main._targetPlayers = {}
    Main._currentLock = nil
    Main._bountyCache = {}
    Main._lastBountyValue = 0
    Main._combatCooldown = 0

    local COMBAT_COOLDOWN = 0.3
    local SKILL_COOLDOWN = 1.5
    local SCAN_INTERVAL = 0.5
    local BRING_RADIUS = 280
    local ATTACK_RANGE = 120

    function Main.getCharacter()
        local char = lp.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            char = lp.CharacterAdded:Wait()
        end
        return char
    end

    function Main.getHRP()
        local char = Main.getCharacter()
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    function Main.getHumanoid()
        local char = Main.getCharacter()
        return char and char:FindFirstChild("HumanoidOfLocal")
    end

    function Main.getRootPos()
        local hrp = Main.getHRP()
        return hrp and hrp.Position or Vector3.new(0,0,0)
    end

    function Main.teleportToCFrame(cf)
        local hrp = Main.getHRP()
        if hrp then hrp.CFrame = cf end
    end

    function Main.teleportToPosition(pos)
        Main.teleportToCFrame(CFrame.new(pos))
    end

    function Main.getDistanceFromChar(targetPos)
        return (Main.getRootPos() - targetPos).Magnitude
    end

    function Main.getPlayerBounty(player)
        local ls = player:FindFirstChild("leaderstats")
        if ls then
            local bh = ls:FindFirstChild("Bounty/Honor")
            if bh then return tonumber(bh.Value) or 0 end
        end
        return 0
    end

    function Main.getPlayerLevel(player)
        local data = player:FindFirstChild("Data")
        if data then
            local lv = data:FindFirstChild("Level")
            if lv then return tonumber(lv.Value) or 0 end
        end
        return 0
    end

    function Main.getPlayerHealth(player)
        local char = player.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then return hum.Health, hum.MaxHealth end
        end
        return 0, 100
    end

    function Main.isPlayerInRange(player, range)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            return Main.getDistanceFromChar(char.HumanoidRootPart.Position) <= (range or ATTACK_RANGE)
        end
        return false
    end

    function Main.getClosestPlayer()
        local closest = nil; local closestDist = math.huge
        local myPos = Main.getRootPos()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (myPos - player.Character.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then closestDist = dist; closest = player end
            end
        end
        return closest, closestDist
    end

    function Main.getTargetPlayers()
        local targets = {}
        local config = Config
        local isWhitelist = config.WHITELIST_MODE == "Whitelist"
        local buddyList = config.BUDDY_LIST or {}
        local teamCheck = config.TEAM_CHECK

        local myTeam = ""
        pcall(function()
            local data = lp:FindFirstChild("Data")
            if data then
                local faction = data:FindFirstChild("Faction")
                if faction then myTeam = tostring(faction.Value) end
            end
        end)

        local myLevel = Main.getPlayerLevel(lp)

        for _, player in ipairs(Players:GetPlayers()) do
            if player == lp then goto continue end
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then goto continue end
            if not player.Character:FindFirstChild("Humanoid") then goto continue end
            local hum = player.Character.Humanoid
            if hum.Health <= 0 then goto continue end

            local playerName = player.Name:lower()
            if isWhitelist then
                local matched = false
                for _, buddyName in ipairs(buddyList) do
                    if playerName == buddyName:lower() then matched = true; break end
                end
                if not matched then goto continue end
            else
                local blocked = false
                for _, buddyName in ipairs(buddyList) do
                    if playerName == buddyName:lower() then blocked = true; break end
                end
                if blocked then goto continue end
            end

            if teamCheck then
                local theirTeam = ""
                pcall(function()
                    local data = player:FindFirstChild("Data")
                    if data then
                        local faction = data:FindFirstChild("Faction")
                        if faction then theirTeam = tostring(faction.Value) end
                    end
                end)
                if myTeam ~= "" and myTeam == theirTeam then goto continue end
            end

            table.insert(targets, player)
            ::continue::
        end
        return targets
    end

    function Main.selectTarget()
        local targets = Main.getTargetPlayers()
        if #targets == 0 then Main.CurrentTarget = nil; return nil end

        local target = nil
        local method = Config.LOCK_METHOD or "Nearest"

        if method == "Nearest" then
            local closestDist = math.huge
            local myPos = Main.getRootPos()
            for _, player in ipairs(targets) do
                local dist = (myPos - player.Character.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then closestDist = dist; target = player end
            end
        elseif method == "Mouse" then
            local mouse = lp:GetMouse()
            local closestDist = math.huge
            for _, player in ipairs(targets) do
                local screenPos, onScreen = Workspace.CurrentCamera:WorldToScreenPoint(player.Character.HumanoidRootPart.Position)
                if onScreen then
                    local dist = (mouse.X - screenPos.X)^2 + (mouse.Y - screenPos.Y)^2
                    if dist < closestDist then closestDist = dist; target = player end
                end
            end
        elseif method == "Health" then
            local lowestHp = math.huge
            for _, player in ipairs(targets) do
                local hp = Main.getPlayerHealth(player)
                if hp < lowestHp then lowestHp = hp; target = player end
            end
        elseif method == "Bounty" then
            local highestBounty = 0
            for _, player in ipairs(targets) do
                local bounty = Main.getPlayerBounty(player)
                if bounty > highestBounty then highestBounty = bounty; target = player end
            end
        elseif method == "Level" then
            local closestLevel = math.huge
            local myLevel = Main.getPlayerLevel(lp)
            for _, player in ipairs(targets) do
                local diff = math.abs(Main.getPlayerLevel(player) - myLevel)
                if diff < closestLevel then closestLevel = diff; target = player end
            end
        end

        Main.CurrentTarget = target
        return target
    end
    function Main.useSkill(skillName, delay)
        delay = delay or SKILL_COOLDOWN
        local now = tick()
        if Main.SkillCooldowns[skillName] and (now - Main.SkillCooldowns[skillName]) < delay then return false end
        local char = Main.getCharacter()
        if not char then return false end
        local tool = char:FindFirstChild(skillName) or char:FindFirstChildWhichIsA("Tool")
        if not tool then return false end
        local remote = tool:FindFirstChild("RemoteFunction") or tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("Activate")
        if remote then
            pcall(function()
                if remote:IsA("RemoteFunction") then remote:InvokeServer()
                elseif remote:IsA("RemoteEvent") then remote:FireServer()
                end
            end)
            Main.SkillCooldowns[skillName] = now
            return true
        end
        return false
    end

    function Main.combatStep(target)
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
            Main.CurrentTarget = nil; return
        end
        local hrp = target.Character.HumanoidRootPart
        local dist = Main.getDistanceFromChar(hrp.Position)
        local myHrp = Main.getHRP()
        if not myHrp then return end

        if dist > ATTACK_RANGE then
            local cf = CFrame.new(hrp.Position + (hrp.Position - myHrp.Position).Unit * math.min(dist - 5, 100))
            if Config.BRING_TP == "Close" then
                Main.teleportToCFrame(cf)
            end
            return
        end

        Main.teleportToCFrame(CFrame.new(hrp.Position + (hrp.Position - myHrp.Position).Unit * 8))
        Main.useSkill("Melee", COMBAT_COOLDOWN)
        Main.useSkill("Sword", COMBAT_COOLDOWN)
        Main.useSkill("Gun", COMBAT_COOLDOWN)
        Main.useSkill(Config.FRUIT or "Flame", SKILL_COOLDOWN)
    end

    function Main.bringMobsToTarget()
        if not Config.BRING_MOBS then return end
        local target = Main.CurrentTarget
        if not target then return end
        local tgtChar = target.Character
        if not tgtChar or not tgtChar:FindFirstChild("HumanoidRootPart") then return end
        local tgtPos = tgtChar.HumanoidRootPart.Position
        local radius = Config.BRING_RADIUS or BRING_RADIUS
        local mode = Config.BRING_MODE or "Normal"

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                local hum = obj.Humanoid
                if hum.Health > 0 then
                    local npcPos = obj.HumanoidRootPart.Position
                    local dist = (npcPos - tgtPos).Magnitude
                    if dist <= radius then
                        local newPos = tgtPos + Vector3.new(math.random(-8,8), 0, math.random(-8,8))
                        if mode == "Fast" then
                            obj.HumanoidRootPart.CFrame = CFrame.new(newPos)
                        else
                            TweenService:Create(obj.HumanoidRootPart, TweenInfo.new(0.5), {CFrame=CFrame.new(newPos)}):Play()
                        end
                    end
                end
            end
        end
    end

    function Main.serverHop()
        local hopType = Config.HOP_TYPE or "Hop"
        if hopType == "Rejoin" then
            TeleportService:Teleport(game.PlaceId, lp)
        else
            local servers = {}
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"))
            end)
            if success and result and result.data then
                for _, server in ipairs(result.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(servers, server.id)
                    end
                end
                if #servers > 0 then
                    local targetId = servers[math.random(1, #servers)]
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, targetId, lp)
                end
            end
        end
        if Utils then
            if Config.AUTO_HOP then Utils.incrementAutoServerHops() else Utils.incrementServerHops() end
        end
    end

    function Main.checkBountyChange()
        local currentBounty = Main.getPlayerBounty(lp)
        if currentBounty > Main._lastBountyValue and Main._lastBountyValue > 0 then
            local gained = currentBounty - Main._lastBountyValue
            if gained > 0 and Utils then
                Utils.updateStats(gained, 0)
                Utils.flushStats()
                if UI then UI:UpdateStatsText() end
            end
        elseif currentBounty < Main._lastBountyValue then
            local lost = Main._lastBountyValue - currentBounty
            if lost > 10000 and Utils then
                Utils.notify("Bounty Lost!", "You lost " .. Utils.formatNumber(lost) .. " bounty!", 3)
            end
        end
        Main._lastBountyValue = currentBounty
    end

    function Main.checkDeath()
        local char = Main.getCharacter()
        if not char then return false end
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.Health <= 0 then return true end
        local bv = char:FindFirstChild("BodyEffects")
        if bv then
            local dead = bv:FindFirstChild("Dead")
            if dead and dead.Value then return true end
        end
        return false
    end

    function Main.autoFarmBounty()
        if Main.checkDeath() then Main.Paused = true
            task.wait(3); Main.Paused = false; return
        end
        local now = tick()
        if now - Main.LastTargetScan < Main.TargetScanInterval then return end
        Main.LastTargetScan = now

        if not Main.CurrentTarget or not Main.CurrentTarget.Character or
            not Main.CurrentTarget.Character:FindFirstChild("HumanoidRootPart") or
            (Main.CurrentTarget.Character:FindFirstChild("Humanoid") and
            Main.CurrentTarget.Character.Humanoid.Health <= 0) then
            Main.selectTarget()
        end

        if Main.CurrentTarget then
            Main.combatStep(Main.CurrentTarget)
            if Config.BRING_MOBS then Main.bringMobsToTarget() end
        end

        if now - Main._combatCooldown > 5 then
            Main.checkBountyChange()
            Main._combatCooldown = now
        end
    end

    function Main.godMode()
        local char = Main.getCharacter()
        if not char then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.MaxHealth = 999999
            humanoid.Health = 999999
        end
        local bre = char:FindFirstChild("BodyEffects")
        if bre then
            local dead = bre:FindFirstChild("Dead")
            if dead then dead.Value = false end
            local health = bre:FindFirstChild("Health")
            if health then health.Value = 999999 end
        end
    end

    function Main.invisibility()
        local char = Main.getCharacter()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 50 end
    end

    function Main.resetCharacter()
        local char = Main.getCharacter()
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.Health = 0 end
        end
    end

    function Main.autoFarmLoop()
        while Main.Running do
            if not Main.Paused then
                local s, e = pcall(function()
                    if Config.AUTO_FARM_BOUNTY then Main.autoFarmBounty() end
                    if Config.AUTO_GODMODE then Main.godMode() end
                    if Config.AUTO_INVIS then Main.invisibility() end
                    if Config.AUTO_BUSO then
                        pcall(function()
                            local data = lp:FindFirstChild("Data")
                            if data then
                                local buso = data:FindFirstChild("ObservationHaki")
                                if buso and not buso.Value then buso.Value = true end
                                local haki = data:FindFirstChild("ObservationHaki")
                                if haki and not haki.Value then haki.Value = true end
                            end
                        end)
                    end
                end)
                if not s and Utils then Utils.logError(e, "AutoFarmLoop") end
            end
            task.wait(0.15)
        end
    end
    function Main.init()
        Config = getgenv()._DeniaConfig
        Utils = getgenv()._DeniaUtils
        UI = getgenv()._DeniaUI
        if not Config or not Utils or not UI then
            Utils = Utils or getgenv()._DeniaUtils
            if Utils then Utils.logError("Missing dependencies in Main.init()", "Main") end
            return false
        end
        Main._lastBountyValue = Main.getPlayerBounty(lp)
        Main.Running = true
        local loopConn = RunService.Heartbeat:Connect(function()
            Main.autoFarmLoop()
        end)
        table.insert(Main.LoopConnections, loopConn)

        local antiBanConn = RunService.Heartbeat:Connect(function()
            if Config.ANTI_BAN then
                pcall(function()
                    local char = Main.getCharacter()
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid.Name = "HumanoidOfLocal"
                    end
                end)
            end
        end)
        table.insert(Main.LoopConnections, antiBanConn)

        local hopCheckConn = RunService.Stepped:Connect(function()
            if Config.AUTO_HOP then
                local stats = Utils and Utils.loadStats()
                if stats and stats.totalKills and stats.totalKills >= 4 then
                    Main.serverHop()
                end
            end
        end)
        table.insert(Main.LoopConnections, hopCheckConn)
        Utils.logDebug(Utils.DEBUG_LEVELS.INFO, "Main", "Main module initialized")
        return true
    end

    function Main.stop()
        Main.Running = false
        for _, conn in ipairs(Main.LoopConnections) do
            pcall(function() conn:Disconnect() end)
        end
        Main.LoopConnections = {}
        Main.CurrentTarget = nil
        Utils = Utils or getgenv()._DeniaUtils
        if Utils then Utils.logDebug(Utils.DEBUG_LEVELS.INFO, "Main", "Main module stopped") end
    end

    return Main
end
_modules["boot"] = function()
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local DeniaHub = {}
    DeniaHub.VERSION = "1.0"
    DeniaHub.START_TIME = os.time()
    DeniaHub.Loaded = false

    function DeniaHub.createTabs(UI, Config, Utils)
        UI:CreateTab("Main", "rbxassetid://8568970646", 1)
        UI:CreateTab("Combat", "rbxassetid://9048465907", 2)
        UI:CreateTab("Farming", "rbxassetid://8567823911", 3)
        UI:CreateTab("Misc", "rbxassetid://8568215835", 4)
        UI:CreateTab("Stats", "rbxassetid://8569146720", 5)
    end

    function DeniaHub.createMainTab(UI, Config, Utils, Main)
        local tab = UI.Tabs[1]
        local sec = UI:Section(tab, "Account", 1)
        UI:Label(tab, sec, ("Player: " .. lp.Name), 1, UI.Library.Theme.AccentLight)
        UI:Label(tab, sec, ("Bounty: " .. Utils.formatNumber(Utils.getCurrentBounty())), 2)
        UI:Separator(tab, sec, 3)
        UI:Button(tab, sec, "Reset Character", function() Main.resetCharacter() end, 4)
        local sec2 = UI:Section(tab, "Targeting", 2)
        UI:Dropdown(tab, sec2, "LOCK_METHOD", "Lock Method", Config.METHOD_LIST, Config.LOCK_METHOD, 1)
        UI:Slider(tab, sec2, "TARGET_DISTANCE", "Target Range", 50, 400, Config.TARGET_DISTANCE, "m", 2)
        UI:Dropdown(tab, sec2, "HOP_TYPE", "Hop Type", Config.HOP_TYPES, Config.HOP_TYPE, 3)
        UI:Button(tab, sec2, "Server Hop", function() Main.serverHop() end, 4)
        local sec3 = UI:Section(tab, "Whitelist", 3)
        UI:Dropdown(tab, sec3, "WHITELIST_MODE", "Mode", Config.WL_MODES, Config.WHITELIST_MODE, 1)
        UI:Label(tab, sec3, "Use DeniaHub/Data to edit buddy list", 2, UI.Library.Theme.TextDim)
        local sec4 = UI:Section(tab, "Visuals", 4)
        UI:Keybind(tab, sec4, "TOGGLE_KEY", "Toggle UI", UI.ToggleKey, 1)
        UI:Label(tab, sec4, "Current key: Right Shift", 2, UI.Library.Theme.TextDim)
        UI:SelectTab(tab)
    end

    function DeniaHub.createCombatTab(UI, Config, Utils, Main)
        local tab = UI.Tabs[2]
        local sec = UI:Section(tab, "Bounty Hunt", 1)
        UI:Toggle(tab, sec, "AUTO_FARM_BOUNTY", "Auto Farm Bounty", Config.AUTO_FARM_BOUNTY, 1)
        UI:Toggle(tab, sec, "BOUNTY_HUNTER", "Bounty Hunter Mode", Config.BOUNTY_HUNTER, 2)
        UI:Toggle(tab, sec, "TEAM_CHECK", "Team Check", Config.TEAM_CHECK, 3)
        UI:Toggle(tab, sec, "SAFE_MODE", "Safe Mode", Config.SAFE_MODE, 4)
        local sec2 = UI:Section(tab, "Weapons", 2)
        UI:Dropdown(tab, sec2, "MELEE", "Melee", Config.MELEE_LIST, Config.MELEE, 1)
        UI:Dropdown(tab, sec2, "SWORD", "Sword", Config.SWORD_LIST, Config.SWORD, 2)
        UI:Dropdown(tab, sec2, "GUN", "Gun", Config.GUN_LIST, Config.GUN, 3)
        local sec3 = UI:Section(tab, "Fruit", 3)
        UI:Dropdown(tab, sec3, "FRUIT", "Selected Fruit", Config.FRUIT_LIST, Config.FRUIT, 1)
        UI:Toggle(tab, sec3, "AUTO_STORE", "Auto Store Fruit", Config.AUTO_STORE, 2)
        local sec4 = UI:Section(tab, "Defense", 4)
        UI:Toggle(tab, sec4, "AUTO_GODMODE", "God Mode", Config.AUTO_GODMODE, 1)
        UI:Toggle(tab, sec4, "AUTO_INVIS", "Invisibility", Config.AUTO_INVIS, 2)
        UI:Toggle(tab, sec4, "AUTO_BUSO", "Auto Buso Haki", Config.AUTO_BUSO, 3)
        UI:Toggle(tab, sec4, "AUTO_OBS", "Auto Observation", Config.AUTO_OBS, 4)
        UI:SelectTab(tab)
    end

    function DeniaHub.createFarmingTab(UI, Config, Utils, Main)
        local tab = UI.Tabs[3]
        local sec = UI:Section(tab, "Level Farming", 1)
        UI:Toggle(tab, sec, "AUTO_FARM_LEVEL", "Auto Farm Level", Config.AUTO_FARM_LEVEL, 1)
        UI:Toggle(tab, sec, "AUTO_FARM_MASTERY", "Auto Farm Mastery", Config.AUTO_FARM_MASTERY, 2)
        UI:Toggle(tab, sec, "AUTO_ROLL", "Auto Roll Fruit", Config.AUTO_ROLL, 3)
        local sec2 = UI:Section(tab, "Raid", 2)
        UI:Toggle(tab, sec2, "AUTO_RAID", "Auto Raid", Config.AUTO_RAID, 1)
        UI:Dropdown(tab, sec2, "SELECTED_RAID", "Raid Mode", Config.RAID_LIST, Config.SELECTED_RAID, 2)
        UI:Toggle(tab, sec2, "AUTO_CHIP", "Auto Chip", Config.AUTO_CHIP, 3)
        local sec3 = UI:Section(tab, "Mobs", 3)
        UI:Toggle(tab, sec3, "BRING_MOBS", "Bring Mobs", Config.BRING_MOBS, 1)
        UI:Dropdown(tab, sec3, "BRING_TP", "TP Mode", Config.BRING_TP_LIST, Config.BRING_TP, 2)
        UI:Slider(tab, sec3, "BRING_RADIUS", "Bring Radius", 50, 400, Config.BRING_RADIUS, "m", 3)
        UI:Dropdown(tab, sec3, "BRING_MODE", "Bring Mode", Config.BRING_MODE_LIST, Config.BRING_MODE, 4)
        UI:Toggle(tab, sec3, "AUTO_ELITE", "Auto Elite", Config.AUTO_ELITE, 5)
        UI:Toggle(tab, sec3, "AUTO_NPC", "Auto NPC", Config.AUTO_NPC, 6)
        local sec4 = UI:Section(tab, "Events & Fish", 4)
        UI:Toggle(tab, sec4, "SEA_EVENT", "Sea Event", Config.SEA_EVENT, 1)
        UI:Dropdown(tab, sec4, "EVENT_TYPE", "Event Type", Config.EVENT_LIST, Config.EVENT_TYPE, 2)
        UI:Toggle(tab, sec4, "AUTO_FISH", "Auto Fish", Config.AUTO_FISH, 3)
        UI:Toggle(tab, sec4, "AUTO_CHEST", "Auto Chest", Config.AUTO_CHEST, 4)
        UI:SelectTab(tab)
    end

    function DeniaHub.createMiscTab(UI, Config, Utils, Main)
        local tab = UI.Tabs[4]
        local sec = UI:Section(tab, "Automation", 1)
        UI:Toggle(tab, sec, "AUTO_HOP", "Auto Hop (4 kills)", Config.AUTO_HOP, 1)
        UI:Toggle(tab, sec, "ANTI_BAN", "Anti Ban", Config.ANTI_BAN, 2)
        UI:Toggle(tab, sec, "AUTO_AURA", "Auto Haki", Config.AUTO_AURA, 3)
        UI:Toggle(tab, sec, "AUTO_HAKI", "Auto Observation", Config.AUTO_HAKI, 4)
        local sec2 = UI:Section(tab, "Teleports", 2)
        UI:Button(tab, sec2, "Teleport Sea 1", function()
            pcall(function() Main.teleportToCFrame(CFrame.new(-786,28,-1286)) end) end, 1)
        UI:Button(tab, sec2, "Teleport Sea 2", function()
            pcall(function() Main.teleportToCFrame(CFrame.new(9572,26,1543)) end) end, 2)
        UI:Button(tab, sec2, "Teleport Sea 3", function()
            pcall(function() Main.teleportToCFrame(CFrame.new(32290,28,8899)) end) end, 3)
        local sec3 = UI:Section(tab, "Save Data", 3)
        UI:Button(tab, sec3, "Save Config", function()
            if Config and Config.saveSettings then Config.saveSettings()
                UI:CreateNotification("Saved","Config saved",2,"success") end end, 1)
        UI:Button(tab, sec3, "Reset Stats", function()
            if Utils then Utils.resetStats()
                UI:CreateNotification("Reset","Stats cleared",2,"info") end end, 2)
        UI:Button(tab, sec3, "Clear Key", function()
            if Utils then Utils.clearKey()
                UI:CreateNotification("Cleared","Key removed",2,"info") end end, 3)
        local sec4 = UI:Section(tab, "Hub", 4)
        UI:Button(tab, sec4, "Destroy UI", function()
            if Main then Main.stop() end
            if UI then UI:Cleanup() end
            getgenv()._DeniaUI=nil; getgenv()._DeniaMain=nil
            getgenv()._DeniaConfig=nil; getgenv()._DeniaUtils=nil; getgenv()._DeniaAuth=nil
        end, 1)
        UI:Label(tab, sec4, ("Uptime: "..Utils.formatTime(os.time()-DeniaHub.START_TIME)),2,UI.Library.Theme.AccentLight)
        UI:SelectTab(tab)
    end

    function DeniaHub.createStatsTab(UI, Config, Utils, Main)
        local tab = UI.Tabs[5]
        local stats = Utils.loadStats()
        local sec = UI:Section(tab, "Session Statistics", 1)
        UI:Label(tab, sec, ("Total Bounty: "..Utils.formatNumber(stats.totalBountyGained or 0)),1,UI.Library.Theme.AccentLight)
        UI:Label(tab, sec, ("Total Kills: "..(stats.totalKills or 0)),2)
        UI:Label(tab, sec, ("Hopped: "..(stats.serversHopped or 0)),3)
        UI:Label(tab, sec, ("Auto Hops: "..(stats.autoServersHopped or 0)),4)
        UI:Label(tab, sec, ("Play Time: "..Utils.formatTime(stats.totalPlayTime or 0)),5)
        UI:Separator(tab, sec, 6)
        UI:Label(tab, sec, ("Session Bounty: "..Utils.formatNumber(stats.sessionBounty or 0)),7)
        UI:Label(tab, sec, ("Session Kills: "..(stats.sessionKills or 0)),8)
        UI:Label(tab, sec, ("Started: "..os.date("%c",stats.sessionStartTime or os.time())),9,UI.Library.Theme.TextDim)
        UI:Button(tab, sec, "Refresh Stats", function()
            tab.Container:ClearAllChildren(); tab.Sections = {}
            DeniaHub.createStatsTab(UI,Config,Utils,Main)
        end, 10)
        UI:SelectTab(tab)
    end

    function DeniaHub.init()
        local Utils = _modules["utils"]()
        getgenv()._DeniaUtils = Utils
        Utils.logDebug(Utils.DEBUG_LEVELS.INFO, "Boot", "Utils v"..DeniaHub.VERSION)
        local Config = _modules["config"]()
        getgenv()._DeniaConfig = Config
        Config.init()
        Utils.logDebug(Utils.DEBUG_LEVELS.INFO, "Boot", "Config loaded")
        local Auth = _modules["auth"]()
        getgenv()._DeniaAuth = Auth
        local UI = _modules["ui"]()
        getgenv()._DeniaUI = UI
        UI:Init()
        UI:CreateNotification("DeniaHub v"..DeniaHub.VERSION,"Welcome "..lp.Name.."!",3,"success")
        local Main = _modules["main"]()
        getgenv()._DeniaMain = Main
        DeniaHub.createTabs(UI,Config,Utils)
        DeniaHub.createMainTab(UI,Config,Utils,Main)
        DeniaHub.createCombatTab(UI,Config,Utils,Main)
        DeniaHub.createFarmingTab(UI,Config,Utils,Main)
        DeniaHub.createMiscTab(UI,Config,Utils,Main)
        DeniaHub.createStatsTab(UI,Config,Utils,Main)
        Main.init()
        DeniaHub.Loaded = true
        Utils.logDebug(Utils.DEBUG_LEVELS.INFO,"Boot","DeniaHub v"..DeniaHub.VERSION.." ready")
        if lp.Character then task.wait(0.5); UI:CreateNotification("Ready","All systems operational",2,"success") end
        lp.CharacterAdded:Connect(function()
            task.wait(1)
            if UI and UI.CreateNotification then UI:CreateNotification("Respawned","Character detected",2,"info") end
        end)
    end

    DeniaHub.init()
    return DeniaHub
end

local ok, mod = pcall(function() return _modules["boot"]() end)
getgenv().DeniaHub = ok and mod or nil
if ok then print("DeniaHub v1.0 - Loaded") else warn("DeniaHub failed:", mod) end

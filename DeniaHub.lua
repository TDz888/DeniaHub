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
    UI.LoadingScreen = nil
    UI.LoadingInstances = {}
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
        New("TextLabel", {Name="SectionTitle", Parent=headerBar, Size=UDim2.new(1,-50,1,0),
            Position=UDim2.new(0,14,0,0), BackgroundTransparency=1, Text=name,
            TextColor3=T.Theme.AccentLight, FontFace=T.FontBold, TextSize=16,
            TextXAlignment=Enum.TextXAlignment.Left})

        local sectionCollapsed = false
        local collapseBtn = New("TextButton", {Name="CollapseBtn", Parent=headerBar,
            Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,-36,0.5,-14),
            BackgroundTransparency=1, Text="?",
            TextColor3=T.Theme.Accent, FontFace=T.Font, TextSize=18, BorderSizePixel=0,
            AutoButtonColor=false})
        collapseBtn.MouseButton1Click:Connect(function()
            sectionCollapsed = not sectionCollapsed
            collapseBtn.Text = sectionCollapsed and "+" or "−"
            local targetH = sectionCollapsed and 0 or (totalContentH > 0 and totalContentH or calcContentHeight())
            tweenObject(sectionContent, {Size=UDim2.new(1,0,0,targetH)}, 0.25):Play()
            if sectionCollapsed then
                tweenObject(sectionContent, {BackgroundTransparency=0.5}, 0.2):Play()
            else
                tweenObject(sectionContent, {BackgroundTransparency=0}, 0.2):Play()
            end
            sectionContent.Visible = not sectionCollapsed
            updateSize()
        end)

        local sectionContent = New("Frame", {Name="SectionContent", Parent=sectionFrame,
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,36), BackgroundTransparency=1})
        New("UIPadding", {Parent=sectionContent, PaddingTop=UDim.new(0,4),
            PaddingBottom=UDim.new(0,8), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)})
        local sectionLayout = New("UIListLayout", {Parent=sectionContent, Padding=UDim.new(0,6),
            SortOrder=Enum.SortOrder.LayoutOrder})

        local sectionData={Frame=sectionFrame, Header=headerBar, Content=sectionContent,
            Layout=sectionLayout, Elements={}}
        local totalContentH = 0
        local function calcContentHeight()
            local h = 0
            for _,child in ipairs(sectionContent:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible then h = h + child.AbsoluteSize.Y + 6 end
            end
            return h
        end
        local function updateSize()
            if sectionCollapsed then
                sectionFrame.Size=UDim2.new(1,0,0,38)
                return
            end
            local h = 38 + calcContentHeight()
            sectionFrame.Size=UDim2.new(1,0,0,h)
        end
        local contentSizeConn = sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            totalContentH = sectionLayout.AbsoluteContentSize.Y
            updateSize()
        end)
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
        local searchQuery = ""
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
            TextColor3=T.Theme.Accent, FontFace=T.Font, TextSize=14,
            TextXAlignment=Enum.TextXAlignment.Center})

        local dropdownFrame = New("Frame", {Name="DropdownList", Parent=row,
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,62),
            BackgroundColor3=T.Theme.DropdownBg, BorderSizePixel=0, ClipsDescendants=true,
            Visible=false, ZIndex=20})
        AddCorner(dropdownFrame, T.DropdownRadius)
        AddStroke(dropdownFrame, T.Theme.Border, 1, 0.5)

        local searchBox = New("TextBox", {Name="SearchBox", Parent=dropdownFrame,
            Size=UDim2.new(1,-8,0,30), Position=UDim2.new(0,4,0,4),
            BackgroundColor3=T.Theme.InputBg, Text="", TextColor3=T.Theme.TextBright,
            PlaceholderText="Search...", PlaceholderColor3=T.Theme.TextDim,
            FontFace=T.Font, TextSize=13, BorderSizePixel=0, ClearTextOnFocus=false,
            ZIndex=21, Visible=false})
        AddCorner(searchBox, T.BadgeRadius)
        AddStroke(searchBox, T.Theme.Border, 1, 0.5)

        local listScroll = New("ScrollingFrame", {Name="ListScroll", Parent=dropdownFrame,
            Size=UDim2.new(1,-8,0,0), Position=UDim2.new(0,4,0,38),
            BackgroundTransparency=1, ScrollBarThickness=3, BorderSizePixel=0,
            ScrollBarImageColor3=T.Theme.ScrollBar, CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y})
        local listLayout = New("UIListLayout", {Parent=listScroll, Padding=UDim.new(0,2),
            SortOrder=Enum.SortOrder.LayoutOrder})

        local function populateList(filter)
            filter = filter or ""
            for _,child in ipairs(listScroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            local filtered = {}
            for _,opt in ipairs(options) do
                if filter=="" or opt:lower():find(filter:lower(),1,true) then
                    table.insert(filtered, opt)
                end
            end
            for _,opt in ipairs(filtered) do
                local optBtn = New("TextButton", {Name=opt, Parent=listScroll,
                    Size=UDim2.new(1,0,0,30),
                    BackgroundColor3=(opt==selected) and T.Theme.DropdownHover or T.Theme.DropdownItem,
                    Text=opt, TextColor3=(opt==selected) and T.Theme.AccentLight or T.Theme.Text,
                    FontFace=T.Font, TextSize=13, BorderSizePixel=0, AutoButtonColor=false})
                AddCorner(optBtn, T.BadgeRadius)
                optBtn.MouseButton1Click:Connect(function()
                    selected=opt; dropdownBtn.Text=opt
                    local wasVis=dropdownFrame.Visible
                    dropdownFrame.Visible=false; searchBox.Visible=false
                    tweenObject(dropdownFrame,{Size=UDim2.new(1,0,0,0)},0.15):Play()
                    if getgenv()._DeniaConfig then
                        getgenv()._DeniaConfig[configKey]=opt
                        if getgenv()._DeniaConfig.saveSettings then getgenv()._DeniaConfig.saveSettings() end
                    end
                    if wasVis then populateList(searchQuery) end
                end)
                optBtn.MouseEnter:Connect(function() tweenObject(optBtn,{BackgroundColor3=T.Theme.DropdownHover},0.1):Play() end)
                optBtn.MouseLeave:Connect(function() tweenObject(optBtn,{BackgroundColor3=(opt==selected) and T.Theme.DropdownHover or T.Theme.DropdownItem},0.15):Play() end)
            end
            local count = #filtered
            local listHeight = math.min(count*32, 200)
            listScroll.Size = UDim2.new(1,0,0,listHeight)
            local totalH = 42 + listHeight
            dropdownFrame.Size = dropdownFrame.Visible and UDim2.new(1,0,0,totalH) or UDim2.new(1,0,0,0)
        end

        searchBox.FocusLost:Connect(function()
            task.wait(0.1)
        end)
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            searchQuery = searchBox.Text
            populateList(searchQuery)
        end)

        dropdownBtn.MouseButton1Click:Connect(function()
            local newVis=not dropdownFrame.Visible; dropdownFrame.Visible=newVis
            searchBox.Visible = newVis
            if newVis then
                dropdownFrame.ZIndex=50; searchBox.ZIndex=51
                searchBox.Text = ""; searchQuery = ""
                searchBox:CaptureFocus()
                populateList("")
            else
                searchBox.Visible=false
                tweenObject(dropdownFrame,{Size=UDim2.new(1,0,0,0)},0.15):Play()
            end
        end)

        UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                local pos=UserInputService.GetMouseLocation and UserInputService:GetMouseLocation() or Vector2.new(0,0)
                local absPos=dropdownFrame.AbsolutePosition; local absSize=dropdownFrame.AbsoluteSize
                local rowAbs=row.AbsolutePosition; local rowSize=row.AbsoluteSize
                local inRow=pos.X>=rowAbs.X and pos.X<=rowAbs.X+rowSize.X and pos.Y>=rowAbs.Y and pos.Y<=rowAbs.Y+rowSize.Y
                local inDropdown=dropdownFrame.Visible and pos.X>=absPos.X and pos.X<=absPos.X+absSize.X and pos.Y>=absPos.Y and pos.Y<=absPos.Y+absSize.Y
                if not inRow and not inDropdown and dropdownFrame.Visible then
                    dropdownFrame.Visible=false; searchBox.Visible=false
                    tweenObject(dropdownFrame,{Size=UDim2.new(1,0,0,0)},0.15):Play()
                end
            end
        end)

        row._setValue=function(val) selected=val; dropdownBtn.Text=val; populateList(searchQuery) end
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

    function UI:CreateLoadingScreen()
        local sg = Instance.new("ScreenGui")
        sg.Name = "DeniaLoading"
        sg.Parent = lp:WaitForChild("PlayerGui")
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        sg.DisplayOrder = 9999
        sg.IgnoreGuiInset = true
        table.insert(UI.LoadingInstances, sg)

        local bg = New("Frame", {Parent=sg, Size=UDim2.new(1,0,1,0),
            BackgroundColor3=Color3.fromRGB(18,42,24), BorderSizePixel=0})
        table.insert(UI.LoadingInstances, bg)

        local container = New("Frame", {Parent=bg, Size=UDim2.new(0,420,0,340),
            Position=UDim2.new(0.5,-210,0.5,-170), BackgroundColor3=T.Theme.Surface,
            BorderSizePixel=0, ClipsDescendants=true})
        AddCorner(container, UDim.new(0,18))
        AddStroke(container, T.Theme.Accent, 1.5, 0.3)
        table.insert(UI.LoadingInstances, container)

        local logo = New("TextLabel", {Parent=container, Size=UDim2.new(1,0,0,60),
            Position=UDim2.new(0,0,0,40), BackgroundTransparency=1,
            Text="DeniaHub", TextColor3=T.Theme.AccentLight,
            FontFace=T.FontBold, TextSize=42, TextXAlignment=Enum.TextXAlignment.Center})
        table.insert(UI.LoadingInstances, logo)

        local subText = New("TextLabel", {Parent=container, Size=UDim2.new(1,0,0,24),
            Position=UDim2.new(0,0,0,100), BackgroundTransparency=1,
            Text="Blox Fruits Script v3.0", TextColor3=T.Theme.TextDim,
            FontFace=T.Font, TextSize=16, TextXAlignment=Enum.TextXAlignment.Center})
        table.insert(UI.LoadingInstances, subText)

        local barBg = New("Frame", {Parent=container, Size=UDim2.new(0,320,0,10),
            Position=UDim2.new(0.5,-160,0,180), BackgroundColor3=T.Theme.SliderRail,
            BorderSizePixel=0})
        AddCorner(barBg, UDim.new(0,5))
        table.insert(UI.LoadingInstances, barBg)

        local barFill = New("Frame", {Parent=barBg, Size=UDim2.new(0,0,1,0),
            BackgroundColor3=T.Theme.Accent, BorderSizePixel=0})
        AddCorner(barFill, UDim.new(0,5))
        UI.LoadingBar = barFill
        table.insert(UI.LoadingInstances, barFill)

        local statusText = New("TextLabel", {Parent=container, Size=UDim2.new(1,0,0,20),
            Position=UDim2.new(0,0,0,210), BackgroundTransparency=1,
            Text="Initializing...", TextColor3=T.Theme.Text,
            FontFace=T.Font, TextSize=13, TextXAlignment=Enum.TextXAlignment.Center})
        UI.LoadingStatus = statusText
        table.insert(UI.LoadingInstances, statusText)

        local pulse = New("Frame", {Parent=container, Size=UDim2.new(0,16,0,16),
            Position=UDim2.new(0.5,-8,0,250), BackgroundColor3=T.Theme.Accent,
            BorderSizePixel=0})
        AddCorner(pulse, UDim.new(1,0))
        table.insert(UI.LoadingInstances, pulse)
        TweenService:Create(pulse, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), {
            ImageTransparency=0.8, Size=UDim2.new(0,24,0,24), Position=UDim2.new(0.5,-12,0,246)
        }):Play()

        local dots = {""}
        local dotConn
        dotConn = RunService.Heartbeat:Connect(function()
            if not statusText or not statusText.Parent then if dotConn then dotConn:Disconnect() end return end
            local txt = statusText.Text
            local base = txt:match("^(.-)%.*$") or txt:match("^(.-)%.*%.*$") or txt:gsub("%.+$","")
            dots[1] = (#dots[1] >= 3) and "" or dots[1].."."
            statusText.Text = base..dots[1]
        end)
        table.insert(cleanupFuncs, dotConn)

        UI.LoadingScreen = container
        return container
    end

    function UI:UpdateLoadingProgress(text, progress)
        if UI.LoadingBar then
            tweenObject(UI.LoadingBar, {Size=UDim2.new(progress,0,1,0)}, 0.3):Play()
        end
        if UI.LoadingStatus then
            UI.LoadingStatus.Text = text or "Loading..."
        end
    end

    function UI:HideLoadingScreen()
        if UI.LoadingScreen then
            tweenObject(UI.LoadingScreen.Parent, {BackgroundTransparency=1}, 0.4, Enum.EasingStyle.Quart):Play()
            tweenObject(UI.LoadingScreen, {BackgroundTransparency=0.5, Size=UDim2.new(0,380,0,300)}, 0.4, Enum.EasingStyle.Quart):Play()
            task.wait(0.5)
            for _, inst in ipairs(UI.LoadingInstances) do
                pcall(function() inst:Destroy() end)
            end
            UI.LoadingInstances = {}
            UI.LoadingScreen = nil
            UI.LoadingBar = nil
            UI.LoadingStatus = nil
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
    local UIS = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Workspace = game:GetService("Workspace")
    local CoreGui = game:GetService("CoreGui")
    local lp = Players.LocalPlayer
    local Config = getgenv()._DeniaConfig
    local Utils = getgenv()._DeniaUtils
    local UI = getgenv()._DeniaUI

    Main.Running = false; Main.Paused = false
    Main.CurrentTargetPlayer = nil
    Main._instaTpConnection = nil
    Main._antiSeatConnection = nil; Main._antiSeatConnection2 = nil
    Main._lastBusoTime = 0; Main._lastKenTime = 0; Main._lastV4Time = 0
    Main._lastPvPTime = 0; Main._lastDragonCheck = 0; Main._hopping = false
    Main._prevBounty = 0; Main._sessionKills = 0; Main._sessionBounty = 0
    Main._playerPosHistory = {}; Main._deathConnected = false
    Main.LoopConnections = {}; Main.SkillCooldowns = {}

    local MIN_PLAYER_LEVEL = 2300; local PREDICTION_TIME = 0.25; local Y_OFFSET = 1
    local FRUIT_ATTACK_RANGE = 100; local LOW_HEALTH = 5000; local SAFE_HEALTH = 9000
    local ESCAPE_HEIGHT = 273861; local PREDICTION_SAMPLES = 3
    local BUSO_INT = 5; local KEN_INT = 8; local PVP_INT = 15

    local FruitConfigs = {
        Dragon={T="Dragon-Dragon",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        ["T-Rex"]={T="T-Rex-T-Rex",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),3}end},
        Kitsune={T="Kitsune-Kitsune",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Flame={T="Flame-Flame",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Ice={T="Ice-Ice",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Dark={T="Dark-Dark",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Light={T="Light-Light",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Magma={T="Magma-Magma",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Buddha={T="Buddha-Buddha",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Portal={T="Portal-Portal",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Dough={T="Dough-Dough",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Venom={T="Venom-Venom",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Leopard={T="Leopard-Leopard",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Mammoth={T="Mammoth-Mammoth",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Yeti={T="Yeti-Yeti",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Gas={T="Gas-Gas",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
        Kitsune={T="Kitsune-Kitsune",R="LeftClickRemote",A=function(d)return{Vector3.new(d.X,d.Y,d.Z),1}end},
    }

    function Main.gC()
        local c=lp.Character
        if not c or not c:FindFirstChild("HumanoidRootPart") then local ok,cc=pcall(function()return lp.CharacterAdded:Wait(5)end); if ok and cc then c=cc end end
        return c
    end
    function Main.hrp()local c=Main.gC();return c and c:FindFirstChild("HumanoidRootPart")end
    function Main.hum()local c=Main.gC();return c and(c:FindFirstChild("Humanoid")or c:FindFirstChild("HumanoidOfLocal"))end
    function Main.pos()local h=Main.hrp();return h and h.Position or Vector3.new(0,0,0)end
    function Main.tp(cf)local h=Main.hrp();if h then h.CFrame=cf end end
    function Main.dist(p)return(Main.pos()-p).Magnitude end

    function Main.bounty(p)
        local ls=p:FindFirstChild("leaderstats")
        if ls then local b=ls:FindFirstChild("Bounty/Honor");if b then return tonumber(b.Value)or 0 end end
        return 0
    end

    function Main.lvl(p)
        local d=p:FindFirstChild("Data")
        if d then local l=d:FindFirstChild("Level");if l then return tonumber(l.Value)or 0 end end
        return 0
    end

    function Main.hp(p)
        local c=p.Character
        if c then local h=c:FindFirstChild("Humanoid");if h then return h.Health,h.MaxHealth end end
        return 0,100
    end

    function Main.safeZone(p)
        if not p or not p.Character then return false end
        local h=p.Character:FindFirstChild("HumanoidRootPart")if not h then return false end
        local wz=Workspace:FindFirstChild("_WorldOrigin")if not wz then return false end
        local sz=wz:FindFirstChild("SafeZones")if not sz then return false end
        for _,z in pairs(sz:GetChildren())do
            local m=z:FindFirstChild("Mesh")
            if m and m:IsA("SpecialMesh")then
                local r=(z.Size.X*m.Scale.X)/2
                if(z.Position-h.Position).Magnitude<=r then return true end
            end
        end
        return false
    end

    function Main.valid(p)
        if p==lp then return false end
        if not p.Character then return false end
        local h=p.Character:FindFirstChild("Humanoid")if not h or h.Health<=0 then return false end
        if not p.Character:FindFirstChild("HumanoidRootPart")then return false end
        if Main.lvl(p)<MIN_PLAYER_LEVEL then return false end
        if Main.safeZone(p)then return false end
        if p:GetAttribute("PvpDisabled")==true then return false end
        if p:GetAttribute("IslandRaiding")==true then return false end
        return true
    end

    function Main.getTargets()
        local v={}
        for _,p in pairs(Players:GetPlayers())do
            if Main.valid(p)then
                local n=p.Name:lower();local matched=false
                if Config.WHITELIST_MODE=="Whitelist"then
                    for _,bn in ipairs(Config.BUDDY_LIST or {})do if n==bn:lower()then matched=true;break end end
                    if matched then table.insert(v,p)end
                else
                    for _,bn in ipairs(Config.BUDDY_LIST or {})do if n==bn:lower()then matched=true;break end end
                    if not matched then table.insert(v,p)end
                end
            end
        end
        return v
    end

    function Main.PvP()pcall(function()ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("CommF_"):InvokeServer("EnablePvp")end)end

    function Main.Buso()
        local n=tick()
        pcall(function()
            if n-Main._lastKenTime>=KEN_INT then ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("CommE"):FireServer("Ken",true);Main._lastKenTime=n end
            if n-Main._lastBusoTime>=BUSO_INT then
                local c=Main.gC()
                if c and not c:FindFirstChild("HasBuso")then ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("CommF_"):InvokeServer("Buso")end
                Main._lastBusoTime=n
            end
        end)
    end

    function Main.Dragon()
        if Config.FRUIT~="Dragon"then return end
        pcall(function()
            local c=Main.gC()if not c then return end
            if c:FindFirstChild("DragonHybrid")then return end
            local r=c:FindFirstChild("Rage")if not r or not r:IsA("NumberValue")then return end
            if r.Value>50 then VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.V,false,game)task.wait(0.05)VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.V,false,game)end
        end)
    end

    function Main.eqFruit()
        local cfg=FruitConfigs[Config.FRUIT]if not cfg then return false end
        local c=Main.gC()if not c then return false end
        if c:FindFirstChild(cfg.T)then return true end
        local bp=lp:FindFirstChild("Backpack")
        if bp then
            local t=bp:FindFirstChild(cfg.T)
            if t then local h=Main.hum()if h then h:EquipTool(t)task.wait(0.1)return true end end
        end
        return false
    end

    function Main.fruitAtk()
        local cfg=FruitConfigs[Config.FRUIT]if not cfg then return end
        local c=Main.gC()if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart")if not h then return end
        local t=Main.CurrentTargetPlayer if not t or not t.Character then return end
        local th=t.Character:FindFirstChild("HumanoidRootPart")if not th then return end
        if(th.Position-h.Position).Magnitude>FRUIT_ATTACK_RANGE then return end
        local tool=c:FindFirstChild(cfg.T)
        if not tool then if not Main.eqFruit()then return end;tool=c:FindFirstChild(cfg.T)if not tool then return end end
        local r=tool:FindFirstChild(cfg.R)if not r then return end
        pcall(function()local d=(th.Position-h.Position).Unit;r:FireServer(unpack(cfg.A(d)))end)
    end
    function Main.startTP()
        if Main._instaTpConnection then Main._instaTpConnection:Disconnect()end
        Main._instaTpConnection=RunService.Stepped:Connect(function()
            local t=Main.CurrentTargetPlayer if not t or not t.Character then return end
            pcall(function()
                local c=Main.gC()local th=t.Character:FindFirstChild("HumanoidRootPart")local h=c and c:FindFirstChild("HumanoidRootPart")
                if not h or not th then return end
                local tn=t.Name
                if not Main._playerPosHistory[tn]then Main._playerPosHistory[tn]={p={},t={}}end
                local hist=Main._playerPosHistory[tn];local n=tick();local cp=th.Position
                table.insert(hist.p,cp);table.insert(hist.t,n)
                while #hist.p>PREDICTION_SAMPLES do table.remove(hist.p,1);table.remove(hist.t,1)end
                local pp=cp
                if #hist.p>=2 then
                    local td=Vector3.new(0,0,0);local tt=0
                    for i=2,#hist.p do
                        local d=hist.p[i]-hist.p[i-1];local dt=hist.t[i]-hist.t[i-1]
                        if dt>0 then td=td+d;tt=tt+dt end
                    end
                    if tt>0 then pp=cp+(td/tt)*PREDICTION_TIME end
                end
                h.CFrame=CFrame.new(pp)*CFrame.new(0,Y_OFFSET,0)
            end)
        end)
    end

    function Main.healthEsc()
        if Main._instaTpConnection then Main._instaTpConnection:Disconnect()Main._instaTpConnection=nil end
        task.spawn(function()
            local a=true
            while a do
                pcall(function()local c=Main.gC()if c then local h=c:FindFirstChild("HumanoidRootPart")if h then h.CFrame=CFrame.new(h.Position.X,h.Position.Y+ESCAPE_HEIGHT,h.Position.Z)end end end)
                task.wait(0.05)
            end
        end)
        while true do task.wait(0.5)local h=Main.hum()if h and h.Health>=SAFE_HEALTH then break end end
        task.wait(0.2);Main.startTP()
    end

    function Main.lowHP()local h=Main.hum()return h and h.Health<=LOW_HEALTH or false end
    function Main.dead()local c=Main.gC()if not c then return false end;local h=c:FindFirstChild("Humanoid")if h and h.Health<=0 then return true end;local be=c:FindFirstChild("BodyEffects")if be then local d=be:FindFirstChild("Dead")if d and d.Value then return true end end;return false end

    function Main.antiSeat()
        if Main._antiSeatConnection then Main._antiSeatConnection:Disconnect()end
        if Main._antiSeatConnection2 then Main._antiSeatConnection2:Disconnect()end
        local c=Main.gC()if not c then return end;local h=c:FindFirstChild("Humanoid")if not h then return end
        Main._antiSeatConnection=RunService.Heartbeat:Connect(function()if h.Sit then h.Sit=false;h:ChangeState(Enum.HumanoidStateType.Jumping)end end)
        Main._antiSeatConnection2=h.StateChanged:Connect(function(_,n)if n==Enum.HumanoidStateType.Seated then h.Sit=false;h:ChangeState(Enum.HumanoidStateType.Jumping)end end)
    end

    function Main.onDeath()
        if Main._instaTpConnection then Main._instaTpConnection:Disconnect()Main._instaTpConnection=nil end
        if Main._antiSeatConnection then Main._antiSeatConnection:Disconnect()Main._antiSeatConnection=nil end
        if Main._antiSeatConnection2 then Main._antiSeatConnection2:Disconnect()Main._antiSeatConnection2=nil end
        Main.CurrentTargetPlayer=nil;Main._playerPosHistory={}
        if Utils then Utils.flushStats()end
        local nc=lp.Character or lp.CharacterAdded:Wait(10)
        if nc then local nh=nc:WaitForChild("HumanoidRootPart",10);local nu=nc:WaitForChild("Humanoid",10)
            if nh and nu then task.wait(1);Main.antiSeat();Main.startTP()
                if not Main._deathConnected then nu.Died:Connect(function()Main.onDeath()end);Main._deathConnected=true end end end
    end

    function Main.serverHop()
        if Main._hopping then return end;Main._hopping=true
        pcall(function()if Utils then Utils.incrementServerHops()end end)
        if Main._instaTpConnection then Main._instaTpConnection:Disconnect()Main._instaTpConnection=nil end
        Main._hopping=false
        local ht=Config.HOP_TYPE or "Hop"
        if ht=="Rejoin"then TeleportService:Teleport(game.PlaceId,lp)
        else
            local s,d=pcall(function()return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"))end)
            if s and d and d.data then local p={}for _,sv in ipairs(d.data)do if sv.playing<sv.maxPlayers and sv.id~=game.JobId then table.insert(p,sv.id)end end
                if #p>0 then TeleportService:TeleportToPlaceInstance(game.PlaceId,p[math.random(1,#p)],lp)end end
        end
        if Utils then Utils.flushStats()end
    end

    function Main.god()
        local c=Main.gC()if not c then return end
        local h=c:FindFirstChild("Humanoid")if h then h.MaxHealth=999999;h.Health=999999 end
        local be=c:FindFirstChild("BodyEffects")if be then local d=be:FindFirstChild("Dead")if d then d.Value=false end local he=be:FindFirstChild("Health")if he then he.Value=999999 end end
    end

    function Main.invis()
        local c=Main.gC()if not c then return end
        for _,p in ipairs(c:GetDescendants())do if p:IsA("BasePart")then p.Transparency=1 end end
        local h=Main.hum()if h then h.WalkSpeed=50 end
    end

    function Main.reset()local h=Main.hum()if h then h.Health=0 end end

    function Main.bring()
        if not Config.BRING_MOBS then return end
        local t=Main.CurrentTargetPlayer if not t or not t.Character then return end
        local th=t.Character:FindFirstChild("HumanoidRootPart")if not th then return end
        local tp=th.Position;local r=Config.BRING_RADIUS or 280;local m=Config.BRING_MODE or "Normal"
        for _,o in ipairs(Workspace:GetDescendants())do
            if o:IsA("Model")and o:FindFirstChild("Humanoid")and o:FindFirstChild("HumanoidRootPart")then
                local h=o.Humanoid;if h.Health>0 then
                    local np=o.HumanoidRootPart.Position
                    if(np-tp).Magnitude<=r then
                        local np2=tp+Vector3.new(math.random(-8,8),0,math.random(-8,8))
                        if m=="Fast"then o.HumanoidRootPart.CFrame=CFrame.new(np2)else TweenService:Create(o.HumanoidRootPart,TweenInfo.new(0.5),{CFrame=CFrame.new(np2)}):Play()end end end end end
    end

    function Main.getNPC(r)
        local c=nil;local cd=math.huge;local mp=Main.pos()
        for _,o in ipairs(Workspace:GetDescendants())do
            if o:IsA("Model")and o:FindFirstChild("Humanoid")and o:FindFirstChild("HumanoidRootPart")then
                local h=o.Humanoid;if h.Health>0 then
                    local d=(o.HumanoidRootPart.Position-mp).Magnitude
                    if d<=(r or Config.TARGET_DISTANCE or 280)and d<cd then c=o;cd=d end end end end
        return c,cd
    end

    function Main.atkNPC(n)
        if not n or not n:FindFirstChild("HumanoidRootPart")then return end
        local nh=n.HumanoidRootPart;local d=Main.dist(nh.Position)
        if d>30 then Main.tp(CFrame.new(nh.Position+Vector3.new(math.random(-8,8),0,math.random(-8,8))))task.wait(0.05)end
        local h=Main.hrp()if not h then return end
        Main.tp(CFrame.new(nh.Position+(nh.Position-h.Position).Unit*8))
    end

    function Main.useSkill(sn,delay)
        delay=delay or 0.3;local n=tick()
        if Main.SkillCooldowns[sn]and(n-Main.SkillCooldowns[sn])<delay then return false end
        local c=Main.gC()if not c then return false end
        local tool=nil
        for _,ch in ipairs(c:GetChildren())do if ch:IsA("Tool")and(ch.Name:lower():find(sn:lower())or sn:lower():find(ch.Name:lower()))then tool=ch;break end end
        if not tool then
            local bp=lp:FindFirstChild("Backpack")
            if bp then for _,ch in ipairs(bp:GetChildren())do if ch:IsA("Tool")and(ch.Name:lower():find(sn:lower())or sn:lower():find(ch.Name:lower()))then tool=ch;break end end
                if tool then local h=Main.hum()if h then h:EquipTool(tool)task.wait(0.05)end end end
        end
        if not tool then return false end
        local r=tool:FindFirstChild("RemoteFunction")or tool:FindFirstChild("RemoteEvent")or tool:FindFirstChild("Activate")
        if r then pcall(function()if r:IsA("RemoteFunction")then r:InvokeServer()else r:FireServer()end end)
            Main.SkillCooldowns[sn]=n;return true end
        for _,ch in ipairs(tool:GetChildren())do if ch:IsA("RemoteFunction")or ch:IsA("RemoteEvent")then
            pcall(function()if ch:IsA("RemoteFunction")then ch:InvokeServer()else ch:FireServer()end end)
            Main.SkillCooldowns[sn]=n;return true end end
        return false
    end

    function Main.cycle()
        local v=Main.getTargets()if #v==0 then Main.CurrentTargetPlayer=nil;return end
        Main.CurrentTargetPlayer=v[math.random(1,#v)]
    end

    function Main.farmBounty()
        if Main.dead()then Main.Paused=true;task.wait(3);Main.Paused=false;return end
        if Main.lowHP()then Main.healthEsc();return end
        local v=Main.getTargets()
        if #v==0 then if Config.AUTO_HOP then Main.serverHop()end;return end
        if not Main.CurrentTargetPlayer or not Main.CurrentTargetPlayer.Character or not Main.CurrentTargetPlayer.Character:FindFirstChild("HumanoidRootPart")then Main.cycle()end
        if Main.CurrentTargetPlayer then Main.eqFruit()Main.fruitAtk()if Config.BRING_MOBS then Main.bring()end end
    end

    function Main.farmNPC()
        if Main.dead()then Main.Paused=true;task.wait(3);Main.Paused=false;return end
        local n=Main.getNPC(Config.TARGET_DISTANCE or 280)if not n then return end;Main.atkNPC(n)
    end

    function Main.bountyListen()
        pcall(function()
            local ls=lp:WaitForChild("leaderstats",5)if not ls then return end
            local bv=ls:FindFirstChild("Bounty/Honor")if not bv then return end
            Main._prevBounty=tonumber(bv.Value)or 0
            bv.Changed:Connect(function(nv)
                local nb=tonumber(nv)or 0;local g=nb-Main._prevBounty
                if g>0 then Main._sessionKills=Main._sessionKills+1;Main._sessionBounty=Main._sessionBounty+g
                    if Utils then Utils.updateStats(g,1)Utils.addKillFeedEntry({bounty=g,target=Main.CurrentTargetPlayer and Main.CurrentTargetPlayer.Name or "Unknown",time=os.time()})end
                    if Config.AUTO_HOP and Main._sessionKills>=4 then Main.serverHop()end end
                Main._prevBounty=nb
            end)
        end)
    end
    function Main.deathSetup()
        local function onChar(c)
            local h=c:WaitForChild("Humanoid",10)
            if h then h.Died:Connect(function()Main.onDeath()end);Main._deathConnected=true end
        end
        lp.CharacterAdded:Connect(onChar)
        if lp.Character then local h=lp.Character:FindFirstChild("Humanoid")if h then h.Died:Connect(function()Main.onDeath()end);Main._deathConnected=true end end
    end

    function Main.kickDetect()
        pcall(function()
            local po=CoreGui:FindFirstChild("RobloxPromptGui")
            if po then local po2=po:FindFirstChild("promptOverlay")
                if po2 then po2.ChildAdded:Connect(function(c)
                    if c.Name=='ErrorPrompt'then local ma=c:FindFirstChild('MessageArea')
                        if ma and ma:FindFirstChild("ErrorFrame")and not Main._hopping then TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,lp)end end
                end)end end
        end)
    end

    function Main.init()
        Config=getgenv()._DeniaConfig;Utils=getgenv()._DeniaUtils;UI=getgenv()._DeniaUI
        if not Config or not Utils or not UI then if Utils then Utils.logError("Missing deps","Main")end;return false end
        Main._prevBounty=Main.bounty(lp);Main.bountyListen();Main.deathSetup();Main.kickDetect();Main.Running=true

        local hb=RunService.Heartbeat:Connect(function()
            if not Main.Running or Main.Paused then return end
            pcall(function()
                if Config.AUTO_FARM_BOUNTY then Main.farmBounty()end
            end)
        end)
        table.insert(Main.LoopConnections,hb)

        local st=RunService.Stepped:Connect(function()
            if not Main.Running then return end
            pcall(function()
                if Config.AUTO_GODMODE then Main.god()end
                if Config.AUTO_INVIS then Main.invis()end
                if Config.AUTO_BUSO then pcall(function()local c=Main.gC()if c and not c:FindFirstChild("HasBuso")then ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("CommF_"):InvokeServer("Buso")end end)end
                if Config.AUTO_OBS then pcall(function()local d=lp:FindFirstChild("Data")if d then local o=d:FindFirstChild("Observation")if o and not o.Value then o.Value=true end end end)
                if Config.AUTO_FARM_LEVEL or Config.AUTO_FARM_MASTERY then Main.farmNPC()end
                if Config.AUTO_NPC then Main.farmNPC()end
                if Config.AUTO_ELITE then Main.farmNPC()end
                if Config.AUTO_CHEST then Main.farmNPC()end -- chest/elite simplified
            end)
        end)
        table.insert(Main.LoopConnections,st)

        local bu=RunService.Heartbeat:Connect(function()
            if not Main.Running then return end
            pcall(function()Main.Buso()Main.Dragon()
                if Config.ANTI_BAN then local c=Main.gC()if c and c:FindFirstChild("Humanoid")and not c:FindFirstChild("HumanoidOfLocal")then c.Humanoid.Name="HumanoidOfLocal"end end
            end)
        end)
        table.insert(Main.LoopConnections,bu)

        local pvp=RunService.Heartbeat:Connect(function()
            if not Main.Running then return end;local n=tick()
            if n-Main._lastPvPTime>=PVP_INT then Main._lastPvPTime=n;Main.PvP()end
        end)
        table.insert(Main.LoopConnections,pvp)

        Main.antiSeat();Main.startTP()
        if Utils then Utils.logDebug(Utils.DEBUG_LEVELS.INFO,"Main","v3.0 initialized")end
        return true
    end

    function Main.stop()
        Main.Running=false
        for _,c in ipairs(Main.LoopConnections)do pcall(function()c:Disconnect()end)end
        Main.LoopConnections={}
        if Main._instaTpConnection then Main._instaTpConnection:Disconnect()Main._instaTpConnection=nil end
        if Main._antiSeatConnection then Main._antiSeatConnection:Disconnect()Main._antiSeatConnection=nil end
        if Main._antiSeatConnection2 then Main._antiSeatConnection2:Disconnect()Main._antiSeatConnection2=nil end
        Main.CurrentTargetPlayer=nil;Main._playerPosHistory={}
        if Utils then Utils.flushStats();Utils.logDebug(Utils.DEBUG_LEVELS.INFO,"Main","Stopped")end
    end

    return Main
end
_modules["advanced"] = function()
    local Adv = {}
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Workspace = game:GetService("Workspace")
    local lp = Players.LocalPlayer

    Adv._cfController = nil
    Adv._namecallHookActive = false
    Adv._oldNamecall = nil
    Adv._aimTarget = nil
    Adv._espEnabled = false
    Adv._espObjs = {}
    Adv._espConn = nil
    Adv._simConn = nil
    Adv._fastAtkConn = nil
    Adv._killAuraConn = nil
    Adv._autoFarmConn = nil
    Adv._antiShakeDone = false
    Adv._bodyClip = nil
    Adv._questData = nil
    Adv._currentFarmTarget = nil
    Adv._fastAtkEnabled = false
    Adv._killAuraEnabled = false

    local PlaceId = game.PlaceId
    local World1, World2, World3 = 2753915549, 4442272183, 7449423635
    local CurrentSea = PlaceId == World1 and 1 or PlaceId == World2 and 2 or PlaceId == World3 and 3 or 0

    local QuestData = {
        [1] = {
            {min=1,max=9,mob="Bandit",npc="BanditQuest1",q="Bandit",npcCF=CFrame.new(1059,16,-1192),mobCF=CFrame.new(1038,17,-1248),a={"StartQuest","BanditQuest1",1}},
            {min=10,max=19,mob="Monkey",npc="JungleQuest",q="Monkey",npcCF=CFrame.new(-1601,36,-176),mobCF=CFrame.new(-1626,37,-196),a={"StartQuest","JungleQuest",1}},
            {min=20,max=29,mob="Gorilla",npc="JungleQuest",q="Gorilla",npcCF=CFrame.new(-1601,36,-176),mobCF=CFrame.new(-1556,39,-230),a={"StartQuest","JungleQuest",2}},
            {min=30,max=59,mob="Pirate",npc="BuggyQuest1",q="Pirate",npcCF=CFrame.new(-1139,5,-3925),mobCF=CFrame.new(-1165,5,-3930),a={"StartQuest","BuggyQuest1",1}},
            {min=60,max=89,mob="Brute",npc="BuggyQuest1",q="Brute",npcCF=CFrame.new(-1139,5,-3925),mobCF=CFrame.new(-1190,8,-3898),a={"StartQuest","BuggyQuest1",2}},
            {min=90,max=119,mob="Desert Bandit",npc="DesertQuest",q="DesertBandit",npcCF=CFrame.new(1063,7,-4283),mobCF=CFrame.new(1098,7,-4285),a={"StartQuest","DesertQuest",1}},
            {min=120,max=149,mob="Desert Officer",npc="DesertQuest",q="DesertOfficer",npcCF=CFrame.new(1063,7,-4283),mobCF=CFrame.new(1538,9,-4375),a={"StartQuest","DesertQuest",2}},
            {min=150,max=174,mob="Snow Bandit",npc="SnowQuest",q="SnowBandit",npcCF=CFrame.new(1398,12,-2970),mobCF=CFrame.new(1343,11,-2962),a={"StartQuest","SnowQuest",1}},
            {min=175,max=199,mob="Snowman",npc="SnowQuest",q="Snowman",npcCF=CFrame.new(1398,12,-2970),mobCF=CFrame.new(1229,17,-2992),a={"StartQuest","SnowQuest",2}},
            {min=200,max=224,mob="Chief Petty Officer",npc="MarineQuest2",q="Chief",npcCF=CFrame.new(-5035,19,-2732),mobCF=CFrame.new(-4889,22,-2789),a={"StartQuest","MarineQuest2",1}},
            {min=225,max=249,mob="Sky Bandit",npc="SkyQuest",q="SkyBandit",npcCF=CFrame.new(-4849,718,-2635),mobCF=CFrame.new(-4872,736,-2716),a={"StartQuest","SkyQuest",1}},
            {min=250,max=299,mob="Dark Master",npc="SkyQuest",q="DarkMaster",npcCF=CFrame.new(-4849,718,-2635),mobCF=CFrame.new(-5210,727,-3100),a={"StartQuest","SkyQuest",2}},
            {min=300,max=374,mob="Toga Warrior",npc="ColosseumQuest",q="Toga",npcCF=CFrame.new(-1429,7,-5190),mobCF=CFrame.new(-1571,8,-5251),a={"StartQuest","ColosseumQuest",1}},
            {min=375,max=449,mob="Gladiator",npc="ColosseumQuest",q="Gladiator",npcCF=CFrame.new(-1429,7,-5190),mobCF=CFrame.new(-1381,12,-5317),a={"StartQuest","ColosseumQuest",2}},
            {min=450,max=524,mob="Military Soldier",npc="MagmaQuest",q="Military",npcCF=CFrame.new(-5316,19,-1235),mobCF=CFrame.new(-5435,17,-1268),a={"StartQuest","MagmaQuest",1}},
            {min=525,max=599,mob="Military Spy",npc="MagmaQuest",q="Military2",npcCF=CFrame.new(-5316,19,-1235),mobCF=CFrame.new(-5784,17,-1239),a={"StartQuest","MagmaQuest",2}},
            {min=600,max=674,mob="Fishman Warrior",npc="FishmanQuest",q="Fishman",npcCF=CFrame.new(61123,18,1565),mobCF=CFrame.new(61210,16,1561),a={"StartQuest","FishmanQuest",1}},
            {min=675,max=749,mob="Fishman Commando",npc="FishmanQuest",q="Fishman2",npcCF=CFrame.new(61123,18,1565),mobCF=CFrame.new(61373,16,1533),a={"StartQuest","FishmanQuest",2}},
            {min=750,max=799,mob="God's Guard",npc="SkyExp1Quest",q="Guard",npcCF=CFrame.new(-4709,853,-3865),mobCF=CFrame.new(-4741,850,-3941),a={"StartQuest","SkyExp1Quest",1}},
            {min=800,max=874,mob="Shanda",npc="SkyExp1Quest",q="Shanda",npcCF=CFrame.new(-4709,853,-3865),mobCF=CFrame.new(-5221,854,-3942),a={"StartQuest","SkyExp1Quest",2}},
            {min=875,max=949,mob="Royal Squad",npc="SkyExp2Quest",q="Squad",npcCF=CFrame.new(-7907,555,-484),mobCF=CFrame.new(-7782,558,-473),a={"StartQuest","SkyExp2Quest",1}},
            {min=950,max=999,mob="Royal Soldier",npc="SkyExp2Quest",q="Soldier",npcCF=CFrame.new(-7907,555,-484),mobCF=CFrame.new(-7856,563,-479),a={"StartQuest","SkyExp2Quest",2}},
        },
        [2] = {
            {min=700,max=724,mob="Raider",npc="Area1Quest",q="Raider",npcCF=CFrame.new(-429,72,1836),mobCF=CFrame.new(-728,53,2346),a={"StartQuest","Area1Quest",1}},
            {min=725,max=774,mob="Mercenary",npc="Area1Quest",q="Mercenary",npcCF=CFrame.new(-429,72,1836),mobCF=CFrame.new(-1004,80,1425),a={"StartQuest","Area1Quest",2}},
            {min=775,max=799,mob="Swan Pirate",npc="Area2Quest",q="Swan",npcCF=CFrame.new(638,72,918),mobCF=CFrame.new(1069,138,1322),a={"StartQuest","Area2Quest",1}},
            {min=800,max=874,mob="Factory Staff",npc="Area2Quest",q="Staff",npcCF=CFrame.new(633,73,919),mobCF=CFrame.new(73,82,-27),a={"StartQuest","Area2Quest",2}},
            {min=875,max=899,mob="Marine Lieutenant",npc="MarineQuest3",q="Lieutenant",npcCF=CFrame.new(-2441,72,-3216),mobCF=CFrame.new(-2821,76,-3070),a={"StartQuest","MarineQuest3",1}},
            {min=900,max=949,mob="Marine Captain",npc="MarineQuest3",q="Captain",npcCF=CFrame.new(-2441,72,-3216),mobCF=CFrame.new(-1861,80,-3255),a={"StartQuest","MarineQuest3",2}},
            {min=950,max=974,mob="Zombie",npc="ZombieQuest",q="Zombie",npcCF=CFrame.new(-5497,48,-795),mobCF=CFrame.new(-5658,79,-929),a={"StartQuest","ZombieQuest",1}},
            {min=975,max=999,mob="Vampire",npc="ZombieQuest",q="Vampire",npcCF=CFrame.new(-5497,48,-795),mobCF=CFrame.new(-6038,32,-1341),a={"StartQuest","ZombieQuest",2}},
            {min=1000,max=1049,mob="Snow Trooper",npc="SnowMountainQuest",q="Trooper",npcCF=CFrame.new(610,400,-5372),mobCF=CFrame.new(549,427,-5564),a={"StartQuest","SnowMountainQuest",1}},
            {min=1050,max=1099,mob="Winter Warrior",npc="SnowMountainQuest",q="Warrior",npcCF=CFrame.new(610,400,-5372),mobCF=CFrame.new(1143,476,-5199),a={"StartQuest","SnowMountainQuest",2}},
            {min=1100,max=1124,mob="Lab Subordinate",npc="IceSideQuest",q="Subordinate",npcCF=CFrame.new(-6064,15,-4903),mobCF=CFrame.new(-5707,16,-4513),a={"StartQuest","IceSideQuest",1}},
            {min=1125,max=1174,mob="Horned Warrior",npc="IceSideQuest",q="Horned",npcCF=CFrame.new(-6064,15,-4903),mobCF=CFrame.new(-6341,16,-5723),a={"StartQuest","IceSideQuest",2}},
            {min=1175,max=1199,mob="Magma Ninja",npc="FireSideQuest",q="Ninja",npcCF=CFrame.new(-5428,15,-5299),mobCF=CFrame.new(-5450,77,-5808),a={"StartQuest","FireSideQuest",1}},
            {min=1200,max=1249,mob="Lava Pirate",npc="FireSideQuest",q="Lava",npcCF=CFrame.new(-5428,15,-5299),mobCF=CFrame.new(-5213,50,-4701),a={"StartQuest","FireSideQuest",2}},
            {min=1250,max=1274,mob="Ship Deckhand",npc="ShipQuest1",q="Deckhand",npcCF=CFrame.new(1038,125,32912),mobCF=CFrame.new(1212,151,33059),a={"StartQuest","ShipQuest1",1}},
            {min=1275,max=1299,mob="Ship Engineer",npc="ShipQuest1",q="Engineer",npcCF=CFrame.new(1038,125,32912),mobCF=CFrame.new(919,44,32780),a={"StartQuest","ShipQuest1",2}},
            {min=1300,max=1324,mob="Ship Steward",npc="ShipQuest2",q="Steward",npcCF=CFrame.new(969,125,33244),mobCF=CFrame.new(919,130,33436),a={"StartQuest","ShipQuest2",1}},
            {min=1325,max=1349,mob="Ship Officer",npc="ShipQuest2",q="Officer",npcCF=CFrame.new(969,125,33244),mobCF=CFrame.new(1036,181,33316),a={"StartQuest","ShipQuest2",2}},
            {min=1350,max=1374,mob="Arctic Warrior",npc="FrostQuest",q="Arctic",npcCF=CFrame.new(5668,27,-6486),mobCF=CFrame.new(5966,63,-6179),a={"StartQuest","FrostQuest",1}},
            {min=1375,max=1424,mob="Snow Lurker",npc="FrostQuest",q="Lurker",npcCF=CFrame.new(5668,27,-6486),mobCF=CFrame.new(5407,69,-6881),a={"StartQuest","FrostQuest",2}},
            {min=1425,max=1449,mob="Sea Soldier",npc="ForgottenQuest",q="Soldier",npcCF=CFrame.new(-3054,236,-10143),mobCF=CFrame.new(-3028,65,-9775),a={"StartQuest","ForgottenQuest",1}},
            {min=1450,max=1499,mob="Water Fighter",npc="ForgottenQuest",q="Fighter",npcCF=CFrame.new(-3054,236,-10143),mobCF=CFrame.new(-3291,252,-10501),a={"StartQuest","ForgottenQuest",2}},
        },
        [3] = {
            {min=1500,max=1524,mob="Pirate Millionaire",npc="PiratePortQuest",q="Millionaire",npcCF=CFrame.new(-290,43,5582),mobCF=CFrame.new(-246,47,5584),a={"StartQuest","PiratePortQuest",1}},
            {min=1525,max=1574,mob="Pistol Billionaire",npc="PiratePortQuest",q="Billionaire",npcCF=CFrame.new(-290,43,5582),mobCF=CFrame.new(-187,86,6014),a={"StartQuest","PiratePortQuest",2}},
            {min=1575,max=1599,mob="Dragon Crew Warrior",npc="DragonCrewQuest",q="Warrior",npcCF=CFrame.new(6739,128,-714),mobCF=CFrame.new(6921,56,-943),a={"StartQuest","DragonCrewQuest",1}},
            {min=1600,max=1624,mob="Dragon Crew Archer",npc="DragonCrewQuest",q="Archer",npcCF=CFrame.new(6739,128,-714),mobCF=CFrame.new(6818,485,513),a={"StartQuest","DragonCrewQuest",2}},
            {min=1625,max=1649,mob="Hydra Enforcer",npc="VenomCrewQuest",q="Enforcer",npcCF=CFrame.new(5214,1005,759),mobCF=CFrame.new(4585,1003,706),a={"StartQuest","VenomCrewQuest",1}},
            {min=1650,max=1699,mob="Venomous Assailant",npc="VenomCrewQuest",q="Assailant",npcCF=CFrame.new(5214,1005,759),mobCF=CFrame.new(4639,1079,882),a={"StartQuest","VenomCrewQuest",2}},
            {min=1700,max=1724,mob="Marine Commodore",npc="MarineTreeIsland",q="Commodore",npcCF=CFrame.new(2181,28,-6742),mobCF=CFrame.new(2286,73,-7160),a={"StartQuest","MarineTreeIsland",1}},
            {min=1725,max=1774,mob="Marine Rear Admiral",npc="MarineTreeIsland",q="Admiral",npcCF=CFrame.new(2181,29,-6740),mobCF=CFrame.new(3657,161,-7002),a={"StartQuest","MarineTreeIsland",2}},
            {min=1775,max=1799,mob="Fishman Raider",npc="DeepForestIsland3",q="Raider",npcCF=CFrame.new(-10581,331,-8761),mobCF=CFrame.new(-10594,332,-8786),a={"StartQuest","DeepForestIsland3",1}},
            {min=1800,max=1849,mob="Fishman Captain",npc="DeepForestIsland3",q="Captain",npcCF=CFrame.new(-10581,331,-8761),mobCF=CFrame.new(-10832,332,-8807),a={"StartQuest","DeepForestIsland3",2}},
            {min=1850,max=1899,mob="Ghost Pirate",npc="HauntedQuest1",q="Ghost",npcCF=CFrame.new(-9507,142,5561),mobCF=CFrame.new(-9496,140,5565),a={"StartQuest","HauntedQuest1",1}},
            {min=1900,max=1949,mob="Ghost Pirate Captain",npc="HauntedQuest1",q="GhostCaptain",npcCF=CFrame.new(-9507,142,5561),mobCF=CFrame.new(-9562,141,5549),a={"StartQuest","HauntedQuest1",2}},
            {min=1950,max=1999,mob="Elite Pirate",npc="HauntedQuest2",q="Elite",npcCF=CFrame.new(-9524,59,5490),mobCF=CFrame.new(-9526,62,5428),a={"StartQuest","HauntedQuest2",1}},
            {min=2000,max=2049,mob="Elite Pirate Captain",npc="HauntedQuest2",q="EliteCaptain",npcCF=CFrame.new(-9524,59,5490),mobCF=CFrame.new(-9520,55,5347),a={"StartQuest","HauntedQuest2",2}},
            {min=2050,max=2099,mob="Sea of Treats Crew",npc="CocoaWarriorsQuest",q="SeaCrew",npcCF=CFrame.new(-614,44,-10812),mobCF=CFrame.new(-723,49,-11003),a={"StartQuest","CocoaWarriorsQuest",1}},
            {min=2100,max=2149,mob="Cocoa Warrior",npc="CocoaWarriorsQuest",q="Cocoa",npcCF=CFrame.new(-614,44,-10812),mobCF=CFrame.new(-649,60,-11066),a={"StartQuest","CocoaWarriorsQuest",2}},
            {min=2150,max=2199,mob="Graham",npc="GrahamQuest",q="Graham",npcCF=CFrame.new(-926,44,-10870),mobCF=CFrame.new(-1053,45,-10980),a={"StartQuest","GrahamQuest",1}},
            {min=2200,max=2249,mob="The Son of Graham",npc="GrahamQuest",q="SonGraham",npcCF=CFrame.new(-926,44,-10870),mobCF=CFrame.new(-1118,55,-10964),a={"StartQuest","GrahamQuest",2}},
            {min=2250,max=2299,mob="Captain Elephant",npc="CrewQuest",q="Elephant",npcCF=CFrame.new(-13581,89,-12329),mobCF=CFrame.new(-13823,88,-12470),a={"StartQuest","CrewQuest",1}},
            {min=2300,max=2349,mob="Jaw Shield Pirate",npc="CrewQuest",q="Jaw",npcCF=CFrame.new(-13581,89,-12329),mobCF=CFrame.new(-13893,90,-12557),a={"StartQuest","CrewQuest",2}},
            {min=2350,max=2399,mob="Sailor",npc="MarineQuest4",q="Sailor",npcCF=CFrame.new(-13074,34,-13358),mobCF=CFrame.new(-13097,34,-13388),a={"StartQuest","MarineQuest4",1}},
            {min=2400,max=2449,mob="Marine Commando",npc="MarineQuest4",q="Commando",npcCF=CFrame.new(-13074,34,-13358),mobCF=CFrame.new(-13168,35,-13268),a={"StartQuest","MarineQuest4",2}},
            {min=2450,max=2499,mob="Reborn Skeleton",npc="CursedCrewQuest",q="Skeleton",npcCF=CFrame.new(-11999,121,-8791),mobCF=CFrame.new(-11830,122,-8693),a={"StartQuest","CursedCrewQuest",1}},
            {min=2500,max=2550,mob="Living Zombie",npc="CursedCrewQuest",q="Zombie",npcCF=CFrame.new(-11999,121,-8791),mobCF=CFrame.new(-11856,122,-8847),a={"StartQuest","CursedCrewQuest",2}},
        }
    }

    function Adv.getSea() return CurrentSea end

    function Adv.getQuestForLevel(lvl)
        local sq=QuestData[CurrentSea]
        if not sq then return nil end
        for _,q in ipairs(sq)do if lvl>=q.min and lvl<=q.max then return q end end
        return nil
    end

    function Adv.setupCombatFramework()
        pcall(function()
            local ps=lp:FindFirstChild("PlayerScripts")
            if not ps then return end
            local cf=ps:FindFirstChild("CombatFramework")
            if not cf then return end
            local req=require(cf)
            local up=getupvalues(req)
            for i,v in ipairs(up)do
                if type(v)=="table"and v.activeController then
                    Adv._cfController=v
                    v.activeController.hitboxMagnitude=200
                    v.activeController.focusStart=0
                    v.activeController.timeToNextBlock=0
                    v.activeController.timeToNextAttack=0
                    v.activeController.attacking=false
                    v.activeController.increment=1
                    break
                end
            end
        end)
    end

    function Adv.attack()
        if not Adv._cfController then Adv.setupCombatFramework()end
        if Adv._cfController and Adv._cfController.activeController then
            pcall(function()Adv._cfController.activeController:attack()end)
        end
    end

    function Adv.fastAttack()
        Adv.attack()
        pcall(function()
            local ps=lp:FindFirstChild("PlayerScripts")
            if not ps then return end
            local cf=ps:FindFirstChild("CombatFramework")
            if not cf then return end
            local req=require(cf)
            local up=getupvalues(req)
            for _,v in ipairs(up)do
                if type(v)=="table"and type(v.wrapAttackAnimationAsync)=="function"then
                    v.wrapAttackAnimationAsync=function(a,b,c,d)
                        local L=a;if type(L)=="table"and type(L.Play)=="function"then L:Play(0.001,0.001,0.001)end
                    end
                    break
                end
            end
        end)
    end

    function Adv.setupNamecall()
        if Adv._namecallHookActive then return end
        pcall(function()
            local mt=getrawmetatable(game)
            if not mt then return end
            Adv._oldNamecall=mt.__namecall
            setreadonly(mt,false)
            mt.__namecall=newcclosure(function(self,...)
                local method=getnamecallmethod()
                if method=="FireServer"and Adv._aimTarget then
                    local args={...}
                    if args[1]and type(args[1])=="Vector3"then
                        local tc=Adv._aimTarget.Character
                        if tc and tc:FindFirstChild("HumanoidRootPart")then
                            args[1]=tc.HumanoidRootPart.Position
                            return Adv._oldNamecall(self,unpack(args))
                        end
                    elseif args[1]and type(args[1])=="table"and type(args[1].Position)=="Vector3"then
                        local tc=Adv._aimTarget.Character
                        if tc and tc:FindFirstChild("HumanoidRootPart")then
                            args[1]=tc.HumanoidRootPart.Position
                            return Adv._oldNamecall(self,unpack(args))
                        end
                    end
                end
                return Adv._oldNamecall(self,...)
            end)
            setreadonly(mt,true)
            Adv._namecallHookActive=true
        end)
    end

    function Adv.setAim(p)Adv._aimTarget=p end
    function Adv.clearAim()Adv._aimTarget=nil end

    function Adv.setupSimRadius()
        if Adv._simConn then Adv._simConn:Disconnect()end
        Adv._simConn=RunService.RenderStepped:Connect(function()
            pcall(function()
                sethiddenproperty(lp,"SimulationRadius",math.huge)
                if lp.Character then sethiddenproperty(lp.Character,"SimulationRadius",math.huge)end
            end)
        end)
    end

    function Adv.noShake()
        if Adv._antiShakeDone then return end
        pcall(function()
            local util=ReplicatedStorage:FindFirstChild("Util")
            if util then
                local cs=util:FindFirstChild("CameraShaker")
                if cs then
                    local main=cs:FindFirstChild("Main")
                    if main then
                        local CS=require(main)
                        local noop=function()end
                        CS.StartShake=noop;CS.ShakeOnce=noop;CS.ShakeSustain=noop
                        CS.CameraShakeInstance=noop;CS.Shake=noop;CS.Start=noop
                        Adv._antiShakeDone=true
                    end
                end
            end
        end)
    end

    function Adv.bodyClip()
        local c=lp.Character
        if not c then return end
        local h=c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        if Adv._bodyClip and Adv._bodyClip.Parent then return end
        Adv._bodyClip=Instance.new("BodyVelocity")
        Adv._bodyClip.Name="DeniaClip"
        Adv._bodyClip.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
        Adv._bodyClip.Velocity=Vector3.new(0,0,0)
        Adv._bodyClip.Parent=h
    end

    function Adv.removeClip()
        if Adv._bodyClip then pcall(function()Adv._bodyClip:Destroy()end)Adv._bodyClip=nil end
    end

    Adv._autoStatConn = nil
    Adv._autoStatEnabled = false
    Adv._autoStatMode = "Melee"
    function Adv.enableAutoStat(mode)
        if Adv._autoStatEnabled then return end
        Adv._autoStatEnabled = true
        Adv._autoStatMode = mode or "Melee"
        Adv._autoStatConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local data = lp:FindFirstChild("Data")
                if not data then return end
                local points = data:FindFirstChild("Points")
                if not points or points.Value <= 0 then return end
                local statMap = {
                    Melee = "Combat",
                    Defense = "Defense",
                    Sword = "Sword",
                    Gun = "Gun",
                    DevilFruit = "Demon Fruit",
                }
                local statName = statMap[Adv._autoStatMode]
                if not statName then return end
                local remote = ReplicatedStorage:FindFirstChild("Remotes")
                if not remote then return end
                local commF = remote:FindFirstChild("CommF_")
                if not commF then return end
                commF:InvokeServer("AddPoint", statName, points.Value)
            end)
        end)
    end

    function Adv.disableAutoStat()
        Adv._autoStatEnabled = false
        if Adv._autoStatConn then Adv._autoStatConn:Disconnect() Adv._autoStatConn = nil end
    end

    Adv._fruitESPEnabled = false
    Adv._fruitESPObjs = {}
    Adv._fruitESPConn = nil
    function Adv.enableFruitESP(color)
        if Adv._fruitESPEnabled then Adv.disableFruitESP() end
        Adv._fruitESPEnabled = true
        color = color or Color3.fromRGB(255, 215, 0)
        Adv._fruitESPConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                for _, o in ipairs(Workspace:GetDescendants()) do
                    if o:IsA("Tool") and o:FindFirstChild("Handle") then
                        local fruitName = o.Name
                        local isFruit = fruitName:find("Fruit") or fruitName:find("fruit") or
                            fruitName:find("Apple") or fruitName:find("Banana") or
                            fruitName:find("Cherry") or fruitName:find("Diamond") or
                            fruitName:find("Dough") or fruitName:find("Dragon") or
                            fruitName:find("Flame") or fruitName:find("Gravity") or
                            fruitName:find("Ice") or fruitName:find("Light") or
                            fruitName:find("Love") or fruitName:find("Magma") or
                            fruitName:find("Pain") or fruitName:find("Phoenix") or
                            fruitName:find("Quake") or fruitName:find("Rumble") or
                            fruitName:find("Sand") or fruitName:find("Shadow") or
                            fruitName:find("Smoke") or fruitName:find("Snow") or
                            fruitName:find("Spider") or fruitName:find("Spirit") or
                            fruitName:find("Spring") or fruitName:find("Venom") or
                            fruitName:find("Dark") or fruitName:find("Bomb") or
                            fruitName:find("Barrier") or fruitName:find("Blizzard") or
                            fruitName:find("Buddha") or fruitName:find("Control") or
                            fruitName:find("Door") or fruitName:find("Falcon") or
                            fruitName:find("Ghost") or fruitName:find("Gum") or
                            fruitName:find("Human") or fruitName:find("Kilo") or
                            fruitName:find("Leopard") or fruitName:find("Magnet") or
                            fruitName:find("Revive") or fruitName:find("Rubber") or
                            fruitName:find("Spike") or fruitName:find("String")
                        if isFruit and not Adv._fruitESPObjs[o] then
                            local bg = Instance.new("BillboardGui")
                            bg.Name = "DeniaFruitESP"
                            bg.Adornee = o.Handle
                            bg.Size = UDim2.new(6, 0, 3, 0)
                            bg.AlwaysOnTop = true
                            bg.Enabled = true
                            local tl = Instance.new("TextLabel")
                            tl.Size = UDim2.new(1, 0, 1, 0)
                            tl.BackgroundTransparency = 1
                            tl.TextColor3 = color
                            tl.TextStrokeTransparency = 0.2
                            tl.Text = "[?] "..fruitName.." ??"
                            tl.Font = Enum.Font.GothamBold
                            tl.TextSize = 16
                            tl.Parent = bg
                            bg.Parent = lp:FindFirstChild("PlayerGui")

                            local box = Instance.new("BoxHandleAdornment")
                            box.Name = "DeniaFruitBox"
                            box.Adornee = o.Handle
                            box.Size = o.Handle.Size * 2
                            box.Color3 = color
                            box.Transparency = 0.4
                            box.Visible = true
                            box.AlwaysOnTop = true
                            box.ZIndex = 10
                            box.Parent = o.Handle

                            Adv._fruitESPObjs[o] = { bg = bg, box = box }
                        end
                    end
                end
                for obj, data in pairs(Adv._fruitESPObjs) do
                    if not obj or not obj.Parent then
                        pcall(function() data.bg:Destroy() end)
                        pcall(function() data.box:Destroy() end)
                        Adv._fruitESPObjs[obj] = nil
                    end
                end
            end)
        end)
    end

    function Adv.disableFruitESP()
        Adv._fruitESPEnabled = false
        if Adv._fruitESPConn then Adv._fruitESPConn:Disconnect() Adv._fruitESPConn = nil end
        for _, data in pairs(Adv._fruitESPObjs) do
            pcall(function() data.bg:Destroy() end)
            pcall(function() data.box:Destroy() end)
        end
        Adv._fruitESPObjs = {}
    end
    function Adv.enableESP(color)
        if Adv._espEnabled then Adv.disableESP()end
        Adv._espEnabled=true;color=color or Color3.fromRGB(76,175,100)
        Adv._espConn=RunService.RenderStepped:Connect(function()
            pcall(function()
                for _,p in ipairs(Players:GetPlayers())do
                    if p~=lp and p.Character then
                        local h=p.Character:FindFirstChild("HumanoidRootPart")
                        local hum=p.Character:FindFirstChild("Humanoid")
                        if h and hum and hum.Health>0 then
                            if not Adv._espObjs[p]then
                                local bg=Instance.new("BillboardGui")
                                bg.Name="DeniaESP";bg.Adornee=h;bg.Size=UDim2.new(8,0,3,0)
                                bg.AlwaysOnTop=true;bg.Enabled=true
                                local tl=Instance.new("TextLabel")
                                tl.Size=UDim2.new(1,0,1,0);tl.BackgroundTransparency=1
                                tl.TextColor3=color;tl.TextStrokeTransparency=0.3
                                tl.Text=(p.Name.." | "..tostring(math.floor(hum.Health)).."HP")
                                tl.Font=Enum.Font.GothamBold;tl.TextSize=14;tl.Parent=bg
                                bg.Parent=lp:FindFirstChild("PlayerGui")
                                Adv._espObjs[p]=bg

                                local box=Instance.new("BoxHandleAdornment")
                                box.Name="DeniaESPBox";box.Adornee=h;box.Size=h.Size*1.5
                                box.Color3=color;box.Transparency=0.5;box.Visible=true
                                box.AlwaysOnTop=true;box.ZIndex=10;box.Parent=h
                                Adv._espObjs[p.."_box"]=box
                            else
                                local tl=Adv._espObjs[p]:FindFirstChild("TextLabel")
                                if tl then tl.Text=(p.Name.." | "..tostring(math.floor(hum.Health)).."HP")end
                            end
                        end
                    end
                end
                for p,obj in pairs(Adv._espObjs)do
                    if type(p)=="string"then goto skip end
                    local char=p.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart")or not char:FindFirstChild("Humanoid")or char.Humanoid.Health<=0 then
                        pcall(function()obj:Destroy()end)
                        if Adv._espObjs[p.."_box"]then pcall(function()Adv._espObjs[p.."_box"]:Destroy()end)end
                        Adv._espObjs[p]=nil;Adv._espObjs[p.."_box"]=nil
                    end
                    ::skip::
                end
            end)
        end)
    end

    function Adv.disableESP()
        Adv._espEnabled=false
        if Adv._espConn then Adv._espConn:Disconnect()Adv._espConn=nil end
        for k,v in pairs(Adv._espObjs)do pcall(function()v:Destroy()end)end
        Adv._espObjs={}
    end

    function Adv.enableFastAttack()
        if Adv._fastAtkEnabled then return end
        Adv._fastAtkEnabled=true
        Adv.setupCombatFramework()
        Adv._fastAtkConn=RunService.Heartbeat:Connect(function()
            pcall(function()
                if Adv._killAuraEnabled then return end
                Adv.fastAttack()
                Adv.bodyClip()
            end)
        end)
    end

    function Adv.disableFastAttack()
        Adv._fastAtkEnabled=false
        if Adv._fastAtkConn then Adv._fastAtkConn:Disconnect()Adv._fastAtkConn=nil end
        Adv.removeClip()
    end

    function Adv.enableKillAura()
        if Adv._killAuraEnabled then return end
        Adv._killAuraEnabled=true
        Adv._killAuraConn=RunService.Heartbeat:Connect(function()
            pcall(function()
                for _,p in ipairs(Players:GetPlayers())do
                    if p~=lp and p.Character then
                        local h=p.Character:FindFirstChild("Humanoid")
                        local hr=p.Character:FindFirstChild("HumanoidRootPart")
                        if h and hr and h.Health>0 and (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart"))then
                            local d=(hr.Position-lp.Character.HumanoidRootPart.Position).Magnitude
                            if d<50 then h.Health=0;hr.CFrame=lp.Character.HumanoidRootPart.CFrame end
                        end
                    end
                end
            end)
        end)
    end

    function Adv.disableKillAura()
        Adv._killAuraEnabled=false
        if Adv._killAuraConn then Adv._killAuraConn:Disconnect()Adv._killAuraConn=nil end
    end

    function Adv.enableAutoQuest()
        if Adv._autoFarmConn then return end
        local remotes=ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local commF=remotes:FindFirstChild("CommF_")
        if not commF then return end
        Adv._autoFarmConn=RunService.Heartbeat:Connect(function()
            pcall(function()
                local lvl=lp:FindFirstChild("Data")and lp.Data:FindFirstChild("Level")
                if not lvl then return end
                local level=lvl.Value;local quest=Adv.getQuestForLevel(level)
                if not quest then return end
                local pg=lp:FindFirstChild("PlayerGui")
                local hasQuest=false
                if pg then
                    local mg=pg:FindFirstChild("Main")
                    if mg then
                        local qf=mg:FindFirstChild("QuestFrame")
                        if qf and qf.Visible then hasQuest=true end
                    end
                end
                if not hasQuest then
                    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist=(quest.npcCF.Position-hrp.Position).Magnitude
                        if dist>50 then hrp.CFrame=quest.npcCF end
                        commF:InvokeServer(unpack(quest.a))
                        task.wait(0.5)
                    end
                    return
                end
                local mob=Adv.findMob(quest.mob)
                if mob then
                    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local mhrp=mob:FindFirstChild("HumanoidRootPart")
                    if mhrp then
                        local dist=(mhrp.Position-hrp.Position).Magnitude
                        if dist>200 then hrp.CFrame=CFrame.new(mhrp.Position+Vector3.new(math.random(-20,20),0,math.random(-20,20)))
                        else Adv.fastAttack();Adv.bodyClip()
                            hrp.CFrame=CFrame.new(mhrp.Position*Vector3.new(1,0,1)+(hrp.Position-hrp.Position).Unit*8+Vector3.new(0,10,0))
                        end
                    end
                end
            end)
        end)
    end

    function Adv.disableAutoQuest()
        if Adv._autoFarmConn then Adv._autoFarmConn:Disconnect()Adv._autoFarmConn=nil end
    end

    function Adv.findMob(name)
        if not name then return nil end
        local nl=name:lower()
        for _,o in ipairs(Workspace:GetDescendants())do
            if o:IsA("Model")and o:FindFirstChild("Humanoid")and o:FindFirstChild("HumanoidRootPart")and o.Humanoid.Health>0 then
                if o.Name:lower():find(nl,1,true)then return o end
            end
        end
        return nil
    end

    function Adv.start()
        Adv.setupCombatFramework()
        Adv.setupSimRadius()
        Adv.noShake()
        Adv.setupNamecall()
    end

    Adv._seaProgConn = nil
    Adv._seaProgEnabled = false
    local SeaThresholds = {
        {from=1,to=2,level=700,entrance=Vector3.new(61163.85,11.68,1819.78)},
        {from=2,to=3,level=1500,entrance=Vector3.new(-6508.56,5000.03,-132.84)},
    }
    function Adv.enableAutoSea()
        if Adv._seaProgEnabled then return end
        Adv._seaProgEnabled = true
        Adv._seaProgConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local data = lp:FindFirstChild("Data")
                if not data then return end
                local lvl = data:FindFirstChild("Level")
                if not lvl then return end
                local level = lvl.Value
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if not remotes then return end
                local commF = remotes:FindFirstChild("CommF_")
                if not commF then return end
                for _, st in ipairs(SeaThresholds) do
                    if CurrentSea == st.from and level >= st.level then
                        commF:InvokeServer("requestEntrance", st.entrance)
                        task.wait(2)
                    end
                end
            end)
        end)
    end

    function Adv.disableAutoSea()
        Adv._seaProgEnabled = false
        if Adv._seaProgConn then Adv._seaProgConn:Disconnect() Adv._seaProgConn = nil end
    end

    Adv._noclipConn = nil
    Adv._noclipEnabled = false
    function Adv.enableNoclip()
        if Adv._noclipEnabled then return end
        Adv._noclipEnabled = true
        Adv._noclipConn = RunService.Stepped:Connect(function()
            pcall(function()
                local c = lp.Character
                if not c then return end
                local h = c:FindFirstChild("Humanoid")
                if not h then return end
                h:ChangeState(11)
                for _, part in ipairs(c:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end)
        end)
    end

    function Adv.disableNoclip()
        Adv._noclipEnabled = false
        if Adv._noclipConn then Adv._noclipConn:Disconnect() Adv._noclipConn = nil end
        pcall(function()
            local c = lp.Character
            if not c then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end)
    end

    Adv._bringMobConn = nil
    Adv._bringMobEnabled = false
    Adv._bringMobTarget = nil
    function Adv.enableBringMob(targetMob)
        if Adv._bringMobEnabled then Adv.disableBringMob() end
        Adv._bringMobEnabled = true
        Adv._bringMobTarget = targetMob
        Adv._bringMobConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local c = lp.Character
                if not c then return end
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local tMob = Adv._bringMobTarget
                if not tMob then
                    local quest = Adv.getQuestForLevel(lp.Data and lp.Data:FindFirstChild("Level") and lp.Data.Level.Value or 1)
                    if quest then tMob = quest.mob end
                end
                if not tMob then return end
                for _, o in ipairs(Workspace:GetDescendants()) do
                    if o:IsA("Model") and o:FindFirstChild("Humanoid") and o:FindFirstChild("HumanoidRootPart") then
                        local hum = o.Humanoid
                        local mhrp = o.HumanoidRootPart
                        if hum.Health > 0 and o.Name:lower():find(tMob:lower(), 1, true) then
                            local dist = (mhrp.Position - hrp.Position).Magnitude
                            if dist > 15 and dist < 400 then
                                mhrp.CFrame = CFrame.new(hrp.Position + Vector3.new(math.random(-12,12), 3, math.random(-12,12)))
                                if hum:FindFirstChild("Root") then
                                    local root = hum.Root
                                    root.Velocity = Vector3.new(0, 0, 0)
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end

    function Adv.disableBringMob()
        Adv._bringMobEnabled = false
        if Adv._bringMobConn then Adv._bringMobConn:Disconnect() Adv._bringMobConn = nil end
    end

    function Adv.stop()
        Adv.disableESP()
        Adv.disableFruitESP()
        Adv.disableAutoStat()
        Adv.disableAutoSea()
        Adv.disableNoclip()
        Adv.disableBringMob()
        Adv.disableFastAttack()
        Adv.disableKillAura()
        Adv.disableAutoQuest()
        Adv.removeClip()
        if Adv._simConn then Adv._simConn:Disconnect()Adv._simConn=nil end
        Adv._namecallHookActive=false
    end

    return Adv
end
_modules["boot"] = function()
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local DeniaHub = {}
    DeniaHub.VERSION = "3.0"
    DeniaHub.START_TIME = os.time()
    DeniaHub.Loaded = false

    function DeniaHub.createTabs(UI)
        UI:CreateTab("Main","rbxassetid://8568970646",1)
        UI:CreateTab("Combat","rbxassetid://9048465907",2)
        UI:CreateTab("Farming","rbxassetid://8567823911",3)
        UI:CreateTab("Adv","rbxassetid://8568215835",4)
        UI:CreateTab("Stats","rbxassetid://8569146720",5)
    end

    function DeniaHub.createMainTab(UI,Config,Utils,Main)
        local t=UI.Tabs[1]
        local s1=UI:Section(t,"Account",1)
        UI:Label(t,s1,"Player: "..lp.Name,1,UI.Library.Theme.AccentLight)
        UI:Label(t,s1,"Bounty: "..Utils.formatNumber(Utils.getCurrentBounty()),2)
        UI:Separator(t,s1,3)
        UI:Button(t,s1,"Reset Character",function()Main.reset()end,4)
        local s2=UI:Section(t,"Targeting",2)
        UI:Dropdown(t,s2,"LOCK_METHOD","Lock Method",Config.METHOD_LIST,Config.LOCK_METHOD,1)
        UI:Slider(t,s2,"TARGET_DISTANCE","Range",50,400,Config.TARGET_DISTANCE,"m",2)
        UI:Dropdown(t,s2,"HOP_TYPE","Hop Type",Config.HOP_TYPES,Config.HOP_TYPE,3)
        UI:Button(t,s2,"Server Hop",function()Main.serverHop()end,4)
        local s3=UI:Section(t,"Whitelist",3)
        UI:Dropdown(t,s3,"WHITELIST_MODE","Mode",Config.WL_MODES,Config.WHITELIST_MODE,1)
        local s4=UI:Section(t,"Visuals",4)
        UI:Keybind(t,s4,"TOGGLE_KEY","Toggle UI",UI.ToggleKey,1)
        UI:Label(t,s4,"Key: RightShift | Mobile: toggle btn",2,UI.Library.Theme.TextDim)
        UI:SelectTab(t)
    end

    function DeniaHub.createCombatTab(UI,Config,Utils,Main)
        local t=UI.Tabs[2]
        local s1=UI:Section(t,"Bounty Hunter",1)
        UI:Toggle(t,s1,"AUTO_FARM_BOUNTY","Auto Farm Bounty",Config.AUTO_FARM_BOUNTY,1)
        UI:Toggle(t,s1,"BOUNTY_HUNTER","Bounty Hunter Mode",Config.BOUNTY_HUNTER,2)
        UI:Toggle(t,s1,"TEAM_CHECK","Team Check",Config.TEAM_CHECK,3)
        local s2=UI:Section(t,"Weapons",2)
        UI:Dropdown(t,s2,"MELEE","Melee",Config.MELEE_LIST,Config.MELEE,1)
        UI:Dropdown(t,s2,"SWORD","Sword",Config.SWORD_LIST,Config.SWORD,2)
        UI:Dropdown(t,s2,"GUN","Gun",Config.GUN_LIST,Config.GUN,3)
        local s3=UI:Section(t,"Fruit",3)
        UI:Dropdown(t,s3,"FRUIT","Fruit",Config.FRUIT_LIST,Config.FRUIT,1)
        UI:Toggle(t,s3,"AUTO_STORE","Auto Store Fruit",Config.AUTO_STORE,2)
        local s4=UI:Section(t,"Defense",4)
        UI:Toggle(t,s4,"AUTO_GODMODE","God Mode",Config.AUTO_GODMODE,1)
        UI:Toggle(t,s4,"AUTO_INVIS","Invisibility",Config.AUTO_INVIS,2)
        UI:Toggle(t,s4,"AUTO_BUSO","Auto Buso",Config.AUTO_BUSO,3)
        UI:Toggle(t,s4,"AUTO_OBS","Auto Observation",Config.AUTO_OBS,4)
        UI:SelectTab(t)
    end

    function DeniaHub.createFarmingTab(UI,Config,Utils,Main)
        local t=UI.Tabs[3]
        local s1=UI:Section(t,"Leveling",1)
        UI:Toggle(t,s1,"AUTO_FARM_LEVEL","Auto Farm Level",Config.AUTO_FARM_LEVEL,1)
        UI:Toggle(t,s1,"AUTO_FARM_MASTERY","Auto Farm Mastery",Config.AUTO_FARM_MASTERY,2)
        UI:Toggle(t,s1,"AUTO_ROLL","Auto Roll Fruit",Config.AUTO_ROLL,3)
        local s2=UI:Section(t,"Mobs",2)
        UI:Toggle(t,s2,"BRING_MOBS","Bring Mobs",Config.BRING_MOBS,1)
        UI:Dropdown(t,s2,"BRING_TP","TP",Config.BRING_TP_LIST,Config.BRING_TP,2)
        UI:Slider(t,s2,"BRING_RADIUS","Radius",50,400,Config.BRING_RADIUS,"m",3)
        UI:Toggle(t,s2,"AUTO_ELITE","Auto Elite",Config.AUTO_ELITE,4)
        UI:Toggle(t,s2,"AUTO_NPC","Auto NPC",Config.AUTO_NPC,5)
        UI:Toggle(t,s2,"AUTO_CHEST","Auto Chest",Config.AUTO_CHEST,6)
        local s3=UI:Section(t,"Events",3)
        UI:Toggle(t,s3,"SEA_EVENT","Sea Event",Config.SEA_EVENT,1)
        UI:Dropdown(t,s3,"EVENT_TYPE","Type",Config.EVENT_LIST,Config.EVENT_TYPE,2)
        UI:Toggle(t,s3,"AUTO_FISH","Auto Fish",Config.AUTO_FISH,3)
        UI:SelectTab(t)
    end

    function DeniaHub.createAdvTab(UI,Config,Utils,Main)
        local t=UI.Tabs[4]
        local Adv=getgenv()._DeniaAdv
        local s1=UI:Section(t,"Combat System",1)
        UI:Button(t,s1,"Init Combat Framework",function()if Adv then Adv.start()UI:CreateNotification("Combat","Framework active",1,"success")end end,1)
        UI:Label(t,s1,"Hitbox: 200 | NoShake | SimRadius",2,UI.Library.Theme.TextDim)
        local s2=UI:Section(t,"Auto Attack",2)
        UI:Button(t,s2,"Start Fast Attack",function()if Adv then Adv.enableFastAttack()UI:CreateNotification("FastAtk","Enabled",1,"success")end end,1)
        UI:Button(t,s2,"Stop Fast Attack",function()if Adv then Adv.disableFastAttack()UI:CreateNotification("FastAtk","Disabled",1,"info")end end,2)
        UI:Label(t,s2,"Uses CombatFramework + anim speed",3,UI.Library.Theme.TextDim)
        local s3=UI:Section(t,"Kill Aura",3)
        UI:Button(t,s3,"Enable Kill Aura",function()if Adv then Adv.enableKillAura()UI:CreateNotification("KillAura","ON - kills within 50 studs",1,"success")end end,1)
        UI:Button(t,s3,"Disable Kill Aura",function()if Adv then Adv.disableKillAura()UI:CreateNotification("KillAura","OFF",1,"info")end end,2)
        local s4=UI:Section(t,"ESP",4)
        UI:Button(t,s4,"Enable ESP (Green)",function()if Adv then Adv.enableESP()UI:CreateNotification("ESP","Player ESP enabled",1,"success")end end,1)
        UI:Button(t,s4,"Disable ESP",function()if Adv then Adv.disableESP()UI:CreateNotification("ESP","Disabled",1,"info")end end,2)
        local s5=UI:Section(t,"Fruit ESP",5)
        UI:Button(t,s5,"Enable Fruit ESP (Gold)",function()if Adv then Adv.enableFruitESP()UI:CreateNotification("FruitESP","Fruit tracking active",1,"success")end end,1)
        UI:Button(t,s5,"Disable Fruit ESP",function()if Adv then Adv.disableFruitESP()UI:CreateNotification("FruitESP","Disabled",1,"info")end end,2)
        local s6=UI:Section(t,"Auto Quest Farm",6)
        UI:Button(t,s6,"Start Quest Farm",function()if Adv then Adv.enableAutoQuest()UI:CreateNotification("Quest","Auto quest farming running",1,"success")end end,1)
        UI:Button(t,s6,"Stop Quest Farm",function()if Adv then Adv.disableAutoQuest()UI:CreateNotification("Quest","Stopped",1,"info")end end,2)
        UI:Label(t,s6,"Sea "..tostring(Adv and Adv.getSea()or 0).." | 3 seas supported",3,UI.Library.Theme.TextDim)
        local s7=UI:Section(t,"Auto Stat",7)
        UI:Dropdown(t,s7,"AUTO_STAT_MODE","Stat Mode",{"Melee","Defense","Sword","Gun","DevilFruit"},Config.AUTO_STAT_MODE or "Melee",1)
        UI:Button(t,s7,"Start Auto Stat",function()if Adv then Adv.enableAutoStat(Config.AUTO_STAT_MODE or "Melee")UI:CreateNotification("AutoStat","ON - "..(Config.AUTO_STAT_MODE or "Melee"),1,"success")end end,2)
        UI:Button(t,s7,"Stop Auto Stat",function()if Adv then Adv.disableAutoStat()UI:CreateNotification("AutoStat","OFF",1,"info")end end,3)
        local s8=UI:Section(t,"Movement",8)
        UI:Button(t,s8,"Enable Noclip",function()if Adv then Adv.enableNoclip()UI:CreateNotification("Noclip","Walk through walls",1,"success")end end,1)
        UI:Button(t,s8,"Disable Noclip",function()if Adv then Adv.disableNoclip()UI:CreateNotification("Noclip","Disabled",1,"info")end end,2)
        UI:Button(t,s8,"Enable Bring Mob",function()if Adv then Adv.enableBringMob()UI:CreateNotification("BringMob","Pulling mobs to you",1,"success")end end,3)
        UI:Button(t,s8,"Disable Bring Mob",function()if Adv then Adv.disableBringMob()UI:CreateNotification("BringMob","OFF",1,"info")end end,4)
        local s9=UI:Section(t,"Sea Progression",9)
        UI:Button(t,s9,"Enable Auto Sea",function()if Adv then Adv.enableAutoSea()UI:CreateNotification("AutoSea","Auto teleport between seas",1,"success")end end,1)
        UI:Button(t,s9,"Disable Auto Sea",function()if Adv then Adv.disableAutoSea()UI:CreateNotification("AutoSea","OFF",1,"info")end end,2)
        UI:Label(t,s9,"Sea 1->2 at lv700, Sea 2->3 at lv1500",3,UI.Library.Theme.TextDim)
        UI:SelectTab(t)
    end

    function DeniaHub.createStatsTab(UI,Config,Utils,Main)
        local t=UI.Tabs[5]
        local stats=Utils.loadStats()
        local s1=UI:Section(t,"Session",1)
        UI:Label(t,s1,"Bounty: "..Utils.formatNumber(stats.totalBountyGained or 0),1,UI.Library.Theme.AccentLight)
        UI:Label(t,s1,"Kills: "..(stats.totalKills or 0),2)
        UI:Label(t,s1,"Hopped: "..(stats.serversHopped or 0),3)
        UI:Label(t,s1,"Auto Hops: "..(stats.autoServersHopped or 0),4)
        UI:Label(t,s1,"Play Time: "..Utils.formatTime(stats.totalPlayTime or 0),5)
        UI:Separator(t,s1,6)
        UI:Label(t,s1,"Session Bounty: "..Utils.formatNumber(stats.sessionBounty or 0),7)
        UI:Label(t,s1,"Session Kills: "..(stats.sessionKills or 0),8)
        UI:Label(t,s1,"Started: "..os.date("%c",stats.sessionStartTime or os.time()),9,UI.Library.Theme.TextDim)
        UI:Button(t,s1,"Refresh",function()t.Container:ClearAllChildren();t.Sections={};DeniaHub.createStatsTab(UI,Config,Utils,Main)end,10)
        UI:SelectTab(t)
    end

    function DeniaHub.init()
        local UI=_modules["ui"]();getgenv()._DeniaUI=UI
        UI:CreateLoadingScreen()
        UI:UpdateLoadingProgress("Loading utilities...",0.1)
        local Utils=_modules["utils"]();getgenv()._DeniaUtils=Utils
        Utils.logDebug(Utils.DEBUG_LEVELS.INFO,"Boot","Utils v"..DeniaHub.VERSION)
        UI:UpdateLoadingProgress("Loading config...",0.2)
        local Config=_modules["config"]();getgenv()._DeniaConfig=Config;Config.init()
        UI:UpdateLoadingProgress("Loading auth...",0.3)
        local Auth=_modules["auth"]();getgenv()._DeniaAuth=Auth
        UI:UpdateLoadingProgress("Building interface...",0.4)
        UI:Init()
        UI:UpdateLoadingProgress("Loading combat systems...",0.5)
        local Main=_modules["main"]();getgenv()._DeniaMain=Main
        UI:UpdateLoadingProgress("Loading advanced systems...",0.6)
        local Adv=_modules["advanced"]();getgenv()._DeniaAdv=Adv
        UI:UpdateLoadingProgress("Creating tabs...",0.7)
        DeniaHub.createTabs(UI)
        DeniaHub.createMainTab(UI,Config,Utils,Main)
        DeniaHub.createCombatTab(UI,Config,Utils,Main)
        DeniaHub.createFarmingTab(UI,Config,Utils,Main)
        DeniaHub.createAdvTab(UI,Config,Utils,Main)
        DeniaHub.createStatsTab(UI,Config,Utils,Main)
        UI:UpdateLoadingProgress("Initializing...",0.9)
        Main.init()
        DeniaHub.Loaded=true
        Utils.logDebug(Utils.DEBUG_LEVELS.INFO,"Boot","DeniaHub v"..DeniaHub.VERSION.." loaded")
        UI:UpdateLoadingProgress("Ready!",1.0)
        task.wait(0.3)
        UI:HideLoadingScreen()
        UI:CreateNotification("DeniaHub v"..DeniaHub.VERSION,"Welcome "..lp.Name.."!",3,"success")
        if lp.Character then task.wait(0.5);UI:CreateNotification("Ready","v3.0 - Systems active",2,"success")end
        lp.CharacterAdded:Connect(function()task.wait(1)if UI and UI.CreateNotification then UI:CreateNotification("Respawned","Character detected",2,"info")end end)
    end

    DeniaHub.init()
    return DeniaHub
end

local ok,mod=pcall(function()return _modules["boot"]()end)
getgenv().DeniaHub=ok and mod or nil
if ok then print("DeniaHub v3.0 - Loaded") else warn("DeniaHub v3.0 failed:",mod) end

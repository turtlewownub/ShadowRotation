-- ShadowRotation 1.0.2 Stable Drag Release Core
SHADOWROTATION_VERSION = "1.0.2"
ShadowRotation = ShadowRotation or {}
SR = ShadowRotation
SR.Modules = SR.Modules or {}
SR.Modules.Core = true



-- Turtle WoW compatibility guard.
-- Some Turtle client builds expect this table to exist when target frames update.
if Turtle_ChallengesCache == nil then Turtle_ChallengesCache = {} end
if type(Turtle_ChallengesCache) == "table" and setmetatable then
  setmetatable(Turtle_ChallengesCache, { __index = function(t, k) local v = {}; rawset(t, k, v); return v end })
end

SR.Spells = {
  swp = { name = "Shadow Word: Pain", short = "SW:P", duration = 18, color = {0.65, 0.15, 1.0} },
  ve  = { name = "Vampiric Embrace", short = "VE", duration = 60, color = {0.85, 0.20, 1.0} },
  dp  = { name = "Devouring Plague", short = "DP", duration = 24, color = {0.35, 1.0, 0.25} },
  mb  = { name = "Mind Blast", short = "MB", color = {1.0, 0.45, 0.10} },
  mf  = { name = "Mind Flay", short = "MF", color = {0.55, 0.25, 1.0} },
  silence = { name = "Silence", short = "Silence", color = {0.75, 0.20, 1.0} },
  scream = { name = "Psychic Scream", short = "Scream", color = {0.65, 0.10, 0.85} },
  shadowguard = { name = "Shadowguard", short = "Guard", color = {0.45, 0.20, 0.85} },
  touch = { name = "Touch of Weakness", short = "Touch", color = {0.60, 0.15, 0.65} },
}

SR.Defaults = {
  debug = false,
  refresh = 2,
  throttle = 0.20,
  order = { "swp", "ve", "dp" },
  enabled = { swp = true, ve = true, dp = true },
  mb = true,
  mbMode = "afterdots",
  mbMana = 0,
  dpMana = 0,
  clip = false,
  targetKey = nil,
  lastCast = {},
  nextCastTime = 0,
  smartAuras = true,
  verifyDelay = 0.75,
  pendingDots = {},
  diagnostics = { gcdSkips = 0, busySkips = 0, failedDots = 0, auraScans = 0 },
  coach = { enabled = true, autoReport = false, maxFights = 10, fights = {}, current = nil },
  pvp = {
    assist = false,
    silence = true,
    scream = true,
    shadowguard = false,
    touch = false,
    healthThreshold = 35
  },
  targetHealthSkipDots = 0,
  profileUi = false,
  rotationPack = "standard",
  decisionLog = {},
  simulation = { enabled = true, lookahead = 1.5 },
  insights = { maxTimeline = 30 },
  ui = {
    hud = true,
    minimap = true,
    locked = false,
    scale = 1.0,
    alpha = 0.92,
    x = 0,
    y = -155,
    minimapAngle = 225,
    compact = false,
    strip = true,
    names = true,
    simple = true,
    dots = true,
    cds = true,
    alerts = true,
    history = true,
    queue = true,
    radial = true,
    announce = false,
    layout = "elite",
    pulse = true,
    grade = true,
    snap = false,
    wizardDone = false,
    tooltips = true,
    autoReport = false,
    lastRecommendation = "",
    integrated = true,
    clean = true,
    splitNext = true,
    background = false,
    tab = "general",
    modules = true,
    layoutMode = "separated",
    separatedPositions = {},
    combinedPositions = {},
    releaseSeen = "",
    safeUiMigrated = false,
    activePreset = "custom",
    customLayout = {},
    bigTimers = true,
    coaching = true,
    fightHistory = {},
    activeProfile = "solo",
    profiles = {},
    dotX = -255,
    dotY = -105,
    cdX = 255,
    cdY = -105,
  },
  stats = { active = false, start = 0, last = 0, casts = {}, history = {} },
}

function SR.Copy(dst, src, seen, depth)
  if type(src) ~= "table" then return dst end
  if type(dst) ~= "table" then dst = {} end
  if dst == src then return dst end

  seen = seen or {}
  depth = depth or 0
  if depth > 40 then return dst end
  if seen[src] then return dst end
  seen[src] = true

  local k,v
  for k,v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" or dst[k] == dst then dst[k] = {} end
      SR.Copy(dst[k], v, seen, depth + 1)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end

  seen[src] = nil
  return dst
end

function SR.Init()
  if type(ShadowRotationDB) ~= "table" then ShadowRotationDB = {} end
  ShadowRotationDB = SR.Copy(ShadowRotationDB, SR.Defaults)
  SR.db = ShadowRotationDB
  return ShadowRotationDB
end

function SR.ResetDefaults()
  ShadowRotationDB = SR.Copy({}, SR.Defaults)
  SR.db = ShadowRotationDB
  if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end
  if SR.Minimap_Apply then SR.Minimap_Apply() end
end

function SR.Msg(s)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff8f45ffShadowRotation:|r " .. tostring(s)) end
end
function SR.Debug(s)
  if SR.db and SR.db.debug then SR.Msg(s) end
end
function SR.Now() if GetTime then return GetTime() else return 0 end end
function SR.Lower(s) if s and string.lower then return string.lower(s) end return s end

function SR.Count(t)
  local n = 0
  if not t then return 0 end
  for _ in pairs(t) do n = n + 1 end
  return n
end

function SR.Split(s)
  local out = {}
  if not s then return out end
  if string.gfind then
    for w in string.gfind(s, "%S+") do table.insert(out, w) end
  else
    local p = 1
    while true do
      local a,b = string.find(s, "%S+", p)
      if not a then break end
      table.insert(out, string.sub(s, a, b))
      p = b + 1
    end
  end
  return out
end

function SR.BoolArg(v, default)
  if not v then return default end
  v = SR.Lower(v)
  if v == "on" or v == "1" or v == "true" or v == "yes" then return true end
  if v == "off" or v == "0" or v == "false" or v == "no" then return false end
  return default
end

function SR.ValidTarget()
  if not UnitExists or not UnitExists("target") then return false end
  if UnitIsDead and UnitIsDead("target") then return false end
  if UnitCanAttack and not UnitCanAttack("player", "target") then return false end
  return true
end

function SR.TargetKey()
  if not UnitExists or not UnitExists("target") then return nil end
  local n = UnitName and UnitName("target") or "target"
  local l = UnitLevel and UnitLevel("target") or 0
  return tostring(n) .. ":" .. tostring(l)
end

function SR.ManaPct()
  if not UnitMana or not UnitManaMax then return 100 end
  local max = UnitManaMax("player") or 0
  if max <= 0 then return 100 end
  return ((UnitMana("player") or 0) / max) * 100
end

function SR.ResetTargetIfNeeded()
  local k = SR.TargetKey()
  if k ~= SR.db.targetKey then
    SR.db.targetKey = k
    SR.db.lastCast = {}
    SR.db.pendingDots = {}
    SR.db.nextCastTime = 0
    SR.Debug("target changed")
  end
end

function SR.Remaining(id)
  local sp = SR.Spells[id]
  if not sp or not sp.duration then return 0 end
  local t = SR.db.lastCast and SR.db.lastCast[id]
  if not t then return 0 end
  local r = sp.duration - (SR.Now() - t)
  if r < 0 then r = 0 end
  return r
end


function SR.ProfileDefaults(name)
  local p = {
    enabled = { swp = true, ve = true, dp = true },
    mb = true,
    mbMode = "afterdots",
    mbMana = 0,
    dpMana = 0,
    refresh = 2,
    smartAuras = true,
    verifyDelay = 0.75,
    pvp = {
    assist = false,
    silence = true,
    scream = true,
    shadowguard = false,
    touch = false,
    healthThreshold = 35
  },
  targetHealthSkipDots = 0,
  profileUi = false,
  rotationPack = "standard",
  decisionLog = {},
  simulation = { enabled = true, lookahead = 1.5 },
  insights = { maxTimeline = 30 },
    order = { "swp", "ve", "dp" },
  }
  if name == "raid" then
    p.dpMana = 15
    p.mbMana = 10
  elseif name == "dungeon" then
    p.dpMana = 20
    p.mbMana = 15
  elseif name == "pvp" then
    p.enabled.swp = true
    p.enabled.ve = true
    p.enabled.dp = true
    p.mb = true
    p.mbMode = "beforedots"
    p.dpMana = 0
    p.mbMana = 0
    p.refresh = 1
    p.pvp.assist = false
    p.targetHealthSkipDots = 0
    p.order = { "swp", "ve", "dp" }
  else
    p.dpMana = 0
    p.mbMana = 0
  end
  return p
end

function SR.EnsureProfiles()
  SR.Init()
  if not SR.db.ui.profiles then SR.db.ui.profiles = {} end
  local names = { "solo", "dungeon", "raid", "pvp" }
  local i
  for i=1,SR.Count(names) do
    local n = names[i]
    if not SR.db.ui.profiles[n] then SR.db.ui.profiles[n] = SR.ProfileDefaults(n) end
  end
  if not SR.db.ui.activeProfile then SR.db.ui.activeProfile = "solo" end
end

function SR.SaveCurrentProfile()
  SR.EnsureProfiles()
  local n = SR.db.ui.activeProfile or "solo"
  SR.db.ui.profiles[n] = {
    enabled = { swp = SR.db.enabled.swp and true or false, ve = SR.db.enabled.ve and true or false, dp = SR.db.enabled.dp and true or false },
    mb = SR.db.mb and true or false,
    mbMode = SR.db.mbMode or "afterdots",
    mbMana = SR.db.mbMana or 0,
    dpMana = SR.db.dpMana or 0,
    refresh = SR.db.refresh or 2,
    smartAuras = SR.db.smartAuras ~= false,
    verifyDelay = SR.db.verifyDelay or 0.75,
    pvp = {
      assist = SR.db.pvp and SR.db.pvp.assist and true or false,
      silence = SR.db.pvp and SR.db.pvp.silence ~= false,
      scream = SR.db.pvp and SR.db.pvp.scream ~= false,
      shadowguard = SR.db.pvp and SR.db.pvp.shadowguard and true or false,
      touch = SR.db.pvp and SR.db.pvp.touch and true or false,
      healthThreshold = SR.db.pvp and SR.db.pvp.healthThreshold or 35,
    },
    targetHealthSkipDots = SR.db.targetHealthSkipDots or 0,
    profileUi = SR.db.profileUi and true or false,
    ui = SR.db.profileUi and {
      hud = SR.db.ui.hud,
      dots = SR.db.ui.dots,
      cds = SR.db.ui.cds,
      queue = SR.db.ui.queue,
      scale = SR.db.ui.scale,
      alpha = SR.db.ui.alpha,
    } or nil,
    order = SR.db.order or { "swp", "ve", "dp" },
  }
end

function SR.LoadProfile(name)
  SR.EnsureProfiles()
  name = SR.Lower(name or "solo")
  if name ~= "solo" and name ~= "dungeon" and name ~= "raid" and name ~= "pvp" then return false end
  local p = SR.db.ui.profiles[name] or SR.ProfileDefaults(name)
  SR.db.ui.activeProfile = name
  SR.db.enabled.swp = p.enabled and p.enabled.swp and true or false
  SR.db.enabled.ve = p.enabled and p.enabled.ve and true or false
  SR.db.enabled.dp = p.enabled and p.enabled.dp and true or false
  SR.db.mb = p.mb and true or false
  SR.db.mbMode = p.mbMode or "afterdots"
  SR.db.mbMana = p.mbMana or 0
  SR.db.dpMana = p.dpMana or 0
  SR.db.refresh = p.refresh or 2
  SR.db.smartAuras = p.smartAuras ~= false
  SR.db.verifyDelay = p.verifyDelay or 0.75
  if type(p.pvp) == "table" then SR.db.pvp = SR.DeepCopy(p.pvp) end
  SR.db.targetHealthSkipDots = p.targetHealthSkipDots or 0
  SR.db.profileUi = p.profileUi and true or false
  if SR.db.profileUi and type(p.ui) == "table" then
    SR.db.ui.hud = p.ui.hud ~= false
    SR.db.ui.dots = p.ui.dots ~= false
    SR.db.ui.cds = p.ui.cds ~= false
    SR.db.ui.queue = p.ui.queue ~= false
    SR.db.ui.scale = p.ui.scale or SR.db.ui.scale
    SR.db.ui.alpha = p.ui.alpha or SR.db.ui.alpha
    if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end
  end
  SR.db.order = p.order or { "swp", "ve", "dp" }
  SR.ResetRotation()
  return true
end

function SR.ResetProfile(name)
  SR.EnsureProfiles()
  name = SR.Lower(name or (SR.db.ui.activeProfile or "solo"))
  SR.db.ui.profiles[name] = SR.ProfileDefaults(name)
  SR.LoadProfile(name)
end



function SR.EnsureSmartState()
  SR.Init()
  if type(SR.db.pendingDots) ~= "table" then SR.db.pendingDots = {} end
  if type(SR.db.diagnostics) ~= "table" then
    SR.db.diagnostics = { gcdSkips = 0, busySkips = 0, failedDots = 0, auraScans = 0 }
  end
  if SR.db.smartAuras == nil then SR.db.smartAuras = true end
  if not SR.db.verifyDelay then SR.db.verifyDelay = 0.75 end
end

function SR.ResetDiagnostics()
  SR.EnsureSmartState()
  SR.db.diagnostics = { gcdSkips = 0, busySkips = 0, failedDots = 0, auraScans = 0 }
end

function SR.Diagnose()
  SR.EnsureSmartState()
  SR.Msg("v"..SHADOWROTATION_VERSION.." diagnostics")
  SR.Msg("Profile="..tostring(SR.db.ui and SR.db.ui.activeProfile or "solo")..
    " SmartAuras="..tostring(SR.db.smartAuras)..
    " Target="..tostring(SR.TargetKey()))
  SR.Msg("UnitDebuff="..tostring(type(UnitDebuff)=="function")..
    " GetCurrentCastingInfo="..tostring(type(GetCurrentCastingInfo)=="function")..
    " CastSpellByName="..tostring(type(CastSpellByName)=="function"))
  local d = SR.db.diagnostics
  SR.Msg("AuraScans="..tostring(d.auraScans or 0)..
    " FailedDots="..tostring(d.failedDots or 0)..
    " BusySkips="..tostring(d.busySkips or 0)..
    " GCDSkips="..tostring(d.gcdSkips or 0))
  local id
  for _,id in ipairs({"swp","ve","dp"}) do
    local present = SR.AuraPresent and SR.AuraPresent(id) or false
    SR.Msg(string.upper(id).." present="..tostring(present)..
      " remaining="..string.format("%.1f", SR.Remaining(id) or 0))
  end
end


function SR.DeepCopy(src, seen, depth)
  if type(src) ~= "table" then return src end
  seen = seen or {}
  depth = depth or 0
  if depth > 40 then return {} end
  if seen[src] then return seen[src] end

  local out = {}
  seen[src] = out
  local k,v
  for k,v in pairs(src) do
    if type(k) ~= "table" and type(v) ~= "function" and type(v) ~= "userdata" and type(v) ~= "thread" then
      out[k] = SR.DeepCopy(v, seen, depth + 1)
    end
  end
  return out
end

function SR.BackupSettings()
  SR.Init()
  ShadowRotationBackup = SR.DeepCopy(ShadowRotationDB)
  SR.Msg("settings backup created")
end

function SR.RestoreSettings()
  if type(ShadowRotationBackup) ~= "table" then
    SR.Msg("no settings backup found")
    return false
  end
  ShadowRotationDB = SR.DeepCopy(ShadowRotationBackup)
  SR.db = ShadowRotationDB
  if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end
  if SR.Minimap_Apply then SR.Minimap_Apply() end
  if SR.Options_Refresh then SR.Options_Refresh() end
  SR.Msg("settings backup restored")
  return true
end

function SR.SaveLayoutPositions(mode)
  SR.Init()
  mode = mode or (SR.db.ui.layoutMode or "separated")
  if not SR.db.ui.separatedPositions then SR.db.ui.separatedPositions = {} end
  if not SR.db.ui.combinedPositions then SR.db.ui.combinedPositions = {} end
  local p = {
    nextX = SR.db.ui.nextX, nextY = SR.db.ui.nextY,
    dotX = SR.db.ui.dotX, dotY = SR.db.ui.dotY,
    cdX = SR.db.ui.cdX, cdY = SR.db.ui.cdY,
    queueX = SR.db.ui.queueX, queueY = SR.db.ui.queueY,
  }
  if mode == "combined" then SR.db.ui.combinedPositions = p
  else SR.db.ui.separatedPositions = p end
end

function SR.ApplyLayoutMode(mode)
  SR.Init()
  mode = SR.Lower(mode or "separated")
  if mode ~= "combined" then mode = "separated" end

  local old = SR.db.ui.layoutMode or "separated"
  if SR.SaveAllFramePositions then SR.SaveAllFramePositions() end
  SR.SaveLayoutPositions(old)
  SR.db.ui.layoutMode = mode

  local p
  if mode == "combined" then
    p = SR.db.ui.combinedPositions
    if not p or not p.nextX then
      p = {
        nextX = 0, nextY = -90,
        dotX = -70, dotY = -165,
        cdX = 70, cdY = -165,
        queueX = 0, queueY = -220,
      }
    end
  else
    p = SR.db.ui.separatedPositions
    if not p or not p.nextX then
      p = {
        nextX = 0, nextY = -95,
        dotX = -180, dotY = -170,
        cdX = 170, cdY = -170,
        queueX = 0, queueY = -245,
      }
    end
  end

  SR.db.ui.nextX = p.nextX; SR.db.ui.nextY = p.nextY
  SR.db.ui.dotX = p.dotX; SR.db.ui.dotY = p.dotY
  SR.db.ui.cdX = p.cdX; SR.db.ui.cdY = p.cdY
  SR.db.ui.queueX = p.queueX; SR.db.ui.queueY = p.queueY

  if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end
  SR.Msg("layout "..mode)
end


function SR.SafeUiMigration()
  SR.Init()
  if SR.db.ui.safeUiMigrated == "16.2" then return end

  SR.db.ui.safeUiMigrated = "16.2"
  SR.db.ui.layoutMode = "separated"
  SR.db.ui.background = false
  SR.db.ui.hud = true
  SR.db.ui.dots = true
  SR.db.ui.cds = true
  SR.db.ui.queue = true
  SR.db.ui.minimap = true
  SR.db.ui.locked = false

  -- Recover the last separated layout if v16.0 saved one.
  local p = SR.db.ui.separatedPositions
  if type(p) == "table" and p.nextX ~= nil then
    SR.db.ui.nextX = p.nextX
    SR.db.ui.nextY = p.nextY
    SR.db.ui.dotX = p.dotX
    SR.db.ui.dotY = p.dotY
    SR.db.ui.cdX = p.cdX
    SR.db.ui.cdY = p.cdY
    SR.db.ui.queueX = p.queueX
    SR.db.ui.queueY = p.queueY
  else
    -- Keep existing coordinates when possible; only fill missing values.
    if SR.db.ui.nextX == nil then SR.db.ui.nextX = 0 end
    if SR.db.ui.nextY == nil then SR.db.ui.nextY = -95 end
    if SR.db.ui.dotX == nil then SR.db.ui.dotX = -180 end
    if SR.db.ui.dotY == nil then SR.db.ui.dotY = -170 end
    if SR.db.ui.cdX == nil then SR.db.ui.cdX = 170 end
    if SR.db.ui.cdY == nil then SR.db.ui.cdY = -170 end
    if SR.db.ui.queueX == nil then SR.db.ui.queueX = 0 end
    if SR.db.ui.queueY == nil then SR.db.ui.queueY = -245 end
  end
end


function SR.CaptureCustomLayout()
  SR.Init()
  if SR.SaveAllFramePositions then SR.SaveAllFramePositions() end
  SR.db.ui.customLayout = {
    nextX = SR.db.ui.nextX, nextY = SR.db.ui.nextY,
    dotX = SR.db.ui.dotX, dotY = SR.db.ui.dotY,
    cdX = SR.db.ui.cdX, cdY = SR.db.ui.cdY,
    queueX = SR.db.ui.queueX, queueY = SR.db.ui.queueY,
    scale = SR.db.ui.scale, alpha = SR.db.ui.alpha,
    hud = SR.db.ui.hud, dots = SR.db.ui.dots,
    cds = SR.db.ui.cds, queue = SR.db.ui.queue,
    background = SR.db.ui.background,
  }
end

function SR.ApplyPreset(name)
  SR.Init()
  name = SR.Lower(name or "custom")

  if name ~= "custom" and SR.db.ui.activePreset == "custom" then
    SR.CaptureCustomLayout()
  end

  if name == "custom" then
    local p = SR.db.ui.customLayout
    if type(p) == "table" and p.nextX ~= nil then
      SR.db.ui.nextX = p.nextX; SR.db.ui.nextY = p.nextY
      SR.db.ui.dotX = p.dotX; SR.db.ui.dotY = p.dotY
      SR.db.ui.cdX = p.cdX; SR.db.ui.cdY = p.cdY
      SR.db.ui.queueX = p.queueX; SR.db.ui.queueY = p.queueY
      SR.db.ui.scale = p.scale or 1
      SR.db.ui.alpha = p.alpha or 0.92
      SR.db.ui.hud = p.hud ~= false
      SR.db.ui.dots = p.dots ~= false
      SR.db.ui.cds = p.cds ~= false
      SR.db.ui.queue = p.queue ~= false
      SR.db.ui.background = p.background and true or false
    end
  elseif name == "minimal" then
    SR.db.ui.nextX = 0; SR.db.ui.nextY = -95
    SR.db.ui.dotX = -95; SR.db.ui.dotY = -165
    SR.db.ui.cdX = 95; SR.db.ui.cdY = -165
    SR.db.ui.queueX = 0; SR.db.ui.queueY = -215
    SR.db.ui.scale = 0.85; SR.db.ui.alpha = 0.90
    SR.db.ui.hud = true; SR.db.ui.dots = true
    SR.db.ui.cds = true; SR.db.ui.queue = false
    SR.db.ui.background = false
  elseif name == "classic" then
    SR.db.ui.nextX = 0; SR.db.ui.nextY = -95
    SR.db.ui.dotX = -180; SR.db.ui.dotY = -170
    SR.db.ui.cdX = 170; SR.db.ui.cdY = -170
    SR.db.ui.queueX = 0; SR.db.ui.queueY = -245
    SR.db.ui.scale = 1.0; SR.db.ui.alpha = 0.92
    SR.db.ui.hud = true; SR.db.ui.dots = true
    SR.db.ui.cds = true; SR.db.ui.queue = true
    SR.db.ui.background = false
  elseif name == "compact" then
    SR.db.ui.nextX = -145; SR.db.ui.nextY = -150
    SR.db.ui.dotX = -25; SR.db.ui.dotY = -150
    SR.db.ui.cdX = 120; SR.db.ui.cdY = -150
    SR.db.ui.queueX = 0; SR.db.ui.queueY = -210
    SR.db.ui.scale = 0.78; SR.db.ui.alpha = 0.90
    SR.db.ui.hud = true; SR.db.ui.dots = true
    SR.db.ui.cds = true; SR.db.ui.queue = true
    SR.db.ui.background = false
  elseif name == "streamer" then
    SR.db.ui.nextX = 0; SR.db.ui.nextY = -70
    SR.db.ui.dotX = -160; SR.db.ui.dotY = -190
    SR.db.ui.cdX = 160; SR.db.ui.cdY = -190
    SR.db.ui.queueX = 0; SR.db.ui.queueY = -265
    SR.db.ui.scale = 1.2; SR.db.ui.alpha = 1.0
    SR.db.ui.hud = true; SR.db.ui.dots = true
    SR.db.ui.cds = true; SR.db.ui.queue = true
    SR.db.ui.background = false
  else
    SR.Msg("Unknown preset: "..tostring(name))
    return false
  end

  SR.db.ui.activePreset = name
  SR.db.ui.locked = false
  if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end
  SR.Msg("HUD preset "..name)
  return true
end


function SR.RotationPackDefaults(name)
  name = SR.Lower(name or "standard")
  if name == "mana" then
    return {
      refresh = 1.0,
      mbMode = "afterdots",
      mbMana = 35,
      dpMana = 45,
      targetHealthSkipDots = 20,
      enabled = { swp = true, ve = true, dp = true },
      order = { "swp", "ve", "dp" },
    }
  elseif name == "maxdps" then
    return {
      refresh = 2.5,
      mbMode = "beforedots",
      mbMana = 0,
      dpMana = 0,
      targetHealthSkipDots = 0,
      enabled = { swp = true, ve = true, dp = true },
      order = { "swp", "dp", "ve" },
    }
  elseif name == "pvp" then
    return {
      refresh = 1.0,
      mbMode = "beforedots",
      mbMana = 0,
      dpMana = 0,
      targetHealthSkipDots = 0,
      enabled = { swp = true, ve = true, dp = true },
      order = { "swp", "ve", "dp" },
    }
  elseif name == "leveling" then
    return {
      refresh = 1.5,
      mbMode = "afterdots",
      mbMana = 20,
      dpMana = 25,
      targetHealthSkipDots = 25,
      enabled = { swp = true, ve = true, dp = false },
      order = { "swp", "ve", "dp" },
    }
  end
  return {
    refresh = 2.0,
    mbMode = "afterdots",
    mbMana = 0,
    dpMana = 0,
    targetHealthSkipDots = 0,
    enabled = { swp = true, ve = true, dp = true },
    order = { "swp", "ve", "dp" },
  }
end

function SR.ApplyRotationPack(name)
  SR.Init()
  name = SR.Lower(name or "standard")
  if name ~= "standard" and name ~= "mana" and name ~= "maxdps" and name ~= "pvp" and name ~= "leveling" then
    SR.Msg("Unknown rotation pack: "..tostring(name))
    return false
  end
  local p = SR.RotationPackDefaults(name)
  SR.db.rotationPack = name
  SR.db.refresh = p.refresh
  SR.db.mbMode = p.mbMode
  SR.db.mbMana = p.mbMana
  SR.db.dpMana = p.dpMana
  SR.db.targetHealthSkipDots = p.targetHealthSkipDots
  SR.db.enabled.swp = p.enabled.swp
  SR.db.enabled.ve = p.enabled.ve
  SR.db.enabled.dp = p.enabled.dp
  SR.db.order = p.order
  if name == "pvp" then
    SR.db.ui.activeProfile = "pvp"
  end
  if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end
  SR.ResetRotation()
  if SR.Options_Refresh then SR.Options_Refresh() end
  SR.Msg("rotation pack "..name)
  return true
end

function SR.DecisionPush(line)
  SR.Init()
  if type(SR.db.decisionLog) ~= "table" then SR.db.decisionLog = {} end
  table.insert(SR.db.decisionLog, 1, tostring(line))
  while SR.Count(SR.db.decisionLog) > 12 do table.remove(SR.db.decisionLog) end
end

function SR.ExplainDecision()
  SR.Init()
  if not SR.ValidTarget() then
    return "No valid hostile target."
  end
  local pieces = {}
  local order = SR.db.order or {"swp","ve","dp"}
  local i
  for i=1,SR.Count(order) do
    local id = order[i]
    local sp = SR.Spells[id]
    if sp and SR.db.enabled[id] then
      table.insert(pieces, sp.short.."="..string.format("%.1f", SR.Remaining(id) or 0))
    end
  end
  local mb = SR.Cooldown("Mind Blast") or 0
  table.insert(pieces, "MB="..string.format("%.1f", mb))
  table.insert(pieces, "Mana="..string.format("%.0f", SR.ManaPct() or 0).."%")
  table.insert(pieces, "TargetHP="..string.format("%.0f", SR.TargetHealthPct and SR.TargetHealthPct() or 100).."%")
  local nextSpell = SR.NextSpellName and SR.NextSpellName() or "Unknown"
  return table.concat(pieces, " | ").." | Decision="..nextSpell
end

function SR.ResetRotation()
  SR.Init()
  SR.db.lastCast = {}
  SR.db.pendingDots = {}
  SR.db.targetKey = nil
  SR.db.nextCastTime = 0
  if SR.HUD_Update then SR.HUD_Update() end
end

local frame = CreateFrame("Frame")
SR.EventFrame = frame
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:SetScript("OnEvent", function()
  SR.Init()
  if event == "PLAYER_TARGET_CHANGED" then SR.ResetRotation() end
  if event == "PLAYER_LOGIN" or event == "VARIABLES_LOADED" then
    if SR.SafeUiMigration then SR.SafeUiMigration() end
    if SR.HUD_Create then SR.HUD_Create() end
    if SR.Minimap_Create then SR.Minimap_Create() end
    if SR.Minimap_Apply then SR.Minimap_Apply() end
    if SR.Options_Create then SR.Options_Create() end
    if SR.Wizard_Create then SR.Wizard_Create() end
    if SR.Wizard_Show and SR.db and SR.db.ui and not SR.db.ui.wizardDone then SR.Wizard_Show() end
    if SR.db and SR.db.ui and SR.db.ui.releaseSeen ~= SHADOWROTATION_VERSION then
      SR.db.ui.releaseSeen = SHADOWROTATION_VERSION
      SR.Msg("v"..SHADOWROTATION_VERSION.." loaded. Separated layout and no background remain the defaults.")
    end
  end
end)

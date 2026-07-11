-- ShadowRotation v17.2 profile import/export
SR.Modules.ProfileIO = true
SR.ProfileIOFrame = nil

local function Bool01(v)
  if v then return "1" else return "0" end
end

function SR.ExportProfileString(name)
  SR.EnsureProfiles()
  name = SR.Lower(name or (SR.db.ui.activeProfile or "solo"))
  local p = SR.db.ui.profiles[name] or SR.ProfileDefaults(name)
  local order = p.order or {"swp","ve","dp"}
  local pv = p.pvp or {}
  return "SR17"..
    "|name="..name..
    "|swp="..Bool01(p.enabled and p.enabled.swp)..
    "|ve="..Bool01(p.enabled and p.enabled.ve)..
    "|dp="..Bool01(p.enabled and p.enabled.dp)..
    "|mb="..Bool01(p.mb)..
    "|mbmode="..tostring(p.mbMode or "afterdots")..
    "|mbmana="..tostring(p.mbMana or 0)..
    "|dpmana="..tostring(p.dpMana or 0)..
    "|refresh="..tostring(p.refresh or 2)..
    "|smart="..Bool01(p.smartAuras ~= false)..
    "|verify="..tostring(p.verifyDelay or .75)..
    "|order="..table.concat(order, ",")..
    "|silence="..Bool01(pv.silence ~= false)..
    "|scream="..Bool01(pv.scream ~= false)..
    "|guard="..Bool01(pv.shadowguard)..
    "|touch="..Bool01(pv.touch)..
    "|assist="..Bool01(pv.assist)..
    "|hp="..tostring(pv.healthThreshold or 35)..
    "|skip="..tostring(p.targetHealthSkipDots or 0)..
    "|profileui="..Bool01(p.profileUi)
end

function SR.ParseProfileString(s)
  if type(s) ~= "string" or string.sub(s,1,4) ~= "SR17" then return nil, "invalid SR17 string" end
  local data = {}
  for part in string.gfind(s, "[^|]+") do
    local a,b = string.find(part, "=")
    if a then data[string.sub(part,1,a-1)] = string.sub(part,b+1) end
  end
  local function on(k) return data[k] == "1" end
  local order = {}
  if data.order then for item in string.gfind(data.order, "[^,]+") do table.insert(order,item) end end
  if SR.Count(order) == 0 then order = {"swp","ve","dp"} end
  local p = {
    enabled = { swp=on("swp"), ve=on("ve"), dp=on("dp") },
    mb = on("mb"),
    mbMode = data.mbmode or "afterdots",
    mbMana = tonumber(data.mbmana) or 0,
    dpMana = tonumber(data.dpmana) or 0,
    refresh = tonumber(data.refresh) or 2,
    smartAuras = data.smart ~= "0",
    verifyDelay = tonumber(data.verify) or .75,
    order = order,
    pvp = {
      silence = data.silence ~= "0",
      scream = data.scream ~= "0",
      shadowguard = on("guard"),
      touch = on("touch"),
      assist = on("assist"),
      healthThreshold = tonumber(data.hp) or 35,
    },
    targetHealthSkipDots = tonumber(data.skip) or 0,
    profileUi = on("profileui"),
  }
  return p, SR.Lower(data.name or "solo")
end

function SR.ImportProfileString(s, destination)
  local p, sourceName = SR.ParseProfileString(s)
  if not p then SR.Msg(sourceName or "profile import failed"); return false end
  local name = SR.Lower(destination or sourceName or "solo")
  if name ~= "solo" and name ~= "dungeon" and name ~= "raid" and name ~= "pvp" then
    SR.Msg("destination must be solo, dungeon, raid, or pvp")
    return false
  end
  SR.EnsureProfiles()
  SR.db.ui.profiles[name] = p
  SR.LoadProfile(name)
  SR.Msg("profile imported to "..name)
  return true
end

function SR.ProfileIOCreate()
  if SR.ProfileIOFrame then return end
  local f = CreateFrame("Frame", "ShadowRotationProfileIO", UIParent)
  f:SetWidth(560); f:SetHeight(210)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(0.008,0.006,0.022,0.96); bg:SetAllPoints(f)
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", f, "TOP", 0, -14); title:SetText("Profile Import / Export")

  local box = CreateFrame("EditBox", "ShadowRotationProfileIOBox", f, "InputBoxTemplate")
  box:SetWidth(500); box:SetHeight(28)
  box:SetPoint("TOP", f, "TOP", 0, -58)
  box:SetAutoFocus(false)
  box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
  f.box = box

  local export = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  export:SetWidth(105); export:SetHeight(23); export:SetPoint("TOPLEFT", f, "TOPLEFT", 28, -105)
  export:SetText("Export Active")
  export:SetScript("OnClick", function()
    f.box:SetText(SR.ExportProfileString())
    f.box:HighlightText()
    f.box:SetFocus()
  end)

  local import = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  import:SetWidth(105); import:SetHeight(23); import:SetPoint("TOPLEFT", f, "TOPLEFT", 143, -105)
  import:SetText("Import Active")
  import:SetScript("OnClick", function()
    SR.ImportProfileString(f.box:GetText(), SR.db.ui.activeProfile or "solo")
  end)

  local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  close:SetWidth(85); close:SetHeight(23); close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, 18)
  close:SetText("Close"); close:SetScript("OnClick", function() f:Hide() end)

  f:Hide(); SR.ProfileIOFrame = f
end

function SR.ProfileIOShow()
  if not SR.ProfileIOFrame then SR.ProfileIOCreate() end
  SR.ProfileIOFrame.box:SetText(SR.ExportProfileString())
  SR.ProfileIOFrame:Show()
end
-- ShadowRotation v18 Addon Health Monitor
SR.Modules.Health = true
SR.HealthFrame = nil

local function HFont(parent, size, justify)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f:SetFont("Fonts\\FRIZQT__.TTF", size or 11, "OUTLINE")
  f:SetJustifyH(justify or "LEFT")
  return f
end

function SR.HealthCreate()
  if SR.HealthFrame then return end
  local f = CreateFrame("Frame", "ShadowRotationHealth", UIParent)
  f:SetWidth(430); f:SetHeight(340)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(0.008,0.006,0.022,0.95); bg:SetAllPoints(f)
  local title = HFont(f, 15, "CENTER")
  title:SetPoint("TOP", f, "TOP", 0, -12)
  title:SetText("ShadowRotation System Health")

  f.lines = {}
  local i
  for i=1,14 do
    local line = HFont(f, 11, "LEFT")
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -45 - ((i-1)*19))
    line:SetWidth(380)
    f.lines[i] = line
  end

  local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  close:SetWidth(80); close:SetHeight(22)
  close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 14)
  close:SetText("Close")
  close:SetScript("OnClick", function() f:Hide() end)

  f:Hide()
  SR.HealthFrame = f
end

function SR.HealthShow()
  if not SR.HealthFrame then SR.HealthCreate() end
  local names = {"Core","Casting","Rotation","PvP","Coach","ProfileIO","HUD","Minimap","Options","Wizard","Commands","Health"}
  local values = {}
  local all = true
  local i
  table.insert(values, "Version: "..tostring(SHADOWROTATION_VERSION))
  table.insert(values, "Rotation pack: "..tostring(SR.db.rotationPack or "standard"))
  for i=1,SR.Count(names) do
    local n = names[i]
    local ok = SR.Modules and SR.Modules[n]
    if not ok then all = false end
    table.insert(values, n..": "..(ok and "OK" or "MISSING"))
  end
  table.insert(values, all and "System Status: READY" or "System Status: INCOMPLETE")
  for i=1,14 do SR.HealthFrame.lines[i]:SetText(values[i] or "") end
  SR.HealthFrame:Show()
end

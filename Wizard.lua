-- ShadowRotation v11 Setup Wizard
SR.Modules.Wizard = true
SR.WizardFrame = nil

local function fnt(parent, size)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
  return f
end

local function btn(parent, text, x, y, w, click)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetWidth(w or 90); b:SetHeight(24)
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  b:SetText(text)
  b:SetScript("OnClick", click)
  return b
end

function SR.Wizard_Create()
  if SR.WizardFrame then return end
  SR.Init()
  local f = CreateFrame("Frame", "ShadowRotationWizard", UIParent)
  f:SetWidth(360); f:SetHeight(260); f:SetPoint("CENTER", UIParent, "CENTER", 0, 0); f:SetFrameStrata("DIALOG")
  f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  local bg = f:CreateTexture(nil, "BACKGROUND"); bg:SetTexture(0.01,0.008,0.025,0.95); bg:SetAllPoints(f)
  local top = f:CreateTexture(nil, "ARTWORK"); top:SetTexture(0.42,0.02,0.90,0.45); top:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1); top:SetWidth(358); top:SetHeight(32)
  local title = fnt(f, 16); title:SetPoint("TOP", f, "TOP", 0, -8); title:SetText("ShadowRotation v14 Setup")
  local body = fnt(f, 12); body:SetPoint("TOP", f, "TOP", 0, -52); body:SetText("Choose a layout preset to get started.")
  btn(f, "Minimal", 35, -95, 130, function() SlashCmdList["SHADOWROTATION"]("layout minimal"); SR.db.ui.wizardDone=true; f:Hide() end)
  btn(f, "Compact", 195, -95, 130, function() SlashCmdList["SHADOWROTATION"]("layout compact"); SR.db.ui.wizardDone=true; f:Hide() end)
  btn(f, "Elite", 35, -135, 130, function() SlashCmdList["SHADOWROTATION"]("layout elite"); SR.db.ui.wizardDone=true; f:Hide() end)
  btn(f, "Raid", 195, -135, 130, function() SlashCmdList["SHADOWROTATION"]("layout raid"); SR.db.ui.wizardDone=true; f:Hide() end)
  btn(f, "Options", 35, -190, 130, function() if SR.Options_Show then SR.Options_Show() end end)
  btn(f, "Close", 195, -190, 130, function() SR.db.ui.wizardDone=true; f:Hide() end)
  f:Hide(); SR.WizardFrame = f
end

function SR.Wizard_Show()
  if not SR.WizardFrame then SR.Wizard_Create() end
  SR.WizardFrame:ClearAllPoints()
  SR.WizardFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  SR.WizardFrame:Show()
end
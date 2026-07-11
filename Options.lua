-- ShadowRotation v1.0.2 Insights Options
SR.Modules.Options = true
SR.OptionsFrame = nil
SR.OptionsTab = "general"
local checks = {}
local tabFrames = {}

local function fnt(parent, size)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
  return f
end

local function addTip(frame, title, body)
  if not frame then return end
  frame:SetScript("OnEnter", function()
    if SR and SR.db and SR.db.ui and SR.db.ui.tooltips == false then return end
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(title or "ShadowRotation")
    if body then GameTooltip:AddLine(body, 1, 1, 1) end
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local Tips = {
  swp = {"Shadow Word: Pain", "Apply/refresh SW:P in this profile."},
  ve = {"Vampiric Embrace", "Apply/refresh VE in this profile."},
  dp = {"Devouring Plague", "Use DP in this profile."},
  mb = {"Mind Blast", "Use Mind Blast when rules allow it."},
  hud = {"Next Spell", "Show/hide the separate next spell icon."},
  dots = {"DoTs", "Show/hide the DoT timer icons."},
  cds = {"Cooldowns", "Show/hide cooldown tracker icons."},
  queue = {"Queue", "Show/hide the prediction queue."},
  background = {"Background", "Toggle subtle background panels behind HUD modules."},
  minimap = {"Minimap", "Show/hide minimap button."},
  locked = {"Lock Frames", "Prevent moving HUD modules."},
  tooltips = {"Tooltips", "Show/hide mouseover help."},
  smart = {"Smart Aura Verification", "Checks the target's real debuff icons to recover from resisted, failed, manual, or dispelled DoTs."},
  coach = {"Rotation Coach", "Stores recent fights and creates an estimated score, grade, and coaching tip."},
  autoreport = {"Auto Fight Summary", "Prints a short score and grade when combat ends."},
  pswp = {"Profile SW:P", "Toggle SW:P for the currently active profile."},
  pve = {"Profile VE", "Toggle Vampiric Embrace for the currently active profile."},
  pdp = {"Profile DP", "Toggle Devouring Plague for the currently active profile."},
  pmb = {"Profile Mind Blast", "Toggle Mind Blast for the currently active profile."},
  profileui = {"Profile HUD State", "When enabled, this profile remembers tracker visibility, scale, and alpha. Positions are never changed."},
  pvpassist = {"PvP Assist", "Allows the rotation macro to cast enabled PvP utility suggestions while the PvP profile is active."},
  silence = {"Silence", "Recommend/cast Silence only when an enemy player is detected casting."},
  scream = {"Psychic Scream", "Recommend/cast Psychic Scream when your health is below the configured threshold."},
  guard = {"Shadowguard", "Maintain Shadowguard when learned and enabled."},
  touch = {"Touch of Weakness", "Maintain Touch of Weakness when learned and enabled."},
}

local function section(parent, title, x, y)
  local t = fnt(parent, 13); t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); t:SetText(title); return t
end

local function check(parent, key, label, x, y, getter, setter)
  local name = "SROpt14" .. key
  local c = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  c:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  getglobal(name .. "Text"):SetText(label)
  c.getter = getter; c.setter = setter
  c:SetScript("OnClick", function()
    local v = this:GetChecked() and true or false
    this.setter(v)
    if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end
    if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end
    if SR.HUD_Update then SR.HUD_Update() end
  end)
  if Tips[key] then addTip(c, Tips[key][1], Tips[key][2]) end
  table.insert(checks, c)
  return c
end

local function button(parent, text, x, y, w, click, tip)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetWidth(w or 92); b:SetHeight(23)
  b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  b:SetText(text)
  b:SetScript("OnClick", click)
  if tip then addTip(b, text, tip) end
  return b
end

local function page(parent)
  local p = CreateFrame("Frame", nil, parent)
  p:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -80)
  p:SetWidth(520); p:SetHeight(280)
  table.insert(tabFrames, p)
  return p
end

function SR.Options_Refresh()
  local i
  for i=1,SR.Count(checks) do
    local c = checks[i]
    if c and c.getter then c:SetChecked(c.getter()) end
  end
end

function SR.Options_ShowTab(tab)
  SR.OptionsTab = tab or SR.OptionsTab or "general"
  local i
  for i=1,SR.Count(tabFrames) do tabFrames[i]:Hide() end
  if SR.OptionsFrame and SR.OptionsFrame.pages and SR.OptionsFrame.pages[SR.OptionsTab] then
    SR.OptionsFrame.pages[SR.OptionsTab]:Show()
  end
  SR.Options_Refresh()
end

function SR.Options_Create()
  if SR.OptionsFrame then return end
  SR.Init()
  if SR.EnsureProfiles then SR.EnsureProfiles() end

  local f = CreateFrame("Frame", "ShadowRotationOptions", UIParent)
  f:SetWidth(560); f:SetHeight(420); f:SetPoint("CENTER", UIParent, "CENTER", 0, 0); f:SetFrameStrata("DIALOG")
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  local bg = f:CreateTexture(nil, "BACKGROUND"); bg:SetTexture(0.008,0.006,0.022,0.93); bg:SetAllPoints(f)
  local top = f:CreateTexture(nil, "ARTWORK"); top:SetTexture(0.28,0.02,0.55,0.35); top:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1); top:SetWidth(558); top:SetHeight(32)
  local title = fnt(f, 16); title:SetPoint("TOP", f, "TOP", 0, -8); title:SetText("ShadowRotation v" .. tostring(SHADOWROTATION_VERSION or "1.0.2"))

  button(f, "General", 18, -45, 82, function() SR.Options_ShowTab("general") end)
  button(f, "Rotation", 108, -45, 82, function() SR.Options_ShowTab("rotation") end)
  button(f, "HUD", 198, -45, 82, function() SR.Options_ShowTab("hud") end)
  button(f, "Profiles", 288, -45, 82, function() SR.Options_ShowTab("profiles") end)
  button(f, "About", 378, -45, 82, function() SR.Options_ShowTab("about") end)

  f.pages = {}
  local general = page(f); f.pages.general = general
  section(general, "General", 0, 0)
  check(general, "minimap", "Minimap Button", 0, -35, function() return SR.db.ui.minimap end, function(v) SR.db.ui.minimap=v; if SR.Minimap_Apply then SR.Minimap_Apply() end end)
  check(general, "tooltips", "Mouseover Tooltips", 0, -70, function() return SR.db.ui.tooltips end, function(v) SR.db.ui.tooltips=v end)
  check(general, "locked", "Lock Frames", 0, -105, function() return SR.db.ui.locked end, function(v) SR.db.ui.locked=v; if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end end)
  button(general, "Wizard", 260, -35, 95, function() if SR.Wizard_Show then SR.Wizard_Show() end end, "Open setup wizard.")
  button(general, "Defaults", 260, -70, 95, function() if SR.ResetDefaults then SR.ResetDefaults() end; SR.Options_Refresh(); SR.Msg("defaults restored") end, "Restore defaults.")

  local rotation = page(f); f.pages.rotation = rotation
  section(rotation, "Rotation", 0, 0)
  check(rotation, "swp", "Shadow Word: Pain", 0, -35, function() return SR.db.enabled.swp end, function(v) SR.db.enabled.swp=v; SR.ResetRotation() end)
  check(rotation, "ve", "Vampiric Embrace", 0, -70, function() return SR.db.enabled.ve end, function(v) SR.db.enabled.ve=v; SR.ResetRotation() end)
  check(rotation, "dp", "Devouring Plague", 0, -105, function() return SR.db.enabled.dp end, function(v) SR.db.enabled.dp=v; SR.ResetRotation() end)
  check(rotation, "mb", "Mind Blast", 0, -140, function() return SR.db.mb end, function(v) SR.db.mb=v end)
  button(rotation, "MB After", 260, -35, 95, function() SR.db.mb=true; SR.db.mbMode="afterdots"; if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end; SR.Msg("MB after dots") end)
  button(rotation, "MB Before", 365, -35, 95, function() SR.db.mb=true; SR.db.mbMode="beforedots"; if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end; SR.Msg("MB before dots") end)
  section(rotation, "Rotation Packs", 260, -90)
  button(rotation, "Standard", 260, -120, 95, function() SR.ApplyRotationPack("standard") end, "Balanced rotation.")
  button(rotation, "Mana Saver", 365, -120, 95, function() SR.ApplyRotationPack("mana") end, "Higher mana thresholds and low-health DoT skipping.")
  button(rotation, "Max DPS", 260, -155, 95, function() SR.ApplyRotationPack("maxdps") end, "Aggressive Mind Blast and DoT usage.")
  button(rotation, "PvP Pressure", 365, -155, 95, function() SR.ApplyRotationPack("pvp") end, "PvP-oriented priority setup.")
  button(rotation, "Leveling", 260, -190, 95, function() SR.ApplyRotationPack("leveling") end, "Efficient questing setup.")
  button(rotation, "Simulation ON", 260, -225, 95, function() SR.db.simulation.enabled=true; SR.Msg("simulation on") end, "Use one-cast lookahead before Mind Blast.")
  button(rotation, "Simulation OFF", 365, -225, 95, function() SR.db.simulation.enabled=false; SR.Msg("simulation off") end, "Disable one-cast lookahead.")


  local hud = page(f); f.pages.hud = hud
  section(hud, "HUD Modules", 0, 0)
  check(hud, "hud", "Next Spell Icon", 0, -35, function() return SR.db.ui.hud end, function(v) SR.db.ui.hud=v end)
  check(hud, "dots", "DoT Icons", 0, -70, function() return SR.db.ui.dots end, function(v) SR.db.ui.dots=v end)
  check(hud, "cds", "Cooldown Icons", 0, -105, function() return SR.db.ui.cds end, function(v) SR.db.ui.cds=v end)
  check(hud, "queue", "Prediction Queue", 0, -140, function() return SR.db.ui.queue end, function(v) SR.db.ui.queue=v end)
  check(hud, "background", "HUD Background", 0, -175, function() return SR.db.ui.background end, function(v) SR.db.ui.background=v end)
  button(hud, "Scale +", 260, -35, 95, function() SR.db.ui.scale=(SR.db.ui.scale or 1)+0.1; SR.HUD_ApplySettings() end)
  button(hud, "Scale -", 365, -35, 95, function() SR.db.ui.scale=math.max(.6,(SR.db.ui.scale or 1)-0.1); SR.HUD_ApplySettings() end)
  button(hud, "Alpha +", 260, -70, 95, function() SR.db.ui.alpha=math.min(1,(SR.db.ui.alpha or .9)+.05); SR.HUD_ApplySettings() end)
  button(hud, "Alpha -", 365, -70, 95, function() SR.db.ui.alpha=math.max(.3,(SR.db.ui.alpha or .9)-.05); SR.HUD_ApplySettings() end)
  button(hud, "Reset UI", 260, -105, 95, function() SR.db.ui.x=0; SR.db.ui.y=-200; SR.db.ui.nextX=0; SR.db.ui.nextY=-95; SR.db.ui.dotX=-78; SR.db.ui.dotY=-168; SR.db.ui.cdX=78; SR.db.ui.cdY=-168; SR.db.ui.queueX=0; SR.db.ui.queueY=-220; SR.HUD_ApplySettings(); SR.Msg("UI reset") end)

  local profiles = page(f); f.pages.profiles = profiles
  section(profiles, "Profiles + Rotation", 0, 0)
  button(profiles, "Solo", 0, -35, 95, function() if SR.LoadProfile then SR.LoadProfile("solo") end; SR.Options_Refresh(); SR.Msg("profile solo") end)
  button(profiles, "Dungeon", 105, -35, 95, function() if SR.LoadProfile then SR.LoadProfile("dungeon") end; SR.Options_Refresh(); SR.Msg("profile dungeon") end)
  button(profiles, "Raid", 210, -35, 95, function() if SR.LoadProfile then SR.LoadProfile("raid") end; SR.Options_Refresh(); SR.Msg("profile raid") end)
  button(profiles, "PvP", 315, -35, 95, function() if SR.LoadProfile then SR.LoadProfile("pvp") end; SR.Options_Refresh(); SR.Msg("profile pvp") end)

  check(profiles, "pswp", "SW:P", 0, -80, function() return SR.db.enabled.swp end, function(v) SR.db.enabled.swp=v; SR.ResetRotation() end)
  check(profiles, "pve", "VE", 85, -80, function() return SR.db.enabled.ve end, function(v) SR.db.enabled.ve=v; SR.ResetRotation() end)
  check(profiles, "pdp", "DP", 150, -80, function() return SR.db.enabled.dp end, function(v) SR.db.enabled.dp=v; SR.ResetRotation() end)
  check(profiles, "pmb", "Mind Blast", 215, -80, function() return SR.db.mb end, function(v) SR.db.mb=v end)
  check(profiles, "profileui", "Save HUD state", 330, -80, function() return SR.db.profileUi end, function(v) SR.db.profileUi=v end)

  section(profiles, "Rotation", 0, -125)
  button(profiles, "SWP > VE > DP", 0, -153, 120, function() SR.db.order={"swp","ve","dp"}; SR.SaveCurrentProfile(); SR.ResetRotation(); SR.Msg("order SWP > VE > DP") end)
  button(profiles, "VE > SWP > DP", 130, -153, 120, function() SR.db.order={"ve","swp","dp"}; SR.SaveCurrentProfile(); SR.ResetRotation(); SR.Msg("order VE > SWP > DP") end)
  button(profiles, "SWP > DP > VE", 260, -153, 120, function() SR.db.order={"swp","dp","ve"}; SR.SaveCurrentProfile(); SR.ResetRotation(); SR.Msg("order SWP > DP > VE") end)
  button(profiles, "MB After", 0, -188, 95, function() SR.db.mb=true; SR.db.mbMode="afterdots"; SR.SaveCurrentProfile(); SR.Options_Refresh(); SR.Msg("MB after dots") end)
  button(profiles, "MB Before", 105, -188, 95, function() SR.db.mb=true; SR.db.mbMode="beforedots"; SR.SaveCurrentProfile(); SR.Options_Refresh(); SR.Msg("MB before dots") end)
  button(profiles, "Skip DoTs 15%", 210, -188, 110, function() SR.db.targetHealthSkipDots=15; SR.SaveCurrentProfile(); SR.Msg("skip DoTs below 15%") end)
  button(profiles, "Never Skip", 330, -188, 95, function() SR.db.targetHealthSkipDots=0; SR.SaveCurrentProfile(); SR.Msg("low-health DoT skip off") end)

  section(profiles, "PvP profile options", 0, -228)
  check(profiles, "pvpassist", "PvP Assist", 0, -252, function() return SR.db.pvp and SR.db.pvp.assist end, function(v) SR.db.pvp.assist=v end)
  check(profiles, "silence", "Silence", 110, -252, function() return SR.db.pvp and SR.db.pvp.silence end, function(v) SR.db.pvp.silence=v end)
  check(profiles, "scream", "Scream", 205, -252, function() return SR.db.pvp and SR.db.pvp.scream end, function(v) SR.db.pvp.scream=v end)
  check(profiles, "guard", "Shadowguard", 300, -252, function() return SR.db.pvp and SR.db.pvp.shadowguard end, function(v) SR.db.pvp.shadowguard=v end)
  check(profiles, "touch", "Touch", 420, -252, function() return SR.db.pvp and SR.db.pvp.touch end, function(v) SR.db.pvp.touch=v end)

  button(profiles, "Save", 0, -290, 95, function() SR.SaveCurrentProfile(); SR.Msg("profile saved") end)
  button(profiles, "Reset Active", 105, -290, 105, function() SR.ResetProfile(SR.db.ui.activeProfile or "solo"); SR.Options_Refresh(); SR.Msg("active profile reset") end)
  button(profiles, "Import/Export", 220, -290, 105, function() if SR.ProfileIOShow then SR.ProfileIOShow() end end)

  local about = page(f); f.pages.about = about
  section(about, "About", 0, 0)
  local txt = fnt(about, 11)
  txt:SetPoint("TOPLEFT", about, "TOPLEFT", 0, -35)
  txt:SetText("ShadowRotation intelligence tools. HUD modules are unchanged.")
  button(about, "Report", 0, -80, 95, function() if SR.Report then SR.Report() end end)
  button(about, "History", 105, -80, 95, function() if SR.History then SR.History() end end)
  button(about, "Coach", 210, -80, 95, function() if SR.CoachShow then SR.CoachShow() end end)
  button(about, "Profile I/O", 315, -80, 95, function() if SR.ProfileIOShow then SR.ProfileIOShow() end end)
  button(about, "Analytics", 0, -120, 95, function() if SR.Analytics_Show then SR.Analytics_Show() end end)
  button(about, "System Health", 105, -120, 105, function() if SR.HealthShow then SR.HealthShow() end end)
  button(about, "Explain", 220, -120, 95, function() SR.Msg(SR.ExplainDecision()) end)
  button(about, "Insights", 325, -120, 95, function() if SR.InsightsShow then SR.InsightsShow() end end)

  button(f, "Close", 450, -380, 85, function() f:Hide() end)
  f:Hide(); SR.OptionsFrame = f
  SR.Options_ShowTab("general")
end

function SR.Options_Show()
  if not SR.OptionsFrame then SR.Options_Create() end
  SR.OptionsFrame:ClearAllPoints()
  SR.OptionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  SR.OptionsFrame:Show()
  SR.Options_ShowTab(SR.OptionsTab or "general")
end

function SR.Options_Toggle()
  if not SR.OptionsFrame then SR.Options_Create() end
  if SR.OptionsFrame:IsShown() then SR.OptionsFrame:Hide() else SR.Options_Show() end
end
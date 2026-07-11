-- ShadowRotation v19 Simulation, Trends, Statistics, and Auto-Tuning
SR.Modules.Insights = true
SR.InsightsFrame = nil

local function IFont(parent, size, justify)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f:SetFont("Fonts\\FRIZQT__.TTF", size or 11, "OUTLINE")
  f:SetJustifyH(justify or "LEFT")
  return f
end

function SR.InsightsEnsure()
  SR.Init()
  if type(SR.db.simulation) ~= "table" then SR.db.simulation = { enabled = true, lookahead = 1.5 } end
  if type(SR.db.insights) ~= "table" then SR.db.insights = { maxTimeline = 30 } end
end

function SR.SimulationSummary()
  SR.InsightsEnsure()
  if not SR.ValidTarget() then return "No valid hostile target." end
  local nextSpell = SR.NextSpellName()
  local reason = SR.DecisionReason and SR.DecisionReason(nextSpell) or "Current priority."
  local second = "Mind Flay"
  if nextSpell == "Mind Blast" then
    local id, spell = SR.DotExpiringWithin((SR.db.simulation.lookahead or 1.5) + 1.5)
    if spell then second = spell end
  elseif SR.MBAllowed and SR.MBAllowed() then
    second = "Mind Blast"
  end
  return "Now: "..nextSpell.." | Then: "..second.." | "..reason
end

function SR.TrendSummary()
  SR.CoachEnsure()
  local fights = SR.db.coach.fights or {}
  local count = SR.Count(fights)
  if count == 0 then return "No completed fights yet." end

  local recentN = math.min(5, count)
  local previousN = math.min(5, math.max(0, count - recentN))
  local recent = 0
  local previous = 0
  local i
  for i=1,recentN do recent = recent + (fights[i].score or 0) end
  for i=recentN+1,recentN+previousN do previous = previous + (fights[i].score or 0) end
  recent = recent / recentN

  if previousN == 0 then
    return "Recent average: "..string.format("%.1f",recent).." ("..recentN.." fights)"
  end

  previous = previous / previousN
  local delta = recent - previous
  local direction = "steady"
  if delta >= 2 then direction = "improving"
  elseif delta <= -2 then direction = "declining" end

  return "Recent: "..string.format("%.1f",recent)..
    " | Previous: "..string.format("%.1f",previous)..
    " | Trend: "..direction.." ("..string.format("%+.1f",delta)..")"
end

function SR.SpellStatistics()
  SR.CoachEnsure()
  local totals = { swp=0, ve=0, dp=0, mb=0, mf=0, fights=0, seconds=0 }
  local fights = SR.db.coach.fights or {}
  local i
  for i=1,SR.Count(fights) do
    local x = fights[i]
    totals.swp = totals.swp + (x.swp or 0)
    totals.ve = totals.ve + (x.ve or 0)
    totals.dp = totals.dp + (x.dp or 0)
    totals.mb = totals.mb + (x.mb or 0)
    totals.mf = totals.mf + (x.mf or 0)
    totals.seconds = totals.seconds + (x.duration or 0)
    totals.fights = totals.fights + 1
  end
  return totals
end

function SR.TuningSuggestion()
  SR.CoachEnsure()
  local fights = SR.db.coach.fights or {}
  local count = SR.Count(fights)
  if count < 3 then return "Complete at least 3 fights before tuning suggestions." end

  local manaEnd = 0
  local short = 0
  local failed = 0
  local busy = 0
  local i
  for i=1,count do
    local x = fights[i]
    manaEnd = manaEnd + (x.manaEnd or 50)
    if (x.duration or 0) < 20 then short = short + 1 end
    failed = failed + (x.failedDots or 0)
    busy = busy + (x.busySkips or 0)
  end
  manaEnd = manaEnd / count

  if manaEnd < 18 then return "Suggestion: try the Mana Saver pack; average ending mana is low." end
  if short >= math.ceil(count * 0.6) then return "Suggestion: try the Leveling pack; most recorded fights are short." end
  if failed > count then return "Suggestion: keep Smart Aura Verification on; many DoTs failed or were dispelled." end
  if busy > count * 20 then return "Suggestion: press the macro less during active casts/channels." end
  if manaEnd > 60 then return "Suggestion: Max DPS may be safe; average ending mana is high." end
  return "Current rotation pack appears well matched to your recent fights."
end

function SR.InsightsCreate()
  if SR.InsightsFrame then return end
  local f = CreateFrame("Frame", "ShadowRotationInsights", UIParent)
  f:SetWidth(520); f:SetHeight(410)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(0.008,0.006,0.022,0.95); bg:SetAllPoints(f)
  local title = IFont(f, 15, "CENTER")
  title:SetPoint("TOP", f, "TOP", 0, -12)
  title:SetText("ShadowRotation Insights")

  f.lines = {}
  local i
  for i=1,17 do
    local line = IFont(f, 11, "LEFT")
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -44 - ((i-1)*19))
    line:SetWidth(470)
    f.lines[i] = line
  end

  local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  close:SetWidth(80); close:SetHeight(22)
  close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 14)
  close:SetText("Close")
  close:SetScript("OnClick", function() f:Hide() end)

  f:Hide()
  SR.InsightsFrame = f
end

function SR.InsightsShow()
  SR.InsightsEnsure()
  if not SR.InsightsFrame then SR.InsightsCreate() end

  local values = {}
  local stats = SR.SpellStatistics()
  table.insert(values, "Rotation pack: "..tostring(SR.db.rotationPack or "standard"))
  table.insert(values, "Simulation: "..(SR.db.simulation.enabled and "ON" or "OFF")..
    "   Lookahead: "..string.format("%.1f",SR.db.simulation.lookahead or 1.5).." sec")
  table.insert(values, SR.TrendSummary())
  table.insert(values, SR.TuningSuggestion())
  table.insert(values, "")
  table.insert(values, "Recorded fights: "..stats.fights.."   Combat time: "..string.format("%.0f",stats.seconds).." sec")
  table.insert(values, "SW:P casts: "..stats.swp.."   VE: "..stats.ve.."   DP: "..stats.dp)
  table.insert(values, "Mind Blast: "..stats.mb.."   Mind Flay: "..stats.mf)
  table.insert(values, "")
  table.insert(values, "Latest cast timeline:")

  local history = SR.db.stats and SR.db.stats.history or {}
  local i
  local shown = 0
  for i=math.max(1, SR.Count(history)-5),SR.Count(history) do
    local e = history[i]
    if e then
      table.insert(values, string.format("%.1f", (e.t or 0) - (SR.db.stats.start or e.t or 0)).."  "..tostring(e.s))
      shown = shown + 1
    end
  end
  if shown == 0 then table.insert(values, "No current timeline recorded.") end

  for i=1,17 do SR.InsightsFrame.lines[i]:SetText(values[i] or "") end
  SR.InsightsFrame:Show()
end

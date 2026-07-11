-- ShadowRotation v19.0 Advanced Rotation Coach
SR.Modules.Coach = true
SR.CoachFrame = nil

local function CFont(parent, size, justify)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f:SetFont("Fonts\\FRIZQT__.TTF", size or 11, "OUTLINE")
  f:SetJustifyH(justify or "LEFT")
  return f
end

function SR.CoachEnsure()
  SR.Init()
  if type(SR.db.coach) ~= "table" then
    SR.db.coach = { enabled = true, autoReport = false, maxFights = 10, fights = {}, current = nil }
  end
  if type(SR.db.coach.fights) ~= "table" then SR.db.coach.fights = {} end
end

function SR.CoachStartFight()
  SR.CoachEnsure()
  if not SR.db.coach.enabled then return end
  local now = SR.Now()
  SR.db.stats = { active = true, start = now, last = now, casts = {}, history = {} }
  local d = SR.db.diagnostics or {}
  SR.db.coach.current = {
    start = now,
    profile = SR.db.ui and SR.db.ui.activeProfile or "solo",
    rotationPack = SR.db.rotationPack or "standard",
    failedStart = d.failedDots or 0,
    busyStart = d.busySkips or 0,
    gcdStart = d.gcdSkips or 0,
    manaStart = SR.ManaPct and SR.ManaPct() or 100,
  }
end

function SR.CoachScore(snapshot)
  local score = 70
  if (snapshot.mf or 0) > 0 then score = score + 10 end
  if (snapshot.mb or 0) > 0 or not snapshot.mbEnabled then score = score + 10 end
  if ((snapshot.swp or 0) + (snapshot.ve or 0) + (snapshot.dp or 0)) >= 3 then score = score + 10 end
  score = score - math.min(10, (snapshot.failedDots or 0) * 2)
  score = score - math.min(10, math.floor((snapshot.busySkips or 0) / 12))
  if score < 0 then score = 0 end
  if score > 100 then score = 100 end
  return score
end

function SR.CoachGrade(score)
  if score >= 97 then return "A+" end
  if score >= 90 then return "A" end
  if score >= 82 then return "B" end
  if score >= 70 then return "C" end
  return "D"
end

function SR.CoachFinishFight()
  SR.CoachEnsure()
  local cur = SR.db.coach.current
  local s = SR.db.stats
  if not cur or not s or not s.start then return end

  local now = SR.Now()
  local d = SR.db.diagnostics or {}
  local snapshot = {
    duration = math.max(1, (s.last or now) - s.start),
    profile = cur.profile or "solo",
    rotationPack = cur.rotationPack or "standard",
    total = 0,
    swp = s.casts and s.casts["Shadow Word: Pain"] or 0,
    ve = s.casts and s.casts["Vampiric Embrace"] or 0,
    dp = s.casts and s.casts["Devouring Plague"] or 0,
    mb = s.casts and s.casts["Mind Blast"] or 0,
    mf = s.casts and s.casts["Mind Flay"] or 0,
    mbEnabled = SR.db.mb and true or false,
    failedDots = math.max(0, (d.failedDots or 0) - (cur.failedStart or 0)),
    busySkips = math.max(0, (d.busySkips or 0) - (cur.busyStart or 0)),
    gcdSkips = math.max(0, (d.gcdSkips or 0) - (cur.gcdStart or 0)),
    finished = now,
    manaStart = cur.manaStart or 100,
    manaEnd = SR.ManaPct and SR.ManaPct() or 100,
  }
  local k,v
  if s.casts then for k,v in pairs(s.casts) do snapshot.total = snapshot.total + v end end
  snapshot.score = SR.CoachScore(snapshot)
  snapshot.grade = SR.CoachGrade(snapshot.score)

  table.insert(SR.db.coach.fights, 1, snapshot)
  while SR.Count(SR.db.coach.fights) > (SR.db.coach.maxFights or 20) do
    table.remove(SR.db.coach.fights)
  end

  SR.db.coach.current = nil
  s.active = false
  if SR.db.coach.autoReport then
    SR.Msg("Fight "..string.format("%.0f",snapshot.duration).."s | Score "..snapshot.score.." | Grade "..snapshot.grade)
  end
end

function SR.CoachTip(snapshot)
  if not snapshot then return "Complete a fight to receive coaching." end
  if snapshot.failedDots and snapshot.failedDots > 0 then return "A DoT failed verification; watch for resists or dispels." end
  if snapshot.mbEnabled and (snapshot.mb or 0) == 0 then return "Mind Blast was enabled but not used." end
  if (snapshot.mf or 0) == 0 then return "No Mind Flay casts were recorded." end
  if ((snapshot.swp or 0)+(snapshot.ve or 0)+(snapshot.dp or 0)) < 3 then return "One or more configured DoTs were not used." end
  if snapshot.busySkips and snapshot.busySkips > 20 then return "Many presses happened during a cast or channel." end
  return "Clean rotation. Keep the same consistency."
end


function SR.CoachSummary()
  SR.CoachEnsure()
  local fights = SR.db.coach.fights
  local count = SR.Count(fights)
  if count == 0 then return 0, 0, 0, "No fights yet." end

  local totalScore = 0
  local best = 0
  local issues = { failed = 0, mb = 0, mf = 0, dots = 0, busy = 0 }
  local i
  for i=1,count do
    local x = fights[i]
    totalScore = totalScore + (x.score or 0)
    if (x.score or 0) > best then best = x.score or 0 end
    if (x.failedDots or 0) > 0 then issues.failed = issues.failed + 1 end
    if x.mbEnabled and (x.mb or 0) == 0 then issues.mb = issues.mb + 1 end
    if (x.mf or 0) == 0 then issues.mf = issues.mf + 1 end
    if ((x.swp or 0)+(x.ve or 0)+(x.dp or 0)) < 3 then issues.dots = issues.dots + 1 end
    if (x.busySkips or 0) > 20 then issues.busy = issues.busy + 1 end
  end

  local common = "Clean and consistent."
  local maxIssue = 0
  local key, value
  for key,value in pairs(issues) do
    if value > maxIssue then maxIssue = value; common = key end
  end
  if common == "failed" then common = "Most common issue: failed or dispelled DoTs."
  elseif common == "mb" then common = "Most common issue: Mind Blast enabled but unused."
  elseif common == "mf" then common = "Most common issue: no Mind Flay recorded."
  elseif common == "dots" then common = "Most common issue: one or more DoTs not used."
  elseif common == "busy" then common = "Most common issue: many presses during casts/channels."
  end

  return count, totalScore / count, best, common
end

function SR.CoachCreate()
  if SR.CoachFrame then return end
  local f = CreateFrame("Frame", "ShadowRotationCoach", UIParent)
  f:SetWidth(500); f:SetHeight(390)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 25)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(0.008,0.006,0.022,0.95); bg:SetAllPoints(f)
  local title = CFont(f, 16, "CENTER")
  title:SetPoint("TOP", f, "TOP", 0, -12)
  title:SetText("ShadowRotation Coach")

  f.lines = {}
  local i
  for i=1,18 do
    local line = CFont(f, 11, "LEFT")
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -45 - ((i-1)*19))
    line:SetWidth(450)
    f.lines[i] = line
  end

  local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  close:SetWidth(80); close:SetHeight(22)
  close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 14)
  close:SetText("Close")
  close:SetScript("OnClick", function() f:Hide() end)

  f:Hide()
  SR.CoachFrame = f
end

function SR.CoachShow()
  SR.CoachEnsure()
  if not SR.CoachFrame then SR.CoachCreate() end
  local f = SR.CoachFrame
  local values = {}
  local latest = SR.db.coach.fights[1]

  if latest then
    table.insert(values, "Latest fight: "..string.format("%.0f",latest.duration).." sec   Profile: "..tostring(latest.profile).."   Pack: "..tostring(latest.rotationPack or "standard"))
    table.insert(values, "Score: "..tostring(latest.score).."   Grade: "..tostring(latest.grade))
    table.insert(values, "SW:P "..latest.swp.."   VE "..latest.ve.."   DP "..latest.dp.."   MB "..latest.mb.."   MF "..latest.mf)
    table.insert(values, "Failed DoTs "..latest.failedDots.."   Busy skips "..latest.busySkips.."   Throttle skips "..latest.gcdSkips)
    table.insert(values, "Coach: "..SR.CoachTip(latest))
    local count, average, best, common = SR.CoachSummary()
    table.insert(values, "Average: "..string.format("%.1f",average).."   Best: "..best.."   Fights: "..count)
    table.insert(values, common)
    table.insert(values, "")
    table.insert(values, "Recent fights:")
    local i
    for i=1,math.min(8, SR.Count(SR.db.coach.fights)) do
      local x = SR.db.coach.fights[i]
      table.insert(values, i..". "..string.format("%.0f",x.duration).."s  "..x.profile.."  Score "..x.score.."  Grade "..x.grade)
    end
  else
    table.insert(values, "No completed fights recorded yet.")
    table.insert(values, "Enter combat and finish a fight to create a report.")
  end

  local i
  for i=1,18 do f.lines[i]:SetText(values[i] or "") end
  f:Show()
end

local coachEvent = CreateFrame("Frame")
coachEvent:RegisterEvent("PLAYER_REGEN_DISABLED")
coachEvent:RegisterEvent("PLAYER_REGEN_ENABLED")
coachEvent:SetScript("OnEvent", function()
  if event == "PLAYER_REGEN_DISABLED" then SR.CoachStartFight()
  elseif event == "PLAYER_REGEN_ENABLED" then SR.CoachFinishFight() end
end)
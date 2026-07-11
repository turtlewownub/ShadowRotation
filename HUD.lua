-- ShadowRotation v16.1 Safe Floating HUD
SR.Modules.HUD = true
SR.HUD = nil
SR.NextFrame = nil
SR.DotFrame = nil
SR.CDFrame = nil
SR.QueueFrame = nil
SR.HUD_LOADED = true

-- Safe early stubs; real functions are defined later in this file.
SR.HUD_ApplySettings = SR.HUD_ApplySettings or function() end
SR.SaveAllFramePositions = SR.SaveAllFramePositions or function() end


local function font(parent, size, justify)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetFont("Fonts\\FRIZQT__.TTF", size or 10, "OUTLINE")
  fs:SetJustifyH(justify or "CENTER")
  return fs
end

local function tex(parent, layer, r,g,b,a)
  local t = parent:CreateTexture(nil, layer or "ARTWORK")
  t:SetTexture(r or 0, g or 0, b or 0, a or 1)
  return t
end

local function makePanel(f, title)
  local bg = tex(f, "BACKGROUND", 0.004, 0.003, 0.015, 0.55)
  bg:SetAllPoints(f)
  local head = tex(f, "ARTWORK", 0.24, 0.02, 0.45, 0.22)
  head:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
  head:SetWidth(f:GetWidth() - 2)
  head:SetHeight(14)
  local titleText = font(f, 9, "CENTER")
  titleText:SetPoint("TOP", f, "TOP", 0, -3)
  titleText:SetText(title or "")
  f.bg = bg; f.head = head; f.title = titleText
end

local function applyPanel(f)
  if not f or not SR.db or not SR.db.ui then return end
  local show = SR.db.ui.background and true or false
  if f.bg then if show then f.bg:Show() else f.bg:Hide() end end
  if f.head then if show then f.head:Show() else f.head:Hide() end end
  if f.title then if show then f.title:Show() else f.title:Hide() end end
end


local function clampCoord(x, y, frame)
  x = x or 0
  y = y or 0

  local sw = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 800
  local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 600
  local scale = (frame and frame.GetScale and frame:GetScale()) or 1
  local fw = ((frame and frame.GetWidth and frame:GetWidth()) or 100) * scale
  local fh = ((frame and frame.GetHeight and frame:GetHeight()) or 50) * scale
  local margin = 10

  local maxX = math.max(0, (sw - fw) / 2 - margin)
  local maxY = math.max(0, (sh - fh) / 2 - margin)

  if x > maxX then x = maxX end
  if x < -maxX then x = -maxX end
  if y > maxY then y = maxY end
  if y < -maxY then y = -maxY end

  return x, y
end

local function saveFramePosition(frame, keyx, keyy)
  if not frame or not SR.db or not SR.db.ui then return end

  -- Tracker movement always finishes on a CENTER-to-CENTER anchor. Saving the
  -- anchor offsets directly avoids scale-dependent GetCenter conversions.
  local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
  if point == "CENTER" and relativeTo == UIParent and relativePoint == "CENTER" and x and y then
    x, y = clampCoord(x, y, frame)
    SR.db.ui[keyx] = x
    SR.db.ui[keyy] = y
    return
  end

  -- Compatibility fallback for an older or externally modified anchor.
  local fx, fy = frame:GetCenter()
  local px, py = UIParent:GetCenter()
  if fx and fy and px and py then
    x = fx - px
    y = fy - py
    x, y = clampCoord(x, y, frame)
    SR.db.ui[keyx] = x
    SR.db.ui[keyy] = y
  end
end

local function mover(f, keyx, keyy)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")

  f:SetScript("OnDragStart", function()
    if not SR.db or not SR.db.ui or SR.db.ui.locked then return end

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = (UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or UIParent:GetScale() or 1

    -- Capture the existing saved/anchored offset and move only by the cursor
    -- delta. We never mix the tracker's own scale with physical cursor pixels,
    -- which prevents the initial up-and-right jump on OctoWoW/Turtle WoW.
    local point, relativeTo, relativePoint, anchorX, anchorY = this:GetPoint(1)
    if point ~= "CENTER" or relativeTo ~= UIParent or relativePoint ~= "CENTER" then
      local fx, fy = this:GetCenter()
      local px, py = UIParent:GetCenter()
      if not fx or not fy or not px or not py then return end
      anchorX = fx - px
      anchorY = fy - py
    end

    this.dragStartCursorX = cursorX / uiScale
    this.dragStartCursorY = cursorY / uiScale
    this.dragStartX = anchorX or 0
    this.dragStartY = anchorY or 0
    this.isDragging = true

    this:SetScript("OnUpdate", function()
      if not this.isDragging then return end

      local currentX, currentY = GetCursorPosition()
      local scale = (UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or UIParent:GetScale() or 1
      currentX = currentX / scale
      currentY = currentY / scale

      local newX = (this.dragStartX or 0) + currentX - (this.dragStartCursorX or currentX)
      local newY = (this.dragStartY or 0) + currentY - (this.dragStartCursorY or currentY)
      newX, newY = clampCoord(newX, newY, this)

      this:ClearAllPoints()
      this:SetPoint("CENTER", UIParent, "CENTER", newX, newY)
    end)
  end)

  f:SetScript("OnDragStop", function()
    if not this.isDragging then return end

    this.isDragging = false
    this:SetScript("OnUpdate", nil)
    saveFramePosition(this, keyx, keyy)

    this.dragStartCursorX = nil
    this.dragStartCursorY = nil
    this.dragStartX = nil
    this.dragStartY = nil
  end)
end

local function icon(parent, size, timerSize)
  local f = CreateFrame("Frame", nil, parent)
  f:SetWidth(size); f:SetHeight(size + 14)
  local image = f:CreateTexture(nil, "ARTWORK")
  image:SetWidth(size); image:SetHeight(size); image:SetPoint("TOP", f, "TOP", 0, 0)

  local shade = f:CreateTexture(nil, "OVERLAY")
  shade:SetTexture(0,0,0,0.42); shade:SetWidth(size); shade:SetHeight(size); shade:SetPoint("CENTER", image, "CENTER", 0, 0); shade:Hide()

  local glow = f:CreateTexture(nil, "OVERLAY")
  glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  glow:SetBlendMode("ADD")
  glow:SetWidth(size + 16); glow:SetHeight(size + 16); glow:SetPoint("CENTER", image, "CENTER", 0, 0)

  local alert = f:CreateTexture(nil, "OVERLAY")
  alert:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  alert:SetBlendMode("ADD"); alert:SetVertexColor(1, 0.05, 0.05)
  alert:SetWidth(size + 20); alert:SetHeight(size + 20); alert:SetPoint("CENTER", image, "CENTER", 0, 0); alert:Hide()

  local timer = font(f, timerSize or 18, "CENTER")
  timer:SetPoint("CENTER", image, "CENTER", 0, 0)

  local label = font(f, 9, "CENTER")
  label:SetPoint("TOP", image, "BOTTOM", 0, 0)

  f.tex = image; f.shade = shade; f.glow = glow; f.alert = alert; f.txt = timer; f.name = label
  return f
end

function SR.PredictQueue()
  local q = {}
  local first = SR.NextSpellName and SR.NextSpellName() or "Mind Flay"
  table.insert(q, first)
  local order = SR.db.order or {"swp","ve","dp"}
  local i
  for i=1,SR.Count(order) do
    local id = order[i]
    if SR.Spells[id] and SR.db.enabled[id] and SR.Remaining(id) <= (SR.db.refresh or 2) then
      if SR.Spells[id].name ~= first then table.insert(q, SR.Spells[id].name) end
    end
  end
  if SR.db.mb and SR.Ready("Mind Blast") and first ~= "Mind Blast" then table.insert(q, "Mind Blast") end
  table.insert(q, "Mind Flay")
  while SR.Count(q) > 4 do table.remove(q) end
  return q
end

function SR.HUD_Create()
  if SR.HUD then return end
  SR.Init()

  local next = CreateFrame("Frame", "ShadowRotationNext", UIParent)
  next:SetWidth(90); next:SetHeight(105)
  mover(next, "nextX", "nextY")
  makePanel(next, "NEXT")
  next.main = icon(next, 58, 18)
  next.main:SetPoint("TOP", next, "TOP", 0, -6)
  next.name = font(next, 10, "CENTER")
  next.name:SetPoint("TOP", next.main, "BOTTOM", 0, -2)
  SR.NextFrame = next

  local dots = CreateFrame("Frame", "ShadowRotationDots", UIParent)
  dots:SetWidth(140); dots:SetHeight(52)
  mover(dots, "dotX", "dotY")
  makePanel(dots, "DOTS")
  dots.icons = {}
  dots.icons.swp = icon(dots, 30, 18); dots.icons.swp:SetPoint("TOPLEFT", dots, "TOPLEFT", 5, -2); dots.icons.swp.name:SetText("SW:P")
  dots.icons.ve  = icon(dots, 30, 18); dots.icons.ve:SetPoint("TOPLEFT", dots, "TOPLEFT", 52, -2); dots.icons.ve.name:SetText("VE")
  dots.icons.dp  = icon(dots, 30, 18); dots.icons.dp:SetPoint("TOPLEFT", dots, "TOPLEFT", 99, -2); dots.icons.dp.name:SetText("DP")
  SR.DotFrame = dots

  local cds = CreateFrame("Frame", "ShadowRotationCDs", UIParent)
  cds:SetWidth(92); cds:SetHeight(52)
  mover(cds, "cdX", "cdY")
  makePanel(cds, "CDS")
  cds.icons = {}
  cds.icons.mb = icon(cds, 30, 18); cds.icons.mb:SetPoint("TOPLEFT", cds, "TOPLEFT", 7, -2); cds.icons.mb.name:SetText("MB")
  cds.icons.ifc = icon(cds, 30, 18); cds.icons.ifc:SetPoint("TOPLEFT", cds, "TOPLEFT", 54, -2); cds.icons.ifc.name:SetText("IF")
  SR.CDFrame = cds

  local q = CreateFrame("Frame", "ShadowRotationQueue", UIParent)
  q:SetWidth(128); q:SetHeight(38)
  mover(q, "queueX", "queueY")
  makePanel(q, "QUEUE")
  q.icons = {}
  local i
  for i=1,4 do
    local ic = icon(q, 22, 12)
    ic:SetPoint("TOPLEFT", q, "TOPLEFT", 4 + (i-1)*31, -1)
    q.icons[i] = ic
  end
  SR.QueueFrame = q
  SR.HUD = next

  SR.HUD_ApplySettings()
  SR.HUD_Update()
end


function SR.SaveAllFramePositions()
  if SR.NextFrame then saveFramePosition(SR.NextFrame, "nextX", "nextY") end
  if SR.DotFrame then saveFramePosition(SR.DotFrame, "dotX", "dotY") end
  if SR.CDFrame then saveFramePosition(SR.CDFrame, "cdX", "cdY") end
  if SR.QueueFrame then saveFramePosition(SR.QueueFrame, "queueX", "queueY") end
end


function SR.HUD_ApplySettings()
  if not SR.db then return end
  if SR.NextFrame then
    if SR.db.ui.hud then SR.NextFrame:Show() else SR.NextFrame:Hide() end
    SR.NextFrame:SetScale(SR.db.ui.scale or 1)
    SR.NextFrame:SetAlpha(SR.db.ui.alpha or 0.90)
    SR.NextFrame:ClearAllPoints()
    local nx, ny = clampCoord(SR.db.ui.nextX or 0, SR.db.ui.nextY or -95, SR.NextFrame); SR.db.ui.nextX = nx; SR.db.ui.nextY = ny; SR.NextFrame:SetPoint("CENTER", UIParent, "CENTER", nx, ny)
    applyPanel(SR.NextFrame)
  end
  if SR.DotFrame then
    if SR.db.ui.dots then SR.DotFrame:Show() else SR.DotFrame:Hide() end
    SR.DotFrame:SetScale(SR.db.ui.scale or 1)
    SR.DotFrame:SetAlpha(SR.db.ui.alpha or 0.90)
    SR.DotFrame:ClearAllPoints()
    local dx, dy = clampCoord(SR.db.ui.dotX or -78, SR.db.ui.dotY or -168, SR.DotFrame); SR.db.ui.dotX = dx; SR.db.ui.dotY = dy; SR.DotFrame:SetPoint("CENTER", UIParent, "CENTER", dx, dy)
    applyPanel(SR.DotFrame)
  end
  if SR.CDFrame then
    if SR.db.ui.cds then SR.CDFrame:Show() else SR.CDFrame:Hide() end
    SR.CDFrame:SetScale(SR.db.ui.scale or 1)
    SR.CDFrame:SetAlpha(SR.db.ui.alpha or 0.90)
    SR.CDFrame:ClearAllPoints()
    local cx, cy = clampCoord(SR.db.ui.cdX or 78, SR.db.ui.cdY or -168, SR.CDFrame); SR.db.ui.cdX = cx; SR.db.ui.cdY = cy; SR.CDFrame:SetPoint("CENTER", UIParent, "CENTER", cx, cy)
    applyPanel(SR.CDFrame)
  end
  if SR.QueueFrame then
    if SR.db.ui.queue then SR.QueueFrame:Show() else SR.QueueFrame:Hide() end
    SR.QueueFrame:SetScale(SR.db.ui.scale or 1)
    SR.QueueFrame:SetAlpha(SR.db.ui.alpha or 0.90)
    SR.QueueFrame:ClearAllPoints()
    local qx, qy = clampCoord(SR.db.ui.queueX or 0, SR.db.ui.queueY or -220, SR.QueueFrame); SR.db.ui.queueX = qx; SR.db.ui.queueY = qy; SR.QueueFrame:SetPoint("CENTER", UIParent, "CENTER", qx, qy)
    applyPanel(SR.QueueFrame)
  end
end

local function spellIcon(ic, spell, hi)
  ic.tex:SetTexture(SR.SpellTexture(spell))
  ic.txt:SetText("")
  ic.shade:Hide(); ic.alert:Hide()
  if hi then ic.glow:Show() else ic.glow:Hide() end
end

local function dotIcon(ic, id)
  local sp = SR.Spells[id]
  local rem = SR.Remaining(id)
  ic.tex:SetTexture(SR.SpellTexture(sp.name))
  if rem <= 0 then
    ic.txt:SetText("--"); ic.shade:Show(); ic.glow:Hide(); ic.alert:Show()
  else
    ic.txt:SetText(string.format("%.0f", rem)); ic.shade:Hide()
    if rem <= (SR.db.refresh or 2) then ic.glow:Hide(); ic.alert:Show()
    elseif rem <= 5 then ic.glow:Show(); ic.alert:Hide()
    else ic.glow:Hide(); ic.alert:Hide() end
  end
end

local function cdIcon(ic, spell)
  ic.tex:SetTexture(SR.SpellTexture(spell))
  local cd = SR.Cooldown(spell)
  if cd and cd > 0 then
    ic.txt:SetText(string.format("%.0f", cd)); ic.shade:Show(); ic.glow:Hide(); ic.alert:Hide()
  else
    ic.txt:SetText("✓"); ic.shade:Hide(); ic.glow:Show(); ic.alert:Hide()
  end
end

function SR.HUD_Update()
  local nextName = SR.NextSpellName and SR.NextSpellName() or "Mind Flay"
  if SR.NextFrame then
    spellIcon(SR.NextFrame.main, nextName, true)
    SR.NextFrame.name:SetText(nextName)
  end
  if SR.DotFrame then
    dotIcon(SR.DotFrame.icons.swp, "swp")
    dotIcon(SR.DotFrame.icons.ve, "ve")
    dotIcon(SR.DotFrame.icons.dp, "dp")
  end
  if SR.CDFrame then
    cdIcon(SR.CDFrame.icons.mb, "Mind Blast")
    cdIcon(SR.CDFrame.icons.ifc, "Inner Focus")
  end
  if SR.QueueFrame then
    local q = SR.PredictQueue()
    local i
    for i=1,4 do spellIcon(SR.QueueFrame.icons[i], q[i] or "Mind Flay", i == 1) end
  end
end

function SR.Report()
  SR.Init()
  local s = SR.db.stats
  if not s or not s.start or s.start == 0 then SR.Msg("No combat history yet."); return end
  local dur = (s.last or SR.Now()) - (s.start or SR.Now()); if dur < 1 then dur = 1 end
  local total = 0; local k,v
  if s.casts then for k,v in pairs(s.casts) do total = total + v end end

  local mf = (s.casts and s.casts["Mind Flay"]) or 0
  local mb = (s.casts and s.casts["Mind Blast"]) or 0
  local swp = (s.casts and s.casts["Shadow Word: Pain"]) or 0
  local ve = (s.casts and s.casts["Vampiric Embrace"]) or 0
  local dp = (s.casts and s.casts["Devouring Plague"]) or 0
  local dots = swp + ve + dp

  local score = 70
  if mf > 0 then score = score + 10 end
  if mb > 0 or not SR.db.mb then score = score + 10 end
  if dots >= 3 then score = score + 10 end
  if score > 100 then score = 100 end

  local grade = "C"
  if score >= 97 then grade = "A+"
  elseif score >= 90 then grade = "A"
  elseif score >= 82 then grade = "B"
  elseif score >= 70 then grade = "C"
  else grade = "D" end

  SR.Msg("Fight: "..string.format("%.0f", dur).." sec | Casts: "..tostring(total).." | Score: "..tostring(score).." | Grade: "..grade)
  if s.casts then for k,v in pairs(s.casts) do SR.Msg(k .. ": " .. tostring(v)) end end
  if mf == 0 then SR.Msg("Tip: Mind Flay was not used.") end
  if SR.db.mb and mb == 0 then SR.Msg("Tip: Mind Blast was enabled but not used.") end
  if dots < 3 then SR.Msg("Tip: One or more DoTs may not have been maintained.") end
end

function SR.History()
  SR.Init()
  local h = SR.db.stats and SR.db.stats.history
  if not h or SR.Count(h) == 0 then SR.Msg("No history yet."); return end
  SR.Msg("Recent casts:")
  local i
  for i=1,SR.Count(h) do
    local e = h[i]
    SR.Msg(string.format("%.1f", (e.t or 0) - (SR.db.stats.start or e.t or 0)) .. "  " .. tostring(e.s))
  end
end


SR.AnalyticsFrame = nil

function SR.Analytics_Create()
  if SR.AnalyticsFrame then return end
  local f = CreateFrame("Frame", "ShadowRotationAnalytics", UIParent)
  f:SetWidth(420); f:SetHeight(330)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(0.008,0.006,0.022,0.94); bg:SetAllPoints(f)

  local title = font(f, 15, "CENTER")
  title:SetPoint("TOP", f, "TOP", 0, -12)
  title:SetText("ShadowRotation Analytics")

  f.lines = {}
  local i
  for i=1,14 do
    local line = font(f, 11, "LEFT")
    line:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -42 - ((i-1)*18))
    line:SetWidth(370)
    line:SetJustifyH("LEFT")
    f.lines[i] = line
  end

  local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  close:SetWidth(80); close:SetHeight(22)
  close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 14)
  close:SetText("Close")
  close:SetScript("OnClick", function() f:Hide() end)

  f:Hide()
  SR.AnalyticsFrame = f
end

function SR.Analytics_Show()
  if not SR.AnalyticsFrame then SR.Analytics_Create() end
  local f = SR.AnalyticsFrame
  local s = SR.db and SR.db.stats
  local values = {}
  if not s or not s.start or s.start == 0 then
    table.insert(values, "No combat history yet.")
  else
    local dur = (s.last or SR.Now()) - (s.start or SR.Now())
    if dur < 1 then dur = 1 end
    local total = 0
    local k,v
    if s.casts then for k,v in pairs(s.casts) do total = total + v end end
    local mf = (s.casts and s.casts["Mind Flay"]) or 0
    local mb = (s.casts and s.casts["Mind Blast"]) or 0
    local swp = (s.casts and s.casts["Shadow Word: Pain"]) or 0
    local ve = (s.casts and s.casts["Vampiric Embrace"]) or 0
    local dp = (s.casts and s.casts["Devouring Plague"]) or 0
    local score = 70
    if mf > 0 then score = score + 10 end
    if mb > 0 or not SR.db.mb then score = score + 10 end
    if (swp + ve + dp) >= 3 then score = score + 10 end
    if score > 100 then score = 100 end
    local grade = "C"
    if score >= 97 then grade = "A+" elseif score >= 90 then grade = "A"
    elseif score >= 82 then grade = "B" elseif score >= 70 then grade = "C" else grade = "D" end

    table.insert(values, "Fight length: "..string.format("%.0f",dur).." sec")
    table.insert(values, "Score: "..score.."   Grade: "..grade)
    table.insert(values, "Total casts: "..total)
    table.insert(values, "SW:P casts: "..swp)
    table.insert(values, "VE casts: "..ve)
    table.insert(values, "DP casts: "..dp)
    table.insert(values, "Mind Blast casts: "..mb)
    table.insert(values, "Mind Flay casts: "..mf)
    local d = SR.db.diagnostics or {}
    table.insert(values, "Failed DoT verifications: "..tostring(d.failedDots or 0))
    table.insert(values, "Busy/channel skips: "..tostring(d.busySkips or 0))
    table.insert(values, "Throttle skips: "..tostring(d.gcdSkips or 0))
    if mb == 0 and SR.db.mb then table.insert(values, "Coach: Mind Blast was enabled but unused.") end
    if mf == 0 then table.insert(values, "Coach: No Mind Flay casts were recorded.") end
    if (swp + ve + dp) < 3 then table.insert(values, "Coach: One or more DoTs were not used.") end
  end

  local i
  for i=1,14 do f.lines[i]:SetText(values[i] or "") end
  f:Show()
end

local ticker = CreateFrame("Frame")
ticker.t = 0
ticker:SetScript("OnUpdate", function()
  this.t = (this.t or 0) + arg1
  if this.t > 0.18 then this.t = 0; if SR.HUD_Update then SR.HUD_Update() end end
end)
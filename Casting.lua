-- ShadowRotation v15 Smart Casting helpers
SR.Modules.Casting = true
SR.slotCache = {}


function SR.NormalizeTexture(t)
  if not t then return nil end
  if type(t) ~= "string" then return tostring(t) end
  return string.lower(t)
end

function SR.AuraPresent(id)
  SR.EnsureSmartState()
  if not SR.db.smartAuras or not UnitDebuff or not SR.ValidTarget() then return false end
  local sp = SR.Spells[id]
  if not sp then return false end
  local wanted = SR.NormalizeTexture(SR.SpellTexture(sp.name))
  if not wanted then return false end

  SR.db.diagnostics.auraScans = (SR.db.diagnostics.auraScans or 0) + 1
  local i = 1
  while i <= 32 do
    local texture = UnitDebuff("target", i)
    if not texture then break end
    if SR.NormalizeTexture(texture) == wanted then return true end
    i = i + 1
  end
  return false
end

function SR.VerifyPendingDots()
  SR.EnsureSmartState()
  if not SR.db.smartAuras or not SR.ValidTarget() then return end
  local now = SR.Now()
  local id, pendingAt
  for id,pendingAt in pairs(SR.db.pendingDots) do
    if pendingAt and now - pendingAt >= (SR.db.verifyDelay or 0.75) then
      if SR.AuraPresent(id) then
        SR.db.lastCast[id] = SR.db.lastCast[id] or pendingAt
      else
        SR.db.lastCast[id] = nil
        SR.db.diagnostics.failedDots = (SR.db.diagnostics.failedDots or 0) + 1
        SR.Debug("dot verification failed: "..tostring(id))
      end
      SR.db.pendingDots[id] = nil
    end
  end
end


function SR.IsBusy()
  if not GetCurrentCastingInfo then return false end
  local a = GetCurrentCastingInfo()
  if type(a) == "string" and a ~= "" then return true end
  if type(a) == "number" and a ~= 0 then return true end
  return false
end

function SR.SpellSlot(name)
  if not name or not GetSpellName then return nil end
  if SR.slotCache[name] then return SR.slotCache[name] end
  local i = 1
  while i <= 300 do
    local s = GetSpellName(i, BOOKTYPE_SPELL)
    if s == name then SR.slotCache[name] = i; return i end
    if not s and i > 120 then break end
    i = i + 1
  end
  return nil
end

function SR.SpellTexture(name)
  local slot = SR.SpellSlot(name)
  if slot and GetSpellTexture then
    local tex = GetSpellTexture(slot, BOOKTYPE_SPELL)
    if tex then return tex end
  end
  return "Interface\\Icons\\Spell_Shadow_ShadowWordPain"
end

function SR.Cooldown(name)
  if not GetSpellCooldown then return 0 end
  local slot = SR.SpellSlot(name)
  if not slot then return 0 end
  local start, dur = GetSpellCooldown(slot, BOOKTYPE_SPELL)
  if not start or not dur or start == 0 or dur == 0 then return 0 end
  local r = start + dur - SR.Now()
  if r < 0 then r = 0 end
  return r
end

function SR.Ready(name)
  return SR.Cooldown(name) <= 0
end

function SR.TrackCast(spell)
  if not SR.db then return end
  if not SR.db.stats then SR.db.stats = { casts = {}, history = {} } end
  if not SR.db.stats.casts then SR.db.stats.casts = {} end
  if not SR.db.stats.history then SR.db.stats.history = {} end
  local now = SR.Now()
  if not SR.db.stats.active then
    SR.db.stats.active = true
    SR.db.stats.start = now
    SR.db.stats.casts = {}
    SR.db.stats.history = {}
  end
  SR.db.stats.last = now
  SR.db.stats.casts[spell] = (SR.db.stats.casts[spell] or 0) + 1
  table.insert(SR.db.stats.history, { t = now, s = spell })
  while SR.Count(SR.db.stats.history) > 20 do table.remove(SR.db.stats.history, 1) end
end

function SR.SafeCast(spell, dotId)
  if not spell then return end
  CastSpellByName(spell)
  SR.db.nextCastTime = SR.Now() + (SR.db.throttle or 0.20)
  if dotId then
    SR.db.lastCast[dotId] = SR.Now()
    SR.db.pendingDots[dotId] = SR.Now()
  end
  SR.TrackCast(spell)
  SR.Debug("cast " .. spell)
  if SR.HUD_Update then SR.HUD_Update(spell) end
end
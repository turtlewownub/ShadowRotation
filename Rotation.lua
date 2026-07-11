-- ShadowRotation v19.0 Simulation engine
SR.Modules.Rotation = true
function SR.NeedsDot(id)
  if not (SR.db.enabled and SR.db.enabled[id]) then return false end

  -- Verify real target aura presence when available. Internal timers remain the
  -- fallback because Vanilla UnitDebuff does not expose reliable durations.
  if SR.db.smartAuras and SR.AuraPresent then
    local present = SR.AuraPresent(id)
    if present and not SR.db.lastCast[id] then
      -- A manually applied or previously unknown aura was found.
      SR.db.lastCast[id] = SR.Now()
    elseif not present and SR.db.lastCast[id] and not SR.db.pendingDots[id] then
      SR.db.lastCast[id] = nil
    end
  end

  return SR.Remaining(id) <= (SR.db.refresh or 2)
end

function SR.TargetHealthPct()
  if not UnitHealth or not UnitHealthMax or not UnitExists or not UnitExists("target") then return 100 end
  local maxHealth = UnitHealthMax("target") or 0
  if maxHealth <= 0 then return 100 end
  return ((UnitHealth("target") or 0) / maxHealth) * 100
end

function SR.DotAllowed(id)
  if id == "dp" and (SR.db.dpMana or 0) > 0 and SR.ManaPct() < SR.db.dpMana then return false end
  local skip = SR.db.targetHealthSkipDots or 0
  if skip > 0 and SR.TargetHealthPct() <= skip then return false end
  return true
end

function SR.DotToCast()
  local order = SR.db.order or SR.Defaults.order
  local i
  for i = 1, SR.Count(order) do
    local id = order[i]
    if SR.Spells[id] and SR.NeedsDot(id) and SR.DotAllowed(id) then return id, SR.Spells[id].name end
  end
  return nil, nil
end

function SR.MBAllowed()
  if not SR.db.mb or SR.db.mbMode == "off" then return false end
  if (SR.db.mbMana or 0) > 0 and SR.ManaPct() < SR.db.mbMana then return false end
  return SR.Ready("Mind Blast")
end


function SR.DecisionReason(spell)
  if spell == "Shadow Word: Pain" then return "SW:P missing or within refresh threshold." end
  if spell == "Vampiric Embrace" then return "VE missing or within refresh threshold." end
  if spell == "Devouring Plague" then return "DP missing or within refresh threshold." end
  if spell == "Mind Blast" then return "Mind Blast ready and allowed by mana/profile rules." end
  if spell == "Mind Flay" then return "All higher-priority actions are handled." end
  if spell == "Psychic Scream" then return "PvP emergency health threshold reached." end
  if spell == "Silence" then return "Enemy player is casting." end
  if spell == "Shadowguard" then return "Configured self-buff is missing." end
  if spell == "Touch of Weakness" then return "Configured self-buff is missing." end
  return "Current highest-priority action."
end

function SR.DotExpiringWithin(seconds)
  local order = SR.db.order or {"swp","ve","dp"}
  local i
  for i=1,SR.Count(order) do
    local id = order[i]
    if SR.Spells[id] and SR.db.enabled[id] and SR.DotAllowed(id) then
      local rem = SR.Remaining(id) or 0
      if rem > (SR.db.refresh or 2) and rem <= ((SR.db.refresh or 2) + (seconds or 0)) then
        return id, SR.Spells[id].name
      end
    end
  end
  return nil, nil
end

function SR.NextSpellName()
  SR.Init()
  if not SR.ValidTarget() then return "No target" end

  if SR.db.ui and SR.db.ui.activeProfile == "pvp" and SR.db.pvp and SR.db.pvp.assist and SR.PvPSuggestion then
    local pvpSpell = SR.PvPSuggestion()
    if pvpSpell then return pvpSpell end
  end

  local lookahead = 0
  if SR.db.simulation and SR.db.simulation.enabled then
    lookahead = SR.db.simulation.lookahead or 1.5
  end

  if lookahead > 0 and SR.MBAllowed() then
    local id, spell = SR.DotExpiringWithin(lookahead)
    if spell then return spell end
  end

  if SR.db.mbMode == "beforedots" and SR.MBAllowed() then return "Mind Blast" end
  local id, spell = SR.DotToCast()
  if spell then return spell end
  if SR.db.mbMode ~= "beforedots" and SR.MBAllowed() then return "Mind Blast" end
  return "Mind Flay"
end

-- Public macro entry point. Keep this global function simple and stable.
function ShadowRotation()
  SR.Init()
  if not SR.ValidTarget() then return end
  SR.ResetTargetIfNeeded()
  if SR.DecisionPush and SR.NextSpellName then
    local recommendation = SR.NextSpellName()
    SR.DecisionPush(recommendation.." - "..SR.DecisionReason(recommendation))
  end
  SR.EnsureSmartState()
  if SR.VerifyPendingDots then SR.VerifyPendingDots() end
  if SR.IsBusy() and not SR.db.clip then
    SR.db.diagnostics.busySkips = (SR.db.diagnostics.busySkips or 0) + 1
    return
  end
  if SR.db.nextCastTime and SR.Now() < SR.db.nextCastTime then
    SR.db.diagnostics.gcdSkips = (SR.db.diagnostics.gcdSkips or 0) + 1
    return
  end

  if SR.db.ui and SR.db.ui.activeProfile == "pvp" and SR.db.pvp and SR.db.pvp.assist and SR.PvPSuggestion then
    local pvpSpell = SR.PvPSuggestion()
    if pvpSpell then SR.SafeCast(pvpSpell); return end
  end

  if SR.db.mbMode == "beforedots" and SR.MBAllowed() then SR.SafeCast("Mind Blast"); return end

  local id, spell = SR.DotToCast()
  if spell then
    local cd = SR.Cooldown(spell)
    if cd and cd > 0 and cd <= 1.8 then return end
    SR.SafeCast(spell, id)
    return
  end

  if SR.db.mbMode ~= "beforedots" and SR.MBAllowed() then SR.SafeCast("Mind Blast"); return end
  SR.SafeCast("Mind Flay")
end

function ShadowRotation_Keybind()
  ShadowRotation()
end
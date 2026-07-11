-- ShadowRotation v17.2 PvP recommendation module
SR.Modules.PvP = true
function SR.PlayerHealthPct()
  if not UnitHealth or not UnitHealthMax then return 100 end
  local m = UnitHealthMax("player") or 0
  if m <= 0 then return 100 end
  return ((UnitHealth("player") or 0) / m) * 100
end

function SR.PlayerBuffPresent(spellName)
  if not UnitBuff then return false end
  local wanted = SR.NormalizeTexture and SR.NormalizeTexture(SR.SpellTexture(spellName)) or nil
  if not wanted then return false end
  local i = 1
  while i <= 32 do
    local texture = UnitBuff("player", i)
    if not texture then break end
    if SR.NormalizeTexture(texture) == wanted then return true end
    i = i + 1
  end
  return false
end


function SR.TargetIsCasting()
  if UnitCastingInfo then
    local name = UnitCastingInfo("target")
    if name then return true end
  end
  if UnitChannelInfo then
    local name = UnitChannelInfo("target")
    if name then return true end
  end
  return false
end

function SR.PvPSuggestion()
  SR.Init()
  if not SR.db.ui or SR.db.ui.activeProfile ~= "pvp" then return nil end
  local p = SR.db.pvp or {}

  if p.scream and SR.PlayerHealthPct() <= (p.healthThreshold or 35) and SR.Ready("Psychic Scream") then
    return "Psychic Scream", "Low health emergency option"
  end

  if p.shadowguard and SR.SpellSlot("Shadowguard") and not SR.PlayerBuffPresent("Shadowguard") then
    return "Shadowguard", "Self buff is missing"
  end

  if p.touch and SR.SpellSlot("Touch of Weakness") and not SR.PlayerBuffPresent("Touch of Weakness") then
    return "Touch of Weakness", "Self buff is missing"
  end

  if p.silence and UnitIsPlayer and UnitIsPlayer("target") and SR.TargetIsCasting() and SR.Ready("Silence") then
    return "Silence", "Enemy player is casting"
  end
  return nil
end
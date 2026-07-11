-- ShadowRotation Slash commands
SR.Modules.Commands = true
SLASH_SHADOWROTATION1 = "/shadow"
SlashCmdList["SHADOWROTATION"] = function(msgtext)
  SR.Init()
  local args = SR.Split(msgtext or "")
  local cmd = SR.Lower(args[1] or "config")
  if cmd == "version" then SR.Msg("v" .. SHADOWROTATION_VERSION); return end
  if cmd == "modules" or cmd == "selfcheck" then
    local names = {"Core","Casting","Rotation","PvP","Coach","ProfileIO","HUD","Minimap","Options","Wizard","Commands","Health","Insights"}
    local all = true
    local i
    SR.Msg("v"..SHADOWROTATION_VERSION.." module check")
    for i=1,SR.Count(names) do
      local n = names[i]
      local ok = SR.Modules and SR.Modules[n]
      if not ok then all = false end
      SR.Msg(n.."="..(ok and "OK" or "MISSING"))
    end
    SR.Msg(all and "System Status: READY" or "System Status: INCOMPLETE")
    return
  end
  if cmd == "reset" then SR.ResetRotation(); SR.Msg("reset"); return end
  if cmd == "defaults" or cmd == "default" then SR.ResetDefaults(); SR.Msg("defaults restored"); return end
  if cmd == "options" or cmd == "config" then SR.Options_Show(); return end
  if cmd == "debug" then SR.db.debug = SR.BoolArg(args[2], false); SR.Msg("debug " .. (SR.db.debug and "on" or "off")); return end
  if cmd == "smart" or cmd == "auras" then
    SR.db.smartAuras = SR.BoolArg(args[2], true)
    if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end
    SR.Msg("smart aura verification " .. (SR.db.smartAuras and "on" or "off"))
    return
  end
  if cmd == "verifydelay" then
    local n = tonumber(args[2])
    if n and n >= 0.2 and n <= 2.0 then
      SR.db.verifyDelay = n
      if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end
      SR.Msg("verify delay "..n)
    else
      SR.Msg("Usage: /shadow verifydelay 0.75")
    end
    return
  end
  if cmd == "diagnose" then
    if SR.Diagnose then SR.Diagnose() end
    SR.Msg("HUD loaded="..tostring(SR.HUD_LOADED)..
      " NextFrame="..tostring(SR.NextFrame ~= nil)..
      " Minimap="..tostring(SR.MinimapButton ~= nil))
    return
  end
  if cmd == "safeui" or cmd == "recoverui" then
    SR.db.ui.safeUiMigrated = false
    if SR.SafeUiMigration then SR.SafeUiMigration() end
    SR.db.ui.locked = false
    SR.db.ui.minimap = true
    if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end
    if SR.Minimap_Apply then SR.Minimap_Apply() end
    SR.Msg("UI recovered, frames unlocked, minimap shown")
    return
  end
  if cmd == "analytics" then if SR.Analytics_Show then SR.Analytics_Show() end; return end
  if cmd == "coach" or cmd == "fights" then if SR.CoachShow then SR.CoachShow() end; return end
  if cmd == "coachon" then SR.CoachEnsure(); SR.db.coach.enabled=true; SR.Msg("coach on"); return end
  if cmd == "coachoff" then SR.CoachEnsure(); SR.db.coach.enabled=false; SR.Msg("coach off"); return end
  if cmd == "autoreport" then SR.CoachEnsure(); SR.db.coach.autoReport=SR.BoolArg(args[2], true); SR.Msg("auto report "..(SR.db.coach.autoReport and "on" or "off")); return end
  if cmd == "profileio" then if SR.ProfileIOShow then SR.ProfileIOShow() end; return end
  if cmd == "exportprofile" then SR.Msg(SR.ExportProfileString(args[2])); return end
  if cmd == "importprofile" then
    local raw = string.sub(msgtext or "", string.len(args[1] or "") + 2)
    SR.ImportProfileString(raw, args[2])
    return
  end
  if cmd == "preset" then
    local p = SR.Lower(args[2] or "custom")
    if SR.ApplyPreset then SR.ApplyPreset(p) end
    return
  end
  if cmd == "backup" then if SR.BackupSettings then SR.BackupSettings() end; return end
  if cmd == "restore" then if SR.RestoreSettings then SR.RestoreSettings() end; return end
  if cmd == "diagreset" then if SR.ResetDiagnostics then SR.ResetDiagnostics(); SR.Msg("diagnostics reset") end; return end
  if cmd == "pvpsuggest" then
    local spell, why = SR.PvPSuggestion and SR.PvPSuggestion() or nil
    if spell then SR.Msg(spell..": "..tostring(why)) else SR.Msg("no PvP suggestion now") end
    return
  end
  if cmd == "pvpassist" then
    SR.db.pvp.assist = SR.BoolArg(args[2], false)
    if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end
    SR.Msg("PvP assist "..(SR.db.pvp.assist and "on" or "off"))
    return
  end
  if cmd == "skipdots" then
    local n = tonumber(args[2])
    if n and n >= 0 and n <= 50 then
      SR.db.targetHealthSkipDots = n
      if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end
      SR.Msg("skip DoTs below "..n.."% target health")
    else
      SR.Msg("Usage: /shadow skipdots 15 (0 disables)")
    end
    return
  end
  if cmd == "profileui" then
    SR.db.profileUi = SR.BoolArg(args[2], false)
    if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end
    SR.Msg("profile HUD state "..(SR.db.profileUi and "on" or "off"))
    return
  end
  if cmd == "pack" then
    if SR.ApplyRotationPack then SR.ApplyRotationPack(args[2] or "standard") end
    return
  end
  if cmd == "why" or cmd == "explain" then
    SR.Msg(SR.ExplainDecision())
    return
  end
  if cmd == "decisionlog" then
    local i
    if not SR.db.decisionLog or SR.Count(SR.db.decisionLog) == 0 then
      SR.Msg("no decisions logged yet")
    else
      for i=1,math.min(8, SR.Count(SR.db.decisionLog)) do SR.Msg(SR.db.decisionLog[i]) end
    end
    return
  end
  if cmd == "simulate" then
    SR.Msg(SR.SimulationSummary())
    return
  end
  if cmd == "simulation" then
    SR.db.simulation.enabled = SR.BoolArg(args[2], true)
    SR.Msg("simulation "..(SR.db.simulation.enabled and "on" or "off"))
    return
  end
  if cmd == "lookahead" then
    local n = tonumber(args[2])
    if n and n >= 0 and n <= 3 then
      SR.db.simulation.lookahead = n
      SR.Msg("lookahead "..n.." sec")
    else
      SR.Msg("Usage: /shadow lookahead 1.5")
    end
    return
  end
  if cmd == "trends" then SR.Msg(SR.TrendSummary()); return end
  if cmd == "stats" then
    local s = SR.SpellStatistics()
    SR.Msg("Fights="..s.fights.." SWP="..s.swp.." VE="..s.ve.." DP="..s.dp.." MB="..s.mb.." MF="..s.mf)
    return
  end
  if cmd == "tune" then SR.Msg(SR.TuningSuggestion()); return end
  if cmd == "insights" then if SR.InsightsShow then SR.InsightsShow() end; return end
  if cmd == "health" then
    if SR.HealthShow then SR.HealthShow() end
    return
  end
  if cmd == "refresh" then local n=tonumber(args[2]); if n then SR.db.refresh=n; SR.Msg("refresh "..n) else SR.Msg("Usage: /shadow refresh 2") end; return end
  if cmd == "throttle" then local n=tonumber(args[2]); if n then SR.db.throttle=n; SR.Msg("throttle "..n) else SR.Msg("Usage: /shadow throttle .20") end; return end
  if cmd == "tracker" or cmd == "hud" then SR.db.ui.hud = SR.BoolArg(args[2], true); SR.HUD_ApplySettings(); SR.Msg("HUD " .. (SR.db.ui.hud and "on" or "off")); return end
  if cmd == "hudunlock" or cmd == "unlock" then SR.db.ui.locked=false; SR.Msg("HUD unlocked"); return end
  if cmd == "hudlock" or cmd == "lock" then SR.db.ui.locked=true; if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end; SR.Msg("HUD locked"); return end
  if cmd == "clamp" then if SR.HUD_ApplySettings then SR.HUD_ApplySettings() end; SR.Msg("frames clamped onscreen"); return end
  if cmd == "resetui" then SR.db.ui.x=0; SR.db.ui.y=-200; SR.db.ui.nextX=0; SR.db.ui.nextY=-95; SR.db.ui.dotX=-78; SR.db.ui.dotY=-168; SR.db.ui.cdX=78; SR.db.ui.cdY=-168; SR.db.ui.queueX=0; SR.db.ui.queueY=-220; SR.db.ui.scale=1.0; SR.db.ui.alpha=0.92; SR.db.ui.hud=true; SR.db.ui.queue=true; SR.db.ui.background=false; SR.HUD_ApplySettings(); SR.Msg("UI reset"); return end
  if cmd == "scale" then local n=tonumber(args[2]); if n then SR.db.ui.scale=n; SR.HUD_ApplySettings(); SR.Msg("scale "..n) end; return end
  if cmd == "alpha" then local n=tonumber(args[2]); if n then SR.db.ui.alpha=n; SR.HUD_ApplySettings(); SR.Msg("alpha "..n) end; return end
  if cmd == "minimap" then SR.db.ui.minimap = SR.BoolArg(args[2], true); SR.Minimap_Apply(); SR.Msg("minimap " .. (SR.db.ui.minimap and "on" or "off")); return end
  if cmd == "dots" or cmd == "dottracker" then SR.db.ui.dots = SR.BoolArg(args[2], true); SR.HUD_ApplySettings(); SR.Msg("dots " .. (SR.db.ui.dots and "on" or "off")); return end
  if cmd == "strip" then SR.db.ui.strip = SR.BoolArg(args[2], true); SR.HUD_Update(); SR.Msg("strip " .. (SR.db.ui.strip and "on" or "off")); return end
  if cmd == "names" or cmd == "spellnames" then SR.db.ui.names = SR.BoolArg(args[2], true); SR.HUD_Update(); SR.Msg("spell names " .. (SR.db.ui.names and "on" or "off")); return end
  if cmd == "cds" or cmd == "cooldowns" then SR.db.ui.cds = SR.BoolArg(args[2], true); SR.HUD_ApplySettings(); SR.Msg("cooldowns " .. (SR.db.ui.cds and "on" or "off")); return end
  if cmd == "queue" then SR.db.ui.queue = SR.BoolArg(args[2], true); SR.HUD_ApplySettings(); SR.Msg("queue " .. (SR.db.ui.queue and "on" or "off")); return end
  if cmd == "background" or cmd == "bg" then SR.db.ui.background = SR.BoolArg(args[2], false); SR.HUD_ApplySettings(); SR.Msg("background " .. (SR.db.ui.background and "on" or "off")); return end
  if cmd == "tooltips" then SR.db.ui.tooltips = SR.BoolArg(args[2], true); SR.Msg("tooltips " .. (SR.db.ui.tooltips and "on" or "off")); return end
  if cmd == "coaching" then SR.db.ui.coaching = SR.BoolArg(args[2], true); SR.Msg("coaching " .. (SR.db.ui.coaching and "on" or "off")); return end
  if cmd == "wizard" or cmd == "setup" then if SR.Wizard_Show then SR.Wizard_Show() else SR.Msg("wizard unavailable") end; return end
  if cmd == "export" then SR.Msg("Profile: swp="..tostring(SR.db.enabled.swp)..";ve="..tostring(SR.db.enabled.ve)..";dp="..tostring(SR.db.enabled.dp)..";mb="..tostring(SR.db.mb)..";refresh="..tostring(SR.db.refresh)); return end
  if cmd == "layout" then
    local p = SR.Lower(args[2] or "separated")
    if p == "combined" or p == "separated" then
      if SR.ApplyLayoutMode then SR.ApplyLayoutMode(p) end
    elseif p == "minimal" then
      SR.db.ui.hud=true; SR.db.ui.dots=false; SR.db.ui.cds=false; SR.db.ui.queue=false
      SR.HUD_ApplySettings(); SR.Msg("layout minimal")
    else
      SR.Msg("Usage: /shadow layout separated/combined/minimal")
    end
    return
  end
  if cmd == "report" then if SR.Report then SR.Report() end; return end
  if cmd == "history" then if SR.History then SR.History() end; return end
  if cmd == "vp" then cmd = "ve" end
  if cmd == "swp" or cmd == "ve" or cmd == "dp" then SR.db.enabled[cmd] = SR.BoolArg(args[2], true); SR.ResetRotation(); if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end; SR.Msg(cmd .. " " .. (SR.db.enabled[cmd] and "on" or "off")); return end
  if cmd == "mb" then
    local v=SR.Lower(args[2] or "")
    if v=="on" then SR.db.mb=true; SR.db.mbMode="afterdots"; SR.Msg("MB on")
    elseif v=="off" then SR.db.mb=false; SR.db.mbMode="off"; SR.Msg("MB off")
    elseif v=="before" or v=="beforedots" then SR.db.mb=true; SR.db.mbMode="beforedots"; SR.Msg("MB before dots")
    elseif v=="after" or v=="afterdots" then SR.db.mb=true; SR.db.mbMode="afterdots"; SR.Msg("MB after dots")
    elseif v=="mana" then local n=tonumber(args[3]); if n then SR.db.mbMana=n; SR.Msg("MB mana "..n.."%") else SR.Msg("Usage: /shadow mb mana 30") end
    else SR.Msg("Usage: /shadow mb on/off/afterdots/beforedots/mana 30") end
    if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end
    return
  end
  if cmd == "order" then
    local new = {}; local i
    for i=2,SR.Count(args) do local id=SR.Lower(args[i]); if id=="vp" then id="ve" end; if SR.Spells[id] and id~="mb" and id~="mf" then table.insert(new,id) end end
    if SR.Count(new) > 0 then SR.db.order = new; SR.ResetRotation(); if SR.SaveCurrentProfile then SR.SaveCurrentProfile() end; SR.Msg("order updated") else SR.Msg("Usage: /shadow order swp ve dp") end
    return
  end
  if cmd == "profile" then
    local p = SR.Lower(args[2] or "")
    if p == "solo" or p == "dungeon" or p == "raid" or p == "pvp" then
      if SR.LoadProfile and SR.LoadProfile(p) then SR.Msg("profile "..p) else SR.Msg("profile failed") end
    elseif p == "reset" then
      local n = SR.Lower(args[3] or (SR.db.ui and SR.db.ui.activeProfile) or "solo")
      if SR.ResetProfile then SR.ResetProfile(n); SR.Msg("profile reset "..n) end
    elseif p == "save" then
      if SR.SaveCurrentProfile then SR.SaveCurrentProfile(); SR.Msg("profile saved") end
    else
      SR.Msg("Usage: /shadow profile solo/dungeon/raid/pvp")
      SR.Msg("Also: /shadow profile save | /shadow profile reset pvp")
    end
    return
  end
  if cmd == "status" then
    SR.Msg("v"..SHADOWROTATION_VERSION.." profile="..tostring(SR.db.ui and SR.db.ui.activeProfile or "solo").." refresh="..tostring(SR.db.refresh).." throttle="..tostring(SR.db.throttle).." smart="..tostring(SR.db.smartAuras))
    SR.Msg("SWP="..tostring(SR.db.enabled.swp).." VE="..tostring(SR.db.enabled.ve).." DP="..tostring(SR.db.enabled.dp).." MB="..tostring(SR.db.mb))
    return
  end
  if cmd == "castinfo" then if GetCurrentCastingInfo then local a,b,c,d,e,f,g=GetCurrentCastingInfo(); SR.Msg("castinfo: "..tostring(a).." | "..tostring(b).." | "..tostring(c).." | "..tostring(d).." | "..tostring(e).." | "..tostring(f).." | "..tostring(g)) else SR.Msg("GetCurrentCastingInfo missing") end; return end
  if cmd == "testve" then CastSpellByName("Vampiric Embrace"); SR.Msg("test VE"); return end
  if cmd == "testdp" then CastSpellByName("Devouring Plague"); SR.Msg("test DP"); return end
  SR.Msg("v"..SHADOWROTATION_VERSION.." commands: options, version, reset, defaults, status, hud/dots/cds/minimap on/off, unlock, lock, resetui, report, history, swp/ve/dp on/off, mb on/off, profile solo/dungeon/raid")
end

SR.Init()
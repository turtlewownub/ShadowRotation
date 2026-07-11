-- ShadowRotation safe minimap button
SR.Modules.Minimap = true
SR.MinimapButton = nil

local function setPos(btn)
  if not btn or not SR.db then return end
  local a = SR.db.ui.minimapAngle or 225
  local r = 78
  local x = math.cos(a * 3.14159 / 180) * r
  local y = math.sin(a * 3.14159 / 180) * r
  btn:ClearAllPoints(); btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function SR.Minimap_Create()
  if SR.MinimapButton then
    if SR.db and SR.db.ui and SR.db.ui.minimap then SR.MinimapButton:Show() end
    return
  end
  SR.Init()
  if not Minimap then return end
  local b = CreateFrame("Button", "ShadowRotationMinimapButton", Minimap)
  b:SetWidth(32); b:SetHeight(32); b:SetFrameStrata("MEDIUM")
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(SR.SpellTexture("Mind Flay")); icon:SetWidth(22); icon:SetHeight(22); icon:SetPoint("CENTER", b, "CENTER", 0, 0)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetWidth(54); border:SetHeight(54); border:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      SR.db.ui.hud = not SR.db.ui.hud; SR.HUD_ApplySettings(); SR.Msg("HUD " .. (SR.db.ui.hud and "shown" or "hidden"))
    else
      if SR.Options_Toggle then SR.Options_Toggle() else SR.Msg("/shadow options") end
    end
  end)
  b:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText("ShadowRotation v" .. tostring(SHADOWROTATION_VERSION or "1.0.2"))
    GameTooltip:AddLine("Left-click: Options", 1,1,1)
    GameTooltip:AddLine("Right-click: Toggle HUD", 1,1,1)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  SR.MinimapButton = b
  setPos(b)
  if SR.db.ui.minimap then b:Show() else b:Hide() end
end

function SR.Minimap_Apply()
  if not SR.MinimapButton and SR.Minimap_Create then SR.Minimap_Create() end
  if not SR.MinimapButton then return end
  setPos(SR.MinimapButton)
  if SR.db.ui.minimap then SR.MinimapButton:Show() else SR.MinimapButton:Hide() end
end
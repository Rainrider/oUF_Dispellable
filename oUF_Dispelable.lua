local _, ns = ...

local oUF = ns.oUF or oUF
assert(oUF, 'oUF_Dispel requires oUF.')

oUF.colors.debuffType = {}
for debuffType, color in next, DebuffTypeColor do
	oUF.colors.debuffType[debuffType] = { color.r, color.g, color.b }
end

local LPS = LibStub('LibPlayerSpells-1.0')
assert(LPS, 'oUF_Dispel requires LibPlayerSpells-1.0.')

local dispelTypeFlags = {
	Curse = LPS.constants.CURSE,
	Disease = LPS.constants.DISEASE,
	Magic = LPS.constants.MAGIC,
	Poison = LPS.constants.POISON,
}

local band = bit.band
local wipe = table.wipe
local IsPlayerSpell = IsPlayerSpell
local IsSpellKnown = IsSpellKnown
local UnitCanAssist = UnitCanAssist
local UnitDebuff = UnitDebuff

local _, playerClass = UnitClass('player')
local dispels = {}

for id, _, _, _, _, _, types in LPS:IterateSpells('HELPFUL PERSONAL', 'DISPEL ' .. playerClass) do
	dispels[id] = types
end

if (not next(dispels)) then return end

local canDispel = {}

local function UpdateTooltip(dispelIcon)
	GameTooltip:SetUnitAura(dispelIcon.unit, dispelIcon.id, 'HARMFUL')
end

local function OnEnter(dispelIcon)
	if (not dispelIcon:IsVisible()) then return end

	GameTooltip:SetOwner(dispelIcon, dispelIcon.tooltipAnchor)
	dispelIcon:UpdateTooltip()
end

local function OnLeave(dispelIcon)
	GameTooltip:Hide()
end

local function UpdateColor(dispelTexture, r, g, b, a)
	dispelTexture:SetVertexColor(r, g, b, a)
end

local function Update(self, event, unit)
	if (self.unit ~= unit or unit and not UnitCanAssist('player', unit)) then return end

	local element = self.Dispelable
	local dispelTexture = element.dispelTexture
	local dispelIcon = element.dispelIcon

	local texture, count, dispelType, duration, expiration, id
	for i = 1, 40 do
		_, _, texture, count, dispelType, duration, expiration = UnitDebuff(unit, i)

		if (not texture or dispelType and (canDispel[dispelType] == true or canDispel[dispelType] == unit)) then
			id = i
			break
		end
	end

	if (dispelType) then
		local color = self.colors.debuffType[dispelType]
		local r, g, b = color[1], color[2], color[3]
		if (dispelTexture) then
			dispelTexture:UpdateColor(r, g, b, dispelTexture.dispelAlpha)
		end

		if (dispelIcon) then
			dispelIcon.unit = unit
			dispelIcon.id = id
			if (dispelIcon.icon) then
				dispelIcon.icon:SetTexture(texture)
			end
			if (dispelIcon.overlay) then
				dispelIcon.overlay:SetVertexColor(r, g, b)
			end
			if (dispelIcon.count) then
				dispelIcon.count:SetText(count and count > 1 and count)
			end
			if (dispelIcon.cd) then
				if (duration and duration > 0) then
					dispelIcon.cd:SetCooldown(expiration - duration, duration)
					dispelIcon.cd:Show()
				else
					dispelIcon.cd:Hide()
				end
			end

			dispelIcon:Show()
		end
	else
		if (dispelTexture) then
			dispelTexture:UpdateColor(1, 1, 1, dispelTexture.noDispelAlpha)
		end
		if (dispelIcon) then
			dispelIcon:Hide()
		end
	end

	if (element.PostUpdate) then
		element:PostUpdate(dispelType, texture, count, duration, expiration)
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.Dispelable
	if (not element) then return end

	element.__owner = self
	element.ForceUpdate = ForceUpdate

	local dispelTexture = element.dispelTexture
	if (dispelTexture) then
		dispelTexture.dispelAlpha = dispelTexture.dispelAlpha or 1
		dispelTexture.noDispelAlpha = dispelTexture.noDispelAlpha or 0
		dispelTexture.UpdateColor = dispelTexture.UpdateColor or UpdateColor
	end

	local dispelIcon = element.dispelIcon
	if (dispelIcon) then
		-- prevent /fstack errors
		if (dispelIcon.cd) then
			if (not dispelIcon:GetName()) then
				dispelIcon:SetName(dispelIcon:GetDebugName())
			end
			if (not dispelIcon.cd:GetName()) then
				dispelIcon.cd:SetName('$parentCooldown')
			end
		end

		if (dispelIcon:IsMouseEnabled()) then
			dispelIcon:SetScript('OnEnter', dispelIcon.OnEnter or OnEnter)
			dispelIcon:SetScript('OnLeave', dispelIcon.OnLeave or OnLeave)
			dispelIcon.tooltipAnchor = dispelIcon.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'
			dispelIcon.UpdateTooltip = dispelIcon.UpdateTooltip or UpdateTooltip
		end
	end

	self:RegisterEvent('UNIT_AURA', Update)

	return true
end

local function Disable(self)
	local element = self.Dispelable
	if (not element) then return end

	if (element.dispelIcon) then
		element.dispelIcon:Hide()
	end
	if (element.dispelTexture) then
		element.dispelTexture:Hide()
	end

	self:UnregisterEvent('UNIT_AURA', Update)
end

oUF:AddElement('Dispel', Update, Enable, Disable)

local function ToggleElement(enable, ...)
	for i = 1, select('#', ...) do
		local object = select(i, ...)
		local element = object.Dispelable
		if (element) then
			if (enable) then
				object:EnableElement('Dispel')
				element:ForceUpdate()
			else
				object:DisableElement('Dispel')
			end
		end
	end
end

local function UpdateDispels()
	local available = {}
	for id, types in next, dispels do
		if (IsSpellKnown(id, id == 89808 or id == 171021) or IsPlayerSpell(id)) then
			for dispelType, flags in next, dispelTypeFlags do
				if (band(types, flags) > 0) then
					available[dispelType] = not available[dispelType]
					                        and band(LPS:GetSpellInfo(id), LPS.constants.PERSONAL) > 0
					                        and 'player' or true
				end
			end
		end
	end

	if (next(available)) then
		local areEqual = true
		for dispelType in next, available do
			if (not canDispel[dispelType]) then
				areEqual = false
				break
			end
		end

		if (areEqual) then
			for dispelType in next, canDispel do
				if (not available[dispelType]) then
					areEqual = false
					break
				end
			end
		end

		if (not areEqual) then
			wipe(canDispel)
			for dispelType in next, available do
				canDispel[dispelType] = true
			end

			for _, object in next, oUF.objects do
				ToggleElement(true, object)
			end
			for _, header in next, oUF.headers do
				ToggleElement(true, header:GetChildren())
			end
		end
	elseif (next(canDispel)) then
		wipe(canDispel)
		for _, object in next, oUF.objects do
			ToggleElement(false, object)
		end
		for _, header in next, oUF.headers do
			ToggleElement(false, header:GetChildren())
		end
	end
end

local frame = CreateFrame('Frame')
frame:SetScript('OnEvent', UpdateDispels)
frame:RegisterEvent('SPELLS_CHANGED')

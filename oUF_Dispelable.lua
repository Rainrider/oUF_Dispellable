--[[
# Element: Dispelable

Highlights debuffs that are dispelable by the player

## Widget

.Dispelable - A `table` to hold the sub-widgets.

## Sub-Widgets

.dispelIcon    - A `Button` to represent the icon of a dispelable debuff.
.dispelTexture - A `Texture` to be colored according to the debuff type.

## Notes

At least one of the sub-widgets should be present for the element to work.
If mouse interactivity is enabled for the `.dispelIcon` sub-widget, 'OnEnter' and/or 'OnLeave' handlers will be set to
display a tooltip.
If `.dispelIcon` and `.dispelIcon.cd` are defined without a global name, one will be set accordingly by the element to
prevent /fstack errors.
The element adds `debuffTypes` to oUF's colors table, which can be customized by the layout.

## .dispelIcon Sub-Widgets

.cd      - used to display the cooldown spiral for the remaining debuff duration (Cooldown)
.count   - used to display the stack count of the dispelable debuff (FontString)
.icon    - used to show the icon's texture (Texture)
.overlay - used to represent the icon's border. Will be colored according to the debuff type color (Texture)

## .dispelIcon Options

.tooltipAnchor - anchor for the widget's tooltip if it is mouse-enabled. Defaults to 'ANCHOR_BOTTOMRIGHT' (string)

## .dispelIcon Attributes

.id   - the aura index of the dispelable debuff displayed by the widget (number)
.unit - the unit on which the dispelable dubuff displayed by the widget has been found (string)

## .dispelTexture Options

.dispelAlpha   - alpha value for the widget when a dispelable debuff is found. Defaults to 1 (number)[0-1]
.noDispelAlpha - alpha value for the widget when no dispelable debuffs are found. Defaults to 0 (number)[0-1]

## Examples

    -- Position and size
    local Dispelable = {}
    local button = CreateFrame('Button', 'LayoutName_Dispel', self.Health)
    button:SetPoint('CENTER')
    button:SetSize(22, 22)
    button:SetToplevel(true)

    local cd = CreateFrame('Cooldown', '$parentCooldown', button, 'CooldownFrameTemplate')
    cd:SetAllPoints()

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()

    local overlay = button:CreateTexture(nil, 'OVERLAY')
    overlay:SetTexture('Interface\\Buttons\\UI-Debuff-Overlays')
    overlay:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    overlay:SetAllPoints()

    local count = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal', 1)
    count:SetPoint('BOTTOMRIGHT', -1, 1)

    local texture = self.Health:CreateTexture(nil, 'OVERLAY')
    texture:SetTexture('Interface\\ChatFrame\\ChatFrameBackground')
    texture:SetAllPoints()

    -- Register with oUF
    button.cd = cd
    button.icon = icon
    button.overlay = overlay
    button.count = count

    Dispelable.dispelIcon = button
    Dispelable.dispelTexture = texture
    self.Dispelable = Dispelable
--]]

local _, ns = ...

local oUF = ns.oUF or oUF
assert(oUF, 'oUF_Dispelable requires oUF.')

oUF.colors.debuffType = {}
for debuffType, color in next, DebuffTypeColor do
	oUF.colors.debuffType[debuffType] = { color.r, color.g, color.b }
end

local LPS = LibStub('LibPlayerSpells-1.0')
assert(LPS, 'oUF_Dispelable requires LibPlayerSpells-1.0.')

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

local canDispel = {}

--[[ Override: Dispelable.dispelIcon:UpdateTooltip()
Called to update the widget's tooltip.

* self - the dispelIcon sub-widget
--]]
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

--[[ Override: Dispelable.dispelTexture:UpdateColor(dispelType, r, g, b, a)
Called to update the widget's color.

* self       - the dispelTexture sub-widget
* dispelType - the type of the dispelable debuff (string?)['Curse', 'Disease', 'Magic', 'Poison']
* r          - the red color component (number)[0-1]
* g          - the green color component (number)[0-1]
* b          - the blue color component (number)[0-1]
* a          - the alpha color component (number)[0-1]
--]]
local function UpdateColor(dispelTexture, dispelType, r, g, b, a)
	dispelTexture:SetVertexColor(r, g, b, a)
end

local function Update(self, event, unit)
	if (self.unit ~= unit) then return end

	local element = self.Dispelable

	--[[ Callback: Dispelable:PreUpdate()
	Called before the element has been updated.

	* self - the Dispelable element
	--]]
	if (element.PreUpdate) then
		element:PreUpdate()
	end

	local dispelTexture = element.dispelTexture
	local dispelIcon = element.dispelIcon

	local texture, count, dispelType, duration, expiration, id
	if (UnitCanAssist('player', unit)) then
		for i = 1, 40 do
			_, _, texture, count, dispelType, duration, expiration = UnitDebuff(unit, i)

			if (not texture or dispelType and (canDispel[dispelType] == true or canDispel[dispelType] == unit)) then
				id = i
				break
			end
		end
	end

	if (dispelType) then
		local color = self.colors.debuffType[dispelType]
		local r, g, b = color[1], color[2], color[3]
		if (dispelTexture) then
			dispelTexture:UpdateColor(dispelType, r, g, b, dispelTexture.dispelAlpha)
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
			dispelTexture:UpdateColor(dispelType, 1, 1, 1, dispelTexture.noDispelAlpha)
		end
		if (dispelIcon) then
			dispelIcon:Hide()
		end
	end

	--[[ Callback: Dispelable:PostUpdate(dispelType, texture, count, duration, expiration)
	Called after the element has been updated.

	* self       - the Dispelable element
	* dispelType - the type of the dispelable debuff (string?)['Curse', 'Disease', 'Magic', 'Poison']
	* texture    - the texture representing the debuff icon (number?)
	* count      - the stack count of the dispelable debuff (number?)
	* duration   - the duration of the dispelable debuff in seconds (number?)
	* expiration - the point in time when the debuff will expire. Can be compared to `GetTime()` (number?)
	--]]
	if (element.PostUpdate) then
		element:PostUpdate(dispelType, texture, count, duration, expiration)
	end
end

local function Path(self, event, unit)
	--[[ Override: Dispelable:Override(event, unit)
	Used to override the internal update function.

	* self  - the Dispelable element
	* event - the event triggering the update (string)
	* unit  - the unit accompaning the event (string)
	--]]
	return (self.Dispelable.Override or Update)(self, event, unit)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
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
			dispelIcon.tooltipAnchor = dispelIcon.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'
			dispelIcon.UpdateTooltip = dispelIcon.UpdateTooltip or UpdateTooltip

			if (not dispelIcon:GetScript('OnEnter')) then
				dispelIcon:SetScript('OnEnter', OnEnter)
			end
			if (not dispelIcon:GetScript('OnLeave')) then
				dispelIcon:SetScript('OnLeave', OnLeave)
			end
		end
	end

	self:RegisterEvent('UNIT_AURA', Path)

	return true
end

local function Disable(self)
	local element = self.Dispelable
	if (not element) then return end

	if (element.dispelIcon) then
		element.dispelIcon:Hide()
	end
	if (element.dispelTexture) then
		element.dispelTexture:UpdateColor(nil, 1, 1, 1, element.dispelTexture.noDispelAlpha)
	end

	self:UnregisterEvent('UNIT_AURA', Path)
end

oUF:AddElement('Dispelable', Path, Enable, Disable)

local firstRun = true
local function ToggleElement(enable, ...)
	for i = 1, select('#', ...) do
		local object = select(i, ...)
		local element = object.Dispelable
		if (element) then
			if (enable) then
				object:EnableElement('Dispelable')
				element:ForceUpdate()
			else
				object:DisableElement('Dispelable')
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
	elseif (firstRun or next(canDispel)) then
		firstRun = false
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

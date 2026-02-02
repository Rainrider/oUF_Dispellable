--[[
# Element: Dispellable

Highlights debuffs that are dispelable by the player

## Widget

.Dispellable - A `table` to hold the sub-widgets.

## Sub-Widgets

.dispelIcon    - A `Button` to represent the icon of a dispellable debuff.
.dispelTexture - A `Texture` to be colored according to the debuff type.

## Options

The element uses oUF's `dispel` colors to apply colors to the sub-widgets.

.dispelColorCurve - A [`color curve object`](https://warcraft.wiki.gg/wiki/ScriptObject_ColorCurveObject) used to color
                    the sub-widgets by the dispel type.
.resetColor       - A [`ColorMixin`](https://warcraft.wiki.gg/wiki/ColorMixin) used to reset the color of the
                    sub-widgets when no dispellable debuff is found.

## Notes

At least one of the sub-widgets should be present for the element to work.

The `.dispelTexture` sub-widget is updated by setting its color and alpha. It is always shown to allow the use on non-
texture widgets without the need to override the internal update function.

If mouse interactivity is enabled for the `.dispelIcon` sub-widget, 'OnEnter' and/or 'OnLeave' handlers will be set to
display a tooltip.

If `.dispelIcon` and `.dispelIcon.cd` are defined without a global name, one will be set accordingly by the element to
prevent /fstack errors.

## .dispelIcon Sub-Widgets

.cd      - used to display the cooldown spiral for the remaining debuff duration (Cooldown)
.count   - used to display the stack count of the dispellable debuff (FontString)
.icon    - used to show the icon's texture (Texture)
.overlay - used to represent the icon's border. Will be colored according to the debuff type color (Texture)

## .dispelIcon Options

.tooltipAnchor - anchor for the widget's tooltip if it is mouse-enabled. Defaults to 'ANCHOR_BOTTOMRIGHT' (string)

## .dispelIcon Attributes

.id   - the aura index of the dispellable debuff displayed by the widget (number)
.unit - the unit on which the dispellable dubuff displayed by the widget has been found (string)

## .dispelTexture Options

.dispelAlpha   - alpha value for the widget when a dispellable debuff is found. Defaults to 1 (number)[0-1]
.noDispelAlpha - alpha value for the widget when no dispellable debuffs are found. Defaults to 0 (number)[0-1]

## Examples

    -- Position and size
    local Dispellable = {}
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

    Dispellable.dispelIcon = button
    Dispellable.dispelTexture = texture
    self.Dispellable = Dispellable
--]]

local _, ns = ...

local oUF = ns.oUF or oUF
assert(oUF, 'oUF_Dispellable requires oUF.')

local wipe = table.wipe
local UnitCanAssist = UnitCanAssist

--[[ Override: Dispellable.dispelIcon:UpdateTooltip()
Called to update the widget's tooltip.

* self - the dispelIcon sub-widget
--]]
local function UpdateTooltip(dispelIcon)
	GameTooltip:SetUnitDebuffByAuraInstanceID(dispelIcon.unit, dispelIcon.id)
end

local function OnEnter(dispelIcon)
	if not dispelIcon:IsVisible() then
		return
	end

	GameTooltip:SetOwner(dispelIcon, dispelIcon.tooltipAnchor)
	dispelIcon:UpdateTooltip()
end

local function OnLeave()
	GameTooltip:Hide()
end

--[[ Override: Dispellable:UpdateColor(unit, debuff)
Called to update the widget's color.

* self   - the Dispellable element
* unit   - the unit on which the displayed debuff has been applied or removed (string)
* debuff - the displayed debuff or nil if none (UnitAuraInfo?)
--]]
local function UpdateColor(element, unit, debuff)
	local color = debuff and C_UnitAuras.GetAuraDispelTypeColor(unit, debuff.auraInstanceID, element.dispelColorCurve)
		or element.resetColor

	local icon = element.dispelIcon
	if icon and icon.overlay then
		icon.overlay:SetVertexColor(color:GetRGBA())
	end

	if element.dispelTexture then
		element.dispelTexture:SetVertexColor(color:GetRGBA())
	end
end

local function UpdateDebuffs(self, unit, updateInfo)
	local element = self.Dispellable
	local debuffs = element.debuffs
	local filter = 'HARMFUL|RAID'

	if not UnitCanAssist('player', unit) then
		wipe(debuffs)

		return
	end

	if not updateInfo or updateInfo.isFullUpdate then
		wipe(debuffs)
		local slots = { C_UnitAuras.GetAuraSlots(unit, filter) }

		for i = 2, #slots do
			local debuff = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])

			debuffs[debuff.auraInstanceID] = debuff
		end
	else
		for _, aura in next, updateInfo.addedAuras or {} do
			if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, filter) then
				debuffs[aura.auraInstanceID] = aura
			end
		end

		for _, auraInstanceID in next, updateInfo.updatedAuraInstanceIDs or {} do
			if not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraInstanceID, filter) then
				local aura = C_UnitAuras.GetAuraByAuraInstanceID(unit, auraInstanceID)
				debuffs[auraInstanceID] = aura
			end
		end

		for _, auraInstanceID in next, updateInfo.removedAuraInstanceIDs or {} do
			debuffs[auraInstanceID] = nil
		end
	end
end

local function UpdateDisplay(self, unit)
	local element = self.Dispellable
	local lowestID = nil

	for auraInstanceID in next, element.debuffs do
		if not lowestID or auraInstanceID < lowestID then
			lowestID = auraInstanceID
		end
	end

	local dispelIcon = element.dispelIcon
	local debuff = lowestID and element.debuffs[lowestID]

	if debuff then
		if dispelIcon then
			dispelIcon.unit = self.unit
			dispelIcon.id = lowestID
			if dispelIcon.icon then
				dispelIcon.icon:SetTexture(debuff.icon)
			end
			if dispelIcon.count then
				dispelIcon.count:SetText(C_UnitAuras.GetAuraApplicationDisplayCount(unit, debuff.auraInstanceID))
			end
			if dispelIcon.cd then
				local duration = C_UnitAuras.GetAuraDuration(unit, debuff.auraInstanceID)

				if duration then
					dispelIcon.cd:SetCooldownFromDurationObject(duration)
					dispelIcon.cd:Show()
				else
					dispelIcon.cd:Hide()
				end
			end

			dispelIcon:Show()
		end
	else
		if dispelIcon then
			dispelIcon:Hide()
		end
	end

	element:UpdateColor(unit, debuff)

	return debuff
end

local function Update(self, _, unit, updateInfo)
	if self.unit ~= unit then
		return
	end

	local element = self.Dispellable

	--[[ Callback: Dispellable:PreUpdate()
	Called before the element has been updated.

	* self - the Dispellable element
	--]]
	if element.PreUpdate then
		element:PreUpdate()
	end

	UpdateDebuffs(self, unit, updateInfo)
	local displayed = UpdateDisplay(self, unit)

	--[[ Callback: Dispellable:PostUpdate(debuffType, texture, count, duration, expiration)
	Called after the element has been updated.

	* self      - the Dispellable element
	* displayed - the displayed debuff (UnitAuraInfo?)
	--]]
	if element.PostUpdate then
		element:PostUpdate(displayed)
	end
end

local function Path(self, event, unit)
	--[[ Override: Dispellable.Override(self, event, unit)
	Used to override the internal update function.

	* self  - the parent of the Dispellable element
	* event - the event triggering the update (string)
	* unit  - the unit accompaning the event (string)
	--]]
	return (self.Dispellable.Override or Update)(self, event, unit)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.Dispellable
	if not element then
		return
	end

	element.__owner = self
	element.debuffs = {}
	element.ForceUpdate = ForceUpdate

	local dispelIcon = element.dispelIcon
	if dispelIcon then
		-- prevent /fstack errors
		if dispelIcon.cd then
			if not dispelIcon:GetName() then
				dispelIcon:SetName(dispelIcon:GetDebugName())
			end
			if not dispelIcon.cd:GetName() then
				dispelIcon.cd:SetName('$parentCooldown')
			end
		end

		if dispelIcon:IsMouseEnabled() then
			dispelIcon.tooltipAnchor = dispelIcon.tooltipAnchor or 'ANCHOR_BOTTOMRIGHT'
			dispelIcon.UpdateTooltip = dispelIcon.UpdateTooltip or UpdateTooltip

			if not dispelIcon:GetScript('OnEnter') then
				dispelIcon:SetScript('OnEnter', OnEnter)
			end
			if not dispelIcon:GetScript('OnLeave') then
				dispelIcon:SetScript('OnLeave', OnLeave)
			end
		end
	end

	local dispelTexture = element.dispelTexture
	if dispelTexture then
		dispelTexture.dispelAlpha = dispelTexture.dispelAlpha or 1
		dispelTexture.noDispelAlpha = dispelTexture.noDispelAlpha or 0
	end

	if not element.dispelColorCurve then
		local curve = _G.C_CurveUtil.CreateColorCurve()
		curve:SetType(_G.Enum.LuaCurveType.Step)

		for _, dispel in next, oUF.Enum.DispelType do
			local color = self.colors.dispel[dispel]

			if color then
				local r, g, b = color:GetRGB()
				curve:AddPoint(dispel, _G.CreateColor(r, g, b, dispelTexture and dispelTexture.dispelAlpha))
			end
		end

		element.dispelColorCurve = curve
	end

	if not element.resetColor then
		element.resetColor = _G.CreateColor(1, 1, 1, dispelTexture and dispelTexture.noDispelAlpha)
	end

	element.UpdateColor = element.UpdateColor or UpdateColor

	self:RegisterEvent('UNIT_AURA', Path)

	return true
end

local function Disable(self)
	local element = self.Dispellable
	if not element then
		return
	end

	self:UnregisterEvent('UNIT_AURA', Path)

	if element.dispelIcon then
		element.dispelIcon:Hide()
	end

	element:UpdateColor(self.unit)
end

oUF:AddElement('Dispellable', Path, Enable, Disable)

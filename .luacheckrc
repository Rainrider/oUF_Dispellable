std = 'lua51'

quiet = 1 -- suppress report output for files without warnings

read_globals = {
	table = { fields = { 'wipe' } },

	-- API
    C_UnitAuras = {
		fields = {
			'GetAuraApplicationDisplayCount',
			'GetAuraByAuraInstanceID',
			'GetAuraDataBySlot',
			'GetAuraDispelTypeColor',
			'GetAuraDuration',
			'GetAuraSlots',
			'IsAuraFilteredOutByInstanceID',
		},
	},
	'CreateFrame',
	'UnitCanAssist',

	-- Widgets
	'GameTooltip',

	-- Namespaces
	'oUF',
}

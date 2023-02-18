std = 'lua51'

quiet = 1 -- suppress report output for files without warnings

read_globals = {
	-- CONSTANTS
	'DebuffTypeColor',

	bit = { fields = { 'band' } },
	table = { fields = { 'wipe' } },

	-- API
    C_UnitAuras = {
		fields = { 'GetAuraByAuraInstanceID', 'GetAuraDataBySlot' }
	},
	'CreateFrame',
	'IsPlayerSpell',
	'IsSpellKnown',
	'UnitAuraSlots',
	'UnitCanAssist',
	'UnitClass',
	'UnitRace',

	-- Widgets
	'GameTooltip',

	-- Namespaces
	'LibStub',
	'oUF',
}

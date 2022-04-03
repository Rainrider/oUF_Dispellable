std = 'lua51'

quiet = 1 -- suppress report output for files without warnings

read_globals = {
	-- CONSTANTS
	'DebuffTypeColor',

	bit = {fields = {'band'}},
	table = {fields = {'wipe'}},

	-- API
	'CreateFrame',
	'IsPlayerSpell',
	'IsSpellKnown',
	'UnitCanAssist',
	'UnitClass',
	'UnitDebuff',
	'UnitRace',

	-- Widgets
	'GameTooltip',

	-- Namespaces
	'LibStub',
	'oUF',
}

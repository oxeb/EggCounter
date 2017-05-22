local LibAddOnMenu2 = LibStub:GetLibrary("LibAddonMenu-2.0")

EggCounter = {}
EggCounter.name = "EggCounter"
EggCounter.settingsName = "Egg Counter"
EggCounter.settingsAuthor = "Gnevsyrom"
EggCounter.settingsCommand = "/eggc"
EggCounter.settingsVersion = "0.0.1"
--EggCounter.chatChannelType = CHAT_CHANNEL_PARTY
EggCounter.chatChannelType = CHAT_CHANNEL_SAY
EggCounter.chatSystemReady = false
EggCounter.ultimateSlotNumber = 8
EggCounter.ultimatePower = 0
EggCounter.mainBarActive = true
EggCounter.mainBarUltimateName = ""
EggCounter.mainBarUltimateCost = 0
EggCounter.mainBarUltimateReady = false
EggCounter.backupBarUltimateName = ""
EggCounter.backupBarUltimateCost = 0
EggCounter.backupBarUltimateReady = false
EggCounter.ultimateNameTable = {}
EggCounter.ultimateEncodingTable = {}
EggCounter.ultimateDropdownMenuTable = nil
EggCounter.ultimateStatusTable = {}

EggCounter.indicatorLabelTable = {}
EggCounter.indicatorTextureTable = {}
EggCounter.indicatorStatusTable = {}

EggCounter.ultimateDisplayGridTable = {}

--################################################################################
function b2s(x)
	if x == true then
		return "true"
	elseif x == false then
		return "false"
	elseif x == nil then
		return "nil"
	else
		return x
	end
end

function d2s(x, y)
	d(x .. " " .. b2s(y))
end
--################################################################################

function EggCounter:DisplayMessage(message)
	if self.chatSystemReady then
		CHAT_SYSTEM["containers"][1]["currentBuffer"]:AddMessage(message)
	end
end

function EggCounter:DisplayPrompt(ultimateName, ultimateReady)
	local encoding = self.ultimateNameTable[ultimateName]
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		local track = self.ultimateEncodingTable[encoding].track
		if track then
			if ultimateReady then
				self:DisplayMessage(ultimateName .. " is ready.")
			else
				self:DisplayMessage(ultimateName .. " is not ready.")
			end
		end
	end
end

function EggCounter:DetectUltimateStatus(override)
	--Detect the current ultimate status
	local ultimatePower, ultimatePowerMaximum, ultimatePowerEffectiveMaximum = GetUnitPower("player", POWERTYPE_ULTIMATE)
	local ultimateName = GetSlotName(self.ultimateSlotNumber)
	local ultimateCost, ultimateMechanic = GetSlotAbilityCost(self.ultimateSlotNumber)
	local mainBarActive = false
	local mainBarUltimateName = self.mainBarUltimateName
	local mainBarUltimateCost = self.mainBarUltimateCost
	local mainBarUltimateReady = false
	local backupBarUltimateName = self.backupBarUltimateName
	local backupBarUltimateCost = self.backupBarUltimateCost
	local backupBarUltimateReady = false
	local activeWeaponPair, activeWeaponPairLocked = GetActiveWeaponPairInfo()
	if activeWeaponPair == ACTIVE_WEAPON_PAIR_MAIN then
		mainBarActive = true
		mainBarUltimateName = ultimateName
		mainBarUltimateCost = ultimateCost
	else
		backupBarUltimateName = ultimateName
		backupBarUltimateCost = ultimateCost
	end
	if ultimatePower >= mainBarUltimateCost then
		mainBarUltimateReady = true
	end
	if ultimatePower >= backupBarUltimateCost then
		backupBarUltimateReady = true
	end

	--Display a prompt to the user if the ultimate status has changed
	if (mainBarUltimateName ~= self.mainBarUltimateName) or
	(mainBarUltimateCost ~= self.mainBarUltimateCost) or
	(mainBarUltimateReady ~= self.mainBarUltimateReady) or override then
		self:DisplayPrompt(mainBarUltimateName, mainBarUltimateReady)
	end
	if (backupBarUltimateName ~= self.backupBarUltimateName) or 
	(backupBarUltimateCost ~= self.backupBarUltimateCost) or 
	(backupBarUltimateReady ~= self.backupBarUltimateReady) or override then
		self:DisplayPrompt(backupBarUltimateName, backupBarUltimateReady)
	end

	--Save the updated ultimate status
	self.ultimatePower = ultimatePower
	self.mainBarActive = mainBarActive
	self.mainBarUltimateName = mainBarUltimateName
	self.mainBarUltimateCost = mainBarUltimateCost
	self.mainBarUltimateReady = mainBarUltimateReady
	self.backupBarUltimateName = backupBarUltimateName
	self.backupBarUltimateCost = backupBarUltimateCost
	self.backupBarUltimateReady = backupBarUltimateReady
end

function EggCounter:InitializeUltimate(encoding, morph1, morph2, morph3, name)
	self.ultimateNameTable[morph1] = encoding
	self.ultimateNameTable[morph2] = encoding
	self.ultimateNameTable[morph3] = encoding
	self.ultimateEncodingTable[encoding] = {}
	self.ultimateEncodingTable[encoding].encoding = encoding
	if type(name) == "string" then
		self.ultimateEncodingTable[encoding].name = name
	else
		self.ultimateEncodingTable[encoding].name = morph1
	end
	self.ultimateEncodingTable[encoding].track = false
	self.ultimateEncodingTable[encoding].texture = nil
end

function EggCounter:TrackUltimate(encoding)
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		self.ultimateEncodingTable[encoding].track = true
	end
end

function EggCounter:SetUltimateTexture(encoding, texture)
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		self.ultimateEncodingTable[encoding].texture = texture
	end
end

function EggCounter:GetUltimateName(encoding)
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		return self.ultimateEncodingTable[encoding].name
	end
	return nil
end

function EggCounter:InitializeIndicator(index, x, y, visible, labelObject, labelContent, textureObject, textureContent)
	self.ultimateDisplayGridTable[index].x = x
	self.ultimateDisplayGridTable[index].y = y
	self.ultimateDisplayGridTable[index].label = label
	self.ultimateDisplayGridTable[index].texture = texture
	
end

function EggCounter:Initialize()
	--Dragonknight
	self:InitializeUltimate("0001",	"Dragonknight Standard",	"Shifting Standard",		"Standard of Might",		nil)				--1
	self:InitializeUltimate("0002",	"Dragon Leap",				"Take Flight",				"Ferocious Leap",			nil)				--2
	self:InitializeUltimate("0003",	"Magma Armor",				"Magma Shell",				"Corrosive Armor",			nil)				--3
	--Nightblade
	self:InitializeUltimate("0011",	"Death Stroke",				"Incapacitating Strike",	"Soul Harvest",				nil)				--4
	self:InitializeUltimate("0012",	"Consuming Darkness",		"Bolstering Darkness",		"Veil of Blades",			nil)				--5
	self:InitializeUltimate("0013",	"Soul Shred",				"Soul Siphon",				"Soul Tether",				nil)				--6
	--Sorcerer
	self:InitializeUltimate("0021",	"Summon Storm Atronach",	"Greater Storm Atronach",	"Summon Charged Atronach",	nil)				--7
	self:InitializeUltimate("0022",	"Negate Magic",				"Suppresion Field",			"Absorption Field",			nil)				--8
	self:InitializeUltimate("0023",	"Overload",					"Energy Overload",			"Power Overload",			nil)				--9
	--Templar													BURNING REMEMBRANCE!!!
	self:InitializeUltimate("0031",	"Radial Sweep",				"Empowering Sweep",			"Crescent Sweep",			nil)				--10
	self:InitializeUltimate("0032",	"Nova",						"Solar Disturbance",		"Solar Prison",				nil)				--11
	self:InitializeUltimate("0033",	"Rite of Passage",			"Remembrance",				"Practised Incantation",	nil)				--12
	--Warden
	self:InitializeUltimate("0041",	"Secluded Grove",			"Enchanted Forest",			"Healing Thicket",			nil)				--13
	self:InitializeUltimate("0042",	"Feral Guardian",			"Eternal Guardian",			"Wild Guardian",			nil)				--14
	self:InitializeUltimate("0043",	"Sleet Storm",				"Northern Storm",			"Permafrost",				nil)				--15
	--Weapons
	self:InitializeUltimate("0101",	"Berserker Strike",			"Onslaught",				"Berserker Rage",			nil)				--16
	self:InitializeUltimate("0102",	"Shield Wall",				"Spell Wall",				"Shield Discipline",		nil)				--17
	self:InitializeUltimate("0103",	"Lacerate",					"Rend",						"Thrive in Chaos",			nil)				--18
	self:InitializeUltimate("0104",	"Rapid Fire",				"Toxic Barrage",			"Ballista",					nil)				--19
	self:InitializeUltimate("0105",	"Fire Storm",				"Fiery Rage",				"Eye of Flame",				"Elemental Storm")	--20
	self:InitializeUltimate("0105",	"Thunder Storm",			"Thunderous Rage",			"Eye of Lightning",			"Elemental Storm")	--20
	self:InitializeUltimate("0105",	"Ice Storm",				"Icy Rage",					"Eye of Frost",				"Elemental Storm")	--20
	self:InitializeUltimate("0106",	"Panacea",					"Life Giver",				"Light's Champion",			nil)				--21
	--World
	self:InitializeUltimate("0111",	"Soul Strike",				"Soul Assault",				"Shatter Soul",				nil)				--22
	self:InitializeUltimate("0112",	"Bat Swarm",				"Clouding Swarm",			"Devouring Swarm",			nil)				--23
	self:InitializeUltimate("0113",	"Werewolf Transformation",	"Pack Leader",				"Werewolf Berserker",		nil)				--24
	--Guild
	self:InitializeUltimate("0121",	"Dawnbreaker",				"Flawless Dawnbreaker",		"Dawnbreaker of Smiting",	nil)				--25
	self:InitializeUltimate("0122",	"Meteor",					"Ice Comet",				"Shooting Star",			nil)				--26
	--Alliance War
	self:InitializeUltimate("0131",	"War Horn",					"Aggressive Horn",			"Sturdy Horn",				nil)				--27
	self:InitializeUltimate("0132",	"Barrier",					"Replenishing Barrier",		"Reviving Barrier",			nil)				--28

	self:TrackUltimate("0001")	--Dragonknight Standard
	self:TrackUltimate("0022")	--Negate Magic
	self:TrackUltimate("0105")	--Elemental Storm
	self:TrackUltimate("0121")	--Dawnbreaker
	self:TrackUltimate("0122")	--Meteor

	self:SetUltimateTexture("0001", "esoui/art/icons/ability_dragonknight_006.dds")			--Dragonknight Standard
	self:SetUltimateTexture("0002", "esoui/art/icons/ability_dragonknight_009.dds")			--Dragon Leap
	self:SetUltimateTexture("0003", "esoui/art/icons/ability_dragonknight_018.dds")			--Magma Armor
	self:SetUltimateTexture("0011", "esoui/art/icons/ability_nightblade_007.dds")			--Death Stroke
	self:SetUltimateTexture("0012", "esoui/art/icons/ability_nightblade_015.dds")			--Consuming Darkness
	self:SetUltimateTexture("0013", "esoui/art/icons/ability_nightblade_018.dds")			--Soul Shred
	self:SetUltimateTexture("0021", "esoui/art/icons/ability_sorcerer_storm_atronach.dds")	--Summon Storm Atronach
	self:SetUltimateTexture("0022", "esoui/art/icons/ability_sorcerer_monsoon.dds")			--Negate Magic
	self:SetUltimateTexture("0023", "esoui/art/icons/ability_sorcerer_overload.dds")		--Overload
	self:SetUltimateTexture("0031", "esoui/art/icons/ability_templar_radial_sweep.dds")		--Radial Sweep
	self:SetUltimateTexture("0032", "esoui/art/icons/ability_templar_nova.dds")				--Nova
	self:SetUltimateTexture("0033", "esoui/art/icons/ability_templar_rite_of_passage.dds")	--Rite of Passage
	self:SetUltimateTexture("0041", "esoui/art/icons/ability_warden_012.dds")				--Secluded Grove
	self:SetUltimateTexture("0042", "esoui/art/icons/ability_warden_018.dds")				--Feral Guardian
	self:SetUltimateTexture("0043", "esoui/art/icons/ability_warden_006.dds")				--Sleet Storm
	self:SetUltimateTexture("0101", "esoui/art/icons/ability_2handed_006.dds")				--Berserker Strike
	self:SetUltimateTexture("0102", "esoui/art/icons/ability_1handed_006.dds")				--Shield Wall
	self:SetUltimateTexture("0103", "esoui/art/icons/ability_dualwield_006.dds")			--Lacerate
	self:SetUltimateTexture("0104", "esoui/art/icons/ability_bow_006.dds")					--Rapid Fire
	self:SetUltimateTexture("0105", "esoui/art/icons/ability_destructionstaff_012.dds")		--Elemental Storm
	self:SetUltimateTexture("0106", "esoui/art/icons/ability_restorationstaff_006.dds")		--Panacea
	self:SetUltimateTexture("0111", "esoui/art/icons/ability_otherclass_002.dds")			--Soul Strike
	self:SetUltimateTexture("0112", "esoui/art/icons/ability_vampire_001.dds")				--Bat Swarm
	self:SetUltimateTexture("0113", "esoui/art/icons/ability_werewolf_001.dds")				--Werewolf Transformation
	self:SetUltimateTexture("0121", "esoui/art/icons/ability_fightersguild_005.dds")		--Dawnbreaker
	self:SetUltimateTexture("0122", "esoui/art/icons/ability_mageguild_005.dds")			--Meteor
	self:SetUltimateTexture("0131", "esoui/art/icons/ability_ava_003.dds")					--War Horn
	self:SetUltimateTexture("0132", "esoui/art/icons/ability_ava_006.dds")					--Barrier

	--This is a contrived attempt to ensure that no ultimate name
	--is mispelled and that ultimates are listed in alphabetical
	--order in dropdown menus.
	self.ultimateDropdownMenuTable = {
		"None",
		self:GetUltimateName("0001"),	self:GetUltimateName("0002"),	self:GetUltimateName("0003"),
		self:GetUltimateName("0011"),	self:GetUltimateName("0012"),	self:GetUltimateName("0013"),
		self:GetUltimateName("0021"),	self:GetUltimateName("0022"),	self:GetUltimateName("0023"),
		self:GetUltimateName("0031"),	self:GetUltimateName("0032"),	self:GetUltimateName("0033"),
		self:GetUltimateName("0041"),	self:GetUltimateName("0042"),	self:GetUltimateName("0043"),
		self:GetUltimateName("0101"),	self:GetUltimateName("0102"),	self:GetUltimateName("0103"),
		self:GetUltimateName("0104"),	self:GetUltimateName("0105"),	self:GetUltimateName("0106"),
		self:GetUltimateName("0111"),	self:GetUltimateName("0112"),	self:GetUltimateName("0113"),
		self:GetUltimateName("0121"),	self:GetUltimateName("0122"),
		self:GetUltimateName("0131"),	self:GetUltimateName("0132"),
	}

	self.indicatorLabelTable[1] = EggCounterIndicatorLabel11
	self.indicatorLabelTable[2] = EggCounterIndicatorLabel12
	self.indicatorLabelTable[3] = EggCounterIndicatorLabel13
	self.indicatorLabelTable[4] = EggCounterIndicatorLabel14
	self.indicatorLabelTable[5] = EggCounterIndicatorLabel15
	self.indicatorLabelTable[6] = EggCounterIndicatorLabel21
	self.indicatorLabelTable[7] = EggCounterIndicatorLabel22
	self.indicatorLabelTable[8] = EggCounterIndicatorLabel23
	self.indicatorLabelTable[9] = EggCounterIndicatorLabel24
	self.indicatorLabelTable[10] = EggCounterIndicatorLabel25
	for key in pairs(self.indicatorLabelTable) do
		--self.indicatorLabelTable[key]:SetHidden(true)
	end

	self.indicatorTextureTable[1] = EggCounterIndicatorTexture11
	self.indicatorTextureTable[2] = EggCounterIndicatorTexture12
	self.indicatorTextureTable[3] = EggCounterIndicatorTexture13
	self.indicatorTextureTable[4] = EggCounterIndicatorTexture14
	self.indicatorTextureTable[5] = EggCounterIndicatorTexture15
	self.indicatorTextureTable[6] = EggCounterIndicatorTexture21
	self.indicatorTextureTable[7] = EggCounterIndicatorTexture22
	self.indicatorTextureTable[8] = EggCounterIndicatorTexture23
	self.indicatorTextureTable[9] = EggCounterIndicatorTexture24
	self.indicatorTextureTable[10] = EggCounterIndicatorTexture25
	for key in pairs(self.indicatorTextureTable) do
		--self.indicatorTextureTable[key]:SetHidden(true)
	end


	
	EggCounterIndicator:SetHidden(false)

	--Fetch the saved variables from their file
	self.savedVariables = ZO_SavedVars:New("EggCounterSavedVariables", 1, nil, {})
	self:LoadIndicatorPosition()
	
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ACTION_SLOTS_FULL_UPDATE, self.OnActionSlotsFullUpdate)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ACTION_SLOT_UPDATED, self.OnActionSlotUpdated)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_POWER_UPDATE, self.OnPowerUpdate)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CHAT_MESSAGE_CHANNEL, self.OnChatMessageChannel)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GROUP_MEMBER_LEFT, self.OnGroupMemberLeft)

	self:DetectUltimateStatus(true)

	--End this horrible nightmare!
	EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)

	self.chatSystemReady = true

	self:Settings()
end

function EggCounter:GetSettingsDropdownMenuValue(menuNumber)
	d2s("menuNumber = ", menuNumber)
	d2s("menuValue = ", "None")
	return "None"
end

function EggCounter:SetSettingsDropdownMenuValue(menuNumber, menuValue)
	d2s("menuNumber = ", menuNumber)
	d2s("menuValue = ", menuValue)
end

function EggCounter:GenerateSettingsDropdownMenu(menuNumber, menuName, menuTooltip, menuDefault)
	return {
		type = "dropdown",
		name = menuName,
		tooltip = menuTooltip,
		choices = self.ultimateDropdownMenuTable,
		default = menuDefault,
		getFunc = function() return EggCounter:GetSettingsDropdownMenuValue(menuNumber) end,
		setFunc = function(menuValue) EggCounter:SetSettingsDropdownMenuValue(menuNumber, menuValue) end,
		width = "full",
	}
end

function EggCounter:Settings()
	local settingsPanelData = {
		type = "panel",
		name = self.settingsName,
		displayName = self.settingsName,
		author = self.settingsAuthor,
		version = self.settingsVersion,
		slashCommand = self.settingsCommand,
		registerForRefresh = true,
		registerForDefaults = true,
	}
	local settingsPanelControlData = {
		[1] = {
			type = "header",
			name = "Interface Scale Settings",
		},
		[2] = {
			type = "description",
			text = "Adjust the size and scale of the Ultimate Display Grid"
		},
		[3] = {
			type = "slider",
			name = "Font Size",
			tooltip = "",
			min = 1,
			max = 5,
			step = 1,
			getFunc = function() return 1 end,
			setFunc = function(value) end,
			width = "full",
			default = "1",
		},
		[4] = {
			type = "slider",
			name = "Interface Scale in Pixels",
			tooltip = "Adjust the size of the icons and text in the Ultimate Display Grid",
			min = 32,
			max = 128,
			step = 1,
			getFunc = function() return 48 end,
			setFunc = function(value) d2s("slider value = ", value) end,
			width = "full",
			default = "48",
		},
		[5] = {
			type = "slider",
			name = "Ultimate Display Grid Width",
			tooltip = "",
			min = 1,
			max = 5,
			step = 1,
			getFunc = function() return 2 end,
			setFunc = function(value) end,
			width = "full",
			default = "3",
		},
		[6] = {
			type = "slider",
			name = "Ultimate Display Grid Height",
			tooltip = "",
			min = 1,
			max = 5,
			step = 1,
			getFunc = function() return 2 end,
			setFunc = function(value) end,
			width = "full",
			default = "3",
		},
		[7] = {
			type = "header",
			name = "Ultimate Tracking Settings",
			
		},
		[8] = {
			type = "description",
			text = "Select which ultimate abilities to track with the Ultimate Display Grid"
		},
		[9] = self:GenerateSettingsDropdownMenu(1, "Alpha", "Beta"),
		[10] = self:GenerateSettingsDropdownMenu(2, "Gamma", "Delta"),
	}
	
	--The first parameter to LibAddOnMenu2:RegisterAddonPanel and 
	--LibAddOnMenu2:RegisterOptionControls must be the same unique
	--string literal.  If the parameters are not such a literal then
	--many variables go out of the global scope, and this breaks any
	--interaction between this source file and the rest of the addon.
	--I go to a dark place when I consider the implications of this.
	local settingsPanelHandle = LibAddOnMenu2:RegisterAddonPanel("EggCounter_Gnevsyrom", settingsPanelData)
	LibAddOnMenu2:RegisterOptionControls("EggCounter_Gnevsyrom", settingsPanelControlData)
end

--This can be called from XML so it is a function and not a method
function EggCounter.Detect()
	EggCounter:DetectUltimateStatus(true)
end

function EggCounter:GenerateReportMessage(ultimateName, ultimateReady)
	local message = "0000f"
	local encoding = self.ultimateNameTable[ultimateName]
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		local readyMessage = "f"
		if ultimateReady then
			readyMessage = "t"
		end
		message = encoding .. readyMessage
	end
	return message
end

--This can be called from XML so it is a function and not a method
function EggCounter.Report()
	local mainBarUltimateMessage = EggCounter:GenerateReportMessage(EggCounter.mainBarUltimateName, EggCounter.mainBarUltimateReady)
	local backupBarUltimateMessage = EggCounter:GenerateReportMessage(EggCounter.backupBarUltimateName, EggCounter.backupBarUltimateReady)
	local message = "#@$?%" .. mainBarUltimateMessage .. "^" .. backupBarUltimateMessage
	StartChatInput(message, EggCounter.chatChannelType, nil)
end

function EggCounter.Reset()
end

--Load the top and left coordinates of the indicator from a file when
--the addon first starts
function EggCounter:LoadIndicatorPosition()
	local left = self.savedVariables.left
	local top = self.savedVariables.top
	EggCounterIndicator:ClearAnchors()
	EggCounterIndicator:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
end

--Save the top and left coordinates of the indicator to a file whenever it 
--moves so that the position is preserved across multiple play sessions
--This can be called from XML so it is a function and not a method
function EggCounter.OnMoveStop()
	EggCounter.savedVariables.left = EggCounterIndicator:GetLeft()
	EggCounter.savedVariables.top = EggCounterIndicator:GetTop()
end

--This can be called from an event so it is a function and not a method
--EVENT_ACTION_SLOTS_FULL_UPDATE (integer eventCode,boolean isHotbarSwap)
function EggCounter.OnActionSlotsFullUpdate(eventCode, isHotBarSwap)
	EggCounter:DetectUltimateStatus(false)
end

--This can be called from an event so it is a function and not a method
--EVENT_ACTION_SLOT_UPDATED (integer eventCode,number slotNum)
function EggCounter.OnActionSlotUpdated(eventCode, slot)
	if slotNumber == EggCounter.ultimateSlotNumber then
		EggCounter:DetectUltimateStatus(false)
	end
end

--This can be called from an event so it is a function and not a method
--EVENT_POWER_UPDATE (integer eventCode,string unitTag, number powerIndex, number powerType, number powerValue, number powerMax, number powerEffectiveMax)
function EggCounter.OnPowerUpdate(eventCode, unitTag, powerIndex, powerType, powerValue, powerMaximum, powerEffectiveMaximum)
	if powerType == POWERTYPE_ULTIMATE then
		EggCounter:DetectUltimateStatus(false)
	end
end

function EggCounter:IsDigit(character)
	if (character >= 48) and (character <= 57) then --0		48	9		57
		return true
	end
	return false
end

function EggCounter:IsBoolean(character)
	if (character == 102) or (character == 116) then --f		102	t		116
		return true
	end
	return false
end

function EggCounter:ValidateMessage(message)
	--#@$?%xxxxy^xxxxy
	--123456789abcdef0
	if string.byte(message, 1) ~= 35 then return false end --#		35
	if string.byte(message, 2) ~= 64 then return false end --@		64
	if string.byte(message, 3) ~= 36 then return false end --$		36
	if string.byte(message, 4) ~= 63 then return false end --?		63
	if string.byte(message, 5) ~= 37 then return false end --%		37
	if not self:IsDigit(string.byte(message, 6)) then return false end
	if not self:IsDigit(string.byte(message, 7)) then return false end
	if not self:IsDigit(string.byte(message, 8)) then return false end
	if not self:IsDigit(string.byte(message, 9)) then return false end
	if not self:IsBoolean(string.byte(message, 10)) then return false end
	if string.byte(message, 11) ~= 94 then return false end --^		94
	if not self:IsDigit(string.byte(message, 12)) then return false end
	if not self:IsDigit(string.byte(message, 13)) then return false end
	if not self:IsDigit(string.byte(message, 14)) then return false end
	if not self:IsDigit(string.byte(message, 15)) then return false end
	if not self:IsBoolean(string.byte(message, 16)) then return false end
	return true
end

function EggCounter:DecodeBoolean(character)
	if character == 116 then --t		116
		return true
	end
	return false
end

function EggCounter.Slash(message)
	d(message)
	EggCounterIndicatorTexture:SetTexture(message)
end

--This can be called from an event so it is a function and not a method
--EVENT_CHAT_MESSAGE_CHANNEL (integer eventCode,number channelType, string fromName, string text, boolean isCustomerService, string fromDisplayName)
function EggCounter.OnChatMessageChannel(eventCode, channelType, fromName, text, isCustomerService, fromDisplayName)
	local messageLength = string.len(text)
	if (channelType == EggCounter.chatChannelType) and (not isCustomerService) and (messageLength == 16) then
		if EggCounter:ValidateMessage(text) then
			local mainBarUltimateEncoding = string.sub(text, 6, 9)
			local mainBarUltimateReady = EggCounter:DecodeBoolean(string.byte(text, 10))
			local backupBarUltimateEncoding = string.sub(text, 12, 15)
			local backupBarUltimateReady = EggCounter:DecodeBoolean(string.byte(text, 16))
			d2s("fromDisplayName = ", fromDisplayName)
			d2s("mainBarUltimateEncoding = ", mainBarUltimateEncoding)
			d2s("mainBarUltimateReady = ", mainBarUltimateReady)
			d2s("backupBarUltimateEncoding = ", backupBarUltimateEncoding)
			d2s("backupBarUltimateReady = ", backupBarUltimateReady)
			
			--EggCounterIndicatorLabel:SetText(mainBarUltimateEncoding)
		end
	end
end

--This can be called from an event so it is a function and not a method
--EVENT_GROUP_MEMBER_LEFT (integer eventCode,string memberCharacterName, number reason, boolean isLocalPlayer, boolean isLeader, string memberDisplayName, boolean actionRequiredVote)
function EggCounter.OnGroupMemberLeft(eventCode, memberCharacterName, reason, isLocalPlayer, isLeader, memberDisplayName, actionRequiredVote)
	d2s("memberDisplayName = ", memberDisplayName)
end

--This can be called from an event so it is a function and not a method
--EVENT_ADD_ON_LOADED (integer eventCode,string addonName)
function EggCounter.OnAddOnLoaded(event, addOnName)
	
	--Ensure that this event is actually for Egg Counter
	if addOnName == EggCounter.name then
		EggCounter:Initialize()
	end
end

EVENT_MANAGER:RegisterForEvent(EggCounter.name, EVENT_ADD_ON_LOADED, EggCounter.OnAddOnLoaded)
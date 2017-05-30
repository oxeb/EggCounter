local LibAddOnMenu2 = LibStub:GetLibrary("LibAddonMenu-2.0")

EggCounter = {}
EggCounter.name = "EggCounter"
--This is used with saved variables in case their
--format changes later
EggCounter.version = 1
--This is for LibAddOnMenu2 and is used
--when creating the settings menu
EggCounter.settingsName = "Egg Counter"
EggCounter.settingsAuthor = "Gnevsyrom"
EggCounter.settingsCommand = "/eggc"
EggCounter.settingsVersion = "0.0.1"
--This is set to true at the end of initialization
--The chat system is not ready prior to this and using
--it will crash the addon
EggCounter.chatSystemReady = false
--Debug mode is toggled by typing /eggd
--When it is enabled CHAT_CHANNEL_SAY works
--in addition to CHAT_CHANNEL_PARTY
EggCounter.debug = false
EggCounter.debugCommand = "/eggd"
--This is the ultimate status information for the
--player running this addon only
EggCounter.ultimateSlotNumber = 8
EggCounter.ultimatePower = 0
EggCounter.mainBarActive = true
EggCounter.mainBarUltimateName = ""
EggCounter.mainBarUltimateCost = 0
EggCounter.mainBarUltimateReady = false
EggCounter.backupBarUltimateName = ""
EggCounter.backupBarUltimateCost = 0
EggCounter.backupBarUltimateReady = false
--This table converts ultimate names to
--a 4 digit decimal string called the encoding
--The different morphs of an ability all share one
--encoding
--There is also an encoding "0000" which
--is intended to be absent from the table
EggCounter.ultimateDropdownNamePrefix = ""
EggCounter.ultimateNameTable = {}
EggCounter.ultimateDropdownNameTable = {}
--This table takes an encoding and stores static information
--about the ultimate ability with that encoding
EggCounter.ultimateEncodingTable = {}
--This table contains the ultimate abilities in a specific
--ordering and ensures that literals are not duplicated in the
--source code
--Duplicate literals do not take up additional memory because
--of how lua works but they do introduce more points of failure
EggCounter.ultimateDropdownMenuTable = nil
--These are the ultimate display grid size constraints
EggCounter.minimumUltimateDisplayGridHeight = 1
EggCounter.maximumUltimateDisplayGridHeight = 5
EggCounter.minimumUltimateDisplayGridWidth = 1
EggCounter.maximumUltimateDisplayGridWidth = 5
--This table is indexed by account display names and stores
--that players current ultimate status
--When in debug mode the state of this table is not
--guaranteed to be coherent
EggCounter.ultimateStatusTable = {}
--This table stores the grid coordinates texures and labels
--for the ultimate display grid
--It is needed because they are declared in XML
EggCounter.ultimateDisplayGridTable = {}
--These are the default values for the settings panel
--These measurements are in display units and not pixels
--The font values are black magic that hurts my soul
EggCounter.default = {
	ultimateDisplayGridLeft = 128,
	ultimateDisplayGridTop = 128,
	ultimateDisplayGridVisibility = "Visible",
	ultimateDisplayGridOpacity = 45,
	ultimateDisplayGridTextureSize = 48,
	ultimateDisplayGridLabelSize = 32,
	ultimateDisplayGridFontSize = 5,
	ultimateDisplayGridFont = "ZoFontWinH1",
	ultimateDisplayGridWidth = EggCounter.maximumUltimateDisplayGridWidth,
	ultimateDisplayGridHeight = EggCounter.maximumUltimateDisplayGridHeight,
	utlimateDisplayGridTrackingTable = {},
}

--Display a formatted string in the chat window
--This is different from a debug string made with d()
--or a player message made with StartChatInput()
function EggCounter:DisplayMessage(message)
	if self.chatSystemReady then
		CHAT_SYSTEM["containers"][1]["currentBuffer"]:AddMessage(message)
	end
end

--Display a prompt automatically whenever ultimate status
--changes in a significant way
--This will only display messages if the ultimates exist in
--the encoding table
function EggCounter:DisplayPrompt(ultimateName, ultimateReady)
	local encoding = self.ultimateNameTable[ultimateName]
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		if ultimateReady then
			self:DisplayMessage(ultimateName .. " is ready.")
		else
			self:DisplayMessage(ultimateName .. " is not ready.")
		end
	end
end

--Detect the ultimate status and possibly display a prompt
--If override is true then a prompt will be display regardless
--of status changes
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
	--or if override is true
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

--These three functions handle events related to ultimate status
--This function handles weapon bar swap events
--This can be called from an event so it is a function and not a method
--EVENT_ACTION_SLOTS_FULL_UPDATE (integer eventCode,boolean isHotbarSwap)
function EggCounter.OnActionSlotsFullUpdate(eventCode, isHotBarSwap)
	EggCounter:DetectUltimateStatus(false)
end

--This function handles individual ability slot events
--This can be called from an event so it is a function and not a method
--EVENT_ACTION_SLOT_UPDATED (integer eventCode,number slotNum)
function EggCounter.OnActionSlotUpdated(eventCode, slot)
	if slotNumber == EggCounter.ultimateSlotNumber then
		EggCounter:DetectUltimateStatus(false)
	end
end

--This function handles the player gaining or losing ultimate power
--This can be called from an event so it is a function and not a method
--EVENT_POWER_UPDATE (integer eventCode,string unitTag, number powerIndex, number powerType, number powerValue, number powerMax, number powerEffectiveMax)
function EggCounter.OnPowerUpdate(eventCode, unitTag, powerIndex, powerType, powerValue, powerMaximum, powerEffectiveMaximum)
	if powerType == POWERTYPE_ULTIMATE then
		EggCounter:DetectUltimateStatus(false)
	end
end

--This function handles the Detect binding under controls
--This can be called from XML so it is a function and not a method
function EggCounter.OnDetectBinding()
	EggCounter:DetectUltimateStatus(true)
end

function EggCounter:SetUltimateDropdownNamePrefix(prefix)
	self.ultimateDropdownNamePrefix = prefix
end

--Initialize static data for ultimates
--This function exists to keep the code clean and
--to avoid literal duplication
function EggCounter:InitializeUltimate(encoding, morph1, morph2, morph3, name)
	self.ultimateNameTable[morph1] = encoding
	self.ultimateNameTable[morph2] = encoding
	self.ultimateNameTable[morph3] = encoding
	self.ultimateEncodingTable[encoding] = {}
	--Yuck
	local suffix = name
	if type(name) == "string" then
		self.ultimateNameTable[name] = encoding
		self.ultimateEncodingTable[encoding].name = name
	else
		self.ultimateEncodingTable[encoding].name = morph1
		suffix = morph1
	end
	local dropdownName = self.ultimateDropdownNamePrefix .. " - " .. suffix
	self.ultimateDropdownNameTable[dropdownName] = encoding
	self.ultimateEncodingTable[encoding].dropdownName = dropdownName
	self.ultimateEncodingTable[encoding].textureFile = nil
end

--Set the texture file for a given ultimate encoding
--This is a separate function for formatting reasons
function EggCounter:SetUltimateTextureFile(encoding, textureFile)
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		self.ultimateEncodingTable[encoding].textureFile = textureFile
	end
end

--Get the name of an ultimate from the encoding table to avoid
--literal duplication
function EggCounter:GetUltimateName(encoding)
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		return self.ultimateEncodingTable[encoding].name
	end
	return nil
end

function EggCounter:GetUltimateDropdownName(encoding)
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		return self.ultimateEncodingTable[encoding].dropdownName
	end
	return nil
end

--Initialize the table to index the XML controls with
--a variable instead of directly
--Populate the defaults for ultimate tracking here to avoid
--literal duplication
function EggCounter:InitializeUltimateDisplayGrid(index, x, y, texture, label, defaultEncoding)
	self.ultimateDisplayGridTable[index] = {}
	self.ultimateDisplayGridTable[index].x = x
	self.ultimateDisplayGridTable[index].y = y
	self.ultimateDisplayGridTable[index].texture = texture
	self.ultimateDisplayGridTable[index].label = label
	self.default.utlimateDisplayGridTrackingTable[index] = {}
	self.default.utlimateDisplayGridTrackingTable[index].visible = true
	self.default.utlimateDisplayGridTrackingTable[index].encoding = defaultEncoding
	self.default.utlimateDisplayGridTrackingTable[index].dropdownName = self:GetUltimateDropdownName(defaultEncoding)
end

--This function starts the addon
function EggCounter:Initialize()
	--Populate various tables
	--Dragonknight
	self:SetUltimateDropdownNamePrefix("Dragonknight")
	self:InitializeUltimate("0001",	"Dragonknight Standard",	"Shifting Standard",		"Standard of Might",		nil)				--1
	self:InitializeUltimate("0002",	"Dragon Leap",				"Take Flight",				"Ferocious Leap",			nil)				--2
	self:InitializeUltimate("0003",	"Magma Armor",				"Magma Shell",				"Corrosive Armor",			nil)				--3
	--Nightblade
	self:SetUltimateDropdownNamePrefix("Nightblade")
	self:InitializeUltimate("0011",	"Death Stroke",				"Incapacitating Strike",	"Soul Harvest",				nil)				--4
	self:InitializeUltimate("0012",	"Consuming Darkness",		"Bolstering Darkness",		"Veil of Blades",			nil)				--5
	self:InitializeUltimate("0013",	"Soul Shred",				"Soul Siphon",				"Soul Tether",				nil)				--6
	--Sorcerer
	self:SetUltimateDropdownNamePrefix("Sorcerer")
	self:InitializeUltimate("0021",	"Summon Storm Atronach",	"Greater Storm Atronach",	"Summon Charged Atronach",	nil)				--7
	self:InitializeUltimate("0022",	"Negate Magic",				"Suppresion Field",			"Absorption Field",			nil)				--8
	self:InitializeUltimate("0023",	"Overload",					"Energy Overload",			"Power Overload",			nil)				--9
	--Templar													BURNING REMEMBRANCE!!!
	self:SetUltimateDropdownNamePrefix("Templar")
	self:InitializeUltimate("0031",	"Radial Sweep",				"Empowering Sweep",			"Crescent Sweep",			nil)				--10
	self:InitializeUltimate("0032",	"Nova",						"Solar Disturbance",		"Solar Prison",				nil)				--11
	self:InitializeUltimate("0033",	"Rite of Passage",			"Remembrance",				"Practised Incantation",	nil)				--12
	--Warden
	self:SetUltimateDropdownNamePrefix("Warden")
	self:InitializeUltimate("0041",	"Secluded Grove",			"Enchanted Forest",			"Healing Thicket",			nil)				--13
	self:InitializeUltimate("0042",	"Feral Guardian",			"Eternal Guardian",			"Wild Guardian",			nil)				--14
	self:InitializeUltimate("0043",	"Sleet Storm",				"Northern Storm",			"Permafrost",				nil)				--15
	--Weapons
	self:SetUltimateDropdownNamePrefix("Weapon")
	self:InitializeUltimate("0101",	"Berserker Strike",			"Onslaught",				"Berserker Rage",			nil)				--16
	self:InitializeUltimate("0102",	"Shield Wall",				"Spell Wall",				"Shield Discipline",		nil)				--17
	self:InitializeUltimate("0103",	"Lacerate",					"Rend",						"Thrive in Chaos",			nil)				--18
	self:InitializeUltimate("0104",	"Rapid Fire",				"Toxic Barrage",			"Ballista",					nil)				--19
	self:InitializeUltimate("0105",	"Fire Storm",				"Fiery Rage",				"Eye of Flame",				"Elemental Storm")	--20
	self:InitializeUltimate("0105",	"Thunder Storm",			"Thunderous Rage",			"Eye of Lightning",			"Elemental Storm")	--20
	self:InitializeUltimate("0105",	"Ice Storm",				"Icy Rage",					"Eye of Frost",				"Elemental Storm")	--20
	self:InitializeUltimate("0106",	"Panacea",					"Life Giver",				"Light's Champion",			nil)				--21
	--World
	self:SetUltimateDropdownNamePrefix("World")
	self:InitializeUltimate("0111",	"Soul Strike",				"Soul Assault",				"Shatter Soul",				nil)				--22
	self:InitializeUltimate("0112",	"Bat Swarm",				"Clouding Swarm",			"Devouring Swarm",			nil)				--23
	self:InitializeUltimate("0113",	"Werewolf Transformation",	"Pack Leader",				"Werewolf Berserker",		nil)				--24
	--Guild
	self:SetUltimateDropdownNamePrefix("Guild")
	self:InitializeUltimate("0121",	"Dawnbreaker",				"Flawless Dawnbreaker",		"Dawnbreaker of Smiting",	nil)				--25
	self:InitializeUltimate("0122",	"Meteor",					"Ice Comet",				"Shooting Star",			nil)				--26
	--Alliance War
	self:SetUltimateDropdownNamePrefix("Alliance War")
	self:InitializeUltimate("0131",	"War Horn",					"Aggressive Horn",			"Sturdy Horn",				nil)				--27
	self:InitializeUltimate("0132",	"Barrier",					"Replenishing Barrier",		"Reviving Barrier",			nil)				--28

	--Assign the texture information
	self:SetUltimateTextureFile("0001", "esoui/art/icons/ability_dragonknight_006.dds")			--Dragonknight Standard
	self:SetUltimateTextureFile("0002", "esoui/art/icons/ability_dragonknight_009.dds")			--Dragon Leap
	self:SetUltimateTextureFile("0003", "esoui/art/icons/ability_dragonknight_018.dds")			--Magma Armor
	self:SetUltimateTextureFile("0011", "esoui/art/icons/ability_nightblade_007.dds")			--Death Stroke
	self:SetUltimateTextureFile("0012", "esoui/art/icons/ability_nightblade_015.dds")			--Consuming Darkness
	self:SetUltimateTextureFile("0013", "esoui/art/icons/ability_nightblade_018.dds")			--Soul Shred
	self:SetUltimateTextureFile("0021", "esoui/art/icons/ability_sorcerer_storm_atronach.dds")	--Summon Storm Atronach
	self:SetUltimateTextureFile("0022", "esoui/art/icons/ability_sorcerer_monsoon.dds")			--Negate Magic
	self:SetUltimateTextureFile("0023", "esoui/art/icons/ability_sorcerer_overload.dds")		--Overload
	self:SetUltimateTextureFile("0031", "esoui/art/icons/ability_templar_radial_sweep.dds")		--Radial Sweep
	self:SetUltimateTextureFile("0032", "esoui/art/icons/ability_templar_nova.dds")				--Nova
	self:SetUltimateTextureFile("0033", "esoui/art/icons/ability_templar_rite_of_passage.dds")	--Rite of Passage
	self:SetUltimateTextureFile("0041", "esoui/art/icons/ability_warden_012.dds")				--Secluded Grove
	self:SetUltimateTextureFile("0042", "esoui/art/icons/ability_warden_018.dds")				--Feral Guardian
	self:SetUltimateTextureFile("0043", "esoui/art/icons/ability_warden_006.dds")				--Sleet Storm
	self:SetUltimateTextureFile("0101", "esoui/art/icons/ability_2handed_006.dds")				--Berserker Strike
	self:SetUltimateTextureFile("0102", "esoui/art/icons/ability_1handed_006.dds")				--Shield Wall
	self:SetUltimateTextureFile("0103", "esoui/art/icons/ability_dualwield_006.dds")			--Lacerate
	self:SetUltimateTextureFile("0104", "esoui/art/icons/ability_bow_006.dds")					--Rapid Fire
	self:SetUltimateTextureFile("0105", "esoui/art/icons/ability_destructionstaff_012.dds")		--Elemental Storm
	self:SetUltimateTextureFile("0106", "esoui/art/icons/ability_restorationstaff_006.dds")		--Panacea
	self:SetUltimateTextureFile("0111", "esoui/art/icons/ability_otherclass_002.dds")			--Soul Strike
	self:SetUltimateTextureFile("0112", "esoui/art/icons/ability_vampire_001.dds")				--Bat Swarm
	self:SetUltimateTextureFile("0113", "esoui/art/icons/ability_werewolf_001.dds")				--Werewolf Transformation
	self:SetUltimateTextureFile("0121", "esoui/art/icons/ability_fightersguild_005.dds")		--Dawnbreaker
	self:SetUltimateTextureFile("0122", "esoui/art/icons/ability_mageguild_005.dds")			--Meteor
	self:SetUltimateTextureFile("0131", "esoui/art/icons/ability_ava_003.dds")					--War Horn
	self:SetUltimateTextureFile("0132", "esoui/art/icons/ability_ava_006.dds")					--Barrier

	self.ultimateDropdownMenuTable = {
		"None",
		self:GetUltimateDropdownName("0001"),	self:GetUltimateDropdownName("0002"),	self:GetUltimateDropdownName("0003"),
		self:GetUltimateDropdownName("0011"),	self:GetUltimateDropdownName("0012"),	self:GetUltimateDropdownName("0013"),
		self:GetUltimateDropdownName("0021"),	self:GetUltimateDropdownName("0022"),	self:GetUltimateDropdownName("0023"),
		self:GetUltimateDropdownName("0031"),	self:GetUltimateDropdownName("0032"),	self:GetUltimateDropdownName("0033"),
		self:GetUltimateDropdownName("0041"),	self:GetUltimateDropdownName("0042"),	self:GetUltimateDropdownName("0043"),
		self:GetUltimateDropdownName("0101"),	self:GetUltimateDropdownName("0102"),	self:GetUltimateDropdownName("0103"),
		self:GetUltimateDropdownName("0104"),	self:GetUltimateDropdownName("0105"),	self:GetUltimateDropdownName("0106"),
		self:GetUltimateDropdownName("0111"),	self:GetUltimateDropdownName("0112"),	self:GetUltimateDropdownName("0113"),
		self:GetUltimateDropdownName("0121"),	self:GetUltimateDropdownName("0122"),
		self:GetUltimateDropdownName("0131"),	self:GetUltimateDropdownName("0132"),
	}

	--This is done to avoid virtual controls
	self:InitializeUltimateDisplayGrid( 1, 1, 1, EggCounterUltimateDisplayGridTexture11, EggCounterUltimateDisplayGridLabel11, "0001")
	self:InitializeUltimateDisplayGrid( 2, 1, 2, EggCounterUltimateDisplayGridTexture12, EggCounterUltimateDisplayGridLabel12, "0002")
	self:InitializeUltimateDisplayGrid( 3, 1, 3, EggCounterUltimateDisplayGridTexture13, EggCounterUltimateDisplayGridLabel13, "0003")
	self:InitializeUltimateDisplayGrid( 4, 1, 4, EggCounterUltimateDisplayGridTexture14, EggCounterUltimateDisplayGridLabel14, "0101")
	self:InitializeUltimateDisplayGrid( 5, 1, 5, EggCounterUltimateDisplayGridTexture15, EggCounterUltimateDisplayGridLabel15, "0102")
	self:InitializeUltimateDisplayGrid( 6, 2, 1, EggCounterUltimateDisplayGridTexture21, EggCounterUltimateDisplayGridLabel21, "0011")
	self:InitializeUltimateDisplayGrid( 7, 2, 2, EggCounterUltimateDisplayGridTexture22, EggCounterUltimateDisplayGridLabel22, "0012")
	self:InitializeUltimateDisplayGrid( 8, 2, 3, EggCounterUltimateDisplayGridTexture23, EggCounterUltimateDisplayGridLabel23, "0013")
	self:InitializeUltimateDisplayGrid( 9, 2, 4, EggCounterUltimateDisplayGridTexture24, EggCounterUltimateDisplayGridLabel24, "0103")
	self:InitializeUltimateDisplayGrid(10, 2, 5, EggCounterUltimateDisplayGridTexture25, EggCounterUltimateDisplayGridLabel25, "0104")
	self:InitializeUltimateDisplayGrid(11, 3, 1, EggCounterUltimateDisplayGridTexture31, EggCounterUltimateDisplayGridLabel31, "0021")
	self:InitializeUltimateDisplayGrid(12, 3, 2, EggCounterUltimateDisplayGridTexture32, EggCounterUltimateDisplayGridLabel32, "0022")
	self:InitializeUltimateDisplayGrid(13, 3, 3, EggCounterUltimateDisplayGridTexture33, EggCounterUltimateDisplayGridLabel33, "0023")
	self:InitializeUltimateDisplayGrid(14, 3, 4, EggCounterUltimateDisplayGridTexture34, EggCounterUltimateDisplayGridLabel34, "0105")
	self:InitializeUltimateDisplayGrid(15, 3, 5, EggCounterUltimateDisplayGridTexture35, EggCounterUltimateDisplayGridLabel35, "0106")
	self:InitializeUltimateDisplayGrid(16, 4, 1, EggCounterUltimateDisplayGridTexture41, EggCounterUltimateDisplayGridLabel41, "0031")
	self:InitializeUltimateDisplayGrid(17, 4, 2, EggCounterUltimateDisplayGridTexture42, EggCounterUltimateDisplayGridLabel42, "0032")
	self:InitializeUltimateDisplayGrid(18, 4, 3, EggCounterUltimateDisplayGridTexture43, EggCounterUltimateDisplayGridLabel43, "0033")
	self:InitializeUltimateDisplayGrid(19, 4, 4, EggCounterUltimateDisplayGridTexture44, EggCounterUltimateDisplayGridLabel44, "0121")
	self:InitializeUltimateDisplayGrid(20, 4, 5, EggCounterUltimateDisplayGridTexture45, EggCounterUltimateDisplayGridLabel45, "0122")
	self:InitializeUltimateDisplayGrid(21, 5, 1, EggCounterUltimateDisplayGridTexture51, EggCounterUltimateDisplayGridLabel51, "0041")
	self:InitializeUltimateDisplayGrid(22, 5, 2, EggCounterUltimateDisplayGridTexture52, EggCounterUltimateDisplayGridLabel52, "0042")
	self:InitializeUltimateDisplayGrid(23, 5, 3, EggCounterUltimateDisplayGridTexture53, EggCounterUltimateDisplayGridLabel53, "0043")
	self:InitializeUltimateDisplayGrid(24, 5, 4, EggCounterUltimateDisplayGridTexture54, EggCounterUltimateDisplayGridLabel54, "0131")
	self:InitializeUltimateDisplayGrid(25, 5, 5, EggCounterUltimateDisplayGridTexture55, EggCounterUltimateDisplayGridLabel55, "0132")

	--Load saved variables and establish defaults
	self.savedVariables = ZO_SavedVars:NewAccountWide("EggCounterSavedVariables", self.version, nil, self.default)
	--Setup the ultimate display grid and unhide it
	self:SetUltimateDisplayGridPosition()
	self:FormatUltimateDisplayGrid()
	self:UpdateUltimateDisplayGridLabels()
	EggCounterUltimateDisplayGrid:SetHidden(false)
	--Register events
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ACTION_SLOTS_FULL_UPDATE, self.OnActionSlotsFullUpdate)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_ACTION_SLOT_UPDATED, self.OnActionSlotUpdated)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_POWER_UPDATE, self.OnPowerUpdate)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CHAT_MESSAGE_CHANNEL, self.OnChatMessageChannel)
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_GROUP_MEMBER_LEFT, self.OnGroupMemberLeft)
	--Take an initial look at the player ultimate status
	self:DetectUltimateStatus(true)
	--Unregister this method so that it does not run twice
	EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
	--The chat system should now be safe to use
	self.chatSystemReady = true
	--Register the debug command
	SLASH_COMMANDS[self.debugCommand] = EggCounter.ToggleDebug
	--The last thing to do is turn on the settings panel
	self:Settings()
end

--This function handles the init event
--This can be called from an event so it is a function and not a method
--EVENT_ADD_ON_LOADED (integer eventCode,string addonName)
function EggCounter.OnAddOnLoaded(event, addOnName)
	--Ensure that this event is actually for Egg Counter
	if addOnName == EggCounter.name then
		EggCounter:Initialize()
	end
end

--Load the ultimate display grid coordinates
function EggCounter:SetUltimateDisplayGridPosition()
	local left = self.savedVariables.ultimateDisplayGridLeft
	local top = self.savedVariables.ultimateDisplayGridTop
	--If the anchors are not cleared none of this works at all
	EggCounterUltimateDisplayGrid:ClearAnchors()
	EggCounterUltimateDisplayGrid:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
end

--Save the ultimate display grid coordinates
--This can be called from XML so it is a function and not a method
function EggCounter.OnMoveStop()
	EggCounter.savedVariables.ultimateDisplayGridLeft = EggCounterUltimateDisplayGrid:GetLeft()
	EggCounter.savedVariables.ultimateDisplayGridTop = EggCounterUltimateDisplayGrid:GetTop()
end

--Convert an index intended for a custom grid size to
--an index for the underlying grid
--so that it can be used to index the XML controls
function EggCounter:ConvertIndex(index, height)
	local x = (math.floor((index - 1) / height)) + 1
	local y = ((index - 1) % height) + 1
	local i = y + ((x - 1) * self.maximumUltimateDisplayGridHeight)
	return i
end

--Force the ultimate display grid to match the saved
--variables that determine its current configuration
function EggCounter:FormatUltimateDisplayGrid()
	local textureSize = self.savedVariables.ultimateDisplayGridTextureSize
	local labelSize = self.savedVariables.ultimateDisplayGridLabelSize
	local font = self.savedVariables.ultimateDisplayGridFont
	local gridHeight = self.savedVariables.ultimateDisplayGridHeight
	local gridWidth = self.savedVariables.ultimateDisplayGridWidth
	local height =(textureSize * gridHeight) + ((gridHeight + 1) * 8)
	local width = (textureSize * gridWidth) + (labelSize * gridWidth) + (((gridWidth * 2) + 1) * 8)
	local total = gridHeight * gridWidth
	--Handle visibility and opacity
	if self.savedVariables.ultimateDisplayGridVisibility == "Visible" then
		EggCounterUltimateDisplayGrid:SetHidden(false)
	else
		EggCounterUltimateDisplayGrid:SetHidden(true)
		return
	end
	EggCounterUltimateDisplayGrid:SetAlpha(self.savedVariables.ultimateDisplayGridOpacity / 100)
	--Resize every control
	EggCounterUltimateDisplayGrid:SetDimensions(width, height)
	EggCounterUltimateDisplayGridBackdrop:SetDimensions(width, height)
	for index in pairs(self.ultimateDisplayGridTable) do
		self.ultimateDisplayGridTable[index].texture:SetDimensions(textureSize, textureSize)
		--The second parameter should be textureSize
		self.ultimateDisplayGridTable[index].label:SetDimensions(labelSize, textureSize)
		self.ultimateDisplayGridTable[index].label:SetFont(font)
	end
	--Hide ultimates that are outside of the custom grid dimensions
	for y = self.minimumUltimateDisplayGridHeight, self.maximumUltimateDisplayGridHeight, 1 do
		for x = self.minimumUltimateDisplayGridWidth, self.maximumUltimateDisplayGridWidth, 1 do
			local index = y + ((x - 1) * self.maximumUltimateDisplayGridHeight)
			if (y > gridHeight) or (x > gridWidth) then
				self.ultimateDisplayGridTable[index].texture:SetHidden(true)
				self.ultimateDisplayGridTable[index].label:SetHidden(true)
			end
		end
	end
	--Hide untracked ultimates and set textures for tracked ultimates
	for index = 1, total, 1 do
		local convertedIndex = self:ConvertIndex(index, gridHeight)
		local visible = self.savedVariables.utlimateDisplayGridTrackingTable[index].visible
		local encoding = self.savedVariables.utlimateDisplayGridTrackingTable[index].encoding
		if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") and visible then
			self.ultimateDisplayGridTable[convertedIndex].texture:SetHidden(false)
			self.ultimateDisplayGridTable[convertedIndex].label:SetHidden(false)
			self.ultimateDisplayGridTable[convertedIndex].texture:SetTexture(self.ultimateEncodingTable[encoding].textureFile)
		else
			self.ultimateDisplayGridTable[convertedIndex].texture:SetHidden(true)
			self.ultimateDisplayGridTable[convertedIndex].label:SetHidden(true)
		end
	end
end

--Change the labels in the ultimate display grid so that they
--accurately reflect the content of the ultimate status table
--for the current party
function EggCounter:UpdateUltimateDisplayGridLabels()
	local gridHeight = self.savedVariables.ultimateDisplayGridHeight
	local gridWidth = self.savedVariables.ultimateDisplayGridWidth
	local total = gridHeight * gridWidth
	for index = 1, total, 1 do
		local convertedIndex = self:ConvertIndex(index, gridHeight)
		local visible = self.savedVariables.utlimateDisplayGridTrackingTable[index].visible
		local encoding = self.savedVariables.utlimateDisplayGridTrackingTable[index].encoding
		if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") and visible then
			local count = 0
			for account in pairs(self.ultimateStatusTable) do
				local mainBarUltimateEncoding = self.ultimateStatusTable[account].mainBarUltimateEncoding
				local mainBarUltimateReady = self.ultimateStatusTable[account].mainBarUltimateReady
				local backupBarUltimateEncoding = self.ultimateStatusTable[account].backupBarUltimateEncoding
				local backupBarUltimateReady = self.ultimateStatusTable[account].backupBarUltimateReady
				if ((encoding == mainBarUltimateEncoding) and mainBarUltimateReady) or ((encoding == backupBarUltimateEncoding) and backupBarUltimateReady) then
					count = count + 1
				end
			end
			local text = "" .. count
			self.ultimateDisplayGridTable[convertedIndex].label:SetText(text)
		end
	end
end

--The following series of functions all manipulate saved variables
--and force a reformat of the ultimate display grid when they change
function EggCounter:GetUltimateDisplayGridVisibility()
	return self.savedVariables.ultimateDisplayGridVisibility
end

function EggCounter:SetUltimateDisplayGridVisibility(value)
	self.savedVariables.ultimateDisplayGridVisibility = value
	self:FormatUltimateDisplayGrid()
end

function EggCounter:GetUltimateDisplayGridOpacity()
	return self.savedVariables.ultimateDisplayGridOpacity
end

function EggCounter:SetUltimateDisplayGridOpacity(value)
	self.savedVariables.ultimateDisplayGridOpacity = value
	self:FormatUltimateDisplayGrid()
end

function EggCounter:GetUltimateDisplayGridTextureSize()
	return self.savedVariables.ultimateDisplayGridTextureSize
end

function EggCounter:SetUltimateDisplayGridTextureSize(value)
	self.savedVariables.ultimateDisplayGridTextureSize = value
	self:FormatUltimateDisplayGrid()
end

function EggCounter:GetUltimateDisplayGridLabelSize()
	return self.savedVariables.ultimateDisplayGridLabelSize
end

function EggCounter:SetUltimateDisplayGridLabelSize(value)
	self.savedVariables.ultimateDisplayGridLabelSize = value
	self:FormatUltimateDisplayGrid()
end

function EggCounter:GetUltimateDisplayGridFontSize()
	return self.savedVariables.ultimateDisplayGridFontSize
end

function EggCounter:SetUltimateDisplayGridFontSize(value)
	self.savedVariables.ultimateDisplayGridFontSize = value
	--Smaller values correspond to larger fonts
	--Reverse this to be less confusing to the user
	if value == 1 then
		self.savedVariables.ultimateDisplayGridFont = "ZoFontWinH5"
	elseif value == 2 then
		self.savedVariables.ultimateDisplayGridFont = "ZoFontWinH4"
	elseif value == 3 then
		self.savedVariables.ultimateDisplayGridFont = "ZoFontWinH3"
	elseif value == 4 then
		self.savedVariables.ultimateDisplayGridFont = "ZoFontWinH2"
	else
		self.savedVariables.ultimateDisplayGridFont = "ZoFontWinH1"
	end
	self:FormatUltimateDisplayGrid()
end

function EggCounter:GetUltimateDisplayGridWidth()
	return self.savedVariables.ultimateDisplayGridWidth
end

function EggCounter:SetUltimateDisplayGridWidth(value)
	self.savedVariables.ultimateDisplayGridWidth = value
	self:FormatUltimateDisplayGrid()
end

function EggCounter:GetUltimateDisplayGridHeight()
	return self.savedVariables.ultimateDisplayGridHeight
end

function EggCounter:SetUltimateDisplayGridHeight(value)
	self.savedVariables.ultimateDisplayGridHeight = value
	self:FormatUltimateDisplayGrid()
end

function EggCounter:GetSettingsDropdownMenuValue(menuIndex)
	return self.savedVariables.utlimateDisplayGridTrackingTable[menuIndex].dropdownName
end

function EggCounter:SetSettingsDropdownMenuValue(menuIndex, menuValue)
	self.savedVariables.utlimateDisplayGridTrackingTable[menuIndex].dropdownName = menuValue
	local encoding = self.ultimateDropdownNameTable[menuValue]
	if (type(encoding) == "string") and (type(self.ultimateEncodingTable[encoding]) == "table") then
		self.savedVariables.utlimateDisplayGridTrackingTable[menuIndex].visible = true
		self.savedVariables.utlimateDisplayGridTrackingTable[menuIndex].encoding = encoding
	else
		self.savedVariables.utlimateDisplayGridTrackingTable[menuIndex].visible = false
		self.savedVariables.utlimateDisplayGridTrackingTable[menuIndex].encoding = "0000"
	end
	self:FormatUltimateDisplayGrid()
end

--menuIndex is captured each time this function is called
function EggCounter:GenerateSettingsDropdownMenu(menuIndex, menuName, menuTooltip)
	return {
		type = "dropdown",
		name = menuName,
		tooltip = menuTooltip,
		choices = self.ultimateDropdownMenuTable,
		getFunc = function() return EggCounter:GetSettingsDropdownMenuValue(menuIndex) end,
		setFunc = function(menuValue) EggCounter:SetSettingsDropdownMenuValue(menuIndex, menuValue) end,
		width = "full",
		default = self.default.utlimateDisplayGridTrackingTable[menuIndex].dropdownName,
	}
end

--Generate the settings menu
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
			text = "Adjust the size and shape of the Ultimate Display Grid"
		},
		[3] = {
			type = "dropdown",
			name = "Visibility",
			tooltip = "",
			choices = {"Visible", "Hidden", },
			getFunc = function() return EggCounter:GetUltimateDisplayGridVisibility() end,
			setFunc = function(value) EggCounter:SetUltimateDisplayGridVisibility(value) end,
			width = "full",
			default = self.default.ultimateDisplayGridVisibility,
		},
		[4] = {
			type = "slider",
			name = "Opacity",
			tooltip = "",
			min = 0,
			max = 100,
			step = 1,
			getFunc = function() return EggCounter:GetUltimateDisplayGridOpacity() end,
			setFunc = function(value) EggCounter:SetUltimateDisplayGridOpacity(value) end,
			width = "full",
			default = self.default.ultimateDisplayGridOpacity,
		},
		[5] = {
			type = "slider",
			name = "Texture Size",
			tooltip = "",
			min = 32,
			max = 128,
			step = 1,
			getFunc = function() return EggCounter:GetUltimateDisplayGridTextureSize() end,
			setFunc = function(value) EggCounter:SetUltimateDisplayGridTextureSize(value) end,
			width = "full",
			default = self.default.ultimateDisplayGridTextureSize,
		},
		[6] = {
			type = "slider",
			name = "Label Size",
			tooltip = "",
			min = 24,
			max = 128,
			step = 1,
			getFunc = function() return EggCounter:GetUltimateDisplayGridLabelSize() end,
			setFunc = function(value) EggCounter:SetUltimateDisplayGridLabelSize(value) end,
			width = "full",
			default = self.default.ultimateDisplayGridLabelSize,
		},
		[7] = {
			type = "slider",
			name = "Font Size",
			tooltip = "",
			min = 1,
			max = 5,
			step = 1,
			getFunc = function() return EggCounter:GetUltimateDisplayGridFontSize() end,
			setFunc = function(value) EggCounter:SetUltimateDisplayGridFontSize(value) end,
			width = "full",
			default = self.default.ultimateDisplayGridFontSize,
		},
		[8] = {
			type = "slider",
			name = "Grid Width",
			tooltip = "",
			min = self.minimumUltimateDisplayGridWidth,
			max = self.maximumUltimateDisplayGridWidth,
			step = 1,
			getFunc = function() return EggCounter:GetUltimateDisplayGridWidth() end,
			setFunc = function(value) EggCounter:SetUltimateDisplayGridWidth(value) end,
			width = "full",
			default = self.default.ultimateDisplayGridWidth,
		},
		[9] = {
			type = "slider",
			name = "Grid Height",
			tooltip = "",
			min = self.minimumUltimateDisplayGridHeight,
			max = self.maximumUltimateDisplayGridHeight,
			step = 1,
			getFunc = function() return EggCounter:GetUltimateDisplayGridHeight() end,
			setFunc = function(value) EggCounter:SetUltimateDisplayGridHeight(value) end,
			width = "full",
			default = self.default.ultimateDisplayGridHeight,
		},
		[10] = {
			type = "header",
			name = "Ultimate Tracking Settings",
			
		},
		[11] = {
			type = "description",
			text = "Select which ultimate abilities to track with the Ultimate Display Grid"
		},
		[12] = self:GenerateSettingsDropdownMenu(1, "Ultimate 1", ""),
		[13] = self:GenerateSettingsDropdownMenu(2, "Ultimate 2", ""),
		[14] = self:GenerateSettingsDropdownMenu(3, "Ultimate 3", ""),
		[15] = self:GenerateSettingsDropdownMenu(4, "Ultimate 4", ""),
		[16] = self:GenerateSettingsDropdownMenu(5, "Ultimate 5", ""),
		[17] = self:GenerateSettingsDropdownMenu(6, "Ultimate 6", ""),
		[18] = self:GenerateSettingsDropdownMenu(7, "Ultimate 7", ""),
		[19] = self:GenerateSettingsDropdownMenu(8, "Ultimate 8", ""),
		[20] = self:GenerateSettingsDropdownMenu(9, "Ultimate 9", ""),
		[21] = self:GenerateSettingsDropdownMenu(10, "Ultimate 10", ""),
		[22] = self:GenerateSettingsDropdownMenu(11, "Ultimate 11", ""),
		[23] = self:GenerateSettingsDropdownMenu(12, "Ultimate 12", ""),
		[24] = self:GenerateSettingsDropdownMenu(13, "Ultimate 13", ""),
		[25] = self:GenerateSettingsDropdownMenu(14, "Ultimate 14", ""),
		[26] = self:GenerateSettingsDropdownMenu(15, "Ultimate 15", ""),
		[27] = self:GenerateSettingsDropdownMenu(16, "Ultimate 16", ""),
		[28] = self:GenerateSettingsDropdownMenu(17, "Ultimate 17", ""),
		[29] = self:GenerateSettingsDropdownMenu(18, "Ultimate 18", ""),
		[30] = self:GenerateSettingsDropdownMenu(19, "Ultimate 19", ""),
		[31] = self:GenerateSettingsDropdownMenu(20, "Ultimate 20", ""),
		[32] = self:GenerateSettingsDropdownMenu(21, "Ultimate 21", ""),
		[33] = self:GenerateSettingsDropdownMenu(22, "Ultimate 22", ""),
		[34] = self:GenerateSettingsDropdownMenu(23, "Ultimate 23", ""),
		[35] = self:GenerateSettingsDropdownMenu(24, "Ultimate 24", ""),
		[36] = self:GenerateSettingsDropdownMenu(25, "Ultimate 25", ""),
	}
	
	--The first parameter to LibAddOnMenu2:RegisterAddonPanel and 
	--LibAddOnMenu2:RegisterOptionControls must be the same unique
	--string literal
	--If the parameters are not such a literal then many variables 
	--go out of the global scope, and this breaks any interaction
	--between this source file and the rest of the addon
	--I go to a dark place when I consider the implications of this
	local settingsPanelHandle = LibAddOnMenu2:RegisterAddonPanel("EggCounter_Gnevsyrom", settingsPanelData)
	LibAddOnMenu2:RegisterOptionControls("EggCounter_Gnevsyrom", settingsPanelControlData)
end

--Update the ultimate status table for a particular account
function EggCounter:UpdateUltimateStatus(account, mainBarUltimateEncoding, mainBarUltimateReady, backupBarUltimateEncoding, backupBarUltimateReady)
	if self.ultimateStatusTable[account] == nil then
		self.ultimateStatusTable[account] = {}
	end
	self.ultimateStatusTable[account].mainBarUltimateEncoding = mainBarUltimateEncoding
	self.ultimateStatusTable[account].mainBarUltimateReady = mainBarUltimateReady
	self.ultimateStatusTable[account].backupBarUltimateEncoding = backupBarUltimateEncoding
	self.ultimateStatusTable[account].backupBarUltimateReady = backupBarUltimateReady
end

--Handle events caused by party members leaving by striking their records
--from the ulitmate status table
--This can be called from an event so it is a function and not a method
--EVENT_GROUP_MEMBER_LEFT (integer eventCode,string memberCharacterName, number reason, boolean isLocalPlayer, boolean isLeader, string memberDisplayName, boolean actionRequiredVote)
function EggCounter.OnGroupMemberLeft(eventCode, memberCharacterName, reason, isLocalPlayer, isLeader, memberDisplayName, actionRequiredVote)
	EggCounter.ultimateStatusTable[memberDisplayName] = nil
	EggCounter:UpdateUltimateDisplayGridLabels()
end

--This function handles the Reset binding under controls
--This can be called from XML so it is a function and not a method
function EggCounter.OnResetBinding()
	for account in pairs(EggCounter.ultimateStatusTable) do
		EggCounter.ultimateStatusTable[account] = nil
	end
	EggCounter:UpdateUltimateDisplayGridLabels()
end

--This function handles the debug slash command
--It has some dumb easter eggs
function EggCounter.ToggleDebug()
	local account = GetDisplayName()
	if (account == "@Woosters") or (account == "@SatuElisa") then
		EggCounter.debug = not EggCounter.debug
		if EggCounter.debug then
			d("DEBUG MODE ON")
		else
			d("DEBUG MODE OFF")
		end
	else
		d("YOU ARE UNWORTHY OF MY SECRETS")
	end	
	if account == "@AdenGrey" then
		d("Fancy!")
	elseif account =="@Bustincapps" then
		d("Bustin you are a punk.")
	elseif account == "@Herbatio" then
		d("COCKSMOKER!!!")
	elseif account == "@Nahz" then
		d("Best guild member detected!")
	elseif account =="@Pandoraaa" then
		d("NOVA-BASIC 3.23")
		d("(C) Copyright Novasoft 1983,1984,1985,1986,1987,1988")
		d("60300 Bytes free")
		d("Ok")
	elseif account =="@SatuElisa" then
		d("All hail the empress!")
	end
end

--Generate a segment of a formatted report message for group chat
--Each segment corresponds to one ultimate
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

--This function handles the Report binding under controls
--This can be called from XML so it is a function and not a method
function EggCounter.OnReportBinding()
	local mainBarUltimateMessage = EggCounter:GenerateReportMessage(EggCounter.mainBarUltimateName, EggCounter.mainBarUltimateReady)
	local backupBarUltimateMessage = EggCounter:GenerateReportMessage(EggCounter.backupBarUltimateName, EggCounter.backupBarUltimateReady)
	--This ugly mess is here to avoid confusion with text from players
	local message = "#@$?%" .. mainBarUltimateMessage .. "^" .. backupBarUltimateMessage
	if IsUnitGrouped("player") then
		StartChatInput(message, CHAT_CHANNEL_PARTY, nil)
	elseif EggCounter.debug then
		StartChatInput(message, CHAT_CHANNEL_SAY, nil)
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

--Handle the event caused whenever a new chat message appears
--This can be called from an event so it is a function and not a method
--EVENT_CHAT_MESSAGE_CHANNEL (integer eventCode,number channelType, string fromName, string text, boolean isCustomerService, string fromDisplayName)
function EggCounter.OnChatMessageChannel(eventCode, channelType, fromName, text, isCustomerService, fromDisplayName)
	local messageLength = string.len(text)
	if (((channelType == CHAT_CHANNEL_SAY) and EggCounter.debug) or (channelType == CHAT_CHANNEL_PARTY)) and (not isCustomerService) and (messageLength == 16) then
		if EggCounter:ValidateMessage(text) then
			local mainBarUltimateEncoding = string.sub(text, 6, 9)
			local mainBarUltimateReady = EggCounter:DecodeBoolean(string.byte(text, 10))
			local backupBarUltimateEncoding = string.sub(text, 12, 15)
			local backupBarUltimateReady = EggCounter:DecodeBoolean(string.byte(text, 16))
			EggCounter:UpdateUltimateStatus(fromDisplayName, mainBarUltimateEncoding, mainBarUltimateReady, backupBarUltimateEncoding, backupBarUltimateReady)
			EggCounter:UpdateUltimateDisplayGridLabels()

		end
	end
end

--This is the last line to ensure that all symbols are declared when it excutes
EVENT_MANAGER:RegisterForEvent(EggCounter.name, EVENT_ADD_ON_LOADED, EggCounter.OnAddOnLoaded)
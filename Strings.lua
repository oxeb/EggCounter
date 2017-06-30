local strings = {
	EGGCOUNTER_BINDING_CATEGORY_TITLE = "|c70C0DEEgg Counter|r",
	SI_BINDING_NAME_EGGCOUNTER_DETECT = "Detect Ultimates",
	SI_BINDING_NAME_EGGCOUNTER_REPORT = "Report Ultimates in Chat",
	SI_BINDING_NAME_EGGCOUNTER_RESET = "Reset the Ultimate Display Grid",
	SI_BINDING_NAME_EGGCOUNTER_TOGGLE = "Hide or Show",
}

for key, value in pairs(strings) do
	ZO_CreateStringId(key, value)
	SafeAddVersion(key, 1)
end
local strings = {
	EGGCOUNTER_BINDING_CATEGORY_TITLE = "|c70C0DEEgg Counter|r",
	SI_BINDING_NAME_EGGCOUNTER_DETECT = "Detect |c777777- Detect ultimates|r",
	SI_BINDING_NAME_EGGCOUNTER_REPORT = "Report |c777777- Report ultimates in chat|r",
	SI_BINDING_NAME_EGGCOUNTER_RESET = "Reset |c777777- Reset ultimate list|r",
}

for key, value in pairs(strings) do
	ZO_CreateStringId(key, value)
	SafeAddVersion(key, 1)
end
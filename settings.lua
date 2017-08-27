data:extend(
{
    {
	type = "int-setting",
	name = "production-monitor-update-seconds",
	setting_type = "runtime-global",
	default_value = 30,
	minimum_value = 1,
	maximum_value = 3600,
	order = "a",
   },

   {
	type = "bool-setting",
	name = "production-monitor-large",
	setting_type = "runtime-per-user",
    default_value = false,
	order = "a",
   },
   {
	type = "bool-setting",
	name = "production-monitor-top",
	setting_type = "runtime-per-user",
    default_value = false,
	order = "b",
   },
    {
	type = "int-setting",
	name = "production-monitor-columns",
	setting_type = "runtime-per-user",
	default_value = 1,
	minimum_value = 1,
	maximum_value = 100,
	order = "c",
   },
}
)
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
	order = "a0",
   },
	{
	type = "bool-setting",
	name = "production-monitor-show-production",
	setting_type = "runtime-per-user",
    default_value = true,
	order = "a1",
   },
   	{
	type = "bool-setting",
	name = "production-monitor-show-consumption",
	setting_type = "runtime-per-user",
    default_value = true,
	order = "a2",
   },
	{
	type = "bool-setting",
	name = "production-monitor-show-difference",
	setting_type = "runtime-per-user",
    default_value = true,
	order = "a3",
   },
	{
	type = "bool-setting",
	name = "production-monitor-show-ratio",
	setting_type = "runtime-per-user",
    default_value = true,
	order = "a4",
   },
   	{
	type = "int-setting",
	name = "production-monitor-precision",
	setting_type = "runtime-per-user",
	default_value = 1,
	minimum_value = 0,
	maximum_value = 10,
	order = "b1",
   },
   {
	type = "bool-setting",
	name = "production-monitor-top",
	setting_type = "runtime-per-user",
    default_value = false,
	order = "c1",
   },

    {
	type = "int-setting",
	name = "production-monitor-columns",
	setting_type = "runtime-per-user",
	default_value = 1,
	minimum_value = 1,
	maximum_value = 100,
	order = "c2",
   },
}
)
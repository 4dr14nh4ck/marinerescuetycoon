--!strict
local FishConfig = {
	Tiers = {
		Common = {value = 1, weight = 70},
		Uncommon = {value = 3, weight = 20},
		Rare = {value = 8, weight = 8},
		Epic = {value = 20, weight = 2},
	},
	SpawnInterval = 6, -- seg
	MaxFishInWorld = 60,
}
return FishConfig
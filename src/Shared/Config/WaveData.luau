local WaveData: any = {}

WaveData.Default = {
	Main = { Creeps = { Base = 1 }, Interval = 1 },
}

WaveData[1] = {
	Main = { Creeps = { Base = 3 }, Interval = 1 },
}

WaveData[2] = {
	Main = { Creeps = { Base = 20 }, Interval = 1 },
	Spaceship = { Creeps = { Base = 5, Evolved = 5 }, Interval = 1 },
}

return WaveData

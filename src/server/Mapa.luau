-- Monta o mapa por código: a esteira no meio e 8 bases, 4 de cada lado.
local Workspace = game:GetService("Workspace")

local Mapa = {}

Mapa.TAMANHO_BASE = 36
Mapa.ESTEIRA_INICIO = Vector3.new(-100, 1, 0)
Mapa.ESTEIRA_FIM = Vector3.new(100, 1, 0)

local function parte(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for chave, valor in props do
		(p :: any)[chave] = valor
	end
	return p
end

export type InfoBase = {
	piso: Part,
	centro: Vector3,
	lado: number, -- -1 ou 1: de que lado da esteira a base está
	pasta: Folder,
}

function Mapa.construir(): { InfoBase }
	local pasta = Instance.new("Folder")
	pasta.Name = "Mapa"

	parte({
		Name = "Esteira",
		Size = Vector3.new(200, 1, 10),
		Position = Vector3.new(0, 0.5, 0),
		Color = Color3.fromRGB(40, 40, 50),
		Material = Enum.Material.DiamondPlate,
		Parent = pasta,
	})

	local bases = {}
	for i = 1, 8 do
		local lado = if i <= 4 then -1 else 1
		local x = -67.5 + ((i - 1) % 4) * 45
		local centro = Vector3.new(x, 0.5, lado * 45)

		local pastaBase = Instance.new("Folder")
		pastaBase.Name = `Base{i}`
		pastaBase.Parent = pasta

		local piso = parte({
			Name = "Piso",
			Size = Vector3.new(Mapa.TAMANHO_BASE, 1, Mapa.TAMANHO_BASE),
			Position = centro,
			Color = Color3.fromHSV((i - 1) / 8, 0.45, 0.85),
			Material = Enum.Material.SmoothPlastic,
			Parent = pastaBase,
		})

		table.insert(bases, { piso = piso, centro = centro, lado = lado, pasta = pastaBase })
	end

	pasta.Parent = Workspace
	return bases
end

return Mapa

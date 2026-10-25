-- Monta o mapa por código: 8 bases perto do começo e uma estrada
-- que leva aos biomas, um depois do outro.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Mapa = {}

Mapa.TAMANHO_BASE = 36
Mapa.TAMANHO_BIOMA = 100
Mapa.INICIO_BIOMAS = 130 -- x onde começa o primeiro bioma
Mapa.ESPACO_BIOMAS = 50 -- estrada entre um bioma e o próximo

local function parte(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local parent = props.Parent
	props.Parent = nil
	for chave, valor in props do
		(p :: any)[chave] = valor
	end
	p.Parent = parent
	return p
end

function Mapa.placa(parent: BasePart, texto: string, altura: number, largura: number?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(largura or 260, 80)
	gui.StudsOffsetWorldSpace = Vector3.new(0, altura, 0)
	gui.MaxDistance = 200
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = texto
	label.Parent = gui
	return label
end

export type InfoBase = {
	piso: Part,
	centro: Vector3, -- topo do piso
	lado: number, -- -1 ou 1: de que lado da estrada a base está
	pasta: Folder,
}

export type InfoBioma = {
	config: any,
	centro: Vector3, -- topo do piso
	entrada: Vector3, -- ponto na estrada logo antes do bioma
	pasta: Folder,
}

function Mapa.construir(): ({ InfoBase }, { InfoBioma })
	local pasta = Instance.new("Folder")
	pasta.Name = "Mapa"

	local fimEstrada = Mapa.INICIO_BIOMAS + #Config.BIOMAS * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
	parte({
		Name = "Estrada",
		Size = Vector3.new(fimEstrada + 100, 1, 14),
		Position = Vector3.new((fimEstrada - 100) / 2, 0.5, 0),
		Color = Color3.fromRGB(60, 60, 70),
		Material = Enum.Material.Asphalt,
		Parent = pasta,
	})

	local bases = {}
	for i = 1, 8 do
		local lado = if i <= 4 then -1 else 1
		local x = -67.5 + ((i - 1) % 4) * 45
		local pastaBase = Instance.new("Folder")
		pastaBase.Name = `Base{i}`
		pastaBase.Parent = pasta

		local piso = parte({
			Name = "Piso",
			Size = Vector3.new(Mapa.TAMANHO_BASE, 1, Mapa.TAMANHO_BASE),
			Position = Vector3.new(x, 0.5, lado * 45),
			Color = Color3.fromHSV((i - 1) / 8, 0.45, 0.85),
			Material = Enum.Material.SmoothPlastic,
			Parent = pastaBase,
		})
		table.insert(bases, { piso = piso, centro = Vector3.new(x, 1, lado * 45), lado = lado, pasta = pastaBase })
	end

	local biomas = {}
	for i, config in Config.BIOMAS do
		local inicio = Mapa.INICIO_BIOMAS + (i - 1) * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
		local centro = Vector3.new(inicio + Mapa.TAMANHO_BIOMA / 2, 1, 0)
		local pastaBioma = Instance.new("Folder")
		pastaBioma.Name = config.nome
		pastaBioma.Parent = pasta

		parte({
			Name = "Piso",
			-- um pouquinho acima da estrada para não piscar onde as duas se encontram
			Size = Vector3.new(Mapa.TAMANHO_BIOMA, 1.3, Mapa.TAMANHO_BIOMA),
			Position = centro - Vector3.new(0, 0.6, 0),
			Color = config.cor,
			Material = Enum.Material.Grass,
			Parent = pastaBioma,
		})

		-- Portal na entrada com o nome e a velocidade necessária
		local portal = parte({
			Name = "Portal",
			Size = Vector3.new(1, 16, 20),
			Position = Vector3.new(inicio, 9, 0),
			Color = config.cor,
			Material = Enum.Material.ForceField,
			Transparency = 0.5,
			CanCollide = false,
			CanQuery = false,
			Parent = pastaBioma,
		})
		local texto = config.nome
		if config.velocidadeMinima > 0 then
			texto ..= `\nPrecisa de {Config.formatar(config.velocidadeMinima)} de Velocidade`
		end
		Mapa.placa(portal, texto, 10, 320)

		table.insert(biomas, {
			config = config,
			centro = centro,
			entrada = Vector3.new(inicio - 8, 4, 0),
			pasta = pastaBioma,
		})
	end

	pasta.Parent = Workspace
	return bases, biomas
end

function Mapa.dentroQuadrado(centro: Vector3, tamanho: number, posicao: Vector3): boolean
	local meio = tamanho / 2
	return math.abs(posicao.X - centro.X) <= meio and math.abs(posicao.Z - centro.Z) <= meio
end

return Mapa

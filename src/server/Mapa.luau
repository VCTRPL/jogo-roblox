-- Monta o mapa por código: 6 bases grandes perto do começo (3 de cada lado)
-- e uma estrada que leva aos biomas, um depois do outro.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Mapa = {}

Mapa.TAMANHO_BASE = 72
-- Bases bem separadas (de lado e da estrada) para roubar dar trabalho mesmo
-- com muita Velocidade.
Mapa.ESPACO_BASES = 190 -- de um centro de base ao próximo (no eixo X)
Mapa.Z_BASES = 110 -- distância do centro das bases até o meio da estrada
Mapa.INICIO_ESTRADA = -313
Mapa.TUNEL_BOCA = -290 -- a estrada sai de um túnel na montanha
Mapa.TUNEL_LARGURA = 22 -- por dentro
Mapa.TUNEL_ALTURA = 20
Mapa.TAMANHO_BIOMA = 100
Mapa.INICIO_BIOMAS = 330 -- x onde começa o primeiro bioma
Mapa.ESPACO_BIOMAS = 70 -- transição entre um bioma e o próximo
Mapa.FIM_BASES = Mapa.INICIO_BIOMAS - 18 -- daqui para trás é a área das bases (os chefes param aqui)
Mapa.Z_PAREDE = Mapa.TAMANHO_BIOMA / 2 + 2 -- paredes dos lados dos biomas
Mapa.FIM_ESTRADA = Mapa.INICIO_BIOMAS + #Config.BIOMAS * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)

-- Onde começa (x) o bioma de número "i".
function Mapa.inicioBioma(i: number): number
	return Mapa.INICIO_BIOMAS + (i - 1) * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
end

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
Mapa.parte = parte

-- Placa flutuante. O tamanho é em studs (não em pixels), então as placas
-- longe ficam pequenas e não enchem a tela. "largura" segue a escala antiga:
-- 260 dá uma placa de 10 studs.
function Mapa.placa(parent: BasePart, texto: string, altura: number, largura: number?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale((largura or 260) / 26, 3.5)
	gui.StudsOffsetWorldSpace = Vector3.new(0, altura, 0)
	gui.MaxDistance = 120
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

	-- Estrada de asfalto só até a entrada do primeiro bioma. Entre um bioma e
	-- o próximo o chão é a transição de um para o outro (Decoracao).
	local fimEstrada = Mapa.FIM_ESTRADA
	local inicioEstrada = Mapa.INICIO_ESTRADA
	local primeiroBioma = Mapa.inicioBioma(1)
	parte({
		Name = "Estrada",
		Size = Vector3.new(primeiroBioma - inicioEstrada, 1, 14),
		Position = Vector3.new((primeiroBioma + inicioEstrada) / 2, 0.5, 0),
		Color = Color3.fromRGB(60, 60, 70),
		Material = Enum.Material.Asphalt,
		Parent = pasta,
	})

	local bases = {}
	for i = 1, 6 do
		local lado = if i <= 3 then -1 else 1
		local x = ((i - 1) % 3 - 1) * Mapa.ESPACO_BASES
		local pastaBase = Instance.new("Folder")
		pastaBase.Name = `Base{i}`
		pastaBase.Parent = pasta

		local piso = parte({
			Name = "Piso",
			Size = Vector3.new(Mapa.TAMANHO_BASE, 1, Mapa.TAMANHO_BASE),
			Position = Vector3.new(x, 0.5, lado * Mapa.Z_BASES),
			-- grama, igual ao resto do mapa
			Color = Color3.fromRGB(125, 195, 90),
			Material = Enum.Material.Grass,
			Parent = pastaBase,
		})
		-- cor de cada base, usada nas lanternas dos cantos (Decoracao)
		piso:SetAttribute("CorBase", Color3.fromHSV((i - 1) / 6, 0.4, 0.85))
		table.insert(bases, { piso = piso, centro = Vector3.new(x, 1, lado * Mapa.Z_BASES), lado = lado, pasta = pastaBase })
	end
	-- caminho de pedra da estrada até a entrada de cada base
	for _, base in bases do
		local de = 7.4
		local ate = Mapa.Z_BASES - Mapa.TAMANHO_BASE / 2
		parte({
			Name = "Caminho",
			Size = Vector3.new(12, 1, ate - de + 1),
			Position = Vector3.new(base.centro.X, 0.45, base.lado * (de + ate) / 2),
			Color = Color3.fromRGB(165, 160, 150),
			Material = Enum.Material.SmoothPlastic,
			Parent = pasta,
		})
	end

	local biomas = {}
	for i, config in Config.BIOMAS do
		local inicio = Mapa.inicioBioma(i)
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
		-- o nome e a Velocidade necessária ficam na placa do arco (Decoracao)
		portal:SetAttribute("Bioma", config.nome)

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

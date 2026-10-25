-- Monta o mapa por código: 6 bases grandes perto do começo (3 de cada lado)
-- e uma estrada que leva aos biomas, um depois do outro. Na estrada tem
-- duas esteiras rolantes: a da direita leva aos biomas, a da esquerda volta.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Mapa = {}

Mapa.TAMANHO_BASE = 54
Mapa.INICIO_ESTRADA = -130
Mapa.TUNEL_BOCA = -110 -- a estrada sai de um túnel na montanha
Mapa.TUNEL_LARGURA = 20 -- por dentro
Mapa.TUNEL_ALTURA = 18
Mapa.VELOCIDADE_ROLANTE = 22
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

	local fimEstrada = Mapa.INICIO_BIOMAS + #Config.BIOMAS * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
	local inicioEstrada = Mapa.INICIO_ESTRADA
	parte({
		Name = "Estrada",
		Size = Vector3.new(fimEstrada - inicioEstrada, 1, 14),
		Position = Vector3.new((fimEstrada + inicioEstrada) / 2, 0.5, 0),
		Color = Color3.fromRGB(60, 60, 70),
		Material = Enum.Material.Asphalt,
		Parent = pasta,
	})

	local bases = {}
	for i = 1, 6 do
		local lado = if i <= 3 then -1 else 1
		local x = -70 + ((i - 1) % 3) * 70
		local pastaBase = Instance.new("Folder")
		pastaBase.Name = `Base{i}`
		pastaBase.Parent = pasta

		local piso = parte({
			Name = "Piso",
			Size = Vector3.new(Mapa.TAMANHO_BASE, 1, Mapa.TAMANHO_BASE),
			Position = Vector3.new(x, 0.5, lado * 52),
			Color = Color3.fromHSV((i - 1) / 6, 0.45, 0.85),
			Material = Enum.Material.SmoothPlastic,
			Parent = pastaBase,
		})
		table.insert(bases, { piso = piso, centro = Vector3.new(x, 1, lado * 52), lado = lado, pasta = pastaBase })
	end

	-- Esteiras rolantes nos trechos de estrada à mostra (dentro dos biomas o
	-- piso cobre a estrada). Olhando para os biomas (+X), a direita é +Z.
	local trechos = {}
	local comeco = inicioEstrada
	for i = 1, #Config.BIOMAS do
		local entrada = Mapa.INICIO_BIOMAS + (i - 1) * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
		table.insert(trechos, { comeco, entrada })
		comeco = entrada + Mapa.TAMANHO_BIOMA
	end
	table.insert(trechos, { comeco, fimEstrada })
	for _, trecho in trechos do
		local a, b = trecho[1] + 1, trecho[2] - 1
		for _, faixa in { { z = 3.4, sentido = 1, cor = Color3.fromRGB(70, 200, 90) }, { z = -3.4, sentido = -1, cor = Color3.fromRGB(70, 140, 230) } } do
			local rolante = parte({
				Name = if faixa.sentido == 1 then "RolanteIda" else "RolanteVolta",
				Size = Vector3.new(b - a, 0.2, 6),
				Position = Vector3.new((a + b) / 2, 1.1, faixa.z),
				Color = faixa.cor:Lerp(Color3.new(0, 0, 0), 0.45),
				Material = Enum.Material.SmoothPlastic,
				Parent = pasta,
			})
			rolante.AssemblyLinearVelocity = Vector3.new(faixa.sentido * Mapa.VELOCIDADE_ROLANTE, 0, 0)
			-- setas de neon que o cliente faz andar no sentido da esteira
			local direcao = Vector3.new(faixa.sentido, 0, 0)
			for x = a + 2, b - 4, 6 do
				local posicao = Vector3.new(x, 1.22, faixa.z)
				local seta = parte({
					Name = "Seta",
					Size = Vector3.new(4.5, 0.05, 0.7),
					CFrame = CFrame.lookAt(posicao, posicao - direcao),
					Color = faixa.cor,
					Material = Enum.Material.Neon,
					CanCollide = false,
					CanQuery = false,
					CanTouch = false,
					CastShadow = false,
					Parent = pasta,
				})
				seta:SetAttribute("Fase", 0)
				seta:SetAttribute("Curso", 6)
				seta:SetAttribute("Velocidade", Mapa.VELOCIDADE_ROLANTE)
				CollectionService:AddTag(seta, "FaixaEsteira")
			end
		end
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
		-- o nome já aparece na faixa do arco; a placa só avisa a Velocidade necessária
		if config.velocidadeMinima > 0 then
			Mapa.placa(portal, `Precisa de {Config.formatar(config.velocidadeMinima)} de Velocidade`, 4, 320)
		end

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

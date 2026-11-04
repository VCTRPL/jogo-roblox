-- Decoração do mapa: céu e iluminação, chão de grama, árvores, o lago,
-- cercas das bases, postes da estrada, o túnel da entrada e os portais
-- dos biomas. Só enfeite: nada aqui muda
-- as regras do jogo. O sorteio usa sempre a mesma semente, então o
-- mapa fica igual toda vez.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Biomas = require(script.Parent.Biomas)
local Blocos = require(script.Parent.Blocos)
local Cidade = require(script.Parent.Cidade)
local Cenario = require(script.Parent.Cenario)
local Mapa = require(script.Parent.Mapa)
local Montanhas = require(script.Parent.Montanhas)
local Paredes = require(script.Parent.Paredes)

local Decoracao = {}

local parte = Mapa.parte
local aleatorio = Random.new(2026)

local FOLHAS = {
	Color3.fromRGB(75, 170, 60),
	Color3.fromRGB(95, 190, 70),
	Color3.fromRGB(60, 145, 65),
	Color3.fromRGB(130, 200, 70),
}
local FOLHAS_LAGO = {
	Color3.fromRGB(60, 175, 110),
	Color3.fromRGB(80, 190, 90),
	Color3.fromRGB(45, 150, 100),
}
local FLORES = {
	Color3.fromRGB(255, 90, 120),
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(170, 110, 255),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 150, 60),
}

local function escurecer(cor: Color3, quanto: number): Color3
	return cor:Lerp(Color3.new(0, 0, 0), quanto)
end

local function escolher<T>(lista: { T }): T
	return lista[aleatorio:NextInteger(1, #lista)]
end

local function iluminar()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.8
	Lighting.Ambient = Color3.fromRGB(110, 110, 125)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 165)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.GlobalShadows = true

	local function efeito(classe: string, props): Instance
		local objeto = Lighting:FindFirstChildOfClass(classe) or Instance.new(classe)
		for chave, valor in props do
			(objeto :: any)[chave] = valor
		end
		objeto.Parent = Lighting
		return objeto
	end
	efeito("Sky", {})
	efeito("Atmosphere", {
		Density = 0.28,
		Offset = 0.2,
		Color = Color3.fromRGB(200, 220, 255),
		Decay = Color3.fromRGB(120, 150, 200),
		Glare = 0.2,
		Haze = 1,
	})
	-- cores fortes de desenho e neon brilhando bastante
	efeito("BloomEffect", { Intensity = 0.5, Size = 24, Threshold = 1.45 })
	efeito("ColorCorrectionEffect", { Saturation = 0.3, Contrast = 0.1, Brightness = 0.03 })
	efeito("SunRaysEffect", { Intensity = 0.04, Spread = 0.7 })

	local nuvens = Workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	nuvens.Cover = 0.55
	nuvens.Density = 0.6
	nuvens.Parent = Workspace.Terrain
end

local function texto(parent: BasePart, face: Enum.NormalId, conteudo: string, cor: Color3, fonte: Enum.Font?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.8)
	label.Position = UDim2.fromScale(0.05, 0.1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = fonte or Enum.Font.FredokaOne
	label.TextColor3 = cor
	label.Text = conteudo
	local contorno = Instance.new("UIStroke")
	contorno.Thickness = 4
	contorno.Color = Color3.fromRGB(40, 30, 60)
	contorno.Parent = label
	label.Parent = gui
end

-- Túnel de trem no começo da estrada, de concreto, entrando na montanha
-- (veja Montanhas.luau): as duas esteiras rolantes saem dele. Por dentro
-- tem arcos de concreto, luzes no teto, faixas de LED pulsando nas paredes
-- e ventiladores girando; na boca, faixas de alerta, luzes vermelhas
-- piscando e fumaça saindo.
local TUNEL_FUNDO = Mapa.INICIO_ESTRADA - 1
local TUNEL_BOCA = Mapa.TUNEL_BOCA
local CONCRETO = Color3.fromRGB(150, 150, 155)
local CONCRETO_ESCURO = Color3.fromRGB(105, 105, 112)
local AMARELO = Color3.fromRGB(255, 200, 40)
local PRETO = Color3.fromRGB(30, 30, 34)
local function tunel(pasta: Instance)
	local comprimento = TUNEL_BOCA - TUNEL_FUNDO
	local meio = (TUNEL_BOCA + TUNEL_FUNDO) / 2
	local meia = Mapa.TUNEL_LARGURA / 2
	local altura = Mapa.TUNEL_ALTURA

	local function enfeite(props): Part
		props.CanCollide = false
		props.CanQuery = false
		props.CanTouch = false
		props.CastShadow = false
		props.Parent = pasta
		return parte(props)
	end

	-- paredes, teto e fundo escuro
	for _, lado in { -1, 1 } do
		parte({
			Name = "ParedeTunel",
			Size = Vector3.new(comprimento, altura, 2.5),
			Position = Vector3.new(meio, altura / 2, lado * (meia + 1.25)),
			Color = CONCRETO_ESCURO,
			Material = Enum.Material.Concrete,
			Parent = pasta,
		})
		-- cantos de cima chanfrados, para a boca ficar arredondada
		parte({
			Name = "CantoTunel",
			Size = Vector3.new(comprimento, 3, 3),
			Position = Vector3.new(meio, altura - 1.5, lado * (meia - 1.5)),
			Color = CONCRETO_ESCURO,
			Material = Enum.Material.Concrete,
			Parent = pasta,
		})
		-- faixa de LED pulsando ao longo da parede
		local led = enfeite({
			Name = "LedTunel",
			Size = Vector3.new(comprimento - 1, 0.35, 0.2),
			Position = Vector3.new(meio, 3, lado * (meia - 0.1)),
			Color = Color3.fromRGB(60, 220, 255),
			Material = Enum.Material.Neon,
		})
		CollectionService:AddTag(led, "PulsarEsteira")
	end
	parte({
		Name = "TetoTunel",
		Size = Vector3.new(comprimento, 4, Mapa.TUNEL_LARGURA + 5),
		Position = Vector3.new(meio, altura + 2, 0),
		Color = CONCRETO_ESCURO,
		Material = Enum.Material.Concrete,
		Parent = pasta,
	})
	parte({
		Name = "FundoTunel",
		Size = Vector3.new(1, altura, Mapa.TUNEL_LARGURA),
		Position = Vector3.new(TUNEL_FUNDO + 0.5, altura / 2, 0),
		Color = Color3.fromRGB(14, 12, 18),
		Material = Enum.Material.SmoothPlastic,
		Parent = pasta,
	})

	-- arcos de concreto por dentro, com uma luz no teto entre eles
	for x = TUNEL_FUNDO + 3, TUNEL_BOCA - 2, 6 do
		for _, lado in { -1, 1 } do
			parte({
				Name = "ArcoTunel",
				Size = Vector3.new(1.2, altura, 1),
				Position = Vector3.new(x, altura / 2, lado * (meia - 0.5)),
				Color = CONCRETO,
				Material = Enum.Material.Concrete,
				Parent = pasta,
			})
		end
		parte({
			Name = "ArcoTunel",
			Size = Vector3.new(1.2, 1, Mapa.TUNEL_LARGURA),
			Position = Vector3.new(x, altura - 0.5, 0),
			Color = CONCRETO,
			Material = Enum.Material.Concrete,
			Parent = pasta,
		})
		if x + 3 < TUNEL_BOCA then
			local lampada = enfeite({
				Name = "LuzTunel",
				Size = Vector3.new(1, 0.3, 5),
				Position = Vector3.new(x + 3, altura - 0.15, 0),
				Color = Color3.fromRGB(255, 210, 130),
				Material = Enum.Material.Neon,
			})
			local luz = Instance.new("PointLight")
			luz.Color = Color3.fromRGB(255, 210, 150)
			luz.Range = 18
			luz.Brightness = 1.2
			luz.Parent = lampada
		end
	end

	-- ventiladores no teto, girando
	for _, x in { TUNEL_BOCA - 4 } do
		local centro = Vector3.new(x, altura - 1.6, 0)
		enfeite({
			Name = "EixoVentilador",
			Size = Vector3.new(0.6, 1.2, 0.6),
			Position = centro + Vector3.new(0, 0.6, 0),
			Color = PRETO,
			Material = Enum.Material.Metal,
		})
		for _, giro in { 0, 90 } do
			local pa = enfeite({
				Name = "PaVentilador",
				Size = Vector3.new(6, 0.2, 0.9),
				CFrame = CFrame.new(centro) * CFrame.Angles(0, math.rad(giro), 0),
				Color = Color3.fromRGB(70, 70, 78),
				Material = Enum.Material.Metal,
			})
			pa:SetAttribute("Centro", centro)
			pa:SetAttribute("Giro", 220)
			CollectionService:AddTag(pa, "GirarEsteira")
		end
	end

	-- camadas pretas no fundo, cada vez mais escuras: as primeiras dá para
	-- atravessar (só sombra), as 3 últimas são blocos sólidos que fecham o
	-- túnel
	local CAMADAS = 7
	local SOLIDAS = 3
	local inicioCamadas = TUNEL_BOCA - 8
	for i = 1, CAMADAS do
		local solida = i > CAMADAS - SOLIDAS
		local x = inicioCamadas - (i - 1) * 2
		local grossura = if solida then 2 else 0.4
		if i == CAMADAS then
			-- o último vai até o fundo, bem grosso para ninguém passar correndo
			grossura = x + 1 - TUNEL_FUNDO
			x = (x + 1 + TUNEL_FUNDO) / 2
		end
		parte({
			Name = if solida then "FimTunel" else "SombraTunel",
			Size = Vector3.new(grossura, altura, Mapa.TUNEL_LARGURA),
			Position = Vector3.new(x, altura / 2, 0),
			Color = Color3.new(0, 0, 0),
			Material = Enum.Material.SmoothPlastic,
			Transparency = if solida then 0 else 0.8 - (i - 1) * 0.15,
			CanCollide = solida,
			CanQuery = false,
			CanTouch = false,
			CastShadow = false,
			Parent = pasta,
		})
	end

	-- frente de concreto em volta da boca, encostada na montanha
	local largura = meia + 12 -- até onde a frente vai para cada lado
	local topo = altura + 8
	local x = TUNEL_BOCA + 1
	for _, lado in { -1, 1 } do
		parte({
			Name = "FrenteTunel",
			Size = Vector3.new(2, topo, largura - meia),
			Position = Vector3.new(x, topo / 2, lado * (meia + largura) / 2),
			Color = CONCRETO,
			Material = Enum.Material.Concrete,
			Parent = pasta,
		})
		-- contraforte inclinado em degraus dos dois lados
		for i = 1, 3 do
			local h = topo - i * 6
			parte({
				Name = "FrenteTunel",
				Size = Vector3.new(2 + i, h, 3),
				Position = Vector3.new(x - 1 + (2 + i) / 2, h / 2, lado * (largura + (i - 0.5) * 3)),
				Color = CONCRETO,
				Material = Enum.Material.Concrete,
				Parent = pasta,
			})
		end
		-- faixas de alerta amarelas e pretas dos lados da abertura
		for i = 0, math.floor((altura - 2) / 1.5) - 1 do
			enfeite({
				Name = "AlertaTunel",
				Size = Vector3.new(0.3, 1.5, 1.2),
				Position = Vector3.new(x + 1.15, 0.75 + i * 1.5, lado * (meia + 1.6)),
				Color = if i % 2 == 0 then AMARELO else PRETO,
				Material = Enum.Material.SmoothPlastic,
			})
		end
		-- luz vermelha piscando no alto, de cada lado
		local alarme = enfeite({
			Name = "AlarmeTunel",
			Size = Vector3.new(1.4, 1.4, 1.4),
			Position = Vector3.new(x + 1.5, altura + 2, lado * (meia + 3.5)),
			Color = Color3.fromRGB(255, 40, 40),
			Material = Enum.Material.Neon,
		})
		CollectionService:AddTag(alarme, "PulsarEsteira")
		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(255, 60, 50)
		luz.Range = 14
		luz.Brightness = 1.5
		luz.Parent = alarme
	end
	parte({
		Name = "FrenteTunel",
		Size = Vector3.new(2, topo - altura, Mapa.TUNEL_LARGURA),
		Position = Vector3.new(x, (topo + altura) / 2, 0),
		Color = CONCRETO,
		Material = Enum.Material.Concrete,
		Parent = pasta,
	})
	-- moldura saltada em volta da abertura e as pedras do arco
	local borda = x + 1.4
	parte({
		Name = "MolduraTunel",
		Size = Vector3.new(0.8, 1.5, Mapa.TUNEL_LARGURA + 3),
		Position = Vector3.new(borda, altura + 0.75, 0),
		Color = CONCRETO_ESCURO,
		Material = Enum.Material.Concrete,
		Parent = pasta,
	})
	for _, lado in { -1, 1 } do
		parte({
			Name = "MolduraTunel",
			Size = Vector3.new(0.8, 3, 3),
			Position = Vector3.new(borda, altura - 1.5, lado * (meia - 1)),
			Color = CONCRETO_ESCURO,
			Material = Enum.Material.Concrete,
			Parent = pasta,
		})
	end
	for i = -3, 3 do
		parte({
			Name = "PedraArco",
			Size = Vector3.new(1.2, 2.5 - math.abs(i) * 0.25, 2.4),
			Position = Vector3.new(borda + 0.2, altura + 2.75 - math.abs(i) * 0.12, i * 2.7),
			Color = if i == 0 then CONCRETO_ESCURO else CONCRETO:Lerp(CONCRETO_ESCURO, 0.4),
			Material = Enum.Material.Concrete,
			Parent = pasta,
		})
	end
	-- cornija no alto da frente
	parte({
		Name = "CornijaTunel",
		Size = Vector3.new(3, 1.2, largura * 2 + 2),
		Position = Vector3.new(x + 0.5, topo + 0.6, 0),
		Color = CONCRETO_ESCURO,
		Material = Enum.Material.Concrete,
		Parent = pasta,
	})

	-- tijolos de pedra por cima da frente de concreto (dos lados e em cima da boca)
	local TIJOLOS = { CONCRETO, CONCRETO_ESCURO, Color3.fromRGB(160, 150, 140), Color3.fromRGB(135, 128, 120) }
	local function parede(zMin: number, zMax: number, yMin: number, yMax: number)
		local linha = 0
		for y = yMin, yMax - 1.9, 2 do
			local z = zMin - (linha % 2) * 2
			while z < zMax do
				local de, ate = math.max(z, zMin), math.min(z + 4, zMax)
				if ate - de > 0.5 then
					enfeite({
						Name = "Tijolo",
						Size = Vector3.new(0.6, 1.9, ate - de - 0.1),
						Position = Vector3.new(x + 1.3 + aleatorio:NextNumber(0, 0.25), y + 0.95, (de + ate) / 2),
						Color = escolher(TIJOLOS),
						Material = Enum.Material.Slate,
					})
				end
				z += 4
			end
			linha += 1
		end
	end
	for _, lado in { -1, 1 } do
		local perto, longe = meia + 2.9, largura
		if lado == 1 then
			parede(perto, longe, 0, topo)
		else
			parede(-longe, -perto, 0, topo)
		end
	end
	parede(-meia - 2.9, meia + 2.9, altura + 4.2, topo)

	-- placa com o nome do jogo em cima da boca
	local placaJogo = parte({
		Name = "PlacaJogo",
		Size = Vector3.new(1.2, 8, 36),
		Position = Vector3.new(x + 2.4, topo + 5.4, 0),
		Color = Color3.fromRGB(150, 100, 60),
		Material = Enum.Material.WoodPlanks,
		Parent = pasta,
	})
	parte({
		Name = "MolduraPlacaJogo",
		Size = Vector3.new(1, 9, 37.4),
		Position = Vector3.new(x + 2.1, topo + 5.4, 0),
		Color = AMARELO,
		Parent = pasta,
	})
	texto(placaJogo, Enum.NormalId.Right, "ROUBE UM OVO\nBRAINROT", Color3.fromRGB(255, 240, 120), Enum.Font.LuckiestGuy)

	-- tochas dos dois lados da boca
	for _, lado in { -1, 1 } do
		local suporte = enfeite({
			Name = "Tocha",
			Size = Vector3.new(1, 1.6, 1),
			Position = Vector3.new(x + 2.2, 9, lado * (meia + 5.5)),
			Color = Color3.fromRGB(70, 50, 35),
			Material = Enum.Material.Wood,
		})
		local fogo = Instance.new("Fire")
		fogo.Size = 3
		fogo.Heat = 6
		fogo.Parent = suporte
		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(255, 160, 80)
		luz.Range = 16
		luz.Brightness = 1.5
		luz.Parent = suporte
	end

	-- trepadeiras caindo da cornija
	for _ = 1, 12 do
		local comprimento = aleatorio:NextNumber(2, 7)
		local z = aleatorio:NextNumber(-largura, largura)
		if math.abs(z) > meia + 1 or comprimento < 5 then
			enfeite({
				Name = "Trepadeira",
				Size = Vector3.new(0.3, comprimento, 0.9),
				Position = Vector3.new(x + 1.9, topo - comprimento / 2, z),
				Color = escolher(FOLHAS),
			})
		end
	end

	-- fumaça saindo devagar da boca
	local saida = enfeite({
		Name = "FumacaTunel",
		Size = Vector3.new(1, altura - 4, Mapa.TUNEL_LARGURA - 4),
		Position = Vector3.new(TUNEL_BOCA - 3, altura / 2, 0),
		Transparency = 1,
	})
	local fumaca = Instance.new("ParticleEmitter")
	fumaca.Texture = "rbxasset://textures/particles/smoke_main.dds"
	fumaca.Color = ColorSequence.new(Color3.fromRGB(200, 200, 210))
	fumaca.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.75),
		NumberSequenceKeypoint.new(1, 1),
	})
	fumaca.Size = NumberSequence.new(4, 9)
	fumaca.EmissionDirection = Enum.NormalId.Right
	fumaca.Speed = NumberRange.new(2, 4)
	fumaca.SpreadAngle = Vector2.new(20, 20)
	fumaca.Lifetime = NumberRange.new(4, 6)
	fumaca.Rate = 4
	fumaca.RotSpeed = NumberRange.new(-20, 20)
	fumaca.Acceleration = Vector3.new(0, 0.6, 0)
	fumaca.Parent = saida
end

-- (criado mais abaixo, junto com a decoração do deserto)
local cacto: (pasta: Instance, chao: Vector3, escala: number) -> ()

-- Portal de cada bioma: um arco com a cara do bioma (troncos na Selva,
-- bambu na Praia, arenito no Deserto, basalto com lava no Vulcão e metal
-- com neon no Espaço), uma placa com o nome e a Velocidade necessária,
-- brilhos na passagem.
type TemaArco = {
	pilar: Color3,
	material: Enum.Material,
	faixa: Color3, -- listras dos pilares
	faixaNeon: boolean,
	placa: Color3,
	borda: Color3,
	bordaNeon: boolean,
	texto: Color3,
	enfeite: ((pasta: Instance, topoPilar: Vector3) -> ())?,
}

local TEMAS_ARCO: { [string]: TemaArco } = {
	floresta = {
		pilar = Color3.fromRGB(115, 78, 46),
		material = Enum.Material.Wood,
		faixa = Color3.fromRGB(80, 150, 60),
		faixaNeon = false,
		placa = Color3.fromRGB(150, 102, 60),
		borda = Color3.fromRGB(90, 60, 35),
		bordaNeon = false,
		texto = Color3.fromRGB(255, 245, 210),
		enfeite = function(pasta, topoPilar)
			-- copa de folhas em cima do tronco
			for i = 0, 2 do
				parte({
					Name = "Folhas",
					Size = Vector3.new(6 - i * 1.5, 2.2, 6 - i * 1.5),
					CFrame = CFrame.new(topoPilar + Vector3.new(0, 1.1 + i * 2, 0)) * CFrame.Angles(0, i * 0.5, 0),
					Color = FOLHAS[i + 1],
					CanCollide = false,
					Parent = pasta,
				})
			end
		end,
	},
	praia = {
		pilar = Color3.fromRGB(225, 200, 130),
		material = Enum.Material.Wood,
		faixa = Color3.fromRGB(120, 160, 80),
		faixaNeon = false,
		placa = Color3.fromRGB(60, 150, 210),
		borda = Color3.fromRGB(245, 245, 245),
		bordaNeon = false,
		texto = Color3.fromRGB(255, 255, 255),
		enfeite = function(pasta, topoPilar)
			-- folhas de palmeira caindo para os lados
			for i = 1, 5 do
				parte({
					Name = "Folha",
					Size = Vector3.new(1.2, 0.3, 5),
					CFrame = CFrame.new(topoPilar + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, math.rad(i * 72), 0) * CFrame.Angles(math.rad(-30), 0, 0) * CFrame.new(0, 0, -2.4),
					Color = FOLHAS_LAGO[i % #FOLHAS_LAGO + 1],
					CanCollide = false,
					Parent = pasta,
				})
			end
		end,
	},
	deserto = {
		pilar = Color3.fromRGB(215, 170, 110),
		material = Enum.Material.Sandstone,
		faixa = Color3.fromRGB(185, 115, 65),
		faixaNeon = false,
		placa = Color3.fromRGB(175, 115, 62),
		borda = Color3.fromRGB(120, 75, 40),
		bordaNeon = false,
		texto = Color3.fromRGB(255, 238, 190),
		enfeite = function(pasta, topoPilar)
			cacto(pasta, topoPilar, 0.45)
		end,
	},
	vulcao = {
		pilar = Color3.fromRGB(50, 40, 40),
		material = Enum.Material.Basalt,
		faixa = Color3.fromRGB(255, 110, 30),
		faixaNeon = true,
		placa = Color3.fromRGB(38, 30, 30),
		borda = Color3.fromRGB(255, 110, 30),
		bordaNeon = true,
		texto = Color3.fromRGB(255, 185, 90),
		enfeite = function(pasta, topoPilar)
			local braseiro = parte({ Name = "Braseiro", Size = Vector3.new(3, 1, 3), Position = topoPilar + Vector3.new(0, 0.5, 0), Color = Color3.fromRGB(255, 110, 30), Material = Enum.Material.Neon, Parent = pasta })
			local fogo = Instance.new("Fire")
			fogo.Size = 6
			fogo.Heat = 10
			fogo.Color = Color3.fromRGB(255, 110, 30)
			fogo.SecondaryColor = Color3.fromRGB(255, 200, 80)
			fogo.Parent = braseiro
		end,
	},
	espaco = {
		pilar = Color3.fromRGB(70, 72, 95),
		material = Enum.Material.Metal,
		faixa = Color3.fromRGB(80, 220, 255),
		faixaNeon = true,
		placa = Color3.fromRGB(22, 22, 48),
		borda = Color3.fromRGB(80, 220, 255),
		bordaNeon = true,
		texto = Color3.fromRGB(170, 240, 255),
		enfeite = function(pasta, topoPilar)
			-- antena com uma luz piscando
			parte({ Name = "Antena", Size = Vector3.new(0.4, 4, 0.4), Position = topoPilar + Vector3.new(0, 2, 0), Color = Color3.fromRGB(180, 180, 195), Material = Enum.Material.Metal, CanCollide = false, Parent = pasta })
			local luz = parte({ Name = "LuzAntena", Size = Vector3.new(1, 1, 1), Position = topoPilar + Vector3.new(0, 4.4, 0), Color = Color3.fromRGB(255, 70, 90), Material = Enum.Material.Neon, CanCollide = false, Parent = pasta })
			CollectionService:AddTag(luz, "PulsarEsteira")
		end,
	},
}

-- Texto da placa do arco: o nome grande e, embaixo, a Velocidade necessária.
-- Fonte grossa de letreiro, só com letras sem acento (a fonte não tem acentos).
local function textoArco(placa: BasePart, face: Enum.NormalId, nome: string, aviso: string?, tema: TemaArco)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = if tema.bordaNeon then 0 else 1
	gui.Parent = placa
	local function linha(conteudo: string, y: number, altura: number, cor: Color3)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0.04, y)
		label.Size = UDim2.fromScale(0.92, altura)
		label.Font = Enum.Font.LuckiestGuy
		label.TextScaled = true
		label.TextColor3 = cor
		label.Text = conteudo
		local contorno = Instance.new("UIStroke")
		contorno.Thickness = 5
		contorno.Color = tema.placa:Lerp(Color3.new(0, 0, 0), 0.6)
		contorno.Parent = label
		label.Parent = gui
	end
	if aviso then
		linha(nome, 0.08, 0.56, tema.texto)
		linha(aviso, 0.66, 0.26, Color3.fromRGB(255, 225, 90))
	else
		linha(nome, 0.14, 0.72, tema.texto)
	end
end

-- Placa de aviso amarela e preta antes do portal: dá para entrar com
-- qualquer Velocidade, mas abaixo do mínimo o guardião alcança quem pega um ovo.
local function placaAviso(pasta: Instance, x: number, z: number, info: Mapa.InfoBioma)
	local PRETO = Color3.fromRGB(30, 28, 32)
	local AMARELO = Color3.fromRGB(255, 205, 40)
	local y = 1 -- em cima do chão de transição
	for _, dz in { -4, 4 } do
		parte({ Name = "PostePlaca", Size = Vector3.new(0.9, 9, 0.9), Position = Vector3.new(x, y + 4.5, z + dz), Color = PRETO, Parent = pasta })
	end
	parte({ Name = "MolduraAviso", Size = Vector3.new(0.8, 7.4, 11.4), Position = Vector3.new(x, y + 8.2, z), Color = PRETO, Parent = pasta })
	local placa = parte({ Name = "PlacaAviso", Size = Vector3.new(1, 6.8, 10.8), Position = Vector3.new(x, y + 8.2, z), Color = AMARELO, Parent = pasta })
	-- pinos de Lego em cima
	for dz = -4, 4, 2 do
		local pino = parte({ Name = "Pino", Size = Vector3.new(0.6, 0.5, 0.6), Position = Vector3.new(x, y + 11.9, z + dz), Color = AMARELO, CanCollide = false, Parent = pasta })
		pino.Shape = Enum.PartType.Cylinder
		pino.Orientation = Vector3.new(0, 0, 90)
	end
	local minimo = Config.formatar(info.config.velocidadeMinima)
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.Parent = placa
		local function linha(texto: string, y: number, altura: number, cor: Color3)
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Position = UDim2.fromScale(0.05, y)
			label.Size = UDim2.fromScale(0.9, altura)
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextWrapped = true
			label.TextColor3 = cor
			label.Text = texto
			label.Parent = gui
		end
		linha("⚠️ ATENÇÃO! ⚠️", 0.05, 0.2, Color3.fromRGB(200, 30, 30))
		linha(`VELOCIDADE MÍNIMA: {minimo}`, 0.27, 0.22, PRETO)
		linha(`para pegar um ovo sem ser pego pelo {info.config.guardiao}`, 0.53, 0.4, PRETO)
	end
end

local juncao: (Instance, Mapa.InfoBioma) -> ()
local function decorarPortal(info: Mapa.InfoBioma)
	local pasta = Instance.new("Folder")
	pasta.Name = "DecoracaoPortal"
	pasta.Parent = info.pasta
	local x = info.centro.X - Mapa.TAMANHO_BIOMA / 2
	local tema = TEMAS_ARCO[info.config.estilo] or TEMAS_ARCO.floresta

	-- pilares de blocos, mais largos embaixo, com listras
	for _, z in { -12.5, 12.5 } do
		parte({ Name = "PePilar", Size = Vector3.new(5, 3, 5), Position = Vector3.new(x, 1.5, z), Color = tema.pilar:Lerp(Color3.new(0, 0, 0), 0.2), Material = tema.material, Parent = pasta })
		parte({ Name = "Pilar", Size = Vector3.new(3.6, 20, 3.6), Position = Vector3.new(x, 13, z), Color = tema.pilar, Material = tema.material, Parent = pasta })
		for y = 6, 20, 5 do
			local listra = parte({
				Name = "Listra",
				Size = Vector3.new(3.9, 0.6, 3.9),
				Position = Vector3.new(x, y, z),
				Color = tema.faixa,
				Material = if tema.faixaNeon then Enum.Material.Neon else tema.material,
				Parent = pasta,
			})
			if tema.faixaNeon then
				CollectionService:AddTag(listra, "PulsarEsteira")
			end
		end
		if tema.enfeite then
			tema.enfeite(pasta, Vector3.new(x, 23, z))
		end
	end

	-- placa grande em cima, com moldura
	local placa = parte({
		Name = "PlacaBioma",
		Size = Vector3.new(1.6, 7.5, 24),
		Position = Vector3.new(x, 26.5, 0),
		Color = tema.placa,
		Material = if tema.material == Enum.Material.Wood then Enum.Material.WoodPlanks else tema.material,
		Parent = pasta,
	})
	parte({
		Name = "MolduraBioma",
		Size = Vector3.new(1.3, 8.7, 25.2),
		Position = Vector3.new(x, 26.5, 0),
		Color = tema.borda,
		Material = if tema.bordaNeon then Enum.Material.Neon else Enum.Material.Wood,
		Parent = pasta,
	})
	parte({ Name = "Viga", Size = Vector3.new(2.4, 1.6, 30), Position = Vector3.new(x, 22.6, 0), Color = tema.pilar, Material = tema.material, Parent = pasta })
	local nome = Config.maiusculas(Config.semAcento(info.config.nome))
	-- só o nome: a Velocidade mínima fica na placa amarela de atenção
	local minimo = info.config.velocidadeMinima
	textoArco(placa, Enum.NormalId.Left, nome, nil, tema)
	textoArco(placa, Enum.NormalId.Right, nome, nil, tema)

	local portal = info.pasta:FindFirstChild("Portal")
	if portal then
		local cor = info.config.cor
		local brilho = Instance.new("ParticleEmitter")
		brilho.Name = "Brilho"
		brilho.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		brilho.Color = ColorSequence.new(cor:Lerp(Color3.new(1, 1, 1), 0.4), Color3.new(1, 1, 1))
		brilho.LightEmission = 1
		brilho.Rate = 30
		brilho.Lifetime = NumberRange.new(1, 2)
		brilho.Speed = NumberRange.new(0.5, 2)
		brilho.SpreadAngle = Vector2.new(180, 180)
		brilho.Size = NumberSequence.new(0.6, 0)
		brilho.Parent = portal
	end

	if minimo > 0 then
		placaAviso(pasta, x - 16, -17, info)
	end
end

local function decorarEstrada(pasta: Instance)
	Cidade.rua(pasta)
	tunel(pasta)
end

-- Cacto de blocos: tronco com dois braços dobrados para cima.
function cacto(pasta: Instance, chao: Vector3, escala: number)
	local verde = Color3.fromRGB(70, 150, 70):Lerp(Color3.fromRGB(100, 170, 80), aleatorio:NextNumber())
	local altura = aleatorio:NextNumber(6, 9) * escala
	local giro = CFrame.new(chao) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi), 0)
	parte({ Name = "Cacto", Size = Vector3.new(1.6, altura, 1.6) * Vector3.new(escala, 1, escala), CFrame = giro * CFrame.new(0, altura / 2, 0), Color = verde, Parent = pasta })
	for _, x in { -1, 1 } do
		local y = altura * aleatorio:NextNumber(0.35, 0.6)
		local braco = aleatorio:NextNumber(1.6, 2.4) * escala
		parte({ Name = "Cacto", Size = Vector3.new(braco, escala, escala), CFrame = giro * CFrame.new(x * (0.8 * escala + braco / 2), y, 0), Color = verde, Parent = pasta })
		parte({ Name = "Cacto", Size = Vector3.new(1, 2.6, 1) * escala, CFrame = giro * CFrame.new(x * (0.8 * escala + braco), y + 1.3 * escala, 0), Color = verde, Parent = pasta })
	end
	if aleatorio:NextNumber() < 0.4 then
		parte({ Name = "Flor", Size = Vector3.new(0.9, 0.5, 0.9) * escala, CFrame = giro * CFrame.new(0, altura + 0.25, 0), Color = escolher(FLORES), CanCollide = false, Parent = pasta })
	end
end

-- Transição entre um bioma e o próximo: um chão de parede a parede que vai
-- misturando o piso dos dois como pixels (perto de um, quase tudo dele; no
-- meio, metade de cada). Embaixo é uma laje só do primeiro piso; os pixels
-- do segundo ficam por cima, finos e sem colisão (blocos vizinhos na mesma
-- coluna viram um só). Depois do último bioma, só o piso dele.
local BLOCO_TRANSICAO = 5
local function transicoes(pasta: Instance, biomas: { Mapa.InfoBioma })
	for i, info in biomas do
		-- faixa do piso do bioma até as paredes (sem ela aparecia a grama embaixo)
		local pisoBioma = info.pasta:FindFirstChild("Piso") :: BasePart
		for _, lado in { -1, 1 } do
			local de = Mapa.TAMANHO_BIOMA / 2 - 0.5
			parte({
				Name = "Rodape",
				Size = Vector3.new(Mapa.TAMANHO_BIOMA, 1.3, Mapa.Z_PAREDE - de + 0.5),
				Position = Vector3.new(info.centro.X, info.centro.Y - 0.6, lado * (de + Mapa.Z_PAREDE + 0.5) / 2),
				Color = pisoBioma.Color,
				Material = pisoBioma.Material,
				Parent = pasta,
			})
		end
		local proximo = biomas[i + 1]
		local de = info.centro.X + Mapa.TAMANHO_BIOMA / 2
		local ate = if proximo then proximo.centro.X - Mapa.TAMANHO_BIOMA / 2 else Mapa.FIM_ESTRADA + 14
		local pisoA = info.pasta:FindFirstChild("Piso") :: BasePart
		local pisoB = if proximo then proximo.pasta:FindFirstChild("Piso") :: BasePart else pisoA
		local largura = Mapa.Z_PAREDE * 2
		parte({
			Name = "Transicao",
			Size = Vector3.new(ate - de, 1.3, largura),
			Position = Vector3.new((de + ate) / 2, info.centro.Y - 0.6, 0),
			Color = pisoA.Color,
			Material = pisoA.Material,
			Parent = pasta,
		})
		if pisoB == pisoA then
			continue
		end
		local colunas = math.max(1, math.round((ate - de) / BLOCO_TRANSICAO))
		local passo = (ate - de) / colunas
		local linhas = math.round(largura / BLOCO_TRANSICAO)
		local passoZ = largura / linhas
		local topo = info.centro.Y + 0.05
		for c = 0, colunas - 1 do
			local t = (c + 0.5) / colunas
			local chance = t * t * (3 - 2 * t) -- suave nas pontas
			local comeco: number? = nil
			for l = 0, linhas do
				local doB = l < linhas and aleatorio:NextNumber() < chance
				if doB and not comeco then
					comeco = l
				elseif not doB and comeco then
					parte({
						Name = "Pixel",
						Size = Vector3.new(passo, 0.12, (l - comeco) * passoZ),
						Position = Vector3.new(de + (c + 0.5) * passo, topo + 0.06, -largura / 2 + (comeco + l) / 2 * passoZ),
						Color = escurecer(pisoB.Color, aleatorio:NextNumber(0, 0.08)),
						Material = pisoB.Material,
						CanCollide = false,
						CanQuery = false,
						CanTouch = false,
						CastShadow = false,
						Parent = pasta,
					})
					comeco = nil
				end
			end
		end
	end
end

-- Fim do mapa, depois do último bioma: o portal do próximo bioma, no estilo
-- do túnel da entrada. Uma fachada de metal com placas, contrafortes em
-- degraus, cornija, faixas de alerta, alarmes piscando e as pedras do arco;
-- por dentro, molduras de neon cada vez mais fundas e um redemoinho de
-- campo de força girando, com o texto e a contagem até Config.PROXIMO_BIOMA
-- flutuando na frente. Na frente: piso brilhando, cristais flutuando e
-- barreiras de obra. Atrás, a parede alta na cor das paredes do Espaço, e
-- uma parede invisível na frente da fachada segura todo mundo.
local function fimDoMapa(pasta: Instance)
	local x0 = Mapa.FIM_ESTRADA + 14 -- frente da fachada fica em x0 - 2
	local chao = 1.05 -- topo do chão de transição
	local larguraMapa = (Mapa.Z_PAREDE + 4) * 2
	local METAL = Color3.fromRGB(52, 52, 78)
	local METAL_ESCURO = Color3.fromRGB(32, 30, 50)
	local METAL_CLARO = Color3.fromRGB(78, 80, 112)
	local ROXO = Color3.fromRGB(160, 80, 255)
	local CIANO = Color3.fromRGB(80, 220, 255)
	local PRETO_ALERTA = Color3.fromRGB(25, 22, 35)

	local function enfeite(props): Part
		props.CanCollide = false
		props.CanQuery = false
		props.CanTouch = false
		props.CastShadow = false
		props.Parent = pasta
		return parte(props)
	end
	local function neon(props): Part
		props.Material = Enum.Material.Neon
		local p = enfeite(props)
		CollectionService:AddTag(p, "PulsarEsteira")
		return p
	end

	-- parede do fundo, de lado a lado, com as linhas de neon
	local ALTURA = 56
	local fundo = x0 + 10
	parte({ Name = "ParedeFim", Size = Vector3.new(4, ALTURA, larguraMapa), Position = Vector3.new(fundo + 2, ALTURA / 2, 0), Color = METAL, Material = Enum.Material.Metal, Parent = pasta })
	for _, y in { 4, ALTURA - 6 } do
		neon({ Name = "NeonFim", Size = Vector3.new(0.3, 0.4, larguraMapa), Position = Vector3.new(fundo - 0.1, y, 0), Color = CIANO })
	end
	-- do lado da fachada até as paredes dos biomas
	for _, lado in { -1, 1 } do
		parte({ Name = "ParedeFim", Size = Vector3.new(fundo - x0 + 2, ALTURA, larguraMapa / 2 - 36), Position = Vector3.new((x0 - 2 + fundo) / 2, ALTURA / 2, lado * (36 + (larguraMapa / 2 - 36) / 2)), Color = METAL, Material = Enum.Material.Metal, Parent = pasta })
	end
	parte({ Name = "Barreira", Size = Vector3.new(2, 200, larguraMapa), Position = Vector3.new(x0 - 3.2, 100, 0), Transparency = 1, CanQuery = false, CanTouch = false, Parent = pasta })

	-- abertura do portal
	local meia = 12
	local topoAbertura = chao + 30
	local frente = x0 - 2

	-- fachada: painéis dos lados e em cima da abertura
	local largura = 24 -- quanto a fachada vai para cada lado da abertura
	local topo = topoAbertura + 10
	for _, lado in { -1, 1 } do
		parte({ Name = "Fachada", Size = Vector3.new(fundo - frente, topo, largura), Position = Vector3.new((frente + fundo) / 2, topo / 2, lado * (meia + largura / 2)), Color = METAL, Material = Enum.Material.Metal, Parent = pasta })
		-- contrafortes em degraus
		for i = 1, 3 do
			local h = topo - i * 7
			parte({ Name = "Contraforte", Size = Vector3.new(2 + i * 1.5, h, 3), Position = Vector3.new(frente - (2 + i * 1.5) / 2 + 1, h / 2, lado * (meia + largura - 1.5 - (i - 1) * 3)), Color = if i % 2 == 0 then METAL_CLARO else METAL, Material = Enum.Material.Metal, Parent = pasta })
		end
		-- placas de metal por cima, em dois tons, algumas com uma luzinha
		for y = chao + 1, topo - 4, 4 do
			for z = meia + 3.2, meia + largura - 8, 4 do
				enfeite({ Name = "Placa", Size = Vector3.new(0.4, 3.7, 3.7), Position = Vector3.new(frente - 0.2, y + 1.85, lado * (z + 1.85)), Color = if (y + z) % 8 < 4 then METAL_CLARO else METAL, Material = Enum.Material.DiamondPlate })
				if aleatorio:NextNumber() < 0.25 then
					neon({ Name = "LuzPlaca", Size = Vector3.new(0.2, 0.5, 0.5), Position = Vector3.new(frente - 0.45, y + 3, lado * (z + 3)), Color = if aleatorio:NextNumber() < 0.5 then ROXO else CIANO })
				end
			end
		end
		-- faixas de alerta roxas e pretas dos lados da abertura
		for i = 0, 19 do
			enfeite({ Name = "Alerta", Size = Vector3.new(0.3, 1.5, 1.4), Position = Vector3.new(frente - 0.5, chao + 0.75 + i * 1.5, lado * (meia + 1.7)), Color = if i % 2 == 0 then ROXO else PRETO_ALERTA, Material = if i % 2 == 0 then Enum.Material.Neon else Enum.Material.SmoothPlastic })
		end
		-- alarme roxo piscando no alto
		local alarme = neon({ Name = "Alarme", Size = Vector3.new(1.6, 1.6, 1.6), Position = Vector3.new(frente - 0.9, topoAbertura + 2.5, lado * (meia + 4)), Color = ROXO })
		local luz = Instance.new("PointLight")
		luz.Color = ROXO
		luz.Range = 18
		luz.Brightness = 2
		luz.Parent = alarme
		-- cristal flutuando em cima de um pedestal, na frente da fachada
		local base = Vector3.new(frente - 12, chao, lado * (meia + 14))
		parte({ Name = "Pedestal", Size = Vector3.new(5, 2, 5), Position = base + Vector3.new(0, 1, 0), Color = METAL_ESCURO, Material = Enum.Material.Metal, Parent = pasta })
		parte({ Name = "Pedestal", Size = Vector3.new(3.6, 2, 3.6), Position = base + Vector3.new(0, 3, 0), Color = METAL, Material = Enum.Material.Metal, Parent = pasta })
		neon({ Name = "AnelPedestal", Size = Vector3.new(4, 0.3, 4), Position = base + Vector3.new(0, 4.1, 0), Color = CIANO })
		local cristal = enfeite({ Name = "Cristal", Size = Vector3.new(2.2, 4.4, 2.2), CFrame = CFrame.new(base + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(45)) * CFrame.Angles(math.rad(45), 0, 0), Color = ROXO, Material = Enum.Material.Neon })
		cristal:SetAttribute("ManterForma", true)
		cristal:SetAttribute("Giro", 70)
		cristal:SetAttribute("Flutua", 0.8)
		CollectionService:AddTag(cristal, "GirarEsteira")
		local brilhoCristal = Instance.new("PointLight")
		brilhoCristal.Color = ROXO
		brilhoCristal.Range = 16
		brilhoCristal.Brightness = 1.5
		brilhoCristal.Parent = cristal
	end
	parte({ Name = "Fachada", Size = Vector3.new(fundo - frente, topo - topoAbertura, meia * 2), Position = Vector3.new((frente + fundo) / 2, (topo + topoAbertura) / 2, 0), Color = METAL, Material = Enum.Material.Metal, Parent = pasta })
	-- pedras do arco, com a do meio brilhando
	for i = -3, 3 do
		local p = parte({
			Name = "PedraArco",
			Size = Vector3.new(1.4, 3 - math.abs(i) * 0.3, 3.2),
			Position = Vector3.new(frente - 0.5, topoAbertura + 1.6 - math.abs(i) * 0.15, i * 3.5),
			Color = if i == 0 then ROXO else METAL_CLARO,
			Material = if i == 0 then Enum.Material.Neon else Enum.Material.Metal,
			Parent = pasta,
		})
		if i == 0 then
			CollectionService:AddTag(p, "PulsarEsteira")
		end
	end
	-- cornija com neon embaixo
	parte({ Name = "Cornija", Size = Vector3.new(4, 1.6, (meia + largura) * 2 + 2), Position = Vector3.new(frente, topo + 0.8, 0), Color = METAL_ESCURO, Material = Enum.Material.Metal, Parent = pasta })
	neon({ Name = "NeonCornija", Size = Vector3.new(0.3, 0.35, (meia + largura) * 2), Position = Vector3.new(frente - 2.1, topo - 0.2, 0), Color = CIANO })

	-- placa "em construção" em cima, com moldura de alerta
	local placa = parte({ Name = "PlacaObra", Size = Vector3.new(1, 6, 30), Position = Vector3.new(frente, topo + 5, 0), Color = Color3.fromRGB(255, 205, 50), Parent = pasta })
	for i = -8, 8 do
		enfeite({ Name = "AlertaPlaca", Size = Vector3.new(1.1, 0.8, 1.7), Position = Vector3.new(frente, topo + 8.2, i * 1.75), Color = if i % 2 == 0 then PRETO_ALERTA else Color3.fromRGB(255, 205, 50), Material = Enum.Material.SmoothPlastic })
	end
	local guiPlaca = Instance.new("SurfaceGui")
	guiPlaca.Face = Enum.NormalId.Left
	guiPlaca.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	guiPlaca.PixelsPerStud = 20
	guiPlaca.Parent = placa
	local textoPlaca = Instance.new("TextLabel")
	textoPlaca.BackgroundTransparency = 1
	textoPlaca.Position = UDim2.fromScale(0.04, 0.12)
	textoPlaca.Size = UDim2.fromScale(0.92, 0.6)
	textoPlaca.Font = Enum.Font.LuckiestGuy
	textoPlaca.TextScaled = true
	textoPlaca.TextColor3 = PRETO_ALERTA
	textoPlaca.Text = "🚧 EM CONSTRUÇÃO 🚧"
	textoPlaca.Parent = guiPlaca

	-- por dentro: paredes e teto da abertura e molduras cada vez mais fundas
	parte({ Name = "PisoAbertura", Size = Vector3.new(fundo - frente, 1.3, meia * 2 + 2), Position = Vector3.new((frente + fundo) / 2, chao - 0.65, 0), Color = METAL_ESCURO, Material = Enum.Material.Metal, Parent = pasta })
	for _, lado in { -1, 1 } do
		parte({ Name = "ParedePortal", Size = Vector3.new(fundo - frente, 30, 1), Position = Vector3.new((frente + fundo) / 2, chao + 15, lado * (meia + 0.5)), Color = METAL_ESCURO, Material = Enum.Material.Metal, Parent = pasta })
	end
	for i = 0, 3 do
		local x = frente + 1 + i * 2
		local dentro = i * 1.2
		local corMoldura = METAL_CLARO:Lerp(METAL_ESCURO, i / 3)
		local alto = 30 - dentro
		for _, lado in { -1, 1 } do
			enfeite({ Name = "MolduraPortal", Size = Vector3.new(1, alto, 1.2), Position = Vector3.new(x, chao + alto / 2, lado * (meia - 0.6 - dentro)), Color = corMoldura, Material = Enum.Material.Metal })
			neon({ Name = "NeonMoldura", Size = Vector3.new(0.3, alto, 0.2), Position = Vector3.new(x - 0.6, chao + alto / 2, lado * (meia - 1.2 - dentro)), Color = ROXO:Lerp(Color3.new(0, 0, 0), i * 0.18) })
		end
		enfeite({ Name = "MolduraPortal", Size = Vector3.new(1, 1.2, (meia - dentro) * 2), Position = Vector3.new(x, chao + alto - 0.6, 0), Color = corMoldura, Material = Enum.Material.Metal })
		neon({ Name = "NeonMoldura", Size = Vector3.new(0.3, 0.2, (meia - dentro) * 2 - 2.4), Position = Vector3.new(x - 0.6, chao + alto - 1.2, 0), Color = ROXO:Lerp(Color3.new(0, 0, 0), i * 0.18) })
	end

	-- redemoinho: fundo preto, dois discos de campo de força e raios girando
	local centro = Vector3.new(fundo - 1, chao + 14, 0)
	parte({ Name = "FundoPortal", Size = Vector3.new(1, 30, meia * 2), Position = Vector3.new(fundo - 0.5, chao + 15, 0), Color = Color3.fromRGB(5, 3, 12), Material = Enum.Material.SmoothPlastic, Parent = pasta })
	for i, info in { { 19, ROXO }, { 12, CIANO } } do
		local disco = enfeite({
			Name = "Redemoinho",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.2, info[1], info[1]),
			Position = centro - Vector3.new(i * 0.3, 0, 0),
			Color = info[2],
			Material = Enum.Material.ForceField,
		})
		disco:SetAttribute("ManterForma", true)
	end
	for i = 0, 2 do
		local raio = enfeite({
			Name = "RaioPortal",
			Size = Vector3.new(0.2, 17, 0.5),
			CFrame = CFrame.new(centro - Vector3.new(0.9, 0, 0)) * CFrame.Angles(math.rad(i * 60), 0, 0),
			Color = Color3.fromRGB(220, 190, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.35,
		})
		raio:SetAttribute("Giro", 90)
		CollectionService:AddTag(raio, "GirarPortal")
	end
	local nucleo = enfeite({ Name = "NucleoPortal", Size = Vector3.new(0.3, 2.4, 2.4), Position = centro - Vector3.new(1, 0, 0), Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon })
	nucleo:SetAttribute("Giro", -140)
	CollectionService:AddTag(nucleo, "GirarPortal")
	local luzPortal = Instance.new("PointLight")
	luzPortal.Color = ROXO
	luzPortal.Range = 40
	luzPortal.Brightness = 3
	luzPortal.Parent = nucleo

	-- partículas sendo sugadas para dentro do portal e brilhos em volta
	local suga = enfeite({ Name = "Aura", Size = Vector3.new(1, 26, 22), Position = Vector3.new(frente - 6, chao + 14, 0), Transparency = 1 })
	local particulas = Instance.new("ParticleEmitter")
	particulas.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particulas.Color = ColorSequence.new(ROXO, CIANO)
	particulas.LightEmission = 1
	particulas.Rate = 60
	particulas.Lifetime = NumberRange.new(0.8, 1.3)
	particulas.Speed = NumberRange.new(4, 8)
	particulas.Acceleration = Vector3.new(18, 0, 0)
	particulas.EmissionDirection = Enum.NormalId.Right
	particulas.Orientation = Enum.ParticleOrientation.VelocityParallel
	particulas.Squash = NumberSequence.new(-1.5)
	particulas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	particulas.Shape = Enum.ParticleEmitterShape.Box
	particulas.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	particulas.Parent = suga
	local estrelas = Instance.new("ParticleEmitter")
	estrelas.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	estrelas.Color = ColorSequence.new(Color3.new(1, 1, 1), ROXO)
	estrelas.LightEmission = 1
	estrelas.Rate = 25
	estrelas.Lifetime = NumberRange.new(1.5, 3)
	estrelas.Speed = NumberRange.new(0.3, 1.2)
	estrelas.RotSpeed = NumberRange.new(-120, 120)
	estrelas.SpreadAngle = Vector2.new(180, 180)
	estrelas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.7), NumberSequenceKeypoint.new(1, 0) })
	estrelas.Parent = nucleo

	-- raios de energia subindo pelas bordas da abertura
	for _, lado in { -1, 1 } do
		local suporte = enfeite({ Name = "Aura", Size = Vector3.new(0.2, 0.2, 0.2), Position = Vector3.new(frente + 0.8, chao, lado * (meia - 2)), Transparency = 1 })
		local a0 = Instance.new("Attachment")
		a0.Parent = suporte
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, 28, 0)
		a1.Parent = suporte
		local energia = Instance.new("Beam")
		energia.Attachment0 = a0
		energia.Attachment1 = a1
		energia.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		energia.TextureMode = Enum.TextureMode.Wrap
		energia.TextureLength = 3
		energia.TextureSpeed = 2
		energia.Color = ColorSequence.new(CIANO, ROXO)
		energia.LightEmission = 1
		energia.LightInfluence = 0
		energia.Width0 = 1.4
		energia.Width1 = 1.4
		energia.CurveSize0 = lado * 4
		energia.CurveSize1 = -lado * 4
		energia.Segments = 20
		energia.FaceCamera = true
		energia.Parent = suporte
	end

	-- texto e contagem flutuando na frente do redemoinho
	local tela = enfeite({ Name = "TextoPortal", Size = Vector3.new(0.2, 28, 22), Position = Vector3.new(frente + 2, chao + 15, 0), Transparency = 1 })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = tela
	local function linha(conteudo: string, y: number, altura: number, cor: Color3): TextLabel
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0.04, y)
		label.Size = UDim2.fromScale(0.92, altura)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = cor
		label.TextStrokeColor3 = Color3.fromRGB(25, 15, 45)
		label.TextStrokeTransparency = 0
		label.Text = conteudo
		label.Parent = gui
		return label
	end
	linha("NOVO BIOMA", 0.16, 0.13, Color3.fromRGB(255, 225, 90))
	linha("EM BREVE", 0.3, 0.1, Color3.fromRGB(215, 185, 255))
	local contagem = linha("", 0.6, 0.12, CIANO)
	linha("PRÓXIMA ATUALIZAÇÃO", 0.74, 0.06, Color3.fromRGB(230, 230, 245))
	local data = Config.PROXIMO_BIOMA
	local fim = os.time({ year = data.ano, month = data.mes, day = data.dia, hour = data.hora, min = 0, sec = 0 })
	task.spawn(function()
		while tela.Parent do
			local falta = fim - os.time()
			if falta <= 0 then
				contagem.Text = "MUITO EM BREVE!"
			else
				local d, h = falta // 86400, (falta % 86400) // 3600
				local m, sg = (falta % 3600) // 60, falta % 60
				contagem.Text = string.format("%dd %02dh %02dm %02ds", d, h, m, sg)
			end
			task.wait(1)
		end
	end)

	-- piso brilhando na frente e as barreiras de obra com cones
	neon({ Name = "PisoPortal", Size = Vector3.new(10, 0.1, meia * 2), Position = Vector3.new(frente - 5, chao + 0.05, 0), Color = ROXO })
	for _, lado in { -1, 1 } do
		for i = 0, 1 do
			local z = lado * (4 + i * 8)
			local base = Vector3.new(frente - 13, chao, z)
			for _, dz in { -2.2, 2.2 } do
				parte({ Name = "PeBarreira", Size = Vector3.new(1.4, 3, 0.4), Position = base + Vector3.new(0, 1.5, dz), Color = Color3.fromRGB(235, 235, 240), Parent = pasta })
			end
			for faixa = 0, 4 do
				enfeite({ Name = "FaixaBarreira", Size = Vector3.new(0.4, 1.2, 1), Position = base + Vector3.new(0, 3.2, -2 + faixa * 1), Color = if faixa % 2 == 0 then Color3.fromRGB(255, 120, 30) else Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic })
			end
		end
		for _, dz in { 18, 22 } do
			local cone = Vector3.new(frente - 9, chao, lado * dz)
			parte({ Name = "BaseCone", Size = Vector3.new(2, 0.3, 2), Position = cone + Vector3.new(0, 0.15, 0), Color = Color3.fromRGB(40, 40, 45), Parent = pasta })
			parte({ Name = "Cone", Size = Vector3.new(1.4, 1.2, 1.4), Position = cone + Vector3.new(0, 0.9, 0), Color = Color3.fromRGB(255, 120, 30), Parent = pasta })
			parte({ Name = "Cone", Size = Vector3.new(1, 0.5, 1), Position = cone + Vector3.new(0, 1.75, 0), Color = Color3.new(1, 1, 1), Parent = pasta })
			parte({ Name = "Cone", Size = Vector3.new(0.7, 0.9, 0.7), Position = cone + Vector3.new(0, 2.45, 0), Color = Color3.fromRGB(255, 120, 30), Parent = pasta })
		end
	end
end

-- Junção da área das bases com o primeiro bioma: o chão do bioma fica 1
-- stud acima da grama. Uma rampa de pedra suave (dos dois lados da estrada,
-- de parede a parede) leva da grama até o piso, sem degrau nem borda à
-- mostra, e um muro de pedra liga as paredes do bioma às montanhas do
-- degrau, sem fresta entre eles.
function juncao(pai: Instance, info: Mapa.InfoBioma)
	local pasta = Instance.new("Folder")
	pasta.Name = "Juncao"
	pasta:SetAttribute("SemLego", true)
	pasta.Parent = pai
	local x = Mapa.inicioBioma(1)
	local piso = info.pasta:FindFirstChild("Piso") :: BasePart
	local topo = info.centro.Y + 0.05
	local RAMPA = 10
	local zMax = Mapa.Z_PAREDE + 4
	for _, lado in { -1, 1 } do
		-- da beira da calçada (z = 14) até a parede
		local de, ate = 7.2, zMax
		local largura = ate - de
		local cunha = Instance.new("WedgePart")
		cunha.Name = "Rampa"
		cunha.Anchored = true
		cunha.Size = Vector3.new(largura, topo - 0.05, RAMPA)
		-- a cunha sobe na direção -Z local; girada, sobe em +X até o bioma
		cunha.CFrame = CFrame.new(x - RAMPA / 2, 0.05 + cunha.Size.Y / 2, lado * (de + ate) / 2) * CFrame.Angles(0, math.rad(-90), 0)
		cunha.Color = piso.Color
		cunha.Material = piso.Material
		cunha.Parent = pasta
		-- faixa do piso do bioma até depois da parede, fechando a borda
		parte({ Name = "Emenda", Size = Vector3.new(4, 1.3, largura), Position = Vector3.new(x + 1, topo - 0.65, lado * (de + ate) / 2), Color = piso.Color, Material = piso.Material, Parent = pasta })
		-- muro de pedra na linha do bioma, da parede até as montanhas
		local zb = Montanhas.Z_BASES + 6
		local comprimento = zb - Mapa.Z_PAREDE + 2
		parte({ Name = "MuroJuncao", Size = Vector3.new(6, 26, comprimento), Position = Vector3.new(x + 3, 13, lado * (Mapa.Z_PAREDE - 2 + comprimento / 2)), Color = Color3.fromRGB(128, 122, 116), Material = Enum.Material.Cobblestone, Parent = pasta })
		parte({ Name = "MuroJuncao", Size = Vector3.new(7, 1.2, comprimento + 1), Position = Vector3.new(x + 3, 26.6, lado * (Mapa.Z_PAREDE - 2 + comprimento / 2)), Color = Color3.fromRGB(186, 178, 166), Material = Enum.Material.Limestone, Parent = pasta })
		for z = Mapa.Z_PAREDE + 4, zb - 2, 12 do
			parte({ Name = "PilarJuncao", Size = Vector3.new(7.5, 28, 3), Position = Vector3.new(x + 3, 14, lado * z), Color = Color3.fromRGB(186, 178, 166), Material = Enum.Material.Limestone, Parent = pasta })
		end
	end
	-- a estrada já chega no nível do bioma (topo 1); só a emenda embaixo do arco
	parte({ Name = "Emenda", Size = Vector3.new(2, 1.3, 14.4), Position = Vector3.new(x, topo - 0.65, 0), Color = Color3.fromRGB(58, 60, 66), Material = Enum.Material.Asphalt, Parent = pasta })
end

function Decoracao.construir(bases: { Mapa.InfoBase }, biomas: { Mapa.InfoBioma })
	iluminar()

	local pasta = Instance.new("Folder")
	pasta.Name = "Decoracao"

	-- Chão de grama só até o fim das montanhas: depois delas é o vazio (void).
	-- A Baseplate que vem no lugar sai, senão ela aparece em volta do mapa.
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	-- (as folgas vêm do tamanho das montanhas medido no Studio)
	-- (até o pé das montanhas; nos biomas, até o lado de fora das paredes)
	local inicio = Montanhas.INICIO - 34 -- montanha do começo
	local transicao = Montanhas.TRANSICAO
	local fimEstrada = Mapa.FIM_ESTRADA + 30 -- parede do fundo do portal
	local zBases = Montanhas.Z_BASES + 34 -- montanhas atrás das bases
	local zFases = Mapa.Z_PAREDE + 4 -- lado de fora das paredes dos biomas
	for _, area in {
		{ de = inicio, ate = transicao + 34, z = zBases }, -- bases (e o degrau até a estrada das fases)
		{ de = transicao, ate = fimEstrada, z = zFases }, -- estrada das fases
	} do
		parte({
			Name = "Chao",
			Size = Vector3.new(area.ate - area.de, 1, area.z * 2),
			Position = Vector3.new((area.de + area.ate) / 2, -0.45, 0),
			Color = Color3.fromRGB(125, 195, 90),
			Material = Enum.Material.Grass,
			Parent = pasta,
		})
	end

	decorarEstrada(pasta)
	Montanhas.construir()
	Paredes.construir(biomas)
	Cenario.construir(biomas)
	Cidade.arredores(pasta)
	Cidade.pracas(pasta)
	juncao(pasta, biomas[1])
	for _, info in bases do
		Cidade.base(info)
	end
	for _, info in biomas do
		Biomas.decorar(info)
		decorarPortal(info)
	end
	-- depois das decorações, que trocam a cor e o material dos pisos
	transicoes(pasta, biomas)
	fimDoMapa(pasta)

	pasta.Parent = Workspace

	-- tudo no estilo Lego (o que for criado depois nessas pastas também)
	for _, nome in { "Mapa", "Decoracao", "Montanhas", "Paredes", "Cenario" } do
		local raiz = Workspace:FindFirstChild(nome)
		if raiz then
			Blocos.vigiar(raiz)
		end
	end
end

return Decoracao

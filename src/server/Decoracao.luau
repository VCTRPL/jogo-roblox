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
local Biblioteca = require(script.Parent.Biblioteca)
local Blocos = require(script.Parent.Blocos)
local Mapa = require(script.Parent.Mapa)
local Montanhas = require(script.Parent.Montanhas)
local Paredes = require(script.Parent.Paredes)

local Decoracao = {}

local parte = Mapa.parte
local aleatorio = Random.new(2026)

local MARROM = Color3.fromRGB(110, 75, 45)
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

-- Árvores da biblioteca do Roblox, se alguém colocou em
-- ReplicatedStorage.ModelosArvore (subpastas "Floresta" e "Praia", ou
-- soltas na pasta para servir nas duas).
local moldesArvore: { [string]: { Model } } = {}
local function arvoresDaBiblioteca(estilo: string): { Model }
	if moldesArvore[estilo] then
		return moldesArvore[estilo]
	end
	local pasta = ReplicatedStorage:FindFirstChild("ModelosArvore")
	local lista = Biblioteca.moldes(pasta and pasta:FindFirstChild(estilo))
	if #lista == 0 and pasta then
		for _, objeto in pasta:GetChildren() do
			if objeto:IsA("Model") then
				table.insert(lista, objeto)
			end
		end
	end
	moldesArvore[estilo] = lista
	return lista
end

-- Planta uma árvore da biblioteca. Devolve false se não tiver nenhuma.
local function arvoreBiblioteca(pasta: Instance, chao: Vector3, estilo: string, escala: number): boolean
	local moldes = arvoresDaBiblioteca(estilo)
	if #moldes == 0 then
		return false
	end
	local modelo = Biblioteca.preparar(escolher(moldes), aleatorio:NextNumber(15, 22) * escala)
	if not modelo then
		return false
	end
	modelo.Name = "ArvoreBiblioteca"
	modelo:PivotTo(CFrame.new(chao) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0) * modelo:GetPivot())
	modelo.Parent = pasta
	return true
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

-- Árvore redonda: tronco e algumas bolas de folhas. "chao" é o ponto no chão.
local function arvore(pasta: Instance, chao: Vector3, escala: number, cores: { Color3 })
	local altura = aleatorio:NextNumber(6, 10) * escala
	local grossura = 1.8 * escala
	parte({
		Name = "Tronco",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(altura, grossura, grossura),
		CFrame = CFrame.new(chao + Vector3.new(0, altura / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = MARROM,
		Material = Enum.Material.Wood,
		Parent = pasta,
	})
	local cor = escolher(cores)
	local raio = aleatorio:NextNumber(7, 10) * escala
	local topo = chao + Vector3.new(0, altura + raio * 0.2, 0)
	parte({
		Name = "Folhas",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * raio,
		Position = topo,
		Color = cor,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = pasta,
	})
	for _ = 1, aleatorio:NextInteger(1, 2) do
		local angulo = aleatorio:NextNumber(0, math.pi * 2)
		local deslocamento = Vector3.new(math.cos(angulo), -0.15, math.sin(angulo)) * raio * 0.38
		parte({
			Name = "Folhas",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * raio * aleatorio:NextNumber(0.6, 0.75),
			Position = topo + deslocamento,
			Color = escurecer(cor, aleatorio:NextNumber(0, 0.15)),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = pasta,
		})
	end
end

-- Pinheiro: tronco e três "andares" de folhas girados.
local function pinheiro(pasta: Instance, chao: Vector3, escala: number)
	local altura = 4 * escala
	parte({
		Name = "Tronco",
		Size = Vector3.new(1.4, altura, 1.4) * Vector3.new(escala, 1, escala),
		Position = chao + Vector3.new(0, altura / 2, 0),
		Color = MARROM,
		Material = Enum.Material.Wood,
		Parent = pasta,
	})
	local cor = Color3.fromRGB(40, 120, 70):Lerp(Color3.fromRGB(60, 150, 80), aleatorio:NextNumber())
	local giro = aleatorio:NextNumber(0, 90)
	for andar = 0, 2 do
		local largura = (9 - andar * 2.6) * escala
		parte({
			Name = "Folhas",
			Size = Vector3.new(largura, 3.2 * escala, largura),
			CFrame = CFrame.new(chao + Vector3.new(0, altura + (andar * 2.6 + 1.2) * escala, 0))
				* CFrame.Angles(0, math.rad(giro + andar * 45), 0),
			Color = cor:Lerp(Color3.new(1, 1, 1), andar * 0.06),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = pasta,
		})
	end
end

-- Palmeira: tronco inclinado e folhas caindo em volta.
local function palmeira(pasta: Instance, chao: Vector3, escala: number)
	local altura = aleatorio:NextNumber(11, 15) * escala
	local inclinacao = CFrame.Angles(math.rad(aleatorio:NextNumber(-8, 8)), 0, math.rad(aleatorio:NextNumber(-8, 8)))
	local base = CFrame.new(chao) * inclinacao
	parte({
		Name = "Tronco",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(altura, 1.3 * escala, 1.3 * escala),
		CFrame = base * CFrame.new(0, altura / 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(150, 110, 70),
		Material = Enum.Material.Wood,
		Parent = pasta,
	})
	local topo = base * CFrame.new(0, altura, 0)
	local cor = escolher(FOLHAS_LAGO)
	for i = 1, 6 do
		parte({
			Name = "Folha",
			Size = Vector3.new(1.5, 0.3, 7) * escala,
			CFrame = topo * CFrame.Angles(0, math.rad(i * 60), 0) * CFrame.Angles(math.rad(-32), 0, 0) * CFrame.new(
				0,
				0,
				-3.6 * escala
			),
			Color = escurecer(cor, (i % 2) * 0.1),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = pasta,
		})
	end
end

local function arbusto(pasta: Instance, chao: Vector3, escala: number)
	local cor = escurecer(escolher(FOLHAS), 0.1)
	for _ = 1, 2 do
		local tamanho = aleatorio:NextNumber(2.5, 4) * escala
		parte({
			Name = "Arbusto",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * tamanho,
			Position = chao + Vector3.new(aleatorio:NextNumber(-1, 1), tamanho * 0.3, aleatorio:NextNumber(-1, 1)),
			Color = cor,
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = pasta,
		})
	end
end

local function pedra(pasta: Instance, chao: Vector3, tamanho: number, solida: boolean)
	local cinza = aleatorio:NextInteger(115, 150)
	parte({
		Name = "Pedra",
		Size = Vector3.new(tamanho * 1.3, tamanho * 0.8, tamanho),
		CFrame = CFrame.new(chao + Vector3.new(0, tamanho * 0.25, 0))
			* CFrame.Angles(0, aleatorio:NextNumber(0, math.pi), 0),
		Color = Color3.fromRGB(cinza, cinza, cinza + 8),
		Material = Enum.Material.Slate,
		CanCollide = solida,
		Parent = pasta,
	})
end

local function flor(pasta: Instance, chao: Vector3)
	parte({
		Name = "Flor",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * aleatorio:NextNumber(0.7, 1.1),
		Position = chao + Vector3.new(0, 0.4, 0),
		Color = escolher(FLORES),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		CastShadow = false,
		Parent = pasta,
	})
end

-- Cerca baixa (dá para pular) de "de" até "ate", no chão.
local function cerca(pasta: Instance, de: Vector3, ate: Vector3)
	local direcao = ate - de
	local comprimento = direcao.Magnitude
	local meio = CFrame.lookAt((de + ate) / 2, ate)
	for _, altura in { 0.8, 1.8 } do
		parte({
			Name = "Cerca",
			Size = Vector3.new(0.3, 0.35, comprimento),
			CFrame = meio + Vector3.new(0, altura, 0),
			Color = Color3.fromRGB(170, 120, 75),
			Material = Enum.Material.WoodPlanks,
			Parent = pasta,
		})
	end
	local postes = math.max(1, math.round(comprimento / 8))
	for i = 0, postes do
		parte({
			Name = "Poste",
			Size = Vector3.new(0.7, 2.4, 0.7),
			Position = de + direcao * (i / postes) + Vector3.new(0, 1.2, 0),
			Color = Color3.fromRGB(140, 95, 60),
			Material = Enum.Material.Wood,
			Parent = pasta,
		})
	end
end

-- Disco (cilindro deitado) centrado em "centro", com o topo a "topo" studs acima dele.
local function disco(pasta: Instance, centro: Vector3, nome: string, raio: number, topo: number, altura: number, props): Part
	props.Name = nome
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(altura, raio * 2, raio * 2)
	props.CFrame = CFrame.new(centro + Vector3.new(0, topo - altura / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	props.Parent = pasta
	return parte(props)
end

-- Sorteia "quantidade" pontos dentro do retângulo que passam no teste "livre".
local function espalhar(minimo: Vector3, maximo: Vector3, quantidade: number, livre: (Vector3) -> boolean, criar: (Vector3) -> ())
	local feitos = 0
	for _ = 1, quantidade * 20 do
		local ponto = Vector3.new(aleatorio:NextNumber(minimo.X, maximo.X), minimo.Y, aleatorio:NextNumber(minimo.Z, maximo.Z))
		if livre(ponto) then
			criar(ponto)
			feitos += 1
			if feitos >= quantidade then
				return
			end
		end
	end
end

local function distanciaPlana(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
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

-- Cerca de madeira de "de" até "ate" (no chão da base): postes a cada
-- ~8 studs, três tábuas compridas e um chapéu em cada poste.
local MADEIRA_ESCURA = Color3.fromRGB(105, 70, 42)
local MADEIRA_CLARA = { Color3.fromRGB(170, 120, 72), Color3.fromRGB(155, 108, 64), Color3.fromRGB(182, 132, 80) }
local function cercaMadeira(pasta: Instance, de: Vector3, ate: Vector3)
	local direcao = ate - de
	local comprimento = direcao.Magnitude
	local meio = CFrame.lookAt((de + ate) / 2, ate)
	for i, altura in { 1.3, 2.7, 4.1 } do
		parte({
			Name = "Tabua",
			Size = Vector3.new(0.5, 0.9, comprimento),
			CFrame = meio + Vector3.new(0, altura, 0),
			Color = MADEIRA_CLARA[i],
			Material = Enum.Material.WoodPlanks,
			Parent = pasta,
		})
	end
	local postes = math.max(1, math.round(comprimento / 8))
	for i = 0, postes do
		local ponto = de + direcao * (i / postes)
		parte({
			Name = "Poste",
			Size = Vector3.new(1.2, 5.2, 1.2),
			Position = ponto + Vector3.new(0, 2.6, 0),
			Color = MADEIRA_ESCURA,
			Material = Enum.Material.Wood,
			Parent = pasta,
		})
		parte({
			Name = "Chapeu",
			Size = Vector3.new(1.6, 0.4, 1.6),
			Position = ponto + Vector3.new(0, 5.4, 0),
			Color = MADEIRA_ESCURA:Lerp(Color3.new(0, 0, 0), 0.2),
			Material = Enum.Material.Wood,
			Parent = pasta,
		})
	end
end

-- Base: cercado de madeira com a entrada virada para a estrada, postes de
-- canto com lanternas na cor da base e um portão com a placa do número.
local ENTRADA = 9 -- metade da largura da entrada
local function decorarBase(info: Mapa.InfoBase)
	local pasta = Instance.new("Folder")
	pasta.Name = "Decoracao"
	pasta.Parent = info.pasta

	local meio = Mapa.TAMANHO_BASE / 2 - 0.6
	local topo = info.centro
	local lado = info.lado
	local cor = info.piso:GetAttribute("CorBase") or info.piso.Color
	local function ponto(x: number, z: number): Vector3
		-- z positivo = fundos da base (longe da estrada)
		return topo + Vector3.new(x, 0, lado * z)
	end

	cercaMadeira(pasta, ponto(-meio, meio), ponto(meio, meio))
	cercaMadeira(pasta, ponto(-meio, -meio), ponto(-meio, meio))
	cercaMadeira(pasta, ponto(meio, -meio), ponto(meio, meio))
	cercaMadeira(pasta, ponto(-meio, -meio), ponto(-ENTRADA - 1.5, -meio))
	cercaMadeira(pasta, ponto(ENTRADA + 1.5, -meio), ponto(meio, -meio))

	-- postes grossos nos cantos, com uma lanterna na cor da base
	for _, x in { -meio, meio } do
		for _, z in { -meio, meio } do
			local canto = ponto(x, z)
			parte({ Name = "PilarCanto", Size = Vector3.new(2.4, 6.4, 2.4), Position = canto + Vector3.new(0, 3.2, 0), Color = MADEIRA_ESCURA, Material = Enum.Material.Wood, Parent = pasta })
			parte({ Name = "Lanterna", Size = Vector3.new(1.6, 1.6, 1.6), Position = canto + Vector3.new(0, 7.2, 0), Color = cor:Lerp(Color3.new(1, 1, 1), 0.3), Material = Enum.Material.Neon, CanCollide = false, Parent = pasta })
			parte({ Name = "TetoLanterna", Size = Vector3.new(2.4, 0.6, 2.4), Position = canto + Vector3.new(0, 8.3, 0), Color = Color3.fromRGB(45, 40, 40), Parent = pasta })
		end
	end

	-- portão da entrada: dois troncos e a viga
	for _, x in { -1, 1 } do
		parte({ Name = "Portao", Size = Vector3.new(2.6, 11, 2.6), Position = ponto(x * (ENTRADA + 1.3), -meio) + Vector3.new(0, 5.5, 0), Color = MADEIRA_ESCURA, Material = Enum.Material.Wood, Parent = pasta })
		parte({ Name = "Tocha", Size = Vector3.new(1, 1, 1), Position = ponto(x * (ENTRADA + 1.3), -meio - 1.8) + Vector3.new(0, 7, 0), Color = cor:Lerp(Color3.new(1, 1, 1), 0.3), Material = Enum.Material.Neon, CanCollide = false, Parent = pasta })
	end
	parte({ Name = "Viga", Size = Vector3.new(ENTRADA * 2 + 6, 1.4, 1.8), Position = ponto(0, -meio) + Vector3.new(0, 10.4, 0), Color = MADEIRA_ESCURA, Material = Enum.Material.Wood, Parent = pasta })
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
-- brilhos na passagem e duas estátuas do guardião.
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

-- Poste de rua alto, de cidade: pé de concreto, coluna grossa embaixo e
-- fina em cima com anéis, cabeça no topo, um braço com mão-francesa indo
-- para cima da estrada e a luminária (caixa escura com a luz embaixo, que
-- ilumina a rua). No meio, um banner na cor de uma das bases.
-- "paraEstrada" é 1 ou -1: para que lado (Z) fica a estrada.
local CORES_BANNER = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 210, 60), Color3.fromRGB(80, 170, 255), Color3.fromRGB(120, 220, 100) }
local ALTURA_POSTE = 19
local function poste(pasta: Instance, chao: Vector3, paraEstrada: number)
	local HASTE = Color3.fromRGB(38, 44, 52)
	local DETALHE = Color3.fromRGB(205, 170, 90)
	local CONCRETO = Color3.fromRGB(165, 165, 170)
	local h = ALTURA_POSTE
	parte({ Name = "PePoste", Size = Vector3.new(3, 1.2, 3), Position = chao + Vector3.new(0, 0.6, 0), Color = CONCRETO, Parent = pasta })
	parte({ Name = "PePoste", Size = Vector3.new(2.2, 0.8, 2.2), Position = chao + Vector3.new(0, 1.6, 0), Color = CONCRETO:Lerp(Color3.new(1, 1, 1), 0.15), Parent = pasta })
	parte({ Name = "Poste", Size = Vector3.new(1.4, 5, 1.4), Position = chao + Vector3.new(0, 4.5, 0), Color = HASTE, Material = Enum.Material.Metal, Parent = pasta })
	parte({ Name = "Poste", Size = Vector3.new(0.9, h - 7, 0.9), Position = chao + Vector3.new(0, 7 + (h - 7) / 2, 0), Color = HASTE, Material = Enum.Material.Metal, Parent = pasta })
	for _, y in { 7.1, 12, h - 0.4 } do
		parte({ Name = "Anel", Size = Vector3.new(1.6, 0.5, 1.6), Position = chao + Vector3.new(0, y, 0), Color = DETALHE, Material = Enum.Material.Metal, CanCollide = false, Parent = pasta })
	end
	parte({ Name = "TopoPoste", Size = Vector3.new(1.3, 1, 1.3), Position = chao + Vector3.new(0, h + 0.5, 0), Color = HASTE, Material = Enum.Material.Metal, CanCollide = false, Parent = pasta })
	parte({ Name = "PontaPoste", Size = Vector3.new(0.5, 0.8, 0.5), Position = chao + Vector3.new(0, h + 1.4, 0), Color = DETALHE, Material = Enum.Material.Metal, CanCollide = false, Parent = pasta })

	-- banner preso na coluna, virado para quem passa na rua
	local corBanner = escolher(CORES_BANNER)
	parte({ Name = "SuporteBanner", Size = Vector3.new(0.3, 0.3, 2.6), Position = chao + Vector3.new(0, 15.6, -paraEstrada * 1.5), Color = HASTE, Material = Enum.Material.Metal, CanCollide = false, Parent = pasta })
	parte({ Name = "Banner", Size = Vector3.new(0.2, 4.2, 2.2), Position = chao + Vector3.new(0, 13.4, -paraEstrada * 1.7), Color = corBanner, CanCollide = false, Parent = pasta })
	parte({ Name = "FaixaBanner", Size = Vector3.new(0.25, 0.5, 2.2), Position = chao + Vector3.new(0, 12.1, -paraEstrada * 1.7), Color = Color3.new(1, 1, 1), CanCollide = false, Parent = pasta })

	-- braço por cima da rua, com a mão-francesa por baixo
	local comprimento = 5.5
	local yBraco = h - 1.2
	parte({ Name = "Braco", Size = Vector3.new(0.6, 0.6, comprimento), Position = chao + Vector3.new(0, yBraco, paraEstrada * comprimento / 2), Color = HASTE, Material = Enum.Material.Metal, CanCollide = false, Parent = pasta })
	local de = chao + Vector3.new(0, yBraco - 3, paraEstrada * 0.4)
	local ate = chao + Vector3.new(0, yBraco - 0.3, paraEstrada * 3)
	parte({
		Name = "MaoFrancesa",
		Size = Vector3.new(0.35, 0.35, (ate - de).Magnitude),
		CFrame = CFrame.lookAt((de + ate) / 2, ate),
		Color = HASTE,
		Material = Enum.Material.Metal,
		CanCollide = false,
		Parent = pasta,
	}):SetAttribute("ManterForma", true)

	-- luminária na ponta do braço
	local ponta = chao + Vector3.new(0, yBraco, paraEstrada * comprimento)
	parte({ Name = "Luminaria", Size = Vector3.new(1.8, 0.8, 3), Position = ponta + Vector3.new(0, -0.1, 0), Color = HASTE, Material = Enum.Material.Metal, CanCollide = false, Parent = pasta })
	parte({ Name = "TampaLuminaria", Size = Vector3.new(1.4, 0.4, 2.4), Position = ponta + Vector3.new(0, 0.5, 0), Color = DETALHE, Material = Enum.Material.Metal, CanCollide = false, Parent = pasta })
	local lampada = parte({
		Name = "Lampada",
		Size = Vector3.new(1.4, 0.25, 2.5),
		Position = ponta + Vector3.new(0, -0.6, 0),
		Color = Color3.fromRGB(255, 232, 170),
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
		Parent = pasta,
	})
	local luz = Instance.new("SpotLight")
	luz.Face = Enum.NormalId.Bottom
	luz.Angle = 110
	luz.Range = 28
	luz.Brightness = 2
	luz.Color = Color3.fromRGB(255, 220, 160)
	luz.Shadows = false
	luz.Parent = lampada
end

-- Faixa de pedestre (zebra) atravessando a rua em "x".
local function faixaPedestre(pasta: Instance, x: number)
	for z = -5.6, 5.6, 1.6 do
		parte({
			Name = "Zebra",
			Size = Vector3.new(8, 0.06, 0.9),
			Position = Vector3.new(x, 1.03, z),
			Color = Color3.fromRGB(240, 240, 240),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			CastShadow = false,
			Parent = pasta,
		})
	end
end

local function decorarEstrada(pasta: Instance, biomas: { Mapa.InfoBioma })
	-- Meio-fio, faixas e postes só na estrada até a Selva Sahur: entre os
	-- biomas não tem rua (veja Mapa.construir).
	local a, b = Mapa.INICIO_ESTRADA, biomas[1].centro.X - Mapa.TAMANHO_BIOMA / 2

	-- meio-fio alto, com a guia branca e uma faixa cinza por cima
	for _, lado in { -1, 1 } do
		parte({ Name = "Meiofio", Size = Vector3.new(b - a, 0.6, 1), Position = Vector3.new((a + b) / 2, 1.2, lado * 7.5), Color = Color3.fromRGB(225, 225, 230), Material = Enum.Material.SmoothPlastic, Parent = pasta })
		parte({ Name = "Sarjeta", Size = Vector3.new(b - a, 0.08, 0.6), Position = Vector3.new((a + b) / 2, 1.03, lado * 6.7), Color = Color3.fromRGB(95, 95, 105), Material = Enum.Material.SmoothPlastic, CanCollide = false, CastShadow = false, Parent = pasta })
		-- linha branca contínua da borda
		parte({ Name = "LinhaBorda", Size = Vector3.new(b - a, 0.06, 0.35), Position = Vector3.new((a + b) / 2, 1.04, lado * 5.9), Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.SmoothPlastic, CanCollide = false, CastShadow = false, Parent = pasta })
	end
	-- faixa dupla amarela tracejada no meio
	for x = a + 6, b - 4, 9 do
		for _, z in { -0.35, 0.35 } do
			parte({
				Name = "Faixa",
				Size = Vector3.new(5, 0.06, 0.35),
				Position = Vector3.new(x, 1.04, z),
				Color = Color3.fromRGB(255, 210, 60),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				CastShadow = false,
				Parent = pasta,
			})
		end
	end
	-- faixa de pedestre na frente do caminho de cada base
	for i = -1, 1 do
		faixaPedestre(pasta, i * Mapa.ESPACO_BASES)
	end

	-- postes dos dois lados, alternados, sem ficar na frente dos caminhos,
	-- das esteiras, dos portais nem dentro do túnel
	local ladoPoste = 1
	for x = math.max(a + 10, TUNEL_BOCA + 10), b - 18, 30 do
		local baseMaisPerto = math.round(x / Mapa.ESPACO_BASES) * Mapa.ESPACO_BASES
		local naFrenteDeBase = x < Mapa.FIM_BASES and math.abs(baseMaisPerto) <= Mapa.ESPACO_BASES and math.abs(x - baseMaisPerto) < 32
		if not naFrenteDeBase then
			local z = ladoPoste * 10
			ladoPoste = -ladoPoste
			poste(pasta, Vector3.new(x, 0.05, z), -math.sign(z))
		end
	end

	tunel(pasta)
end

local function decorarFloresta(info: Mapa.InfoBioma)
	local pasta = Instance.new("Folder")
	pasta.Name = "Decoracao"
	pasta.Parent = info.pasta
	local centro = info.centro + Vector3.new(0, 0.05, 0)
	local meio = Mapa.TAMANHO_BIOMA / 2 - 2
	local canto = Vector3.new(meio, 0, meio)

	-- trilha de terra passando pelos ninhos
	local piso = info.pasta:FindFirstChild("Piso") :: BasePart
	disco(pasta, centro, "Trilha", 37, 0.08, 0.5, {
		Color = Color3.fromRGB(150, 115, 75),
		Material = Enum.Material.Ground,
	})
	disco(pasta, centro, "Clareira", 27, 0.12, 0.5, {
		Color = piso.Color,
		Material = Enum.Material.Grass,
	})

	-- árvores só fora do anel de ninhos e longe da passagem da estrada
	espalhar(centro - canto, centro + canto, 24, function(p)
		local d = distanciaPlana(p, centro)
		return d > 41 and math.abs(p.Z - centro.Z) > 11
	end, function(p)
		if aleatorio:NextNumber() < 0.6 and arvoreBiblioteca(pasta, p, "Floresta", 1) then
			return
		end
		if aleatorio:NextNumber() < 0.3 then
			pinheiro(pasta, p, aleatorio:NextNumber(0.8, 1.1))
		else
			arvore(pasta, p, aleatorio:NextNumber(0.8, 1.2), FOLHAS)
		end
	end)
	espalhar(centro - canto, centro + canto, 18, function(p)
		local d = distanciaPlana(p, centro)
		return (d > 38 or (d > 13 and d < 24)) and math.abs(p.Z - centro.Z) > 6
	end, function(p)
		arbusto(pasta, p, aleatorio:NextNumber(0.8, 1.2))
	end)
	espalhar(centro - canto, centro + canto, 60, function(p)
		local d = distanciaPlana(p, centro)
		return d > 8 and math.abs(d - 32) > 4
	end, function(p)
		flor(pasta, p)
	end)
	espalhar(centro - canto, centro + canto, 10, function(p)
		return distanciaPlana(p, centro) > 40
	end, function(p)
		pedra(pasta, p, aleatorio:NextNumber(2, 4), true)
	end)

	local m = Mapa.TAMANHO_BIOMA / 2 - 0.5
	local function ponto(x: number, z: number): Vector3
		return centro + Vector3.new(x, 0, z)
	end
	cerca(pasta, ponto(-m, -m), ponto(m, -m))
	cerca(pasta, ponto(-m, m), ponto(m, m))
	for _, x in { -m, m } do
		cerca(pasta, ponto(x, -m), ponto(x, -10))
		cerca(pasta, ponto(x, 10), ponto(x, m))
	end
end

local function decorarLago(info: Mapa.InfoBioma)
	local pasta = Instance.new("Folder")
	pasta.Name = "Decoracao"
	pasta.Parent = info.pasta
	local centro = info.centro + Vector3.new(0, 0.05, 0)
	local RAIO_LAGO = 21

	-- o Lago vira uma praia: piso de areia e areia molhada na beira da água
	local piso = info.pasta:FindFirstChild("Piso") :: BasePart
	piso.Color = Color3.fromRGB(235, 215, 160)
	piso.Material = Enum.Material.Sand
	disco(pasta, centro, "AreiaMolhada", RAIO_LAGO + 4, 0.1, 0.5, {
		Color = Color3.fromRGB(205, 180, 125),
		Material = Enum.Material.Sand,
	})
	disco(pasta, centro, "Fundo", RAIO_LAGO, 0.15, 0.5, {
		Color = Color3.fromRGB(35, 95, 150),
		Material = Enum.Material.SmoothPlastic,
	})
	-- água rasa: dá para atravessar andando
	disco(pasta, centro, "Agua", RAIO_LAGO, 0.65, 0.45, {
		Color = Color3.fromRGB(70, 170, 235),
		Material = Enum.Material.Glass,
		Transparency = 0.35,
		Reflectance = 0.15,
		CanCollide = false,
		CastShadow = false,
	})

	-- barbatanas de tubarão (do Tralalero Tralala) saindo da água
	for i, graus in { 30, 150, 260 } do
		local angulo = math.rad(graus)
		local raio = 10 + i * 2
		local ponto = centro + Vector3.new(math.cos(angulo) * raio, 0.65, math.sin(angulo) * raio)
		parte({
			Name = "Barbatana",
			Size = Vector3.new(0.5, 2.4, 2.4),
			CFrame = CFrame.lookAt(ponto, ponto + Vector3.new(-math.sin(angulo), 0, math.cos(angulo)))
				* CFrame.Angles(math.rad(45), 0, 0),
			Color = Color3.fromRGB(85, 115, 145),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = pasta,
		})
	end

	-- vitórias-régias
	for i = 1, 10 do
		local angulo = i / 10 * math.pi * 2 + aleatorio:NextNumber(-0.2, 0.2)
		local raio = aleatorio:NextNumber(8, RAIO_LAGO - 3)
		parte({
			Name = "Folha",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.1, 2.6, 2.6),
			CFrame = CFrame.new(centro + Vector3.new(math.cos(angulo) * raio, 0.68, math.sin(angulo) * raio))
				* CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(70, 160, 70),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			CastShadow = false,
			Parent = pasta,
		})
	end
	-- juncos e pedras na beira da água
	for i = 1, 36 do
		local angulo = i / 36 * math.pi * 2 + aleatorio:NextNumber(-0.08, 0.08)
		local raio = RAIO_LAGO + aleatorio:NextNumber(-1, 2)
		local p = centro + Vector3.new(math.cos(angulo) * raio, 0.1, math.sin(angulo) * raio)
		if i % 4 == 0 then
			pedra(pasta, p, aleatorio:NextNumber(1.2, 2.2), false)
		else
			local altura = aleatorio:NextNumber(2.5, 4.5)
			parte({
				Name = "Junco",
				Size = Vector3.new(0.3, altura, 0.3),
				CFrame = CFrame.new(p + Vector3.new(0, altura / 2, 0)) * CFrame.Angles(aleatorio:NextNumber(-0.2, 0.2), 0, aleatorio:NextNumber(-0.2, 0.2)),
				Color = Color3.fromRGB(90, 140, 60),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				CastShadow = false,
				Parent = pasta,
			})
		end
	end

	local meio = Mapa.TAMANHO_BIOMA / 2 - 3
	local canto = Vector3.new(meio, 0, meio)
	espalhar(centro - canto, centro + canto, 14, function(p)
		return distanciaPlana(p, centro) > 41 and math.abs(p.Z - centro.Z) > 11
	end, function(p)
		if aleatorio:NextNumber() < 0.6 and arvoreBiblioteca(pasta, p, "Praia", 1) then
			return
		end
		palmeira(pasta, p, aleatorio:NextNumber(0.85, 1.15))
	end)
	espalhar(centro - canto, centro + canto, 10, function(p)
		return distanciaPlana(p, centro) > 40
	end, function(p)
		pedra(pasta, p, aleatorio:NextNumber(2, 4.5), true)
	end)
	espalhar(centro - canto, centro + canto, 40, function(p)
		local d = distanciaPlana(p, centro)
		return d > RAIO_LAGO + 6 and math.abs(d - 32) > 4
	end, function(p)
		flor(pasta, p)
	end)
end

-- Partes comuns dos biomas novos ---------------------------------------------

-- Troca a cor e o material do piso do bioma.
local function pintarPiso(info: Mapa.InfoBioma, cor: Color3, material: Enum.Material)
	local piso = info.pasta:FindFirstChild("Piso") :: BasePart
	piso.Color = cor
	piso.Material = material
end

-- Ponto livre para enfeite grande: fora do anel de ninhos e longe da estrada.
local function foraDoAnel(centro: Vector3)
	return function(p: Vector3): boolean
		return distanciaPlana(p, centro) > 41 and math.abs(p.Z - centro.Z) > 11
	end
end

-- Faz a peça girar e flutuar (o cliente anima tudo com a tag "GirarEsteira").
local function girarNoCliente(p: BasePart, graus: number, flutua: number)
	p:SetAttribute("Giro", graus)
	p:SetAttribute("Flutua", flutua)
	CollectionService:AddTag(p, "GirarEsteira")
end

local function emissor(parent: Instance, props): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for chave, valor in props do
		(e :: any)[chave] = valor
	end
	e.Parent = parent
	return e
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

-- Morro de pedra em degraus (mesa do deserto, cratera do vulcão).
local function morro(pasta: Instance, chao: Vector3, largura: number, altura: number, cores: { Color3 })
	local andares = 3
	for andar = 0, andares - 1 do
		local w = largura * (1 - andar * 0.25)
		local h = altura / andares
		parte({
			Name = "Morro",
			Size = Vector3.new(w, h, w * aleatorio:NextNumber(0.8, 1)),
			CFrame = CFrame.new(chao + Vector3.new(0, h * andar + h / 2, 0)) * CFrame.Angles(0, aleatorio:NextNumber(0, 0.4), 0),
			Color = cores[andar % #cores + 1],
			Parent = pasta,
		})
	end
end

-- Deserto Frigo: areia, dunas, cactos, mesas de pedra e um oásis -----------

local function decorarDeserto(info: Mapa.InfoBioma)
	local pasta = Instance.new("Folder")
	pasta.Name = "Decoracao"
	pasta.Parent = info.pasta
	local centro = info.centro + Vector3.new(0, 0.05, 0)
	local meio = Mapa.TAMANHO_BIOMA / 2 - 3
	local canto = Vector3.new(meio, 0, meio)
	local livre = foraDoAnel(centro)

	pintarPiso(info, Color3.fromRGB(235, 200, 130), Enum.Material.Sand)
	disco(pasta, centro, "Trilha", 37, 0.08, 0.5, { Color = Color3.fromRGB(210, 170, 100), Material = Enum.Material.Sand })
	disco(pasta, centro, "Clareira", 27, 0.12, 0.5, { Color = Color3.fromRGB(240, 210, 145), Material = Enum.Material.Sand })

	-- oásis no meio, onde fica o guardião
	disco(pasta, centro, "Oasis", 7, 0.3, 0.3, {
		Color = Color3.fromRGB(70, 180, 220),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
		CanCollide = false,
		CastShadow = false,
	})

	espalhar(centro - canto, centro + canto, 10, livre, function(p)
		-- duna: blocos baixos e largos
		parte({
			Name = "Duna",
			Size = Vector3.new(aleatorio:NextNumber(10, 16), aleatorio:NextNumber(1.5, 3), aleatorio:NextNumber(6, 9)),
			CFrame = CFrame.new(p) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi), 0),
			Color = Color3.fromRGB(230, 195, 125):Lerp(Color3.fromRGB(245, 215, 150), aleatorio:NextNumber()),
			Parent = pasta,
		})
	end)
	espalhar(centro - canto, centro + canto, 16, livre, function(p)
		cacto(pasta, p, aleatorio:NextNumber(0.8, 1.2))
	end)
	espalhar(centro - canto, centro + canto, 4, livre, function(p)
		morro(pasta, p, aleatorio:NextNumber(9, 13), aleatorio:NextNumber(8, 12), {
			Color3.fromRGB(200, 110, 70),
			Color3.fromRGB(220, 140, 90),
			Color3.fromRGB(185, 95, 60),
		})
	end)
	-- cactinhos baixos e ossos entre os ninhos
	espalhar(centro - canto, centro + canto, 30, function(p)
		local d = distanciaPlana(p, centro)
		return d > 9 and math.abs(d - 32) > 4
	end, function(p)
		if aleatorio:NextNumber() < 0.5 then
			cacto(pasta, p, 0.4)
		else
			parte({ Name = "Osso", Size = Vector3.new(2, 0.4, 0.4), CFrame = CFrame.new(p + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi), 0), Color = Color3.fromRGB(245, 240, 225), CanCollide = false, Parent = pasta })
		end
	end)
end

-- Vulcão Toasterino: chão de pedra escura, rios de lava, vulcão soltando
-- fumaça e árvores queimadas ------------------------------------------------

local function decorarVulcao(info: Mapa.InfoBioma)
	local pasta = Instance.new("Folder")
	pasta.Name = "Decoracao"
	pasta.Parent = info.pasta
	local centro = info.centro + Vector3.new(0, 0.05, 0)
	local meio = Mapa.TAMANHO_BIOMA / 2 - 3
	local canto = Vector3.new(meio, 0, meio)
	local livre = foraDoAnel(centro)
	local LAVA = Color3.fromRGB(255, 110, 30)

	pintarPiso(info, Color3.fromRGB(60, 45, 45), Enum.Material.Basalt)
	disco(pasta, centro, "Trilha", 37, 0.08, 0.5, { Color = Color3.fromRGB(85, 65, 60), Material = Enum.Material.Slate })
	disco(pasta, centro, "Clareira", 27, 0.12, 0.5, { Color = Color3.fromRGB(70, 52, 50), Material = Enum.Material.Basalt })

	-- rios de lava saindo dos cantos (só enfeite: não machucam)
	for _, canto2 in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
		local de = centro + canto2 * (Mapa.TAMANHO_BIOMA / 2 - 4)
		local ate = centro + canto2 * 26
		local acima = Vector3.new(0, 0.12, 0)
		local rio = parte({
			Name = "Lava",
			Size = Vector3.new(3, 0.2, (ate - de).Magnitude),
			CFrame = CFrame.lookAt((de + ate) / 2 + acima, ate + acima),
			Color = LAVA,
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
			Parent = pasta,
		})
		CollectionService:AddTag(rio, "PulsarEsteira")
		emissor(rio, {
			Texture = "rbxasset://textures/particles/fire_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), LAVA),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
			Lifetime = NumberRange.new(0.6, 1.2),
			Rate = 6,
			Speed = NumberRange.new(2, 5),
			LightEmission = 1,
		})
	end

	-- o vulcão no canto de trás, com lava no topo e fumaça
	local pe = centro + Vector3.new(Mapa.TAMANHO_BIOMA / 2 - 14, 0, -(Mapa.TAMANHO_BIOMA / 2 - 14))
	morro(pasta, pe, 22, 20, { Color3.fromRGB(80, 60, 55), Color3.fromRGB(65, 50, 48), Color3.fromRGB(95, 70, 60) })
	local cratera = parte({
		Name = "Cratera",
		Size = Vector3.new(6, 0.6, 6),
		Position = pe + Vector3.new(0, 20.2, 0),
		Color = LAVA,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = pasta,
	})
	CollectionService:AddTag(cratera, "PulsarEsteira")
	emissor(cratera, {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(70, 60, 60)),
		Transparency = NumberSequence.new(0.3, 1),
		Size = NumberSequence.new(4, 12),
		Lifetime = NumberRange.new(4, 6),
		Rate = 5,
		Speed = NumberRange.new(4, 7),
		SpreadAngle = Vector2.new(15, 15),
	})
	emissor(cratera, {
		Texture = "rbxasset://textures/particles/fire_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), LAVA),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(1, 2),
		Rate = 14,
		Speed = NumberRange.new(10, 18),
		SpreadAngle = Vector2.new(25, 25),
		Acceleration = Vector3.new(0, -20, 0),
		LightEmission = 1,
	})
	local luz = Instance.new("PointLight")
	luz.Color = LAVA
	luz.Range = 30
	luz.Brightness = 2
	luz.Parent = cratera

	espalhar(centro - canto, centro + canto, 14, livre, function(p)
		-- árvore queimada: tronco preto torto com galhos
		local altura = aleatorio:NextNumber(5, 8)
		local giro = CFrame.new(p) * CFrame.Angles(aleatorio:NextNumber(-0.15, 0.15), aleatorio:NextNumber(0, math.pi), 0)
		parte({ Name = "Queimada", Size = Vector3.new(1.2, altura, 1.2), CFrame = giro * CFrame.new(0, altura / 2, 0), Color = Color3.fromRGB(35, 30, 30), Parent = pasta })
		for _, x in { -1, 1 } do
			parte({ Name = "Galho", Size = Vector3.new(2.4, 0.5, 0.5), CFrame = giro * CFrame.new(x * 1.2, altura * 0.75, 0) * CFrame.Angles(0, 0, math.rad(x * 30)), Color = Color3.fromRGB(45, 38, 36), CanCollide = false, Parent = pasta })
		end
	end)
	espalhar(centro - canto, centro + canto, 12, livre, function(p)
		pedra(pasta, p, aleatorio:NextNumber(2, 4.5), true)
	end)
	-- brasas brilhando no chão entre os ninhos
	espalhar(centro - canto, centro + canto, 24, function(p)
		local d = distanciaPlana(p, centro)
		return d > 9 and math.abs(d - 32) > 4
	end, function(p)
		parte({ Name = "Brasa", Size = Vector3.new(0.8, 0.3, 0.8), Position = p + Vector3.new(0, 0.15, 0), Color = LAVA, Material = Enum.Material.Neon, CanCollide = false, CastShadow = false, Parent = pasta })
	end)
end

-- Espaço Saturnita: chão roxo de lua, crateras, cristais de neon, pedras e
-- planetinhas flutuando e estrelas ------------------------------------------

local function decorarEspaco(info: Mapa.InfoBioma)
	local pasta = Instance.new("Folder")
	pasta.Name = "Decoracao"
	pasta.Parent = info.pasta
	local centro = info.centro + Vector3.new(0, 0.05, 0)
	local meio = Mapa.TAMANHO_BIOMA / 2 - 3
	local canto = Vector3.new(meio, 0, meio)
	local livre = foraDoAnel(centro)
	local CRISTAIS = { Color3.fromRGB(80, 220, 255), Color3.fromRGB(200, 90, 255), Color3.fromRGB(255, 90, 200) }

	pintarPiso(info, Color3.fromRGB(55, 45, 90), Enum.Material.Slate)
	disco(pasta, centro, "Trilha", 37, 0.08, 0.5, { Color = Color3.fromRGB(85, 75, 130), Material = Enum.Material.Slate })
	disco(pasta, centro, "Clareira", 27, 0.12, 0.5, { Color = Color3.fromRGB(65, 55, 105), Material = Enum.Material.Slate })

	-- crateras: anel de pedra com o fundo escuro
	espalhar(centro - canto, centro + canto, 8, livre, function(p)
		local raio = aleatorio:NextNumber(3, 6)
		disco(pasta, p, "Cratera", raio + 1, 0.6, 0.6, { Color = Color3.fromRGB(110, 100, 150) })
		disco(pasta, p, "FundoCratera", raio, 0.65, 0.2, { Color = Color3.fromRGB(35, 28, 60) })
	end)
	-- cristais de neon saindo do chão
	espalhar(centro - canto, centro + canto, 18, livre, function(p)
		local cor = escolher(CRISTAIS)
		local cristal: BasePart? = nil
		for i = 1, aleatorio:NextInteger(2, 4) do
			local altura = aleatorio:NextNumber(2, 6)
			cristal = parte({
				Name = "Cristal",
				Size = Vector3.new(1, altura, 1),
				CFrame = CFrame.new(p + Vector3.new(aleatorio:NextNumber(-1, 1), altura / 2 - 0.3, aleatorio:NextNumber(-1, 1)))
					* CFrame.Angles(aleatorio:NextNumber(-0.4, 0.4), i, aleatorio:NextNumber(-0.4, 0.4)),
				Color = cor,
				Material = Enum.Material.Neon,
				Transparency = 0.15,
				CastShadow = false,
				Parent = pasta,
			})
		end
		local luz = Instance.new("PointLight")
		luz.Color = cor
		luz.Range = 10
		luz.Brightness = 1.2
		luz.Parent = cristal
	end)
	-- pedras e planetinhas flutuando e girando
	espalhar(centro - canto + Vector3.new(0, 10, 0), centro + canto + Vector3.new(0, 10, 0), 10, livre, function(p)
		local tamanho = aleatorio:NextNumber(2, 4)
		local pedraVoando = parte({
			Name = "PedraVoando",
			Size = Vector3.one * tamanho,
			CFrame = CFrame.new(p + Vector3.new(0, aleatorio:NextNumber(0, 10), 0)) * CFrame.Angles(0.5, 0.5, 0),
			Color = Color3.fromRGB(120, 110, 160),
			CanCollide = false,
			Parent = pasta,
		})
		girarNoCliente(pedraVoando, aleatorio:NextNumber(15, 40), aleatorio:NextNumber(0.6, 1.4))
	end)
	for i, cor in { Color3.fromRGB(255, 160, 90), Color3.fromRGB(110, 200, 255) } do
		local lado = if i == 1 then 1 else -1
		local planeta = parte({
			Name = "Planeta",
			Size = Vector3.one * (8 + i * 3),
			Position = centro + Vector3.new(lado * 30, 34 + i * 6, -lado * 30),
			Color = cor,
			CanCollide = false,
			CastShadow = false,
			Parent = pasta,
		})
		girarNoCliente(planeta, 10 * lado, 2)
	end
	-- estrelas piscando no céu do bioma
	local ceu = parte({
		Name = "Estrelas",
		Size = Vector3.new(Mapa.TAMANHO_BIOMA, 1, Mapa.TAMANHO_BIOMA),
		Position = centro + Vector3.new(0, 45, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = pasta,
	})
	emissor(ceu, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(180, 200, 255)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(2, 4),
		Rate = 25,
		Speed = NumberRange.new(0, 0.5),
		LightEmission = 1,
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
end

-- Transição entre um bioma e o próximo: um chão de blocos de parede a
-- parede que vai misturando o piso dos dois como pixels (perto de um, quase
-- tudo dele; no meio, metade de cada). Depois do último bioma, só o piso dele.
local BLOCO_TRANSICAO = 5
local function transicoes(pasta: Instance, biomas: { Mapa.InfoBioma })
	for i, info in biomas do
		local proximo = biomas[i + 1]
		local de = info.centro.X + Mapa.TAMANHO_BIOMA / 2
		local ate = if proximo then proximo.centro.X - Mapa.TAMANHO_BIOMA / 2 else Mapa.FIM_ESTRADA + 14
		local pisoA = info.pasta:FindFirstChild("Piso") :: BasePart
		local pisoB = if proximo then proximo.pasta:FindFirstChild("Piso") :: BasePart else pisoA
		local colunas = math.max(1, math.round((ate - de) / BLOCO_TRANSICAO))
		local passo = (ate - de) / colunas
		local largura = Mapa.Z_PAREDE * 2
		local linhas = math.round(largura / BLOCO_TRANSICAO)
		local passoZ = largura / linhas
		for c = 0, colunas - 1 do
			local t = (c + 0.5) / colunas
			local chance = t * t * (3 - 2 * t) -- suave nas pontas
			for l = 0, linhas - 1 do
				local piso = if aleatorio:NextNumber() < chance then pisoB else pisoA
				parte({
					Name = "Transicao",
					Size = Vector3.new(passo, 1.3, passoZ),
					Position = Vector3.new(de + (c + 0.5) * passo, info.centro.Y - 0.6, -largura / 2 + (l + 0.5) * passoZ),
					Color = escurecer(piso.Color, aleatorio:NextNumber(0, 0.08)),
					Material = piso.Material,
					Parent = pasta,
				})
			end
		end
	end
end

-- Árvores, arbustos e pedras nos cantos livres entre as montanhas, fora
-- das áreas de jogo.
local function decorarArredores(pasta: Instance, biomas: { Mapa.InfoBioma })
	local fim = Mapa.INICIO_BIOMAS + #biomas * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
	local function livre(p: Vector3): boolean
		if math.abs(p.Z) < 16 then
			return false -- estrada e postes
		end
		-- dentro das montanhas
		if p.X < Mapa.TUNEL_BOCA + 6 or p.X > fim + 8 then
			return false
		end
		if p.X < Montanhas.TRANSICAO and math.abs(p.Z) > Montanhas.Z_BASES - 5 then
			return false
		end
		if p.X >= Montanhas.TRANSICAO - 6 and math.abs(p.Z) > Montanhas.Z_FASES - 4 then
			return false
		end
		local limiteBases = Mapa.ESPACO_BASES + Mapa.TAMANHO_BASE / 2 + 6
		if math.abs(p.X) < limiteBases and math.abs(p.Z) < Mapa.Z_BASES + Mapa.TAMANHO_BASE / 2 + 6 then
			return false -- bases, esteiras e caminhos
		end
		if p.X < Mapa.TUNEL_BOCA + 30 and math.abs(p.Z) < 48 then
			return false -- túnel da entrada
		end
		for _, bioma in biomas do
			if math.abs(p.X - bioma.centro.X) < 60 and math.abs(p.Z) < 60 then
				return false
			end
			-- nada no chão de transição entre os biomas (fica mais alto)
			if p.X > Mapa.FIM_BASES and math.abs(p.Z) < Mapa.Z_PAREDE + 3 then
				return false
			end
			-- nada na frente da placa amarela de atenção (veja placaAviso)
			local portal = bioma.centro.X - Mapa.TAMANHO_BIOMA / 2
			if p.X > portal - 50 and p.X < portal + 2 and p.Z < -6 and p.Z > -45 then
				return false
			end
		end
		return true
	end
	local minimo = Vector3.new(Montanhas.INICIO, 0.05, -Montanhas.Z_BASES)
	local maximo = Vector3.new(fim + 10, 0.05, Montanhas.Z_BASES)
	espalhar(minimo, maximo, 45, livre, function(p)
		if aleatorio:NextNumber() < 0.6 and arvoreBiblioteca(pasta, p, "Floresta", 1.1) then
			return
		end
		if aleatorio:NextNumber() < 0.35 then
			pinheiro(pasta, p, aleatorio:NextNumber(0.9, 1.4))
		else
			arvore(pasta, p, aleatorio:NextNumber(0.9, 1.5), FOLHAS)
		end
	end)
	espalhar(minimo, maximo, 30, livre, function(p)
		arbusto(pasta, p, aleatorio:NextNumber(0.9, 1.4))
	end)
	espalhar(minimo, maximo, 14, livre, function(p)
		pedra(pasta, p, aleatorio:NextNumber(2.5, 5), true)
	end)
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
	local inicio = Montanhas.INICIO - 64 -- montanha do começo
	local transicao = Montanhas.TRANSICAO
	local fimEstrada = Mapa.FIM_ESTRADA + 14 + 62 -- montanha do fim
	local zBases = Montanhas.Z_BASES + 66 -- montanhas atrás das bases
	local zFases = Mapa.Z_PAREDE + 8 -- nos biomas não tem montanha: o chão vai até as paredes
	for _, area in {
		{ de = inicio, ate = transicao + 60, z = zBases }, -- bases (e o degrau até a estrada das fases)
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

	decorarEstrada(pasta, biomas)
	Montanhas.construir()
	Paredes.construir(biomas)
	decorarArredores(pasta, biomas)
	for _, info in bases do
		decorarBase(info)
	end
	for _, info in biomas do
		local estilo = info.config.estilo
		if estilo == "praia" then
			decorarLago(info)
		elseif estilo == "deserto" then
			decorarDeserto(info)
		elseif estilo == "vulcao" then
			decorarVulcao(info)
		elseif estilo == "espaco" then
			decorarEspaco(info)
		else
			decorarFloresta(info)
		end
		decorarPortal(info)
	end
	-- depois das decorações, que trocam a cor e o material dos pisos
	transicoes(pasta, biomas)

	pasta.Parent = Workspace

	-- tudo no estilo Lego (o que for criado depois nessas pastas também)
	for _, nome in { "Mapa", "Decoracao", "Montanhas", "Paredes" } do
		local raiz = Workspace:FindFirstChild(nome)
		if raiz then
			Blocos.vigiar(raiz)
		end
	end
end

return Decoracao

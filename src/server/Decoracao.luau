-- Decoração do mapa: céu e iluminação, chão de grama, árvores, o lago,
-- cercas das bases, postes da estrada, o túnel da entrada e os portais
-- dos biomas. Só enfeite: nada aqui muda
-- as regras do jogo. O sorteio usa sempre a mesma semente, então o
-- mapa fica igual toda vez.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Biblioteca = require(script.Parent.Biblioteca)
local Blocos = require(script.Parent.Blocos)
local Guardioes = require(script.Parent.Guardioes)
local Mapa = require(script.Parent.Mapa)
local Montanhas = require(script.Parent.Montanhas)

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

local function texto(parent: BasePart, face: Enum.NormalId, conteudo: string, cor: Color3)
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
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = cor
	label.Text = conteudo
	local contorno = Instance.new("UIStroke")
	contorno.Thickness = 4
	contorno.Color = Color3.fromRGB(40, 30, 60)
	contorno.Parent = label
	label.Parent = gui
end

local function decorarBase(info: Mapa.InfoBase)
	local pasta = Instance.new("Folder")
	pasta.Name = "Decoracao"
	pasta.Parent = info.pasta

	local meio = Mapa.TAMANHO_BASE / 2
	local topo = info.centro
	local lado = info.lado
	local cor = info.piso.Color
	local BRANCO = Color3.fromRGB(240, 240, 245)

	-- muros nos fundos e dos lados; o lado da estrada fica aberto
	parte({
		Name = "Muro",
		Size = Vector3.new(Mapa.TAMANHO_BASE, 3, 1),
		Position = topo + Vector3.new(0, 1.5, lado * (meio - 0.5)),
		Color = BRANCO,
		Material = Enum.Material.SmoothPlastic,
		Parent = pasta,
	})
	for _, x in { -1, 1 } do
		parte({
			Name = "Muro",
			Size = Vector3.new(1, 3, Mapa.TAMANHO_BASE),
			Position = topo + Vector3.new(x * (meio - 0.5), 1.5, 0),
			Color = BRANCO,
			Material = Enum.Material.SmoothPlastic,
			Parent = pasta,
		})
		for _, z in { -1, 1 } do
			local canto = topo + Vector3.new(x * (meio - 0.5), 0, z * (meio - 0.5))
			parte({
				Name = "Pilar",
				Size = Vector3.new(2, 4.5, 2),
				Position = canto + Vector3.new(0, 2.25, 0),
				Color = escurecer(cor, 0.2),
				Material = Enum.Material.SmoothPlastic,
				Parent = pasta,
			})
			parte({
				Name = "Luz",
				Size = Vector3.new(2.3, 0.5, 2.3),
				Position = canto + Vector3.new(0, 4.7, 0),
				Color = cor,
				Material = Enum.Material.Neon,
				Parent = pasta,
			})
		end
	end

	-- faixa de neon em cima dos muros, na cor da base
	parte({
		Name = "Neon",
		Size = Vector3.new(Mapa.TAMANHO_BASE, 0.4, 1.2),
		Position = topo + Vector3.new(0, 3.2, lado * (meio - 0.5)),
		Color = cor:Lerp(Color3.new(1, 1, 1), 0.2),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = pasta,
	})
	for _, x in { -1, 1 } do
		parte({
			Name = "Neon",
			Size = Vector3.new(1.2, 0.4, Mapa.TAMANHO_BASE),
			Position = topo + Vector3.new(x * (meio - 0.5), 3.2, 0),
			Color = cor:Lerp(Color3.new(1, 1, 1), 0.2),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = pasta,
		})
	end

	-- placa com o número da base, em cima do muro dos fundos, virada para a estrada
	local placa = parte({
		Name = "Placa",
		Size = Vector3.new(14, 4, 0.6),
		Position = topo + Vector3.new(0, 6, lado * (meio - 0.5)),
		Color = escurecer(cor, 0.15),
		Material = Enum.Material.SmoothPlastic,
		Parent = pasta,
	})
	texto(placa, if lado == 1 then Enum.NormalId.Front else Enum.NormalId.Back, info.pasta.Name:gsub("Base", "BASE "), Color3.new(1, 1, 1))
end

-- Põe um modelo em pé num ponto do chão, olhando para "olhar", e ancora tudo.
local function plantar(modelo: Model, pasta: Instance, chao: Vector3, olhar: Vector3, escala: number)
	modelo:ScaleTo(modelo:GetScale() * escala)
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
		end
	end
	local caixa, tamanho = modelo:GetBoundingBox()
	local pes = caixa.Position - Vector3.new(0, tamanho.Y / 2, 0)
	modelo:PivotTo(modelo:GetPivot() + (Vector3.zero - pes))
	local giro = CFrame.lookAt(Vector3.zero, Vector3.new(olhar.X, 0, olhar.Z))
	modelo:PivotTo(CFrame.new(chao) * giro * modelo:GetPivot())
	modelo.Parent = pasta
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

-- Portal de cada bioma: arco com neon, o nome em cima, brilhos e duas
-- estátuas do guardião do bioma, uma de cada lado.
local function decorarPortal(info: Mapa.InfoBioma)
	local pasta = Instance.new("Folder")
	pasta.Name = "DecoracaoPortal"
	pasta.Parent = info.pasta
	local x = info.centro.X - Mapa.TAMANHO_BIOMA / 2
	local cor = info.config.cor
	local escura = escurecer(cor, 0.35)

	for _, z in { -11.5, 11.5 } do
		parte({
			Name = "Pilar",
			Size = Vector3.new(3, 20, 3),
			Position = Vector3.new(x, 10.5, z),
			Color = escura,
			Material = Enum.Material.SmoothPlastic,
			Parent = pasta,
		})
		for y = 4, 16, 4 do
			parte({
				Name = "Listra",
				Size = Vector3.new(3.3, 0.5, 3.3),
				Position = Vector3.new(x, y, z),
				Color = cor:Lerp(Color3.new(1, 1, 1), 0.3),
				Material = Enum.Material.Neon,
				Parent = pasta,
			})
		end
	end
	local viga = parte({
		Name = "Viga",
		Size = Vector3.new(3.4, 4, 27),
		Position = Vector3.new(x, 22, 0),
		Color = escura,
		Material = Enum.Material.SmoothPlastic,
		Parent = pasta,
	})
	parte({
		Name = "VigaNeon",
		Size = Vector3.new(3.6, 0.5, 27.4),
		Position = Vector3.new(x, 19.9, 0),
		Color = cor:Lerp(Color3.new(1, 1, 1), 0.3),
		Material = Enum.Material.Neon,
		Parent = pasta,
	})
	texto(viga, Enum.NormalId.Left, string.upper(info.config.nome), Color3.new(1, 1, 1))
	texto(viga, Enum.NormalId.Right, string.upper(info.config.nome), Color3.new(1, 1, 1))

	local portal = info.pasta:FindFirstChild("Portal")
	if portal then
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

	-- estátuas do guardião, olhando para quem chega pela estrada
	for _, z in { -18, 18 } do
		local estatua = Guardioes.estatua(info.config.guardiao)
		estatua.Name = "EstatuaGuardiao"
		plantar(estatua, pasta, Vector3.new(x - 5, 0.05, z), -Vector3.xAxis, 0.8)
	end
end

local function decorarEstrada(pasta: Instance, biomas: { Mapa.InfoBioma })
	local fim = Mapa.INICIO_BIOMAS + #biomas * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
	-- trechos de estrada à mostra (dentro dos biomas o piso cobre a estrada)
	local trechos = {}
	local inicio = Mapa.INICIO_ESTRADA
	for _, bioma in biomas do
		local comeco = bioma.centro.X - Mapa.TAMANHO_BIOMA / 2
		table.insert(trechos, { inicio, comeco })
		inicio = comeco + Mapa.TAMANHO_BIOMA
	end
	table.insert(trechos, { inicio, fim })

	local ladoPoste = 1
	for _, trecho in trechos do
		local a, b = trecho[1], trecho[2]
		for _, z in { -7.4, 7.4 } do
			parte({
				Name = "Meiofio",
				Size = Vector3.new(b - a, 0.4, 0.8),
				Position = Vector3.new((a + b) / 2, 1.2, z),
				Color = Color3.fromRGB(230, 230, 235),
				Material = Enum.Material.SmoothPlastic,
				Parent = pasta,
			})
		end
		for x = a + 6, b - 4, 10 do
			parte({
				Name = "Faixa",
				Size = Vector3.new(5, 0.06, 0.6),
				Position = Vector3.new(x, 1.03, 0),
				Color = Color3.fromRGB(255, 220, 80),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
				CastShadow = false,
				Parent = pasta,
			})
		end
		-- sem poste colado nos portais dos biomas nem dentro do túnel
		for x = math.max(a + 10, TUNEL_BOCA + 8), b - 16, 26 do
			local z = ladoPoste * 9.5
			ladoPoste = -ladoPoste
			parte({
				Name = "Poste",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(11, 0.7, 0.7),
				CFrame = CFrame.new(x, 5.5, z) * CFrame.Angles(0, 0, math.rad(90)),
				Color = Color3.fromRGB(50, 50, 60),
				Material = Enum.Material.Metal,
				Parent = pasta,
			})
			parte({
				Name = "Braco",
				Size = Vector3.new(0.5, 0.5, 3),
				Position = Vector3.new(x, 10.8, z - math.sign(z) * 1.3),
				Color = Color3.fromRGB(50, 50, 60),
				Material = Enum.Material.Metal,
				Parent = pasta,
			})
			local lampada = parte({
				Name = "Lampada",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 1.4,
				Position = Vector3.new(x, 10.3, z - math.sign(z) * 2.6),
				Color = Color3.fromRGB(255, 235, 180),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = pasta,
			})
			local luz = Instance.new("PointLight")
			luz.Range = 18
			luz.Brightness = 1.2
			luz.Color = Color3.fromRGB(255, 225, 170)
			luz.Parent = lampada
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
local function cacto(pasta: Instance, chao: Vector3, escala: number)
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
		if math.abs(p.X) < 100 and math.abs(p.Z) < 84 then
			return false -- bases
		end
		if p.X > -140 and p.X < -100 and math.abs(p.Z) < 48 then
			return false -- túnel da entrada
		end
		for _, bioma in biomas do
			if math.abs(p.X - bioma.centro.X) < 60 and math.abs(p.Z) < 60 then
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

	-- chão de grama por cima da Baseplate
	local fim = Mapa.INICIO_BIOMAS + #biomas * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
	parte({
		Name = "Chao",
		Size = Vector3.new(2000, 1, 2000),
		Position = Vector3.new(fim / 2, -0.45, 0),
		Color = Color3.fromRGB(125, 195, 90),
		Material = Enum.Material.Grass,
		Parent = pasta,
	})

	decorarEstrada(pasta, biomas)
	Montanhas.construir()
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

	pasta.Parent = Workspace

	-- tudo no estilo Lego (o que for criado depois nessas pastas também)
	for _, nome in { "Mapa", "Decoracao", "Montanhas" } do
		local raiz = Workspace:FindFirstChild(nome)
		if raiz then
			Blocos.vigiar(raiz)
		end
	end
end

return Decoracao

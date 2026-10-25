-- Decoração do mapa: céu e iluminação, chão de grama, árvores, o lago,
-- cercas das bases, postes da estrada, o arco de entrada com estátuas
-- gigantes e os portais dos biomas. Só enfeite: nada aqui muda
-- as regras do jogo. O sorteio usa sempre a mesma semente, então o
-- mapa fica igual toda vez.
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Guardioes = require(script.Parent.Guardioes)
local Mapa = require(script.Parent.Mapa)
local Modelos = require(script.Parent.Modelos)

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
	efeito("BloomEffect", { Intensity = 0.65, Size = 28, Threshold = 1.25 })
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
			* CFrame.Angles(aleatorio:NextNumber(-0.3, 0.3), aleatorio:NextNumber(0, math.pi), aleatorio:NextNumber(-0.3, 0.3)),
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

local ARCO_IRIS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 90)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 230, 110)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(70, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
})
local NEON = {
	Color3.fromRGB(255, 80, 200),
	Color3.fromRGB(60, 220, 255),
	Color3.fromRGB(255, 230, 60),
}

-- Põe um modelo em pé num ponto do chão, olhando para "olhar", e ancora tudo.
local function plantar(modelo: Model, pasta: Instance, chao: Vector3, olhar: Vector3, escala: number)
	modelo:ScaleTo(escala)
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

-- Pedestal com neon e uma estátua gigante de um Brainrot.
local function estatuaBrainrot(pasta: Instance, id: string, mutacao: string?, chao: Vector3, olhar: Vector3)
	parte({
		Name = "Pedestal",
		Size = Vector3.new(9, 2, 9),
		Position = chao + Vector3.new(0, 1, 0),
		Color = Color3.fromRGB(70, 50, 110),
		Material = Enum.Material.SmoothPlastic,
		Parent = pasta,
	})
	parte({
		Name = "PedestalNeon",
		Size = Vector3.new(9.4, 0.5, 9.4),
		Position = chao + Vector3.new(0, 2, 0),
		Color = NEON[1],
		Material = Enum.Material.Neon,
		Parent = pasta,
	})
	local modelo = Modelos.boneco(id, mutacao)
	if modelo then
		modelo.Name = `Estatua{id}`
		plantar(modelo, pasta, chao + Vector3.new(0, 2.25, 0), olhar, 2.6)
	end
end

-- Placa com "ROUBE UM OVO" e "BRAINROT" em arco-íris.
local function letreiro(parent: BasePart, face: Enum.NormalId)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = parent
	local function linha(conteudo: string, y: number, altura: number): TextLabel
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(0.92, altura)
		label.Position = UDim2.fromScale(0.04, y)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = conteudo
		local contorno = Instance.new("UIStroke")
		contorno.Thickness = 5
		contorno.Color = Color3.fromRGB(40, 20, 70)
		contorno.Parent = label
		label.Parent = gui
		return label
	end
	linha("ROUBE UM OVO", 0.06, 0.38).TextColor3 = Color3.fromRGB(255, 245, 200)
	local brainrot = linha("BRAINROT", 0.44, 0.5)
	local gradiente = Instance.new("UIGradient")
	gradiente.Color = ARCO_IRIS
	gradiente.Parent = brainrot
end

-- Arco de entrada no começo da estrada, virado para as bases, com duas
-- estátuas gigantes de Brainrots e confete caindo.
local function arcoDeEntrada(pasta: Instance)
	local x = -104
	for _, z in { -15, 15 } do
		parte({
			Name = "Coluna",
			Size = Vector3.new(3, 22, 3),
			Position = Vector3.new(x, 11, z),
			Color = Color3.fromRGB(110, 70, 190),
			Material = Enum.Material.SmoothPlastic,
			Parent = pasta,
		})
		for i, y in { 3, 7, 11, 15, 19 } do
			parte({
				Name = "Listra",
				Size = Vector3.new(3.3, 0.6, 3.3),
				Position = Vector3.new(x, y, z),
				Color = NEON[(i - 1) % #NEON + 1],
				Material = Enum.Material.Neon,
				Parent = pasta,
			})
		end
		local bola = parte({
			Name = "Bola",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 4.5,
			Position = Vector3.new(x, 24, z),
			Color = NEON[3],
			Material = Enum.Material.Neon,
			Parent = pasta,
		})
		local luz = Instance.new("PointLight")
		luz.Color = NEON[3]
		luz.Range = 24
		luz.Brightness = 2
		luz.Parent = bola
	end
	parte({
		Name = "Moldura",
		Size = Vector3.new(1, 13.4, 31.4),
		Position = Vector3.new(x, 18, 0),
		Color = NEON[1],
		Material = Enum.Material.Neon,
		Parent = pasta,
	})
	local painel = parte({
		Name = "BoasVindas",
		Size = Vector3.new(1.4, 12, 30),
		Position = Vector3.new(x, 18, 0),
		Color = Color3.fromRGB(255, 200, 60),
		Material = Enum.Material.SmoothPlastic,
		Parent = pasta,
	})
	letreiro(painel, Enum.NormalId.Right)
	letreiro(painel, Enum.NormalId.Left)

	-- confete colorido caindo do arco
	local confete = Instance.new("ParticleEmitter")
	confete.Name = "Confete"
	confete.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	confete.Color = ARCO_IRIS
	confete.LightEmission = 0.8
	confete.Rate = 18
	confete.Lifetime = NumberRange.new(2.5, 3.5)
	confete.Speed = NumberRange.new(2, 5)
	confete.SpreadAngle = Vector2.new(70, 70)
	confete.Acceleration = Vector3.new(0, -4, 0)
	confete.Size = NumberSequence.new(0.7, 0.2)
	confete.RotSpeed = NumberRange.new(-180, 180)
	confete.Parent = painel

	estatuaBrainrot(pasta, "Tralalero", nil, Vector3.new(x, 0.05, -34), Vector3.xAxis)
	estatuaBrainrot(pasta, "Bombardiro", "Dourado", Vector3.new(x, 0.05, 34), Vector3.xAxis)
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
	local inicio = -100
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
		for x = a + 10, b - 5, 26 do
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

	arcoDeEntrada(pasta)
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

-- Árvores, arbustos e pedras em volta de tudo, fora das áreas de jogo.
local function decorarArredores(pasta: Instance, biomas: { Mapa.InfoBioma })
	local function livre(p: Vector3): boolean
		if math.abs(p.Z) < 16 then
			return false -- estrada e postes
		end
		if math.abs(p.X) < 96 and math.abs(p.Z) < 72 then
			return false -- bases
		end
		if p.X > -125 and p.X < -90 and math.abs(p.Z) < 48 then
			return false -- arco de entrada e estátuas
		end
		for _, bioma in biomas do
			if math.abs(p.X - bioma.centro.X) < 60 and math.abs(p.Z) < 60 then
				return false
			end
		end
		return true
	end
	local fim = Mapa.INICIO_BIOMAS + #biomas * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
	local minimo = Vector3.new(-180, 0.05, -160)
	local maximo = Vector3.new(fim + 40, 0.05, 160)
	espalhar(minimo, maximo, 120, livre, function(p)
		if aleatorio:NextNumber() < 0.35 then
			pinheiro(pasta, p, aleatorio:NextNumber(0.9, 1.4))
		else
			arvore(pasta, p, aleatorio:NextNumber(0.9, 1.5), FOLHAS)
		end
	end)
	espalhar(minimo, maximo, 50, livre, function(p)
		arbusto(pasta, p, aleatorio:NextNumber(0.9, 1.4))
	end)
	espalhar(minimo, maximo, 25, livre, function(p)
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
	decorarArredores(pasta, biomas)
	for _, info in bases do
		decorarBase(info)
	end
	for _, info in biomas do
		if info.config.estilo == "praia" then
			decorarLago(info)
		else
			decorarFloresta(info)
		end
		decorarPortal(info)
	end

	pasta.Parent = Workspace
end

return Decoracao

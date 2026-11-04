-- Decoração de dentro de cada bioma, seguindo a arrumação de Mapa.arrumacao:
-- trilhas da entrada até os ninhos e a arena do chefe, clareiras nos ninhos,
-- a arena do chefe num canto do fundo, um enfeite principal no meio e outro
-- grande no outro canto, e o resto espalhado sem tampar caminhos, ninhos nem
-- uns aos outros. Os modelos 3D vêm de ServerStorage.ModelosMapa (Adereco).
-- Só enfeite: nada aqui muda as regras do jogo.
local CollectionService = game:GetService("CollectionService")

local Adereco = require(script.Parent.Adereco)
local Cidade = require(script.Parent.Cidade)
local Mapa = require(script.Parent.Mapa)

local Biomas = {}

local parte = Mapa.parte
local aleatorio = Random.new(8080)

local function escolher<T>(lista: { T }): T
	return lista[aleatorio:NextInteger(1, #lista)]
end

local function plana(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function enfeite(props): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.CastShadow = false
	return parte(props)
end

local function disco(pasta: Instance, centro: Vector3, raio: number, topo: number, altura: number, props): Part
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(altura, raio * 2, raio * 2)
	props.CFrame = CFrame.new(Vector3.new(centro.X, topo - altura / 2, centro.Z)) * CFrame.Angles(0, 0, math.rad(90))
	props.Parent = pasta
	return parte(props)
end

local function emissor(parent: Instance, props): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for chave, valor in props do
		(e :: any)[chave] = valor
	end
	e.Parent = parent
	return e
end

local function luz(parent: Instance, cor: Color3, alcance: number, brilho: number)
	local l = Instance.new("PointLight")
	l.Color = cor
	l.Range = alcance
	l.Brightness = brilho
	l.Parent = parent
end

-- O cliente faz a peça girar e flutuar (tag "GirarEsteira").
local function girar(p: BasePart, graus: number, flutua: number, centro: Vector3?)
	p:SetAttribute("Giro", graus)
	p:SetAttribute("Flutua", flutua)
	if centro then
		p:SetAttribute("Centro", centro)
	end
	CollectionService:AddTag(p, "GirarEsteira")
end

local function giroQualquer(): CFrame
	return CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0)
end

-- Como é cada bioma ------------------------------------------------------------

type Tema = {
	piso: Color3,
	material: Enum.Material,
	trilha: Color3,
	materialTrilha: Enum.Material,
	clareira: Color3,
	arena: Color3,
	pedra: Color3,
	borda: Color3?, -- luz nas bordas das trilhas (Espaço)
}

local TEMAS: { [string]: Tema } = {
	floresta = {
		piso = Color3.fromRGB(110, 185, 80),
		material = Enum.Material.Grass,
		trilha = Color3.fromRGB(150, 112, 74),
		materialTrilha = Enum.Material.Ground,
		clareira = Color3.fromRGB(130, 200, 95),
		arena = Color3.fromRGB(120, 100, 80),
		pedra = Color3.fromRGB(140, 145, 140),
	},
	praia = {
		piso = Color3.fromRGB(238, 218, 165),
		material = Enum.Material.Sand,
		trilha = Color3.fromRGB(205, 180, 128),
		materialTrilha = Enum.Material.Sand,
		clareira = Color3.fromRGB(245, 228, 185),
		arena = Color3.fromRGB(190, 170, 130),
		pedra = Color3.fromRGB(165, 158, 150),
	},
	deserto = {
		piso = Color3.fromRGB(236, 200, 132),
		material = Enum.Material.Sand,
		trilha = Color3.fromRGB(205, 160, 98),
		materialTrilha = Enum.Material.Sandstone,
		clareira = Color3.fromRGB(244, 214, 150),
		arena = Color3.fromRGB(175, 110, 70),
		pedra = Color3.fromRGB(196, 120, 80),
	},
	vulcao = {
		piso = Color3.fromRGB(62, 48, 48),
		material = Enum.Material.Basalt,
		trilha = Color3.fromRGB(92, 72, 66),
		materialTrilha = Enum.Material.Slate,
		clareira = Color3.fromRGB(78, 60, 58),
		arena = Color3.fromRGB(45, 35, 35),
		pedra = Color3.fromRGB(70, 58, 56),
	},
	espaco = {
		piso = Color3.fromRGB(56, 46, 92),
		material = Enum.Material.Slate,
		trilha = Color3.fromRGB(80, 86, 120),
		materialTrilha = Enum.Material.DiamondPlate,
		clareira = Color3.fromRGB(70, 60, 112),
		arena = Color3.fromRGB(38, 30, 66),
		pedra = Color3.fromRGB(112, 100, 150),
		borda = Color3.fromRGB(90, 220, 255),
	},
}

-- Peças comuns -----------------------------------------------------------------

-- Trilhas: faixas da cor da trilha ligando os pontos, com um disco em cada
-- curva para a emenda ficar redonda.
local function trilhas(pasta: Instance, arrumacao: Mapa.Arrumacao, tema: Tema, topo: number)
	local LARGURA = 7
	for _, trilha in arrumacao.trilhas do
		for k = 1, #trilha - 1 do
			local a = Vector3.new(trilha[k].X, topo, trilha[k].Z)
			local b = Vector3.new(trilha[k + 1].X, topo, trilha[k + 1].Z)
			local comprimento = (b - a).Magnitude
			if comprimento < 0.5 then
				continue
			end
			local cf = CFrame.lookAt((a + b) / 2, b)
			enfeite({ Name = "Trilha", Size = Vector3.new(LARGURA, 0.1, comprimento), CFrame = cf * CFrame.new(0, -0.03, 0), Color = tema.trilha, Material = tema.materialTrilha, Parent = pasta })
			if tema.borda then
				for _, s in { -1, 1 } do
					local fio = enfeite({ Name = "BordaTrilha", Size = Vector3.new(0.25, 0.06, comprimento), CFrame = cf * CFrame.new(s * (LARGURA / 2 - 0.2), 0.02, 0), Color = tema.borda, Material = Enum.Material.Neon, Parent = pasta })
					CollectionService:AddTag(fio, "PulsarEsteira")
				end
			end
		end
		for _, ponto in trilha do
			disco(pasta, ponto, LARGURA / 2, topo + 0.02, 0.1, { Name = "Trilha", Color = tema.trilha, Material = tema.materialTrilha, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		end
	end
end

-- Clareira em volta de cada ninho e a arena do chefe: piso escuro, anel de
-- pedras e dois braseiros na boca, virados para a trilha.
local function clareirasEArena(pasta: Instance, arrumacao: Mapa.Arrumacao, tema: Tema, topo: number, cor: Color3)
	for _, ninho in arrumacao.ninhos do
		disco(pasta, ninho, 7.5, topo + 0.03, 0.1, { Name = "Clareira", Color = tema.clareira, Material = tema.material, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	end
	local chefe = arrumacao.chefe
	local R = Mapa.RAIO_ARENA
	disco(pasta, chefe, R, topo + 0.04, 0.1, { Name = "Arena", Color = tema.arena, Material = tema.materialTrilha, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	disco(pasta, chefe, R - 1.2, topo + 0.05, 0.1, { Name = "Arena", Color = tema.arena:Lerp(Color3.new(0, 0, 0), 0.15), Material = tema.material, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	local paraEntrada = Vector3.new(arrumacao.entrada.X - chefe.X, 0, arrumacao.entrada.Z - chefe.Z).Unit
	local anguloBoca = math.atan2(paraEntrada.Z, paraEntrada.X)
	-- anel de pedras, deixando a boca (do lado da entrada) aberta
	for k = 0, 17 do
		local a = k / 18 * math.pi * 2
		local diferenca = math.abs((a - anguloBoca + math.pi) % (math.pi * 2) - math.pi)
		if diferenca > 0.5 then
			local p = chefe + Vector3.new(math.cos(a), 0, math.sin(a)) * (R + 1.5)
			Cidade.pedra(pasta, Vector3.new(p.X, topo, p.Z), aleatorio:NextNumber(1.1, 1.7), tema.pedra, true)
		end
	end
	-- braseiros dos dois lados da boca
	for _, s in { -1, 1 } do
		local a = anguloBoca + s * 0.55
		local p = chefe + Vector3.new(math.cos(a), 0, math.sin(a)) * (R + 1.5)
		local pe = Vector3.new(p.X, topo, p.Z)
		parte({ Name = "Braseiro", Size = Vector3.new(2.6, 3, 2.6), Position = pe + Vector3.new(0, 1.5, 0), Color = tema.pedra:Lerp(Color3.new(0, 0, 0), 0.3), Material = Enum.Material.Slate, Parent = pasta })
		local fogo = enfeite({ Name = "Fogo", Size = Vector3.new(2, 0.4, 2), Position = pe + Vector3.new(0, 3.2, 0), Color = cor:Lerp(Color3.fromRGB(255, 140, 40), 0.6), Material = Enum.Material.Neon, Parent = pasta })
		emissor(fogo, {
			Texture = "rbxasset://textures/particles/fire_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), cor:Lerp(Color3.fromRGB(255, 80, 20), 0.5)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0.2) }),
			Lifetime = NumberRange.new(0.6, 1),
			Rate = 18,
			Speed = NumberRange.new(3, 5),
			LightEmission = 1,
		})
		luz(fogo, Color3.fromRGB(255, 170, 90), 18, 1.6)
	end
end

-- Lugar livre do bioma "i", afastado "folga" a mais.
local function livre(i: number, folga: number): (Vector3) -> boolean
	return function(p: Vector3): boolean
		return Mapa.livreNoBioma(i, p, folga)
	end
end

local function cantos(info: Mapa.InfoBioma): (Vector3, Vector3)
	local T = Mapa.TAMANHO_BIOMA
	local y = info.centro.Y + 0.05
	return Vector3.new(info.centro.X - T / 2, y, -T / 2), Vector3.new(info.centro.X + T / 2, y, T / 2)
end

-- Selva Sahur -------------------------------------------------------------------

local FOLHAS_SELVA = { Color3.fromRGB(70, 165, 60), Color3.fromRGB(90, 185, 70), Color3.fromRGB(55, 140, 65), Color3.fromRGB(120, 195, 70) }

local function selva(info: Mapa.InfoBioma, pasta: Instance, arrumacao: Mapa.Arrumacao, topo: number)
	local centro = Vector3.new(info.centro.X, topo, 0)
	-- meio: uma árvore anciã enorme num morrinho de grama, com flores em volta
	disco(pasta, centro, 12, topo + 0.6, 1.2, { Name = "Morro", Color = Color3.fromRGB(100, 175, 72), Material = Enum.Material.Grass })
	disco(pasta, centro, 8, topo + 1.2, 1.2, { Name = "Morro", Color = Color3.fromRGB(95, 168, 70), Material = Enum.Material.Grass })
	Cidade.arvore(pasta, centro + Vector3.new(0, 1.2, 0), 2.6, "ArvoreLarga", { Color3.fromRGB(80, 175, 65) })
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		Cidade.flores(pasta, centro + Vector3.new(math.cos(a), 0, math.sin(a)) * 15, 1.8, 5)
	end
	-- canto: um lago com cachoeira de pedra e pedras grandes
	local marco = Vector3.new(arrumacao.marco.X, topo, arrumacao.marco.Z)
	disco(pasta, marco, 16, topo + 0.08, 0.3, { Name = "AreiaLago", Color = Color3.fromRGB(150, 130, 95), Material = Enum.Material.Ground, CanCollide = false })
	disco(pasta, marco, 14, topo + 0.14, 0.2, { Name = "Lago", Color = Color3.fromRGB(70, 160, 220), Material = Enum.Material.Glass, Transparency = 0.25, Reflectance = 0.1, CanCollide = false, CastShadow = false })
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2 + aleatorio:NextNumber(-0.15, 0.15)
		Cidade.pedra(pasta, marco + Vector3.new(math.cos(a), 0, math.sin(a)) * aleatorio:NextNumber(15, 18), aleatorio:NextNumber(0.9, 2.2), Color3.fromRGB(130, 135, 130))
	end
	-- árvores em três tamanhos, sem uma tampar a outra
	local minimo, maximo = cantos(info)
	local ocupados = {}
	Cidade.espalhar(minimo, maximo, 26, 14, livre(info.indice, 7), function(p)
		Cidade.arvore(pasta, p, aleatorio:NextNumber(1.3, 1.7), nil, FOLHAS_SELVA)
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 30, 10, livre(info.indice, 5), function(p)
		Cidade.arvore(pasta, p, aleatorio:NextNumber(0.9, 1.2), nil, FOLHAS_SELVA)
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 40, 5, livre(info.indice, 2), function(p)
		Adereco.colocar("Arbusto", CFrame.new(p) * giroQualquer(), pasta, { escala = aleatorio:NextNumber(0.9, 1.5), cores = { Copa = escolher(FOLHAS_SELVA) } })
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 14, 7, livre(info.indice, 2), function(p)
		Cidade.pedra(pasta, p, aleatorio:NextNumber(1.2, 2), Color3.fromRGB(135, 140, 135))
		Cidade.pedra(pasta, p + Vector3.new(2.6, 0, 1.2), aleatorio:NextNumber(0.5, 0.8), Color3.fromRGB(135, 140, 135))
	end, ocupados)
	-- troncos caídos
	Cidade.espalhar(minimo, maximo, 6, 8, livre(info.indice, 4), function(p)
		local tronco = parte({ Name = "TroncoCaido", Shape = Enum.PartType.Cylinder, Size = Vector3.new(aleatorio:NextNumber(6, 9), 1.6, 1.6), CFrame = CFrame.new(p + Vector3.new(0, 0.7, 0)) * giroQualquer(), Color = Color3.fromRGB(115, 80, 50), Material = Enum.Material.Wood, Parent = pasta })
		tronco:SetAttribute("SemLego", true)
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 30, 5, livre(info.indice, 0), function(p)
		Cidade.flores(pasta, p, 2, aleatorio:NextInteger(5, 8))
	end, ocupados)
end

-- Praia Tralalá -----------------------------------------------------------------

local function praia(info: Mapa.InfoBioma, pasta: Instance, arrumacao: Mapa.Arrumacao, topo: number)
	local centro = Vector3.new(info.centro.X, topo, 0)
	-- meio: lagoa rasa com barbatanas de tubarão (do Tralalero) e palmeiras
	local RAIO = 15
	disco(pasta, centro, RAIO + 3.5, topo + 0.08, 0.3, { Name = "AreiaMolhada", Color = Color3.fromRGB(205, 182, 128), Material = Enum.Material.Sand, CanCollide = false })
	disco(pasta, centro, RAIO, topo + 0.12, 0.2, { Name = "Fundo", Color = Color3.fromRGB(35, 110, 160), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	disco(pasta, centro, RAIO, topo + 0.5, 0.35, { Name = "Agua", Color = Color3.fromRGB(70, 190, 235), Material = Enum.Material.Glass, Transparency = 0.35, Reflectance = 0.12, CanCollide = false, CastShadow = false })
	for k, graus in { 30, 150, 260 } do
		local a = math.rad(graus)
		local r = 5 + k * 2.5
		local p = centro + Vector3.new(math.cos(a) * r, 0.5, math.sin(a) * r)
		enfeite({ Name = "Barbatana", Size = Vector3.new(0.5, 2.4, 2.4), CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a))) * CFrame.Angles(math.rad(45), 0, 0), Color = Color3.fromRGB(85, 115, 145), Material = Enum.Material.SmoothPlastic, Parent = pasta })
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2 + 0.3
		Adereco.colocar(if k % 2 == 0 then "Palmeira" else "PalmeiraBaixa", CFrame.new(centro + Vector3.new(math.cos(a), 0, math.sin(a)) * (RAIO + 4)) * CFrame.Angles(0, -a + math.pi, 0), pasta, { escala = aleatorio:NextNumber(1.1, 1.4), solidas = { "Tronco" } })
	end
	-- canto: rochedo com farol listrado
	local marco = Vector3.new(arrumacao.marco.X, topo, arrumacao.marco.Z)
	for k = 0, 8 do
		local a = k / 9 * math.pi * 2
		Cidade.pedra(pasta, marco + Vector3.new(math.cos(a), 0, math.sin(a)) * aleatorio:NextNumber(4, 11), aleatorio:NextNumber(2, 3.6), Color3.fromRGB(150, 145, 140))
	end
	local farol = Instance.new("Folder")
	farol.Name = "Farol"
	farol:SetAttribute("SemLego", true)
	farol.Parent = pasta
	for k = 0, 5 do
		local y = topo + 2 + k * 3.2
		local raio = 3.4 - k * 0.22
		disco(farol, Vector3.new(marco.X, 0, marco.Z), raio, y + 3.2, 3.2, { Name = "Farol", Color = if k % 2 == 0 then Color3.fromRGB(240, 240, 240) else Color3.fromRGB(225, 60, 60), Material = Enum.Material.SmoothPlastic })
	end
	local alto = topo + 2 + 6 * 3.2
	disco(farol, Vector3.new(marco.X, 0, marco.Z), 3.4, alto + 0.6, 0.6, { Name = "Farol", Color = Color3.fromRGB(50, 50, 60), Material = Enum.Material.Metal })
	local lampada = disco(farol, Vector3.new(marco.X, 0, marco.Z), 1.8, alto + 3, 2.4, { Name = "LuzFarol", Color = Color3.fromRGB(255, 240, 170), Material = Enum.Material.Neon })
	girar(lampada, 60, 0)
	luz(lampada, Color3.fromRGB(255, 235, 170), 30, 2)
	disco(farol, Vector3.new(marco.X, 0, marco.Z), 2.6, alto + 4.6, 1.6, { Name = "Farol", Color = Color3.fromRGB(225, 60, 60), Material = Enum.Material.SmoothPlastic })

	local minimo, maximo = cantos(info)
	local ocupados = {}
	Cidade.espalhar(minimo, maximo, 28, 12, livre(info.indice, 6), function(p)
		Adereco.colocar(escolher({ "Palmeira", "PalmeiraBaixa" }), CFrame.new(p) * giroQualquer(), pasta, { escala = aleatorio:NextNumber(1.0, 1.5), solidas = { "Tronco" } })
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 16, 7, livre(info.indice, 2), function(p)
		Cidade.pedra(pasta, p, aleatorio:NextNumber(1, 2.2), Color3.fromRGB(160, 152, 145))
	end, ocupados)
	-- guarda-sóis com toalha
	local CORES_SOL = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(80, 170, 255), Color3.fromRGB(255, 210, 60), Color3.fromRGB(120, 220, 120) }
	Cidade.espalhar(minimo, maximo, 6, 12, livre(info.indice, 4), function(p)
		local cor = escolher(CORES_SOL)
		local sol = Instance.new("Folder")
		sol.Name = "GuardaSol"
		sol:SetAttribute("SemLego", true)
		sol.Parent = pasta
		enfeite({ Name = "Haste", Size = Vector3.new(0.3, 7, 0.3), CFrame = CFrame.new(p + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0.12, 0, 0), Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.SmoothPlastic, Parent = sol })
		for k = 0, 7 do
			local cunha = Instance.new("WedgePart")
			cunha.Name = "Lona"
			cunha.Anchored = true
			cunha.CanCollide = false
			cunha.CanQuery = false
			cunha.CanTouch = false
			cunha.Size = Vector3.new(0.1, 1.2, 3.4)
			cunha.CFrame = CFrame.new(p + Vector3.new(0, 6.6, 0)) * CFrame.Angles(0, k * math.pi / 4, 0) * CFrame.new(0, 0, -1.7) * CFrame.Angles(math.rad(-20), 0, 0)
			cunha.Color = if k % 2 == 0 then cor else Color3.new(1, 1, 1)
			cunha.Material = Enum.Material.Fabric
			cunha.Parent = sol
		end
		enfeite({ Name = "Toalha", Size = Vector3.new(2.6, 0.08, 5), CFrame = CFrame.new(p + Vector3.new(2.5, 0.04, 0)) * giroQualquer(), Color = escolher(CORES_SOL), Material = Enum.Material.Fabric, Parent = sol })
	end, ocupados)
	-- estrelas-do-mar e conchas
	Cidade.espalhar(minimo, maximo, 22, 4, livre(info.indice, 0), function(p)
		local cor = escolher({ Color3.fromRGB(255, 130, 90), Color3.fromRGB(255, 190, 210), Color3.fromRGB(250, 235, 210) })
		for k = 0, 4 do
			enfeite({ Name = "Estrela", Size = Vector3.new(0.35, 0.15, 1.1), CFrame = CFrame.new(p + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, k * math.pi * 2 / 5, 0) * CFrame.new(0, 0, -0.5), Color = cor, Material = Enum.Material.SmoothPlastic, Parent = pasta })
		end
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 14, 5, livre(info.indice, 0), function(p)
		Cidade.flores(pasta, p, 1.8, 5, { Color3.fromRGB(255, 80, 140), Color3.fromRGB(255, 150, 60), Color3.fromRGB(255, 230, 80) })
	end, ocupados)
end

-- Deserto Frigo -----------------------------------------------------------------

local function deserto(info: Mapa.InfoBioma, pasta: Instance, arrumacao: Mapa.Arrumacao, topo: number)
	local centro = Vector3.new(info.centro.X, topo, 0)
	-- meio: oásis com palmeiras baixas e pedras
	disco(pasta, centro, 13, topo + 0.08, 0.3, { Name = "AreiaMolhada", Color = Color3.fromRGB(200, 160, 100), Material = Enum.Material.Sand, CanCollide = false })
	disco(pasta, centro, 10, topo + 0.45, 0.35, { Name = "Agua", Color = Color3.fromRGB(70, 190, 220), Material = Enum.Material.Glass, Transparency = 0.3, Reflectance = 0.12, CanCollide = false, CastShadow = false })
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		Adereco.colocar("PalmeiraBaixa", CFrame.new(centro + Vector3.new(math.cos(a), 0, math.sin(a)) * 14.5) * CFrame.Angles(0, -a + math.pi, 0), pasta, { escala = aleatorio:NextNumber(1.1, 1.35), solidas = { "Tronco" } })
		Cidade.pedra(pasta, centro + Vector3.new(math.cos(a + 0.6), 0, math.sin(a + 0.6)) * 12, aleatorio:NextNumber(0.8, 1.4), Color3.fromRGB(190, 140, 95))
	end
	-- canto: mesas de arenito
	local marco = Vector3.new(arrumacao.marco.X, topo, arrumacao.marco.Z)
	Adereco.colocar("Mesa", CFrame.new(marco) * giroQualquer(), pasta, { escala = 1.25, colide = true })
	Adereco.colocar("Mesa", CFrame.new(marco + Vector3.new(14, 0, -10)) * giroQualquer(), pasta, { escala = 0.6, colide = true })

	local minimo, maximo = cantos(info)
	local ocupados = {}
	Cidade.espalhar(minimo, maximo, 3, 30, livre(info.indice, 14), function(p)
		Adereco.colocar("Mesa", CFrame.new(p) * giroQualquer(), pasta, { escala = aleatorio:NextNumber(0.5, 0.75), colide = true })
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 22, 9, livre(info.indice, 3), function(p)
		Adereco.colocar("Cacto", CFrame.new(p) * giroQualquer(), pasta, { escala = aleatorio:NextNumber(0.9, 1.5), solidas = { "Cacto" }, cores = { Flor = escolher({ Color3.fromRGB(255, 110, 170), Color3.fromRGB(255, 230, 90), Color3.fromRGB(255, 255, 255) }) } })
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 20, 5, livre(info.indice, 1), function(p)
		Adereco.colocar("CactoBola", CFrame.new(p) * giroQualquer(), pasta, { escala = aleatorio:NextNumber(0.7, 1.3), cores = { Flor = escolher({ Color3.fromRGB(255, 110, 170), Color3.fromRGB(255, 160, 60) }) } })
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 16, 7, livre(info.indice, 2), function(p)
		Cidade.pedra(pasta, p, aleatorio:NextNumber(1.1, 2.2), Color3.fromRGB(196, 125, 82))
		Cidade.pedra(pasta, p + Vector3.new(-2.4, 0, 1.6), aleatorio:NextNumber(0.4, 0.8), Color3.fromRGB(196, 125, 82))
	end, ocupados)
	-- dunas baixas e ossos
	Cidade.espalhar(minimo, maximo, 10, 14, livre(info.indice, 5), function(p)
		for k = 0, 1 do
			local cunha = Instance.new("WedgePart")
			cunha.Name = "Duna"
			cunha.Anchored = true
			cunha.Size = Vector3.new(aleatorio:NextNumber(10, 14), aleatorio:NextNumber(1.5, 2.5), 5)
			cunha.CFrame = CFrame.new(p + Vector3.new(0, cunha.Size.Y / 2, 0)) * CFrame.Angles(0, aleatorio:NextNumber(-0.2, 0.2), 0) * CFrame.new(0, 0, (k - 0.5) * 5) * CFrame.Angles(0, k * math.pi, 0)
			cunha.Color = Color3.fromRGB(232, 196, 128):Lerp(Color3.fromRGB(246, 214, 150), aleatorio:NextNumber())
			cunha.Material = Enum.Material.Sand
			cunha:SetAttribute("SemLego", true)
			cunha.Parent = pasta
		end
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 12, 5, livre(info.indice, 0), function(p)
		enfeite({ Name = "Osso", Size = Vector3.new(2.2, 0.4, 0.4), CFrame = CFrame.new(p + Vector3.new(0, 0.2, 0)) * giroQualquer(), Color = Color3.fromRGB(245, 240, 225), Material = Enum.Material.SmoothPlastic, Parent = pasta })
	end, ocupados)
end

-- Vulcão Toasterino -------------------------------------------------------------

local LAVA = Color3.fromRGB(255, 110, 30)

local function vulcao(info: Mapa.InfoBioma, pasta: Instance, arrumacao: Mapa.Arrumacao, topo: number)
	local centro = Vector3.new(info.centro.X, topo, 0)
	-- meio: poça de lava borbulhando cercada de pedras
	disco(pasta, centro, 12, topo + 0.25, 0.5, { Name = "BordaLava", Color = Color3.fromRGB(40, 32, 32), Material = Enum.Material.Basalt, CanCollide = false })
	local poca = disco(pasta, centro, 10, topo + 0.32, 0.3, { Name = "Lava", Color = LAVA, Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
	CollectionService:AddTag(poca, "PulsarEsteira")
	luz(poca, LAVA, 26, 2)
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		Cidade.pedra(pasta, centro + Vector3.new(math.cos(a), 0, math.sin(a)) * 12.5, aleatorio:NextNumber(1, 1.8), Color3.fromRGB(55, 45, 45))
	end
	-- canto: o vulcão, soltando fumaça e lava pela cratera
	local marco = Vector3.new(arrumacao.marco.X, topo, arrumacao.marco.Z)
	local ESCALA = 1.15
	local monte = Adereco.colocar("Vulcao", CFrame.new(marco - Vector3.new(0, 0.5, 0)) * giroQualquer(), pasta, {
		escala = ESCALA,
		colide = true,
		materiais = { Lava = Enum.Material.Neon, Rocha = Enum.Material.Basalt },
		cores = { Lava = LAVA },
	})
	local cratera = enfeite({ Name = "Cratera", Size = Vector3.new(4, 1, 4), Position = marco + Vector3.new(0, 27 * ESCALA, 0), Transparency = 1, Parent = pasta })
	emissor(cratera, {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(80, 70, 70), Color3.fromRGB(40, 36, 36)),
		Transparency = NumberSequence.new(0.25, 1),
		Size = NumberSequence.new(5, 16),
		Lifetime = NumberRange.new(5, 7),
		Rate = 5,
		Speed = NumberRange.new(5, 8),
		SpreadAngle = Vector2.new(12, 12),
		Acceleration = Vector3.new(2, 0, 0),
	})
	emissor(cratera, {
		Texture = "rbxasset://textures/particles/fire_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), LAVA),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(1.2, 2),
		Rate = 16,
		Speed = NumberRange.new(14, 22),
		SpreadAngle = Vector2.new(22, 22),
		Acceleration = Vector3.new(0, -24, 0),
		LightEmission = 1,
	})
	luz(cratera, LAVA, 40, 2.5)
	if not monte then
		parte({ Name = "Morro", Size = Vector3.new(30, 24, 30), Position = marco + Vector3.new(0, 12, 0), Color = Color3.fromRGB(70, 55, 52), Parent = pasta })
	end

	local minimo, maximo = cantos(info)
	local ocupados = {}
	-- rachaduras de lava no chão
	Cidade.espalhar(minimo, maximo, 16, 10, livre(info.indice, 3), function(p)
		local giro = giroQualquer()
		local comprimento = aleatorio:NextNumber(6, 12)
		local rachadura = enfeite({ Name = "Lava", Size = Vector3.new(0.8, 0.12, comprimento), CFrame = CFrame.new(p + Vector3.new(0, 0.07, 0)) * giro, Color = LAVA, Material = Enum.Material.Neon, Parent = pasta })
		CollectionService:AddTag(rachadura, "PulsarEsteira")
		enfeite({ Name = "Lava", Size = Vector3.new(0.6, 0.12, comprimento * 0.5), CFrame = CFrame.new(p + Vector3.new(0, 0.07, 0)) * giro * CFrame.new(0, 0, comprimento * 0.35) * CFrame.Angles(0, 0.7, 0) * CFrame.new(0, 0, comprimento * 0.2), Color = LAVA, Material = Enum.Material.Neon, Parent = pasta })
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 18, 9, livre(info.indice, 3), function(p)
		Adereco.colocar("ArvoreQueimada", CFrame.new(p - Vector3.new(0, 0.2, 0)) * giroQualquer(), pasta, { escala = aleatorio:NextNumber(1, 1.5), solidas = { "Tronco" } })
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 22, 7, livre(info.indice, 2), function(p)
		Cidade.pedra(pasta, p, aleatorio:NextNumber(1.1, 2.4), Color3.fromRGB(62, 50, 48))
		if aleatorio:NextNumber() < 0.35 then
			local brasa = enfeite({ Name = "Brasa", Size = Vector3.new(1.4, 0.3, 1.4), CFrame = CFrame.new(p + Vector3.new(2, 0.15, 0)) * giroQualquer(), Color = LAVA, Material = Enum.Material.Neon, Parent = pasta })
			CollectionService:AddTag(brasa, "PulsarEsteira")
		end
	end, ocupados)
	-- respiros soltando fumaça e fagulhas
	Cidade.espalhar(minimo, maximo, 6, 20, livre(info.indice, 3), function(p)
		local respiro = disco(pasta, p, 1.6, topo + 0.4, 0.8, { Name = "Respiro", Color = Color3.fromRGB(35, 28, 28), Material = Enum.Material.Basalt })
		emissor(respiro, {
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(110, 100, 100)),
			Transparency = NumberSequence.new(0.5, 1),
			Size = NumberSequence.new(1.5, 5),
			Lifetime = NumberRange.new(2, 3),
			Rate = 3,
			Speed = NumberRange.new(3, 5),
			EmissionDirection = Enum.NormalId.Right, -- o cilindro deita no X: "Right" aponta para cima
		})
		emissor(respiro, {
			Texture = "rbxasset://textures/particles/fire_sparks_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(255, 200, 90), LAVA),
			Size = NumberSequence.new(0.4, 0),
			Lifetime = NumberRange.new(0.8, 1.4),
			Rate = 6,
			Speed = NumberRange.new(5, 9),
			SpreadAngle = Vector2.new(20, 20),
			EmissionDirection = Enum.NormalId.Right,
			LightEmission = 1,
		})
	end, ocupados)
end

-- Espaço Saturnita --------------------------------------------------------------

local CRISTAIS = { Color3.fromRGB(80, 220, 255), Color3.fromRGB(200, 90, 255), Color3.fromRGB(255, 90, 200) }

local function espaco(info: Mapa.InfoBioma, pasta: Instance, arrumacao: Mapa.Arrumacao, topo: number)
	local centro = Vector3.new(info.centro.X, topo, 0)
	-- meio: cratera com um cristal gigante brilhando
	disco(pasta, centro, 13, topo + 0.5, 1, { Name = "Cratera", Color = Color3.fromRGB(105, 95, 145), Material = Enum.Material.Slate })
	disco(pasta, centro, 10.5, topo + 0.55, 1, { Name = "FundoCratera", Color = Color3.fromRGB(32, 26, 58), Material = Enum.Material.Slate })
	local gigante = Adereco.colocar("Cristais", CFrame.new(centro + Vector3.new(0, 0.4, 0)) * giroQualquer(), pasta, {
		escala = 2.2,
		colide = true,
		cores = { Cristal = CRISTAIS[1] },
		materiais = { Cristal = Enum.Material.Neon },
	})
	if gigante then
		local cristal = Adereco.peca(gigante, "Cristal")
		if cristal then
			cristal.Transparency = 0.1
			CollectionService:AddTag(cristal, "PulsarEsteira")
			luz(cristal, CRISTAIS[1], 28, 2)
		end
	end
	-- canto: planeta grande flutuando e girando em cima de uma plataforma
	local marco = Vector3.new(arrumacao.marco.X, topo, arrumacao.marco.Z)
	disco(pasta, marco, 9, topo + 1, 1, { Name = "Plataforma", Color = Color3.fromRGB(70, 75, 100), Material = Enum.Material.DiamondPlate })
	local aro = disco(pasta, marco, 9.3, topo + 0.6, 0.6, { Name = "AroPlataforma", Color = Color3.fromRGB(90, 220, 255), Material = Enum.Material.Neon, CanCollide = false })
	CollectionService:AddTag(aro, "PulsarEsteira")
	local alto = marco + Vector3.new(0, 24, 0)
	local planeta = Adereco.colocar("Planeta", CFrame.new(alto) * CFrame.Angles(0, 0, 0.3), pasta, { escala = 1.6, cores = { Planeta = Color3.fromRGB(255, 150, 90), Anel = Color3.fromRGB(255, 225, 170) } })
	if planeta then
		for _, p in planeta:GetDescendants() do
			if p:IsA("BasePart") then
				girar(p, 12, 1.5, alto)
			end
		end
	end
	local feixe = enfeite({ Name = "Feixe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(16, 3, 3), CFrame = CFrame.new(marco + Vector3.new(0, 9, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(120, 230, 255), Material = Enum.Material.ForceField, Transparency = 0.3, Parent = pasta })
	feixe:SetAttribute("SemLego", true)

	local minimo, maximo = cantos(info)
	local ocupados = {}
	local luzes = 0
	Cidade.espalhar(minimo, maximo, 18, 9, livre(info.indice, 3), function(p)
		local cor = escolher(CRISTAIS)
		local modelo = Adereco.colocar("Cristais", CFrame.new(p) * giroQualquer(), pasta, {
			escala = aleatorio:NextNumber(0.8, 1.4),
			solidas = { "Rocha" },
			cores = { Cristal = cor },
			materiais = { Cristal = Enum.Material.Neon },
		})
		local cristal = modelo and Adereco.peca(modelo, "Cristal")
		if cristal and luzes < 6 then
			luzes += 1
			luz(cristal, cor, 14, 1.2)
		end
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 8, 14, livre(info.indice, 5), function(p)
		local raio = aleatorio:NextNumber(3, 5.5)
		disco(pasta, p, raio + 1, topo + 0.5, 0.6, { Name = "Cratera", Color = Color3.fromRGB(110, 100, 150), Material = Enum.Material.Slate })
		disco(pasta, p, raio, topo + 0.55, 0.3, { Name = "FundoCratera", Color = Color3.fromRGB(35, 28, 60), Material = Enum.Material.Slate })
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 12, 8, livre(info.indice, 2), function(p)
		Cidade.pedra(pasta, p, aleatorio:NextNumber(1, 2), Color3.fromRGB(110, 100, 150))
	end, ocupados)
	-- meteoros flutuando e girando
	Cidade.espalhar(minimo, maximo, 10, 12, livre(info.indice, 0), function(p)
		local alto2 = p + Vector3.new(0, aleatorio:NextNumber(10, 22), 0)
		local m = Adereco.colocar("Meteoro", CFrame.new(alto2) * giroQualquer(), pasta, { escala = aleatorio:NextNumber(0.4, 0.9), cores = { Rocha = Color3.fromRGB(120, 108, 160) } })
		local rocha = m and Adereco.peca(m, "Rocha")
		if rocha then
			girar(rocha, aleatorio:NextNumber(15, 40), aleatorio:NextNumber(0.8, 1.6))
		end
	end, ocupados)
	-- torres de energia com raio entre elas
	Cidade.espalhar(minimo, maximo, 4, 30, livre(info.indice, 4), function(p)
		parte({ Name = "TorreEnergia", Size = Vector3.new(1.6, 9, 1.6), Position = p + Vector3.new(0, 4.5, 0), Color = Color3.fromRGB(70, 75, 100), Material = Enum.Material.Metal, Parent = pasta })
		local bola = enfeite({ Name = "Energia", Size = Vector3.new(2.2, 2.2, 2.2), Position = p + Vector3.new(0, 10, 0), Color = escolher(CRISTAIS), Material = Enum.Material.Neon, Parent = pasta })
		girar(bola, 90, 0.4)
		emissor(bola, {
			Texture = "rbxasset://textures/particles/sparkles_main.dds",
			Color = ColorSequence.new(bola.Color, Color3.new(1, 1, 1)),
			Size = NumberSequence.new(0.6, 0),
			Lifetime = NumberRange.new(0.6, 1),
			Rate = 10,
			Speed = NumberRange.new(2, 4),
			SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1,
		})
	end, ocupados)
	-- estrelas piscando no céu do bioma
	local ceu = enfeite({ Name = "Estrelas", Size = Vector3.new(Mapa.TAMANHO_BIOMA, 1, Mapa.TAMANHO_BIOMA), Position = centro + Vector3.new(0, 50, 0), Transparency = 1, Parent = pasta })
	emissor(ceu, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(180, 200, 255)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(2, 4),
		Rate = 40,
		Speed = NumberRange.new(0, 0.5),
		LightEmission = 1,
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
end

local DECORAR = {
	floresta = selva,
	praia = praia,
	deserto = deserto,
	vulcao = vulcao,
	espaco = espaco,
}

function Biomas.decorar(info: Mapa.InfoBioma)
	local estilo = info.config.estilo or "floresta"
	local tema = TEMAS[estilo] or TEMAS.floresta
	local pasta = Instance.new("Folder")
	pasta.Name = "Decoracao"
	pasta:SetAttribute("SemLego", true)
	pasta.Parent = info.pasta

	local piso = info.pasta:FindFirstChild("Piso") :: BasePart
	piso.Color = tema.piso
	piso.Material = tema.material
	piso:SetAttribute("SemLego", true)

	local topo = info.centro.Y + 0.05
	local arrumacao = Mapa.arrumacao(info.indice)
	trilhas(pasta, arrumacao, tema, topo + 0.06)
	clareirasEArena(pasta, arrumacao, tema, topo + 0.04, info.config.cor)
	local decorar = DECORAR[estilo] or selva
	decorar(info, pasta, arrumacao, topo)
	local _ = plana
end

return Biomas

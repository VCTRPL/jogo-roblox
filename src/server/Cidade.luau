-- A área das bases, repaginada: a rua (asfalto, calçadas com meio-fio,
-- faixas, faixas de pedestre POR CIMA das listras amarelas, bueiros e placas),
-- os postes com luz no chão, a arquitetura das bases (muro de pedra com
-- pilares, torres nos cantos e o portal da entrada) e as
-- duas praças com chafariz. Tudo aqui usa materiais de verdade (atributo
-- "SemLego"): os modelos 3D vêm de ServerStorage.ModelosMapa (Adereco).
-- Só enfeite: nada aqui muda as regras do jogo.
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Adereco = require(script.Parent.Adereco)
local Mapa = require(script.Parent.Mapa)
local Montanhas = require(script.Parent.Montanhas)

local Cidade = {}

local parte = Mapa.parte
local aleatorio = Random.new(5150)

local LUZ_QUENTE = Color3.fromRGB(255, 214, 150)
local PEDRA_CLARA = Color3.fromRGB(222, 216, 204)
local PEDRA_MEDIA = Color3.fromRGB(186, 178, 166)
local PEDRA_ESCURA = Color3.fromRGB(128, 122, 116)
local TERRACOTA = Color3.fromRGB(196, 124, 92)
local MADEIRA = Color3.fromRGB(165, 112, 68)
local FERRO = Color3.fromRGB(42, 46, 54)
local FLORES = {
	Color3.fromRGB(255, 90, 120),
	Color3.fromRGB(255, 210, 60),
	Color3.fromRGB(170, 110, 255),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 140, 60),
	Color3.fromRGB(90, 170, 255),
}
local FOLHAS = {
	Color3.fromRGB(85, 175, 70),
	Color3.fromRGB(100, 190, 75),
	Color3.fromRGB(70, 155, 70),
	Color3.fromRGB(125, 195, 70),
}

-- Faixas de pedestre: na frente do caminho de cada base e no meio dos
-- espaços entre elas (onde ficam as praças e a loja).
local FAIXAS = {}
for i = -2, 2 do
	table.insert(FAIXAS, i * Mapa.ESPACO_BASES / 2)
end

local function escolher<T>(lista: { T }): T
	return lista[aleatorio:NextInteger(1, #lista)]
end

local function pastaSemLego(nome: string, pai: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = nome
	f:SetAttribute("SemLego", true)
	f.Parent = pai
	return f
end

-- Peça de enfeite: não colide, não atrapalha cliques nem toques.
local function enfeite(props): Part
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	return parte(props)
end

-- Cilindro deitado (o do Roblox deita no eixo X): disco no chão, com o topo em "topo".
local function disco(pasta: Instance, centro: Vector3, raio: number, topo: number, altura: number, props): Part
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(altura, raio * 2, raio * 2)
	props.CFrame = CFrame.new(Vector3.new(centro.X, topo - altura / 2, centro.Z)) * CFrame.Angles(0, 0, math.rad(90))
	props.Parent = pasta
	return parte(props)
end

-- Octógono (dois quadrados girados) com o topo em "topo".
local function octogono(pasta: Instance, centro: Vector3, raio: number, topo: number, altura: number, props)
	for _, giro in { 0, math.pi / 4 } do
		local p = table.clone(props)
		p.Size = Vector3.new(raio * 2 * 0.924, altura, raio * 2 * 0.924)
		p.CFrame = CFrame.new(Vector3.new(centro.X, topo - altura / 2, centro.Z)) * CFrame.Angles(0, giro + math.pi / 8, 0)
		p.Parent = pasta
		parte(p)
	end
end

local function plana(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Flores de verdade (Margarida e Tulipa do Blender) em volta de um ponto.
function Cidade.flores(pasta: Instance, centro: Vector3, raio: number, quantas: number, cores: { Color3 }?)
	local paleta = cores or FLORES
	for _ = 1, quantas do
		local a = aleatorio:NextNumber(0, math.pi * 2)
		local r = math.sqrt(aleatorio:NextNumber()) * raio
		local p = centro + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local nome = if aleatorio:NextNumber() < 0.55 then "Margarida" else "Tulipa"
		Adereco.colocar(nome, CFrame.new(p) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0), pasta, {
			escala = aleatorio:NextNumber(0.8, 1.25),
			cores = { Petala = escolher(paleta) },
			sombra = false,
		})
	end
end

-- Árvore do Blender, com tamanho e tom de folha variados.
local ARVORES = { "ArvoreRedonda", "ArvoreLarga", "ArvoreAlta", "Pinheiro" }
function Cidade.arvore(pasta: Instance, chao: Vector3, escala: number, nome: string?, folhas: { Color3 }?): Model?
	local qual = nome or escolher(ARVORES)
	local cor = escolher(folhas or FOLHAS)
	if qual == "Pinheiro" then
		cor = cor:Lerp(Color3.fromRGB(30, 100, 60), 0.45)
	end
	return Adereco.colocar(qual, CFrame.new(chao - Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0), pasta, {
		escala = escala,
		cores = { Copa = cor },
		solidas = { "Tronco" },
	})
end

-- Pedra do Blender (três formatos), girada, com tamanho e tom variados.
function Cidade.pedra(pasta: Instance, chao: Vector3, escala: number, cor: Color3?, solida: boolean?): Model?
	local base = cor or Color3.fromRGB(150, 148, 155)
	local tom = base:Lerp(Color3.new(1, 1, 1), aleatorio:NextNumber(-0.05, 0.12))
	return Adereco.colocar(`Pedra{aleatorio:NextInteger(1, 3)}`, CFrame.new(chao - Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0), pasta, {
		escala = escala,
		cores = { Rocha = tom },
		colide = solida ~= false and escala > 1,
	})
end

-- Espalha pontos sem deixar dois mais perto que "distancia" (nada de árvore
-- tampando a outra). "ocupados" guarda os pontos já usados (pode ser
-- compartilhado entre chamadas).
function Cidade.espalhar(
	minimo: Vector3,
	maximo: Vector3,
	quantidade: number,
	distancia: number,
	livre: (Vector3) -> boolean,
	criar: (Vector3, number) -> (),
	ocupados: { { p: Vector3, r: number } }?
)
	local lista = ocupados or {}
	local feitos = 0
	for _ = 1, quantidade * 25 do
		if feitos >= quantidade then
			break
		end
		local p = Vector3.new(aleatorio:NextNumber(minimo.X, maximo.X), minimo.Y, aleatorio:NextNumber(minimo.Z, maximo.Z))
		local ok = livre(p)
		if ok then
			for _, outro in lista do
				if plana(p, outro.p) < math.max(distancia, outro.r) then
					ok = false
					break
				end
			end
		end
		if ok then
			table.insert(lista, { p = p, r = distancia })
			feitos += 1
			criar(p, feitos)
		end
	end
end

-- Rua --------------------------------------------------------------------------

local function pertoDaFaixa(x: number, folga: number): boolean
	for _, xf in FAIXAS do
		if math.abs(x - xf) < folga then
			return true
		end
	end
	return false
end

-- Poste de rua do Blender (ferro com detalhes dourados e a lanterna), com o
-- braço por cima da rua, luz para baixo, um círculo de luz no asfalto e
-- uns brilhos voando em volta da lanterna. "paraEstrada" é 1 ou -1.
local function poste(pasta: Instance, chao: Vector3, paraEstrada: number)
	local ESCALA = 1.3
	local giro = if paraEstrada > 0 then CFrame.new() else CFrame.Angles(0, math.pi, 0)
	local modelo = Adereco.colocar("Poste", CFrame.new(chao) * giro, pasta, {
		escala = ESCALA,
		colide = false, -- a colisão do modelo pegava uma caixa enorme (com o braço) e travava a calçada
		cores = { Vidro = LUZ_QUENTE },
		materiais = { Vidro = Enum.Material.Neon },
	})
	local lanterna = chao + Vector3.new(0, 12 * ESCALA, paraEstrada * 3.4 * ESCALA)
	if not modelo then
		-- sem o modelo: poste simples de blocos
		enfeite({ Name = "Poste", Size = Vector3.new(0.8, 16, 0.8), Position = chao + Vector3.new(0, 8, 0), Color = FERRO, Material = Enum.Material.Metal, Parent = pasta })
		enfeite({ Name = "Braco", Size = Vector3.new(0.4, 0.4, 4.6), Position = chao + Vector3.new(0, 16, paraEstrada * 2.2), Color = FERRO, Material = Enum.Material.Metal, Parent = pasta })
		enfeite({ Name = "Lampada", Size = Vector3.new(1.2, 1.4, 1.2), Position = lanterna, Color = LUZ_QUENTE, Material = Enum.Material.Neon, Parent = pasta })
	end
	-- só a coluna segura o jogador: um cilindro fino e invisível
	parte({
		Name = "ColisaoPoste",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(16, 1, 1),
		CFrame = CFrame.new(chao + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
		Parent = pasta,
	})
	local foco = enfeite({
		Name = "FocoPoste",
		Size = Vector3.new(0.4, 0.4, 0.4),
		Position = lanterna - Vector3.new(0, 0.8, 0),
		Transparency = 1,
		Parent = pasta,
	})
	local luz = Instance.new("SpotLight")
	luz.Face = Enum.NormalId.Bottom
	luz.Angle = 120
	luz.Range = 26
	luz.Brightness = 2.2
	luz.Color = LUZ_QUENTE
	luz.Parent = foco
	-- brilhos de luz voando em volta da lanterna (bem poucos)
	local brilhos = Instance.new("ParticleEmitter")
	brilhos.Name = "VagaLumes"
	brilhos.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	brilhos.Color = ColorSequence.new(LUZ_QUENTE)
	brilhos.LightEmission = 1
	brilhos.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0) })
	brilhos.Lifetime = NumberRange.new(2, 3)
	brilhos.Rate = 1.5
	brilhos.Speed = NumberRange.new(0.3, 0.8)
	brilhos.SpreadAngle = Vector2.new(180, 180)
	brilhos.Parent = foco
	-- poça de luz no chão, embaixo da lanterna
	disco(pasta, Vector3.new(lanterna.X, 0, lanterna.Z), 6.5, 1.075, 0.04, {
		Name = "LuzChao",
		Color = LUZ_QUENTE,
		Material = Enum.Material.Neon,
		Transparency = 0.86,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
	})
end

-- Placa azul de travessia num poste fino, virada para a rua.
local function placaTravessia(pasta: Instance, chao: Vector3, olhar: Vector3)
	enfeite({ Name = "PostePlaca", Size = Vector3.new(0.3, 7, 0.3), Position = chao + Vector3.new(0, 3.5, 0), Color = Color3.fromRGB(150, 155, 165), Material = Enum.Material.Metal, Parent = pasta })
	local placa = enfeite({
		Name = "PlacaTravessia",
		Size = Vector3.new(2.4, 2.4, 0.15),
		CFrame = CFrame.lookAt(chao + Vector3.new(0, 6.4, 0), chao + Vector3.new(0, 6.4, 0) + olhar),
		Color = Color3.fromRGB(30, 110, 220),
		Material = Enum.Material.SmoothPlastic,
		Parent = pasta,
	})
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = placa
		local fundo = Instance.new("Frame")
		fundo.AnchorPoint = Vector2.new(0.5, 0.5)
		fundo.Position = UDim2.fromScale(0.5, 0.5)
		fundo.Size = UDim2.fromScale(0.78, 0.78)
		fundo.BackgroundColor3 = Color3.new(1, 1, 1)
		fundo.Rotation = 45
		fundo.Parent = gui
		local icone = Instance.new("TextLabel")
		icone.BackgroundTransparency = 1
		icone.Size = UDim2.fromScale(1, 1)
		icone.Text = "🚶"
		icone.TextScaled = true
		icone.Parent = gui
	end
end

function Cidade.rua(pai: Instance)
	local pasta = pastaSemLego("Rua", pai)
	local a, b = Mapa.INICIO_ESTRADA, Mapa.inicioBioma(1)
	local c0 = Mapa.TUNEL_BOCA + 2 -- calçada começa na boca do túnel
	local ASFALTO_TOPO = 1

	-- Ordem de cima para baixo (cada uma um pouco mais alta que a de baixo,
	-- para nunca piscar): faixa de pedestre e linha de parada > listras
	-- amarelas e brancas > asfalto.
	local Y_LISTRA = ASFALTO_TOPO + 0.03
	local Y_FAIXA = ASFALTO_TOPO + 0.07

	-- linhas brancas contínuas das bordas
	for _, z in { -5.9, 5.9 } do
		enfeite({ Name = "LinhaBorda", Size = Vector3.new(b - a, 0.06, 0.3), Position = Vector3.new((a + b) / 2, Y_LISTRA - 0.03 + 0.03, z), Color = Color3.fromRGB(245, 245, 245), Material = Enum.Material.SmoothPlastic, CastShadow = false, Parent = pasta })
	end
	-- listras amarelas duplas tracejadas no meio, interrompidas nas faixas
	for x = a + 6, b - 6, 9 do
		if pertoDaFaixa(x, 8) then
			continue
		end
		for _, z in { -0.32, 0.32 } do
			enfeite({ Name = "ListraAmarela", Size = Vector3.new(5, 0.06, 0.3), Position = Vector3.new(x, Y_LISTRA, z), Color = Color3.fromRGB(255, 205, 50), Material = Enum.Material.SmoothPlastic, CastShadow = false, Parent = pasta })
		end
	end
	-- faixas de pedestre (zebra), bem brancas e acima de tudo, e as linhas de
	-- parada antes delas
	for _, x in FAIXAS do
		for z = -5.0, 5.01, 1.66 do
			enfeite({ Name = "Zebra", Size = Vector3.new(7, 0.1, 0.95), Position = Vector3.new(x, Y_FAIXA - 0.05 + 0.05, z), Color = Color3.fromRGB(250, 250, 250), Material = Enum.Material.SmoothPlastic, CastShadow = false, Parent = pasta })
		end
		enfeite({ Name = "LinhaParada", Size = Vector3.new(0.6, 0.1, 5.6), Position = Vector3.new(x - 5.2, Y_FAIXA, -2.95), Color = Color3.fromRGB(250, 250, 250), Material = Enum.Material.SmoothPlastic, CastShadow = false, Parent = pasta })
		enfeite({ Name = "LinhaParada", Size = Vector3.new(0.6, 0.1, 5.6), Position = Vector3.new(x + 5.2, Y_FAIXA, 2.95), Color = Color3.fromRGB(250, 250, 250), Material = Enum.Material.SmoothPlastic, CastShadow = false, Parent = pasta })
		for _, lado in { -1, 1 } do
			placaTravessia(pasta, Vector3.new(x + lado * 5.5, 1.2, lado * 12.6), Vector3.new(0, 0, -lado))
		end
	end
	-- bueiros no asfalto, alternando as pistas
	local pista = 1
	for x = a + 30, b - 20, 75 do
		if not pertoDaFaixa(x, 10) then
			disco(pasta, Vector3.new(x, 0, pista * 3), 1.3, Y_LISTRA, 0.08, { Name = "Bueiro", Color = Color3.fromRGB(70, 72, 80), Material = Enum.Material.DiamondPlate, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
			pista = -pista
		end
	end

	-- calçadas: laje de concreto com juntas, meio-fio claro na beira da rua e
	-- guia de pedra do lado da grama
	for _, lado in { -1, 1 } do
		parte({ Name = "Calcada", Size = Vector3.new(b - c0, 1.15, 6), Position = Vector3.new((c0 + b) / 2, 0.625, lado * 10.5), Color = Color3.fromRGB(208, 204, 196), Material = Enum.Material.Concrete, Parent = pasta })
		parte({ Name = "Meiofio", Size = Vector3.new(b - a, 1.3, 0.55), Position = Vector3.new((a + b) / 2, 0.65, lado * 7.6), Color = Color3.fromRGB(232, 232, 236), Material = Enum.Material.Concrete, Parent = pasta })
		parte({ Name = "Guia", Size = Vector3.new(b - c0, 1.25, 0.5), Position = Vector3.new((c0 + b) / 2, 0.625, lado * 13.6), Color = PEDRA_ESCURA, Material = Enum.Material.Cobblestone, Parent = pasta })
		for x = c0 + 6, b - 3, 6 do
			enfeite({ Name = "Junta", Size = Vector3.new(0.22, 0.04, 5.6), Position = Vector3.new(x, 1.215, lado * 10.5), Color = Color3.fromRGB(176, 171, 162), Material = Enum.Material.SmoothPlastic, CastShadow = false, Parent = pasta })
		end
		-- piso tátil amarelo na ponta de cada travessia
		for _, x in FAIXAS do
			enfeite({ Name = "PisoTatil", Size = Vector3.new(6.5, 0.05, 1.2), Position = Vector3.new(x, 1.225, lado * 8.6), Color = Color3.fromRGB(250, 200, 40), Material = Enum.Material.DiamondPlate, CastShadow = false, Parent = pasta })
		end
	end

	-- postes dos dois lados, alternados, fora das travessias e do túnel
	local ladoPoste = 1
	for x = c0 + 14, b - 30, 38 do
		if pertoDaFaixa(x, 9) then
			x += 10
		end
		poste(pasta, Vector3.new(x, 1.2, ladoPoste * 12), -ladoPoste)
		ladoPoste = -ladoPoste
	end
	return pasta
end

-- Bases ------------------------------------------------------------------------

local ENTRADA = 9 -- metade da largura da entrada

-- Muro baixo de pedra de "de" até "ate" (no chão da base), com pilares a cada
-- ~12 studs, chapéu claro e uma faixa na cor da base.
local function muro(pasta: Instance, de: Vector3, ate: Vector3, cor: Color3, fora: Vector3)
	local direcao = ate - de
	local comprimento = direcao.Magnitude
	local cf = CFrame.lookAt((de + ate) / 2, ate)
	local ALTURA = 3.2
	parte({ Name = "Muro", Size = Vector3.new(1.4, ALTURA, comprimento), CFrame = cf * CFrame.new(0, ALTURA / 2, 0), Color = PEDRA_MEDIA, Material = Enum.Material.Cobblestone, Parent = pasta })
	enfeite({ Name = "ChapeuMuro", Size = Vector3.new(1.9, 0.45, comprimento + 0.4), CFrame = cf * CFrame.new(0, ALTURA + 0.2, 0), Color = PEDRA_CLARA, Material = Enum.Material.Limestone, Parent = pasta })
	enfeite({ Name = "FaixaMuro", Size = Vector3.new(1.5, 0.35, comprimento), CFrame = cf * CFrame.new(0, ALTURA * 0.55, 0), Color = cor, Material = Enum.Material.SmoothPlastic, Parent = pasta })
	local pilares = math.max(1, math.round(comprimento / 12))
	for i = 0, pilares do
		local p = de + direcao * (i / pilares)
		parte({ Name = "Pilar", Size = Vector3.new(2.2, 4.4, 2.2), Position = p + Vector3.new(0, 2.2, 0), Color = PEDRA_CLARA, Material = Enum.Material.Limestone, Parent = pasta })
		enfeite({ Name = "ChapeuPilar", Size = Vector3.new(2.6, 0.5, 2.6), Position = p + Vector3.new(0, 4.65, 0), Color = PEDRA_MEDIA, Material = Enum.Material.Limestone, Parent = pasta })
		enfeite({ Name = "LuzPilar", Size = Vector3.new(0.9, 0.6, 0.9), Position = p + Vector3.new(0, 5.2, 0), Color = cor:Lerp(Color3.new(1, 1, 1), 0.35), Material = Enum.Material.Neon, CastShadow = false, Parent = pasta })
	end
	local _ = fora
end

-- Torre de canto: pedra clara, faixa brilhante na cor da base e telhado.
local function torre(pasta: Instance, chao: Vector3, cor: Color3)
	parte({ Name = "Torre", Size = Vector3.new(4.4, 1, 4.4), Position = chao + Vector3.new(0, 0.5, 0), Color = PEDRA_ESCURA, Material = Enum.Material.Limestone, Parent = pasta })
	parte({ Name = "Torre", Size = Vector3.new(3.6, 8, 3.6), Position = chao + Vector3.new(0, 5, 0), Color = PEDRA_CLARA, Material = Enum.Material.Limestone, Parent = pasta })
	local faixa = enfeite({ Name = "FaixaTorre", Size = Vector3.new(3.75, 0.5, 3.75), Position = chao + Vector3.new(0, 6.8, 0), Color = cor:Lerp(Color3.new(1, 1, 1), 0.2), Material = Enum.Material.Neon, CastShadow = false, Parent = pasta })
	CollectionService:AddTag(faixa, "PulsarEsteira")
	enfeite({ Name = "TopoTorre", Size = Vector3.new(4.4, 0.7, 4.4), Position = chao + Vector3.new(0, 9.35, 0), Color = PEDRA_MEDIA, Material = Enum.Material.Limestone, Parent = pasta })
	-- telhado em pirâmide (duas cunhas de cada lado)
	for i = 0, 3 do
		local giro = CFrame.Angles(0, i * math.pi / 2, 0)
		local cunha = Instance.new("WedgePart")
		cunha.Name = "Telhado"
		cunha.Anchored = true
		cunha.CanCollide = false
		cunha.CanQuery = false
		cunha.CanTouch = false
		cunha.Size = Vector3.new(4.4, 3, 2.2)
		cunha.CFrame = CFrame.new(chao + Vector3.new(0, 11.2, 0)) * giro * CFrame.new(0, 0, 1.1) * CFrame.Angles(0, math.pi, 0)
		cunha.Color = cor:Lerp(Color3.new(0, 0, 0), 0.25)
		cunha.Material = Enum.Material.SmoothPlastic
		cunha.Parent = pasta
	end
end

-- Arquitetura de uma base (o chão continua a grama): muro de pedra com
-- pilares, torres nos cantos,
-- portal na entrada (pilares altos, arco, placa e lanternas acesas),
-- canteiros com arbustos e flores no fundo e os mastros com bandeira.
function Cidade.base(info: Mapa.InfoBase)
	local pasta = pastaSemLego("Arquitetura", info.pasta)
	local T = Mapa.TAMANHO_BASE
	local meio = T / 2 - 0.7
	local topo = info.centro -- topo do piso (y = 1)
	local lado = info.lado
	local cor = info.piso:GetAttribute("CorBase") or info.piso.Color
	local corForte = Color3.fromHSV(cor:ToHSV(), 0.65, 0.95)
	local function ponto(x: number, z: number): Vector3
		-- z positivo = fundos da base (longe da estrada)
		return topo + Vector3.new(x, 0, lado * z)
	end

	-- o chão da base é a grama dela (Mapa); só o muro, as torres e o portal em volta

	-- muro (com a entrada na frente) e torres nos cantos
	muro(pasta, ponto(-meio, meio), ponto(meio, meio), cor, Vector3.new(0, 0, lado))
	muro(pasta, ponto(-meio, -meio), ponto(-meio, meio), cor, Vector3.new(-1, 0, 0))
	muro(pasta, ponto(meio, -meio), ponto(meio, meio), cor, Vector3.new(1, 0, 0))
	muro(pasta, ponto(-meio, -meio), ponto(-ENTRADA - 2.2, -meio), cor, Vector3.new(0, 0, -lado))
	muro(pasta, ponto(ENTRADA + 2.2, -meio), ponto(meio, -meio), cor, Vector3.new(0, 0, -lado))
	for _, x in { -meio, meio } do
		for _, z in { -meio, meio } do
			torre(pasta, ponto(x, z), cor)
		end
	end

	-- portal da entrada: dois pilares altos, arco com a placa, faixa na cor
	-- da base e lanternas acesas viradas para a rua
	for _, s in { -1, 1 } do
		local pe = ponto(s * (ENTRADA + 1.6), -meio)
		parte({ Name = "PilarPortal", Size = Vector3.new(3.4, 1.2, 3.4), Position = pe + Vector3.new(0, 0.6, 0), Color = PEDRA_ESCURA, Material = Enum.Material.Limestone, Parent = pasta })
		parte({ Name = "PilarPortal", Size = Vector3.new(2.8, 12, 2.8), Position = pe + Vector3.new(0, 7.2, 0), Color = PEDRA_CLARA, Material = Enum.Material.Limestone, Parent = pasta })
		for _, y in { 4, 9 } do
			enfeite({ Name = "AnelPortal", Size = Vector3.new(3.1, 0.5, 3.1), Position = pe + Vector3.new(0, y, 0), Color = cor, Material = Enum.Material.SmoothPlastic, Parent = pasta })
		end
		local lanterna = enfeite({ Name = "LanternaPortal", Size = Vector3.new(1.2, 1.6, 1.2), Position = pe + Vector3.new(0, 7, -lado * 1.9), Color = LUZ_QUENTE, Material = Enum.Material.Neon, CastShadow = false, Parent = pasta })
		enfeite({ Name = "SuporteLanterna", Size = Vector3.new(0.3, 0.3, 1.2), Position = pe + Vector3.new(0, 7.9, -lado * 1.4), Color = FERRO, Material = Enum.Material.Metal, Parent = pasta })
		enfeite({ Name = "TetoLanterna", Size = Vector3.new(1.6, 0.4, 1.6), Position = pe + Vector3.new(0, 8, -lado * 1.9), Color = FERRO, Material = Enum.Material.Metal, Parent = pasta })
		local luz = Instance.new("PointLight")
		luz.Color = LUZ_QUENTE
		luz.Range = 16
		luz.Brightness = 1.4
		luz.Parent = lanterna
	end
	local arco = ponto(0, -meio) + Vector3.new(0, 13.6, 0)
	parte({ Name = "ArcoPortal", Size = Vector3.new(ENTRADA * 2 + 6.4, 1.6, 3), Position = arco, Color = PEDRA_CLARA, Material = Enum.Material.Limestone, Parent = pasta })
	enfeite({ Name = "ArcoPortal", Size = Vector3.new(ENTRADA * 2 + 7.4, 0.5, 3.4), Position = arco + Vector3.new(0, 1.05, 0), Color = PEDRA_MEDIA, Material = Enum.Material.Limestone, Parent = pasta })
	enfeite({ Name = "FaixaPortal", Size = Vector3.new(ENTRADA * 2 + 1, 0.5, 3.1), Position = arco + Vector3.new(0, -0.55, 0), Color = cor, Material = Enum.Material.SmoothPlastic, Parent = pasta })
	local brilhoArco = enfeite({ Name = "LuzArco", Size = Vector3.new(ENTRADA * 2 + 1, 0.2, 0.2), Position = arco + Vector3.new(0, -0.9, -lado * 1.45), Color = corForte, Material = Enum.Material.Neon, CastShadow = false, Parent = pasta })
	CollectionService:AddTag(brilhoArco, "PulsarEsteira")
	-- frontão em cima do arco, com uma pedra preciosa na cor da base
	enfeite({ Name = "Frontao", Size = Vector3.new(8, 2.2, 2.6), Position = arco + Vector3.new(0, 2.4, 0), Color = PEDRA_CLARA, Material = Enum.Material.Limestone, Parent = pasta })
	local joia = enfeite({ Name = "Joia", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(arco + Vector3.new(0, 2.6, -lado * 1.35)) * CFrame.Angles(0, 0, math.rad(45)), Color = corForte, Material = Enum.Material.Neon, CastShadow = false, Parent = pasta })
	CollectionService:AddTag(joia, "PulsarEsteira")

	-- canteiros no fundo (por dentro do muro), com arbustos e flores
	for _, x in { -22, 0, 22 } do
		local c = ponto(x, meio - 3.2)
		parte({ Name = "Canteiro", Size = Vector3.new(12, 1.2, 3.4), Position = c + Vector3.new(0, 0.6, 0), Color = PEDRA_CLARA, Material = Enum.Material.Limestone, Parent = pasta })
		enfeite({ Name = "Terra", Size = Vector3.new(11.2, 0.2, 2.6), Position = c + Vector3.new(0, 1.15, 0), Color = Color3.fromRGB(95, 70, 50), Material = Enum.Material.Ground, Parent = pasta })
		for _, dx in { -3.5, 3.5 } do
			Adereco.colocar("Arbusto", CFrame.new(c + Vector3.new(dx, 1.1, 0)) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0), pasta, { escala = 0.75, cores = { Copa = escolher(FOLHAS) } })
		end
		Cidade.flores(pasta, c + Vector3.new(0, 1.25, 0), 1.4, 5)
	end

	-- mastros com bandeira nos cantos do fundo (para ver de longe de quem é)
	for _, x in { -meio + 5, meio - 5 } do
		local pe = ponto(x, meio - 6.5)
		parte({ Name = "Mastro", Size = Vector3.new(0.5, 24, 0.5), Position = pe + Vector3.new(0, 12, 0), Color = Color3.fromRGB(235, 235, 240), Material = Enum.Material.Metal, Parent = pasta })
		enfeite({ Name = "Bandeira", Size = Vector3.new(6, 3.8, 0.2), Position = pe + Vector3.new(-math.sign(x) * 3.2, 21.6, 0), Color = cor, Material = Enum.Material.Fabric, Parent = pasta })
		enfeite({ Name = "PontaMastro", Size = Vector3.new(0.9, 0.9, 0.9), Position = pe + Vector3.new(0, 24.4, 0), Color = Color3.fromRGB(255, 210, 60), Material = Enum.Material.Neon, Parent = pasta })
	end
end

-- Praças com chafariz ---------------------------------------------------------

local function banco(pasta: Instance, chao: Vector3, olhar: Vector3)
	local base = CFrame.lookAt(chao, chao + olhar)
	for _, x in { -2, 2 } do
		parte({ Name = "PeBanco", Size = Vector3.new(0.4, 1.6, 1.8), CFrame = base * CFrame.new(x, 0.8, 0), Color = FERRO, Material = Enum.Material.Metal, Parent = pasta })
		enfeite({ Name = "PeBanco", Size = Vector3.new(0.4, 2.2, 0.4), CFrame = base * CFrame.new(x, 2.3, 0.8) * CFrame.Angles(math.rad(-10), 0, 0), Color = FERRO, Material = Enum.Material.Metal, Parent = pasta })
	end
	for i = 0, 2 do
		parte({ Name = "Assento", Size = Vector3.new(5, 0.25, 0.55), CFrame = base * CFrame.new(0, 1.7, -0.6 + i * 0.6), Color = MADEIRA, Material = Enum.Material.WoodPlanks, Parent = pasta })
	end
	for i = 0, 1 do
		enfeite({ Name = "Encosto", Size = Vector3.new(5, 0.45, 0.2), CFrame = base * CFrame.new(0, 2.5 + i * 0.6, 0.95) * CFrame.Angles(math.rad(-10), 0, 0), Color = MADEIRA, Material = Enum.Material.WoodPlanks, Parent = pasta })
	end
end

local function emissor(parent: Instance, props): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for chave, valor in props do
		(e :: any)[chave] = valor
	end
	e.Parent = parent
	return e
end

local AGUA = Color3.fromRGB(80, 185, 240)

-- Jatos d'água do chafariz: um no topo (sobe e cai na bacia de cima), as
-- quatro bicas do tanque, névoa e brilhos. "escala" é a do modelo.
local function jatos(pasta: Instance, centro: Vector3, escala: number)
	local function ponto(nome: string, posicao: Vector3, direcao: Vector3?): BasePart
		local p = enfeite({ Name = nome, Size = Vector3.new(0.4, 0.4, 0.4), Position = posicao, Transparency = 1, CastShadow = false, Parent = pasta })
		if direcao then
			p.CFrame = CFrame.lookAt(posicao, posicao + direcao)
		end
		return p
	end
	local topo = ponto("JatoTopo", centro + Vector3.new(0, 11.9 * escala, 0))
	emissor(topo, {
		Name = "Jato",
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(220, 245, 255), AGUA),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.9) }),
		Size = NumberSequence.new(0.55, 0.25),
		Lifetime = NumberRange.new(1.0, 1.3),
		Rate = 70,
		Speed = NumberRange.new(9, 11),
		SpreadAngle = Vector2.new(10, 10),
		Acceleration = Vector3.new(0, -22, 0),
		EmissionDirection = Enum.NormalId.Top,
		LightEmission = 0.4,
	})
	emissor(topo, {
		Name = "Nevoa",
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.new(1, 1, 1)),
		Transparency = NumberSequence.new(0.75, 1),
		Size = NumberSequence.new(2, 5),
		Lifetime = NumberRange.new(1.5, 2.5),
		Rate = 4,
		Speed = NumberRange.new(1, 2),
		SpreadAngle = Vector2.new(180, 180),
	})
	-- cortina caindo da borda das bacias (anel de gotas)
	for _, bacia in { { y = 6.9, r = 4.4 }, { y = 9.6, r = 2.5 } } do
		local anel = enfeite({ Name = "Cortina", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, bacia.r * 2 * escala, bacia.r * 2 * escala), CFrame = CFrame.new(centro + Vector3.new(0, bacia.y * escala, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 1, CastShadow = false, Parent = pasta })
		emissor(anel, {
			Name = "Cortina",
			Texture = "rbxasset://textures/particles/sparkles_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(210, 240, 255)),
			Transparency = NumberSequence.new(0.25, 0.9),
			Size = NumberSequence.new(0.35, 0.15),
			Squash = NumberSequence.new(-1.5),
			Lifetime = NumberRange.new(0.45, 0.6),
			Rate = 45,
			Speed = NumberRange.new(0.5, 1),
			Acceleration = Vector3.new(0, -30, 0),
			Shape = Enum.ParticleEmitterShape.Cylinder,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
		})
	end
	-- bicas na parede do tanque, jorrando para o meio
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + math.pi / 8
		local d = Vector3.new(math.cos(a), 0, -math.sin(a))
		local bica = ponto("Bica", centro + d * 7.3 * escala + Vector3.new(0, 1.75 * escala, 0), -d + Vector3.new(0, 0.55, 0))
		emissor(bica, {
			Name = "Bica",
			Texture = "rbxasset://textures/particles/sparkles_main.dds",
			Color = ColorSequence.new(Color3.fromRGB(220, 245, 255), AGUA),
			Transparency = NumberSequence.new(0.15, 0.85),
			Size = NumberSequence.new(0.4, 0.2),
			Lifetime = NumberRange.new(0.5, 0.6),
			Rate = 30,
			Speed = NumberRange.new(7, 8),
			SpreadAngle = Vector2.new(4, 4),
			Acceleration = Vector3.new(0, -26, 0),
			EmissionDirection = Enum.NormalId.Front,
		})
	end
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(120, 210, 255)
	luz.Range = 18
	luz.Brightness = 1.2
	luz.Parent = topo
end

-- Praça redonda com o chafariz do Blender no meio (água correndo, jatos,
-- cortinas d'água, névoa e luz), piso de pedra com anel de terracota, seis
-- bancos, luminárias de jardim, canteiros e um passeio até a calçada.
local function praca(pasta: Instance, centro: Vector3)
	local R = Mapa.RAIO_PRACA
	local TOPO = 1.05
	octogono(pasta, centro, R + 1.2, TOPO - 0.2, 1.05, { Name = "DegrauPraca", Color = PEDRA_ESCURA, Material = Enum.Material.Cobblestone })
	octogono(pasta, centro, R, TOPO, 1.0, { Name = "PisoPraca", Color = PEDRA_CLARA, Material = Enum.Material.Pavement })
	octogono(pasta, centro, 13.4, TOPO + 0.03, 0.06, { Name = "AnelPraca", Color = TERRACOTA, Material = Enum.Material.Brick, CanCollide = false, CanQuery = false, CastShadow = false })
	octogono(pasta, centro, 12.3, TOPO + 0.06, 0.06, { Name = "PisoPraca", Color = Color3.fromRGB(232, 226, 214), Material = Enum.Material.Pavement, CanCollide = false, CanQuery = false, CastShadow = false })

	local ESCALA = 1.0
	local chafariz = Adereco.colocar("Chafariz", CFrame.new(centro + Vector3.new(0, TOPO + 0.06, 0)), pasta, {
		escala = ESCALA,
		solidas = { "Pedra", "Base" },
		materiais = { Agua = Enum.Material.Glass, Pedra = Enum.Material.Limestone, Base = Enum.Material.Cobblestone, Dourado = Enum.Material.Metal },
	})
	if chafariz then
		for _, p in chafariz:GetDescendants() do
			if p:IsA("BasePart") and p.Name == "Agua" then
				p.Color = AGUA
				p.Transparency = 0.25
				p.Reflectance = 0.15
				p.CastShadow = false
			end
		end
		jatos(pasta, centro + Vector3.new(0, TOPO + 0.06, 0), ESCALA)
	end

	-- bancos virados para o chafariz, entre os canteiros
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + math.pi / 6
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		banco(pasta, centro + d * 16 + Vector3.new(0, TOPO, 0), -d)
	end
	-- luminárias de jardim e canteiros de flores
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		local pe = centro + d * 18.6 + Vector3.new(0, TOPO, 0)
		local lum = Adereco.colocar("Luminaria", CFrame.new(pe), pasta, { escala = 1.1, colide = false, cores = { Vidro = LUZ_QUENTE }, materiais = { Vidro = Enum.Material.Neon } })
		if lum then
			local vidro = Adereco.peca(lum, "Vidro")
			if vidro then
				local luz = Instance.new("PointLight")
				luz.Color = LUZ_QUENTE
				luz.Range = 13
				luz.Brightness = 1.2
				luz.Parent = vidro
			end
		end
		local c = centro + d * 14.8
		disco(pasta, c, 1.9, TOPO + 0.4, 0.8, { Name = "Vaso", Color = TERRACOTA, Material = Enum.Material.Brick })
		Cidade.flores(pasta, c + Vector3.new(0, TOPO + 0.4, 0), 1.3, 6)
	end

	-- passeio até a calçada, com arbustos dos dois lados
	local calcada = math.sign(centro.Z) * 13.4
	local inicio = centro.Z - math.sign(centro.Z) * R
	local comprimento = math.abs(inicio - calcada)
	local meioZ = (inicio + calcada) / 2
	parte({ Name = "Passeio", Size = Vector3.new(8, 1.0, comprimento + 1), Position = Vector3.new(centro.X, TOPO - 0.5, meioZ), Color = PEDRA_CLARA, Material = Enum.Material.Pavement, Parent = pasta })
	for _, s in { -1, 1 } do
		parte({ Name = "BordaPasseio", Size = Vector3.new(0.6, 1.1, comprimento + 1), Position = Vector3.new(centro.X + s * 4.3, TOPO - 0.45, meioZ), Color = PEDRA_ESCURA, Material = Enum.Material.Cobblestone, Parent = pasta })
		for z = math.min(inicio, calcada) + 4, math.max(inicio, calcada) - 3, 7 do
			Adereco.colocar("Arbusto", CFrame.new(Vector3.new(centro.X + s * 6.4, 0, z)) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0), pasta, { escala = 0.7, cores = { Copa = escolher(FOLHAS) } })
		end
	end
end

function Cidade.pracas(pai: Instance)
	local pasta = pastaSemLego("Pracas", pai)
	for _, centro in Mapa.FONTES do
		praca(pasta, centro)
	end
	return pasta
end

-- Lugar livre para enfeite na área das bases ----------------------------------

-- Longe da rua, das bases (e do caminho e da esteira de cada uma), das praças
-- com o passeio, da loja de trilhas e do túnel. "folga" afasta mais.
function Cidade.livre(p: Vector3, folga: number?): boolean
	local f = folga or 0
	if math.abs(p.Z) < 16 + f then
		return false -- rua e calçadas
	end
	if p.X < Mapa.TUNEL_BOCA + 6 or p.X > Mapa.FIM_BASES - 8 then
		return false
	end
	if math.abs(p.Z) > Montanhas.Z_BASES - 5 then
		return false -- montanhas
	end
	if p.X < Mapa.TUNEL_BOCA + 30 and math.abs(p.Z) < 48 then
		return false -- túnel da entrada
	end
	for _, centro in Mapa.FONTES do
		if plana(p, centro) < Mapa.RAIO_PRACA + 3 + f then
			return false -- praça
		end
		if math.abs(p.X - centro.X) < 8 + f and p.Z * centro.Z > 0 and math.abs(p.Z) < math.abs(centro.Z) then
			return false -- passeio da praça
		end
	end
	local loja = Mapa.LOJA_TRILHAS
	if math.abs(p.X - loja.X) < 26 + f and math.abs(p.Z - loja.Z) < 24 + f then
		return false -- loja de trilhas
	end
	if math.abs(p.X - loja.X) < 8 + f and p.Z * loja.Z > 0 and math.abs(p.Z) < math.abs(loja.Z) then
		return false -- passeio da loja
	end
	local frente = Mapa.Z_BASES - Mapa.TAMANHO_BASE / 2
	for i = -1, 1 do
		local dx = p.X - i * Mapa.ESPACO_BASES
		for _, lado in { -1, 1 } do
			local dz = p.Z * lado
			if dz > 0 then
				local meia = Mapa.TAMANHO_BASE / 2 + 8 + f
				if math.abs(dx) < meia and math.abs(dz - Mapa.Z_BASES) < meia then
					return false -- a base
				end
				if dz < frente + 4 then
					if math.abs(dx) < 10 + f then
						return false -- caminho
					end
					if math.abs(dx + lado * 20) < 12 + f then
						return false -- esteira (fica em x = base - lado * 20)
					end
				end
			end
		end
	end
	return true
end

-- Árvores (sem uma tampar a outra), arbustos, pedras em grupinhos, flores em
-- canteiros, bancos e luminárias nos caminhos das bases.
function Cidade.arredores(pai: Instance)
	local pasta = pastaSemLego("Arredores", pai)
	local minimo = Vector3.new(Mapa.TUNEL_BOCA, 0.05, -Montanhas.Z_BASES)
	local maximo = Vector3.new(Mapa.FIM_BASES, 0.05, Montanhas.Z_BASES)
	local ocupados = {}
	-- árvores grandes primeiro (mais longe da rua), depois médias e pequenas
	Cidade.espalhar(minimo, maximo, 40, 15, function(p)
		return Cidade.livre(p, 7) and math.abs(p.Z) > 40
	end, function(p)
		Cidade.arvore(pasta, p, aleatorio:NextNumber(1.35, 1.7))
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 60, 11, function(p)
		return Cidade.livre(p, 5)
	end, function(p)
		Cidade.arvore(pasta, p, aleatorio:NextNumber(1.0, 1.3))
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 40, 8, function(p)
		return Cidade.livre(p, 3)
	end, function(p)
		Cidade.arvore(pasta, p, aleatorio:NextNumber(0.7, 0.9), escolher({ "ArvoreRedonda", "ArvoreAlta" }))
	end, ocupados)
	Cidade.espalhar(minimo, maximo, 70, 5, function(p)
		return Cidade.livre(p, 1)
	end, function(p)
		Adereco.colocar("Arbusto", CFrame.new(p) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0), pasta, {
			escala = aleatorio:NextNumber(0.8, 1.3),
			cores = { Copa = escolher(FOLHAS) },
		})
	end, ocupados)
	-- pedras em grupinhos de 2 ou 3, de tamanhos diferentes
	Cidade.espalhar(minimo, maximo, 22, 6, function(p)
		return Cidade.livre(p, 2)
	end, function(p)
		Cidade.pedra(pasta, p, aleatorio:NextNumber(1.1, 1.8))
		for _ = 1, aleatorio:NextInteger(1, 2) do
			local a = aleatorio:NextNumber(0, math.pi * 2)
			Cidade.pedra(pasta, p + Vector3.new(math.cos(a), 0, math.sin(a)) * aleatorio:NextNumber(2.5, 3.5), aleatorio:NextNumber(0.4, 0.8))
		end
	end, ocupados)
	-- canteiros de flores (cada um com cores de uma paleta só, fica mais bonito)
	Cidade.espalhar(minimo, maximo, 34, 6, function(p)
		return Cidade.livre(p, 0)
	end, function(p)
		local cor = escolher(FLORES)
		Cidade.flores(pasta, p, 2.4, aleatorio:NextInteger(6, 10), { cor, cor:Lerp(Color3.new(1, 1, 1), 0.4), escolher(FLORES) })
	end, ocupados)

	-- luminárias nos caminhos das bases e um banco no meio de cada um
	local frente = Mapa.Z_BASES - Mapa.TAMANHO_BASE / 2
	for i = -1, 1 do
		local x = i * Mapa.ESPACO_BASES
		for _, lado in { -1, 1 } do
			for z = 22, frente - 6, 20 do
				for _, dx in { -8, 8 } do
					local lum = Adereco.colocar("Luminaria", CFrame.new(Vector3.new(x + dx, 0.05, lado * z)), pasta, {
						colide = false,
						cores = { Vidro = LUZ_QUENTE },
						materiais = { Vidro = Enum.Material.Neon },
					})
					if not lum then
						enfeite({ Name = "Luminaria", Size = Vector3.new(0.5, 7, 0.5), Position = Vector3.new(x + dx, 3.5, lado * z), Color = FERRO, Parent = pasta })
					end
				end
			end
			local meio = (16 + frente) / 2
			banco(pasta, Vector3.new(x + lado * 11, 0.05, lado * meio), Vector3.new(-lado, 0, 0))
			Cidade.flores(pasta, Vector3.new(x + lado * 11, 0.05, lado * (meio + 6)), 1.6, 6)
			Cidade.flores(pasta, Vector3.new(x + lado * 11, 0.05, lado * (meio - 6)), 1.6, 6)
		end
	end
	return pasta
end

return Cidade

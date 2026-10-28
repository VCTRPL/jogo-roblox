-- Cria os modelos 3D de ovos e Brainrots, com placa de informações e um ProximityPrompt.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Blocos = require(script.Parent.Blocos)

local Modelos = {}

-- Um item é um ovo ou um Brainrot que pode ficar num ninho, numa base ou ser carregado.
export type Item = {
	tipo: string, -- "ovo" ou "brainrot"
	id: string,
	tamanho: string,
	mutacao: string?, -- só Brainrots
	restante: number?, -- só ovos: segundos que faltam para chocar
}

local function peca(modelo: Model, nome: string, tamanho: Vector3, cf: CFrame, cor: Color3, props: any?): Part
	local p = Instance.new("Part")
	p.Name = nome
	p.Size = tamanho
	p.CFrame = cf
	p.Color = cor
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for chave, valor in props or {} do
		(p :: any)[chave] = valor
	end
	p.Parent = modelo
	return p
end

local function bola(modelo: Model, nome: string, diametro: number, cf: CFrame, cor: Color3, props: any?): Part
	local p = peca(modelo, nome, Vector3.one * diametro, cf, cor, props)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Brilhos subindo em volta do item, mais fortes quanto mais raro.
local BRILHO_RARIDADE = { Comum = 0, Raro = 3, Epico = 5, Lendario = 8, Mitico = 12, Secreto = 16 }

local function brilhar(parte: BasePart, cor: Color3, quantidade: number)
	if quantidade <= 0 then
		return
	end
	local emissor = Instance.new("ParticleEmitter")
	emissor.Name = "Brilho"
	emissor.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emissor.Color = ColorSequence.new(cor, Color3.new(1, 1, 1))
	emissor.LightEmission = 1
	emissor.Rate = quantidade
	emissor.Lifetime = NumberRange.new(0.8, 1.6)
	emissor.Speed = NumberRange.new(1, 2.5)
	emissor.SpreadAngle = Vector2.new(180, 180)
	emissor.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emissor.Acceleration = Vector3.new(0, 2, 0)
	emissor.Parent = parte
	local luz = Instance.new("PointLight")
	luz.Color = cor
	-- luz fraca e curta: com vários na base, luz forte estoura o chão
	luz.Range = 4 + quantidade * 0.4
	luz.Brightness = 0.3 + quantidade / 40
	luz.Parent = parte
end

-- Detalhes de cada personagem no boneco padrão.
local ENFEITES = {
	Patapim = function(modelo: Model, cabeca: Part)
		-- copa de árvore em cima da cabeça
		bola(modelo, "Copa", 2.2, cabeca.CFrame * CFrame.new(0, 1.6, 0), Color3.fromRGB(70, 160, 60), { Material = Enum.Material.Grass })
		peca(modelo, "Nariz", Vector3.new(0.7, 0.7, 1.8), cabeca.CFrame * CFrame.new(0, -0.2, -1.4), Color3.fromRGB(150, 110, 70))
	end,
	Larila = function(modelo: Model, cabeca: Part)
		-- tromba de elefante e espinhos de cacto
		peca(modelo, "Tromba", Vector3.new(0.6, 0.6, 2), cabeca.CFrame * CFrame.new(0, -0.6, -1.6) * CFrame.Angles(math.rad(-30), 0, 0), cabeca.Color)
		for i = -1, 1 do
			peca(modelo, "Espinho", Vector3.new(0.2, 0.2, 0.8), cabeca.CFrame * CFrame.new(i * 0.9, -2.4, -1.2), Color3.fromRGB(240, 240, 200))
		end
	end,
	Bananini = function(modelo: Model, cabeca: Part)
		-- casca de banana aberta em volta do macaco
		for i = 0, 3 do
			local giro = CFrame.Angles(0, math.rad(i * 90), 0)
			peca(modelo, "Casca", Vector3.new(1.2, 2.8, 0.3), cabeca.CFrame * giro * CFrame.new(0, -1.6, -1.6) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(255, 225, 70))
		end
	end,
	Cappuccina = function(modelo: Model, cabeca: Part)
		-- saia de bailarina e xícara de café no lugar do chapéu
		local saia = peca(modelo, "Saia", Vector3.new(0.6, 4.6, 4.6), cabeca.CFrame * CFrame.new(0, -3.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 140, 200), { Shape = Enum.PartType.Cylinder })
		saia.Material = Enum.Material.Fabric
		peca(modelo, "Xicara", Vector3.new(1.4, 2.4, 2.4), cabeca.CFrame * CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.new(1, 1, 1), { Shape = Enum.PartType.Cylinder })
	end,
	Tralalero = function(modelo: Model, cabeca: Part)
		-- barbatana de tubarão e tênis azuis
		peca(modelo, "Barbatana", Vector3.new(0.4, 2, 1.6), cabeca.CFrame * CFrame.new(0, 1.6, 0.3) * CFrame.Angles(math.rad(20), 0, 0), cabeca.Color)
		for _, x in { -0.8, 0.8 } do
			peca(modelo, "Tenis", Vector3.new(1.2, 0.8, 1.8), cabeca.CFrame * CFrame.new(x, -6, -0.3), Color3.fromRGB(40, 90, 255), { Material = Enum.Material.Neon })
		end
	end,
	Bombardiro = function(modelo: Model, cabeca: Part)
		-- asas de avião e focinho de crocodilo
		peca(modelo, "Asas", Vector3.new(8, 0.4, 1.8), cabeca.CFrame * CFrame.new(0, -2.4, 0.2), Color3.fromRGB(110, 120, 100), { Material = Enum.Material.Metal })
		peca(modelo, "Focinho", Vector3.new(1.6, 0.9, 2), cabeca.CFrame * CFrame.new(0, -0.3, -1.6), cabeca.Color)
		for _, x in { -0.6, 0.6 } do
			peca(modelo, "Dente", Vector3.new(0.25, 0.4, 0.25), cabeca.CFrame * CFrame.new(x, -0.9, -2.4), Color3.new(1, 1, 1))
		end
	end,
	Ambalabu = function(modelo: Model, cabeca: Part)
		-- sapo dentro de um pneu, com pernas de gente
		for i = 0, 7 do
			local giro = CFrame.Angles(0, math.rad(i * 45), 0)
			peca(modelo, "Pneu", Vector3.new(1.6, 1.4, 0.9), CFrame.new(0, -0.6, 0) * giro * CFrame.new(0, 0, -2.1), Color3.fromRGB(30, 30, 34))
		end
		peca(modelo, "Boca", Vector3.new(2.2, 0.3, 0.4), cabeca.CFrame * CFrame.new(0, -0.6, -1.25), Color3.fromRGB(200, 60, 80))
		for _, perna in modelo:GetChildren() do
			if perna.Name == "Perna" then
				(perna :: Part).Color = Color3.fromRGB(240, 200, 160)
			end
		end
	end,
	Trippi = function(modelo: Model, cabeca: Part)
		-- camarão com cara de gato: orelhas, bigodes e o rabo em gomos
		for _, x in { -0.8, 0.8 } do
			peca(modelo, "Orelha", Vector3.new(0.7, 0.9, 0.4), cabeca.CFrame * CFrame.new(x, 1.5, 0), cabeca.Color)
			peca(modelo, "Bigode", Vector3.new(1.2, 0.1, 0.1), cabeca.CFrame * CFrame.new(x * 1.3, -0.4, -1.2), Color3.new(1, 1, 1))
			peca(modelo, "Antena", Vector3.new(0.15, 2.4, 0.15), cabeca.CFrame * CFrame.new(x * 0.4, 2.2, 0.6) * CFrame.Angles(math.rad(-25), 0, 0), Color3.fromRGB(255, 120, 90))
		end
		for i = 1, 4 do
			local tamanho = 1.6 - i * 0.25
			peca(modelo, "Rabo", Vector3.new(tamanho * 1.4, tamanho, tamanho), CFrame.new(0, -1 - i * 0.3, 1 + i * 0.9), Color3.fromRGB(255, 150 - i * 10, 120))
		end
	end,
	Frigo = function(modelo: Model, cabeca: Part)
		-- geladeira com cabeça de camelo: porta, puxador e duas corcovas
		peca(modelo, "Porta", Vector3.new(3.05, 0.12, 2.05), CFrame.new(0, 0.5, 0), Color3.fromRGB(170, 175, 185))
		peca(modelo, "Puxador", Vector3.new(0.25, 1.4, 0.3), CFrame.new(1, 1, -1.1), Color3.fromRGB(150, 155, 165))
		for i, z in { 0.2, 1.1 } do
			peca(modelo, "Corcova", Vector3.new(1.6, 1.2 - i * 0.2, 1), CFrame.new(0, 2.1, z), Color3.fromRGB(200, 160, 100))
		end
		peca(modelo, "Focinho", Vector3.new(1.4, 1, 1.6), cabeca.CFrame * CFrame.new(0, -0.4, -1.4), cabeca.Color)
		for _, perna in modelo:GetChildren() do
			if perna.Name == "Perna" then
				(perna :: Part).Color = Color3.fromRGB(110, 70, 40) -- botas
			end
		end
	end,
	Glorbo = function(modelo: Model, cabeca: Part)
		-- melancia com focinho de crocodilo: listras e sementes
		for i = -1, 1 do
			peca(modelo, "Listra", Vector3.new(0.4, 3.45, 2.05), CFrame.new(i * 0.9, 0, 0), Color3.fromRGB(30, 100, 40))
		end
		peca(modelo, "Focinho", Vector3.new(1.8, 0.9, 2.2), cabeca.CFrame * CFrame.new(0, -0.4, -1.8), cabeca.Color)
		for _, x in { -0.6, 0, 0.6 } do
			peca(modelo, "Semente", Vector3.new(0.2, 0.35, 0.15), cabeca.CFrame * CFrame.new(x, 0.9, -1.2), Color3.fromRGB(25, 25, 25))
			peca(modelo, "Dente", Vector3.new(0.25, 0.35, 0.25), cabeca.CFrame * CFrame.new(x, -0.95, -2.7), Color3.new(1, 1, 1))
		end
	end,
	Cocofanto = function(modelo: Model, cabeca: Part)
		-- coco com cabeça de elefante: orelhas grandes e tromba
		for _, x in { -1, 1 } do
			peca(modelo, "Orelha", Vector3.new(0.3, 2.2, 2), cabeca.CFrame * CFrame.new(x * 1.6, 0, 0.2) * CFrame.Angles(0, math.rad(x * 20), 0), cabeca.Color:Lerp(Color3.fromRGB(255, 180, 190), 0.25))
		end
		for i = 1, 3 do
			peca(modelo, "Tromba", Vector3.new(0.7, 0.7, 0.9), cabeca.CFrame * CFrame.new(0, -0.4 - i * 0.55, -1.3 - i * 0.25), cabeca.Color)
		end
		peca(modelo, "Pelos", Vector3.new(3.1, 0.4, 2.1), CFrame.new(0, 1.6, 0), Color3.fromRGB(80, 55, 35))
	end,
	Gusini = function(modelo: Model, cabeca: Part)
		-- ganso bombardeiro: bico laranja, asas de avião e bombas
		peca(modelo, "Bico", Vector3.new(1, 0.5, 1.6), cabeca.CFrame * CFrame.new(0, -0.3, -1.6), Color3.fromRGB(255, 150, 40))
		peca(modelo, "Asas", Vector3.new(8.5, 0.4, 2), CFrame.new(0, 0.6, 0.2), Color3.fromRGB(110, 120, 100))
		for _, x in { -3, 3 } do
			peca(modelo, "Bomba", Vector3.new(0.8, 0.8, 1.8), CFrame.new(x, -0.1, 0.2), Color3.fromRGB(50, 55, 50))
			peca(modelo, "Helice", Vector3.new(1.8, 0.2, 0.15), CFrame.new(x * 0.6, 0.6, -1.2), Color3.fromRGB(60, 60, 65))
		end
	end,
	Svinino = function(modelo: Model, cabeca: Part)
		-- porquinho com cabeça de bomba: pavio aceso, focinho e orelhas
		peca(modelo, "Pavio", Vector3.new(0.25, 0.9, 0.25), cabeca.CFrame * CFrame.new(0, 1.8, 0), Color3.fromRGB(200, 180, 140))
		peca(modelo, "Faisca", Vector3.new(0.5, 0.5, 0.5), cabeca.CFrame * CFrame.new(0, 2.4, 0), Color3.fromRGB(255, 200, 40), { Material = Enum.Material.Neon })
		peca(modelo, "Focinho", Vector3.new(1.2, 0.8, 0.5), cabeca.CFrame * CFrame.new(0, -0.5, -1.4), Color3.fromRGB(255, 150, 175))
		for _, x in { -0.9, 0.9 } do
			peca(modelo, "Orelha", Vector3.new(0.7, 0.7, 0.3), cabeca.CFrame * CFrame.new(x, 1.3, -0.2), Color3.fromRGB(255, 170, 190))
		end
	end,
	Udin = function(modelo: Model, cabeca: Part)
		-- o dançarino laranja: cabelo espetado, sorrisão e auréola de neon
		for i = -1, 1 do
			peca(modelo, "Cabelo", Vector3.new(0.6, 1.2, 0.6), cabeca.CFrame * CFrame.new(i * 0.7, 1.6, 0) * CFrame.Angles(0, 0, math.rad(-i * 20)), Color3.fromRGB(255, 120, 20))
		end
		peca(modelo, "Sorriso", Vector3.new(1.6, 0.4, 0.3), cabeca.CFrame * CFrame.new(0, -0.6, -1.3), Color3.fromRGB(120, 30, 40))
		for i = 0, 7 do
			local giro = CFrame.Angles(0, math.rad(i * 45), 0)
			peca(modelo, "Aureola", Vector3.new(0.9, 0.2, 0.25), cabeca.CFrame * CFrame.new(0, 2.6, 0) * giro * CFrame.new(0, 0, -1.1), Color3.fromRGB(255, 240, 150), { Material = Enum.Material.Neon })
		end
	end,
}

local function bonecoBrainrot(def, mutacao): Model
	local modelo = Instance.new("Model")
	local brilhoMutacao = mutacao.cor ~= nil
	local corCorpo = def.cor or Config.CORES_RARIDADE[def.raridade]

	local corpo = peca(modelo, "Corpo", Vector3.new(3, 3.4, 2), CFrame.new(), corCorpo)
	local cabeca = bola(modelo, "Cabeca", 2.8, CFrame.new(0, 3.1, 0), def.corCabeca or Color3.fromRGB(255, 220, 180))

	-- olhos grandes, braços e pernas
	for _, x in { -0.6, 0.6 } do
		bola(modelo, "Olho", 0.9, cabeca.CFrame * CFrame.new(x, 0.35, -1.1), Color3.new(1, 1, 1))
		bola(modelo, "Pupila", 0.45, cabeca.CFrame * CFrame.new(x, 0.35, -1.5), Color3.fromRGB(20, 20, 30))
	end
	for _, x in { -1.9, 1.9 } do
		peca(modelo, "Braco", Vector3.new(0.8, 2.6, 0.8), CFrame.new(x, 0.1, 0) * CFrame.Angles(0, 0, math.rad(x > 0 and -20 or 20)), corCorpo)
	end
	for _, x in { -0.8, 0.8 } do
		peca(modelo, "Perna", Vector3.new(0.9, 1.6, 0.9), CFrame.new(x, -2.5, 0), corCorpo)
	end

	local enfeite = ENFEITES[def.id]
	if enfeite then
		enfeite(modelo, cabeca)
	end

	-- mutação: o corpo fica da cor da mutação, brilhando
	if brilhoMutacao then
		corpo.Color = mutacao.cor
		corpo.Material = Enum.Material.Neon
	end

	local corBrilho = mutacao.cor or Config.CORES_RARIDADE[def.raridade]
	local quantidade = BRILHO_RARIDADE[def.raridade] or 0
	if brilhoMutacao then
		quantidade += 6
	end
	brilhar(corpo, corBrilho, quantidade)

	-- Lendários (e acima) ganham um anel de luz nos pés
	if Config.nivelRaridade(def.raridade) >= Config.nivelRaridade("Lendario") then
		local anel = peca(modelo, "Aura", Vector3.new(0.2, 5, 5), CFrame.new(0, -3.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Config.CORES_RARIDADE[def.raridade], {
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Transparency = 0.4,
		})
		anel.CastShadow = false
	end

	modelo.PrimaryPart = corpo
	return modelo
end

-- Ovo de blocos: camadas quadradas, largas no meio e estreitas nas pontas,
-- na cor do Brainrot que vai nascer, com pintas e uma faixa de neon na cor
-- da raridade.
local CAMADAS_OVO = { { 1.5, 0.4 }, { 2.1, 0.5 }, { 2.4, 0.8 }, { 2.3, 0.5 }, { 1.9, 0.4 }, { 1.2, 0.4 } }

local function bonecoOvo(def): Model
	local modelo = Instance.new("Model")
	local cor = Config.CORES_RARIDADE[def.raridade]
	local brainrot = Config.brainrot(def.brainrot)
	local corCasca = if brainrot then brainrot.cor:Lerp(Color3.new(1, 1, 1), 0.3) else cor
	local corPinta = if brainrot then brainrot.corCabeca else cor:Lerp(Color3.new(1, 1, 1), 0.6)

	local casca: Part? = nil
	local y = -1.5
	for i, camada in CAMADAS_OVO do
		local largura, altura = camada[1], camada[2]
		local p = peca(modelo, if i == 3 then "Casca" else "Camada", Vector3.new(largura, altura, largura), CFrame.new(0, y + altura / 2, 0), corCasca)
		if i == 3 then
			casca = p
		end
		y += altura
	end

	-- pintas nos quatro lados (sempre iguais para o mesmo ovo)
	local aleatorio = Random.new(#def.id)
	for lado = 0, 3 do
		local giro = CFrame.Angles(0, lado * math.pi / 2, 0)
		local deslocamento = if lado % 2 == 0 then 0.45 else -0.45
		for _, altura in { { 0.45, 2.3 }, { -0.85, 2.1 } } do
			local x = deslocamento * (if aleatorio:NextNumber() < 0.5 then 1 else -1)
			peca(modelo, "Pinta", Vector3.new(0.55, 0.38, 0.12), giro * CFrame.new(x, altura[1], -altura[2] / 2 - 0.04), corPinta)
		end
	end
	peca(modelo, "Faixa", Vector3.new(2.52, 0.22, 2.52), CFrame.new(0, -0.2, 0), cor:Lerp(Color3.new(1, 1, 1), 0.3), {
		Material = Enum.Material.Neon,
	})

	local principal = casca :: Part
	brilhar(principal, cor, BRILHO_RARIDADE[def.raridade] or 0)
	modelo.PrimaryPart = principal
	return modelo
end

-- Usa o modelo da pasta do Studio se existir; senão, o boneco padrão.
local function doStudio(pastaNome: string, id: string): Model?
	local pasta = ReplicatedStorage:FindFirstChild(pastaNome)
	local molde = pasta and pasta:FindFirstChild(id)
	if not (molde and molde:IsA("Model")) then
		return nil
	end
	local modelo = molde:Clone()
	-- modelo feito por você: o estilo Lego não mexe nele
	modelo:SetAttribute("Biblioteca", true)
	if not modelo.PrimaryPart then
		modelo.PrimaryPart = modelo:FindFirstChildWhichIsA("BasePart", true)
	end
	if not modelo.PrimaryPart then
		warn(`Modelo {id} não tem nenhuma peça; usando o boneco padrão.`)
		modelo:Destroy()
		return nil
	end
	return modelo
end

local function criarTexto(nome: string, texto: string, cor: Color3, parent: Instance)
	local label = Instance.new("TextLabel")
	label.Name = nome
	label.Size = UDim2.new(1, 0, 0, 22)
	label.BackgroundTransparency = 1
	label.Text = texto
	label.TextColor3 = cor
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

-- Ancora, solda as peças, põe o pivot nos pés e cria placa e prompt.
local function finalizar(modelo: Model, nome: string, escala: number, linhas): Model
	modelo.Name = nome
	-- estilo Lego antes das soldas e do pivot (bolas e cilindros viram blocos)
	if not modelo:GetAttribute("Biblioteca") then
		Blocos.aplicar(modelo)
	end
	if escala ~= 1 then
		modelo:ScaleTo(escala)
	end

	local primaria = modelo.PrimaryPart :: BasePart
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Anchored = true
			parte.CanCollide = false
			parte.CanTouch = false
			parte.Massless = true
			if parte ~= primaria then
				local solda = Instance.new("WeldConstraint")
				solda.Part0 = primaria
				solda.Part1 = parte
				solda.Parent = primaria
			end
		end
	end

	-- pivot embaixo do modelo, para ele ficar em pé em cima da vaga. Com
	-- PrimaryPart o Roblox ignora o WorldPivot, então o ajuste vai no PivotOffset.
	local centro, tamanho = modelo:GetBoundingBox()
	primaria.PivotOffset = primaria.CFrame:ToObjectSpace(centro * CFrame.new(0, -tamanho.Y / 2, 0))
	local topo = centro.Position.Y + tamanho.Y / 2

	local placa = Instance.new("BillboardGui")
	placa.Name = "Placa"
	-- em studs, para as placas das outras bases ficarem pequenas de longe
	placa.Size = UDim2.fromScale(7, 0.9 * #linhas)
	placa.StudsOffsetWorldSpace = Vector3.new(0, topo - primaria.Position.Y + 1 + #linhas * 0.5, 0)
	placa.MaxDistance = 80
	placa.Parent = primaria
	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.Parent = placa
	for ordem, linha in linhas do
		local label = criarTexto(linha[1], linha[2], linha[3], placa)
		label.LayoutOrder = ordem
		label.Size = UDim2.fromScale(1, 1 / #linhas)
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Acao"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = primaria

	return modelo
end

local BRANCO = Color3.new(1, 1, 1)
local VERDE = Color3.fromRGB(90, 255, 120)
local AMARELO = Color3.fromRGB(255, 230, 90)

function Modelos.criar(item: Item): Model
	local tamanho = Config.tamanho(item.tamanho)
	if item.tipo == "ovo" then
		local def = Config.ovo(item.id)
		local modelo = doStudio("ModelosOvo", def.id) or bonecoOvo(def)
		local linhas = {
			{ "Raridade", def.raridade, Config.CORES_RARIDADE[def.raridade] },
			{ "Nome", `{def.nome} ({tamanho.nome})`, BRANCO },
			{ "Tempo", `Choca em {def.chocar}s`, AMARELO },
		}
		finalizar(modelo, def.id, tamanho.escala, linhas)
		Modelos.prompt(modelo).ObjectText = def.nome
		-- o cliente põe os efeitos do ovo (aura, flutuar, rachar)
		modelo:SetAttribute("Raridade", def.raridade)
		CollectionService:AddTag(modelo, "Ovo")
		return modelo
	end

	local def = Config.brainrot(item.id)
	local mutacao = Config.mutacao(item.mutacao)
	local modelo = doStudio("ModelosBrainrot", def.id) or bonecoBrainrot(def, mutacao)
	local nome = if mutacao.nome == "Normal" then def.nome else `{def.nome} {mutacao.nome}`
	local linhas = {
		{ "Raridade", def.raridade, Config.CORES_RARIDADE[def.raridade] },
		{ "Nome", `{nome} ({tamanho.nome})`, mutacao.cor or BRANCO },
		{ "Renda", `${Config.formatar(Config.renda(item))}/s`, VERDE },
	}
	finalizar(modelo, def.id, tamanho.escala, linhas)
	Modelos.prompt(modelo).ObjectText = nome
	return modelo
end

-- Só o boneco de um Brainrot, sem placa nem botão: para as estátuas do mapa.
function Modelos.boneco(id: string, mutacao: string?): Model?
	local def = Config.brainrot(id)
	if not def then
		return nil
	end
	local modelo = doStudio("ModelosBrainrot", def.id)
	if not modelo then
		modelo = bonecoBrainrot(def, Config.mutacao(mutacao))
		Blocos.aplicar(modelo)
	end
	return modelo
end

function Modelos.prompt(modelo: Model): ProximityPrompt
	return (modelo.PrimaryPart :: BasePart):FindFirstChild("Acao") :: ProximityPrompt
end

-- Muda uma linha da placa (por exemplo o tempo que falta para chocar).
function Modelos.textoPlaca(modelo: Model, linha: string, texto: string)
	local placa = (modelo.PrimaryPart :: BasePart):FindFirstChild("Placa")
	local label = placa and placa:FindFirstChild(linha)
	if label then
		(label :: TextLabel).Text = texto
	end
end

-- Solta o modelo das âncoras e gruda em cima da cabeça de um personagem.
function Modelos.grudar(modelo: Model, raiz: BasePart)
	local primaria = modelo.PrimaryPart :: BasePart
	modelo:PivotTo(raiz.CFrame * CFrame.new(0, 3, 0))
	local solda = Instance.new("WeldConstraint")
	solda.Part0 = raiz
	solda.Part1 = primaria
	solda.Parent = primaria
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Anchored = false
		end
	end
end

return Modelos

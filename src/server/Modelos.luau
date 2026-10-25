-- Cria os modelos 3D de ovos e Brainrots, com placa de informações e um ProximityPrompt.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

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
local BRILHO_RARIDADE = { Comum = 0, Raro = 3, Epico = 5, Lendario = 8, Mitico = 12 }

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
	luz.Range = 6 + quantidade
	luz.Brightness = 0.6 + quantidade / 10
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

	-- Lendários e Míticos ganham um anel de luz nos pés
	if def.raridade == "Lendario" or def.raridade == "Mitico" then
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

local function bonecoOvo(def): Model
	local modelo = Instance.new("Model")
	local cor = Config.CORES_RARIDADE[def.raridade]
	local casca = peca(modelo, "Casca", Vector3.new(2.4, 3, 2.4), CFrame.new(), cor, { Material = Enum.Material.Glass, Reflectance = 0.15 })
	local malha = Instance.new("SpecialMesh")
	malha.MeshType = Enum.MeshType.Sphere
	malha.Parent = casca

	-- pintas e uma faixa brilhante
	local aleatorio = Random.new(#def.id)
	for _ = 1, 6 do
		local direcao = aleatorio:NextUnitVector()
		local ponto = Vector3.new(direcao.X * 1.1, direcao.Y * 1.35, direcao.Z * 1.1)
		bola(modelo, "Pinta", 0.6, CFrame.new(ponto), cor:Lerp(Color3.new(1, 1, 1), 0.6))
	end
	local faixa = peca(modelo, "Faixa", Vector3.new(0.35, 2.5, 2.5), CFrame.Angles(0, 0, math.rad(90)), Color3.new(1, 1, 1), {
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Neon,
	})
	faixa.Color = cor:Lerp(Color3.new(1, 1, 1), 0.3)

	brilhar(casca, cor, BRILHO_RARIDADE[def.raridade] or 0)
	modelo.PrimaryPart = casca
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

	local centro, tamanho = modelo:GetBoundingBox()
	modelo.WorldPivot = centro * CFrame.new(0, -tamanho.Y / 2, 0)
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
	return doStudio("ModelosBrainrot", def.id) or bonecoBrainrot(def, Config.mutacao(mutacao))
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

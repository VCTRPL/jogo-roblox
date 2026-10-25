-- Cria os modelos 3D de ovos e Verities, com placa de informações e um ProximityPrompt.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Modelos = {}

-- Um item é um ovo ou um Verity que pode ficar num ninho, numa base ou ser carregado.
export type Item = {
	tipo: string, -- "ovo" ou "verity"
	id: string,
	tamanho: string,
	mutacao: string?, -- só Verities
	restante: number?, -- só ovos: segundos que faltam para chocar
}

local function bonecoVerity(def, mutacao): Model
	local modelo = Instance.new("Model")

	local corpo = Instance.new("Part")
	corpo.Name = "Corpo"
	corpo.Size = Vector3.new(3, 4, 2)
	corpo.Color = Config.CORES_RARIDADE[def.raridade]
	corpo.Material = Enum.Material.SmoothPlastic
	corpo.CFrame = CFrame.new()
	corpo.Parent = modelo

	local cabeca = Instance.new("Part")
	cabeca.Name = "Cabeca"
	cabeca.Shape = Enum.PartType.Ball
	cabeca.Size = Vector3.new(2.6, 2.6, 2.6)
	cabeca.Color = mutacao.cor or Color3.fromRGB(255, 220, 180)
	cabeca.Material = if mutacao.cor then Enum.Material.Neon else Enum.Material.SmoothPlastic
	cabeca.CFrame = CFrame.new(0, 3.2, 0)
	cabeca.Parent = modelo

	modelo.PrimaryPart = corpo
	return modelo
end

local function bonecoOvo(def): Model
	local modelo = Instance.new("Model")
	local casca = Instance.new("Part")
	casca.Name = "Casca"
	casca.Size = Vector3.new(2.4, 3, 2.4)
	casca.Color = Config.CORES_RARIDADE[def.raridade]
	casca.Material = Enum.Material.SmoothPlastic
	casca.CFrame = CFrame.new()
	local malha = Instance.new("SpecialMesh")
	malha.MeshType = Enum.MeshType.Sphere
	malha.Parent = casca
	casca.Parent = modelo
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
	placa.Size = UDim2.fromOffset(180, 22 * #linhas)
	placa.StudsOffsetWorldSpace = Vector3.new(0, topo - primaria.Position.Y + 1 + #linhas * 0.5, 0)
	placa.MaxDistance = 80
	placa.Parent = primaria
	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.Parent = placa
	for ordem, linha in linhas do
		criarTexto(linha[1], linha[2], linha[3], placa).LayoutOrder = ordem
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

	local def = Config.verity(item.id)
	local mutacao = Config.mutacao(item.mutacao)
	local modelo = doStudio("ModelosVerity", def.id) or bonecoVerity(def, mutacao)
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

-- Cria o modelo 3D de um Verity, com placa de nome e um ProximityPrompt.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Verities = {}

-- Boneco simples usado enquanto não existe um modelo de verdade.
local function criarBoneco(def): Model
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
	cabeca.Color = Color3.fromRGB(255, 220, 180)
	cabeca.CFrame = CFrame.new(0, 3.2, 0)
	cabeca.Parent = modelo

	modelo.PrimaryPart = corpo
	return modelo
end

local function criarModelo(def): Model
	local pasta = ReplicatedStorage:FindFirstChild("ModelosVerity")
	local molde = pasta and pasta:FindFirstChild(def.id)
	if molde and molde:IsA("Model") then
		local modelo = molde:Clone()
		if not modelo.PrimaryPart then
			modelo.PrimaryPart = modelo:FindFirstChildWhichIsA("BasePart", true)
		end
		if modelo.PrimaryPart then
			return modelo
		end
		warn(`Modelo {def.id} não tem nenhuma peça; usando o boneco padrão.`)
		modelo:Destroy()
	end
	return criarBoneco(def)
end

local function criarTexto(nome: string, texto: string, cor: Color3, ordem: number, parent: Instance)
	local label = Instance.new("TextLabel")
	label.Name = nome
	label.Size = UDim2.new(1, 0, 0.25, 0)
	label.Position = UDim2.fromScale(0, ordem * 0.25)
	label.BackgroundTransparency = 1
	label.Text = texto
	label.TextColor3 = cor
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

-- Cria o Verity. O "pivot" do modelo fica nos pés, então basta usar
-- modelo:PivotTo(cframeDoChao) para colocá-lo em cima de algo.
function Verities.criar(def): Model
	local modelo = criarModelo(def)
	modelo.Name = def.id
	modelo:SetAttribute("VerityId", def.id)

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
	placa.Size = UDim2.fromOffset(180, 80)
	placa.StudsOffsetWorldSpace = Vector3.new(0, topo - primaria.Position.Y + 2, 0)
	placa.MaxDistance = 80
	placa.Parent = primaria
	criarTexto("Raridade", def.raridade, Config.CORES_RARIDADE[def.raridade], 0, placa)
	criarTexto("Nome", def.nome, Color3.new(1, 1, 1), 1, placa)
	criarTexto("Renda", `${Config.formatar(def.renda)}/s`, Color3.fromRGB(90, 255, 120), 2, placa)
	criarTexto("Preco", `${Config.formatar(def.preco)}`, Color3.fromRGB(255, 230, 90), 3, placa)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Acao"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.ObjectText = def.nome
	prompt.Parent = primaria

	return modelo
end

function Verities.prompt(modelo: Model): ProximityPrompt
	return (modelo.PrimaryPart :: BasePart):FindFirstChild("Acao") :: ProximityPrompt
end

-- Solta o modelo das âncoras e gruda nas costas/cabeça de um personagem.
function Verities.grudar(modelo: Model, raiz: BasePart)
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

return Verities

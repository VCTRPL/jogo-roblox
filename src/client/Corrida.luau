-- Efeitos de quem está correndo na esteira: riscos de vento passando pelo
-- corpo, faíscas saindo dos pés, uma luz na cor da esteira e, para você,
-- "+Velocidade" pulando e a câmera abrindo um pouco. Também faz as luzes
-- das esteiras pulsarem. Tudo só neste computador.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Corrida = {}

local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local CAMPO_DE_VISAO = 70
local CAMPO_CORRENDO = 80

local jogador = Players.LocalPlayer

type Efeito = { pecas: { Instance } }
local ativos: { [Player]: Efeito } = {}

local function corDa(player: Player): Color3
	local nivel = Config.NIVEIS_ESTEIRA[player:GetAttribute("NivelEsteira") or 1] or Config.NIVEIS_ESTEIRA[1]
	return nivel.cor or Color3.new(1, 1, 1)
end

local function desligar(player: Player)
	local efeito = ativos[player]
	if efeito then
		ativos[player] = nil
		for _, peca in efeito.pecas do
			peca:Destroy()
		end
	end
end

local function ligar(player: Player)
	local personagem = player.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz or ativos[player] then
		return
	end
	local cor = corDa(player)
	local nivel = player:GetAttribute("NivelEsteira") or 1

	-- riscos de vento passando pelo corpo, de frente para trás
	local corpo = Instance.new("Attachment")
	corpo.Name = "CorridaVento"
	corpo.Position = Vector3.new(0, 0.5, -1.5)
	corpo.Parent = raiz
	local vento = Instance.new("ParticleEmitter")
	vento.Texture = FAISCA
	vento.Color = ColorSequence.new(Color3.new(1, 1, 1), cor)
	vento.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	vento.Size = NumberSequence.new(0.22)
	vento.Squash = NumberSequence.new(-2.5)
	vento.Orientation = Enum.ParticleOrientation.VelocityParallel
	vento.EmissionDirection = Enum.NormalId.Back
	vento.SpreadAngle = Vector2.new(35, 50)
	vento.Speed = NumberRange.new(28, 40)
	vento.Lifetime = NumberRange.new(0.18, 0.3)
	vento.Rate = 20 + nivel * 8
	vento.LightEmission = 1
	vento.Parent = corpo

	-- faíscas (ou poeira na esteira básica) saindo dos pés
	local pes = Instance.new("Attachment")
	pes.Name = "CorridaPes"
	pes.Position = Vector3.new(0, -2.8, 0.4)
	pes.Parent = raiz
	local faiscas = Instance.new("ParticleEmitter")
	faiscas.Texture = FAISCA
	faiscas.Color = ColorSequence.new(Color3.fromRGB(255, 250, 220), cor)
	faiscas.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	faiscas.EmissionDirection = Enum.NormalId.Back
	faiscas.SpreadAngle = Vector2.new(40, 40)
	faiscas.Speed = NumberRange.new(6, 12)
	faiscas.Acceleration = Vector3.new(0, -30, 0)
	faiscas.Lifetime = NumberRange.new(0.3, 0.6)
	faiscas.Rate = 10 + nivel * 6
	faiscas.LightEmission = 1
	faiscas.Parent = pes

	local luz = Instance.new("PointLight")
	luz.Color = cor
	luz.Range = 10
	luz.Brightness = 1.5
	luz.Parent = raiz

	ativos[player] = { pecas = { corpo, pes, luz } }
end

local function atualizar(player: Player)
	desligar(player)
	if player:GetAttribute("NaEsteira") then
		ligar(player)
	end
	if player == jogador then
		local camera = Workspace.CurrentCamera
		if camera then
			local campo = if player:GetAttribute("NaEsteira") then CAMPO_CORRENDO else CAMPO_DE_VISAO
			TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { FieldOfView = campo }):Play()
		end
	end
end

-- "+3 ⚡" pulando em cima da sua cabeça enquanto você corre.
local ultimoTexto = 0
local function mostrarGanho(ganho: number)
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not raiz or os.clock() - ultimoTexto < 0.2 then
		return
	end
	ultimoTexto = os.clock()
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(4, 1.3)
	gui.StudsOffsetWorldSpace = Vector3.new(math.random(-15, 15) / 10, 3, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = raiz
	gui.Parent = raiz
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = `+{Config.formatar(ganho)} ⚡`
	label.TextColor3 = corDa(jogador):Lerp(Color3.new(1, 1, 1), 0.3)
	label.TextStrokeColor3 = Color3.fromRGB(25, 20, 45)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	local info = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 0.85)
end

local function acompanhar(player: Player)
	player:GetAttributeChangedSignal("NaEsteira"):Connect(function()
		atualizar(player)
	end)
	player:GetAttributeChangedSignal("NivelEsteira"):Connect(function()
		atualizar(player)
	end)
	player.CharacterAdded:Connect(function()
		ativos[player] = nil -- as peças sumiram com o personagem antigo
		task.wait(0.5)
		atualizar(player)
	end)
	atualizar(player)
end

function Corrida.iniciar()
	Players.PlayerAdded:Connect(acompanhar)
	for _, player in Players:GetPlayers() do
		task.spawn(acompanhar, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ativos[player] = nil
	end)

	task.spawn(function()
		local stats = jogador:WaitForChild("leaderstats")
		local velocidade = stats:WaitForChild("Velocidade") :: IntValue
		local anterior = velocidade.Value
		velocidade.Changed:Connect(function()
			local ganho = velocidade.Value - anterior
			anterior = velocidade.Value
			if ganho > 0 and jogador:GetAttribute("NaEsteira") then
				mostrarGanho(ganho)
			end
		end)
	end)

	-- luzes das esteiras pulsando: a cor vai e volta para um tom mais claro
	local base: { [BasePart]: Color3 } = {}
	CollectionService:GetInstanceRemovedSignal("PulsarEsteira"):Connect(function(parte)
		base[parte :: BasePart] = nil
	end)
	RunService.RenderStepped:Connect(function()
		local agora = os.clock()
		for _, parte in CollectionService:GetTagged("PulsarEsteira") do
			if parte:IsA("BasePart") then
				local cor = base[parte]
				if not cor then
					cor = parte.Color
					base[parte] = cor
				end
				local onda = (math.sin(agora * 4 + parte.Position.X * 0.2 + parte.Position.Z * 0.2) + 1) / 2
				parte.Color = cor:Lerp(Color3.new(1, 1, 1), onda * 0.45)
			end
		end
	end)
end

return Corrida

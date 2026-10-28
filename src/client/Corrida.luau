-- Efeitos de quem está correndo na esteira: riscos de vento passando pelo
-- corpo, faíscas saindo dos pés, rastro e uma luz na cor da esteira e, para
-- você, "+Velocidade" pulando, linhas de velocidade na tela, a barra do
-- fôlego e a câmera abrindo um pouco. Também faz as luzes das esteiras
-- pulsarem. Tudo só neste computador.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ui = require(script.Parent.Ui)

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

	-- rastro atrás do corpo (as pernas "ficam" para trás, como em desenho)
	local cima = Instance.new("Attachment")
	cima.Name = "CorridaRastroCima"
	cima.Position = Vector3.new(0, 1, 0.6)
	cima.Parent = raiz
	local baixo = Instance.new("Attachment")
	baixo.Name = "CorridaRastroBaixo"
	baixo.Position = Vector3.new(0, -2.4, 0.6)
	baixo.Parent = raiz
	local rastro = Instance.new("Trail")
	rastro.Attachment0 = cima
	rastro.Attachment1 = baixo
	rastro.Color = ColorSequence.new(cor, Color3.new(1, 1, 1))
	rastro.Transparency = NumberSequence.new(0.55, 1)
	rastro.LightEmission = 0.7
	rastro.Lifetime = 0.25
	rastro.FaceCamera = true
	rastro.Parent = raiz
	-- na esteira o corpo fica parado, então o rastro é empurrado para trás pelo vento
	local vel = Instance.new("ParticleEmitter")
	vel.Texture = FAISCA
	vel.Color = ColorSequence.new(cor)
	vel.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.1) })
	vel.Transparency = NumberSequence.new(0.6, 1)
	vel.Squash = NumberSequence.new(-1.5)
	vel.EmissionDirection = Enum.NormalId.Back
	vel.Speed = NumberRange.new(14, 18)
	vel.SpreadAngle = Vector2.new(4, 20)
	vel.Lifetime = NumberRange.new(0.15, 0.25)
	vel.Rate = 12 + nivel * 4
	vel.LightEmission = 0.8
	vel.Parent = baixo

	ativos[player] = { pecas = { corpo, pes, luz, cima, baixo, rastro } }
end

-- Na esteira o personagem fica parado no lugar, então a corrida é uma
-- animação: a mesma "run" do script Animate do personagem.
local trilha: AnimationTrack? = nil

local function animarCorrida(ligada: boolean)
	if trilha then
		trilha:Stop(0.2)
		trilha = nil
	end
	local personagem = jogador.Character
	local hum = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local animador = hum and hum:FindFirstChildOfClass("Animator")
	local animate = personagem and personagem:FindFirstChild("Animate")
	local correr = animate and animate:FindFirstChild("run")
	local animacao = correr and correr:FindFirstChildOfClass("Animation")
	if ligada and animador and animacao then
		local nova = animador:LoadAnimation(animacao)
		nova.Priority = Enum.AnimationPriority.Action
		nova.Looped = true
		nova:Play(0.2)
		nova:AdjustSpeed(1.6)
		trilha = nova
	end
end

-- Botão "Sair" embaixo enquanto corre (pular também sai).
local tela = Ui.tela("Corrida", 1)
local botaoSair = Ui.criar("TextButton", {
	Name = "Sair",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -26),
	Size = UDim2.fromOffset(220, 62),
	BackgroundColor3 = Ui.BRANCO,
	Text = "",
	Visible = false,
	Parent = tela,
}, { Ui.cantos(18), Ui.borda(Ui.CONTORNO, 3.5), Ui.gradiente(Color3.fromRGB(255, 120, 120), Color3.fromRGB(210, 40, 60)) })
Ui.texto({ Text = "SAIR DA ESTEIRA", Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 1, -20), Parent = botaoSair })

-- Barra do fôlego em cima do botão "Sair".
local quadroFolego = Ui.criar("Frame", {
	Name = "Folego",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -100),
	Size = UDim2.fromOffset(300, 46),
	BackgroundColor3 = Ui.BRANCO,
	Visible = false,
	Parent = tela,
}, { Ui.cantos(14), Ui.borda(Ui.CONTORNO, 3), Ui.gradiente(Color3.fromRGB(70, 62, 120), Color3.fromRGB(36, 30, 66)) })
local escalaFolego = Ui.criar("UIScale", { Parent = quadroFolego })
local trilhoFolego = Ui.criar("Frame", {
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 1, -16),
	BackgroundColor3 = Color3.fromRGB(15, 12, 30),
	ClipsDescendants = true,
	Parent = quadroFolego,
}, { Ui.cantos(10) })
local enchimentoFolego = Ui.criar("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Ui.BRANCO,
	Parent = trilhoFolego,
}, { Ui.cantos(10), Ui.gradiente(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 90, 40)) })
local textoFolego = Ui.texto({ Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = trilhoFolego })
local folegoMostrado = 1

local function atualizarFolego()
	local folego = jogador:GetAttribute("Folego") or 1
	local fracao = math.clamp((folego - 1) / (Config.FOLEGO_MAXIMO - 1), 0, 1)
	TweenService:Create(enchimentoFolego, TweenInfo.new(0.4), { Size = UDim2.fromScale(fracao, 1) }):Play()
	textoFolego.Text = if fracao >= 1 then `🔥 FÔLEGO MÁXIMO {folego}x!` else `🔥 FÔLEGO {folego}x`
	if folego > folegoMostrado and math.floor(folego * 2) > math.floor(folegoMostrado * 2) then
		Ui.pular(escalaFolego, 1.15) -- pula a cada meio "x"
	end
	folegoMostrado = folego
end
jogador:GetAttributeChangedSignal("Folego"):Connect(atualizarFolego)

-- Linhas de velocidade passando pelas bordas da tela enquanto você corre.
local telaLinhas = Ui.criar("ScreenGui", {
	Name = "LinhasVelocidade",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = -1,
	Parent = jogador:WaitForChild("PlayerGui"),
})
type Linha = { quadro: Frame, angulo: number, inicio: number, duracao: number }
local linhas: { Linha } = {}
for _ = 1, 26 do
	local quadro = Ui.criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Ui.BRANCO,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		Parent = telaLinhas,
	})
	table.insert(linhas, { quadro = quadro, angulo = 0, inicio = -10, duracao = 0.3 })
end

local function animarLinhas()
	local correndo = jogador:GetAttribute("NaEsteira") == true
	local agora = os.clock()
	local nivel = jogador:GetAttribute("NivelEsteira") or 1
	local folego = jogador:GetAttribute("Folego") or 1
	-- mais linhas e mais fortes com esteira melhor e mais fôlego
	local ativas = if correndo then math.floor(6 + nivel * 2 + (folego - 1) * 8) else 0
	local cor = corDa(jogador)
	for i, linha in linhas do
		local quadro = linha.quadro
		if i > ativas then
			quadro.BackgroundTransparency = 1
			continue
		end
		local t = (agora - linha.inicio) / linha.duracao
		if t >= 1 then
			-- nova linha num ângulo qualquer, perto da borda da tela
			linha.angulo = math.random() * math.pi * 2
			linha.inicio = agora
			linha.duracao = 0.18 + math.random() * 0.2
			quadro.BackgroundColor3 = if math.random() < 0.5 then Ui.BRANCO else cor:Lerp(Ui.BRANCO, 0.5)
			t = 0
		end
		-- anda de fora para dentro e some
		local distancia = 0.75 - t * 0.25
		quadro.Position = UDim2.fromScale(0.5 + math.cos(linha.angulo) * distancia, 0.5 + math.sin(linha.angulo) * distancia)
		quadro.Rotation = math.deg(linha.angulo)
		quadro.Size = UDim2.new(0, 140 + nivel * 15, 0, 3)
		quadro.BackgroundTransparency = 0.35 + t * 0.65
	end
end

local function pedirSaida()
	if jogador:GetAttribute("NaEsteira") then
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local sair = remotes and remotes:FindFirstChild("SairEsteira")
		if sair then
			(sair :: RemoteEvent):FireServer()
		end
	end
end
botaoSair.Activated:Connect(pedirSaida)
UserInputService.JumpRequest:Connect(pedirSaida)

local function atualizar(player: Player)
	desligar(player)
	if player:GetAttribute("NaEsteira") then
		ligar(player)
	end
	if player == jogador then
		local naEsteira = player:GetAttribute("NaEsteira") == true
		botaoSair.Visible = naEsteira
		quadroFolego.Visible = naEsteira
		if naEsteira then
			folegoMostrado = 1
			atualizarFolego()
		end
		animarCorrida(naEsteira)
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
	RunService.RenderStepped:Connect(animarLinhas)
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

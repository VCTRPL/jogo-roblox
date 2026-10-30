-- Clima de cada bioma, só neste computador: quando você entra num bioma a
-- cor da tela muda de leve, aparecem partículas em volta (vaga-lumes na
-- Selva, brisa na Praia, areia voando no Deserto, cinzas e brasas no
-- Vulcão, estrelas no Espaço) e o nome do bioma aparece grande na tela.
-- O servidor diz em que bioma você está pelo atributo "Bioma".
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Tremor = require(script.Parent.Tremor)
local Ui = require(script.Parent.Ui)

local Ambiente = {}

local jogador = Players.LocalPlayer
local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"
local FOGO = "rbxasset://textures/particles/fire_main.dds"
local BRASA = "rbxasset://textures/particles/fire_sparks_main.dds"

type Clima = {
	tinta: Color3, -- cor da tela
	brilho: number,
	saturacao: number?,
	nevoa: { cor: Color3, densidade: number, brilho: number }?, -- Atmosphere
	particulas: { { [string]: any } },
}

local CLIMAS: { [string]: Clima } = {
	floresta = {
		tinta = Color3.fromRGB(235, 255, 230),
		brilho = 0,
		particulas = {
			{ -- vaga-lumes
				Texture = FAISCA,
				Color = ColorSequence.new(Color3.fromRGB(220, 255, 120)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(3, 5),
				Rate = 18,
				Speed = NumberRange.new(0.5, 1.5),
				SpreadAngle = Vector2.new(180, 180),
				LightEmission = 1,
			},
			{ -- folhas caindo e rodopiando
				Texture = FUMACA,
				Color = ColorSequence.new(Color3.fromRGB(120, 200, 70), Color3.fromRGB(200, 220, 60)),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, 0.1), NumberSequenceKeypoint.new(0.85, 0.1), NumberSequenceKeypoint.new(1, 1) }),
				Size = NumberSequence.new(0.45),
				Squash = NumberSequence.new(0.6),
				Lifetime = NumberRange.new(5, 7),
				Rate = 9,
				Speed = NumberRange.new(1, 2),
				EmissionDirection = Enum.NormalId.Bottom,
				SpreadAngle = Vector2.new(40, 40),
				Acceleration = Vector3.new(1.5, -1.2, 0.5),
				Rotation = NumberRange.new(0, 360),
				RotSpeed = NumberRange.new(-160, 160),
			},
			{ -- pólen dourado no ar
				Texture = FAISCA,
				Color = ColorSequence.new(Color3.fromRGB(255, 240, 170)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.12), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(4, 6),
				Rate = 25,
				Speed = NumberRange.new(0.2, 0.6),
				SpreadAngle = Vector2.new(180, 180),
				LightEmission = 0.6,
			},
		},
		saturacao = 0.15,
		nevoa = { cor = Color3.fromRGB(190, 230, 170), densidade = 0.38, brilho = 0.3 },
	},
	praia = {
		tinta = Color3.fromRGB(235, 248, 255),
		brilho = 0.03,
		particulas = {
			{ -- brisa do mar
				Texture = FAISCA,
				Color = ColorSequence.new(Color3.fromRGB(200, 240, 255)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(2, 4),
				Rate = 12,
				Speed = NumberRange.new(4, 7),
				EmissionDirection = Enum.NormalId.Front,
				SpreadAngle = Vector2.new(20, 20),
				LightEmission = 0.8,
			},
			{ -- borrifo do mar, salgadinho
				Texture = FUMACA,
				Color = ColorSequence.new(Color3.fromRGB(240, 250, 255)),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.85), NumberSequenceKeypoint.new(1, 1) }),
				Size = NumberSequence.new(3, 6),
				Lifetime = NumberRange.new(3, 4),
				Rate = 4,
				Speed = NumberRange.new(3, 5),
				EmissionDirection = Enum.NormalId.Front,
				SpreadAngle = Vector2.new(15, 10),
			},
		},
		saturacao = 0.2,
		nevoa = { cor = Color3.fromRGB(200, 235, 255), densidade = 0.3, brilho = 0.4 },
	},
	deserto = {
		tinta = Color3.fromRGB(255, 240, 210),
		brilho = 0.04,
		particulas = {
			{ -- areia voando com o vento
				Texture = FUMACA,
				Color = ColorSequence.new(Color3.fromRGB(235, 205, 150)),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.75), NumberSequenceKeypoint.new(1, 1) }),
				Size = NumberSequence.new(4, 9),
				Lifetime = NumberRange.new(2, 3),
				Rate = 10,
				Speed = NumberRange.new(14, 22),
				EmissionDirection = Enum.NormalId.Front,
				SpreadAngle = Vector2.new(10, 5),
			},
			{ -- grãozinhos de areia rápidos, rente ao chão
				Texture = FAISCA,
				Color = ColorSequence.new(Color3.fromRGB(250, 220, 160)),
				Size = NumberSequence.new(0.12),
				Squash = NumberSequence.new(-1.5),
				Orientation = Enum.ParticleOrientation.VelocityParallel,
				Lifetime = NumberRange.new(0.8, 1.4),
				Rate = 35,
				Speed = NumberRange.new(25, 35),
				EmissionDirection = Enum.NormalId.Front,
				SpreadAngle = Vector2.new(5, 3),
				Acceleration = Vector3.new(0, -2, 0),
			},
		},
		saturacao = 0.1,
		nevoa = { cor = Color3.fromRGB(240, 210, 160), densidade = 0.42, brilho = 0.5 },
	},
	vulcao = {
		tinta = Color3.fromRGB(255, 215, 195),
		brilho = -0.03,
		particulas = {
			{ -- brasas subindo
				Texture = FOGO,
				Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 80, 20)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(2, 3),
				Rate = 20,
				Speed = NumberRange.new(2, 5),
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(30, 30),
				LightEmission = 1,
			},
			{ -- cinzas caindo
				Texture = FUMACA,
				Color = ColorSequence.new(Color3.fromRGB(90, 85, 85)),
				Transparency = NumberSequence.new(0.5, 1),
				Size = NumberSequence.new(0.4, 0.8),
				Lifetime = NumberRange.new(3, 5),
				Rate = 25,
				Speed = NumberRange.new(2, 4),
				EmissionDirection = Enum.NormalId.Bottom,
				SpreadAngle = Vector2.new(25, 25),
			},
			{ -- faíscas estalando perto do chão
				Texture = BRASA,
				Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 60, 10)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(0.6, 1.2),
				Rate = 12,
				Speed = NumberRange.new(6, 12),
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(40, 40),
				Acceleration = Vector3.new(0, -20, 0),
				LightEmission = 1,
			},
		},
		saturacao = 0.15,
		nevoa = { cor = Color3.fromRGB(150, 80, 60), densidade = 0.45, brilho = 0.1 },
	},
	espaco = {
		tinta = Color3.fromRGB(220, 215, 255),
		brilho = -0.02,
		particulas = {
			{ -- estrelinhas piscando em volta
				Texture = FAISCA,
				Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(160, 200, 255)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(1.5, 3),
				Rate = 30,
				Speed = NumberRange.new(0, 0.3),
				SpreadAngle = Vector2.new(180, 180),
				LightEmission = 1,
			},
			{ -- poeira cósmica roxa flutuando
				Texture = FUMACA,
				Color = ColorSequence.new(Color3.fromRGB(150, 90, 255), Color3.fromRGB(80, 160, 255)),
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.82), NumberSequenceKeypoint.new(1, 1) }),
				Size = NumberSequence.new(6, 10),
				Lifetime = NumberRange.new(5, 7),
				Rate = 2,
				Speed = NumberRange.new(0.3, 0.8),
				SpreadAngle = Vector2.new(180, 180),
				Rotation = NumberRange.new(0, 360),
				RotSpeed = NumberRange.new(-10, 10),
				LightEmission = 0.5,
			},
		},
		saturacao = 0.25,
		nevoa = { cor = Color3.fromRGB(70, 50, 140), densidade = 0.4, brilho = 0.2 },
	},
}

local cor = Instance.new("ColorCorrectionEffect")
cor.Name = "CorBioma"
cor.Parent = Lighting

-- caixa invisível que segue a câmera; as partículas nascem dentro dela
local caixa = Instance.new("Part")
caixa.Name = "ClimaBioma"
caixa.Anchored = true
caixa.CanCollide = false
caixa.CanQuery = false
caixa.CanTouch = false
caixa.Transparency = 1
caixa.Size = Vector3.new(70, 24, 70)
caixa.Parent = Workspace
local emissores: { ParticleEmitter } = {}
local estiloAtual: string? = nil

-- névoa do jogo fora dos biomas (para voltar a ela)
local atmosfera = Lighting:FindFirstChildOfClass("Atmosphere")
local nevoaOriginal = atmosfera and { cor = atmosfera.Color, densidade = atmosfera.Density, brilho = atmosfera.Glare }

-- Clarão na tela ao passar por um portal --------------------------------------

local telaClarao = Ui.criar("ScreenGui", {
	Name = "ClaraoBioma",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 5,
	Parent = jogador:WaitForChild("PlayerGui"),
})
local clarao = Ui.criar("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = telaClarao,
}, {
	-- mais forte nas bordas, o meio fica quase limpo
	Ui.criar("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		}),
	}),
})

local function piscar(corBioma: Color3)
	clarao.BackgroundColor3 = corBioma:Lerp(Color3.new(1, 1, 1), 0.5)
	clarao.BackgroundTransparency = 0.15
	TweenService:Create(clarao, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	Tremor.soco(9)
	Tremor.sacudir(0.25, 0.3)
end

-- Nome do bioma aparecendo grande ----------------------------------------------

local tela = Ui.tela("Ambiente", 0)
local titulo = Ui.texto({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.26),
	Size = UDim2.fromOffset(760, 80),
	Font = Enum.Font.LuckiestGuy,
	TextTransparency = 1,
	TextStrokeTransparency = 1,
	Parent = tela,
})
local escalaTitulo = Ui.criar("UIScale", { Parent = titulo })

local function mostrarTitulo(nome: string, corBioma: Color3)
	titulo.Text = Config.maiusculas(Config.semAcento(nome))
	titulo.TextColor3 = corBioma:Lerp(Color3.new(1, 1, 1), 0.45)
	titulo.TextTransparency = 0
	titulo.TextStrokeTransparency = 0
	Ui.pular(escalaTitulo, 0.5)
	task.delay(2.2, function()
		if titulo.Text == Config.maiusculas(Config.semAcento(nome)) then
			local info = TweenInfo.new(0.8)
			TweenService:Create(titulo, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function trocarClima()
	for _, emissor in emissores do
		emissor:Destroy()
	end
	table.clear(emissores)

	local nome = jogador:GetAttribute("Bioma")
	local config = nil
	for _, bioma in Config.BIOMAS do
		if bioma.nome == nome then
			config = bioma
		end
	end
	local clima = config and CLIMAS[config.estilo]
	estiloAtual = if clima then config.estilo else nil
	local info = TweenInfo.new(1.5)
	local nevoa = clima and clima.nevoa or nevoaOriginal
	if atmosfera and nevoa then
		TweenService:Create(atmosfera, TweenInfo.new(2.5), { Color = nevoa.cor, Density = nevoa.densidade, Glare = nevoa.brilho }):Play()
	end
	if not clima then
		TweenService:Create(cor, info, { TintColor = Color3.new(1, 1, 1), Brightness = 0, Saturation = 0 }):Play()
		return
	end
	TweenService:Create(cor, info, { TintColor = clima.tinta, Brightness = clima.brilho, Saturation = clima.saturacao or 0 }):Play()
	for _, props in clima.particulas do
		local emissor = Instance.new("ParticleEmitter")
		emissor.Shape = Enum.ParticleEmitterShape.Box
		emissor.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		for chave, valor in props do
			(emissor :: any)[chave] = valor
		end
		emissor.Rate *= Tremor.qualidade
		emissor.Parent = caixa
		table.insert(emissores, emissor)
	end
	mostrarTitulo(config.nome, config.cor)
	piscar(config.cor)
end

-- Estrela cadente cruzando o céu do Espaço.
local function estrelaCadente()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local olho = camera.Focus.Position
	local de = olho + Vector3.new(math.random(-60, 60), math.random(45, 70), math.random(-80, 80))
	local direcao = Vector3.new(math.random(-10, 10) / 10, -0.45, math.random(-10, 10) / 10).Unit
	local estrela = Instance.new("Part")
	estrela.Name = "EstrelaCadente"
	estrela.Anchored = true
	estrela.CanCollide = false
	estrela.CanQuery = false
	estrela.CanTouch = false
	estrela.CastShadow = false
	estrela.Material = Enum.Material.Neon
	estrela.Color = Color3.fromRGB(230, 240, 255)
	estrela.Size = Vector3.one * 0.6
	estrela.CFrame = CFrame.new(de)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.3, 0)
	a0.Parent = estrela
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.3, 0)
	a1.Parent = estrela
	local rastro = Instance.new("Trail")
	rastro.Attachment0 = a0
	rastro.Attachment1 = a1
	rastro.Lifetime = 0.5
	rastro.FaceCamera = true
	rastro.LightEmission = 1
	rastro.WidthScale = NumberSequence.new(1, 0)
	rastro.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 120, 255))
	rastro.Transparency = NumberSequence.new(0, 1)
	rastro.Parent = estrela
	estrela.Parent = caixa
	TweenService:Create(estrela, TweenInfo.new(1.1, Enum.EasingStyle.Linear), { CFrame = CFrame.new(de + direcao * 90) }):Play()
	task.delay(1.7, estrela.Destroy, estrela)
end

function Ambiente.iniciar()
	jogador:GetAttributeChangedSignal("Bioma"):Connect(trocarClima)
	trocarClima()
	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if camera and #emissores > 0 then
			-- olhando para +X (a direção da estrada), para o vento ir para a frente
			caixa.CFrame = CFrame.lookAt(camera.Focus.Position, camera.Focus.Position + Vector3.xAxis)
		end
	end)
	-- coisas de vez em quando: estrelas cadentes no Espaço, o Vulcão roncando
	task.spawn(function()
		while true do
			task.wait(1 + math.random() * 1.5)
			if estiloAtual == "espaco" then
				estrelaCadente()
			elseif estiloAtual == "vulcao" and math.random() < 0.12 then
				Tremor.sacudir(0.35, 1.4)
			end
		end
	end)
end

return Ambiente

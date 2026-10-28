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
local Ui = require(script.Parent.Ui)

local Ambiente = {}

local jogador = Players.LocalPlayer
local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"
local FOGO = "rbxasset://textures/particles/fire_main.dds"

type Clima = {
	tinta: Color3, -- cor da tela
	brilho: number,
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
		},
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
		},
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
		},
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
		},
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
		},
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
	local info = TweenInfo.new(1.5)
	if not clima then
		TweenService:Create(cor, info, { TintColor = Color3.new(1, 1, 1), Brightness = 0 }):Play()
		return
	end
	TweenService:Create(cor, info, { TintColor = clima.tinta, Brightness = clima.brilho }):Play()
	for _, props in clima.particulas do
		local emissor = Instance.new("ParticleEmitter")
		emissor.Shape = Enum.ParticleEmitterShape.Box
		emissor.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		for chave, valor in props do
			(emissor :: any)[chave] = valor
		end
		emissor.Parent = caixa
		table.insert(emissores, emissor)
	end
	mostrarTitulo(config.nome, config.cor)
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
end

return Ambiente

-- Chefes assustadores, só neste computador: a câmera treme quando um chefe
-- bravo corre perto de você, os passos dele fazem barulho, e quem está
-- sendo perseguido vê as bordas da tela piscando em vermelho e o aviso
-- "CORRA PARA A BASE!". O servidor marca os chefes com a tag "Guardiao" e o
-- atributo "Bravo", e põe o atributo "Perseguido" em quem ele persegue.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sons = require(script.Parent.Sons)
local Ui = require(script.Parent.Ui)

local Chefes = {}

local jogador = Players.LocalPlayer
local ALCANCE_TREMOR = 70 -- longe disso a câmera não treme
local VERMELHO = Color3.fromRGB(255, 30, 30)

-- Tela vermelha de perseguição ----------------------------------------------

local tela = Ui.criar("ScreenGui", {
	Name = "Perseguicao",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = -1,
	Enabled = false,
	Parent = jogador:WaitForChild("PlayerGui"),
})
-- quatro bordas que vão de vermelho a transparente para o meio da tela
local bordas: { Frame } = {}
for _, lado in {
	{ pos = UDim2.fromScale(0, 0), tam = UDim2.fromScale(1, 0.18), giro = 90 },
	{ pos = UDim2.fromScale(0, 0.82), tam = UDim2.fromScale(1, 0.18), giro = -90 },
	{ pos = UDim2.fromScale(0, 0), tam = UDim2.fromScale(0.12, 1), giro = 0 },
	{ pos = UDim2.fromScale(0.88, 0), tam = UDim2.fromScale(0.12, 1), giro = 180 },
} do
	local borda = Ui.criar("Frame", {
		Position = lado.pos,
		Size = lado.tam,
		BackgroundColor3 = VERMELHO,
		BorderSizePixel = 0,
		Parent = tela,
	}, {
		Ui.criar("UIGradient", {
			Rotation = lado.giro,
			Transparency = NumberSequence.new(0, 1),
		}),
	})
	table.insert(bordas, borda)
end
local aviso = Ui.texto({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 80),
	Size = UDim2.new(0.7, 0, 0, 44),
	TextColor3 = Color3.fromRGB(255, 80, 80),
	Text = "",
	Parent = tela,
})
local escalaAviso = Ui.criar("UIScale", { Parent = aviso })

local function atualizarPerseguicao()
	local nome = jogador:GetAttribute("Perseguido")
	tela.Enabled = nome ~= nil
	if nome then
		aviso.Text = `⚠️ {Config.maiusculas(nome)} ESTÁ ATRÁS DE VOCÊ! CORRA PARA A BASE!`
		Ui.pular(escalaAviso, 1.4)
	end
end

-- Tremor e passos -------------------------------------------------------------

type Estado = { ultima: Vector3, proximoPasso: number }
local estados: { [Instance]: Estado } = {}

local function tremer()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local agora = os.clock()
	local olho = camera.Focus.Position
	local forca = 0
	for _, chefe in CollectionService:GetTagged("Guardiao") do
		if chefe:IsA("Model") and chefe:IsDescendantOf(Workspace) then
			local posicao = chefe:GetPivot().Position
			local estado = estados[chefe]
			if not estado then
				estado = { ultima = posicao, proximoPasso = 0 }
				estados[chefe] = estado
			end
			local andando = (posicao - estado.ultima).Magnitude > 0.05
			estado.ultima = posicao
			local distancia = (posicao - olho).Magnitude
			if chefe:GetAttribute("Bravo") and andando and distancia < ALCANCE_TREMOR then
				forca = math.max(forca, 1 - distancia / ALCANCE_TREMOR)
				if agora >= estado.proximoPasso then
					estado.proximoPasso = agora + 0.42
					Sons.tocar("Passo", posicao)
				end
			end
		end
	end
	if forca > 0 then
		local quanto = forca * 0.35
		camera.CFrame *= CFrame.Angles(
			math.rad(math.noise(agora * 12, 1) * quanto * 4),
			math.rad(math.noise(agora * 12, 2) * quanto * 4),
			math.rad(math.noise(agora * 12, 3) * quanto * 2)
		)
	end
	-- a borda vermelha pulsa como um coração acelerado
	if tela.Enabled then
		local batida = (math.sin(agora * 9) + 1) / 2
		for _, borda in bordas do
			borda.BackgroundTransparency = 0.25 + batida * 0.45
		end
	end
end

function Chefes.iniciar()
	jogador:GetAttributeChangedSignal("Perseguido"):Connect(atualizarPerseguicao)
	atualizarPerseguicao()
	CollectionService:GetInstanceRemovedSignal("Guardiao"):Connect(function(chefe)
		estados[chefe] = nil
	end)
	-- depois da câmera se mexer, para o tremor não ser desfeito
	RunService:BindToRenderStep("TremorChefe", Enum.RenderPriority.Camera.Value + 1, tremer)
end

return Chefes

-- Chefes assustadores, só neste computador: a câmera treme quando um chefe
-- bravo corre perto de você, os passos dele fazem barulho, e quem está
-- sendo perseguido vê as bordas da tela piscando em vermelho e o aviso
-- "CORRA PARA A BASE!". O servidor marca os chefes com a tag "Guardiao" e o
-- atributo "Bravo", e põe o atributo "Perseguido" em quem ele persegue.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ChefesAnimacao = require(script.Parent.ChefesAnimacao)
local Sons = require(script.Parent.Sons)
local Tremor = require(script.Parent.Tremor)
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

-- Medidor: quanto falta para o chefe te alcançar e quanto falta até a base.
local medidor = Ui.criar("Frame", {
	Name = "Medidor",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 132),
	Size = UDim2.fromOffset(420, 40),
	BackgroundColor3 = Color3.fromRGB(40, 10, 20),
	BackgroundTransparency = 0.15,
	Parent = tela,
}, { Ui.cantos(20), Ui.borda(Ui.CONTORNO, 3) })
local enchimento = Ui.criar("Frame", {
	Name = "Perigo",
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Ui.BRANCO,
	Parent = medidor,
}, { Ui.cantos(20), Ui.gradiente(Color3.fromRGB(255, 120, 90), Color3.fromRGB(200, 20, 30)) })
local textoChefe = Ui.texto({
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(14, 5),
	Size = UDim2.new(0.6, -14, 1, -10),
	ZIndex = 2,
	Parent = medidor,
})
local textoBase = Ui.texto({
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = Color3.fromRGB(150, 255, 160),
	Position = UDim2.new(0.6, 0, 0, 5),
	Size = UDim2.new(0.4, -14, 1, -10),
	ZIndex = 2,
	Parent = medidor,
})

local function atualizarMedidor(nome: string)
	local personagem = jogador.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not raiz then
		return
	end
	local chefe: Model? = nil
	for _, modelo in CollectionService:GetTagged("Guardiao") do
		if modelo.Name == nome and modelo:IsA("Model") then
			chefe = modelo
		end
	end
	local minha = Vector3.new(raiz.Position.X, 0, raiz.Position.Z)
	if chefe then
		local posicao = chefe:GetPivot().Position
		local alcance = chefe:GetAttribute("Alcance") or 8
		local falta = math.max(0, (Vector3.new(posicao.X, 0, posicao.Z) - minha).Magnitude - alcance)
		textoChefe.Text = `👹 {math.floor(falta)} m`
		-- enche quanto mais perto: cheio = ele está quase te pegando
		local perigo = math.clamp(1 - falta / 60, 0.04, 1)
		enchimento.Size = enchimento.Size:Lerp(UDim2.fromScale(perigo, 1), 0.25)
		textoChefe.TextColor3 = if falta < 12 then Color3.fromRGB(255, 255, 120) else Ui.BRANCO
	end
	local base = jogador:GetAttribute("BaseCentro")
	if typeof(base) == "Vector3" then
		textoBase.Text = `🏠 {math.floor((Vector3.new(base.X, 0, base.Z) - minha).Magnitude)} m`
	end
end

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

-- Nuvem de poeira e um anel no chão a cada passo pesado do chefe.
local function poeira(chefe: Model)
	local caixa, tamanho = chefe:GetBoundingBox()
	local chao = caixa.Position - Vector3.new(0, tamanho.Y / 2 - 0.3, 0)
	local centro = Instance.new("Part")
	centro.Name = "PoeiraPasso"
	centro.Anchored = true
	centro.CanCollide = false
	centro.CanQuery = false
	centro.CanTouch = false
	centro.Transparency = 1
	centro.Size = Vector3.new(tamanho.X * 0.6, 0.2, tamanho.Z * 0.6)
	centro.Position = chao
	centro.Parent = Workspace
	local nuvem = Instance.new("ParticleEmitter")
	nuvem.Texture = "rbxasset://textures/particles/smoke_main.dds"
	nuvem.Color = ColorSequence.new(Color3.fromRGB(200, 185, 160))
	nuvem.Transparency = NumberSequence.new(0.35, 1)
	nuvem.Size = NumberSequence.new(1.5, 4.5)
	nuvem.Lifetime = NumberRange.new(0.6, 1)
	nuvem.Speed = NumberRange.new(5, 9)
	nuvem.SpreadAngle = Vector2.new(180, 8)
	nuvem.Drag = 4
	nuvem.Rotation = NumberRange.new(0, 360)
	nuvem.Rate = 0
	nuvem.Shape = Enum.ParticleEmitterShape.Box
	nuvem.Parent = centro
	nuvem:Emit(if Tremor.celular then 4 else 8)
	Debris:AddItem(centro, 1.2)
end

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
				-- chefe animado: o som e a poeira saem quando o pé bate no chão
				if agora >= estado.proximoPasso and not ChefesAnimacao.animado(chefe) then
					estado.proximoPasso = agora + 0.42
					Sons.tocar("Passo", posicao)
					poeira(chefe)
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
		local nome = jogador:GetAttribute("Perseguido")
		if nome then
			atualizarMedidor(nome)
		end
		local batida = (math.sin(agora * 9) + 1) / 2
		for _, borda in bordas do
			borda.BackgroundTransparency = 0.25 + batida * 0.45
		end
	end
end

function Chefes.iniciar()
	ChefesAnimacao.aoPisar(function(chefe, posicao, forca)
		local camera = Workspace.CurrentCamera
		if not (camera and chefe:GetAttribute("Bravo")) then
			return
		end
		local distancia = (posicao - camera.Focus.Position).Magnitude
		if distancia < ALCANCE_TREMOR * 1.5 then
			Sons.tocar("Passo", posicao)
			poeira(chefe)
			Tremor.perto(posicao, 0.35 * forca, ALCANCE_TREMOR, 0.2)
		end
	end)
	jogador:GetAttributeChangedSignal("Perseguido"):Connect(atualizarPerseguicao)
	atualizarPerseguicao()
	CollectionService:GetInstanceRemovedSignal("Guardiao"):Connect(function(chefe)
		estados[chefe] = nil
	end)
	-- depois da câmera se mexer, para o tremor não ser desfeito
	RunService:BindToRenderStep("TremorChefe", Enum.RenderPriority.Camera.Value + 1, tremer)
end

return Chefes

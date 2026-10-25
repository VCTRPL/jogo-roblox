-- Efeitos visuais que o servidor pede (Remotes.Efeito). Tudo é criado só
-- neste computador e some sozinho, então não pesa o servidor.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Efeitos = {}

local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"
local DISTANCIA_MAXIMA = 260 -- longe disso ninguém vê, então nem cria

local ARCO_IRIS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 90)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(70, 230, 110)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(70, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
})

-- quantas faíscas cada raridade solta
local FAISCAS = { Comum = 25, Raro = 45, Epico = 70, Lendario = 110, Mitico = 160 }

local pasta = Instance.new("Folder")
pasta.Name = "Efeitos"
pasta.Parent = Workspace

local function peca(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for chave, valor in props do
		(p :: any)[chave] = valor
	end
	p.Parent = pasta
	return p
end

local function perto(posicao: Vector3): boolean
	local camera = Workspace.CurrentCamera
	return camera ~= nil and (camera.CFrame.Position - posicao).Magnitude <= DISTANCIA_MAXIMA
end

local function explodir(parent: BasePart, cores: ColorSequence, quantidade: number, props: { [string]: any }?)
	local emissor = Instance.new("ParticleEmitter")
	emissor.Texture = FAISCA
	emissor.Color = cores
	emissor.LightEmission = 1
	emissor.Rate = 0
	emissor.Lifetime = NumberRange.new(0.6, 1.3)
	emissor.Speed = NumberRange.new(14, 30)
	emissor.SpreadAngle = Vector2.new(180, 180)
	emissor.Drag = 4
	emissor.Acceleration = Vector3.new(0, -12, 0)
	emissor.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	emissor.RotSpeed = NumberRange.new(-200, 200)
	if props then
		for chave, valor in props do
			(emissor :: any)[chave] = valor
		end
	end
	emissor.Parent = parent
	emissor:Emit(quantidade)
end

-- Pedaços da casca do ovo voando para os lados (física só neste computador).
local function cascas(posicao: Vector3, cor: Color3)
	for i = 1, 8 do
		local angulo = i / 8 * math.pi * 2
		local direcao = Vector3.new(math.cos(angulo), 0, math.sin(angulo))
		local caco = peca({
			Name = "Casca",
			Anchored = false,
			CanCollide = true,
			Material = Enum.Material.SmoothPlastic,
			Color = cor,
			Size = Vector3.new(0.9, 0.9, 0.3),
			CFrame = CFrame.new(posicao + direcao + Vector3.new(0, 1, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0),
		})
		caco.AssemblyLinearVelocity = direcao * math.random(10, 18) + Vector3.new(0, math.random(18, 28), 0)
		caco.AssemblyAngularVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))
		Debris:AddItem(caco, 1.6)
		task.delay(1.1, function()
			if caco.Parent then
				TweenService:Create(caco, TweenInfo.new(0.5), { Transparency = 1 }):Play()
			end
		end)
	end
end

-- Anel de luz que cresce no chão e some.
local function onda(posicao: Vector3, cor: Color3, tamanho: number)
	local anel = peca({
		Name = "Onda",
		Shape = Enum.PartType.Cylinder,
		Color = cor,
		Transparency = 0.15,
		Size = Vector3.new(0.3, 2, 2),
		CFrame = CFrame.new(posicao + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(anel, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.3, tamanho, tamanho),
		Transparency = 1,
	}):Play()
	Debris:AddItem(anel, 0.8)
end

-- Coluna de luz subindo até o céu (Lendários e Míticos).
local function coluna(posicao: Vector3, cor: Color3)
	local raio = peca({
		Name = "Coluna",
		Shape = Enum.PartType.Cylinder,
		Color = cor,
		Transparency = 0.2,
		Size = Vector3.new(80, 4, 4),
		CFrame = CFrame.new(posicao + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(raio, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = Vector3.new(80, 0.2, 0.2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(raio, 1.9)
end

-- Texto que sobe em cima do lugar do efeito, como "NASCEU!".
local function letreiro(parent: BasePart, linhas: { { string } | any })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 40 * #linhas)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 140
	gui.Parent = parent
	local lista = Instance.new("UIListLayout")
	lista.SortOrder = Enum.SortOrder.LayoutOrder
	lista.Parent = gui
	local escala = Instance.new("UIScale")
	escala.Scale = 0.3
	escala.Parent = gui
	for ordem, linha in linhas do
		local label = Instance.new("TextLabel")
		label.LayoutOrder = ordem
		label.Size = UDim2.new(1, 0, 0, 40)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = linha[1]
		label.TextColor3 = linha[2]
		label.TextStrokeColor3 = Color3.fromRGB(25, 20, 45)
		label.TextStrokeTransparency = 0
		label.Parent = gui
		task.delay(1.4, function()
			TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end)
	end
	TweenService:Create(escala, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(gui, TweenInfo.new(1.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = Vector3.new(0, 10, 0),
	}):Play()
end

local function chocou(dados)
	local posicao: Vector3 = dados.posicao
	if not perto(posicao) then
		return
	end
	local corRaridade = Config.CORES_RARIDADE[dados.raridade] or Color3.new(1, 1, 1)
	local mutacao = Config.mutacao(dados.mutacao)
	local arcoIris = dados.mutacao == "Arco-iris"
	local cores = if arcoIris then ARCO_IRIS else ColorSequence.new(corRaridade, mutacao.cor or Color3.new(1, 1, 1))

	local centro = peca({
		Name = "Chocou",
		Transparency = 1,
		Size = Vector3.one,
		Position = posicao + Vector3.new(0, 2, 0),
	})
	Debris:AddItem(centro, 3)

	explodir(centro, cores, FAISCAS[dados.raridade] or 25)
	-- nuvem de fumaça colorida da casca quebrando
	explodir(centro, ColorSequence.new(corRaridade:Lerp(Color3.new(1, 1, 1), 0.5)), 12, {
		Texture = FUMACA,
		LightEmission = 0.3,
		Speed = NumberRange.new(4, 9),
		Drag = 3,
		Acceleration = Vector3.new(0, 3, 0),
		Lifetime = NumberRange.new(0.8, 1.4),
		Transparency = NumberSequence.new(0.3, 1),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(1, 5),
		}),
	})
	cascas(posicao, corRaridade)
	onda(posicao, mutacao.cor or corRaridade, 16)

	local luz = Instance.new("PointLight")
	luz.Color = corRaridade
	luz.Range = 24
	luz.Brightness = 6
	luz.Parent = centro
	TweenService:Create(luz, TweenInfo.new(1), { Brightness = 0 }):Play()

	if dados.raridade == "Lendario" or dados.raridade == "Mitico" or mutacao.cor then
		coluna(posicao, mutacao.cor or corRaridade)
		task.delay(0.25, onda, posicao, corRaridade, 28)
	end

	local linhas = { { "NASCEU!", corRaridade } }
	if mutacao.cor then
		table.insert(linhas, { string.upper(mutacao.nome) .. "!", mutacao.cor })
	end
	if dados.ganho and dados.ganho > 0 then
		table.insert(linhas, { `+${Config.formatar(dados.ganho)}`, Color3.fromRGB(120, 255, 120) })
	end
	letreiro(centro, linhas)
end

local efeitos: { [string]: (any) -> () } = {
	Chocou = chocou,
}

function Efeitos.iniciar()
	local evento = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Efeito") :: RemoteEvent
	evento.OnClientEvent:Connect(function(nome: string, dados)
		local efeito = efeitos[nome]
		if efeito then
			efeito(dados)
		end
	end)
end

return Efeitos

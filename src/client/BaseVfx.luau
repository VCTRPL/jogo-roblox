-- Efeitos das bases e dos chefes, só neste computador:
--  * Brainrot chegando na base: raio de luz caindo do céu, poeira e anel;
--  * Brainrots Épicos ou mais raros (e os com mutação) brilham sempre;
--  * tranca: as paredes acendem num clarão, uma faixa de luz sobe e desce
--    por elas e soltam faíscas enquanto a base está trancada; ao destrancar
--    elas se desfazem em brilhos;
--  * chefe bravo: fumaça vermelha e uma luz vermelha em volta dele.
-- O servidor marca os Brainrots com a tag "Brainrot", as paredes com
-- "TrancaBase" e os chefes com "Guardiao" (atributo "Bravo").
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Tremor = require(script.Parent.Tremor)

local BaseVfx = {}

local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"
local BRANCO = Color3.new(1, 1, 1)
local AZUL_TRANCA = Color3.fromRGB(90, 190, 255)

local pasta = Instance.new("Folder")
pasta.Name = "BaseVfx"
pasta.Parent = Workspace

local function peca(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for chave, valor in props do
		(p :: any)[chave] = valor
	end
	p.Parent = pasta
	return p
end

local function emissor(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for chave, valor in props do
		(e :: any)[chave] = valor
	end
	e.Rate *= Tremor.qualidade
	e.Parent = parent
	return e
end

local function perto(posicao: Vector3, alcance: number): boolean
	local camera = Workspace.CurrentCamera
	return camera ~= nil and (camera.CFrame.Position - posicao).Magnitude <= alcance
end

-- Brainrots --------------------------------------------------------------------

local inicio = os.clock()
local chegadasRecentes = 0 -- muitas de uma vez (base carregando) não fazem efeito

local function chegada(modelo: Model)
	local cor = Config.CORES_RARIDADE[modelo:GetAttribute("Raridade") or "Comum"] or BRANCO
	local chao = modelo:GetPivot().Position
	local _, tamanho = modelo:GetBoundingBox()
	chao -= Vector3.new(0, tamanho.Y / 2, 0)
	if not perto(chao, 200) then
		return
	end
	-- raio caindo do céu: começa alto e fino, bate no chão e se abre
	local raio = peca({
		Name = "RaioChegada",
		Shape = Enum.PartType.Cylinder,
		Color = cor:Lerp(BRANCO, 0.35),
		Transparency = 0.15,
		Size = Vector3.new(60, 0.4, 0.4),
		CFrame = CFrame.new(chao + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(raio, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = Vector3.new(60, 3.2, 3.2),
	}):Play()
	task.delay(0.25, function()
		TweenService:Create(raio, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(60, 0.1, 0.1),
			Transparency = 1,
		}):Play()
	end)
	Debris:AddItem(raio, 0.8)

	local anel = peca({
		Name = "AnelChegada",
		Shape = Enum.PartType.Cylinder,
		Color = cor,
		Transparency = 0.1,
		Size = Vector3.new(0.25, 2, 2),
		CFrame = CFrame.new(chao + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(anel, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.25, 14, 14),
		Transparency = 1,
	}):Play()
	Debris:AddItem(anel, 0.7)

	local centro = peca({ Name = "PoeiraChegada", Transparency = 1, Size = Vector3.one, Position = chao + Vector3.new(0, 0.5, 0) })
	Debris:AddItem(centro, 2)
	local poeira = emissor(centro, {
		Texture = FUMACA,
		Color = ColorSequence.new(Color3.fromRGB(230, 225, 215)),
		Transparency = NumberSequence.new(0.3, 1),
		Size = NumberSequence.new(1.5, 4),
		Lifetime = NumberRange.new(0.6, 1),
		Speed = NumberRange.new(8, 12),
		SpreadAngle = Vector2.new(180, 5),
		EmissionDirection = Enum.NormalId.Top,
		Drag = 5,
		Rate = 0,
	})
	poeira:Emit(math.floor(14 * Tremor.qualidade))
	local brilho = emissor(centro, {
		Texture = FAISCA,
		Color = ColorSequence.new(cor, BRANCO),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.6, 1.1),
		Speed = NumberRange.new(10, 18),
		SpreadAngle = Vector2.new(40, 40),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -25, 0),
		LightEmission = 1,
		Rate = 0,
	})
	brilho:Emit(math.floor(24 * Tremor.qualidade))
end

-- brilho constante dos raros, preso no próprio modelo (some junto com ele)
local function aura(modelo: Model)
	local nivel = Config.nivelRaridade(modelo:GetAttribute("Raridade") or "Comum")
	local mutacao = Config.mutacao(modelo:GetAttribute("Mutacao") or "Normal")
	if nivel < Config.nivelRaridade("Epico") and not mutacao.cor then
		return
	end
	local parte = modelo.PrimaryPart or modelo:FindFirstChildWhichIsA("BasePart", true)
	if not parte then
		return
	end
	local cor = Config.CORES_RARIDADE[modelo:GetAttribute("Raridade")] or BRANCO
	local _, tamanho = modelo:GetBoundingBox()
	local anexo = Instance.new("Attachment")
	anexo.Name = "VfxAura"
	anexo.Parent = parte
	emissor(anexo, {
		Name = "VfxAuraBrilho",
		Texture = FAISCA,
		Color = ColorSequence.new(cor, mutacao.cor or BRANCO),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.35 + nivel * 0.05), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(1, 1.6),
		Speed = NumberRange.new(1, 2.5),
		SpreadAngle = Vector2.new(180, 30),
		EmissionDirection = Enum.NormalId.Top,
		LightEmission = 1,
		Rate = (nivel - 2) * 3 + (if mutacao.cor then 4 else 0),
	})
	if nivel >= Config.nivelRaridade("Lendario") then
		local luz = Instance.new("PointLight")
		luz.Name = "VfxAuraLuz"
		luz.Color = cor
		luz.Range = math.max(tamanho.X, tamanho.Y) + 6
		luz.Brightness = 0.8 + (nivel - 4) * 0.4
		luz.Parent = anexo
	end
end

local function novoBrainrot(modelo: Instance)
	if not modelo:IsA("Model") then
		return
	end
	task.defer(function()
		local mapa = Workspace:FindFirstChild("Mapa")
		-- só os da base (os carregados na cabeça ficam dentro do personagem)
		if not modelo.Parent or not mapa or not modelo:IsDescendantOf(mapa) then
			return
		end
		aura(modelo)
		if os.clock() - inicio > 5 and chegadasRecentes < 3 then
			chegadasRecentes += 1
			task.delay(0.6, function()
				chegadasRecentes -= 1
			end)
			chegada(modelo)
		end
	end)
end

-- Tranca -------------------------------------------------------------------------

type Parede = { faixa: BasePart?, brilho: ParticleEmitter?, trancada: boolean }
local paredes: { [BasePart]: Parede } = {}

local function trancou(parede: BasePart, estado: Parede)
	-- clarão: uma cópia acesa da parede some aos poucos (a parede em si é do
	-- servidor; mexer nela aqui brigaria com o que ele manda)
	local clarao = peca({
		Name = "ClaraoTranca",
		Color = AZUL_TRANCA:Lerp(BRANCO, 0.5),
		Transparency = 0.1,
		Size = parede.Size + Vector3.new(0.2, 0, 0.2),
		CFrame = parede.CFrame,
	})
	TweenService:Create(clarao, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
	Debris:AddItem(clarao, 0.65)
	estado.faixa = peca({
		Name = "FaixaTranca",
		Color = AZUL_TRANCA:Lerp(BRANCO, 0.4),
		Transparency = 0.2,
		Size = Vector3.new(parede.Size.X + 0.3, 0.4, parede.Size.Z + 0.3),
		CFrame = parede.CFrame,
	})
	estado.brilho = emissor(parede, {
		Name = "VfxTranca",
		Texture = FAISCA,
		Color = ColorSequence.new(AZUL_TRANCA, BRANCO),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(0.5, 1.5),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		LightEmission = 1,
		Rate = 10,
	})
	if perto(parede.Position, 80) then
		Tremor.perto(parede.Position, 0.25, 40)
	end
end

local function destrancou(parede: BasePart, estado: Parede)
	if estado.faixa then
		estado.faixa:Destroy()
		estado.faixa = nil
	end
	local brilho = estado.brilho
	if brilho then
		estado.brilho = nil
		brilho.Enabled = false
		brilho.Speed = NumberRange.new(4, 9)
		brilho:Emit(math.floor(30 * Tremor.qualidade))
		Debris:AddItem(brilho, 1.5)
	end
end

local function acompanharParede(parede: Instance)
	if not parede:IsA("BasePart") or paredes[parede] then
		return
	end
	local estado: Parede = { faixa = nil, brilho = nil, trancada = parede.Transparency < 1 }
	paredes[parede] = estado
	parede:GetPropertyChangedSignal("Transparency"):Connect(function()
		local agora = parede.Transparency < 1
		if agora == estado.trancada then
			return
		end
		estado.trancada = agora
		if agora then
			trancou(parede, estado)
		else
			destrancou(parede, estado)
		end
	end)
	if estado.trancada then
		trancou(parede, estado)
	end
end

local function esquecerParede(parede: Instance)
	local estado = paredes[parede :: BasePart]
	if estado then
		paredes[parede :: BasePart] = nil
		destrancou(parede :: BasePart, estado)
	end
end

-- Chefes ---------------------------------------------------------------------------

type Chefe = { emissores: { ParticleEmitter }, luz: PointLight }
local chefes: { [Model]: Chefe } = {}

local function ajustarChefe(modelo: Model)
	local bravo = modelo:GetAttribute("Bravo") == true
	local estado = chefes[modelo]
	if not estado and bravo then
		local parte = modelo.PrimaryPart or modelo:FindFirstChildWhichIsA("BasePart", true)
		if not parte then
			return
		end
		local anexo = Instance.new("Attachment")
		anexo.Name = "VfxBravo"
		anexo.Parent = parte
		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(255, 40, 30)
		luz.Range = 18
		luz.Brightness = 2.5
		luz.Parent = anexo
		local fumaca = emissor(anexo, {
			Texture = FUMACA,
			Color = ColorSequence.new(Color3.fromRGB(255, 50, 30), Color3.fromRGB(60, 10, 10)),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.55), NumberSequenceKeypoint.new(1, 1) }),
			Size = NumberSequence.new(2, 5),
			Lifetime = NumberRange.new(0.8, 1.3),
			Speed = NumberRange.new(2, 4),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 4, 0),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-40, 40),
			LightEmission = 0.4,
			Rate = 14,
		})
		local brasas = emissor(anexo, {
			Texture = FAISCA,
			Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 40, 20)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(6, 10),
			SpreadAngle = Vector2.new(180, 180),
			LightEmission = 1,
			Rate = 18,
		})
		estado = { emissores = { fumaca, brasas }, luz = luz }
		chefes[modelo] = estado
		anexo.Destroying:Once(function()
			chefes[modelo] = nil
		end)
	end
	if estado then
		for _, e in estado.emissores do
			e.Enabled = bravo
		end
		estado.luz.Enabled = bravo
	end
end

local function acompanharChefe(modelo: Instance)
	if not modelo:IsA("Model") then
		return
	end
	modelo:GetAttributeChangedSignal("Bravo"):Connect(function()
		ajustarChefe(modelo)
	end)
	ajustarChefe(modelo)
end

function BaseVfx.iniciar()
	CollectionService:GetInstanceAddedSignal("Brainrot"):Connect(novoBrainrot)
	for _, modelo in CollectionService:GetTagged("Brainrot") do
		novoBrainrot(modelo)
	end

	CollectionService:GetInstanceAddedSignal("TrancaBase"):Connect(acompanharParede)
	CollectionService:GetInstanceRemovedSignal("TrancaBase"):Connect(esquecerParede)
	for _, parede in CollectionService:GetTagged("TrancaBase") do
		acompanharParede(parede)
	end

	CollectionService:GetInstanceAddedSignal("Guardiao"):Connect(acompanharChefe)
	CollectionService:GetInstanceRemovedSignal("Guardiao"):Connect(function(modelo)
		chefes[modelo :: Model] = nil
	end)
	for _, modelo in CollectionService:GetTagged("Guardiao") do
		acompanharChefe(modelo)
	end

	-- faixa de luz subindo e descendo pelas paredes trancadas
	RunService.RenderStepped:Connect(function()
		local agora = os.clock()
		for parede, estado in paredes do
			local faixa = estado.faixa
			if faixa then
				local t = (math.sin(agora * 1.6) + 1) / 2
				local altura = parede.Size.Y
				faixa.CFrame = parede.CFrame * CFrame.new(0, -altura / 2 + 0.3 + t * (altura - 0.6), 0)
				faixa.Transparency = 0.15 + (1 - math.abs(t - 0.5) * 2) * 0.3
			end
		end
	end)
end

return BaseVfx

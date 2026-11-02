-- Efeitos presos ao chão de cada bioma, só neste computador (o Ambiente cuida
-- do que segue a câmera):
--  * Selva: raios de sol entre as árvores, vaga-lumes e pétalas subindo das flores;
--  * Praia: ondinhas abrindo na água, bolhas e espuma atrás das barbatanas;
--  * Deserto: redemoinhos de areia passeando e brilho no oásis;
--  * Vulcão: fumaça saindo da cratera, erupções de vez em quando (com pedras
--    de fogo voando e o chão tremendo) e brasas estalando no chão;
--  * Espaço: aurora no céu, cristais piscando e meteoros caindo nas crateras.
-- Só o bioma perto da câmera fica ligado. As peças são achadas pelo nome.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Tremor = require(script.Parent.Tremor)

local BiomasVfx = {}

local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"
local FOGO = "rbxasset://textures/particles/fire_main.dds"
local BRASA = "rbxasset://textures/particles/fire_sparks_main.dds"
local BRANCO = Color3.new(1, 1, 1)
local ALCANCE = 150 -- distância (no chão) do centro do bioma para ligar

type Bioma = {
	pasta: Instance,
	centro: Vector3,
	estilo: string,
	montado: boolean,
	ativo: boolean,
	criados: { Instance },
	emissores: { ParticleEmitter },
	proximo: number, -- próximo evento (ondinha, erupção, meteoro...)
	quadro: ((Bioma, number, number) -> ())?, -- roda todo quadro enquanto ativo
	eventos: ((Bioma) -> ())?, -- roda quando chega a hora de "proximo"
	dados: { [string]: any },
}

local biomas: { Bioma } = {}
local pasta = Instance.new("Folder")
pasta.Name = "BiomasVfx"
pasta.Parent = Workspace

local function peca(b: Bioma?, props: { [string]: any }): Part
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
	if b then
		table.insert(b.criados, p)
	end
	return p
end

local function emissor(b: Bioma?, parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for chave, valor in props do
		(e :: any)[chave] = valor
	end
	e.Rate *= Tremor.qualidade
	e.Parent = parent
	if b then
		table.insert(b.criados, e)
		table.insert(b.emissores, e)
	end
	return e
end

-- caixa invisível onde as partículas nascem
local function area(b: Bioma, posicao: Vector3, tamanho: Vector3): Part
	return peca(b, { Name = "Area", Transparency = 1, Size = tamanho, Position = posicao })
end

local function todos(b: Bioma, nome: string): { BasePart }
	local lista = {}
	for _, x in b.pasta:GetDescendants() do
		if x.Name == nome and x:IsA("BasePart") then
			table.insert(lista, x)
		end
	end
	return lista
end

-- Efeito rápido em um ponto (some sozinho).
local function estouro(posicao: Vector3, props: { [string]: any }, quantos: number, duracao: number)
	local centro = peca(nil, { Name = "Estouro", Transparency = 1, Size = Vector3.one, Position = posicao })
	local e = emissor(nil, centro, props)
	e.Rate = 0
	e:Emit(math.max(1, math.floor(quantos * Tremor.qualidade)))
	Debris:AddItem(centro, duracao)
	return centro
end

local function anelNoChao(posicao: Vector3, cor: Color3, tamanho: number, tempo: number, transparencia: number?)
	local anel = peca(nil, {
		Name = "Anel",
		Shape = Enum.PartType.Cylinder,
		Color = cor,
		Transparency = transparencia or 0.3,
		Size = Vector3.new(0.1, 1, 1),
		CFrame = CFrame.new(posicao) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(anel, TweenInfo.new(tempo, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.1, tamanho, tamanho),
		Transparency = 1,
	}):Play()
	Debris:AddItem(anel, tempo + 0.05)
end

-- Selva ---------------------------------------------------------------------------

local function montarSelva(b: Bioma)
	local c = b.centro
	-- vaga-lumes espalhados pela selva inteira, perto do chão
	emissor(b, area(b, c + Vector3.new(0, 4, 0), Vector3.new(150, 6, 150)), {
		Texture = FAISCA,
		Color = ColorSequence.new(Color3.fromRGB(230, 255, 120), Color3.fromRGB(150, 255, 90)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.45), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(3, 5),
		Speed = NumberRange.new(0.3, 1),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 0.3, 0),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		LightEmission = 1,
		Rate = 45,
	})
	-- raios de sol inclinados atravessando as copas
	local raios = {}
	local aleatorio = Random.new(7)
	for i = 1, 7 do
		local x = aleatorio:NextNumber(-60, 60)
		local z = aleatorio:NextNumber(-60, 60)
		local largura = aleatorio:NextNumber(3, 6)
		local raio = peca(b, {
			Name = "RaioDeSol",
			Material = Enum.Material.ForceField,
			Color = Color3.fromRGB(255, 245, 190),
			Transparency = 0.7,
			Size = Vector3.new(largura, 40, largura * 0.4),
			CFrame = CFrame.new(c + Vector3.new(x, 18, z)) * CFrame.Angles(math.rad(18), math.rad(30), math.rad(-14)),
		})
		table.insert(raios, { parte = raio, fase = i * 1.3 })
	end
	b.dados.raios = raios
	-- pétalas e pólen subindo de algumas flores
	local flores = todos(b, "Flor")
	for i = 1, math.min(#flores, 10) do
		local flor = flores[(i * 7) % #flores + 1]
		emissor(b, flor, {
			Texture = FAISCA,
			Color = ColorSequence.new(flor.Color:Lerp(BRANCO, 0.4), BRANCO),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) }),
			Lifetime = NumberRange.new(2, 3),
			Speed = NumberRange.new(0.8, 1.6),
			SpreadAngle = Vector2.new(30, 30),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0.6, 0.2, 0),
			LightEmission = 0.6,
			Rate = 2,
		})
	end
	b.quadro = function(_, agora)
		for _, item in b.dados.raios do
			item.parte.Transparency = 0.72 + (math.sin(agora * 0.5 + item.fase) + 1) / 2 * 0.22
		end
	end
end

-- Praia -----------------------------------------------------------------------------

local function montarPraia(b: Bioma)
	local agua = b.pasta:FindFirstChild("Agua", true)
	if agua and agua:IsA("BasePart") then
		b.dados.agua = agua
		emissor(b, agua, {
			Name = "Bolhas",
			Texture = FAISCA,
			Color = ColorSequence.new(Color3.fromRGB(210, 245, 255)),
			Transparency = NumberSequence.new(0.2, 1),
			Size = NumberSequence.new(0.25, 0.5),
			Lifetime = NumberRange.new(0.8, 1.4),
			Speed = NumberRange.new(1, 2.5),
			EmissionDirection = Enum.NormalId.Top,
			Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			Rate = 10,
		})
	end
	-- espuma na barbatana (ela anda: a espuma vai junto)
	for _, barbatana in todos(b, "Barbatana") do
		local anexo = Instance.new("Attachment")
		anexo.Position = Vector3.new(0, -barbatana.Size.Y / 2, 0)
		anexo.Parent = barbatana
		table.insert(b.criados, anexo)
		emissor(b, anexo, {
			Texture = FUMACA,
			Color = ColorSequence.new(BRANCO),
			Transparency = NumberSequence.new(0.3, 1),
			Size = NumberSequence.new(0.6, 1.8),
			Lifetime = NumberRange.new(0.8, 1.2),
			Speed = NumberRange.new(0.5, 1),
			SpreadAngle = Vector2.new(90, 10),
			Rate = 12,
		})
	end
	b.eventos = function()
		-- ondinha abrindo em um ponto qualquer da água
		local agua2 = b.dados.agua
		if agua2 then
			local meio = agua2.Size / 2 - Vector3.new(4, 0, 4)
			local ponto = agua2.Position + Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1) * Vector3.new(meio.X, 0, meio.Z)
			anelNoChao(ponto + Vector3.new(0, agua2.Size.Y / 2 + 0.05, 0), Color3.fromRGB(230, 250, 255), 6 + math.random() * 5, 1.4, 0.35)
		end
		b.proximo = os.clock() + 0.35 + math.random() * 0.5
	end
end

-- Deserto ---------------------------------------------------------------------------

local function montarDeserto(b: Bioma)
	local redemoinhos = {}
	for i = 1, 2 do
		local base = peca(b, { Name = "Redemoinho", Transparency = 1, Size = Vector3.new(3, 1, 3), Position = b.centro })
		-- areia girando e subindo em cone
		emissor(b, base, {
			Texture = FUMACA,
			Color = ColorSequence.new(Color3.fromRGB(235, 205, 150), Color3.fromRGB(210, 175, 120)),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.45), NumberSequenceKeypoint.new(1, 1) }),
			Size = NumberSequence.new(1.2, 5),
			Lifetime = NumberRange.new(1.4, 1.9),
			Speed = NumberRange.new(5, 8),
			SpreadAngle = Vector2.new(12, 12),
			EmissionDirection = Enum.NormalId.Top,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(260, 360),
			Shape = Enum.ParticleEmitterShape.Box,
			Rate = 22,
		})
		emissor(b, base, {
			Texture = FAISCA,
			Color = ColorSequence.new(Color3.fromRGB(255, 230, 170)),
			Size = NumberSequence.new(0.15),
			Lifetime = NumberRange.new(0.8, 1.2),
			Speed = NumberRange.new(6, 10),
			SpreadAngle = Vector2.new(25, 25),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -6, 0),
			Rate = 20,
		})
		table.insert(redemoinhos, { parte = base, fase = i * math.pi })
	end
	b.dados.redemoinhos = redemoinhos
	local oasis = b.pasta:FindFirstChild("Oasis", true)
	if oasis and oasis:IsA("BasePart") then
		emissor(b, oasis, {
			Texture = FAISCA,
			Color = ColorSequence.new(BRANCO, Color3.fromRGB(150, 230, 255)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0) }),
			Lifetime = NumberRange.new(0.6, 1),
			Speed = NumberRange.new(0),
			EmissionDirection = Enum.NormalId.Top,
			Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			LightEmission = 1,
			Rate = 8,
		})
	end
	b.quadro = function(_, agora)
		-- passeiam em oito pela areia, longe da clareira do meio
		for _, r in b.dados.redemoinhos do
			local t = agora * 0.12 + r.fase
			local x = math.sin(t) * 55
			local z = math.sin(t * 2) * 40
			r.parte.Position = b.centro + Vector3.new(x, 1, z)
		end
	end
end

-- Vulcão ----------------------------------------------------------------------------

local function erupcao(b: Bioma, boca: Vector3)
	-- fase 1: o chão ronca e a cratera acende
	local luz = b.dados.luzCratera :: PointLight?
	if luz then
		TweenService:Create(luz, TweenInfo.new(0.6), { Brightness = 8 }):Play()
		task.delay(1.4, function()
			TweenService:Create(luz, TweenInfo.new(1.5), { Brightness = 2 }):Play()
		end)
	end
	Tremor.perto(boca, 0.3, 140, 0.7)
	task.delay(0.6, function()
		if not b.ativo then
			return
		end
		-- fase 2: explosão de fogo e fumaça escura
		estouro(boca + Vector3.new(0, 2, 0), {
			Texture = FOGO,
			Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 60, 10)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 1) }),
			Transparency = NumberSequence.new(0.1, 1),
			Lifetime = NumberRange.new(0.8, 1.3),
			Speed = NumberRange.new(20, 34),
			SpreadAngle = Vector2.new(25, 25),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -20, 0),
			LightEmission = 1,
		}, 40, 2)
		estouro(boca + Vector3.new(0, 3, 0), {
			Texture = FUMACA,
			Color = ColorSequence.new(Color3.fromRGB(70, 55, 50)),
			Transparency = NumberSequence.new(0.2, 1),
			Size = NumberSequence.new(5, 14),
			Lifetime = NumberRange.new(2.5, 3.5),
			Speed = NumberRange.new(10, 16),
			SpreadAngle = Vector2.new(20, 20),
			EmissionDirection = Enum.NormalId.Top,
			Drag = 1,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-30, 30),
		}, 16, 4)
		Tremor.perto(boca, 0.7, 140, 0.9)
		-- pedras de lava voando em arco e caindo em volta
		for _ = 1, if Tremor.celular then 4 else 7 do
			local angulo = math.random() * math.pi * 2
			local longe = 15 + math.random() * 30
			local destino = Vector3.new(boca.X + math.cos(angulo) * longe, 1.5, boca.Z + math.sin(angulo) * longe)
			local pedra = peca(nil, {
				Name = "PedraDeLava",
				Color = Color3.fromRGB(255, 110, 30),
				Size = Vector3.one * (0.8 + math.random() * 0.8),
				CFrame = CFrame.new(boca),
			})
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(0, 0.4, 0)
			a0.Parent = pedra
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(0, -0.4, 0)
			a1.Parent = pedra
			local rastro = Instance.new("Trail")
			rastro.Attachment0 = a0
			rastro.Attachment1 = a1
			rastro.Color = ColorSequence.new(Color3.fromRGB(255, 200, 80), Color3.fromRGB(80, 40, 30))
			rastro.Transparency = NumberSequence.new(0, 1)
			rastro.Lifetime = 0.4
			rastro.FaceCamera = true
			rastro.LightEmission = 0.8
			rastro.Parent = pedra
			local duracao = 1.1 + math.random() * 0.5
			local altura = 18 + math.random() * 14
			local inicio = os.clock()
			local conexao
			conexao = RunService.RenderStepped:Connect(function()
				local t = math.min((os.clock() - inicio) / duracao, 1)
				local ponto = boca:Lerp(destino, t) + Vector3.new(0, math.sin(t * math.pi) * altura, 0)
				pedra.CFrame = CFrame.new(ponto) * CFrame.Angles(t * 9, t * 7, 0)
				if t >= 1 then
					conexao:Disconnect()
					estouro(destino, {
						Texture = BRASA,
						Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 70, 20)),
						Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
						Lifetime = NumberRange.new(0.4, 0.8),
						Speed = NumberRange.new(8, 14),
						SpreadAngle = Vector2.new(60, 60),
						EmissionDirection = Enum.NormalId.Top,
						Acceleration = Vector3.new(0, -30, 0),
						LightEmission = 1,
					}, 14, 1)
					anelNoChao(destino - Vector3.new(0, 1, 0), Color3.fromRGB(255, 120, 40), 6, 0.5)
					pedra:Destroy()
				end
			end)
			-- garantia: se algo der errado no caminho, a pedra some mesmo assim
			Debris:AddItem(pedra, duracao + 1)
		end
	end)
end

local function montarVulcao(b: Bioma)
	local cratera = b.pasta:FindFirstChild("Cratera", true)
	if cratera and cratera:IsA("BasePart") then
		local boca = cratera.Position
		b.dados.boca = boca
		local topo = peca(b, { Name = "BocaVulcao", Transparency = 1, Size = Vector3.new(5, 1, 5), Position = boca + Vector3.new(0, 1, 0) })
		emissor(b, topo, {
			Texture = FUMACA,
			Color = ColorSequence.new(Color3.fromRGB(110, 90, 85), Color3.fromRGB(60, 55, 55)),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) }),
			Size = NumberSequence.new(4, 16),
			Lifetime = NumberRange.new(5, 7),
			Speed = NumberRange.new(4, 6),
			SpreadAngle = Vector2.new(10, 10),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(1.5, 0.5, 0),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-15, 15),
			Shape = Enum.ParticleEmitterShape.Box,
			Rate = 4,
		})
		emissor(b, topo, {
			Texture = BRASA,
			Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 60, 10)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
			Lifetime = NumberRange.new(1, 1.8),
			Speed = NumberRange.new(6, 12),
			SpreadAngle = Vector2.new(30, 30),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -8, 0),
			Shape = Enum.ParticleEmitterShape.Box,
			LightEmission = 1,
			Rate = 16,
		})
		local luz = Instance.new("PointLight")
		luz.Color = Color3.fromRGB(255, 110, 40)
		luz.Range = 40
		luz.Brightness = 2
		luz.Parent = topo
		b.dados.luzCratera = luz
	end
	-- brasas do chão estalando (uma a cada três, para não pesar)
	for i, brasa in todos(b, "Brasa") do
		if i % 3 == 0 then
			emissor(b, brasa, {
				Texture = BRASA,
				Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 70, 20)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(0.5, 1),
				Speed = NumberRange.new(3, 6),
				SpreadAngle = Vector2.new(35, 35),
				EmissionDirection = Enum.NormalId.Top,
				Acceleration = Vector3.new(0, -10, 0),
				LightEmission = 1,
				Rate = 3,
			})
		end
	end
	b.proximo = os.clock() + 4
	b.eventos = function()
		if b.dados.boca then
			erupcao(b, b.dados.boca)
		end
		b.proximo = os.clock() + 9 + math.random() * 7
	end
end

-- Espaço ----------------------------------------------------------------------------

local function meteoro(b: Bioma)
	local crateras = b.dados.crateras
	if #crateras == 0 then
		return
	end
	local alvo = crateras[math.random(1, #crateras)].Position + Vector3.new(0, 0.5, 0)
	local de = alvo + Vector3.new(-40 + math.random() * 20, 70, -30 + math.random() * 60)
	local pedra = peca(nil, { Name = "Meteoro", Color = Color3.fromRGB(200, 170, 255), Size = Vector3.one * 1.4, CFrame = CFrame.new(de) })
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.7, 0)
	a0.Parent = pedra
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.7, 0)
	a1.Parent = pedra
	local rastro = Instance.new("Trail")
	rastro.Attachment0 = a0
	rastro.Attachment1 = a1
	rastro.Color = ColorSequence.new(BRANCO, Color3.fromRGB(150, 90, 255))
	rastro.Transparency = NumberSequence.new(0, 1)
	rastro.WidthScale = NumberSequence.new(1.5, 0)
	rastro.Lifetime = 0.5
	rastro.FaceCamera = true
	rastro.LightEmission = 1
	rastro.Parent = pedra
	TweenService:Create(pedra, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(alvo) }):Play()
	task.delay(0.9, function()
		pedra:Destroy()
		estouro(alvo, {
			Texture = FAISCA,
			Color = ColorSequence.new(BRANCO, Color3.fromRGB(170, 110, 255)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(10, 20),
			SpreadAngle = Vector2.new(70, 70),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -12, 0),
			LightEmission = 1,
		}, 30, 1.5)
		anelNoChao(alvo, Color3.fromRGB(180, 130, 255), 16, 0.6, 0.15)
		Tremor.perto(alvo, 0.3, 50, 0.3)
	end)
end

local function montarEspaco(b: Bioma)
	-- aurora: fitas de luz ondulando lá no alto
	local auroras = {}
	local cores = {
		ColorSequence.new(Color3.fromRGB(80, 255, 200), Color3.fromRGB(140, 90, 255)),
		ColorSequence.new(Color3.fromRGB(255, 90, 220), Color3.fromRGB(80, 160, 255)),
		ColorSequence.new(Color3.fromRGB(120, 200, 255), Color3.fromRGB(80, 255, 160)),
	}
	for i = 1, 3 do
		local de = peca(b, { Name = "Aurora", Transparency = 1, Size = Vector3.one, Position = b.centro + Vector3.new(-80, 55 + i * 8, -60 + i * 35) })
		local ate = peca(b, { Name = "Aurora", Transparency = 1, Size = Vector3.one, Position = b.centro + Vector3.new(80, 60 + i * 6, -40 + i * 30) })
		local a0 = Instance.new("Attachment")
		a0.Parent = de
		local a1 = Instance.new("Attachment")
		a1.Parent = ate
		local fita = Instance.new("Beam")
		fita.Attachment0 = a0
		fita.Attachment1 = a1
		fita.Color = cores[i]
		fita.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.3), NumberSequenceKeypoint.new(0.75, 0.3), NumberSequenceKeypoint.new(1, 1) })
		fita.Width0 = 22
		fita.Width1 = 30
		fita.LightEmission = 0.5
		fita.Brightness = 2
		fita.FaceCamera = false
		fita.Segments = 20
		fita.Parent = de
		table.insert(b.criados, fita)
		table.insert(auroras, { fita = fita, fase = i * 2.1 })
	end
	b.dados.auroras = auroras
	-- cristais piscando (um brilho de cada vez)
	for i, cristal in todos(b, "Cristal") do
		if i % 2 == 0 then
			emissor(b, cristal, {
				Texture = FAISCA,
				Color = ColorSequence.new(BRANCO, cristal.Color),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 1.4), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(0.4, 0.6),
				Speed = NumberRange.new(0),
				Rotation = NumberRange.new(0, 90),
				Shape = Enum.ParticleEmitterShape.Box,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
				LightEmission = 1,
				Rate = 0.4,
			})
		end
	end
	b.dados.crateras = todos(b, "Cratera")
	b.quadro = function(_, agora)
		for _, a in b.dados.auroras do
			a.fita.CurveSize0 = math.sin(agora * 0.4 + a.fase) * 25
			a.fita.CurveSize1 = math.cos(agora * 0.33 + a.fase) * 25
		end
	end
	b.proximo = os.clock() + 2
	b.eventos = function()
		meteoro(b)
		b.proximo = os.clock() + 3 + math.random() * 4
	end
end

local MONTAR: { [string]: (Bioma) -> () } = {
	floresta = montarSelva,
	praia = montarPraia,
	deserto = montarDeserto,
	vulcao = montarVulcao,
	espaco = montarEspaco,
}

-- Liga e desliga ----------------------------------------------------------------------

local function ligar(b: Bioma, ativo: boolean)
	if b.ativo == ativo then
		return
	end
	b.ativo = ativo
	if ativo and not b.montado then
		b.montado = true
		MONTAR[b.estilo](b)
	end
	for _, e in b.emissores do
		e.Enabled = ativo
	end
	for _, objeto in b.criados do
		if objeto:IsA("BasePart") and objeto.Name == "RaioDeSol" then
			objeto.LocalTransparencyModifier = if ativo then 0 else 1
		elseif objeto:IsA("Beam") then
			objeto.Enabled = ativo
		end
	end
end

local function esquecer(b: Bioma)
	for _, objeto in b.criados do
		objeto:Destroy()
	end
	table.clear(b.criados)
	table.clear(b.emissores)
end

local function procurar()
	local mapa = Workspace:FindFirstChild("Mapa")
	if not mapa then
		return
	end
	for _, config in Config.BIOMAS do
		local pastaBioma = mapa:FindFirstChild(config.nome)
		local piso = pastaBioma and pastaBioma:FindFirstChild("Piso")
		if pastaBioma and piso and piso:IsA("BasePart") and MONTAR[config.estilo] then
			local ja = false
			for _, b in biomas do
				if b.pasta == pastaBioma then
					ja = true
				end
			end
			if not ja then
				local b: Bioma = {
					pasta = pastaBioma,
					centro = piso.Position,
					estilo = config.estilo,
					montado = false,
					ativo = false,
					criados = {},
					emissores = {},
					proximo = os.clock() + 1,
					quadro = nil,
					eventos = nil,
					dados = {},
				}
				table.insert(biomas, b)
				pastaBioma.Destroying:Once(function()
					esquecer(b)
					table.remove(biomas, table.find(biomas, b) or 0)
				end)
			end
		end
	end
end

function BiomasVfx.iniciar()
	task.spawn(function()
		local mapa = Workspace:WaitForChild("Mapa", 60)
		if not mapa then
			return
		end
		task.wait(2) -- deixa a decoração chegar do servidor
		procurar()
		mapa.ChildAdded:Connect(function()
			task.delay(2, procurar)
		end)
	end)

	task.spawn(function()
		local voltas = 0
		while true do
			task.wait(0.5)
			-- com streaming, o chão dos biomas longe só chega quando você se aproxima
			voltas += 1
			if voltas % 4 == 0 and #biomas < #Config.BIOMAS then
				procurar()
			end
			local camera = Workspace.CurrentCamera
			if camera then
				local olho = camera.CFrame.Position
				for _, b in biomas do
					local plano = Vector3.new(olho.X - b.centro.X, 0, olho.Z - b.centro.Z)
					ligar(b, plano.Magnitude < ALCANCE)
				end
			end
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		local agora = os.clock()
		for _, b in biomas do
			if b.ativo then
				if b.quadro then
					b.quadro(b, agora, dt)
				end
				if b.eventos and agora >= b.proximo then
					b.eventos(b)
				end
			end
		end
	end)
end

return BiomasVfx

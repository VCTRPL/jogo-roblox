-- Vida do mapa, só neste computador: água correndo e respingando nas
-- cachoeiras, brilhos no lago da Praia, brasas e fumaça saindo das rachaduras
-- de lava, redemoinho e cubinhos em órbita nos portais dos biomas e um
-- vórtice no portal do fim do mapa. As peças são achadas pelo nome, então o
-- mapa pode mudar à vontade. Longe da câmera tudo desliga (celular agradece).
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Tremor = require(script.Parent.Tremor)

local MapaVfx = {}

local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"
local BRASA = "rbxasset://textures/particles/fire_sparks_main.dds"
local VORTICE = "rbxasset://textures/particles/forcefield_vortex_main.dds"
local BRILHO = "rbxasset://textures/particles/forcefield_glow_main.dds"
local ALCANCE = 260 -- longe disso desliga
local BRANCO = Color3.new(1, 1, 1)

type Enfeite = {
	fonte: BasePart, -- a peça do mapa
	emissores: { ParticleEmitter },
	criados: { Instance }, -- tudo que este módulo criou para ela
	texturas: { { textura: Texture, velocidade: number } },
	orbita: { { parte: BasePart, angulo: number, raio: number } }?,
	ligado: boolean,
}

local enfeites: { [BasePart]: Enfeite } = {}
local pasta = Instance.new("Folder")
pasta.Name = "MapaVfx"
pasta.Parent = Workspace

local function emissor(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for chave, valor in props do
		(e :: any)[chave] = valor
	end
	e.Rate *= Tremor.qualidade
	e.Parent = parent
	return e
end

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

-- Faixas de água descendo: a textura de fumaça repetida e andando para baixo.
local function texturaCorrendo(e: Enfeite, face: Enum.NormalId, cor: Color3, velocidade: number, transparencia: number)
	local t = Instance.new("Texture")
	t.Name = "VfxCorrendo"
	t.Texture = FUMACA
	t.Face = face
	t.Color3 = cor
	t.Transparency = transparencia
	t.StudsPerTileU = 3
	t.StudsPerTileV = 6
	t.Parent = e.fonte
	table.insert(e.criados, t)
	table.insert(e.texturas, { textura = t, velocidade = velocidade })
end

local function novo(fonte: BasePart): Enfeite
	local e: Enfeite = { fonte = fonte, emissores = {}, criados = {}, texturas = {}, orbita = nil, ligado = true }
	enfeites[fonte] = e
	return e
end

local function guardar(e: Enfeite, objeto: Instance)
	table.insert(e.criados, objeto)
	if objeto:IsA("ParticleEmitter") then
		table.insert(e.emissores, objeto)
	end
end

-- Cada tipo de peça ganha um enfeite -----------------------------------------

local ENFEITAR: { [string]: (BasePart) -> () } = {}

ENFEITAR.Cachoeira = function(fonte)
	local e = novo(fonte)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		texturaCorrendo(e, face, BRANCO, 9, 0.35)
	end
	-- riscos de água caindo junto com a queda
	guardar(e, emissor(fonte, {
		Name = "VfxQueda",
		Texture = FAISCA,
		Color = ColorSequence.new(Color3.fromRGB(220, 245, 255)),
		Transparency = NumberSequence.new(0.2, 0.9),
		Size = NumberSequence.new(0.35),
		Squash = NumberSequence.new(-2.5),
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		EmissionDirection = Enum.NormalId.Bottom,
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(16, 24),
		SpreadAngle = Vector2.new(4, 4),
		Rate = 22,
		LightEmission = 0.6,
	}))
	-- névoa e gotas pulando lá embaixo
	local pe = Instance.new("Attachment")
	pe.Name = "VfxPeCachoeira"
	pe.Position = Vector3.new(0, -fonte.Size.Y / 2 + 0.3, 0)
	pe.Parent = fonte
	guardar(e, pe)
	guardar(e, emissor(pe, {
		Name = "VfxNevoa",
		Texture = FUMACA,
		Color = ColorSequence.new(Color3.fromRGB(235, 248, 255)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.55), NumberSequenceKeypoint.new(1, 1) }),
		Size = NumberSequence.new(2.5, 7),
		Lifetime = NumberRange.new(1.4, 2.2),
		Speed = NumberRange.new(2, 4),
		SpreadAngle = Vector2.new(70, 70),
		Acceleration = Vector3.new(0, 1.5, 0),
		RotSpeed = NumberRange.new(-30, 30),
		Rotation = NumberRange.new(0, 360),
		Rate = 6,
	}))
	guardar(e, emissor(pe, {
		Name = "VfxGotas",
		Texture = FAISCA,
		Color = ColorSequence.new(BRANCO, Color3.fromRGB(150, 210, 255)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(7, 12),
		SpreadAngle = Vector2.new(55, 55),
		Acceleration = Vector3.new(0, -40, 0),
		Rate = 18,
		LightEmission = 0.7,
	}))
end

local function brilhosNaAgua(fonte: BasePart, quantos: number)
	local e = novo(fonte)
	texturaCorrendo(e, Enum.NormalId.Top, BRANCO, 1.2, 0.75)
	guardar(e, emissor(fonte, {
		Name = "VfxBrilhoAgua",
		Texture = FAISCA,
		Color = ColorSequence.new(BRANCO, Color3.fromRGB(170, 230, 255)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.6, 1.2),
		Speed = NumberRange.new(0, 0.2),
		EmissionDirection = Enum.NormalId.Top,
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Rate = quantos,
		LightEmission = 1,
	}))
end
ENFEITAR.Agua = function(fonte)
	brilhosNaAgua(fonte, 26)
end
ENFEITAR.Lago = function(fonte)
	brilhosNaAgua(fonte, 4)
end

ENFEITAR.Lava = function(fonte)
	local e = novo(fonte)
	-- rachaduras finas: só soltam brasas; poças grandes soltam fumaça também
	local tamanho = fonte.Size.X * fonte.Size.Y * fonte.Size.Z
	guardar(e, emissor(fonte, {
		Name = "VfxBrasas",
		Texture = BRASA,
		Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 70, 20)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(1, 2),
		Speed = NumberRange.new(2, 6),
		SpreadAngle = Vector2.new(25, 25),
		Acceleration = Vector3.new(math.random(-2, 2), 4, 0),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Rate = math.clamp(tamanho * 0.6, 3, 14),
		RotSpeed = NumberRange.new(-90, 90),
		LightEmission = 1,
	}))
	guardar(e, emissor(fonte, {
		Name = "VfxCalor",
		Texture = FUMACA,
		Color = ColorSequence.new(Color3.fromRGB(255, 120, 60), Color3.fromRGB(60, 50, 50)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.75), NumberSequenceKeypoint.new(1, 1) }),
		Size = NumberSequence.new(1.5, 5),
		Lifetime = NumberRange.new(2, 3),
		Speed = NumberRange.new(2, 4),
		SpreadAngle = Vector2.new(15, 15),
		Acceleration = Vector3.new(0, 1, 0),
		Shape = Enum.ParticleEmitterShape.Box,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-20, 20),
		Rate = math.clamp(tamanho * 0.15, 1, 5),
	}))
end

-- Portal de entrada de cada bioma (campo de força com o atributo "Bioma").
ENFEITAR.Portal = function(fonte)
	if not fonte:GetAttribute("Bioma") then
		return
	end
	local e = novo(fonte)
	local cor = fonte.Color
	-- redemoinho girando bem no meio do arco
	guardar(e, emissor(fonte, {
		Name = "VfxRedemoinho",
		Texture = VORTICE,
		Color = ColorSequence.new(cor:Lerp(BRANCO, 0.4)),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(1, 1) }),
		Size = NumberSequence.new(9, 11),
		Lifetime = NumberRange.new(1.6, 2.2),
		Speed = NumberRange.new(0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(120, 160),
		Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
		LockedToPart = true,
		Rate = 2,
		LightEmission = 0.8,
	}))
	-- brilhos subindo pela cortina do portal
	guardar(e, emissor(fonte, {
		Name = "VfxBrilhoPortal",
		Texture = FAISCA,
		Color = ColorSequence.new(BRANCO, cor),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(1.2, 2),
		Speed = NumberRange.new(1, 3),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(20, 20),
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Rate = 14,
		LightEmission = 1,
	}))
	local luz = Instance.new("PointLight")
	luz.Name = "VfxLuzPortal"
	luz.Color = cor
	luz.Range = 22
	luz.Brightness = 1.5
	luz.Parent = fonte
	guardar(e, luz)
	-- anel de cubinhos (estilo Lego) girando em volta do arco
	e.orbita = {}
	local raio = math.min(fonte.Size.Y, fonte.Size.Z) * 0.55
	for i = 1, 10 do
		local cubo = peca({
			Name = "VfxCuboPortal",
			Color = cor:Lerp(BRANCO, (i % 2) * 0.5),
			Size = Vector3.one * 0.7,
		})
		guardar(e, cubo)
		table.insert(e.orbita :: any, { parte = cubo, angulo = i / 10 * math.pi * 2, raio = raio })
	end
end

-- Núcleo do portal do fim do mapa: um vórtice puxando brilhos para dentro.
ENFEITAR.NucleoPortal = function(fonte)
	local e = novo(fonte)
	local casca = peca({ Name = "VfxVorticeFim", Transparency = 1, Size = Vector3.one * 18, Shape = Enum.PartType.Ball, CFrame = fonte.CFrame })
	guardar(e, casca)
	guardar(e, emissor(casca, {
		Name = "VfxSugado",
		Texture = FAISCA,
		Color = ColorSequence.new(Color3.fromRGB(200, 120, 255), BRANCO),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.9, 1.1),
		Speed = NumberRange.new(8, 10),
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Rate = 40,
		LightEmission = 1,
	}))
	guardar(e, emissor(fonte, {
		Name = "VfxNucleo",
		Texture = BRILHO,
		Color = ColorSequence.new(Color3.fromRGB(170, 90, 255), BRANCO),
		Transparency = NumberSequence.new(0.3, 1),
		Size = NumberSequence.new(4, 10),
		Lifetime = NumberRange.new(0.8, 1.2),
		Speed = NumberRange.new(0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-200, 200),
		LockedToPart = true,
		Rate = 6,
		LightEmission = 1,
	}))
end

-- Liga, desliga e esquece ------------------------------------------------------

local function esquecer(fonte: BasePart)
	local e = enfeites[fonte]
	if not e then
		return
	end
	enfeites[fonte] = nil
	for _, objeto in e.criados do
		objeto:Destroy()
	end
end

local function considerar(objeto: Instance)
	if not objeto:IsA("BasePart") or enfeites[objeto] or objeto:IsDescendantOf(pasta) then
		return
	end
	local enfeitar = ENFEITAR[objeto.Name]
	if not enfeitar then
		return
	end
	-- ignora peças sem lugar no mapa (por exemplo, dentro de personagens)
	local modelo = objeto:FindFirstAncestorWhichIsA("Model")
	if modelo and modelo:FindFirstChildOfClass("Humanoid") then
		return
	end
	enfeitar(objeto)
	local e = enfeites[objeto]
	if e then
		objeto.Destroying:Once(function()
			esquecer(objeto)
		end)
		objeto.AncestryChanged:Connect(function(_, pai)
			if not pai then
				esquecer(objeto)
			end
		end)
	end
end

local function ligar(e: Enfeite, ligado: boolean)
	if e.ligado == ligado then
		return
	end
	e.ligado = ligado
	for _, em in e.emissores do
		em.Enabled = ligado
	end
	if e.orbita then
		for _, item in e.orbita do
			item.parte.Transparency = if ligado then 0 else 1
		end
	end
end

function MapaVfx.iniciar()
	Workspace.DescendantAdded:Connect(considerar)
	task.spawn(function()
		-- devagar, para não travar a entrada no jogo
		for i, objeto in Workspace:GetDescendants() do
			considerar(objeto)
			if i % 4000 == 0 then
				task.wait()
			end
		end
	end)

	-- liga só o que está perto, duas vezes por segundo
	task.spawn(function()
		while true do
			task.wait(0.5)
			local camera = Workspace.CurrentCamera
			if camera then
				local olho = camera.CFrame.Position
				for fonte, e in enfeites do
					ligar(e, (fonte.Position - olho).Magnitude < ALCANCE)
				end
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		local agora = os.clock()
		for fonte, e in enfeites do
			if not e.ligado then
				continue
			end
			for _, item in e.texturas do
				item.textura.OffsetStudsV = -(agora * item.velocidade) % item.textura.StudsPerTileV
			end
			local orbita = e.orbita
			if orbita then
				-- gira em volta do eixo X do portal (a estrada vai em X)
				local centro = fonte.CFrame
				local pulso = 1 + math.sin(agora * 2) * 0.06
				for i, item in orbita do
					local a = item.angulo + agora * 1.3
					item.parte.CFrame = centro
						* CFrame.new(0, math.sin(a) * item.raio * pulso, math.cos(a) * item.raio * pulso)
						* CFrame.Angles(agora * 2 + i, agora * 3, 0)
				end
			end
		end
	end)
end

return MapaVfx

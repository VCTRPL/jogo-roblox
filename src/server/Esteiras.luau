-- Modelos 3D das esteiras de corrida: cada nível tem uma esteira diferente,
-- todas no formato de esteira de academia (deck comprido, colunas, corrimão
-- e painel), com neon e efeitos cada vez mais fortes.
-- A peça "Pista" é onde o jogador corre: quem sobe nela fica preso em
-- cima dela correndo sozinho (veja Bases.luau). O cliente anima as faixas da pista (tag "FaixaEsteira") e o
-- que gira ou flutua (tag "GirarEsteira"), veja src/client/init.client.luau.
local CollectionService = game:GetService("CollectionService")

local Mapa = require(script.Parent.Mapa)

local Esteiras = {}

local VELOCIDADE_FAIXAS = 12
local ALTURA_PISTA = 1.05 -- topo da pista acima do chão
local PRETO = Color3.fromRGB(28, 28, 32)

local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"
local FOGO = "rbxasset://textures/particles/fire_main.dds"

type Estilo = {
	estrutura: Color3, -- deck, colunas e corrimão
	material: Enum.Material,
	pista: Color3,
	materialPista: Enum.Material,
	faixa: Color3,
	neon: Color3?, -- cor das luzes (nil = sem brilho)
	grosso: boolean?, -- luzes largas, tipo armadura
	tela: (gui: SurfaceGui, cor: Color3) -> (),
	extra: ((modelo: Model, cf: CFrame, cor: Color3) -> ())?,
}

-- Peça decorativa: não colide e não atrapalha cliques nem toques.
local function enfeite(modelo: Instance, cf: CFrame, tamanho: Vector3, cor: Color3, material: Enum.Material, props: any?): BasePart
	local p = Mapa.parte({
		Size = tamanho,
		CFrame = cf,
		Color = cor,
		Material = material,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = modelo,
	})
	if props then
		for chave, valor in props do
			(p :: any)[chave] = valor
		end
	end
	return p
end

local function particulas(parent: Instance, props): ParticleEmitter
	local emissor = Instance.new("ParticleEmitter")
	for chave, valor in props do
		(emissor :: any)[chave] = valor
	end
	emissor.Parent = parent
	return emissor
end

local function luz(parent: Instance, cor: Color3, alcance: number, brilho: number)
	local l = Instance.new("PointLight")
	l.Color = cor
	l.Range = alcance
	l.Brightness = brilho
	l.Parent = parent
end

-- Faz a peça girar no lugar (ou em volta de "centro") e, se pedir, flutuar.
local function girar(parte: BasePart, graus: number, flutua: number, centro: Vector3?)
	parte:SetAttribute("Giro", graus)
	parte:SetAttribute("Flutua", flutua)
	if centro then
		parte:SetAttribute("Centro", centro)
	end
	CollectionService:AddTag(parte, "GirarEsteira")
end

-- Peça invisível que só serve de área para as partículas saírem.
local function area(modelo: Model, cf: CFrame, tamanho: Vector3): BasePart
	return enfeite(modelo, cf, tamanho, PRETO, Enum.Material.SmoothPlastic, { Transparency = 1, Name = "Aura" })
end

-- Quadradinhos ou cristais brilhando em volta da esteira.
local function flutuantes(modelo: Model, cf: CFrame, cor: Color3, quantidade: number, tamanho: Vector3)
	local aleatorio = Random.new(quantidade)
	for i = 1, quantidade do
		local angulo = i / quantidade * math.pi * 2
		local raio = aleatorio:NextNumber(4.2, 5.4)
		local posicao = cf * CFrame.new(math.cos(angulo) * raio, aleatorio:NextNumber(1.5, 7), math.sin(angulo) * raio * 1.3)
		local peca = enfeite(
			modelo,
			posicao * CFrame.Angles(math.rad(45), aleatorio:NextNumber(0, math.pi), math.rad(45)),
			tamanho,
			cor,
			Enum.Material.Neon,
			{ CastShadow = false, Name = "Flutuante" }
		)
		girar(peca, aleatorio:NextNumber(40, 120), aleatorio:NextNumber(0.2, 0.5))
	end
end

-- Círculo de luz no chão em volta da esteira.
local function halo(modelo: Model, cf: CFrame, cor: Color3, transparencia: number)
	enfeite(
		modelo,
		cf * CFrame.new(0, 0.03, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Vector3.new(0.05, 12, 12),
		cor,
		Enum.Material.Neon,
		{ Shape = Enum.PartType.Cylinder, Transparency = transparencia, CastShadow = false, Name = "Halo" }
	)
end

-- Brilhos subindo da esteira.
local function brilhosSubindo(modelo: Model, cf: CFrame, cor: Color3, taxa: number)
	local aura = area(modelo, cf * CFrame.new(0, 1.2, 0), Vector3.new(8, 0.5, 14))
	particulas(aura, {
		Texture = FAISCA,
		Color = ColorSequence.new(Color3.new(1, 1, 1), cor),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(1, 2),
		Rate = taxa,
		Speed = NumberRange.new(2, 4),
		SpreadAngle = Vector2.new(10, 10),
		LightEmission = 1,
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
end

-- Fumaça colorida rente ao chão.
local function fumaca(modelo: Model, cf: CFrame, cor: Color3, taxa: number)
	local aura = area(modelo, cf * CFrame.new(0, 0.4, 0), Vector3.new(9, 0.5, 15))
	particulas(aura, {
		Texture = FUMACA,
		Color = ColorSequence.new(cor),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Size = NumberSequence.new(2.5, 5),
		Lifetime = NumberRange.new(2, 3),
		Rate = taxa,
		Speed = NumberRange.new(0.5, 1.5),
		LightEmission = 0.7,
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
end

-- Anel girando em volta da esteira, um pouco ondulado.
local function anel(modelo: Model, cf: CFrame, cor: Color3, raioX: number, raioZ: number, altura: number, onda: number, giro: number)
	local centro = (cf * CFrame.new(0, altura, 0)).Position
	local pedacos = 22
	local function ponto(i: number): Vector3
		local angulo = i / pedacos * math.pi * 2
		return (cf * CFrame.new(math.cos(angulo) * raioX, altura + math.sin(angulo) * onda, math.sin(angulo) * raioZ)).Position
	end
	for i = 0, pedacos - 1 do
		if i % 6 ~= 5 then -- uns buracos para parecer um rastro
			local de, ate = ponto(i), ponto(i + 1)
			local pedaco = enfeite(
				modelo,
				CFrame.lookAt((de + ate) / 2, ate),
				Vector3.new(0.18, 0.18, (ate - de).Magnitude + 0.1),
				cor,
				Enum.Material.Neon,
				{ CastShadow = false, Transparency = 0.15 + (i % 6) * 0.12, Name = "Anel" }
			)
			girar(pedaco, giro, 0, centro)
		end
	end
end

-- Telas do painel ------------------------------------------------------------

local function icone(texto: string)
	return function(gui: SurfaceGui, cor: Color3)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.TextColor3 = cor
		label.Text = texto
		label.Parent = gui
	end
end

local function graficoBarras(gui: SurfaceGui, cor: Color3)
	for i, altura in { 0.35, 0.6, 0.45, 0.8, 0.65 } do
		local barra = Instance.new("Frame")
		barra.AnchorPoint = Vector2.new(0, 1)
		barra.Position = UDim2.fromScale(0.12 + (i - 1) * 0.16, 0.88)
		barra.Size = UDim2.fromScale(0.11, altura * 0.75)
		barra.BackgroundColor3 = cor
		barra.BorderSizePixel = 0
		barra.Parent = gui
	end
end

local function telaApagada(gui: SurfaceGui, _cor: Color3)
	local fundo = Instance.new("Frame")
	fundo.Size = UDim2.fromScale(1, 1)
	fundo.BackgroundColor3 = Color3.fromRGB(70, 80, 85)
	fundo.BorderSizePixel = 0
	fundo.Parent = gui
end

-- Estilos de cada nível ------------------------------------------------------

local ESTILOS: { Estilo } = {
	-- 1: Básica, cinza e prata, sem brilho
	{
		estrutura = Color3.fromRGB(150, 152, 158),
		material = Enum.Material.Metal,
		pista = Color3.fromRGB(25, 25, 28),
		materialPista = Enum.Material.Fabric,
		faixa = Color3.fromRGB(45, 45, 50),
		neon = nil,
		tela = telaApagada,
	},
	-- 2: Intermediária, preta com neon azul
	{
		estrutura = PRETO,
		material = Enum.Material.SmoothPlastic,
		pista = Color3.fromRGB(20, 20, 24),
		materialPista = Enum.Material.Fabric,
		faixa = Color3.fromRGB(35, 40, 50),
		neon = Color3.fromRGB(0, 170, 255),
		tela = graficoBarras,
		extra = function(modelo, cf, cor)
			halo(modelo, cf, cor, 0.7)
			brilhosSubindo(modelo, cf, cor, 5)
			flutuantes(modelo, cf, cor, 5, Vector3.new(0.35, 0.35, 0.35))
		end,
	},
	-- 3: Avançada, neon roxo, fumaça roxa e quadradinhos flutuando
	{
		estrutura = PRETO,
		material = Enum.Material.SmoothPlastic,
		pista = Color3.fromRGB(22, 20, 28),
		materialPista = Enum.Material.Fabric,
		faixa = Color3.fromRGB(45, 35, 60),
		neon = Color3.fromRGB(115, 60, 255),
		tela = icone("🏃"),
		extra = function(modelo, cf, cor)
			halo(modelo, cf, cor, 0.55)
			fumaca(modelo, cf, cor, 8)
			brilhosSubindo(modelo, cf, cor, 8)
			flutuantes(modelo, cf, cor, 12, Vector3.new(0.45, 0.45, 0.45))
		end,
	},
	-- 4: Épica, dourada grossa, anéis dourados girando e muito brilho
	{
		estrutura = Color3.fromRGB(22, 22, 24),
		material = Enum.Material.SmoothPlastic,
		pista = Color3.fromRGB(20, 20, 22),
		materialPista = Enum.Material.Fabric,
		faixa = Color3.fromRGB(50, 45, 30),
		neon = Color3.fromRGB(255, 165, 20),
		grosso = true,
		tela = icone("👑"),
		extra = function(modelo, cf, cor)
			-- placas douradas nas laterais e nas colunas, tipo armadura
			for _, x in { -1, 1 } do
				for _, z in { -4.2, 4.6 } do
					enfeite(modelo, cf * CFrame.new(x * 3.64, 0.65, z), Vector3.new(0.06, 1, 3.4), cor, Enum.Material.Neon)
				end
				local coluna = cf * CFrame.new(x * 2.95, 4.5, -5.75) * CFrame.Angles(math.rad(10), 0, 0)
				enfeite(modelo, coluna * CFrame.new(x * 0.47, 0.3, 0), Vector3.new(0.05, 5.4, 0.8), cor, Enum.Material.Neon)
			end
			-- dois anéis girando para lados opostos
			anel(modelo, cf, cor, 5, 8, 3, 1.2, 50)
			anel(modelo, cf, Color3.fromRGB(255, 225, 120), 4.4, 7, 5, -1, -70)
			halo(modelo, cf, cor, 0.45)
			brilhosSubindo(modelo, cf, cor, 14)
			local aura = area(modelo, cf * CFrame.new(0, 4, 0), Vector3.new(9, 7, 15))
			particulas(aura, {
				Texture = FAISCA,
				Color = ColorSequence.new(cor, Color3.fromRGB(255, 240, 160)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(1, 2),
				Rate = 12,
				Speed = NumberRange.new(0.3, 1),
				RotSpeed = NumberRange.new(-120, 120),
				LightEmission = 1,
				Shape = Enum.ParticleEmitterShape.Box,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			})
			flutuantes(modelo, cf, cor, 14, Vector3.new(0.4, 0.4, 0.4))
		end,
	},
	-- 5: Lendária, neon vermelho, espinhos, chamas, brasas e cristais
	{
		estrutura = Color3.fromRGB(20, 18, 20),
		material = Enum.Material.SmoothPlastic,
		pista = Color3.fromRGB(35, 12, 14),
		materialPista = Enum.Material.DiamondPlate,
		faixa = Color3.fromRGB(110, 20, 25),
		neon = Color3.fromRGB(255, 35, 45),
		grosso = true,
		tela = icone("🔥"),
		extra = function(modelo, cf, cor)
			-- espinhos nas colunas, no painel e nos cantos
			local function espinho(lugar: CFrame, tamanho: number)
				enfeite(modelo, lugar, Vector3.new(0.5, tamanho, 0.9), Color3.fromRGB(20, 18, 20), Enum.Material.SmoothPlastic, {
					Name = "Espinho",
				})
				local ponta = Instance.new("WedgePart")
				ponta.Anchored = true
				ponta.CanCollide = false
				ponta.CanQuery = false
				ponta.CanTouch = false
				ponta.Size = Vector3.new(0.5, tamanho * 0.8, 0.9)
				ponta.CFrame = lugar * CFrame.new(0, tamanho * 0.9, 0)
				ponta.Color = cor
				ponta.Material = Enum.Material.Neon
				ponta.Parent = modelo
			end
			for _, x in { -1, 1 } do
				-- no topo das colunas, apontando para fora
				espinho(cf * CFrame.new(x * 3.4, 8, -5.6) * CFrame.Angles(0, 0, math.rad(-x * 35)), 1.4)
				espinho(cf * CFrame.new(x * 3.2, 6.6, -5.8) * CFrame.Angles(0, 0, math.rad(-x * 55)), 1.1)
				-- dos lados do painel
				espinho(cf * CFrame.new(x * 2.6, 9.3, -5.6) * CFrame.Angles(0, 0, math.rad(-x * 20)), 1.3)
				-- cantos de trás e da frente, deitados para fora
				espinho(cf * CFrame.new(x * 3.8, 0.9, 6.4) * CFrame.Angles(math.rad(50), 0, math.rad(-x * 40)), 1.2)
				espinho(cf * CFrame.new(x * 3.8, 0.9, -6.6) * CFrame.Angles(math.rad(-50), 0, math.rad(-x * 40)), 1.2)
			end
			-- chamas nos cantos de trás e no topo das colunas
			for _, lugar in { Vector3.new(-3.2, 1, 6.4), Vector3.new(3.2, 1, 6.4), Vector3.new(-3.4, 8.6, -5.6), Vector3.new(3.4, 8.6, -5.6) } do
				local suporte = area(modelo, cf * CFrame.new(lugar), Vector3.new(1, 1, 1))
				local fogo = Instance.new("Fire")
				fogo.Size = if lugar.Y > 2 then 3 else 5
				fogo.Heat = 8
				fogo.Color = cor
				fogo.SecondaryColor = Color3.fromRGB(255, 120, 60)
				fogo.Parent = suporte
			end
			halo(modelo, cf, cor, 0.4)
			fumaca(modelo, cf, cor, 12)
			-- brasas subindo por toda a esteira
			local brasas = area(modelo, cf * CFrame.new(0, 1.2, 0), Vector3.new(8, 0.5, 14))
			particulas(brasas, {
				Texture = FOGO,
				Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), cor),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(1, 2),
				Rate = 16,
				Speed = NumberRange.new(2, 5),
				SpreadAngle = Vector2.new(15, 15),
				RotSpeed = NumberRange.new(-90, 90),
				LightEmission = 1,
				Shape = Enum.ParticleEmitterShape.Box,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			})
			flutuantes(modelo, cf, cor, 14, Vector3.new(0.4, 1.2, 0.4))
		end,
	},
	-- 6: Cósmica, azul-marinho com neon ciano, planetinhas em órbita e galáxia girando
	{
		estrutura = Color3.fromRGB(16, 18, 40),
		material = Enum.Material.SmoothPlastic,
		pista = Color3.fromRGB(12, 14, 34),
		materialPista = Enum.Material.Fabric,
		faixa = Color3.fromRGB(40, 70, 130),
		neon = Color3.fromRGB(80, 220, 255),
		grosso = true,
		tela = icone("🌌"),
		extra = function(modelo, cf, cor)
			local roxo = Color3.fromRGB(190, 90, 255)
			anel(modelo, cf, cor, 5.4, 8.4, 2.5, 0.8, 40)
			anel(modelo, cf, roxo, 4.6, 7.4, 5.5, -1.2, -55)
			-- planetinhas girando em volta da esteira
			local centro = (cf * CFrame.new(0, 4, 0)).Position
			for i, planeta in { { Color3.fromRGB(255, 150, 80), 1.4 }, { Color3.fromRGB(120, 255, 200), 1 }, { roxo, 1.2 } } do
				local angulo = i / 3 * math.pi * 2
				local p = enfeite(
					modelo,
					cf * CFrame.new(math.cos(angulo) * 6, 3 + i * 1.5, math.sin(angulo) * 8),
					Vector3.one * planeta[2],
					planeta[1],
					Enum.Material.Neon,
					{ CastShadow = false, Name = "Planeta" }
				)
				girar(p, 30 + i * 12, 0.3, centro)
			end
			halo(modelo, cf, cor, 0.4)
			-- poeira de galáxia girando
			local aura = area(modelo, cf * CFrame.new(0, 4, 0), Vector3.new(10, 7, 16))
			particulas(aura, {
				Texture = FAISCA,
				Color = ColorSequence.new(cor, roxo),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.5), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(1.5, 3),
				Rate = 20,
				Speed = NumberRange.new(0.2, 0.8),
				RotSpeed = NumberRange.new(-60, 60),
				LightEmission = 1,
				Shape = Enum.ParticleEmitterShape.Box,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			})
			fumaca(modelo, cf, roxo, 10)
			brilhosSubindo(modelo, cf, cor, 16)
			flutuantes(modelo, cf, Color3.new(1, 1, 1), 18, Vector3.new(0.25, 0.25, 0.25))
		end,
	},
	-- 7: Divina, branca e dourada, com asas, auréola girando e raios de luz
	{
		estrutura = Color3.fromRGB(245, 245, 250),
		material = Enum.Material.SmoothPlastic,
		pista = Color3.fromRGB(235, 230, 215),
		materialPista = Enum.Material.Fabric,
		faixa = Color3.fromRGB(255, 220, 120),
		neon = Color3.fromRGB(255, 225, 120),
		grosso = true,
		tela = icone("👼"),
		extra = function(modelo, cf, cor)
			-- asas de penas dos dois lados
			for _, x in { -1, 1 } do
				for i = 0, 4 do
					local comprimento = 6 - i * 0.9
					local pena = cf
						* CFrame.new(x * 4.2, 3 + i * 0.9, 1.5 + i * 0.4)
						* CFrame.Angles(0, 0, math.rad(x * (20 + i * 12)))
						* CFrame.new(x * comprimento / 2, 0, 0)
					enfeite(modelo, pena, Vector3.new(comprimento, 0.7, 1.4), Color3.fromRGB(250, 250, 255), Enum.Material.SmoothPlastic, { Name = "Pena" })
					enfeite(modelo, pena * CFrame.new(0, -0.37, 0), Vector3.new(comprimento, 0.06, 1.42), cor, Enum.Material.Neon, { Name = "PenaNeon", CastShadow = false })
				end
			end
			-- auréola girando em cima do painel
			anel(modelo, cf * CFrame.new(0, 0, -5.3), cor, 2.2, 2.2, 11.5, 0, 90)
			-- raios de luz subindo dos cantos
			for _, x in { -1, 1 } do
				for _, z in { -6, 6.5 } do
					enfeite(modelo, cf * CFrame.new(x * 3.6, 12, z), Vector3.new(0.8, 24, 0.8), cor, Enum.Material.Neon, {
						Transparency = 0.75,
						CastShadow = false,
						Name = "Raio",
					})
				end
			end
			anel(modelo, cf, cor, 5.2, 8.2, 3, 0.6, 35)
			halo(modelo, cf, cor, 0.35)
			-- penas douradas caindo devagar
			local ceu = area(modelo, cf * CFrame.new(0, 12, 0), Vector3.new(10, 1, 16))
			particulas(ceu, {
				Texture = FAISCA,
				Color = ColorSequence.new(Color3.new(1, 1, 1), cor),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.2) }),
				Lifetime = NumberRange.new(3, 5),
				Rate = 10,
				Speed = NumberRange.new(1, 2),
				EmissionDirection = Enum.NormalId.Bottom,
				RotSpeed = NumberRange.new(-90, 90),
				LightEmission = 1,
				Shape = Enum.ParticleEmitterShape.Box,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			})
			brilhosSubindo(modelo, cf, cor, 18)
			flutuantes(modelo, cf, cor, 16, Vector3.new(0.35, 0.35, 0.35))
		end,
	},
}

-- Efeitos que toda esteira tem, mais fortes a cada nível: riscos de vento
-- correndo pela pista, faíscas (ou poeira, na Básica) saindo do rolo de trás
-- e um pilar de brilhos subindo nas laterais.
local function efeitosPista(modelo: Model, chao: CFrame, nivel: number, cor: Color3)
	-- 1 na Lendária (nível 5); as Cósmica e Divina passam disso
	local forca = nivel / 5

	-- riscos de vento: nascem na frente da pista e correm para trás
	local frente = area(modelo, chao * CFrame.new(0, ALTURA_PISTA + 0.9, -4), Vector3.new(4.4, 1.6, 0.5))
	particulas(frente, {
		Name = "Vento",
		Texture = FAISCA,
		Color = ColorSequence.new(Color3.new(1, 1, 1), cor),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Size = NumberSequence.new(0.18 + forca * 0.12),
		Squash = NumberSequence.new(-2.2),
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		EmissionDirection = Enum.NormalId.Back,
		Lifetime = NumberRange.new(0.35, 0.55),
		Rate = 6 + forca * 22,
		Speed = NumberRange.new(20, 28),
		SpreadAngle = Vector2.new(4, 4),
		LightEmission = 1,
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})

	-- rolo de trás: faíscas pulando (ou poeira na esteira básica)
	local rolo = area(modelo, chao * CFrame.new(0, ALTURA_PISTA, 6.3), Vector3.new(4.6, 0.3, 0.3))
	if nivel == 1 then
		particulas(rolo, {
			Name = "Poeira",
			Texture = FUMACA,
			Color = ColorSequence.new(Color3.fromRGB(200, 195, 185)),
			Transparency = NumberSequence.new(0.55, 1),
			Size = NumberSequence.new(0.8, 2.2),
			EmissionDirection = Enum.NormalId.Back,
			Lifetime = NumberRange.new(0.6, 1),
			Rate = 6,
			Speed = NumberRange.new(2, 4),
			SpreadAngle = Vector2.new(30, 30),
			Acceleration = Vector3.new(0, 1.5, 0),
			Shape = Enum.ParticleEmitterShape.Box,
		})
	else
		particulas(rolo, {
			Name = "Faiscas",
			Texture = FAISCA,
			Color = ColorSequence.new(Color3.fromRGB(255, 250, 220), cor),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }),
			EmissionDirection = Enum.NormalId.Back,
			Lifetime = NumberRange.new(0.4, 0.8),
			Rate = 4 + forca * 26,
			Speed = NumberRange.new(8, 14),
			SpreadAngle = Vector2.new(35, 25),
			Acceleration = Vector3.new(0, -40, 0),
			Drag = 1,
			LightEmission = 1,
			Shape = Enum.ParticleEmitterShape.Box,
		})
	end

	-- pilares de brilho subindo dos dois lados
	if nivel >= 2 then
		for _, x in { -1, 1 } do
			local lateral = area(modelo, chao * CFrame.new(x * 3.6, 1.4, 0.4), Vector3.new(0.3, 0.3, 11))
			particulas(lateral, {
				Name = "Pilar",
				Texture = FAISCA,
				Color = ColorSequence.new(cor, Color3.new(1, 1, 1)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(0.8, 1.4),
				Rate = 3 + forca * 12,
				Speed = NumberRange.new(3, 6),
				SpreadAngle = Vector2.new(5, 5),
				LightEmission = 1,
				Shape = Enum.ParticleEmitterShape.Box,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			})
		end
	else
		halo(modelo, chao, Color3.fromRGB(255, 255, 255), 0.85)
		brilhosSubindo(modelo, chao, Color3.fromRGB(255, 255, 255), 2)
	end
end

-- Monta a esteira do nível pedido. "cf" fica 0.2 acima do chão, no centro
-- da esteira, olhando para a frente (onde fica o painel); a pista empurra o
-- jogador para trás.
function Esteiras.criar(nivel: number, cf: CFrame): Model
	local estilo = ESTILOS[math.clamp(nivel, 1, #ESTILOS)]
	local cor = estilo.neon or estilo.estrutura
	local chao = cf * CFrame.new(0, -0.2, 0) -- tudo é medido a partir do chão

	local modelo = Instance.new("Model")
	modelo.Name = "Esteira"

	local pista = Mapa.parte({
		Name = "Pista",
		Size = Vector3.new(5, 0.3, 12.4),
		CFrame = chao * CFrame.new(0, ALTURA_PISTA - 0.15, 0.3),
		Color = estilo.pista,
		Material = estilo.materialPista,
		Parent = modelo,
	})
	modelo.PrimaryPart = pista

	local function peca(lugar: CFrame, tamanho: Vector3, props: any?): BasePart
		return enfeite(modelo, chao * lugar, tamanho, estilo.estrutura, estilo.material, props)
	end
	local function preta(lugar: CFrame, tamanho: Vector3): BasePart
		return enfeite(modelo, chao * lugar, tamanho, PRETO, Enum.Material.SmoothPlastic)
	end
	local function brilho(lugar: CFrame, tamanho: Vector3)
		if estilo.neon then
			local luzNeon = enfeite(modelo, chao * lugar, tamanho, estilo.neon, Enum.Material.Neon, { CastShadow = false })
			-- o cliente faz as luzes pulsarem
			CollectionService:AddTag(luzNeon, "PulsarEsteira")
		end
	end
	local largura = if estilo.grosso then 0.45 else 0.16

	-- deck: corpo por baixo da pista, laterais, capô do motor e pés de trás
	preta(CFrame.new(0, 0.4, 0.3), Vector3.new(5, 0.75, 12.6))
	for _, x in { -1, 1 } do
		peca(CFrame.new(x * 3.05, 0.65, 0.3), Vector3.new(1.1, 1.3, 13))
		brilho(CFrame.new(x * 3.62, 0.65, 0.5), Vector3.new(0.1, largura, 11))
		brilho(CFrame.new(x * 2.55, 1.31, 0.5), Vector3.new(0.14, 0.05, 11.5))
		-- pé de trás, mais largo
		peca(CFrame.new(x * 3.15, 0.8, 6.55), Vector3.new(1.5, 1.6, 1.3))
		brilho(CFrame.new(x * 3.92, 0.8, 6.55), Vector3.new(0.1, 0.5, 0.8))
	end
	peca(CFrame.new(0, 0.9, -6.75), Vector3.new(7.2, 1.8, 1.9))
	brilho(CFrame.new(0, 1.5, -5.79), Vector3.new(5.2, largura * 0.6, 0.06))
	for _, x in { -1, 1 } do
		brilho(CFrame.new(x * 3.62, 0.9, -6.75), Vector3.new(0.1, 0.9, 1.2))
	end

	-- colunas inclinadas e corrimão
	for _, x in { -1, 1 } do
		local coluna = CFrame.new(x * 2.95, 4.5, -5.75) * CFrame.Angles(math.rad(10), 0, 0)
		peca(coluna, Vector3.new(0.9, 6.4, 1))
		brilho(coluna * CFrame.new(0, 0, 0.51), Vector3.new(largura * 0.8, 5.4, 0.05))
		if estilo.grosso then
			-- placas de armadura na frente das colunas
			brilho(coluna * CFrame.new(x * 0.46, -1.5, 0), Vector3.new(0.05, 2.5, 0.7))
		end
		peca(CFrame.new(x * 3.15, 7.35, -3.75), Vector3.new(0.75, 0.75, 3.6))
		preta(CFrame.new(x * 3.15, 7.35, -1.75), Vector3.new(0.8, 0.8, 0.5))
		brilho(CFrame.new(x * 3.15, 7.75, -3.75), Vector3.new(0.3, 0.05, 3.2))
	end
	peca(CFrame.new(0, 7.4, -5.2), Vector3.new(6.6, 0.7, 0.9))

	-- painel inclinado com a tela virada para quem corre
	local painel = chao * CFrame.new(0, 8.6, -5.3) * CFrame.Angles(math.rad(-25), 0, 0)
	enfeite(modelo, painel, Vector3.new(4.6, 2.6, 0.8), PRETO, Enum.Material.SmoothPlastic)
	if estilo.neon then
		enfeite(modelo, painel * CFrame.new(0, 1.32, 0), Vector3.new(4.7, 0.08, 0.85), estilo.neon, Enum.Material.Neon)
	end
	local tela = enfeite(
		modelo,
		painel * CFrame.new(0, 0.25, 0.42),
		Vector3.new(3.6, 1.6, 0.05),
		Color3.fromRGB(10, 10, 14),
		Enum.Material.SmoothPlastic,
		{ Name = "Tela" }
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.Parent = tela
	estilo.tela(gui, cor)
	for i = -1, 1 do
		enfeite(
			modelo,
			painel * CFrame.new(i * 0.9, -0.9, 0.42),
			Vector3.new(0.65, 0.3, 0.06),
			if estilo.neon then estilo.neon else Color3.fromRGB(220, 220, 225),
			if estilo.neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		)
	end
	if estilo.neon then
		luz(tela, estilo.neon, 10, 1)
		luz(pista, estilo.neon, 12, if estilo.grosso then 2 else 1)
	end

	-- faixas da pista (o cliente faz elas andarem)
	local quantidade = 6
	local curso = 12
	for i = 0, quantidade - 1 do
		local fase = i * curso / quantidade
		local faixa = enfeite(
			modelo,
			pista.CFrame * CFrame.new(0, 0.17, -curso / 2 + fase),
			Vector3.new(4.8, 0.04, 0.25),
			estilo.faixa,
			Enum.Material.SmoothPlastic,
			{ CastShadow = false, Name = "Faixa" }
		)
		faixa:SetAttribute("Fase", fase)
		faixa:SetAttribute("Curso", curso)
		faixa:SetAttribute("Velocidade", VELOCIDADE_FAIXAS)
		CollectionService:AddTag(faixa, "FaixaEsteira")
	end

	efeitosPista(modelo, chao, nivel, estilo.neon or Color3.fromRGB(235, 235, 240))
	if estilo.extra then
		estilo.extra(modelo, chao, cor)
	end
	return modelo
end

-- Explosão de brilhos na cor do nível, para quando alguém compra a melhoria.
function Esteiras.celebrar(modelo: Model, nivel: number)
	local estilo = ESTILOS[math.clamp(nivel, 1, #ESTILOS)]
	local cor = estilo.neon or Color3.new(1, 1, 1)
	local pista = modelo:FindFirstChild("Pista")
	if not pista then
		return
	end
	local anexo = Instance.new("Attachment")
	anexo.Position = Vector3.new(0, 2, 0)
	anexo.Parent = pista
	local explosao = particulas(anexo, {
		Texture = FAISCA,
		Color = ColorSequence.new(Color3.new(1, 1, 1), cor),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(1, 1.8),
		Rate = 0,
		Speed = NumberRange.new(12, 22),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -18, 0),
		Drag = 2,
		RotSpeed = NumberRange.new(-180, 180),
		LightEmission = 1,
	})
	explosao:Emit(120)
	task.delay(3, function()
		anexo:Destroy()
	end)
end

return Esteiras

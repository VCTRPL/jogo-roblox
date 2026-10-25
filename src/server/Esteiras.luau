-- Modelos 3D das esteiras de corrida: cada nível tem uma esteira diferente,
-- mais bonita conforme o preço. A peça "Pista" é onde o jogador corre: ela
-- empurra para trás, então ele corre parado.
-- O cliente anima as faixas da pista (tag "FaixaEsteira") e o que gira
-- (tag "GirarEsteira"), veja src/client/init.client.luau.
local CollectionService = game:GetService("CollectionService")

local Mapa = require(script.Parent.Mapa)

local Esteiras = {}

Esteiras.TAMANHO_PISTA = Vector3.new(6, 0.4, 12)
local EMPURRAO = 18 -- velocidade com que a pista empurra o jogador
local VELOCIDADE_FAIXAS = 12

local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local FOGO = "rbxasset://textures/particles/fire_main.dds"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"

type Estilo = {
	moldura: Color3,
	materialMoldura: Enum.Material,
	lateral: Color3,
	materialLateral: Enum.Material,
	pista: Color3,
	materialPista: Enum.Material,
	acento: Color3?, -- fita neon dos lados
	faixas: { Color3 },
	faixaNeon: boolean,
	tela: Color3,
	extra: ((modelo: Model, cf: CFrame) -> ())?,
}

-- Peça decorativa: não colide e não atrapalha cliques nem toques.
local function enfeite(modelo: Model, cf: CFrame, tamanho: Vector3, cor: Color3, material: Enum.Material, props: any?): Part
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

local function sequencia(cores: { Color3 }): ColorSequence
	local pontos = {}
	for i, cor in cores do
		table.insert(pontos, ColorSequenceKeypoint.new((i - 1) / math.max(1, #cores - 1), cor))
	end
	return ColorSequence.new(pontos)
end

local function girar(parte: BasePart, velocidade: number)
	parte:SetAttribute("Giro", velocidade)
	CollectionService:AddTag(parte, "GirarEsteira")
end

local ARCO_IRIS = {
	Color3.fromRGB(255, 70, 90),
	Color3.fromRGB(255, 160, 50),
	Color3.fromRGB(255, 235, 70),
	Color3.fromRGB(80, 230, 120),
	Color3.fromRGB(70, 170, 255),
	Color3.fromRGB(170, 90, 255),
}

local ESTILOS: { Estilo } = {
	-- 1: Madeira, simples
	{
		moldura = Color3.fromRGB(140, 95, 60),
		materialMoldura = Enum.Material.WoodPlanks,
		lateral = Color3.fromRGB(115, 75, 45),
		materialLateral = Enum.Material.Wood,
		pista = Color3.fromRGB(45, 45, 50),
		materialPista = Enum.Material.Fabric,
		acento = nil,
		faixas = { Color3.fromRGB(90, 90, 95) },
		faixaNeon = false,
		tela = Color3.fromRGB(120, 200, 120),
		extra = function(modelo, cf)
			-- toquinhos de madeira nos cantos de trás
			for _, x in { -3.4, 3.4 } do
				enfeite(modelo, cf * CFrame.new(x, 0.8, 6.3), Vector3.new(0.8, 1.6, 0.8), Color3.fromRGB(115, 75, 45), Enum.Material.Wood)
			end
		end,
	},
	-- 2: Esportiva, vermelha e branca de academia
	{
		moldura = Color3.fromRGB(240, 240, 245),
		materialMoldura = Enum.Material.SmoothPlastic,
		lateral = Color3.fromRGB(220, 40, 50),
		materialLateral = Enum.Material.SmoothPlastic,
		pista = Color3.fromRGB(25, 25, 30),
		materialPista = Enum.Material.Rubber,
		acento = Color3.fromRGB(255, 255, 255),
		faixas = { Color3.fromRGB(220, 40, 50), Color3.fromRGB(240, 240, 245) },
		faixaNeon = false,
		tela = Color3.fromRGB(255, 90, 90),
		extra = function(modelo, cf)
			-- garrafinha de água no painel
			local garrafa = enfeite(
				modelo,
				cf * CFrame.new(2.6, 4.75, -6.2) * CFrame.Angles(0, 0, math.rad(90)),
				Vector3.new(1, 0.5, 0.5),
				Color3.fromRGB(90, 180, 255),
				Enum.Material.Glass,
				{ Shape = Enum.PartType.Cylinder, Transparency = 0.3 }
			)
			garrafa.Name = "Garrafa"
			-- halteres no chão, atrás da esteira
			for _, x in { -1.5, 1.5 } do
				local cabo = cf * CFrame.new(x, 0.35, 7.8)
				enfeite(modelo, cabo, Vector3.new(1.4, 0.25, 0.25), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
				for _, ponta in { -0.7, 0.7 } do
					enfeite(
						modelo,
						cabo * CFrame.new(ponta, 0, 0),
						Vector3.new(0.35, 0.7, 0.7),
						Color3.fromRGB(220, 40, 50),
						Enum.Material.SmoothPlastic,
						{ Shape = Enum.PartType.Cylinder }
					)
				end
			end
			local anexo = Instance.new("Attachment")
			anexo.Position = Vector3.new(0, 1.2, 0)
			anexo.Parent = modelo:FindFirstChild("Pista")
			particulas(anexo, {
				Texture = FAISCA,
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 120, 120)),
				Size = NumberSequence.new(0.35, 0),
				Lifetime = NumberRange.new(0.6, 1),
				Rate = 4,
				Speed = NumberRange.new(1.5, 3),
				SpreadAngle = Vector2.new(60, 60),
				LightEmission = 0.6,
			})
		end,
	},
	-- 3: Sci-Fi, metal com neon ciano
	{
		moldura = Color3.fromRGB(150, 160, 175),
		materialMoldura = Enum.Material.DiamondPlate,
		lateral = Color3.fromRGB(55, 60, 75),
		materialLateral = Enum.Material.Metal,
		pista = Color3.fromRGB(20, 30, 40),
		materialPista = Enum.Material.SmoothPlastic,
		acento = Color3.fromRGB(0, 230, 255),
		faixas = { Color3.fromRGB(0, 230, 255) },
		faixaNeon = true,
		tela = Color3.fromRGB(0, 230, 255),
		extra = function(modelo, cf)
			local ciano = Color3.fromRGB(0, 230, 255)
			-- arco "scanner" no meio da pista
			for _, x in { -3.5, 3.5 } do
				enfeite(modelo, cf * CFrame.new(x, 3, 1.5), Vector3.new(0.4, 6, 0.4), Color3.fromRGB(55, 60, 75), Enum.Material.Metal)
				enfeite(modelo, cf * CFrame.new(x * 0.93, 3, 1.5), Vector3.new(0.15, 5.6, 0.5), ciano, Enum.Material.Neon)
			end
			local topo = enfeite(modelo, cf * CFrame.new(0, 6.1, 1.5), Vector3.new(7.4, 0.4, 0.6), Color3.fromRGB(55, 60, 75), Enum.Material.Metal)
			enfeite(modelo, cf * CFrame.new(0, 5.85, 1.5), Vector3.new(6.6, 0.12, 0.3), ciano, Enum.Material.Neon)
			luz(topo, ciano, 14, 1.5)
			-- faíscas saindo dos lados da pista
			for _, x in { -3.6, 3.6 } do
				local anexo = Instance.new("Attachment")
				anexo.Position = Vector3.new(x, 0.4, 0)
				anexo.Parent = modelo:FindFirstChild("Pista")
				particulas(anexo, {
					Texture = FAISCA,
					Color = ColorSequence.new(ciano, Color3.fromRGB(180, 255, 255)),
					Size = NumberSequence.new(0.3, 0),
					Lifetime = NumberRange.new(0.4, 0.8),
					Rate = 5,
					Speed = NumberRange.new(2, 4),
					SpreadAngle = Vector2.new(30, 30),
					EmissionDirection = if x < 0 then Enum.NormalId.Left else Enum.NormalId.Right,
					Acceleration = Vector3.new(0, -6, 0),
					LightEmission = 1,
				})
			end
		end,
	},
	-- 4: Lava, pedra escura com rachaduras de fogo
	{
		moldura = Color3.fromRGB(45, 38, 38),
		materialMoldura = Enum.Material.Basalt,
		lateral = Color3.fromRGB(70, 50, 45),
		materialLateral = Enum.Material.Basalt,
		pista = Color3.fromRGB(60, 30, 25),
		materialPista = Enum.Material.CrackedLava,
		acento = Color3.fromRGB(255, 110, 20),
		faixas = { Color3.fromRGB(255, 90, 20), Color3.fromRGB(255, 170, 40) },
		faixaNeon = true,
		tela = Color3.fromRGB(255, 120, 30),
		extra = function(modelo, cf)
			local laranja = Color3.fromRGB(255, 110, 20)
			-- vulcõezinhos nos cantos de trás: pedra em degraus com lava no topo
			for _, x in { -3.9, 3.9 } do
				local base = cf * CFrame.new(x, 0, 6.2) * CFrame.Angles(0, math.rad(x * 6), 0)
				for degrau = 0, 2 do
					local largura = 2.4 - degrau * 0.6
					enfeite(
						modelo,
						base * CFrame.new(0, 0.5 + degrau * 0.9, 0) * CFrame.Angles(0, math.rad(degrau * 30), 0),
						Vector3.new(largura, 1, largura),
						Color3.fromRGB(45 + degrau * 8, 38, 38),
						Enum.Material.Basalt
					)
				end
				enfeite(modelo, base * CFrame.new(0, 1.45, 0), Vector3.new(1.9, 0.12, 1.9), laranja, Enum.Material.Neon)
				local pedra = enfeite(
					modelo,
					base * CFrame.new(0, 2.85, 0),
					Vector3.new(1, 1, 1),
					Color3.fromRGB(255, 140, 30),
					Enum.Material.Neon,
					{ Shape = Enum.PartType.Ball }
				)
				pedra.Name = "Lava"
				local fogo = Instance.new("Fire")
				fogo.Size = 4
				fogo.Heat = 8
				fogo.Color = laranja
				fogo.SecondaryColor = Color3.fromRGB(255, 220, 80)
				fogo.Parent = pedra
			end
			-- brasas subindo da pista e fumaça atrás
			local pista = modelo:FindFirstChild("Pista")
			local brasas = Instance.new("Attachment")
			brasas.Position = Vector3.new(0, 0.3, 0)
			brasas.Parent = pista
			particulas(brasas, {
				Texture = FOGO,
				Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 60, 20)),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(1, 1.8),
				Rate = 8,
				Speed = NumberRange.new(1.5, 3),
				SpreadAngle = Vector2.new(20, 20),
				Shape = Enum.ParticleEmitterShape.Box,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
				LightEmission = 1,
			})
			local fumaca = Instance.new("Attachment")
			fumaca.Position = Vector3.new(0, 1, 6.5)
			fumaca.Parent = pista
			particulas(fumaca, {
				Texture = FUMACA,
				Color = ColorSequence.new(Color3.fromRGB(70, 60, 60)),
				Transparency = NumberSequence.new(0.6, 1),
				Size = NumberSequence.new(1.5, 4),
				Lifetime = NumberRange.new(2, 3),
				Rate = 3,
				Speed = NumberRange.new(1.5, 2.5),
				SpreadAngle = Vector2.new(15, 15),
			})
			luz(pista :: BasePart, laranja, 16, 2)
		end,
	},
	-- 5: Galáxia, roxa com estrelas e arco-íris
	{
		moldura = Color3.fromRGB(25, 15, 45),
		materialMoldura = Enum.Material.SmoothPlastic,
		lateral = Color3.fromRGB(80, 35, 150),
		materialLateral = Enum.Material.SmoothPlastic,
		pista = Color3.fromRGB(35, 15, 70),
		materialPista = Enum.Material.Glass,
		acento = Color3.fromRGB(255, 80, 220),
		faixas = ARCO_IRIS,
		faixaNeon = true,
		tela = Color3.fromRGB(200, 120, 255),
		extra = function(modelo, cf)
			-- arco-íris por cima da pista
			local segmentos = 12
			local function ponto(i: number): Vector3
				local angulo = math.pi * i / segmentos
				return (cf * CFrame.new(math.cos(angulo) * 4, 1 + math.sin(angulo) * 5.2, 3)).Position
			end
			for i = 0, segmentos - 1 do
				-- cada pedaço liga um ponto da curva ao próximo
				local de, ate = ponto(i), ponto(i + 1)
				enfeite(
					modelo,
					CFrame.lookAt((de + ate) / 2, ate),
					Vector3.new(0.5, 0.5, (ate - de).Magnitude + 0.3),
					ARCO_IRIS[i // 2 % #ARCO_IRIS + 1],
					Enum.Material.Neon
				)
			end
			-- cristal girando em cima do painel
			local cristal = enfeite(
				modelo,
				cf * CFrame.new(0, 7.2, -6.3) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
				Vector3.new(1.3, 1.3, 1.3),
				Color3.fromRGB(255, 120, 240),
				Enum.Material.Neon
			)
			cristal.Name = "Cristal"
			girar(cristal, 90)
			luz(cristal, Color3.fromRGB(220, 120, 255), 16, 2)
			-- estrelas em volta
			local estrelas = Instance.new("Attachment")
			estrelas.Position = Vector3.new(0, 3, 0)
			estrelas.Parent = modelo:FindFirstChild("Pista")
			particulas(estrelas, {
				Texture = FAISCA,
				Color = sequencia({ Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 120, 240), Color3.fromRGB(120, 200, 255) }),
				Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 0) }),
				Lifetime = NumberRange.new(1.5, 2.5),
				Rate = 10,
				Speed = NumberRange.new(0.5, 1.5),
				SpreadAngle = Vector2.new(180, 180),
				Shape = Enum.ParticleEmitterShape.Box,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
				LightEmission = 1,
				RotSpeed = NumberRange.new(-90, 90),
			})
			-- um pouco de brilho na própria pista
			local sparkles = Instance.new("Sparkles")
			sparkles.SparkleColor = Color3.fromRGB(200, 140, 255)
			sparkles.Parent = cristal
		end,
	},
}

-- Monta a esteira do nível pedido. "cf" é o centro da pista, olhando para
-- a frente (onde fica o painel); a pista empurra o jogador para trás.
function Esteiras.criar(nivel: number, cf: CFrame): Model
	local estilo = ESTILOS[math.clamp(nivel, 1, #ESTILOS)]
	local tamanho = Esteiras.TAMANHO_PISTA
	local meio = tamanho.Z / 2

	local modelo = Instance.new("Model")
	modelo.Name = "Esteira"

	local pista = Mapa.parte({
		Name = "Pista",
		Size = tamanho,
		CFrame = cf,
		Color = estilo.pista,
		Material = estilo.materialPista,
		Parent = modelo,
	})
	pista.AssemblyLinearVelocity = -cf.LookVector * EMPURRAO
	modelo.PrimaryPart = pista

	-- moldura por baixo e laterais
	enfeite(modelo, cf * CFrame.new(0, -0.15, 0.3), Vector3.new(7.4, 0.5, tamanho.Z + 1), estilo.moldura, estilo.materialMoldura)
	for _, lado in { -1, 1 } do
		local x = lado * (tamanho.X / 2 + 0.35)
		enfeite(modelo, cf * CFrame.new(x, 0.35, 0.3), Vector3.new(0.7, 0.5, tamanho.Z + 1), estilo.lateral, estilo.materialLateral)
		if estilo.acento then
			enfeite(
				modelo,
				cf * CFrame.new(lado * (tamanho.X / 2 + 0.75), 0.35, 0.3),
				Vector3.new(0.12, 0.18, tamanho.Z + 0.6),
				estilo.acento,
				Enum.Material.Neon
			)
		end
		-- poste do painel e corrimão
		enfeite(modelo, cf * CFrame.new(lado * 3.2, 2.2, -meio - 0.2), Vector3.new(0.5, 4.2, 0.5), estilo.lateral, estilo.materialLateral)
		enfeite(modelo, cf * CFrame.new(lado * 3.2, 3.4, -meio + 2.3), Vector3.new(0.3, 0.3, 5), estilo.moldura, estilo.materialMoldura)
	end

	-- painel com a telinha virada para quem corre
	enfeite(modelo, cf * CFrame.new(0, 4.1, -meio - 0.2), Vector3.new(6.9, 0.4, 0.4), estilo.lateral, estilo.materialLateral)
	local painel = enfeite(
		modelo,
		cf * CFrame.new(0, 4.9, -meio - 0.3) * CFrame.Angles(math.rad(-25), 0, 0),
		Vector3.new(3.6, 1.9, 0.4),
		estilo.lateral,
		estilo.materialLateral
	)
	local tela = enfeite(modelo, painel.CFrame * CFrame.new(0, 0, 0.21), Vector3.new(3.1, 1.5, 0.05), estilo.tela, Enum.Material.Neon)
	tela.Name = "Tela"
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = tela
	local texto = Instance.new("TextLabel")
	texto.Size = UDim2.fromScale(1, 1)
	texto.BackgroundTransparency = 1
	texto.TextScaled = true
	texto.Font = Enum.Font.FredokaOne
	texto.TextColor3 = Color3.fromRGB(20, 20, 30)
	texto.Text = `NÍVEL {nivel}`
	texto.Parent = gui

	-- faixas da pista (o cliente faz elas andarem)
	local quantidade = 6
	local espaco = tamanho.Z / quantidade
	for i = 0, quantidade - 1 do
		local fase = i * espaco
		local faixa = enfeite(
			modelo,
			cf * CFrame.new(0, tamanho.Y / 2 + 0.03, -meio + fase + 0.3),
			Vector3.new(tamanho.X - 0.4, 0.06, 0.5),
			estilo.faixas[i % #estilo.faixas + 1],
			if estilo.faixaNeon then Enum.Material.Neon else Enum.Material.SmoothPlastic,
			{ CastShadow = false }
		)
		faixa.Name = "Faixa"
		faixa:SetAttribute("Fase", fase)
		faixa:SetAttribute("Curso", tamanho.Z - 0.6)
		faixa:SetAttribute("Velocidade", VELOCIDADE_FAIXAS)
		CollectionService:AddTag(faixa, "FaixaEsteira")
	end

	if estilo.extra then
		estilo.extra(modelo, cf)
	end
	return modelo
end

return Esteiras

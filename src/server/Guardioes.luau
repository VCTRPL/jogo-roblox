-- Modelos dos guardiões dos biomas, montados com peças. Cada bioma diz
-- qual guardião tem em Config.BIOMAS (campo "guardiao").
-- O modelo é montado com os pés em (0, 0, 0) e olhando para -Z.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Biblioteca = require(script.Parent.Biblioteca)
local Blocos = require(script.Parent.Blocos)
local Mapa = require(script.Parent.Mapa)

local Guardioes = {}

-- Altura (em studs) dos chefões que vêm da biblioteca do Roblox.
local ALTURA_CHEFAO = {
	["Tung Tung Tung Sahur"] = 10,
	["Cappuccino Assassino"] = 9,
	["Il Cacto Hipopotamo"] = 11,
	["Rhino Toasterino"] = 10,
	["La Vaca Saturno Saturnita"] = 12,
}

export type Visual = {
	modelo: Model,
	olhos: { BasePart }, -- ficam vermelhos quando ele está bravo
	alerta: BillboardGui, -- o "!" em cima da cabeça
	rastro: ParticleEmitter, -- poeira enquanto corre
	luz: PointLight,
}

local PRETO = Color3.fromRGB(25, 20, 20)
local BRANCO = Color3.fromRGB(245, 245, 245)
local VERMELHO = Color3.fromRGB(255, 40, 40)

local function peca(modelo: Model, nome: string, tamanho: Vector3, cf: CFrame, cor: Color3, material: Enum.Material?): Part
	return Mapa.parte({
		Name = nome,
		Size = tamanho,
		CFrame = cf,
		Color = cor,
		Material = material or Enum.Material.SmoothPlastic,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = modelo,
	})
end

-- Cilindro em pé (o cilindro do Roblox deita no eixo X, então gira 90 graus).
local function cilindro(modelo: Model, nome: string, altura: number, diametro: number, cf: CFrame, cor: Color3, material: Enum.Material?): Part
	local p = peca(modelo, nome, Vector3.new(altura, diametro, diametro), cf * CFrame.Angles(0, 0, math.rad(90)), cor, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- Cilindro ligando dois pontos (braços, pernas, taco).
local function barra(modelo: Model, nome: string, de: Vector3, ate: Vector3, diametro: number, cor: Color3, material: Enum.Material?): Part
	local meio = (de + ate) / 2
	-- o eixo do cilindro (X) passa a apontar de "de" para "ate"
	local cf = CFrame.lookAt(meio, ate) * CFrame.Angles(0, math.rad(90), 0)
	local p = peca(modelo, nome, Vector3.new((ate - de).Magnitude, diametro, diametro), cf, cor, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function bola(modelo: Model, nome: string, diametro: number, cf: CFrame, cor: Color3, material: Enum.Material?): Part
	local p = peca(modelo, nome, Vector3.one * diametro, cf, cor, material)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Olhos grandes de desenho: branco com pupila. Devolve as pupilas.
local function olhos(modelo: Model, altura: number, frente: number, distancia: number, tamanho: number): { BasePart }
	local pupilas: { BasePart } = {}
	for _, x in { -distancia, distancia } do
		bola(modelo, "Olho", tamanho, CFrame.new(x, altura, frente), BRANCO)
		table.insert(pupilas, bola(modelo, "Pupila", tamanho * 0.45, CFrame.new(x, altura, frente - tamanho * 0.42), PRETO))
	end
	return pupilas
end

-- Tronco de madeira com olhos arregalados e um taco: Tung Tung Tung Sahur.
local function sahur(modelo: Model): ({ BasePart }, number)
	local MADEIRA = Color3.fromRGB(165, 112, 66)
	local CLARA = Color3.fromRGB(222, 180, 125)

	for _, x in { -0.9, 0.9 } do
		cilindro(modelo, "Perna", 2.8, 0.9, CFrame.new(x, 1.4, 0), MADEIRA, Enum.Material.Wood)
		peca(modelo, "Pe", Vector3.new(1.3, 0.5, 1.8), CFrame.new(x, 0.25, -0.3), MADEIRA, Enum.Material.Wood)
	end
	local tronco = cilindro(modelo, "Corpo", 9, 4.4, CFrame.new(0, 7.3, 0), MADEIRA, Enum.Material.Wood)
	cilindro(modelo, "Topo", 0.25, 4, CFrame.new(0, 11.85, 0), CLARA, Enum.Material.Wood)
	cilindro(modelo, "Anel", 0.3, 4.6, CFrame.new(0, 4.4, 0), Color3.fromRGB(130, 85, 50), Enum.Material.Wood)

	local pupilas = olhos(modelo, 9.4, -1.95, 0.95, 1.6)
	-- sobrancelhas bravas e a boca aberta
	for _, x in { -1, 1 } do
		peca(modelo, "Sobrancelha", Vector3.new(1.5, 0.35, 0.4), CFrame.new(x * 0.95, 10.5, -2.1) * CFrame.Angles(0, 0, math.rad(x * -18)), PRETO)
	end
	peca(modelo, "Boca", Vector3.new(1.8, 0.9, 0.4), CFrame.new(0, 7.4, -2.05), Color3.fromRGB(70, 20, 20))
	peca(modelo, "Lingua", Vector3.new(1, 0.35, 0.42), CFrame.new(0, 7.1, -2.06), Color3.fromRGB(230, 90, 110))

	-- braços finos: o esquerdo solto e o direito levantando o taco
	barra(modelo, "Braco", Vector3.new(-2, 8.8, -0.3), Vector3.new(-3.1, 6.2, -0.7), 0.7, MADEIRA, Enum.Material.Wood)
	local mao = Vector3.new(3.5, 10.8, -0.9)
	barra(modelo, "Braco", Vector3.new(2, 8.8, -0.4), mao, 0.7, MADEIRA, Enum.Material.Wood)
	local direcao = Vector3.new(0.35, 0.87, 0.35).Unit
	barra(modelo, "Cabo", mao - direcao * 0.4, mao + direcao * 2.6, 0.6, CLARA, Enum.Material.Wood)
	barra(modelo, "Taco", mao + direcao * 2.4, mao + direcao * 6.8, 1.3, CLARA, Enum.Material.Wood)

	return pupilas, tronco.Position.Y
end

-- Xícara de café ninja com duas espadas: Cappuccino Assassino.
local function cappuccino(modelo: Model): ({ BasePart }, number)
	local CAFE = Color3.fromRGB(110, 65, 35)
	local ESPUMA = Color3.fromRGB(230, 200, 160)

	for _, x in { -0.8, 0.8 } do
		cilindro(modelo, "Perna", 2.6, 0.7, CFrame.new(x, 1.3, 0), PRETO)
		peca(modelo, "Pe", Vector3.new(1.1, 0.4, 1.6), CFrame.new(x, 0.2, -0.3), PRETO)
	end
	cilindro(modelo, "Pires", 0.4, 6.4, CFrame.new(0, 2.8, 0), BRANCO)
	local xicara = cilindro(modelo, "Corpo", 5.4, 4.6, CFrame.new(0, 5.7, 0), BRANCO)
	cilindro(modelo, "Cafe", 0.3, 4.2, CFrame.new(0, 8.45, 0), CAFE)
	bola(modelo, "Espuma", 1.6, CFrame.new(0.4, 8.6, 0.2), ESPUMA)
	-- alça da xícara
	peca(modelo, "Alca", Vector3.new(0.6, 2.4, 0.7), CFrame.new(3.2, 5.9, 0), BRANCO)
	peca(modelo, "Alca", Vector3.new(1, 0.6, 0.7), CFrame.new(2.8, 7.1, 0), BRANCO)
	peca(modelo, "Alca", Vector3.new(1, 0.6, 0.7), CFrame.new(2.8, 4.7, 0), BRANCO)

	-- máscara ninja: faixa preta com os olhos e as pontas da faixa nas costas
	cilindro(modelo, "Mascara", 1.5, 4.75, CFrame.new(0, 6.6, 0), PRETO)
	local pupilas: { BasePart } = {}
	for _, x in { -1, 1 } do
		table.insert(pupilas, peca(modelo, "Olho", Vector3.new(1.1, 0.45, 0.3), CFrame.new(x * 0.9, 6.6, -2.35) * CFrame.Angles(0, 0, math.rad(x * -15)), BRANCO))
		peca(modelo, "Faixa", Vector3.new(0.5, 2.4, 0.2), CFrame.new(x * 0.5, 5.8, 2.5) * CFrame.Angles(math.rad(20), 0, math.rad(x * 15)), PRETO)
	end

	-- braços e duas espadas cruzadas na frente da xícara
	for _, x in { -1, 1 } do
		local mao = Vector3.new(x * 3.3, 4.4, -1.6)
		barra(modelo, "Braco", Vector3.new(x * 2.1, 6, -0.2), mao, 0.6, PRETO)
		local direcao = Vector3.new(-x * 0.75, 0.75, -0.45).Unit
		barra(modelo, "Cabo", mao - direcao * 0.5, mao + direcao * 0.7, 0.4, Color3.fromRGB(150, 30, 30))
		local inicio, fim = mao + direcao * 0.7, mao + direcao * 5.7
		peca(
			modelo,
			"Lamina",
			Vector3.new(0.15, 0.55, (fim - inicio).Magnitude),
			CFrame.lookAt((inicio + fim) / 2, fim),
			Color3.fromRGB(210, 230, 255),
			Enum.Material.Metal
		)
	end

	return pupilas, xicara.Position.Y
end

-- Cacto alto de braços para cima com cabeça de hipopótamo: Il Cacto Hipopotamo.
local function cacto(modelo: Model): ({ BasePart }, number)
	local VERDE = Color3.fromRGB(80, 160, 75)
	local ESCURO = Color3.fromRGB(55, 120, 55)
	local HIPO = Color3.fromRGB(150, 130, 160)

	for _, x in { -1, 1 } do
		peca(modelo, "Perna", Vector3.new(1.2, 2.6, 1.2), CFrame.new(x, 1.3, 0), ESCURO)
		peca(modelo, "Pe", Vector3.new(1.6, 0.6, 2), CFrame.new(x, 0.3, -0.3), Color3.fromRGB(190, 130, 70))
	end
	local corpo = peca(modelo, "Corpo", Vector3.new(4, 6, 3.6), CFrame.new(0, 5.6, 0), VERDE)
	-- gomos do cacto e espinhos
	for _, x in { -1.2, 0, 1.2 } do
		peca(modelo, "Gomo", Vector3.new(0.4, 5.8, 3.7), CFrame.new(x, 5.6, 0), ESCURO)
	end
	for i = 1, 10 do
		local y = 3.2 + (i % 5) * 1.1
		local x = if i <= 5 then -2.1 else 2.1
		peca(modelo, "Espinho", Vector3.new(0.6, 0.15, 0.15), CFrame.new(x, y, -0.8), Color3.fromRGB(250, 245, 220))
	end
	-- braços de cacto dobrados para cima
	for _, x in { -1, 1 } do
		peca(modelo, "Braco", Vector3.new(2, 1.2, 1.2), CFrame.new(x * 3, 5.4, 0), VERDE)
		peca(modelo, "Braco", Vector3.new(1.2, 2.6, 1.2), CFrame.new(x * 3.6, 6.8, 0), VERDE)
	end
	-- cabeça de hipopótamo com focinho largo, narinas e dentões
	peca(modelo, "Cabeca", Vector3.new(4.2, 3, 3.4), CFrame.new(0, 10.1, 0), HIPO)
	peca(modelo, "Focinho", Vector3.new(4.6, 2, 2), CFrame.new(0, 9.4, -2.4), HIPO:Lerp(Color3.new(1, 1, 1), 0.15))
	for _, x in { -0.8, 0.8 } do
		peca(modelo, "Narina", Vector3.new(0.5, 0.3, 0.2), CFrame.new(x, 10.2, -3.4), PRETO)
		peca(modelo, "Dente", Vector3.new(0.5, 0.7, 0.3), CFrame.new(x * 1.6, 8.3, -3.3), BRANCO)
		peca(modelo, "Orelha", Vector3.new(0.7, 0.7, 0.4), CFrame.new(x * 2, 11.8, 0.6), HIPO)
	end
	local pupilas = olhos(modelo, 11, -1.6, 1.1, 1.1)
	-- flor rosa no topo do cacto
	peca(modelo, "Flor", Vector3.new(1.4, 0.6, 1.4), CFrame.new(0.8, 11.9, 0.6), Color3.fromRGB(255, 110, 170))
	return pupilas, corpo.Position.Y
end

-- Torradeira prateada com cabeça de rinoceronte e duas torradas: Rhino Toasterino.
local function toasterino(modelo: Model): ({ BasePart }, number)
	local PRATA = Color3.fromRGB(190, 195, 205)
	local RINO = Color3.fromRGB(140, 140, 150)
	local PAO = Color3.fromRGB(215, 160, 90)

	for _, x in { -1.4, 1.4 } do
		peca(modelo, "Perna", Vector3.new(1.4, 2.4, 1.4), CFrame.new(x, 1.2, 0.8), RINO)
		peca(modelo, "Perna", Vector3.new(1.4, 2.4, 1.4), CFrame.new(x, 1.2, -1.6), RINO)
	end
	local corpo = peca(modelo, "Corpo", Vector3.new(5, 4.6, 6), CFrame.new(0, 4.7, 0), PRATA, Enum.Material.Metal)
	-- duas torradas saindo em cima e a alavanca do lado
	for _, z in { -1, 1 } do
		peca(modelo, "Torrada", Vector3.new(3.4, 2.4, 0.6), CFrame.new(0, 7.6, z), PAO)
		peca(modelo, "Casca", Vector3.new(3.6, 0.4, 0.7), CFrame.new(0, 8.8, z), Color3.fromRGB(150, 95, 45))
	end
	peca(modelo, "Alavanca", Vector3.new(0.4, 0.5, 1.2), CFrame.new(2.7, 5.6, 0), PRETO)
	peca(modelo, "Fenda", Vector3.new(0.1, 3, 4.6), CFrame.new(-2.52, 4.7, 0), Color3.fromRGB(255, 120, 40), Enum.Material.Neon)
	-- cabeça de rinoceronte na frente, com dois chifres
	peca(modelo, "Cabeca", Vector3.new(3.4, 3, 3), CFrame.new(0, 5.4, -4.2), RINO)
	peca(modelo, "Focinho", Vector3.new(2.6, 2, 1.6), CFrame.new(0, 4.8, -6.2), RINO)
	peca(modelo, "Chifre", Vector3.new(0.9, 2.2, 0.9), CFrame.new(0, 6.6, -6.4) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(235, 225, 200))
	peca(modelo, "Chifre", Vector3.new(0.6, 1.2, 0.6), CFrame.new(0, 6.4, -5.2), Color3.fromRGB(235, 225, 200))
	for _, x in { -1.3, 1.3 } do
		peca(modelo, "Orelha", Vector3.new(0.6, 0.9, 0.4), CFrame.new(x, 7.2, -3.4), RINO)
	end
	local pupilas = olhos(modelo, 6.1, -5.75, 1, 0.9)
	return pupilas, corpo.Position.Y
end

-- Planeta Saturno com cara de vaca, anel em volta e pernas de gente:
-- La Vaca Saturno Saturnita.
local function saturnita(modelo: Model): ({ BasePart }, number)
	local PLANETA = Color3.fromRGB(230, 185, 110)
	local FAIXA = Color3.fromRGB(200, 140, 80)
	local VACA = Color3.fromRGB(245, 245, 245)

	for _, x in { -1, 1 } do
		peca(modelo, "Perna", Vector3.new(1, 3.4, 1), CFrame.new(x * 1.2, 1.7, 0), VACA)
		peca(modelo, "Pe", Vector3.new(1.4, 0.7, 1.8), CFrame.new(x * 1.2, 0.35, -0.3), PRETO)
	end
	-- o planeta em camadas (largo no meio), com faixas
	local corpo = peca(modelo, "Corpo", Vector3.new(7, 4, 7), CFrame.new(0, 7.4, 0), PLANETA)
	peca(modelo, "Camada", Vector3.new(5.6, 1.4, 5.6), CFrame.new(0, 10.1, 0), FAIXA)
	peca(modelo, "Camada", Vector3.new(5.6, 1.4, 5.6), CFrame.new(0, 4.7, 0), FAIXA)
	peca(modelo, "Camada", Vector3.new(3.6, 1, 3.6), CFrame.new(0, 11.3, 0), PLANETA)
	-- anel inclinado em volta
	for i = 0, 15 do
		local giro = CFrame.Angles(0, math.rad(i * 22.5), 0)
		peca(
			modelo,
			"Anel",
			Vector3.new(2.2, 0.3, 0.8),
			CFrame.new(0, 7.6, 0) * CFrame.Angles(0, 0, math.rad(12)) * giro * CFrame.new(0, 0, -5.4),
			Color3.fromRGB(180, 220, 255),
			Enum.Material.Neon
		)
	end
	-- cara de vaca na frente: manchas, focinho rosa e chifres
	peca(modelo, "Cara", Vector3.new(4.2, 3.4, 0.4), CFrame.new(0, 8, -3.6), VACA)
	peca(modelo, "Mancha", Vector3.new(1.4, 1.2, 0.1), CFrame.new(-1.2, 9, -3.85), PRETO)
	peca(modelo, "Focinho", Vector3.new(2.4, 1.2, 0.6), CFrame.new(0, 6.8, -3.9), Color3.fromRGB(255, 160, 180))
	for _, x in { -1, 1 } do
		peca(modelo, "Narina", Vector3.new(0.35, 0.35, 0.1), CFrame.new(x * 0.5, 6.8, -4.25), PRETO)
		peca(modelo, "Chifre", Vector3.new(0.5, 1.6, 0.5), CFrame.new(x * 2.6, 10.4, -2.2) * CFrame.Angles(0, 0, math.rad(-x * 30)), Color3.fromRGB(240, 230, 200))
		peca(modelo, "Braco", Vector3.new(0.9, 3, 0.9), CFrame.new(x * 4.1, 6.6, 0) * CFrame.Angles(0, 0, math.rad(x * 25)), VACA)
	end
	local pupilas = olhos(modelo, 8.8, -3.9, 0.95, 1)
	return pupilas, corpo.Position.Y
end

-- Bloco com olhos, para um guardião sem modelo próprio.
local function padrao(modelo: Model): ({ BasePart }, number)
	local corpo = peca(modelo, "Corpo", Vector3.new(7, 8, 7), CFrame.new(0, 4, 0), Color3.fromRGB(60, 30, 30), Enum.Material.Slate)
	return olhos(modelo, 5.8, -3.5, 1.6, 1.4), corpo.Position.Y
end

local MONTAR = {
	["Tung Tung Tung Sahur"] = sahur,
	["Cappuccino Assassino"] = cappuccino,
	["Il Cacto Hipopotamo"] = cacto,
	["Rhino Toasterino"] = toasterino,
	["La Vaca Saturno Saturnita"] = saturnita,
}

-- Chefão da biblioteca: um Model com o nome do guardião dentro de
-- ReplicatedStorage.ModelosChefao (veja o README). Fica do tamanho certo,
-- de pé na origem, olhando para -Z, com uma peça invisível "Corpo" no meio.
local function daBiblioteca(nome: string?): (Model?, number)
	local pasta = ReplicatedStorage:FindFirstChild("ModelosChefao")
	local molde = nome and pasta and pasta:FindFirstChild(nome)
	if not (molde and molde:IsA("Model")) then
		return nil, 0
	end
	local modelo = Biblioteca.preparar(molde, ALTURA_CHEFAO[nome :: string] or 10)
	if not modelo then
		return nil, 0
	end
	modelo.Name = "Guardiao"
	local caixa, tamanho = modelo:GetBoundingBox()
	local corpo = peca(modelo, "CorpoChefao", Vector3.new(1, 1, 1), CFrame.new(caixa.Position), BRANCO)
	corpo.Transparency = 1
	modelo.PrimaryPart = corpo
	corpo.PivotOffset = corpo.CFrame:Inverse() -- pivot nos pés
	return modelo, tamanho.Y / 2
end

local function montar(nome: string?): (Model, { BasePart }, number)
	local biblioteca, meio = daBiblioteca(nome)
	if biblioteca then
		return biblioteca, {}, meio
	end

	local modelo = Instance.new("Model")
	modelo.Name = "Guardiao"
	local montador = MONTAR[nome or ""] or padrao
	local pupilas, alturaCorpo = montador(modelo)
	-- estilo Lego antes de pôr o pivot (o corpo cilíndrico vira bloco)
	Blocos.aplicar(modelo)
	local corpo = modelo:FindFirstChild("Corpo") :: BasePart
	modelo.PrimaryPart = corpo
	-- pivot nos pés (a origem). Com PrimaryPart o Roblox usa o pivot da peça
	-- e ignora o WorldPivot, por isso o ajuste vai no PivotOffset.
	corpo.PivotOffset = corpo.CFrame:Inverse()
	return modelo, pupilas, alturaCorpo
end

-- Só as peças, sem placa nem efeitos: para estátuas na decoração.
function Guardioes.estatua(nome: string): Model
	return (montar(nome))
end

function Guardioes.criar(config): Visual
	local modelo, pupilas, alturaCorpo = montar(config.guardiao)
	local corpo = modelo.PrimaryPart :: BasePart
	local _, tamanho = modelo:GetBoundingBox()
	-- As placas vão numa peça invisível sem rotação: o corpo é um cilindro
	-- girado, e o deslocamento da placa gira junto com a peça.
	local marcador = peca(modelo, "Marcador", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, alturaCorpo, 0), BRANCO)
	marcador.Transparency = 1
	Mapa.placa(marcador, config.guardiao or "Guardião", tamanho.Y - alturaCorpo + 2, 260)

	local alerta = Instance.new("BillboardGui")
	alerta.Name = "Alerta"
	alerta.Size = UDim2.fromOffset(90, 90)
	alerta.StudsOffsetWorldSpace = Vector3.new(0, tamanho.Y - alturaCorpo + 5.5, 0)
	-- sem AlwaysOnTop: com ele ligado o "!" não aparecia
	alerta.MaxDistance = 200
	alerta.Enabled = false
	alerta.Parent = marcador
	local exclamacao = Instance.new("TextLabel")
	exclamacao.Size = UDim2.fromScale(1, 1)
	exclamacao.BackgroundTransparency = 1
	exclamacao.Font = Enum.Font.FredokaOne
	exclamacao.Text = "!"
	exclamacao.TextScaled = true
	exclamacao.TextColor3 = VERMELHO
	exclamacao.TextStrokeColor3 = Color3.new(1, 1, 1)
	exclamacao.TextStrokeTransparency = 0
	exclamacao.Parent = alerta

	local pes = Instance.new("Attachment")
	pes.Name = "Pes"
	pes.Parent = marcador
	-- o marcador não gira, então a poeira sai para cima
	pes.WorldCFrame = CFrame.new(0, 0.5, 0)
	local rastro = Instance.new("ParticleEmitter")
	rastro.Name = "Poeira"
	rastro.Texture = "rbxasset://textures/particles/smoke_main.dds"
	rastro.Color = ColorSequence.new(Color3.fromRGB(210, 190, 160))
	rastro.Transparency = NumberSequence.new(0.4, 1)
	rastro.Size = NumberSequence.new(1.5, 4)
	rastro.Lifetime = NumberRange.new(0.6, 1)
	rastro.Speed = NumberRange.new(2, 4)
	rastro.SpreadAngle = Vector2.new(60, 60)
	rastro.Rate = 30
	rastro.Enabled = false
	rastro.Parent = pes

	local luz = Instance.new("PointLight")
	luz.Color = VERMELHO
	luz.Range = 16
	luz.Brightness = 3
	luz.Enabled = false
	luz.Parent = corpo

	return { modelo = modelo, olhos = pupilas, alerta = alerta, rastro = rastro, luz = luz }
end

-- Liga ou desliga o modo bravo: "!" na cabeça, olhos vermelhos e luz.
function Guardioes.bravo(visual: Visual, bravo: boolean)
	visual.alerta.Enabled = bravo
	visual.luz.Enabled = bravo
	visual.rastro.Enabled = bravo
	for _, olho in visual.olhos do
		if olho:GetAttribute("CorNormal") == nil then
			olho:SetAttribute("CorNormal", olho.Color)
		end
		olho.Color = if bravo then VERMELHO else olho:GetAttribute("CorNormal")
		olho.Material = if bravo then Enum.Material.Neon else Enum.Material.Plastic
	end
end

return Guardioes

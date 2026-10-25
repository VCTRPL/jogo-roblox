-- Modelos dos guardiões dos biomas, montados com peças. Cada bioma diz
-- qual guardião tem em Config.BIOMAS (campo "guardiao").
-- O modelo é montado com os pés em (0, 0, 0) e olhando para -Z.
local Mapa = require(script.Parent.Mapa)

local Guardioes = {}

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

-- Bloco com olhos, para um guardião sem modelo próprio.
local function padrao(modelo: Model): ({ BasePart }, number)
	local corpo = peca(modelo, "Corpo", Vector3.new(7, 8, 7), CFrame.new(0, 4, 0), Color3.fromRGB(60, 30, 30), Enum.Material.Slate)
	return olhos(modelo, 5.8, -3.5, 1.6, 1.4), corpo.Position.Y
end

local MONTAR = {
	["Tung Tung Tung Sahur"] = sahur,
	["Cappuccino Assassino"] = cappuccino,
}

local function montar(nome: string?): (Model, { BasePart }, number)
	local modelo = Instance.new("Model")
	modelo.Name = "Guardiao"
	local montador = MONTAR[nome or ""] or padrao
	local pupilas, alturaCorpo = montador(modelo)
	modelo.PrimaryPart = modelo:FindFirstChild("Corpo") :: BasePart
	modelo.WorldPivot = CFrame.new() -- pivot nos pés
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
	Mapa.placa(corpo, config.guardiao or "Guardião", tamanho.Y - alturaCorpo + 2, 260)

	local alerta = Instance.new("BillboardGui")
	alerta.Name = "Alerta"
	alerta.Size = UDim2.fromOffset(90, 90)
	alerta.StudsOffsetWorldSpace = Vector3.new(0, tamanho.Y - alturaCorpo + 5.5, 0)
	alerta.AlwaysOnTop = true
	alerta.MaxDistance = 200
	alerta.Enabled = false
	alerta.Parent = corpo
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
	pes.Parent = corpo
	-- sem girar junto com o corpo (que é um cilindro deitado), para a poeira subir
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
		olho.Material = if bravo then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

return Guardioes

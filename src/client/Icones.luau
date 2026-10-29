-- Ícones desenhados com formas (sem imagem), no estilo dos ícones do
-- ForgeGUI: formas gordinhas com gradiente, contorno escuro grosso e um
-- brilho de plástico em cima. Servem para quem não tem imagem em
-- Ui.IMAGENS (Ranking, Renascer, Loja, Som, Melhorar esteira, Trancar base).
-- Tudo é medido de 0 a 1 dentro de um quadrado.
local Ui = require(script.Parent.Ui)

local criar = Ui.criar
local CONTORNO = Ui.CONTORNO
local BRANCO = Ui.BRANCO

local Icones = {}

local OURO = { Color3.fromRGB(255, 236, 120), Color3.fromRGB(235, 140, 20) }
local BRANCO_GELO = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 210, 230) }
local AZUL = { Color3.fromRGB(160, 230, 255), Color3.fromRGB(40, 140, 255) }
local VERDE = { Color3.fromRGB(150, 255, 140), Color3.fromRGB(30, 170, 70) }
local VERMELHO = { Color3.fromRGB(255, 130, 130), Color3.fromRGB(210, 30, 50) }
local ESCURO = { Color3.fromRGB(95, 90, 110), Color3.fromRGB(45, 40, 60) }
local PRATA = { Color3.fromRGB(240, 242, 250), Color3.fromRGB(150, 155, 175) }

type Ctx = { quadro: Frame, traco: number, z: number }

local function grad(cores: { Color3 }): UIGradient
	return criar("UIGradient", { Color = ColorSequence.new(cores[1], cores[2]), Rotation = 90 })
end

-- Forma cheia com gradiente e contorno. "raio" de 0 (quadrado) a 0.5 (redondo).
local function forma(ctx: Ctx, x: number, y: number, w: number, h: number, cores: { Color3 }, raio: number?, rotacao: number?): Frame
	return criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(x + w / 2, y + h / 2),
		Size = UDim2.fromScale(w, h),
		Rotation = rotacao or 0,
		BackgroundColor3 = BRANCO,
		BorderSizePixel = 0,
		ZIndex = ctx.z,
		Parent = ctx.quadro,
	}, {
		criar("UICorner", { CornerRadius = UDim.new(raio or 0.2, 0) }),
		criar("UIStroke", { Color = CONTORNO, Thickness = ctx.traco, LineJoinMode = Enum.LineJoinMode.Round }),
		grad(cores),
	})
end

-- Brilho de plástico: oval branco meio transparente.
local function brilho(ctx: Ctx, x: number, y: number, w: number, h: number)
	criar("Frame", {
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(w, h),
		BackgroundColor3 = BRANCO,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = ctx.z + 1,
		Parent = ctx.quadro,
	}, { criar("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
end

-- Anel (só a borda de um círculo), com contorno escuro por fora e por dentro.
-- "corte" (opcional) mostra só um pedaço: { x, y, w, h } da área visível.
local function anel(ctx: Ctx, cx: number, cy: number, diametro: number, grossura: number, cor: Color3, corte: { number }?)
	local pai: Instance = ctx.quadro
	local ox, oy, escalaX, escalaY = 0, 0, 1, 1
	if corte then
		pai = criar("Frame", {
			Position = UDim2.fromScale(corte[1], corte[2]),
			Size = UDim2.fromScale(corte[3], corte[4]),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = ctx.z,
			Parent = ctx.quadro,
		})
		ox, oy, escalaX, escalaY = corte[1], corte[2], corte[3], corte[4]
	end
	local function circulo(espessura: number, corTraco: Color3)
		criar("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale((cx - ox) / escalaX, (cy - oy) / escalaY),
			Size = UDim2.fromScale(diametro / escalaX, diametro / escalaY),
			BackgroundTransparency = 1,
			ZIndex = ctx.z,
			Parent = pai,
		}, {
			criar("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
			criar("UIStroke", { Color = corTraco, Thickness = espessura }),
		})
	end
	local px = grossura * ctx.traco * 20 -- "traco" é 1/20 do tamanho do ícone
	circulo(px + ctx.traco * 2, CONTORNO)
	circulo(px, cor)
end

-- Triângulo com centro em (cx, cy), "largura" na base, apontando para
-- "direcao" ("cima", "baixo", "esquerda" ou "direita"): um quadrado girado
-- 45 graus, do qual só aparece a metade de dentro de uma caixa que recorta.
-- (O Roblox não recorta dentro de quadro girado, por isso nada gira aqui.)
local LADOS = {
	cima = { Vector2.new(0.5, 1), false },
	baixo = { Vector2.new(0.5, 0), false },
	direita = { Vector2.new(0, 0.5), true },
	esquerda = { Vector2.new(1, 0.5), true },
}
local function triangulo(ctx: Ctx, cx: number, cy: number, largura: number, cores: { Color3 }, direcao: string)
	local lado = LADOS[direcao]
	local deitado = lado[2]
	local altura = largura / 2
	local caixa = criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(cx, cy),
		Size = if deitado then UDim2.fromScale(altura, largura) else UDim2.fromScale(largura, altura),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = ctx.z,
		Parent = ctx.quadro,
	})
	local relativo = 1 / math.sqrt(2) -- lado do quadrado em relação à base
	criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(lado[1].X, lado[1].Y),
		Size = UDim2.fromScale(relativo, relativo),
		SizeConstraint = if deitado then Enum.SizeConstraint.RelativeYY else Enum.SizeConstraint.RelativeXX,
		Rotation = 45,
		BackgroundColor3 = BRANCO,
		BorderSizePixel = 0,
		ZIndex = ctx.z,
		Parent = caixa,
	}, {
		criar("UICorner", { CornerRadius = UDim.new(0.12, 0) }),
		criar("UIStroke", { Color = CONTORNO, Thickness = ctx.traco }),
		criar("UIGradient", { Color = ColorSequence.new(cores[1], cores[2]), Rotation = 45 }),
	})
end

local DESENHOS: { [string]: (ctx: Ctx) -> () } = {
	-- troféu dourado com alças, haste e pedestal
	Ranking = function(ctx)
		for _, cx in { 0.2, 0.8 } do
			anel(ctx, cx, 0.3, 0.3, 0.09, OURO[2])
		end
		forma(ctx, 0.2, 0.08, 0.6, 0.44, OURO, 0.3)
		forma(ctx, 0.42, 0.5, 0.16, 0.16, OURO, 0.1)
		forma(ctx, 0.28, 0.64, 0.44, 0.1, OURO, 0.25)
		forma(ctx, 0.2, 0.74, 0.6, 0.16, ESCURO, 0.2)
		forma(ctx, 0.38, 0.775, 0.24, 0.09, OURO, 0.3)
		brilho(ctx, 0.28, 0.13, 0.12, 0.22)
	end,

	-- seta em círculo (renascer)
	Renascer = function(ctx)
		anel(ctx, 0.5, 0.52, 0.6, 0.12, Color3.fromRGB(255, 255, 255))
		-- duas pontas correndo uma atrás da outra: em cima para a direita,
		-- embaixo para a esquerda
		triangulo(ctx, 0.6, 0.22, 0.34, BRANCO_GELO, "direita")
		triangulo(ctx, 0.4, 0.82, 0.34, BRANCO_GELO, "esquerda")
	end,

	-- carrinho de compras
	Loja = function(ctx)
		forma(ctx, 0.06, 0.14, 0.2, 0.09, ESCURO, 0.5, 15)
		forma(ctx, 0.22, 0.24, 0.66, 0.4, BRANCO_GELO, 0.18)
		for _, x in { 0.42, 0.62 } do
			criar("Frame", {
				Position = UDim2.fromScale(x, 0.29),
				Size = UDim2.fromScale(0.05, 0.3),
				BackgroundColor3 = Color3.fromRGB(150, 160, 185),
				BorderSizePixel = 0,
				ZIndex = ctx.z + 1,
				Parent = ctx.quadro,
			}, { criar("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
		end
		forma(ctx, 0.26, 0.66, 0.58, 0.07, ESCURO, 0.5)
		for _, x in { 0.28, 0.66 } do
			forma(ctx, x, 0.74, 0.18, 0.18, ESCURO, 0.5)
		end
		brilho(ctx, 0.27, 0.28, 0.2, 0.08)
	end,

	-- alto-falante com duas ondas
	Som = function(ctx)
		forma(ctx, 0.08, 0.36, 0.2, 0.3, BRANCO_GELO, 0.2)
		forma(ctx, 0.2, 0.2, 0.24, 0.62, BRANCO_GELO, 0.3)
		anel(ctx, 0.44, 0.51, 0.34, 0.09, AZUL[2], { 0.56, 0, 0.44, 1 })
		anel(ctx, 0.44, 0.51, 0.66, 0.09, AZUL[2], { 0.56, 0, 0.44, 1 })
		brilho(ctx, 0.23, 0.25, 0.08, 0.2)
	end,

	-- alto-falante com um X vermelho (mudo)
	SemSom = function(ctx)
		forma(ctx, 0.08, 0.36, 0.2, 0.3, BRANCO_GELO, 0.2)
		forma(ctx, 0.2, 0.2, 0.24, 0.62, BRANCO_GELO, 0.3)
		forma(ctx, 0.52, 0.45, 0.42, 0.12, VERMELHO, 0.5, 45)
		forma(ctx, 0.52, 0.45, 0.42, 0.12, VERMELHO, 0.5, -45)
		brilho(ctx, 0.23, 0.25, 0.08, 0.2)
	end,

	-- seta verde para cima (melhorar)
	Melhorar = function(ctx)
		forma(ctx, 0.36, 0.46, 0.28, 0.44, VERDE, 0.2)
		triangulo(ctx, 0.5, 0.3, 0.84, VERDE, "cima")
		brilho(ctx, 0.41, 0.52, 0.07, 0.25)
	end,

	-- cadeado dourado com alça de prata
	Trancar = function(ctx)
		anel(ctx, 0.5, 0.4, 0.5, 0.11, PRATA[2], { 0, 0, 1, 0.45 })
		for _, x in { 0.25, 0.75 } do
			forma(ctx, x - 0.06, 0.36, 0.12, 0.12, PRATA, 0.2)
		end
		forma(ctx, 0.14, 0.42, 0.72, 0.5, OURO, 0.22)
		forma(ctx, 0.44, 0.55, 0.12, 0.12, ESCURO, 0.5)
		forma(ctx, 0.47, 0.64, 0.06, 0.14, ESCURO, 0.3)
		brilho(ctx, 0.22, 0.47, 0.18, 0.08)
	end,
}

function Icones.tem(nome: string): boolean
	return DESENHOS[nome] ~= nil
end

-- (Re)desenha o ícone "nome" dentro de "quadro".
function Icones.desenhar(quadro: GuiObject, nome: string)
	for _, filho in quadro:GetChildren() do
		if filho:IsA("GuiObject") then
			filho:Destroy()
		end
	end
	local desenho = DESENHOS[nome]
	if not desenho then
		return
	end
	-- contorno proporcional ao tamanho do ícone (3 px num ícone de 60)
	local tamanho = math.max(quadro.Size.X.Offset, quadro.Size.Y.Offset, 30)
	desenho({ quadro = quadro :: Frame, traco = math.clamp(tamanho / 20, 2, 4), z = quadro.ZIndex + 1 })
end

-- Cria o ícone com as propriedades de "props" (Position, Size, Parent...).
function Icones.criar(nome: string, props: { [string]: any }): Frame
	local quadro = criar("Frame", { BackgroundTransparency = 1 })
	for chave, valor in props do
		if chave ~= "Parent" then
			(quadro :: any)[chave] = valor
		end
	end
	criar("UIAspectRatioConstraint", { AspectRatio = 1, Parent = quadro })
	quadro.Parent = props.Parent
	Icones.desenhar(quadro, nome)
	return quadro
end

return Icones

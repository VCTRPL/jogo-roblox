-- Telas que ajudam a jogar: barra da Velocidade até o próximo bioma, faixa
-- "Carregando" com uma trilha de luz até a sua base, e os botões do Índice
-- (todos os Brainrots), da Ajuda (como jogar), do Renascer e do som.
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local LojaOvos = require(script.Parent.LojaOvos)
local Ranking = require(script.Parent.Ranking)
local Sons = require(script.Parent.Sons)
local Ui = require(script.Parent.Ui)

local criar, cantos, borda, gradiente, texto, pular = Ui.criar, Ui.cantos, Ui.borda, Ui.gradiente, Ui.texto, Ui.pular
local CONTORNO = Ui.CONTORNO
local BRANCO = Ui.BRANCO
local ROXO_CLARO = Color3.fromRGB(70, 62, 120)
local ROXO_ESCURO = Color3.fromRGB(36, 30, 66)
local AMARELO = Color3.fromRGB(255, 230, 120)

local NOME_RARIDADE = Config.NOME_RARIDADE

local Interface = {}

local jogador = Players.LocalPlayer
local tela = Ui.tela("Interface", 1)

-- Barra do próximo bioma ------------------------------------------------------

local barra = criar("Frame", {
	Name = "ProximoBioma",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(440, 58),
	BackgroundColor3 = BRANCO,
	Parent = tela,
}, { cantos(16), borda(CONTORNO, 3.5), gradiente(ROXO_CLARO, ROXO_ESCURO) })
local tituloBarra = texto({
	Text = "PRÓXIMO BIOMA",
	TextColor3 = AMARELO,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(14, 4),
	Size = UDim2.new(1, -28, 0, 19),
	Parent = barra,
})
local trilho = criar("Frame", {
	Position = UDim2.fromOffset(12, 26),
	Size = UDim2.new(1, -24, 0, 24),
	BackgroundColor3 = Color3.fromRGB(15, 12, 30),
	ClipsDescendants = true,
	Parent = barra,
}, { cantos(12) })
local preenchimento = criar("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = BRANCO,
	ClipsDescendants = true,
	Parent = trilho,
}, { cantos(12), gradiente(Color3.fromRGB(130, 235, 255), Color3.fromRGB(40, 120, 255)) })
-- reflexo branco correndo pela barra
local reflexo = criar("Frame", {
	Size = UDim2.new(0, 40, 1, 0),
	BackgroundColor3 = BRANCO,
	BackgroundTransparency = 0.65,
	BorderSizePixel = 0,
	Parent = preenchimento,
})
local textoBarra = texto({ Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = trilho })

-- Aviso grande no meio da tela quando um bioma novo é liberado.
local liberado = texto({
	Name = "Liberado",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.38),
	Size = UDim2.fromOffset(700, 80),
	TextColor3 = AMARELO,
	Visible = false,
	Parent = tela,
})
local escalaLiberado = criar("UIScale", { Parent = liberado })

local proximoAnterior: string? = nil

local function atualizarBarra(velocidade: number)
	local proximo = nil
	local anterior = 0
	for _, bioma in Config.BIOMAS do
		if bioma.velocidadeMinima > velocidade then
			proximo = bioma
			break
		end
		anterior = bioma.velocidadeMinima
	end
	if proximo then
		tituloBarra.Text = `PRÓXIMO BIOMA: {Config.maiusculas(proximo.nome)}`
		local fracao = math.clamp((velocidade - anterior) / (proximo.velocidadeMinima - anterior), 0, 1)
		TweenService:Create(preenchimento, TweenInfo.new(0.3), { Size = UDim2.fromScale(fracao, 1) }):Play()
		textoBarra.Text = `⚡ {Config.formatar(velocidade)} / {Config.formatar(proximo.velocidadeMinima)}`
	else
		tituloBarra.Text = "TODOS OS BIOMAS LIBERADOS!"
		TweenService:Create(preenchimento, TweenInfo.new(0.3), { Size = UDim2.fromScale(1, 1) }):Play()
		textoBarra.Text = `⚡ {Config.formatar(velocidade)}`
	end

	-- o "próximo" mudou: o anterior acabou de ser liberado
	local nome = if proximo then proximo.nome else "fim"
	if proximoAnterior and proximoAnterior ~= nome and proximoAnterior ~= "fim" then
		liberado.Text = `🔓 {Config.maiusculas(proximoAnterior)} LIBERADA!`
		liberado.Visible = true
		pular(escalaLiberado, 0.3)
		task.delay(2.5, function()
			liberado.Visible = false
		end)
	end
	proximoAnterior = nome
end

-- Faixa "Carregando" e trilha até a base ------------------------------------

local faixaCarga = criar("Frame", {
	Name = "Carregando",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -26),
	Size = UDim2.fromOffset(420, 74),
	BackgroundColor3 = BRANCO,
	Visible = false,
	Parent = tela,
}, { cantos(18), gradiente(ROXO_CLARO, ROXO_ESCURO) })
local bordaCarga = borda(BRANCO, 4)
bordaCarga.Parent = faixaCarga
local escalaCarga = criar("UIScale", { Parent = faixaCarga })
texto({ Text = "🥚", Position = UDim2.fromOffset(10, 9), Size = UDim2.fromOffset(56, 56), Parent = faixaCarga })
local nomeCarga = texto({
	Text = "",
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(74, 6),
	Size = UDim2.new(1, -86, 0, 34),
	Parent = faixaCarga,
})
local dicaCarga = texto({
	Text = "",
	TextColor3 = AMARELO,
	TextXAlignment = Enum.TextXAlignment.Left,
	Position = UDim2.fromOffset(74, 42),
	Size = UDim2.new(1, -86, 0, 24),
	Parent = faixaCarga,
})

-- A trilha é um Beam que sai do personagem e vai até a base (só neste computador).
local alvo = criar("Part", {
	Name = "TrilhaBase",
	Anchored = true,
	CanCollide = false,
	CanQuery = false,
	CanTouch = false,
	Transparency = 1,
	Size = Vector3.one,
	Parent = Workspace,
})
local anexoAlvo = criar("Attachment", { Parent = alvo })
local anexoJogador = criar("Attachment", { Name = "TrilhaBase", Position = Vector3.new(0, -1.5, 0) })
local feixe = criar("Beam", {
	Attachment0 = anexoJogador,
	Attachment1 = anexoAlvo,
	FaceCamera = true,
	Width0 = 1.4,
	Width1 = 2.4,
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	TextureMode = Enum.TextureMode.Static,
	TextureLength = 3,
	TextureSpeed = 2.5,
	LightEmission = 1,
	Transparency = NumberSequence.new(0.15),
	Enabled = false,
	Parent = alvo,
})

local function atualizarCarga()
	local nome = jogador:GetAttribute("Carregando")
	local cor = jogador:GetAttribute("CorCarregando") or BRANCO
	local centro = jogador:GetAttribute("BaseCentro")
	if nome then
		nomeCarga.Text = nome
		nomeCarga.TextColor3 = cor
		bordaCarga.Color = cor
		feixe.Color = ColorSequence.new(cor, BRANCO)
		if typeof(centro) == "Vector3" then
			alvo.Position = centro + Vector3.new(0, 1, 0)
		end
		faixaCarga.Visible = true
		feixe.Enabled = typeof(centro) == "Vector3"
		pular(escalaCarga, 0.5)
	else
		faixaCarga.Visible = false
		feixe.Enabled = false
	end
end

local function aoNascer(personagem: Model)
	local raiz = personagem:WaitForChild("HumanoidRootPart", 10)
	if raiz then
		anexoJogador.Parent = raiz
	end
end

RunService.RenderStepped:Connect(function()
	local agora = os.clock()
	reflexo.Position = UDim2.new((agora * 0.6) % 1.6 - 0.3, 0, 0, 0)
	if faixaCarga.Visible then
		bordaCarga.Thickness = 4 + math.sin(agora * 8) * 1.5
		local centro = jogador:GetAttribute("BaseCentro")
		local raiz = anexoJogador.Parent
		if typeof(centro) == "Vector3" and raiz and raiz:IsA("BasePart") then
			local distancia = (Vector3.new(centro.X, 0, centro.Z) - Vector3.new(raiz.Position.X, 0, raiz.Position.Z)).Magnitude
			dicaCarga.Text = `Leve para a sua base! ({math.floor(distancia)} m)`
		else
			dicaCarga.Text = "Leve para a sua base!"
		end
	end
end)

-- Painéis (Índice e Ajuda) --------------------------------------------------

local desfoque = criar("BlurEffect", { Name = "DesfoquePainel", Size = 0, Parent = Lighting })
local aberto: Frame? = nil

local function fecharPainel()
	if aberto then
		aberto.Visible = false
		aberto = nil
	end
	TweenService:Create(desfoque, TweenInfo.new(0.2), { Size = 0 }):Play()
end

local function abrirPainel(painel: Frame)
	if aberto == painel then
		fecharPainel()
		return
	end
	if aberto then
		aberto.Visible = false
	end
	aberto = painel
	painel.Visible = true
	pular(painel:FindFirstChildOfClass("UIScale") :: UIScale, 0.6)
	TweenService:Create(desfoque, TweenInfo.new(0.25), { Size = 14 }):Play()
end

local function criarPainel(nome: string, titulo: string, cima: Color3, baixo: Color3): (Frame, ScrollingFrame)
	local painel = criar("Frame", {
		Name = nome,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(660, 450),
		BackgroundColor3 = BRANCO,
		Visible = false,
		ZIndex = 5,
		Parent = tela,
	}, { cantos(22), borda(CONTORNO, 4), gradiente(ROXO_CLARO, ROXO_ESCURO), criar("UIScale", {}) })
	local cabecalho = criar("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = BRANCO,
		ZIndex = 5,
		Parent = painel,
	}, { cantos(22), gradiente(cima, baixo) })
	texto({
		Text = titulo,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(22, 9),
		Size = UDim2.new(1, -100, 0, 46),
		ZIndex = 6,
		Parent = cabecalho,
	})
	local fechar = criar("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(48, 44),
		Text = "X",
		Font = Ui.FONTE,
		TextScaled = true,
		TextColor3 = BRANCO,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = CONTORNO,
		BackgroundColor3 = BRANCO,
		ZIndex = 6,
		Parent = cabecalho,
	}, { cantos(12), borda(CONTORNO, 3), gradiente(Color3.fromRGB(255, 120, 120), Color3.fromRGB(220, 40, 60)) })
	fechar.Activated:Connect(fecharPainel)
	local conteudo = criar("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 78),
		Size = UDim2.new(1, -32, 1, -92),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = AMARELO,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 5,
		Parent = painel,
	})
	return painel, conteudo
end

-- Bonequinho de blocos de um Brainrot, feito só com quadrados.
local function bonequinho(def, parent: Instance)
	local caixa = criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(72, 74),
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = parent,
	})
	local function quadrado(x: number, y: number, w: number, h: number, cor: Color3, contorno: number?)
		local q = criar("Frame", {
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = cor,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = caixa,
		}, { cantos(3) })
		if contorno then
			borda(CONTORNO, contorno).Parent = q
		end
		return q
	end
	quadrado(18, 38, 36, 30, def.cor or BRANCO, 2.5)
	quadrado(14, 4, 44, 38, def.corCabeca or BRANCO, 2.5)
	for _, x in { 22, 40 } do
		quadrado(x, 14, 10, 10, BRANCO)
		quadrado(x + 3, 17, 5, 5, CONTORNO)
	end
end

-- Em que biomas cada Brainrot aparece (pelos ovos dos ninhos).
local function biomasDo(id: string): string
	local nomes = {}
	for _, bioma in Config.BIOMAS do
		for ovoId in bioma.ovos do
			local ovo = Config.ovo(ovoId)
			if ovo and ovo.brainrot == id then
				table.insert(nomes, bioma.nome)
				break
			end
		end
	end
	return if #nomes > 0 then table.concat(nomes, " / ") else "?"
end

local painelIndice, conteudoIndice = criarPainel("Indice", "📖 ÍNDICE DE BRAINROTS", Color3.fromRGB(255, 200, 70), Color3.fromRGB(240, 120, 40))
criar("UIGridLayout", {
	CellSize = UDim2.fromOffset(196, 196),
	CellPadding = UDim2.fromOffset(10, 10),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = conteudoIndice,
})
-- do mais comum para o mais raro (e, na mesma raridade, do que rende menos)
local ordemIndice = table.clone(Config.BRAINROTS)
table.sort(ordemIndice, function(a, b)
	local ra, rb = Config.nivelRaridade(a.raridade), Config.nivelRaridade(b.raridade)
	if ra ~= rb then
		return ra < rb
	end
	return a.renda < b.renda
end)
for ordem, def in ordemIndice do
	local corRaridade = Config.CORES_RARIDADE[def.raridade]
	local cartao = criar("Frame", {
		LayoutOrder = ordem,
		BackgroundColor3 = BRANCO,
		ZIndex = 5,
		Parent = conteudoIndice,
	}, { cantos(16), borda(corRaridade, 3.5), gradiente(Color3.fromRGB(62, 56, 108), Color3.fromRGB(32, 28, 60)) })
	bonequinho(def, cartao)
	texto({ Text = def.nome, Position = UDim2.fromOffset(8, 88), Size = UDim2.new(1, -16, 0, 24), ZIndex = 6, Parent = cartao })
	local selo = criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 116),
		Size = UDim2.fromOffset(110, 24),
		BackgroundColor3 = corRaridade,
		ZIndex = 6,
		Parent = cartao,
	}, { cantos(12), borda(CONTORNO, 2.5) })
	texto({ Text = NOME_RARIDADE[def.raridade] or def.raridade, Size = UDim2.fromScale(1, 1), ZIndex = 7, Parent = selo })
	texto({
		Text = `💰 ${Config.formatar(def.renda)}/s`,
		TextColor3 = Color3.fromRGB(130, 255, 130),
		Position = UDim2.fromOffset(8, 144),
		Size = UDim2.new(1, -16, 0, 22),
		ZIndex = 6,
		Parent = cartao,
	})
	texto({
		Text = `📍 {biomasDo(def.id)}`,
		TextColor3 = Color3.fromRGB(200, 220, 255),
		Position = UDim2.fromOffset(8, 168),
		Size = UDim2.new(1, -16, 0, 18),
		ZIndex = 6,
		Parent = cartao,
	})
end

local painelAjuda, conteudoAjuda = criarPainel("Ajuda", "❓ COMO JOGAR", Color3.fromRGB(120, 230, 140), Color3.fromRGB(30, 160, 90))
criar("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = conteudoAjuda })
local PASSOS = {
	{ "🏃", "Corra na esteira da sua base para ganhar Velocidade." },
	{ "🥚", "Vá aos biomas e pegue ovos nos ninhos. O chefe do bioma corre atrás de você até as bases!" },
	{ "🏠", "Leve o ovo para a sua base: ele choca e vira um Brainrot que dá dinheiro." },
	{ "⬆️", "Use o dinheiro para melhorar a esteira e liberar biomas novos." },
	{ "🔥", "Correndo sem parar na esteira, o fôlego sobe e você ganha até 2x de Velocidade." },
	{ "😈", "Roube ovos e Brainrots das outras bases, e tranque a sua!" },
	{ "💰", "Base cheia? Segure E num Brainrot seu para vender." },
	{ "🔄", "Com bastante dinheiro, renasça: começa de novo, mas ganha mais para sempre." },
	{ "🛒", "Na Loja tem ovos especiais, que abrem na hora, e passes como 2x Dinheiro e Tênis Turbo." },
	{ "🏆", "No Ranking, veja quem tem mais Brainrots, dinheiro e Velocidade no servidor e no mundo." },
}
for ordem, passo in PASSOS do
	local linha = criar("Frame", {
		LayoutOrder = ordem,
		Size = UDim2.new(1, -12, 0, 58),
		BackgroundColor3 = BRANCO,
		ZIndex = 5,
		Parent = conteudoAjuda,
	}, { cantos(14), borda(CONTORNO, 2.5), gradiente(Color3.fromRGB(62, 56, 108), Color3.fromRGB(40, 35, 75)) })
	texto({ Text = passo[1], Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(46, 46), ZIndex = 6, Parent = linha })
	texto({
		Text = passo[2],
		TextScaled = false,
		TextSize = 22,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(62, 4),
		Size = UDim2.new(1, -70, 1, -8),
		ZIndex = 6,
		Parent = linha,
	})
end

-- Painel do Renascer ----------------------------------------------------------

local painelRenascer, conteudoRenascer = criarPainel("Renascer", "🔄 RENASCER", Color3.fromRGB(255, 120, 220), Color3.fromRGB(150, 60, 230))
criar("UIListLayout", {
	Padding = UDim.new(0, 10),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = conteudoRenascer,
})

local function linhaRenascer(ordem: number, altura: number): Frame
	return criar("Frame", {
		LayoutOrder = ordem,
		Size = UDim2.new(1, -12, 0, altura),
		BackgroundColor3 = BRANCO,
		ZIndex = 5,
		Parent = conteudoRenascer,
	}, { cantos(14), borda(CONTORNO, 2.5), gradiente(Color3.fromRGB(62, 56, 108), Color3.fromRGB(40, 35, 75)) })
end

local textoVezes = texto({ Text = "", Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), ZIndex = 6, Parent = linhaRenascer(1, 46) })
local quadroGanhos = linhaRenascer(2, 92)
local textoRenda = texto({
	Text = "",
	TextColor3 = Color3.fromRGB(130, 255, 130),
	Size = UDim2.new(1, -16, 0, 38),
	Position = UDim2.fromOffset(8, 6),
	ZIndex = 6,
	Parent = quadroGanhos,
})
local textoEsteira = texto({
	Text = "",
	TextColor3 = Color3.fromRGB(130, 220, 255),
	Size = UDim2.new(1, -16, 0, 38),
	Position = UDim2.fromOffset(8, 48),
	ZIndex = 6,
	Parent = quadroGanhos,
})
texto({
	Text = "⚠️ Você perde o dinheiro, a Velocidade, a esteira e tudo da base.",
	TextColor3 = Color3.fromRGB(255, 170, 170),
	TextScaled = false,
	TextSize = 20,
	TextWrapped = true,
	Size = UDim2.new(1, -16, 1, -8),
	Position = UDim2.fromOffset(8, 4),
	ZIndex = 6,
	Parent = linhaRenascer(3, 54),
})
-- barra do dinheiro até o preço
local quadroPreco = linhaRenascer(4, 50)
local trilhoPreco = criar("Frame", {
	Position = UDim2.fromOffset(10, 10),
	Size = UDim2.new(1, -20, 1, -20),
	BackgroundColor3 = Color3.fromRGB(15, 12, 30),
	ClipsDescendants = true,
	ZIndex = 6,
	Parent = quadroPreco,
}, { cantos(12) })
local enchimentoPreco = criar("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = BRANCO,
	ZIndex = 6,
	Parent = trilhoPreco,
}, { cantos(12), gradiente(Color3.fromRGB(255, 230, 120), Color3.fromRGB(240, 150, 30)) })
local textoPreco = texto({ Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 7, Parent = trilhoPreco })

local botaoRenascer = criar("TextButton", {
	LayoutOrder = 5,
	Size = UDim2.fromOffset(280, 60),
	BackgroundColor3 = BRANCO,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 6,
	Parent = conteudoRenascer,
}, { cantos(18), borda(CONTORNO, 3.5) })
local gradienteBotao = gradiente(Color3.fromRGB(255, 120, 220), Color3.fromRGB(150, 60, 230))
gradienteBotao.Parent = botaoRenascer
local escalaBotao = criar("UIScale", { Parent = botaoRenascer })
local textoBotao = texto({ Text = "RENASCER", Size = UDim2.new(1, -20, 1, -16), Position = UDim2.fromOffset(10, 8), ZIndex = 7, Parent = botaoRenascer })

local podeRenascer = false
local function atualizarRenascer()
	local stats = jogador:FindFirstChild("leaderstats")
	local vezesValor = stats and stats:FindFirstChild("Renascimentos")
	local dinheiroValor = stats and stats:FindFirstChild("Dinheiro")
	if not (vezesValor and dinheiroValor) then
		return
	end
	local vezes = (vezesValor :: IntValue).Value
	local dinheiro = (dinheiroValor :: IntValue).Value
	textoVezes.Text = `Renascimentos: {vezes} / {Config.RENASCER.maximo}`
	if vezes >= Config.RENASCER.maximo then
		textoRenda.Text = `💰 Dinheiro: {Config.multiplicadorRenda(vezes)}x`
		textoEsteira.Text = `⚡ Esteira: {Config.multiplicadorEsteira(vezes)}x`
		textoPreco.Text = "MÁXIMO!"
		enchimentoPreco.Size = UDim2.fromScale(1, 1)
		podeRenascer = false
	else
		local preco = Config.precoRenascer(vezes)
		textoRenda.Text = `💰 Dinheiro: {Config.multiplicadorRenda(vezes)}x → {Config.multiplicadorRenda(vezes + 1)}x`
		textoEsteira.Text = `⚡ Esteira: {Config.multiplicadorEsteira(vezes)}x → {Config.multiplicadorEsteira(vezes + 1)}x`
		textoPreco.Text = `${Config.formatar(dinheiro)} / ${Config.formatar(preco)}`
		enchimentoPreco.Size = UDim2.fromScale(math.clamp(dinheiro / preco, 0, 1), 1)
		podeRenascer = dinheiro >= preco
	end
	textoBotao.Text = if podeRenascer then "RENASCER!" else "FALTA DINHEIRO"
	gradienteBotao.Color = if podeRenascer
		then ColorSequence.new(Color3.fromRGB(255, 120, 220), Color3.fromRGB(150, 60, 230))
		else ColorSequence.new(Color3.fromRGB(130, 125, 150), Color3.fromRGB(80, 75, 100))
end

botaoRenascer.Activated:Connect(function()
	pular(escalaBotao, 0.85)
	if not podeRenascer then
		Sons.tocar("Erro")
		return
	end
	local evento = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("Renascer")
	if evento then
		(evento :: RemoteEvent):FireServer()
	end
	fecharPainel()
end)

-- Loja de gamepasses ---------------------------------------------------------

local painelLoja, conteudoLoja = criarPainel("Loja", "🛒 LOJA", Color3.fromRGB(120, 230, 140), Color3.fromRGB(20, 150, 110))
criar("UIGridLayout", {
	CellSize = UDim2.fromOffset(196, 210),
	CellPadding = UDim2.fromOffset(10, 10),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = conteudoLoja,
})

type CartaoLoja = { passe: any, botao: TextButton, texto: TextLabel, gradiente: UIGradient, preco: string? }
local cartoesLoja: { CartaoLoja } = {}

local function atualizarCartaoLoja(cartao: CartaoLoja)
	local passe = cartao.passe
	local tem = jogador:GetAttribute(`Pass_{passe.chave}`) == true
	if tem then
		cartao.texto.Text = "✅ VOCÊ TEM"
		cartao.gradiente.Color = ColorSequence.new(Color3.fromRGB(130, 125, 150), Color3.fromRGB(80, 75, 100))
	elseif passe.id == 0 then
		cartao.texto.Text = "EM BREVE"
		cartao.gradiente.Color = ColorSequence.new(Color3.fromRGB(130, 125, 150), Color3.fromRGB(80, 75, 100))
	else
		cartao.texto.Text = if cartao.preco then `R$ {cartao.preco}` else "COMPRAR"
		cartao.gradiente.Color = ColorSequence.new(Color3.fromRGB(120, 255, 130), Color3.fromRGB(30, 170, 70))
	end
end

for ordem, passe in Config.GAMEPASSES do
	local quadro = criar("Frame", {
		LayoutOrder = ordem,
		BackgroundColor3 = BRANCO,
		ZIndex = 5,
		Parent = conteudoLoja,
	}, { cantos(16), borda(Color3.fromRGB(255, 215, 80), 3.5), gradiente(Color3.fromRGB(62, 56, 108), Color3.fromRGB(32, 28, 60)) })
	texto({ Text = passe.icone, Position = UDim2.new(0.5, -30, 0, 8), Size = UDim2.fromOffset(60, 56), ZIndex = 6, Parent = quadro })
	texto({ Text = passe.nome, TextColor3 = Color3.fromRGB(255, 225, 120), Position = UDim2.fromOffset(8, 66), Size = UDim2.new(1, -16, 0, 26), ZIndex = 6, Parent = quadro })
	texto({
		Text = passe.descricao,
		TextScaled = false,
		TextSize = 16,
		TextWrapped = true,
		Position = UDim2.fromOffset(10, 94),
		Size = UDim2.new(1, -20, 0, 58),
		ZIndex = 6,
		Parent = quadro,
	})
	local botaoCompra = criar("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -24, 0, 42),
		BackgroundColor3 = BRANCO,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		Parent = quadro,
	}, { cantos(12), borda(CONTORNO, 3) })
	local gradienteCompra = gradiente(Color3.fromRGB(120, 255, 130), Color3.fromRGB(30, 170, 70))
	gradienteCompra.Parent = botaoCompra
	local textoCompra = texto({ Text = "", Size = UDim2.new(1, -12, 1, -10), Position = UDim2.fromOffset(6, 5), ZIndex = 7, Parent = botaoCompra })
	local cartao: CartaoLoja = { passe = passe, botao = botaoCompra, texto = textoCompra, gradiente = gradienteCompra, preco = nil }
	table.insert(cartoesLoja, cartao)
	atualizarCartaoLoja(cartao)
	jogador:GetAttributeChangedSignal(`Pass_{passe.chave}`):Connect(function()
		atualizarCartaoLoja(cartao)
	end)
	botaoCompra.Activated:Connect(function()
		if passe.id ~= 0 and not jogador:GetAttribute(`Pass_{passe.chave}`) then
			MarketplaceService:PromptGamePassPurchase(jogador, passe.id)
		end
	end)
	-- preço em Robux, do Creator Dashboard
	if passe.id ~= 0 then
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(passe.id, Enum.InfoType.GamePass)
			end)
			if ok and info and info.PriceInRobux then
				cartao.preco = tostring(info.PriceInRobux)
				atualizarCartaoLoja(cartao)
			end
		end)
	end
end

-- Ovos especiais (Robux) numa aba da Loja
LojaOvos.montar(painelLoja, conteudoLoja)

-- Ranking ---------------------------------------------------------------------

local painelRanking, conteudoRanking = criarPainel("Ranking", "🏆 RANKING", Color3.fromRGB(255, 215, 80), Color3.fromRGB(240, 130, 30))
Ranking.montar(painelRanking, conteudoRanking)

-- Botões do lado direito ----------------------------------------------------

local menu = criar("Frame", {
	Name = "Menu",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0.45, 0),
	Size = UDim2.fromOffset(84, 564),
	BackgroundTransparency = 1,
	Parent = tela,
}, { criar("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }) })

-- "acao" é um painel para abrir ou uma função para chamar.
local function botao(ordem: number, icone: string, legenda: string, cima: Color3, baixo: Color3, acao: Frame | (() -> ())): any
	local b = criar("TextButton", {
		Name = legenda,
		LayoutOrder = ordem,
		Size = UDim2.fromOffset(84, 84),
		BackgroundColor3 = BRANCO,
		Text = "",
		AutoButtonColor = false,
		Parent = menu,
	}, { cantos(20), borda(CONTORNO, 3.5), gradiente(cima, baixo) })
	local escala = criar("UIScale", { Parent = b })
	criar("Frame", {
		Position = UDim2.fromOffset(6, 4),
		Size = UDim2.new(1, -12, 0.35, 0),
		BackgroundColor3 = BRANCO,
		BackgroundTransparency = 0.75,
		Parent = b,
	}, { cantos(14) })
	local textoIcone = Ui.icone(legenda, icone, { Position = UDim2.fromOffset(12, 4), Size = UDim2.fromOffset(60, 52), Parent = b })
	texto({ Text = legenda, Position = UDim2.new(0, 4, 1, -28), Size = UDim2.new(1, -8, 0, 24), Parent = b })
	b.MouseEnter:Connect(function()
		TweenService:Create(escala, TweenInfo.new(0.15), { Scale = 1.08 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(escala, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
	b.Activated:Connect(function()
		pular(escala, 0.85)
		if typeof(acao) == "function" then
			acao()
		else
			abrirPainel(acao)
		end
	end)
	return textoIcone
end

botao(1, "📖", "Índice", Color3.fromRGB(255, 210, 80), Color3.fromRGB(240, 120, 40), painelIndice)
botao(2, "❓", "Ajuda", Color3.fromRGB(130, 235, 150), Color3.fromRGB(30, 160, 90), painelAjuda)
botao(3, "🏆", "Ranking", Color3.fromRGB(255, 225, 90), Color3.fromRGB(235, 140, 30), painelRanking)
botao(4, "🔄", "Renascer", Color3.fromRGB(255, 120, 220), Color3.fromRGB(150, 60, 230), function()
	atualizarRenascer()
	abrirPainel(painelRenascer)
end)
botao(5, "🛒", "Loja", Color3.fromRGB(120, 255, 140), Color3.fromRGB(20, 150, 110), painelLoja)
local iconeSom: TextLabel
iconeSom = botao(6, "🔊", "Som", Color3.fromRGB(130, 200, 255), Color3.fromRGB(50, 110, 230), function()
	iconeSom.Text = if Sons.alternar() then "🔇" else "🔊"
end)

function Interface.iniciar()
	jogador:GetAttributeChangedSignal("Carregando"):Connect(atualizarCarga)
	jogador:GetAttributeChangedSignal("BaseCentro"):Connect(atualizarCarga)
	atualizarCarga()

	jogador.CharacterAdded:Connect(aoNascer)
	if jogador.Character then
		task.spawn(aoNascer, jogador.Character)
	end

	task.spawn(function()
		local stats = jogador:WaitForChild("leaderstats")
		for _, nome in { "Dinheiro", "Renascimentos" } do
			(stats:WaitForChild(nome) :: IntValue).Changed:Connect(function()
				if painelRenascer.Visible then
					atualizarRenascer()
				end
			end)
		end
	end)

	task.spawn(function()
		local stats = jogador:WaitForChild("leaderstats")
		local velocidade = stats:WaitForChild("Velocidade") :: IntValue
		velocidade.Changed:Connect(function()
			atualizarBarra(velocidade.Value)
		end)
		atualizarBarra(velocidade.Value)
	end)
end

return Interface

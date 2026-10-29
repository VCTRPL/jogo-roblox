-- Aba "Ovos Especiais" da Loja (Config.OVOS_ROBUX): cada ovo com a aparência,
-- a raridade, o preço em Robux, os Brainrots que podem sair com a chance de
-- cada um e os benefícios. O botão só pede a compra para o servidor; quem
-- entrega o prêmio é o servidor, depois que o Roblox confirma o pagamento.
-- Quando o prêmio chega, o ovo aparece no meio da tela, treme e abre.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sons = require(script.Parent.Sons)
local Ui = require(script.Parent.Ui)

local criar, cantos, borda, gradiente, texto, pular = Ui.criar, Ui.cantos, Ui.borda, Ui.gradiente, Ui.texto, Ui.pular
local CONTORNO = Ui.CONTORNO
local BRANCO = Ui.BRANCO
local AMARELO = Color3.fromRGB(255, 230, 120)
local CINZA_CIMA = Color3.fromRGB(110, 104, 150)
local CINZA_BAIXO = Color3.fromRGB(70, 64, 110)
local VERDE_CIMA = Color3.fromRGB(120, 255, 130)
local VERDE_BAIXO = Color3.fromRGB(30, 170, 70)

local LojaOvos = {}

local jogador = Players.LocalPlayer

-- Ovos com efeito animado: { gradiente, efeito, estrelas, ativo }.
local animados = {}

local function oval(): UICorner
	return criar("UICorner", { CornerRadius = UDim.new(0.5, 0) })
end

-- Desenha um ovo com as cores e o efeito do ovo de Robux.
local function desenharOvo(parent: Instance, ovo, props: { [string]: any }, ativo: () -> boolean): Frame
	local z = props.ZIndex or 6
	local quadro = criar("Frame", { BackgroundColor3 = BRANCO, ZIndex = z }, { oval(), borda(CONTORNO, 3) })
	for chave, valor in props do
		(quadro :: any)[chave] = valor
	end
	quadro.Parent = parent
	local grad = gradiente(ovo.cores[1], ovo.cores[2])
	grad.Parent = quadro
	-- faixa e pintinhas, como num ovo de Páscoa de plástico
	criar("Frame", {
		Position = UDim2.fromScale(0, 0.56),
		Size = UDim2.fromScale(1, 0.1),
		BackgroundColor3 = BRANCO,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = z + 1,
		Parent = quadro,
	})
	for _, ponto in { Vector2.new(0.3, 0.75), Vector2.new(0.6, 0.8), Vector2.new(0.68, 0.38) } do
		criar("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(ponto.X, ponto.Y),
			Size = UDim2.fromScale(0.13, 0.1),
			BackgroundColor3 = BRANCO,
			BackgroundTransparency = 0.35,
			ZIndex = z + 1,
			Parent = quadro,
		}, { oval() })
	end
	-- brilho de plástico
	criar("Frame", {
		Position = UDim2.fromScale(0.18, 0.1),
		Size = UDim2.fromScale(0.22, 0.28),
		Rotation = -18,
		BackgroundColor3 = BRANCO,
		BackgroundTransparency = 0.3,
		ZIndex = z + 2,
		Parent = quadro,
	}, { oval() })
	local estrelas = {}
	if ovo.efeito == "cosmico" then
		for i = 1, 5 do
			table.insert(estrelas, texto({
				Text = "✦",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.2 + (i * 0.37) % 0.6, 0.15 + (i * 0.23) % 0.7),
				Size = UDim2.fromScale(0.22, 0.16),
				TextStrokeTransparency = 1,
				ZIndex = z + 2,
				Parent = quadro,
			}))
		end
	end
	table.insert(animados, { gradiente = grad, efeito = ovo.efeito, estrelas = estrelas, ativo = ativo, cores = ovo.cores })
	return quadro
end

RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for _, anim in animados do
		if anim.gradiente.Parent and anim.ativo() then
			if anim.efeito == "arco-iris" then
				local pontos = {}
				for i = 0, 4 do
					table.insert(pontos, ColorSequenceKeypoint.new(i / 4, Color3.fromHSV((t * 0.25 + i * 0.2) % 1, 0.55, 1)))
				end
				anim.gradiente.Color = ColorSequence.new(pontos)
			elseif anim.efeito == "cosmico" then
				anim.gradiente.Rotation = 90 + math.sin(t * 1.4) * 30
				for i, estrela in anim.estrelas do
					estrela.TextTransparency = 0.5 + math.sin(t * 3 + i * 1.7) * 0.5
				end
			else
				anim.gradiente.Offset = Vector2.new(0, math.sin(t * 2) * 0.18)
			end
		end
	end
end)

local function nomeTamanho(nome: string?): string
	return if nome == "Medio" then "Médio" else nome or ""
end

-- "Udin Din Din Dun 15%", com a cor da raridade.
local function textoChances(ovo): string
	local partes = {}
	for _, item in Config.chancesOvoRobux(ovo) do
		local def = Config.brainrot(item.id)
		if def then
			local cor = Config.CORES_RARIDADE[def.raridade]:ToHex()
			local chance = if item.chance < 1 then string.format("%.1f", item.chance) else tostring(math.floor(item.chance + 0.5))
			table.insert(partes, `<font color="#{cor}">{def.nome}</font> {chance}%`)
		end
	end
	return table.concat(partes, "  •  ")
end

local function textoBeneficios(ovo): string
	local partes = {}
	if (ovo.quantidade or 1) > 1 then
		table.insert(partes, `📦 {ovo.quantidade} ovos`)
	end
	if ovo.tamanhoMinimo and ovo.tamanhoMinimo ~= Config.TAMANHOS[1].nome then
		table.insert(partes, `📏 {nomeTamanho(ovo.tamanhoMinimo)} ou maior`)
	end
	if ovo.mutacaoMinima and ovo.mutacaoMinima ~= "Normal" then
		local ultima = Config.MUTACOES[#Config.MUTACOES].nome
		table.insert(partes, if ovo.mutacaoMinima == ultima then `🌈 Sempre {ultima}` else `✨ {ovo.mutacaoMinima} ou melhor`)
	end
	if ovo.sorte then
		table.insert(partes, "🍀 Sorte dobrada")
	end
	table.insert(partes, "⚡ Abre na hora")
	return table.concat(partes, "   ")
end

-- "12d 4h", "3h 20min" ou "45s"
local function tempoRestante(segundos: number): string
	if segundos >= 86400 then
		return `{segundos // 86400}d {(segundos % 86400) // 3600}h`
	elseif segundos >= 3600 then
		return `{segundos // 3600}h {(segundos % 3600) // 60}min`
	elseif segundos >= 60 then
		return `{segundos // 60}min {segundos % 60}s`
	end
	return `{math.max(0, segundos)}s`
end

type Cartao = { ovo: any, texto: TextLabel, gradiente: UIGradient, tempo: TextLabel?, preco: number? }
local cartoes: { Cartao } = {}

local function disponivel(cartao: Cartao): (boolean, string)
	local fim = Config.fimOferta(cartao.ovo)
	if fim and os.time() > fim then
		return false, "ACABOU"
	end
	if cartao.ovo.produtoId == 0 then
		return false, "EM BREVE"
	end
	return true, `R$ {cartao.preco or cartao.ovo.robux}`
end

local function atualizarCartao(cartao: Cartao)
	local pode, rotulo = disponivel(cartao)
	cartao.texto.Text = rotulo
	cartao.gradiente.Color = if pode then ColorSequence.new(VERDE_CIMA, VERDE_BAIXO) else ColorSequence.new(CINZA_CIMA, CINZA_BAIXO)
	local fim = Config.fimOferta(cartao.ovo)
	if cartao.tempo and fim then
		local falta = fim - os.time()
		cartao.tempo.Text = if falta > 0 then `⏳ {tempoRestante(falta)}` else "⏳ ACABOU"
	end
end

local function criarCartao(lista: ScrollingFrame, ordem: number, ovo, ativo: () -> boolean)
	local corRaridade = Config.CORES_RARIDADE[ovo.raridade] or BRANCO
	local quadro = criar("Frame", {
		LayoutOrder = ordem,
		Size = UDim2.new(1, -12, 0, 200),
		BackgroundColor3 = BRANCO,
		ZIndex = 5,
		Parent = lista,
	}, { cantos(16), borda(corRaridade, 3.5), gradiente(Color3.fromRGB(62, 56, 108), Color3.fromRGB(32, 28, 60)) })
	criar("Frame", {
		Position = UDim2.fromOffset(8, 4),
		Size = UDim2.new(1, -16, 0, 40),
		BackgroundColor3 = BRANCO,
		BackgroundTransparency = 0.9,
		ZIndex = 5,
		Parent = quadro,
	}, { cantos(12) })

	-- o ovo, com o selo do pacote
	local ovoDesenho = desenharOvo(quadro, ovo, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 70, 0.5, 0),
		Size = UDim2.fromOffset(100, 130),
		ZIndex = 6,
	}, ativo)
	if (ovo.quantidade or 1) > 1 then
		local selo = criar("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 14, 0, -6),
			Size = UDim2.fromOffset(54, 32),
			BackgroundColor3 = Color3.fromRGB(255, 70, 90),
			Rotation = 12,
			ZIndex = 9,
			Parent = ovoDesenho,
		}, { cantos(10), borda(CONTORNO, 2.5) })
		texto({ Text = `x{ovo.quantidade}`, Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 1, -6), ZIndex = 10, Parent = selo })
	end

	texto({
		Text = ovo.nome,
		TextColor3 = AMARELO,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(136, 10),
		Size = UDim2.new(1, -300, 0, 32),
		ZIndex = 6,
		Parent = quadro,
	})
	local selos = criar("Frame", {
		Position = UDim2.fromOffset(136, 46),
		Size = UDim2.new(1, -300, 0, 26),
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = quadro,
	}, { criar("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local seloRaridade = criar("Frame", {
		LayoutOrder = 1,
		Size = UDim2.fromOffset(120, 26),
		BackgroundColor3 = corRaridade,
		ZIndex = 6,
		Parent = selos,
	}, { cantos(12), borda(CONTORNO, 2.5) })
	texto({ Text = `{Config.NOME_RARIDADE[ovo.raridade] or ovo.raridade}+`, Position = UDim2.fromOffset(6, 2), Size = UDim2.new(1, -12, 1, -4), ZIndex = 7, Parent = seloRaridade })
	local tempo = nil
	if ovo.ate then
		local seloTempo = criar("Frame", {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(130, 26),
			BackgroundColor3 = Color3.fromRGB(255, 80, 80),
			ZIndex = 6,
			Parent = selos,
		}, { cantos(12), borda(CONTORNO, 2.5) })
		tempo = texto({ Text = "", Position = UDim2.fromOffset(6, 2), Size = UDim2.new(1, -12, 1, -4), ZIndex = 7, Parent = seloTempo })
	else
		local seloSempre = criar("Frame", {
			LayoutOrder = 2,
			Size = UDim2.fromOffset(110, 26),
			BackgroundColor3 = Color3.fromRGB(70, 140, 255),
			ZIndex = 6,
			Parent = selos,
		}, { cantos(12), borda(CONTORNO, 2.5) })
		texto({ Text = "PERMANENTE", Position = UDim2.fromOffset(6, 3), Size = UDim2.new(1, -12, 1, -6), ZIndex = 7, Parent = seloSempre })
	end

	texto({
		Text = textoChances(ovo),
		RichText = true,
		TextScaled = false,
		TextSize = 17,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(136, 80),
		Size = UDim2.new(1, -150, 0, 66),
		ZIndex = 6,
		Parent = quadro,
	})
	texto({
		Text = textoBeneficios(ovo),
		TextColor3 = Color3.fromRGB(150, 255, 170),
		TextScaled = false,
		TextSize = 16,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(136, 150),
		Size = UDim2.new(1, -150, 0, 42),
		ZIndex = 6,
		Parent = quadro,
	})

	local botaoCompra = criar("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(140, 56),
		BackgroundColor3 = BRANCO,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
		Parent = quadro,
	}, { cantos(16), borda(CONTORNO, 3.5) })
	local gradienteCompra = gradiente(VERDE_CIMA, VERDE_BAIXO)
	gradienteCompra.Parent = botaoCompra
	criar("Frame", {
		Position = UDim2.fromOffset(6, 3),
		Size = UDim2.new(1, -12, 0.35, 0),
		BackgroundColor3 = BRANCO,
		BackgroundTransparency = 0.75,
		ZIndex = 6,
		Parent = botaoCompra,
	}, { cantos(12) })
	local escala = criar("UIScale", { Parent = botaoCompra })
	local textoCompra = texto({ Text = "", Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), ZIndex = 7, Parent = botaoCompra })

	local cartao: Cartao = { ovo = ovo, texto = textoCompra, gradiente = gradienteCompra, tempo = tempo, preco = nil }
	table.insert(cartoes, cartao)
	atualizarCartao(cartao)
	botaoCompra.Activated:Connect(function()
		pular(escala, 0.85)
		if not disponivel(cartao) then
			Sons.tocar("Erro")
			return
		end
		Sons.tocar("Clique")
		local evento = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("ComprarOvo")
		if evento then
			(evento :: RemoteEvent):FireServer(ovo.chave)
		end
	end)
	-- preço de verdade, do Creator Dashboard
	if ovo.produtoId ~= 0 then
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(ovo.produtoId, Enum.InfoType.Product)
			end)
			if ok and info and info.PriceInRobux then
				cartao.preco = info.PriceInRobux
				atualizarCartao(cartao)
			end
		end)
	end
end

-- Ovo abrindo no meio da tela ---------------------------------------------------

-- Sem o UIScale do Ui.tela: o fundo escuro precisa cobrir a tela inteira.
local telaRevelar = criar("ScreenGui", {
	Name = "RevelarOvo",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 20,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = jogador:WaitForChild("PlayerGui"),
})
local fundo = criar("TextButton", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(10, 6, 25),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 10,
	Parent = telaRevelar,
})
local palco = criar("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(460, 460),
	BackgroundTransparency = 1,
	ZIndex = 11,
	Parent = fundo,
})
local escalaPalco = criar("UIScale", { Parent = palco })
local function ajustarPalco()
	local camera = workspace.CurrentCamera
	if camera then
		escalaPalco.Scale = math.clamp(camera.ViewportSize.Y / 820, 0.6, 1.15)
	end
end
ajustarPalco()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarPalco)
end
local clarao = criar("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = BRANCO,
	BackgroundTransparency = 1,
	ZIndex = 30,
	Parent = fundo,
})

local revelando = false
local function revelarAtivo(): boolean
	return fundo.Visible
end

local function limparPalco()
	for _, filho in palco:GetChildren() do
		filho:Destroy()
	end
end

local function esperarToque(segundos: number)
	local tocou = false
	local conexao = fundo.Activated:Connect(function()
		tocou = true
	end)
	local inicio = os.clock()
	while not tocou and os.clock() - inicio < segundos do
		task.wait()
	end
	conexao:Disconnect()
end

local function revelar(ovo, item, numero: number, total: number)
	limparPalco()
	local def = Config.brainrot(item.id)
	if not def then
		return
	end
	local corRaridade = Config.CORES_RARIDADE[def.raridade] or BRANCO
	local mutacao = Config.mutacao(item.mutacao)
	local corNome = mutacao.cor or corRaridade

	-- 1. o ovo aparece e treme
	local desenho = desenharOvo(palco, ovo, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(170, 220),
		ZIndex = 12,
	}, revelarAtivo)
	local escala = criar("UIScale", { Scale = 0, Parent = desenho })
	TweenService:Create(escala, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	texto({
		Text = if total > 1 then `{ovo.nome} ({numero}/{total})` else ovo.nome,
		TextColor3 = AMARELO,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.02),
		Size = UDim2.fromOffset(440, 44),
		ZIndex = 12,
		Parent = palco,
	})
	task.wait(0.45)
	for i = 1, 12 do
		desenho.Rotation = (if i % 2 == 0 then 1 else -1) * (3 + i * 1.2)
		escala.Scale = 1 + i * 0.015
		if i % 4 == 0 then
			Sons.tocar("Brilho")
		end
		task.wait(0.07)
	end

	-- 2. clarão e o Brainrot
	clarao.BackgroundTransparency = 0
	TweenService:Create(clarao, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	local raro = Config.nivelRaridade(def.raridade) >= Config.nivelRaridade("Lendario") or item.mutacao ~= "Normal"
	Sons.tocar(if raro then "ChocouRaro" else "Chocou")
	desenho:Destroy()

	-- raios girando atrás
	local raios = criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(420, 420),
		BackgroundTransparency = 1,
		ZIndex = 11,
		Parent = palco,
	})
	for i = 1, 8 do
		criar("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 34, 1, 0),
			Rotation = i * 22.5,
			BackgroundColor3 = corNome,
			BackgroundTransparency = 0.6,
			ZIndex = 11,
			Parent = raios,
		}, { cantos(17) })
	end
	TweenService:Create(raios, TweenInfo.new(6, Enum.EasingStyle.Linear), { Rotation = 180 }):Play()

	local cartao = criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 250),
		BackgroundColor3 = BRANCO,
		ZIndex = 13,
		Parent = palco,
	}, { cantos(22), borda(corRaridade, 5), gradiente(Color3.fromRGB(70, 62, 120), Color3.fromRGB(36, 30, 66)) })
	local escalaCartao = criar("UIScale", { Parent = cartao })
	pular(escalaCartao, 0.4)
	texto({ Text = "VOCÊ GANHOU!", TextColor3 = AMARELO, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 40), ZIndex = 14, Parent = cartao })
	local nome = if item.mutacao ~= "Normal" then `{def.nome} {item.mutacao}` else def.nome
	texto({ Text = nome, TextColor3 = corNome, Position = UDim2.fromOffset(16, 58), Size = UDim2.new(1, -32, 0, 48), ZIndex = 14, Parent = cartao })
	local selo = criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 114),
		Size = UDim2.fromOffset(150, 30),
		BackgroundColor3 = corRaridade,
		ZIndex = 14,
		Parent = cartao,
	}, { cantos(14), borda(CONTORNO, 3) })
	texto({ Text = Config.NOME_RARIDADE[def.raridade] or def.raridade, Position = UDim2.fromOffset(6, 3), Size = UDim2.new(1, -12, 1, -6), ZIndex = 15, Parent = selo })
	texto({
		Text = `📏 {nomeTamanho(item.tamanho)}   ✨ {item.mutacao}`,
		Position = UDim2.fromOffset(16, 152),
		Size = UDim2.new(1, -32, 0, 30),
		ZIndex = 14,
		Parent = cartao,
	})
	texto({
		Text = `💰 ${Config.formatar(Config.renda(item))}/s`,
		TextColor3 = Color3.fromRGB(130, 255, 130),
		Position = UDim2.fromOffset(16, 186),
		Size = UDim2.new(1, -32, 0, 32),
		ZIndex = 14,
		Parent = cartao,
	})
	texto({
		Text = if jogador:GetAttribute("Pendentes") and jogador:GetAttribute("Pendentes") > 0
			then "Base cheia: ele entra assim que abrir uma vaga. Toque para continuar"
			else "Já está na sua base! Toque para continuar",
		TextColor3 = Color3.fromRGB(200, 200, 230),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(440, 24),
		ZIndex = 14,
		Parent = palco,
	})
	esperarToque(5)
end

local fila = {}
local function mostrarFila()
	if revelando then
		return
	end
	revelando = true
	fundo.Visible = true
	TweenService:Create(fundo, TweenInfo.new(0.25), { BackgroundTransparency = 0.3 }):Play()
	while #fila > 0 do
		local pedido = table.remove(fila, 1)
		local ovo = Config.ovoRobux(pedido.chave)
		if ovo and typeof(pedido.itens) == "table" then
			for numero, item in pedido.itens do
				revelar(ovo, item, numero, #pedido.itens)
			end
		end
	end
	limparPalco()
	fundo.BackgroundTransparency = 1
	fundo.Visible = false
	revelando = false
end

-- Monta as abas "Ovos Especiais" e "Passes" dentro do painel da Loja.
function LojaOvos.montar(painel: Frame, conteudoPasses: ScrollingFrame)
	painel.Size = UDim2.fromOffset(660, 540)
	local function ativo(): boolean
		return painel.Visible
	end

	local conteudoOvos = criar("ScrollingFrame", {
		Name = "Ovos",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = AMARELO,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 5,
		Parent = painel,
	})
	for _, lista in { conteudoOvos, conteudoPasses } do
		lista.Position = UDim2.fromOffset(16, 126)
		lista.Size = UDim2.new(1, -32, 1, -140)
	end
	criar("UIListLayout", {
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = conteudoOvos,
	})
	criar("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = conteudoOvos })

	-- aviso dos Brainrots comprados esperando vaga
	local esperando = criar("Frame", {
		LayoutOrder = 0,
		Size = UDim2.new(1, -12, 0, 40),
		BackgroundColor3 = BRANCO,
		Visible = false,
		ZIndex = 5,
		Parent = conteudoOvos,
	}, { cantos(12), borda(CONTORNO, 2.5), gradiente(Color3.fromRGB(255, 200, 70), Color3.fromRGB(230, 120, 30)) })
	local textoEsperando = texto({ Text = "", Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 1, -12), ZIndex = 6, Parent = esperando })
	local function atualizarEsperando()
		local quantos = jogador:GetAttribute("Pendentes") or 0
		esperando.Visible = quantos > 0
		textoEsperando.Text = `📦 {quantos} Brainrot(s) esperando vaga na sua base`
	end
	jogador:GetAttributeChangedSignal("Pendentes"):Connect(atualizarEsperando)
	atualizarEsperando()

	for ordem, ovo in Config.OVOS_ROBUX do
		criarCartao(conteudoOvos, ordem, ovo, ativo)
	end

	-- abas
	local abas = criar("Frame", {
		Position = UDim2.fromOffset(16, 74),
		Size = UDim2.new(1, -32, 0, 42),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = painel,
	}, { criar("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local gradientes = {}
	local function escolher(qual: ScrollingFrame)
		conteudoOvos.Visible = qual == conteudoOvos
		conteudoPasses.Visible = qual == conteudoPasses
		for lista, grad in gradientes do
			grad.Color = if lista == qual
				then ColorSequence.new(Color3.fromRGB(255, 215, 80), Color3.fromRGB(240, 130, 30))
				else ColorSequence.new(CINZA_CIMA, CINZA_BAIXO)
		end
	end
	for ordem, info in { { conteudoOvos, "🥚 OVOS ESPECIAIS" }, { conteudoPasses, "🎫 PASSES" } } do
		local b = criar("TextButton", {
			LayoutOrder = ordem,
			Size = UDim2.fromOffset(if ordem == 1 then 250 else 170, 42),
			BackgroundColor3 = BRANCO,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 6,
			Parent = abas,
		}, { cantos(14), borda(CONTORNO, 3) })
		local grad = gradiente(CINZA_CIMA, CINZA_BAIXO)
		grad.Parent = b
		gradientes[info[1]] = grad
		local escala = criar("UIScale", { Parent = b })
		texto({ Text = info[2], Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 1, -12), ZIndex = 7, Parent = b })
		b.Activated:Connect(function()
			pular(escala, 0.85)
			Sons.tocar("Clique")
			escolher(info[1])
		end)
	end
	escolher(conteudoOvos)

	-- contagem regressiva das ofertas limitadas
	task.spawn(function()
		while true do
			task.wait(1)
			if painel.Visible then
				for _, cartao in cartoes do
					atualizarCartao(cartao)
				end
			end
		end
	end)
end

function LojaOvos.iniciar()
	local evento = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Efeito") :: RemoteEvent
	evento.OnClientEvent:Connect(function(nome: string, dados)
		if nome == "OvoRobux" and typeof(dados) == "table" then
			table.insert(fila, dados)
			task.spawn(mostrarFila)
		end
	end)
end

return LojaOvos

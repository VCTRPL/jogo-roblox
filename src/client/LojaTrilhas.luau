-- Tela da loja de trilhas (a barraca no mapa): um cartão para cada trilha de
-- Config.TRILHAS, com o rastro de cores, o multiplicador da Velocidade da
-- esteira e o botão. As trilhas são compradas em ordem; as já compradas podem
-- ser equipadas. Quem compra e equipa é o servidor (Trilhas.luau).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sons = require(script.Parent.Sons)
local Ui = require(script.Parent.Ui)

local criar, cantos, borda, gradiente, texto = Ui.criar, Ui.cantos, Ui.borda, Ui.gradiente, Ui.texto
local CONTORNO = Ui.CONTORNO
local BRANCO = Ui.BRANCO
local AMARELO = Color3.fromRGB(255, 230, 120)

local LojaTrilhas = {}

local jogador = Players.LocalPlayer

type Cartao = { botao: TextButton, textoBotao: TextLabel, gradienteBotao: UIGradient, selo: TextLabel, indice: number }
local cartoes: { Cartao } = {}

local function coresDa(trilha): ColorSequence
	if trilha.arcoIris then
		local pontos = {}
		for i = 0, 6 do
			table.insert(pontos, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.8, 1)))
		end
		return ColorSequence.new(pontos)
	end
	return ColorSequence.new(trilha.cores[1], trilha.cores[2])
end

local function dinheiro(): number
	local stats = jogador:FindFirstChild("leaderstats")
	local valor = stats and stats:FindFirstChild("Dinheiro") :: IntValue?
	return if valor then valor.Value else 0
end

local function pintarBotao(cartao: Cartao, cima: Color3, baixo: Color3, textoBotao: string)
	cartao.gradienteBotao.Color = ColorSequence.new(cima, baixo)
	cartao.textoBotao.Text = textoBotao
end

local function atualizar()
	local nivel = jogador:GetAttribute("NivelTrilha") or 0
	local equipada = jogador:GetAttribute("TrilhaEquipada") or 0
	for _, cartao in cartoes do
		local trilha = Config.TRILHAS[cartao.indice]
		cartao.selo.Visible = cartao.indice == equipada
		if cartao.indice == equipada then
			pintarBotao(cartao, Color3.fromRGB(150, 150, 170), Color3.fromRGB(90, 90, 110), "EQUIPADA")
		elseif cartao.indice <= nivel then
			pintarBotao(cartao, Color3.fromRGB(120, 200, 255), Color3.fromRGB(40, 110, 230), "EQUIPAR")
		elseif cartao.indice == nivel + 1 then
			local pode = dinheiro() >= trilha.preco
			if pode then
				pintarBotao(cartao, Color3.fromRGB(120, 255, 130), Color3.fromRGB(30, 170, 70), `$ {Config.formatar(trilha.preco)}`)
			else
				pintarBotao(cartao, Color3.fromRGB(255, 120, 120), Color3.fromRGB(190, 40, 60), `$ {Config.formatar(trilha.preco)}`)
			end
		else
			pintarBotao(cartao, Color3.fromRGB(110, 104, 150), Color3.fromRGB(70, 64, 110), "🔒 " .. Config.formatar(trilha.preco))
		end
	end
end

local function criarCartao(lista: ScrollingFrame, indice: number, evento: RemoteEvent)
	local trilha = Config.TRILHAS[indice]
	local cartao = criar("Frame", {
		Name = trilha.id,
		LayoutOrder = indice,
		Size = UDim2.new(1, -12, 0, 92),
		BackgroundColor3 = BRANCO,
		ZIndex = 6,
		Parent = lista,
	}, { cantos(16), borda(CONTORNO, 3), gradiente(Color3.fromRGB(80, 72, 135), Color3.fromRGB(46, 40, 82)) })

	-- amostra do rastro: uma faixa com as cores da trilha que vai sumindo
	local amostra = criar("Frame", {
		Position = UDim2.fromOffset(12, 14),
		Size = UDim2.fromOffset(150, 64),
		BackgroundColor3 = BRANCO,
		ZIndex = 7,
		Parent = cartao,
	}, { cantos(14), borda(CONTORNO, 3) })
	criar("UIGradient", {
		Color = coresDa(trilha),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.75, 0.15),
			NumberSequenceKeypoint.new(1, 0.8),
		}),
		Parent = amostra,
	})
	texto({
		Text = `x{trilha.multiplicador}`,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
		Parent = amostra,
	})

	texto({
		Text = trilha.nome,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(176, 12),
		Size = UDim2.new(1, -360, 0, 36),
		ZIndex = 7,
		Parent = cartao,
	})
	texto({
		Text = `⚡ Velocidade da esteira x{trilha.multiplicador}`,
		TextColor3 = AMARELO,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(176, 50),
		Size = UDim2.new(1, -360, 0, 26),
		ZIndex = 7,
		Parent = cartao,
	})
	local selo = texto({
		Text = "✔ USANDO",
		TextColor3 = Color3.fromRGB(140, 255, 150),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 4),
		Size = UDim2.fromOffset(150, 20),
		Visible = false,
		ZIndex = 8,
		Parent = cartao,
	})

	local botao = criar("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 6),
		Size = UDim2.fromOffset(160, 50),
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = BRANCO,
		ZIndex = 7,
		Parent = cartao,
	}, { cantos(14), borda(CONTORNO, 3) })
	local gradienteBotao = gradiente(BRANCO, BRANCO)
	gradienteBotao.Parent = botao
	local textoBotao = texto({ Text = "", Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 1, -12), ZIndex = 8, Parent = botao })

	local dados: Cartao = {
		botao = botao,
		textoBotao = textoBotao,
		gradienteBotao = gradienteBotao,
		selo = selo,
		indice = indice,
	}
	table.insert(cartoes, dados)

	botao.Activated:Connect(function()
		local nivel = jogador:GetAttribute("NivelTrilha") or 0
		if indice <= nivel then
			evento:FireServer("equipar", indice)
		elseif indice == nivel + 1 then
			evento:FireServer("comprar", indice)
		else
			Sons.tocar("Erro")
			return
		end
		Sons.tocar("Clique")
	end)
end

-- Monta a lista dentro do painel que a Interface cria.
function LojaTrilhas.montar(conteudo: ScrollingFrame)
	local evento = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Trilhas") :: RemoteEvent
	criar("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = conteudo })
	criar("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), Parent = conteudo })
	texto({
		Text = "A melhor trilha que você tem multiplica a Velocidade da esteira. Use a que achar mais bonita!",
		TextColor3 = AMARELO,
		LayoutOrder = 0,
		Size = UDim2.new(1, -12, 0, 40),
		ZIndex = 6,
		Parent = conteudo,
	})
	for indice in Config.TRILHAS do
		criarCartao(conteudo, indice, evento)
	end
	jogador:GetAttributeChangedSignal("NivelTrilha"):Connect(atualizar)
	jogador:GetAttributeChangedSignal("TrilhaEquipada"):Connect(atualizar)
	task.spawn(function()
		local valor = jogador:WaitForChild("leaderstats"):WaitForChild("Dinheiro") :: IntValue
		valor.Changed:Connect(atualizar)
		atualizar()
	end)
	atualizar()
end

return LojaTrilhas

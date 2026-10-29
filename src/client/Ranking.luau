-- Painel do Ranking: abas "Servidor" (quem está aqui agora) e "Global"
-- (todo mundo, quando o jogo está publicado), uma categoria por vez, com
-- posição, avatar, nome e o número. O 1º, o 2º e o 3º ganham medalha e borda
-- de ouro, prata e bronze. Os números vêm prontos do servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Sons = require(script.Parent.Sons)
local Ui = require(script.Parent.Ui)

local criar, cantos, borda, gradiente, texto, pular = Ui.criar, Ui.cantos, Ui.borda, Ui.gradiente, Ui.texto, Ui.pular
local CONTORNO = Ui.CONTORNO
local BRANCO = Ui.BRANCO
local AMARELO = Color3.fromRGB(255, 230, 120)
local CINZA_CIMA = Color3.fromRGB(110, 104, 150)
local CINZA_BAIXO = Color3.fromRGB(70, 64, 110)

-- Ouro, prata e bronze.
local PODIO = {
	{ medalha = "🥇", cor = Color3.fromRGB(255, 205, 50), cima = Color3.fromRGB(120, 95, 30), baixo = Color3.fromRGB(70, 50, 20) },
	{ medalha = "🥈", cor = Color3.fromRGB(215, 225, 240), cima = Color3.fromRGB(95, 100, 125), baixo = Color3.fromRGB(55, 58, 80) },
	{ medalha = "🥉", cor = Color3.fromRGB(235, 140, 70), cima = Color3.fromRGB(110, 70, 45), baixo = Color3.fromRGB(65, 40, 30) },
}

local Ranking = {}

local jogador = Players.LocalPlayer
local CATEGORIAS = Config.RANKING.categorias

local aba = "servidor"
local categoria = CATEGORIAS[1].chave
local dados: any = nil
local painel: Frame
local lista: ScrollingFrame
local rodape: TextLabel
local aviso: TextLabel
local botoesAba: { [string]: { gradiente: UIGradient } } = {}
local botoesCategoria: { [string]: { gradiente: UIGradient, borda: UIStroke } } = {}

local function formatar(valor: number): string
	local def = Config.categoriaRanking(categoria)
	return if def and def.dinheiro then `${Config.formatar(valor)}` else Config.formatar(valor)
end

local function botaoPilula(props: { [string]: any }, rotulo: string, aoClicar: () -> ()): (TextButton, UIGradient, UIStroke)
	local b = criar("TextButton", {
		BackgroundColor3 = BRANCO,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
	})
	for chave, valor in props do
		(b :: any)[chave] = valor
	end
	cantos(14).Parent = b
	local contorno = borda(CONTORNO, 3)
	contorno.Parent = b
	local grad = gradiente(CINZA_CIMA, CINZA_BAIXO)
	grad.Parent = b
	local escala = criar("UIScale", { Parent = b })
	texto({ Text = rotulo, Position = UDim2.fromOffset(8, 5), Size = UDim2.new(1, -16, 1, -10), ZIndex = 7, Parent = b })
	b.Activated:Connect(function()
		pular(escala, 0.85)
		Sons.tocar("Clique")
		aoClicar()
	end)
	return b, grad, contorno
end

local function limparLista()
	for _, filho in lista:GetChildren() do
		if filho:IsA("GuiObject") then
			filho:Destroy()
		end
	end
end

local function linha(ordem: number, item: { id: number, nome: string, valor: number })
	local podio = PODIO[ordem]
	local eu = item.id == jogador.UserId
	local altura = if podio then 64 else 54
	local quadro = criar("Frame", {
		LayoutOrder = ordem,
		Size = UDim2.new(1, -12, 0, altura),
		BackgroundColor3 = BRANCO,
		ZIndex = 5,
		Parent = lista,
	}, {
		cantos(14),
		borda(if eu then Color3.fromRGB(90, 230, 255) elseif podio then podio.cor else CONTORNO, if podio or eu then 3.5 else 2.5),
		gradiente(
			if podio then podio.cima else Color3.fromRGB(62, 56, 108),
			if podio then podio.baixo else Color3.fromRGB(40, 35, 75)
		),
	})
	-- brilho de plástico em cima
	criar("Frame", {
		Position = UDim2.fromOffset(6, 3),
		Size = UDim2.new(1, -12, 0.3, 0),
		BackgroundColor3 = BRANCO,
		BackgroundTransparency = 0.88,
		ZIndex = 5,
		Parent = quadro,
	}, { cantos(10) })
	-- posição
	local selo = criar("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(altura - 14, altura - 14),
		BackgroundColor3 = if podio then podio.cor else Color3.fromRGB(30, 26, 55),
		ZIndex = 6,
		Parent = quadro,
	}, { cantos(100), borda(CONTORNO, 2.5) })
	texto({
		Text = if podio then podio.medalha else `#{ordem}`,
		Position = UDim2.fromScale(0.12, 0.12),
		Size = UDim2.fromScale(0.76, 0.76),
		ZIndex = 7,
		Parent = selo,
	})
	-- avatar
	local tamanhoAvatar = altura - 12
	criar("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, altura + 2, 0.5, 0),
		Size = UDim2.fromOffset(tamanhoAvatar, tamanhoAvatar),
		BackgroundColor3 = Color3.fromRGB(200, 205, 230),
		Image = `rbxthumb://type=AvatarHeadShot&id={item.id}&w=150&h=150`,
		ZIndex = 6,
		Parent = quadro,
	}, { cantos(12), borda(CONTORNO, 2.5) })
	local inicioNome = altura + tamanhoAvatar + 12
	texto({
		Text = if eu then `{item.nome} (você)` else item.nome,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = if podio then podio.cor else BRANCO,
		Position = UDim2.new(0, inicioNome, 0.5, -15),
		Size = UDim2.new(0.62, -inicioNome, 0, 30),
		ZIndex = 6,
		Parent = quadro,
	})
	texto({
		Text = formatar(item.valor),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = if Config.categoriaRanking(categoria).dinheiro then Color3.fromRGB(130, 255, 130) else AMARELO,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0.36, 0, 0, 32),
		ZIndex = 6,
		Parent = quadro,
	})
end

local function desenhar()
	for chave, b in botoesAba do
		b.gradiente.Color = if chave == aba
			then ColorSequence.new(Color3.fromRGB(255, 215, 80), Color3.fromRGB(240, 130, 30))
			else ColorSequence.new(CINZA_CIMA, CINZA_BAIXO)
	end
	for chave, b in botoesCategoria do
		local ativa = chave == categoria
		b.gradiente.Color = if ativa
			then ColorSequence.new(Color3.fromRGB(130, 220, 255), Color3.fromRGB(50, 110, 230))
			else ColorSequence.new(CINZA_CIMA, CINZA_BAIXO)
		b.borda.Color = if ativa then BRANCO else CONTORNO
	end

	limparLista()
	aviso.Visible = false
	local def = Config.categoriaRanking(categoria)
	if not dados then
		aviso.Text = "Carregando o ranking..."
		aviso.Visible = true
		rodape.Text = def.descricao
		return
	end

	local itens = nil
	if aba == "servidor" then
		itens = dados.servidor and dados.servidor[categoria] or {}
	else
		itens = dados.global and dados.global[categoria]
		if not itens then
			-- sem ranking global: só a mensagem, nunca o do servidor no lugar
			aviso.Text = `🌍 {dados.globalErro or "Ranking global indisponível agora."}`
			aviso.Visible = true
			rodape.Text = `{def.icone} {def.descricao}`
			return
		end
	end

	local minhaPosicao, meuValor = nil, nil
	for posicao, item in itens do
		if item.id == jogador.UserId then
			minhaPosicao, meuValor = posicao, item.valor
		end
		if posicao <= Config.RANKING.quantos then
			linha(posicao, item)
		end
	end
	if #itens == 0 then
		aviso.Text = "Ninguém no ranking ainda. Seja o primeiro!"
		aviso.Visible = true
	end

	if aba == "servidor" then
		rodape.Text = if minhaPosicao
			then `{def.icone} {def.descricao} • Você: #{minhaPosicao} de {#itens} ({formatar(meuValor)})`
			else `{def.icone} {def.descricao}`
	else
		local minutos = math.max(0, math.floor(((dados.agora or 0) - (dados.globalEm or 0)) / 60))
		local quando = if minutos < 1 then "agora há pouco" else `há {minutos} min`
		local onde = if minhaPosicao then `Você: #{minhaPosicao}!` else `Entre no top {Config.RANKING.quantos}!`
		rodape.Text = `🌍 {def.descricao} • {onde} • Atualizado {quando}`
		if dados.globalErro then
			rodape.Text ..= " ⚠️"
		end
	end
end

local buscando = false
local function buscar()
	if buscando then
		return
	end
	buscando = true
	local remoto = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Ranking", 10)
	if remoto then
		local ok, resposta = pcall(function()
			return (remoto :: RemoteFunction):InvokeServer()
		end)
		if ok and resposta then
			dados = resposta
		end
	end
	buscando = false
	if painel.Visible then
		desenhar()
	end
end

-- Monta o conteúdo dentro de um painel criado pela Interface.
function Ranking.montar(novoPainel: Frame, conteudo: ScrollingFrame)
	painel = novoPainel
	lista = conteudo
	painel.Size = UDim2.fromOffset(660, 540)

	local abas = criar("Frame", {
		Position = UDim2.fromOffset(16, 74),
		Size = UDim2.new(1, -32, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = painel,
	}, { criar("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
	for ordem, info in { { "servidor", "🏠 SERVIDOR" }, { "global", "🌍 GLOBAL" } } do
		local _, grad = botaoPilula({ LayoutOrder = ordem, Size = UDim2.fromOffset(180, 40), Parent = abas }, info[2], function()
			aba = info[1]
			desenhar()
		end)
		botoesAba[info[1]] = { gradiente = grad }
	end

	local categorias = criar("Frame", {
		Position = UDim2.fromOffset(16, 124),
		Size = UDim2.new(1, -32, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = painel,
	}, { criar("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	for ordem, def in CATEGORIAS do
		local largura = (628 - 8 * (#CATEGORIAS - 1)) / #CATEGORIAS
		local _, grad, contorno = botaoPilula({ LayoutOrder = ordem, Size = UDim2.fromOffset(largura, 40), Parent = categorias }, `{def.icone} {def.nome}`, function()
			categoria = def.chave
			desenhar()
		end)
		botoesCategoria[def.chave] = { gradiente = grad, borda = contorno }
	end

	lista.Position = UDim2.fromOffset(16, 176)
	lista.Size = UDim2.new(1, -32, 1, -232)
	criar("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = lista,
	})
	criar("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = lista })

	aviso = texto({
		Text = "",
		TextScaled = false,
		TextSize = 24,
		TextWrapped = true,
		Position = UDim2.fromOffset(40, 220),
		Size = UDim2.new(1, -80, 0, 120),
		Visible = false,
		ZIndex = 6,
		Parent = painel,
	})
	local barraRodape = criar("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -32, 0, 38),
		BackgroundColor3 = BRANCO,
		ZIndex = 5,
		Parent = painel,
	}, { cantos(12), borda(CONTORNO, 2.5), gradiente(Color3.fromRGB(30, 26, 55), Color3.fromRGB(20, 17, 40)) })
	rodape = texto({
		Text = "",
		TextColor3 = AMARELO,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -20, 1, -12),
		ZIndex = 6,
		Parent = barraRodape,
	})
	desenhar()

	-- enquanto o painel está aberto, atualiza junto com o servidor
	local aberturas = 0
	painel:GetPropertyChangedSignal("Visible"):Connect(function()
		if not painel.Visible then
			return
		end
		aberturas += 1
		local esta = aberturas
		desenhar()
		task.spawn(buscar)
		task.spawn(function()
			while painel.Visible and aberturas == esta do
				task.wait(Config.RANKING.servidorSegundos)
				if painel.Visible and aberturas == esta then
					buscar()
				end
			end
		end)
	end)
end

return Ranking

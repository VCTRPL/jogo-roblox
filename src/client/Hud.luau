-- Tela do jogador: painel com Dinheiro, Velocidade e Roubos, avisos que
-- pulam na tela e o anúncio grande quando alguém choca um raro.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Hud = {}

local jogador = Players.LocalPlayer
local FONTE = Enum.Font.FredokaOne
local CONTORNO = Color3.fromRGB(25, 20, 45)
local BRANCO = Color3.new(1, 1, 1)

local function criar(classe: string, props: { [string]: any }, filhos: { Instance }?): any
	local objeto = Instance.new(classe)
	for chave, valor in props do
		if chave ~= "Parent" then
			(objeto :: any)[chave] = valor
		end
	end
	if filhos then
		for _, filho in filhos do
			filho.Parent = objeto
		end
	end
	objeto.Parent = props.Parent
	return objeto
end

local function cantos(raio: number): UICorner
	return criar("UICorner", { CornerRadius = UDim.new(0, raio) })
end

local function borda(cor: Color3, grossura: number): UIStroke
	return criar("UIStroke", {
		Color = cor,
		Thickness = grossura,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function gradiente(cima: Color3, baixo: Color3): UIGradient
	return criar("UIGradient", {
		Color = ColorSequence.new(cima, baixo),
		Rotation = 90,
	})
end

-- Texto grande com contorno escuro, o estilo de todos os textos da tela.
local function texto(props: { [string]: any }): TextLabel
	local label = criar("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONTE,
		TextColor3 = BRANCO,
		TextScaled = true,
		TextStrokeColor3 = CONTORNO,
		TextStrokeTransparency = 0,
	})
	for chave, valor in props do
		if chave ~= "Parent" then
			(label :: any)[chave] = valor
		end
	end
	label.Parent = props.Parent
	return label
end

local function pular(escala: UIScale, ate: number)
	escala.Scale = ate
	TweenService:Create(escala, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local tela: ScreenGui = criar("ScreenGui", {
	Name = "Hud",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = jogador:WaitForChild("PlayerGui"),
})

-- Em telas pequenas (celular) tudo fica um pouco menor.
local escalaTela: UIScale = criar("UIScale", { Parent = tela })
local function ajustarEscala()
	local camera = Workspace.CurrentCamera
	if camera then
		escalaTela.Scale = math.clamp(camera.ViewportSize.Y / 820, 0.6, 1.15)
	end
end
ajustarEscala()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala)
end

-- Painel de status -----------------------------------------------------------

local painel = criar("Frame", {
	Name = "Painel",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.45, 0),
	Size = UDim2.fromOffset(250, 230),
	BackgroundTransparency = 1,
	Parent = tela,
}, {
	criar("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})

type Cartao = {
	quadro: Frame,
	valor: TextLabel,
	legenda: TextLabel,
	escala: UIScale,
	mostrado: number,
	contador: NumberValue,
}

local function criarCartao(nome: string, ordem: number, icone: string, cima: Color3, baixo: Color3, legenda: string): Cartao
	local quadro = criar("Frame", {
		Name = nome,
		LayoutOrder = ordem,
		Size = UDim2.fromOffset(240, 66),
		BackgroundColor3 = BRANCO,
		Parent = painel,
	}, {
		cantos(16),
		borda(CONTORNO, 3.5),
		gradiente(cima, baixo),
	})
	local escala = criar("UIScale", { Parent = quadro })

	-- brilho em cima do cartão, para parecer um botão de plástico
	criar("Frame", {
		Name = "Brilho",
		Position = UDim2.fromOffset(6, 4),
		Size = UDim2.new(1, -12, 0.35, 0),
		BackgroundColor3 = BRANCO,
		BackgroundTransparency = 0.75,
		Parent = quadro,
	}, { cantos(12) })

	local bolinha = criar("Frame", {
		Name = "Icone",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -10, 0.5, 0),
		Size = UDim2.fromOffset(62, 62),
		BackgroundColor3 = BRANCO,
		Parent = quadro,
	}, {
		cantos(31),
		borda(CONTORNO, 3.5),
		gradiente(baixo:Lerp(BRANCO, 0.35), baixo),
	})
	texto({ Text = icone, Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Parent = bolinha })

	local valor = texto({
		Name = "Valor",
		Text = "0",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(60, 4),
		Size = UDim2.new(1, -68, 0.62, 0),
		Parent = quadro,
	})
	local textoLegenda = texto({
		Name = "Legenda",
		Text = legenda,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 255, 220),
		Position = UDim2.new(0, 61, 0.62, -2),
		Size = UDim2.new(1, -68, 0.3, 0),
		Parent = quadro,
	})

	return {
		quadro = quadro,
		valor = valor,
		legenda = textoLegenda,
		escala = escala,
		mostrado = 0,
		contador = Instance.new("NumberValue"),
	}
end

local cartaoDinheiro = criarCartao("Dinheiro", 1, "💰", Color3.fromRGB(120, 255, 110), Color3.fromRGB(30, 170, 60), "+$0/s")
local cartaoVelocidade = criarCartao("Velocidade", 2, "⚡", Color3.fromRGB(110, 210, 255), Color3.fromRGB(40, 100, 230), "Velocidade")
local cartaoRoubos = criarCartao("Roubos", 3, "😈", Color3.fromRGB(255, 130, 200), Color3.fromRGB(170, 50, 200), "Roubos")

-- "+$30" que sobe e some ao lado do cartão
local function subirTexto(cartao: Cartao, conteudo: string, cor: Color3)
	local label = texto({
		Text = conteudo,
		TextColor3 = cor,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 10, 0.5, 0),
		Size = UDim2.fromOffset(130, 34),
		TextXAlignment = Enum.TextXAlignment.Left,
		Rotation = math.random(-8, 8),
		Parent = cartao.quadro,
	})
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, {
		Position = UDim2.new(1, 18, 0.5, -46),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(0.9, label.Destroy, label)
end

local function ligarCartao(cartao: Cartao, nome: string, prefixo: string, corGanho: Color3)
	local stats = jogador:WaitForChild("leaderstats")
	local valor = stats:WaitForChild(nome) :: IntValue

	cartao.contador.Changed:Connect(function(numero)
		cartao.valor.Text = prefixo .. Config.formatar(numero)
	end)
	local ultimoTexto = 0
	local function atualizar()
		local novo = valor.Value
		local diferenca = novo - cartao.mostrado
		cartao.mostrado = novo
		-- conta até o número novo em vez de pular direto
		TweenService:Create(cartao.contador, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Value = novo }):Play()
		if diferenca > 0 then
			pular(cartao.escala, 1.08)
			if os.clock() - ultimoTexto > 0.2 then
				ultimoTexto = os.clock()
				subirTexto(cartao, `+{prefixo}{Config.formatar(diferenca)}`, corGanho)
			end
		end
	end
	cartao.mostrado = valor.Value
	cartao.contador.Value = valor.Value
	cartao.valor.Text = prefixo .. Config.formatar(valor.Value)
	valor.Changed:Connect(atualizar)
end

task.spawn(ligarCartao, cartaoDinheiro, "Dinheiro", "$", Color3.fromRGB(120, 255, 120))
task.spawn(ligarCartao, cartaoVelocidade, "Velocidade", "", Color3.fromRGB(120, 220, 255))
task.spawn(ligarCartao, cartaoRoubos, "Roubos", "", Color3.fromRGB(255, 140, 220))

local function atualizarRenda()
	local renda = jogador:GetAttribute("Renda") or 0
	cartaoDinheiro.legenda.Text = `+${Config.formatar(renda)}/s`
end
jogador:GetAttributeChangedSignal("Renda"):Connect(atualizarRenda)
atualizarRenda()

-- Avisos ---------------------------------------------------------------------

local listaAvisos = criar("Frame", {
	Name = "Avisos",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 96),
	Size = UDim2.new(0.8, 0, 0, 200),
	BackgroundTransparency = 1,
	Parent = tela,
}, {
	criar("UIListLayout", {
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local MAXIMO_AVISOS = 4
local contagemAvisos = 0
local avisosAbertos: { { quadro: Frame, texto: string, fecharEm: number, escala: UIScale } } = {}

local function fecharAviso(aviso)
	local i = table.find(avisosAbertos, aviso)
	if i then
		table.remove(avisosAbertos, i)
	end
	local info = TweenInfo.new(0.3)
	for _, objeto in aviso.quadro:GetDescendants() do
		if objeto:IsA("TextLabel") then
			TweenService:Create(objeto, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		elseif objeto:IsA("UIStroke") then
			TweenService:Create(objeto, info, { Transparency = 1 }):Play()
		end
	end
	TweenService:Create(aviso.quadro, info, { BackgroundTransparency = 1 }):Play()
	task.delay(0.3, aviso.quadro.Destroy, aviso.quadro)
end

local function mostrarAviso(mensagem: string, cor: Color3)
	-- o mesmo aviso de novo só pula e fica mais tempo
	for _, aviso in avisosAbertos do
		if aviso.texto == mensagem then
			aviso.fecharEm = os.clock() + 3
			pular(aviso.escala, 1.12)
			return
		end
	end

	contagemAvisos += 1
	local quadro = criar("Frame", {
		LayoutOrder = -contagemAvisos, -- o mais novo fica em cima
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 42),
		BackgroundColor3 = Color3.fromRGB(20, 18, 35),
		BackgroundTransparency = 0.2,
		Parent = listaAvisos,
	}, {
		cantos(12),
		borda(cor, 3),
		criar("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	texto({
		Text = mensagem,
		TextColor3 = cor,
		TextScaled = false,
		TextSize = 24,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		Parent = quadro,
	})
	local escala = criar("UIScale", { Parent = quadro })
	pular(escala, 0.4)

	local aviso = { quadro = quadro, texto = mensagem, fecharEm = os.clock() + 3, escala = escala }
	table.insert(avisosAbertos, aviso)
	if #avisosAbertos > MAXIMO_AVISOS then
		fecharAviso(avisosAbertos[1])
	end
end

RunService.Heartbeat:Connect(function()
	local agora = os.clock()
	for i = #avisosAbertos, 1, -1 do
		local aviso = avisosAbertos[i]
		if agora >= aviso.fecharEm then
			fecharAviso(aviso)
		end
	end
end)

-- Anúncio para o servidor inteiro ---------------------------------------------

local ARCO_IRIS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 90)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 170, 40)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 60)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(70, 230, 110)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(70, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
})

local faixa = criar("Frame", {
	Name = "Anuncio",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, -120),
	Size = UDim2.new(0.75, 0, 0, 74),
	BackgroundColor3 = BRANCO,
	Visible = false,
	Parent = tela,
}, {
	cantos(18),
	criar("UISizeConstraint", { MaxSize = Vector2.new(820, 74) }),
})
local gradienteFaixa = criar("UIGradient", { Color = ARCO_IRIS, Parent = faixa })
local bordaFaixa = borda(BRANCO, 4)
bordaFaixa.Parent = faixa
local textoFaixa = texto({
	Size = UDim2.new(1, -24, 1, -12),
	Position = UDim2.fromOffset(12, 6),
	Parent = faixa,
})
local fimAnuncio = 0

local function mostrarAnuncio(mensagem: string, cor: Color3)
	textoFaixa.Text = `🌟 {mensagem} 🌟`
	bordaFaixa.Color = cor
	faixa.Visible = true
	fimAnuncio = os.clock() + 5
	TweenService:Create(faixa, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 12),
	}):Play()
end

RunService.RenderStepped:Connect(function()
	if not faixa.Visible then
		return
	end
	local agora = os.clock()
	-- o arco-íris anda e a borda pisca
	gradienteFaixa.Offset = Vector2.new(math.sin(agora * 2) * 0.35, 0)
	bordaFaixa.Thickness = 4 + math.sin(agora * 10) * 1.5
	if agora >= fimAnuncio and fimAnuncio > 0 then
		fimAnuncio = 0
		local saida = TweenService:Create(faixa, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -120),
		})
		saida.Completed:Connect(function()
			if fimAnuncio == 0 then
				faixa.Visible = false
			end
		end)
		saida:Play()
	end
end)

function Hud.iniciar()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local eventoAviso = remotes:WaitForChild("Aviso") :: RemoteEvent
	eventoAviso.OnClientEvent:Connect(function(mensagem: string, cor: Color3, tipo: string?)
		if tipo == "anuncio" then
			mostrarAnuncio(mensagem, cor)
		else
			mostrarAviso(mensagem, cor)
		end
	end)
end

return Hud

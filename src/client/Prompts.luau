-- Botões dos ProximityPrompts ("Pegar", "Roubar", "Melhorar esteira"...)
-- no estilo do jogo: tecla num quadrado colorido que enche enquanto você
-- segura, e o texto do lado. No celular dá para tocar no botão.
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Icones = require(script.Parent.Icones)
local Ui = require(script.Parent.Ui)

local criar, cantos, borda, gradiente, texto, pular = Ui.criar, Ui.cantos, Ui.borda, Ui.gradiente, Ui.texto, Ui.pular
local CONTORNO = Ui.CONTORNO
local BRANCO = Ui.BRANCO

local Prompts = {}

-- Cor do botão pela palavra da ação.
local CORES = {
	{ "Roubar", Color3.fromRGB(255, 90, 90), Color3.fromRGB(200, 30, 50) },
	{ "Melhorar", Color3.fromRGB(255, 215, 80), Color3.fromRGB(235, 140, 30) },
	{ "Trancar", Color3.fromRGB(255, 170, 80), Color3.fromRGB(220, 90, 30) },
	{ "Vender", Color3.fromRGB(255, 235, 110), Color3.fromRGB(60, 190, 80) },
}
local PADRAO = { "", Color3.fromRGB(120, 240, 130), Color3.fromRGB(30, 165, 80) }
-- Ações com ícone (o nome do desenho em Icones.luau é a palavra da ação).
local ICONES = { "Melhorar", "Trancar" }

local function coresDa(acao: string)
	for _, cor in CORES do
		if string.find(acao, cor[1], 1, true) then
			return cor
		end
	end
	return PADRAO
end

local function nomeDaTecla(prompt: ProximityPrompt, entrada: Enum.ProximityPromptInputType): string
	if entrada == Enum.ProximityPromptInputType.Touch then
		return "👆"
	elseif entrada == Enum.ProximityPromptInputType.Gamepad then
		return (string.gsub(prompt.GamepadKeyCode.Name, "Button", ""))
	end
	return UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
end

local tela = Ui.tela("Prompts", 2)

local function mostrar(prompt: ProximityPrompt, entrada: Enum.ProximityPromptInputType)
	local adorno = prompt.Parent
	if not (adorno and (adorno:IsA("BasePart") or adorno:IsA("Attachment") or adorno:IsA("Model"))) then
		return
	end
	local cor = coresDa(prompt.ActionText)

	local gui = criar("BillboardGui", {
		Name = "Prompt",
		Adornee = adorno,
		AlwaysOnTop = true,
		Active = true,
		Size = UDim2.fromOffset(260, 74),
		StudsOffset = Vector3.new(0, 0.5, 0),
		Parent = tela,
	})
	local escala = criar("UIScale", { Parent = gui })

	-- tecla: quadrado que enche de baixo para cima enquanto segura
	local tecla = criar("Frame", {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(66, 66),
		BackgroundColor3 = Color3.fromRGB(30, 26, 55),
		ClipsDescendants = true,
		Parent = gui,
	}, { cantos(16), borda(CONTORNO, 3.5) })
	local enchimento = criar("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, if prompt.HoldDuration > 0 then 0 else 1),
		BackgroundColor3 = BRANCO,
		BorderSizePixel = 0,
		Parent = tecla,
	}, { gradiente(cor[2], cor[3]) })
	texto({ Text = nomeDaTecla(prompt, entrada), Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), ZIndex = 2, Parent = tecla })

	-- texto da ação
	local caixa = criar("Frame", {
		Position = UDim2.fromOffset(78, 10),
		Size = UDim2.new(1, -82, 0, 54),
		BackgroundColor3 = BRANCO,
		Parent = gui,
	}, { cantos(14), borda(CONTORNO, 3), gradiente(Color3.fromRGB(70, 62, 120), Color3.fromRGB(36, 30, 66)) })
	local temObjeto = prompt.ObjectText ~= ""
	-- ícone no canto (Icones.luau), para as ações que têm
	local icone = nil
	for _, nome in ICONES do
		if string.find(prompt.ActionText, nome, 1, true) then
			icone = nome
		end
	end
	local folga = if icone then 64 else 20
	if icone then
		Icones.criar(icone, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(42, 42),
			Parent = caixa,
		})
	end
	texto({
		Text = prompt.ActionText,
		TextColor3 = cor[2],
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(12, if temObjeto then 3 else 9),
		Size = UDim2.new(1, -folga, 0, if temObjeto then 28 else 36),
		Parent = caixa,
	})
	if temObjeto then
		texto({
			Text = prompt.ObjectText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(12, 30),
			Size = UDim2.new(1, -folga, 0, 20),
			Parent = caixa,
		})
	end

	-- toque e clique seguram o botão como a tecla
	local botao = criar("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 5,
		Parent = gui,
	})
	botao.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldBegin()
		end
	end)
	botao.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end)

	local conexoes = {}
	local enchendo: Tween? = nil
	table.insert(conexoes, prompt.PromptButtonHoldBegan:Connect(function()
		if prompt.HoldDuration > 0 then
			local tween = TweenService:Create(enchimento, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
			tween:Play()
			enchendo = tween
		end
	end))
	table.insert(conexoes, prompt.PromptButtonHoldEnded:Connect(function()
		if enchendo then
			enchendo:Cancel()
		end
		if prompt.HoldDuration > 0 then
			enchimento.Size = UDim2.fromScale(1, 0)
		end
	end))
	table.insert(conexoes, prompt.Triggered:Connect(function()
		pular(escala, 1.25)
	end))

	escala.Scale = 0.3
	TweenService:Create(escala, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	prompt.PromptHidden:Once(function()
		for _, conexao in conexoes do
			conexao:Disconnect()
		end
		local saida = TweenService:Create(escala, TweenInfo.new(0.15), { Scale = 0 })
		saida.Completed:Connect(function()
			gui:Destroy()
		end)
		saida:Play()
	end)
end

-- Todo prompt vira "Custom" neste computador para usar o botão de cima.
function Prompts.estilizar(prompt: ProximityPrompt)
	prompt.Style = Enum.ProximityPromptStyle.Custom
end

function Prompts.iniciar()
	ProximityPromptService.PromptShown:Connect(function(prompt, entrada)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			mostrar(prompt, entrada)
		end
	end)
end

return Prompts

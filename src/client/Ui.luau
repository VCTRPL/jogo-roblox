-- Peças de interface usadas por todas as telas: o mesmo estilo de desenho
-- (cantos redondos, contorno escuro grosso, gradiente e texto com contorno).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Ui = {}

Ui.FONTE = Enum.Font.FredokaOne
Ui.CONTORNO = Color3.fromRGB(25, 20, 45)
Ui.BRANCO = Color3.new(1, 1, 1)

function Ui.criar(classe: string, props: { [string]: any }, filhos: { Instance }?): any
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

function Ui.cantos(raio: number): UICorner
	return Ui.criar("UICorner", { CornerRadius = UDim.new(0, raio) })
end

function Ui.borda(cor: Color3, grossura: number): UIStroke
	return Ui.criar("UIStroke", {
		Color = cor,
		Thickness = grossura,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Ui.gradiente(cima: Color3, baixo: Color3): UIGradient
	return Ui.criar("UIGradient", {
		Color = ColorSequence.new(cima, baixo),
		Rotation = 90,
	})
end

-- Texto grande com contorno escuro, o estilo de todos os textos da tela.
function Ui.texto(props: { [string]: any }): TextLabel
	local label = Ui.criar("TextLabel", {
		BackgroundTransparency = 1,
		Font = Ui.FONTE,
		TextColor3 = Ui.BRANCO,
		TextScaled = true,
		TextStrokeColor3 = Ui.CONTORNO,
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

-- Ícones de blocos Lego feitos no ForgeGUI (arte/gui). Quem não tem imagem
-- aqui continua usando o emoji.
Ui.IMAGENS = {
	Dinheiro = "rbxassetid://130947068605662",
	Velocidade = "rbxassetid://93729721093398",
	Roubos = "rbxassetid://79422839232555",
	["Índice"] = "rbxassetid://131760784198257",
	Ajuda = "rbxassetid://101323235798081",
} :: { [string]: string }

-- Botões do menu da direita inteiros (moldura, ícone e nome), gerados com
-- IA e recortados em arte/gui/botoes. Quem tem imagem aqui não desenha a
-- moldura por código (veja Interface.luau).
Ui.BOTOES = {
	["Índice"] = "rbxassetid://95103673286782",
	Ajuda = "rbxassetid://118805225301399",
	Ranking = "rbxassetid://104103890074746",
	Renascer = "rbxassetid://88622449692239",
	Loja = "rbxassetid://100609958700586",
	Som = "rbxassetid://83906082992387",
} :: { [string]: string }

-- Ícone com a imagem de "nome"; se não tiver, o desenhado em Icones.luau;
-- se nem isso, o emoji como texto.
function Ui.icone(nome: string, emoji: string, props: { [string]: any }): GuiObject
	local imagem = Ui.IMAGENS[nome]
	-- carregado aqui dentro porque o Icones usa o Ui
	local Icones = require(script.Parent.Icones) :: any
	if not imagem and Icones.tem(nome) then
		return Icones.criar(nome, props)
	end
	if not imagem then
		props.Text = emoji
		return Ui.texto(props)
	end
	local icone = Ui.criar("ImageLabel", {
		BackgroundTransparency = 1,
		Image = imagem,
		ScaleType = Enum.ScaleType.Fit,
	})
	for chave, valor in props do
		if chave ~= "Parent" then
			(icone :: any)[chave] = valor
		end
	end
	icone.Parent = props.Parent
	return icone
end

function Ui.pular(escala: UIScale, ate: number)
	escala.Scale = ate
	TweenService:Create(escala, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- ScreenGui que não some quando o personagem morre e fica um pouco menor
-- em telas pequenas (celular).
function Ui.tela(nome: string, ordem: number?): ScreenGui
	local tela = Ui.criar("ScreenGui", {
		Name = nome,
		ResetOnSpawn = false,
		DisplayOrder = ordem or 0,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	local escala = Ui.criar("UIScale", { Parent = tela })
	local function ajustar()
		local camera = Workspace.CurrentCamera
		if camera then
			escala.Scale = math.clamp(camera.ViewportSize.Y / 820, 0.6, 1.15)
		end
	end
	ajustar()
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar)
	end
	return tela
end

return Ui

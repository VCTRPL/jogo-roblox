-- Painéis flutuantes no estilo das telas do jogo (cantos redondos, contorno
-- escuro grosso, gradiente e texto com contorno): ícone à esquerda, título,
-- uma linha de texto e uma barra embaixo. Usados no botão de trancar, na
-- esteira e na loja de trilhas. O tamanho é em studs, como as outras placas.
local Paineis = {}

local CONTORNO = Color3.fromRGB(25, 20, 45)
local FONTE = Enum.Font.FredokaOne

export type Painel = {
	gui: BillboardGui,
	fundo: Frame,
	gradiente: UIGradient,
	icone: TextLabel,
	titulo: TextLabel,
	linha: TextLabel,
	barra: Frame,
	enchimento: Frame,
}

local function novo(classe: string, props: { [string]: any }, parent: Instance): any
	local objeto = Instance.new(classe)
	for chave, valor in props do
		(objeto :: any)[chave] = valor
	end
	objeto.Parent = parent
	return objeto
end

local function texto(props: { [string]: any }, parent: Instance): TextLabel
	props.BackgroundTransparency = 1
	props.Font = FONTE
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextStrokeColor3 = CONTORNO
	props.TextStrokeTransparency = 0
	return novo("TextLabel", props, parent)
end

-- opcoes: altura (studs acima da peça), largura e alto (tamanho em studs),
-- cores { cima, baixo } e distancia (até onde aparece).
function Paineis.criar(parent: BasePart, opcoes): Painel
	local gui = novo("BillboardGui", {
		Name = "Painel",
		Size = UDim2.fromScale(opcoes.largura or 10, opcoes.alto or 3.4),
		StudsOffsetWorldSpace = Vector3.new(0, opcoes.altura or 5, 0),
		MaxDistance = opcoes.distancia or 120,
		LightInfluence = 0,
	}, parent)
	local fundo = novo("Frame", { Name = "Fundo", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1) }, gui)
	novo("UICorner", { CornerRadius = UDim.new(0.22, 0) }, fundo)
	novo("UIStroke", { Color = CONTORNO, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, fundo)
	local cores = opcoes.cores or { Color3.fromRGB(70, 62, 120), Color3.fromRGB(36, 30, 66) }
	local gradiente = novo("UIGradient", { Color = ColorSequence.new(cores[1], cores[2]), Rotation = 90 }, fundo)
	-- brilho branco na metade de cima, como nos botões da tela
	local brilho = novo("Frame", {
		Size = UDim2.new(1, -10, 0.42, 0),
		Position = UDim2.new(0, 5, 0, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
	}, fundo)
	novo("UICorner", { CornerRadius = UDim.new(0.4, 0) }, brilho)

	local icone = texto({ Name = "Icone", Text = "", Position = UDim2.fromScale(0.03, 0.12), Size = UDim2.fromScale(0.22, 0.76) }, fundo)
	novo("UIAspectRatioConstraint", { AspectRatio = 1 }, icone)
	local titulo = texto({
		Name = "Titulo",
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.27, 0.08),
		Size = UDim2.fromScale(0.7, 0.4),
	}, fundo)
	local linha = texto({
		Name = "Linha",
		Text = "",
		TextColor3 = Color3.fromRGB(255, 235, 140),
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.27, 0.48),
		Size = UDim2.fromScale(0.7, 0.24),
	}, fundo)
	local barra = novo("Frame", {
		Name = "Barra",
		Position = UDim2.fromScale(0.27, 0.76),
		Size = UDim2.fromScale(0.68, 0.13),
		BackgroundColor3 = Color3.fromRGB(15, 12, 30),
		ClipsDescendants = true,
	}, fundo)
	novo("UICorner", { CornerRadius = UDim.new(0.5, 0) }, barra)
	local enchimento = novo("Frame", {
		Name = "Enchimento",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(120, 240, 130),
	}, barra)
	novo("UICorner", { CornerRadius = UDim.new(0.5, 0) }, enchimento)

	return {
		gui = gui,
		fundo = fundo,
		gradiente = gradiente,
		icone = icone,
		titulo = titulo,
		linha = linha,
		barra = barra,
		enchimento = enchimento,
	}
end

function Paineis.cores(painel: Painel, cima: Color3, baixo: Color3)
	painel.gradiente.Color = ColorSequence.new(cima, baixo)
end

return Paineis

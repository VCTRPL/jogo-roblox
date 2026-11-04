-- Loja de trilhas: uma barraca no mapa vende as trilhas de Config.TRILHAS,
-- uma depois da outra. A melhor que o jogador já comprou multiplica a
-- Velocidade ganha na esteira (Bases.luau usa o atributo "NivelTrilha"); a
-- equipada ("TrilhaEquipada") é só a aparência, um rastro de luz atrás dele.
-- O cliente abre a tela da loja pelo botão da barraca (atributo "AbreLoja").
-- Para usar um modelo seu na barraca, ponha um Model chamado "LojaTrilhas"
-- em ServerStorage: ele vai para o lugar da barraca de blocos.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Dados = require(script.Parent.Dados)
local Mapa = require(script.Parent.Mapa)
local Paineis = require(script.Parent.Paineis)

local Trilhas = {}

-- Do lado norte da rua, no meio do espaço entre as bases 5 e 6
-- (Mapa.LOJA_TRILHAS), de frente para a rua.
local POSICAO_LOJA = Mapa.LOJA_TRILHAS

local VERMELHO = Color3.fromRGB(255, 90, 90)

local ultimoPedido: { [Player]: number } = {}

local function corDa(trilha): ColorSequence
	if trilha.arcoIris then
		local pontos = {}
		for i = 0, 6 do
			table.insert(pontos, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.8, 1)))
		end
		return ColorSequence.new(pontos)
	end
	return ColorSequence.new(trilha.cores[1], trilha.cores[2])
end

-- Põe (ou troca) o rastro de luz no personagem.
local function vestir(player: Player)
	local personagem = player.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not raiz then
		return
	end
	for _, nome in { "TrilhaLoja", "TrilhaCima", "TrilhaBaixo" } do
		local velho = raiz:FindFirstChild(nome)
		if velho then
			velho:Destroy()
		end
	end
	local trilha = Config.TRILHAS[player:GetAttribute("TrilhaEquipada") or 0]
	if not trilha then
		return
	end
	local cima = Instance.new("Attachment")
	cima.Name = "TrilhaCima"
	cima.Position = Vector3.new(0, 1.1, 0.4)
	cima.Parent = raiz
	local baixo = Instance.new("Attachment")
	baixo.Name = "TrilhaBaixo"
	baixo.Position = Vector3.new(0, -1.3, 0.4)
	baixo.Parent = raiz
	local rastro = Instance.new("Trail")
	rastro.Name = "TrilhaLoja"
	rastro.Attachment0 = cima
	rastro.Attachment1 = baixo
	rastro.Color = corDa(trilha)
	rastro.LightEmission = 0.8
	rastro.Lifetime = 0.35 + 0.08 * table.find(Config.TRILHAS, trilha)
	rastro.MinLength = 0.1
	rastro.FaceCamera = true
	rastro.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	rastro.WidthScale = NumberSequence.new(1, 0.2)
	rastro.Parent = raiz
end

local function comprar(player: Player, indice: number)
	local nivel = player:GetAttribute("NivelTrilha") or 0
	local trilha = Config.TRILHAS[indice]
	if not trilha or indice ~= nivel + 1 then
		Avisos.enviar(player, "Compre as trilhas na ordem!", VERMELHO)
		return
	end
	if Dados.valor(player, "Dinheiro") < trilha.preco then
		Avisos.enviar(player, "Dinheiro insuficiente!", VERMELHO)
		Avisos.som(player, "Erro")
		return
	end
	Dados.adicionar(player, "Dinheiro", -trilha.preco)
	player:SetAttribute("NivelTrilha", indice)
	player:SetAttribute("TrilhaEquipada", indice)
	Avisos.enviar(player, `{trilha.nome}! Velocidade da esteira x{trilha.multiplicador}`, trilha.cores[1])
	Avisos.som(player, "Comprou")
	local raiz = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if raiz then
		Avisos.efeito("EsteiraNova", { posicao = raiz.Position, nivel = math.min(indice + 1, #Config.NIVEIS_ESTEIRA) })
	end
end

local function equipar(player: Player, indice: number)
	local nivel = player:GetAttribute("NivelTrilha") or 0
	if indice < 0 or indice > nivel then
		return
	end
	player:SetAttribute("TrilhaEquipada", indice)
	Avisos.som(player, "Clique")
end

local function pedido(player: Player, acao: any, indice: any)
	if typeof(acao) ~= "string" or typeof(indice) ~= "number" or indice ~= indice then
		return
	end
	local agora = os.clock()
	if agora - (ultimoPedido[player] or 0) < 0.3 then
		return
	end
	ultimoPedido[player] = agora
	indice = math.floor(indice)
	if acao == "comprar" then
		comprar(player, indice)
	elseif acao == "equipar" then
		equipar(player, indice)
	end
end

-- Loja de Trilhas: um pavilhão de pedra clara com piso de mármore, colunas
-- na frente, telhado com a beirada em neon nas cores das trilhas, letreiro,
-- balcão, vitrines com uma trilha de verdade girando em cima de cada
-- pedestal e o vendedor atrás do balcão. O modelo é montado olhando para -Z
-- (a frente, onde fica a rua) e depois girado para o lugar.
local MARMORE = Color3.fromRGB(240, 236, 228)
local PEDRA = Color3.fromRGB(205, 198, 186)
local ROXO = Color3.fromRGB(110, 60, 200)

local function corDaTrilha(trilha): Color3
	return if trilha.arcoIris then Color3.fromRGB(255, 120, 200) else trilha.cores[1]
end

local function lojaNova(): Model
	local modelo = Instance.new("Model")
	modelo:SetAttribute("SemLego", true)
	local function bloco(nome: string, tamanho: Vector3, cf: CFrame, cor: Color3, material: Enum.Material?, props: any?): BasePart
		local p = Mapa.parte({ Name = nome, Size = tamanho, CFrame = cf, Color = cor, Material = material or Enum.Material.SmoothPlastic, Parent = modelo })
		if props then
			for chave, valor in props do
				(p :: any)[chave] = valor
			end
		end
		return p
	end
	local W, D, H = 40, 30, 15
	local piso = bloco("Piso", Vector3.new(W, 1.2, D), CFrame.new(0, 0.6, 0), PEDRA, Enum.Material.Limestone)
	bloco("Marmore", Vector3.new(W - 2, 0.1, D - 2), CFrame.new(0, 1.22, 0), MARMORE, Enum.Material.Marble)
	-- tapete roxo da entrada até o balcão
	bloco("Tapete", Vector3.new(7, 0.06, 18), CFrame.new(0, 1.29, -5), ROXO, Enum.Material.Fabric, { CanCollide = false })
	-- degraus na frente
	for i = 0, 1 do
		bloco("Degrau", Vector3.new(16 - i * 2, 0.6, 2), CFrame.new(0, 0.3 + i * 0.3, -D / 2 - 2 + i), PEDRA, Enum.Material.Limestone)
	end
	-- paredes do fundo e dos lados (os lados vão até 2/3)
	bloco("Parede", Vector3.new(W, H, 1.6), CFrame.new(0, 1.2 + H / 2, D / 2 - 0.8), PEDRA, Enum.Material.Limestone)
	for _, s in { -1, 1 } do
		bloco("Parede", Vector3.new(1.6, H, D * 0.62), CFrame.new(s * (W / 2 - 0.8), 1.2 + H / 2, D / 2 - D * 0.31), PEDRA, Enum.Material.Limestone)
	end
	-- colunas na frente
	for _, x in { -W / 2 + 1, -9, 9, W / 2 - 1 } do
		bloco("Base", Vector3.new(3, 1, 3), CFrame.new(x, 1.7, -D / 2 + 1.5), PEDRA, Enum.Material.Limestone)
		local c = bloco("Coluna", Vector3.new(H - 1, 2.2, 2.2), CFrame.new(x, 1.2 + H / 2, -D / 2 + 1.5) * CFrame.Angles(0, 0, math.rad(90)), MARMORE, Enum.Material.Marble)
		c.Shape = Enum.PartType.Cylinder
		bloco("Capitel", Vector3.new(3, 0.8, 3), CFrame.new(x, H + 0.8, -D / 2 + 1.5), Color3.fromRGB(230, 190, 90), Enum.Material.Metal)
	end
	-- telhado com beiral e a beirada em neon com as cores das trilhas
	bloco("Telhado", Vector3.new(W + 4, 1.6, D + 4), CFrame.new(0, H + 2, 0), Color3.fromRGB(70, 50, 120), Enum.Material.SmoothPlastic)
	bloco("Telhado", Vector3.new(W + 1, 1, D + 1), CFrame.new(0, H + 3.2, 0), Color3.fromRGB(90, 66, 150), Enum.Material.SmoothPlastic)
	local largura = (W + 4) / #Config.TRILHAS
	for i, trilha in Config.TRILHAS do
		local faixa = bloco("BeiralNeon", Vector3.new(largura, 0.5, 0.3), CFrame.new(-(W + 4) / 2 + largura * (i - 0.5), H + 1.5, -(D + 4) / 2 - 0.1), corDaTrilha(trilha), Enum.Material.Neon, { CanCollide = false })
		CollectionService:AddTag(faixa, "PulsarEsteira")
	end
	-- letreiro em cima da entrada
	local letreiro = bloco("Letreiro", Vector3.new(22, 4.2, 0.6), CFrame.new(0, H + 5.6, -D / 2 + 1), Color3.fromRGB(40, 28, 70), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = letreiro
	local texto = Instance.new("TextLabel")
	texto.BackgroundTransparency = 1
	texto.Size = UDim2.fromScale(0.94, 0.8)
	texto.Position = UDim2.fromScale(0.03, 0.1)
	texto.Font = Enum.Font.LuckiestGuy
	texto.Text = "LOJA DE TRILHAS"
	texto.TextScaled = true
	texto.TextColor3 = Color3.new(1, 1, 1)
	local grad = Instance.new("UIGradient")
	local pontos = {}
	for i, trilha in Config.TRILHAS do
		table.insert(pontos, ColorSequenceKeypoint.new((i - 1) / (#Config.TRILHAS - 1), corDaTrilha(trilha)))
	end
	grad.Color = ColorSequence.new(pontos)
	grad.Parent = texto
	local contorno = Instance.new("UIStroke")
	contorno.Thickness = 4
	contorno.Color = Color3.fromRGB(20, 10, 40)
	contorno.Parent = texto
	texto.Parent = gui
	bloco("MolduraLetreiro", Vector3.new(23, 5.2, 0.4), CFrame.new(0, H + 5.6, -D / 2 + 1.4), Color3.fromRGB(230, 190, 90), Enum.Material.Metal)
	-- balcão
	bloco("Balcao", Vector3.new(14, 3.6, 2.6), CFrame.new(0, 3, 6), Color3.fromRGB(120, 80, 170), Enum.Material.SmoothPlastic)
	bloco("TampoBalcao", Vector3.new(14.6, 0.4, 3.2), CFrame.new(0, 5, 6), MARMORE, Enum.Material.Marble)
	bloco("FaixaBalcao", Vector3.new(14.1, 0.25, 0.1), CFrame.new(0, 4.2, 4.65), Color3.fromRGB(255, 120, 255), Enum.Material.Neon, { CanCollide = false })
	-- vitrines: um pedestal por trilha, com a trilha girando em cima
	for i, trilha in Config.TRILHAS do
		local s = if i <= 4 then -1 else 1
		local k = if i <= 4 then i - 1 else i - 5
		local pos = Vector3.new(s * (W / 2 - 4.5), 1.2, -D / 2 + 7 + k * 5.2)
		local pedestal = bloco("Pedestal", Vector3.new(2.4, 3, 2.4), CFrame.new(pos + Vector3.new(0, 1.5, 0)), MARMORE, Enum.Material.Marble)
		bloco("TopoPedestal", Vector3.new(2.8, 0.3, 2.8), CFrame.new(pos + Vector3.new(0, 3.15, 0)), Color3.fromRGB(230, 190, 90), Enum.Material.Metal)
		local centro = Vector3.new(pos.X, pos.Y + 5, pos.Z)
		local bola = bloco("Amostra", Vector3.new(0.5, 0.5, 0.5), CFrame.new(centro + Vector3.new(1.3, 0, 0)), corDaTrilha(trilha), Enum.Material.Neon, { CanCollide = false, CanQuery = false })
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.5, 0)
		a0.Parent = bola
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.5, 0)
		a1.Parent = bola
		local rastro = Instance.new("Trail")
		rastro.Attachment0 = a0
		rastro.Attachment1 = a1
		rastro.Color = corDa(trilha)
		rastro.LightEmission = 0.8
		rastro.Lifetime = 0.6
		rastro.Transparency = NumberSequence.new(0, 1)
		rastro.Parent = bola
		bola:SetAttribute("Giro", 200)
		bola:SetAttribute("Flutua", 0.4)
		-- "Centro" é posto depois de girar a loja para o lugar (montarLoja)
		bola:SetAttribute("CentroLocal", centro)
		CollectionService:AddTag(bola, "AmostraTrilha")
		local placa = Instance.new("SurfaceGui")
		placa.Face = if s > 0 then Enum.NormalId.Left else Enum.NormalId.Right
		placa.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		placa.PixelsPerStud = 40
		placa.Parent = pedestal
		local nome = Instance.new("TextLabel")
		nome.BackgroundTransparency = 1
		nome.Size = UDim2.fromScale(1, 0.5)
		nome.Position = UDim2.fromScale(0, 0.25)
		nome.Font = Enum.Font.FredokaOne
		nome.TextScaled = true
		nome.Text = trilha.nome .. "\nx" .. trilha.multiplicador
		nome.TextColor3 = corDaTrilha(trilha):Lerp(Color3.new(0, 0, 0), 0.35)
		nome.Parent = placa
	end
	-- luzes de dentro
	for _, x in { -10, 10 } do
		local lampada = bloco("Lustre", Vector3.new(2, 0.6, 2), CFrame.new(x, H + 0.4, 0), Color3.fromRGB(255, 230, 180), Enum.Material.Neon, { CanCollide = false })
		local luzLoja = Instance.new("PointLight")
		luzLoja.Range = 22
		luzLoja.Brightness = 1.4
		luzLoja.Color = Color3.fromRGB(255, 220, 255)
		luzLoja.Parent = lampada
	end
	-- brilhos na entrada
	local entrada = bloco("BrilhoEntrada", Vector3.new(14, 1, 2), CFrame.new(0, 2, -D / 2 + 1), Color3.new(1, 1, 1), nil, { Transparency = 1, CanCollide = false, CanQuery = false })
	local brilho = Instance.new("ParticleEmitter")
	brilho.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	brilho.Color = ColorSequence.new(pontos)
	brilho.LightEmission = 1
	brilho.Size = NumberSequence.new(0.5, 0)
	brilho.Lifetime = NumberRange.new(1, 2)
	brilho.Rate = 12
	brilho.Speed = NumberRange.new(1, 3)
	brilho.EmissionDirection = Enum.NormalId.Top
	brilho.Parent = entrada
	modelo.PrimaryPart = piso
	return modelo
end

-- Vendedor atrás do balcão: um boneco R15 de roupa roxa, avental e chapéu,
-- uma trilha arco-íris na mão e acenando sem parar. Falar com ele abre a
-- mesma tela da loja (atributo "AbreLoja"), sem outro sistema de compra.
local function vendedor(cf: CFrame, pai: Instance)
	local ok, boneco = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = Color3.fromRGB(255, 205, 160)
		desc.LeftArmColor = desc.HeadColor
		desc.RightArmColor = desc.HeadColor
		desc.TorsoColor = Color3.fromRGB(130, 70, 210)
		desc.LeftLegColor = Color3.fromRGB(45, 35, 80)
		desc.RightLegColor = Color3.fromRGB(45, 35, 80)
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not boneco then
		warn("Vendedor de trilhas não montou:", boneco)
		return
	end
	boneco.Name = "Vendedor de Trilhas"
	boneco:SetAttribute("SemLego", true)
	local humanoid = boneco:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayName = "Vendedor de Trilhas"
	humanoid.NameDisplayDistance = 60
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	for _, p in boneco:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = p.Name == "HumanoidRootPart"
			p.CanCollide = false
		end
	end
	local tronco = boneco:FindFirstChild("UpperTorso") :: BasePart?
	local cabeca = boneco:FindFirstChild("Head") :: BasePart?
	local function preso(alvo: BasePart, nome: string, tamanho: Vector3, desloca: CFrame, cor: Color3, material: Enum.Material)
		local p = Instance.new("Part")
		p.Name = nome
		p.Size = tamanho
		p.Color = cor
		p.Material = material
		p.CanCollide = false
		p.Massless = true
		p.CFrame = alvo.CFrame * desloca
		local solda = Instance.new("WeldConstraint")
		solda.Part0 = alvo
		solda.Part1 = p
		solda.Parent = p
		p.Parent = boneco
	end
	if tronco then
		preso(tronco, "Avental", Vector3.new(1.7, 1.5, 0.15), CFrame.new(0, -0.1, -0.55), Color3.fromRGB(255, 215, 90), Enum.Material.Fabric)
	end
	if cabeca then
		preso(cabeca, "Chapeu", Vector3.new(1.6, 0.25, 1.6), CFrame.new(0, 0.7, 0), Color3.fromRGB(70, 40, 140), Enum.Material.SmoothPlastic)
		preso(cabeca, "Chapeu", Vector3.new(1.1, 0.8, 1.1), CFrame.new(0, 1.15, 0), Color3.fromRGB(70, 40, 140), Enum.Material.SmoothPlastic)
		preso(cabeca, "FitaChapeu", Vector3.new(1.15, 0.2, 1.15), CFrame.new(0, 0.85, 0), Color3.fromRGB(255, 120, 255), Enum.Material.Neon)
	end
	boneco:PivotTo(cf)
	boneco.Parent = pai
	local mao = boneco:FindFirstChild("RightHand") :: BasePart?
	if mao then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.4, 0)
		a0.Parent = mao
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.4, 0)
		a1.Parent = mao
		local rastro = Instance.new("Trail")
		rastro.Attachment0 = a0
		rastro.Attachment1 = a1
		rastro.Color = corDa(Config.TRILHAS[6] or Config.TRILHAS[1])
		rastro.LightEmission = 0.8
		rastro.Lifetime = 0.5
		rastro.Transparency = NumberSequence.new(0, 1)
		rastro.Parent = mao
	end
	-- acenando o tempo todo (o aceno padrão do Roblox)
	local animador = humanoid:FindFirstChildOfClass("Animator")
	if not animador then
		animador = Instance.new("Animator")
		animador.Parent = humanoid
	end
	local animacao = Instance.new("Animation")
	animacao.AnimationId = "rbxassetid://507770239"
	local ok2, faixa = pcall(function()
		return (animador :: Animator):LoadAnimation(animacao)
	end)
	if ok2 and faixa then
		faixa.Looped = true
		faixa:Play()
	end
	local raiz = boneco:FindFirstChild("HumanoidRootPart") :: BasePart?
	if raiz then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Vendedor"
		prompt.ActionText = "Falar"
		prompt.ObjectText = "Vendedor de Trilhas"
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 14
		prompt:SetAttribute("AbreLoja", "Trilhas")
		prompt.Parent = raiz
	end
end

local function montarLoja()
	local proprio = ServerStorage:FindFirstChild("LojaTrilhas")
	local modelo: Model = if proprio and proprio:IsA("Model") then proprio:Clone() else lojaNova()
	modelo.Name = "LojaTrilhas"
	-- de frente para a estrada (que fica em z = 0)
	local olhar = Vector3.new(POSICAO_LOJA.X, POSICAO_LOJA.Y, 0)
	local _, tamanho = modelo:GetBoundingBox()
	modelo:PivotTo(CFrame.lookAt(POSICAO_LOJA, olhar))
	if proprio then
		-- apoia o modelo no chão
		local centro, tamanho2 = modelo:GetBoundingBox()
		modelo:PivotTo(modelo:GetPivot() + Vector3.new(0, POSICAO_LOJA.Y - (centro.Position.Y - tamanho2.Y / 2), 0))
	end
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Anchored = true
		end
	end

	-- ponto do botão e da placa, na frente do balcão
	local marco = Instance.new("Part")
	marco.Name = "BotaoLoja"
	marco.Anchored = true
	marco.CanCollide = false
	marco.CanQuery = false
	marco.CanTouch = false
	marco.Transparency = 1
	marco.Size = Vector3.one
	-- na frente do balcão (num modelo próprio, na frente dele)
	marco.CFrame = CFrame.lookAt(POSICAO_LOJA, olhar)
		* (if proprio then CFrame.new(0, 3, -math.max(tamanho.Z / 2, 4) - 1) else CFrame.new(0, 4, 2.5))
	marco.Parent = modelo
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Loja"
	prompt.ActionText = "Abrir loja"
	prompt.ObjectText = "Trilhas"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 14
	prompt:SetAttribute("AbreLoja", "Trilhas")
	prompt.Parent = marco
	-- placa grande em cima (a loja nova já tem o letreiro dela)
	if proprio then
		local placa = Paineis.criar(marco, {
			altura = math.max(tamanho.Y, 12) - 1,
			largura = 14,
			alto = 4.2,
			cores = { Color3.fromRGB(255, 120, 255), Color3.fromRGB(70, 40, 200) },
			distancia = 200,
		})
		placa.icone.Text = "✨"
		placa.titulo.Text = "LOJA DE TRILHAS"
		placa.linha.Text = "Mais Velocidade na esteira!"
		placa.barra.Visible = false
	end

	modelo.Parent = Workspace:FindFirstChild("Mapa") or Workspace
	-- as amostras giram em volta do ponto certo, já com a loja no lugar
	for _, bola in modelo:GetDescendants() do
		local local_ = bola:GetAttribute("CentroLocal")
		if bola:IsA("BasePart") and local_ then
			bola:SetAttribute("Centro", CFrame.lookAt(POSICAO_LOJA, olhar) * local_)
			CollectionService:AddTag(bola, "GirarEsteira")
		end
	end
	if not proprio then
		-- vendedor atrás do balcão, olhando para a entrada
		local frente = CFrame.lookAt(POSICAO_LOJA, olhar)
		vendedor(frente * CFrame.new(0, 4.3, 9), modelo)
		-- passeio de pedra da calçada até os degraus
		local inicio = math.sign(POSICAO_LOJA.Z) * 13.6
		local fim = POSICAO_LOJA.Z - math.sign(POSICAO_LOJA.Z) * 17
		local passeio = Mapa.parte({
			Name = "PasseioLoja",
			Size = Vector3.new(10, 1, math.abs(fim - inicio)),
			Position = Vector3.new(POSICAO_LOJA.X, 0.55, (inicio + fim) / 2),
			Color = Color3.fromRGB(222, 216, 204),
			Material = Enum.Material.Pavement,
			Parent = modelo,
		})
		passeio:SetAttribute("SemLego", true)
	end
end

-- Multiplicador da Velocidade da esteira pelas trilhas compradas.
function Trilhas.multiplicador(player: Player): number
	return Config.multiplicadorTrilha(player:GetAttribute("NivelTrilha") or 0)
end

function Trilhas.iniciar()
	local evento = Instance.new("RemoteEvent")
	evento.Name = "Trilhas"
	evento.Parent = ReplicatedStorage:WaitForChild("Remotes")
	evento.OnServerEvent:Connect(pedido)

	montarLoja()

	local function aoEntrar(player: Player)
		player.CharacterAdded:Connect(function(personagem)
			personagem:WaitForChild("HumanoidRootPart")
			vestir(player)
		end)
		-- os dados chegam depois de entrar
		player:GetAttributeChangedSignal("TrilhaEquipada"):Connect(function()
			vestir(player)
		end)
	end
	Players.PlayerAdded:Connect(aoEntrar)
	for _, player in Players:GetPlayers() do
		aoEntrar(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ultimoPedido[player] = nil
	end)
end

return Trilhas

-- Loja de trilhas: uma vendinha no mapa (com a vovó vendedora) vende as trilhas de Config.TRILHAS,
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

-- Loja de Trilhas: uma vendinha simples de blocos (como a da referência):
-- piso de tábuas, muretas de tijolo com pinos, quatro pilares quadrados,
-- telhado de duas águas com listras azuis e brancas, uma mesinha no fundo
-- com vaso de planta, patinho e caneca, uma cadeira, a placa "TRILHAS" e,
-- pendurados na beirada do telhado, uma bolinha de cada trilha girando com
-- o rastro dela. A vendedora fica atrás do balcão. O modelo é montado
-- olhando para -Z (a frente, onde fica a rua) e depois girado para o lugar.
local TIJOLO = Color3.fromRGB(176, 104, 58)
local TIJOLO_ESCURO = Color3.fromRGB(150, 86, 46)
local MADEIRA_ESCURA = Color3.fromRGB(70, 46, 32)
local AZUL = Color3.fromRGB(20, 40, 230)
local BRANCO_TOLDO = Color3.fromRGB(235, 240, 255)

local function corDaTrilha(trilha): Color3
	return if trilha.arcoIris then Color3.fromRGB(255, 120, 200) else trilha.cores[1]
end

local function lojaNova(): Model
	local modelo = Instance.new("Model")
	local function bloco(nome: string, tamanho: Vector3, cf: CFrame, cor: Color3, material: Enum.Material?, props: any?): BasePart
		local p = Mapa.parte({ Name = nome, Size = tamanho, CFrame = cf, Color = cor, Material = material or Enum.Material.Plastic, Parent = modelo })
		if props then
			for chave, valor in props do
				(p :: any)[chave] = valor
			end
		end
		return p
	end
	local W, D = 18, 13 -- largura (X) e fundo (Z)
	local ALTURA_PILAR = 9
	local MURETA = 3.6
	local piso = bloco("Piso", Vector3.new(W, 1, D), CFrame.new(0, 0.5, 0), Color3.fromRGB(140, 96, 60), Enum.Material.WoodPlanks)

	-- muretas de tijolo: frente inteira (é o balcão), lados e fundo
	local function mureta(centro: Vector3, tamanho: Vector3)
		bloco("Mureta", tamanho, CFrame.new(centro), TIJOLO)
		-- fiadas mais escuras para parecer tijolo
		for y = 1, math.floor(tamanho.Y) - 1 do
			bloco("Fiada", Vector3.new(tamanho.X + 0.06, 0.12, tamanho.Z + 0.06), CFrame.new(centro.X, centro.Y - tamanho.Y / 2 + y, centro.Z), TIJOLO_ESCURO, nil, { CanCollide = false })
		end
	end
	local yMureta = 1 + MURETA / 2
	mureta(Vector3.new(0, yMureta, -D / 2 + 0.6), Vector3.new(W - 2, MURETA, 1.2))
	mureta(Vector3.new(0, yMureta, D / 2 - 0.6), Vector3.new(W - 2, MURETA, 1.2))
	for _, s in { -1, 1 } do
		mureta(Vector3.new(s * (W / 2 - 0.6), yMureta, 0), Vector3.new(1.2, MURETA, D - 2))
	end
	-- tampo de madeira em cima da mureta da frente (o balcão)
	bloco("Balcao", Vector3.new(W - 2, 0.4, 2), CFrame.new(0, 1 + MURETA + 0.2, -D / 2 + 0.8), MADEIRA_ESCURA, Enum.Material.Wood)

	-- quatro pilares quadrados com "pinos" de lado (os quadradinhos da foto)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * (W / 2 - 0.9), sz * (D / 2 - 0.9)
			bloco("Pilar", Vector3.new(1.8, ALTURA_PILAR, 1.8), CFrame.new(x, 1 + ALTURA_PILAR / 2, z), TIJOLO)
			for y = 1.8, ALTURA_PILAR, 1.4 do
				bloco("Pino", Vector3.new(0.8, 0.8, 0.25), CFrame.new(x, y, z - 1.0), TIJOLO_ESCURO, nil, { CanCollide = false })
				bloco("Pino", Vector3.new(0.25, 0.8, 0.8), CFrame.new(x + sx * 1.0, y, z), TIJOLO_ESCURO, nil, { CanCollide = false })
			end
		end
	end
	-- viga em volta, em cima dos pilares
	local yViga = 1 + ALTURA_PILAR + 0.4
	for _, sz in { -1, 1 } do
		bloco("Viga", Vector3.new(W, 0.8, 1), CFrame.new(0, yViga, sz * (D / 2 - 0.9)), TIJOLO_ESCURO)
	end
	for _, sx in { -1, 1 } do
		bloco("Viga", Vector3.new(1, 0.8, D), CFrame.new(sx * (W / 2 - 0.9), yViga, 0), TIJOLO_ESCURO)
	end

	-- telhado de duas águas com listras azuis e brancas (descendo para a
	-- frente e para trás), passando um pouco das paredes
	local beiral = 1.4
	local meioFundo = D / 2 + beiral
	local subida = 4.2
	local inclinacao = math.atan2(subida, meioFundo)
	local comprimento = math.sqrt(meioFundo * meioFundo + subida * subida)
	local largura = W + 2
	local listras = 12
	local passo = largura / listras
	local yBase = yViga + 0.4
	for _, sz in { -1, 1 } do
		for k = 0, listras - 1 do
			local x = -largura / 2 + passo * (k + 0.5)
			local centro = CFrame.new(x, yBase + subida / 2, sz * meioFundo / 2) * CFrame.Angles(sz * inclinacao, 0, 0)
			bloco("Toldo", Vector3.new(passo, 0.5, comprimento), centro, if k % 2 == 0 then AZUL else BRANCO_TOLDO)
		end
		-- franja na beirada
		for k = 0, listras - 1 do
			local x = -largura / 2 + passo * (k + 0.5)
			bloco("Franja", Vector3.new(passo - 0.1, 0.7, 0.3), CFrame.new(x, yBase - 0.3, sz * (meioFundo - 0.1)), if k % 2 == 0 then BRANCO_TOLDO else AZUL, nil, { CanCollide = false })
		end
	end
	-- oitões azuis (triângulos dos lados)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local cunha = Instance.new("WedgePart")
			cunha.Name = "Oitao"
			cunha.Anchored = true
			cunha.CanCollide = false
			cunha.Size = Vector3.new(0.4, subida, meioFundo - beiral)
			-- a cunha sobe para -Z local; girada 180 no lado de trás
			cunha.CFrame = CFrame.new(sx * (W / 2 - 0.4), yBase + subida / 2, sz * (meioFundo - beiral) / 2) * CFrame.Angles(0, if sz > 0 then math.pi else 0, 0)
			cunha.Color = AZUL
			cunha.Parent = modelo
		end
	end

	-- placa "TRILHAS" em cima do telhado, na frente
	local placa = bloco("PlacaLoja", Vector3.new(10, 2.6, 0.5), CFrame.new(0, yBase + subida - 0.6, -1.6) * CFrame.Angles(-inclinacao, 0, 0) * CFrame.new(0, 1.6, 0), Color3.fromRGB(255, 245, 225), Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = placa
	local texto = Instance.new("TextLabel")
	texto.BackgroundTransparency = 1
	texto.Size = UDim2.fromScale(0.92, 0.84)
	texto.Position = UDim2.fromScale(0.04, 0.08)
	texto.Font = Enum.Font.Bangers
	texto.Text = "✨ TRILHAS ✨"
	texto.TextScaled = true
	texto.TextColor3 = AZUL
	local contorno = Instance.new("UIStroke")
	contorno.Thickness = 3
	contorno.Color = Color3.new(1, 1, 1)
	contorno.Parent = texto
	texto.Parent = gui

	-- mesinha no fundo com vaso de planta, patinho e caneca, e uma cadeira
	local mesa = CFrame.new(-W / 2 + 4.5, 1, D / 2 - 2.6)
	bloco("Mesa", Vector3.new(5, 0.4, 2.4), mesa * CFrame.new(0, 2.6, 0), MADEIRA_ESCURA, Enum.Material.Wood)
	for _, dx in { -2.1, 2.1 } do
		for _, dz in { -0.9, 0.9 } do
			bloco("PeMesa", Vector3.new(0.35, 2.4, 0.35), mesa * CFrame.new(dx, 1.2, dz), MADEIRA_ESCURA, Enum.Material.Wood)
		end
	end
	bloco("Vaso", Vector3.new(1, 0.9, 1), mesa * CFrame.new(1.4, 3.25, 0.2), MADEIRA_ESCURA)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		bloco("Folha", Vector3.new(0.3, 1.2, 0.7), mesa * CFrame.new(1.4 + math.cos(a) * 0.3, 4.1, 0.2 + math.sin(a) * 0.3) * CFrame.Angles(math.cos(a) * 0.5, a, math.sin(a) * 0.5), Color3.fromRGB(60, 160, 60), nil, { CanCollide = false })
	end
	bloco("Pato", Vector3.new(0.9, 0.7, 1.1), mesa * CFrame.new(-0.4, 3.15, 0), Color3.fromRGB(255, 220, 30))
	bloco("CabecaPato", Vector3.new(0.6, 0.6, 0.6), mesa * CFrame.new(-0.4, 3.75, -0.3), Color3.fromRGB(255, 220, 30))
	bloco("BicoPato", Vector3.new(0.3, 0.2, 0.3), mesa * CFrame.new(-0.4, 3.7, -0.7), Color3.fromRGB(255, 140, 30), nil, { CanCollide = false })
	bloco("Caneca", Vector3.new(0.6, 0.6, 0.6), mesa * CFrame.new(-1.7, 3.1, 0.3), Color3.fromRGB(160, 220, 255))
	local cadeira = CFrame.new(W / 2 - 4, 1, 1.5)
	bloco("Assento", Vector3.new(2, 0.3, 2), cadeira * CFrame.new(0, 2, 0), Color3.fromRGB(35, 25, 20), Enum.Material.Wood)
	bloco("Encosto", Vector3.new(2, 2.6, 0.3), cadeira * CFrame.new(0, 3.4, 0.85), Color3.fromRGB(35, 25, 20), Enum.Material.Wood)
	for _, dx in { -0.8, 0.8 } do
		for _, dz in { -0.8, 0.8 } do
			bloco("PeCadeira", Vector3.new(0.25, 2, 0.25), cadeira * CFrame.new(dx, 1, dz), Color3.fromRGB(35, 25, 20), Enum.Material.Wood)
		end
	end

	-- uma bolinha de cada trilha pendurada na beirada da frente, girando com o rastro
	for i, trilha in Config.TRILHAS do
		local x = -W / 2 + 2 + (i - 1) * (W - 4) / (#Config.TRILHAS - 1)
		local centro = Vector3.new(x, yBase - 2.2, -D / 2 - 0.4)
		bloco("Fio", Vector3.new(0.08, 1.6, 0.08), CFrame.new(centro + Vector3.new(0, 1.3, 0)), Color3.fromRGB(240, 240, 240), nil, { CanCollide = false, CanQuery = false })
		local bola = bloco("Amostra", Vector3.new(0.5, 0.5, 0.5), CFrame.new(centro + Vector3.new(0.6, 0, 0)), corDaTrilha(trilha), Enum.Material.Neon, { CanCollide = false, CanQuery = false })
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.3, 0)
		a0.Parent = bola
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.3, 0)
		a1.Parent = bola
		local rastro = Instance.new("Trail")
		rastro.Attachment0 = a0
		rastro.Attachment1 = a1
		rastro.Color = corDa(trilha)
		rastro.LightEmission = 0.8
		rastro.Lifetime = 0.5
		rastro.Transparency = NumberSequence.new(0, 1)
		rastro.Parent = bola
		bola:SetAttribute("Giro", 180 + i * 10)
		bola:SetAttribute("Flutua", 0.2)
		bola:SetAttribute("CentroLocal", centro)
	end
	-- luzinha quente dentro
	local lampada = bloco("Lampada", Vector3.new(0.8, 0.8, 0.8), CFrame.new(0, yBase + 1.4, 0), Color3.fromRGB(255, 225, 160), Enum.Material.Neon, { CanCollide = false })
	local luzLoja = Instance.new("PointLight")
	luzLoja.Range = 16
	luzLoja.Brightness = 1.2
	luzLoja.Color = Color3.fromRGB(255, 220, 170)
	luzLoja.Parent = lampada
	modelo.PrimaryPart = piso
	return modelo
end

-- Vendedora atrás do balcão (como a da foto): uma vovozinha R15 de cabelo
-- branco em coque, vestido azul com avental branco e óculos, acenando e com
-- uma trilha arco-íris na mão. A loja abre pelo botão "LOJA" que aparece
-- na tela perto da barraca (Interface.luau), sem outro sistema de compra.
local function vendedor(cf: CFrame, pai: Instance)
	local ok, boneco = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = Color3.fromRGB(255, 214, 180)
		desc.LeftArmColor = desc.HeadColor
		desc.RightArmColor = desc.HeadColor
		desc.TorsoColor = Color3.fromRGB(70, 110, 210)
		desc.LeftLegColor = Color3.fromRGB(70, 110, 210)
		desc.RightLegColor = Color3.fromRGB(70, 110, 210)
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not boneco then
		warn("Vendedora de trilhas não montou:", boneco)
		return
	end
	boneco.Name = "Vendedora de Trilhas"
	local humanoid = boneco:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayName = "Vovó das Trilhas"
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
	local function preso(alvo: BasePart, nome: string, tamanho: Vector3, desloca: CFrame, cor: Color3, material: Enum.Material?)
		local p = Instance.new("Part")
		p.Name = nome
		p.Size = tamanho
		p.Color = cor
		p.Material = material or Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.Massless = true
		p.CFrame = alvo.CFrame * desloca
		local solda = Instance.new("WeldConstraint")
		solda.Part0 = alvo
		solda.Part1 = p
		solda.Parent = p
		p.Parent = boneco
	end
	local BRANCO_CABELO = Color3.fromRGB(245, 245, 250)
	if tronco then
		preso(tronco, "Avental", Vector3.new(1.6, 1.6, 0.15), CFrame.new(0, -0.1, -0.55), Color3.new(1, 1, 1), Enum.Material.Fabric)
		preso(tronco, "Gola", Vector3.new(1.4, 0.3, 1.1), CFrame.new(0, 0.75, 0), Color3.new(1, 1, 1), Enum.Material.Fabric)
	end
	if cabeca then
		-- cabelo branco cacheado e o coque em cima
		preso(cabeca, "Cabelo", Vector3.new(1.35, 0.6, 1.35), CFrame.new(0, 0.45, 0.05), BRANCO_CABELO)
		for _, dx in { -0.6, 0.6 } do
			preso(cabeca, "Cabelo", Vector3.new(0.4, 0.9, 1.1), CFrame.new(dx, 0.05, 0.15), BRANCO_CABELO)
		end
		preso(cabeca, "Cabelo", Vector3.new(1.2, 0.9, 0.4), CFrame.new(0, 0.05, 0.6), BRANCO_CABELO)
		preso(cabeca, "Coque", Vector3.new(0.75, 0.6, 0.75), CFrame.new(0, 0.95, 0.15), BRANCO_CABELO)
		-- óculos redondinhos
		for _, dx in { -0.25, 0.25 } do
			preso(cabeca, "Oculos", Vector3.new(0.32, 0.32, 0.05), CFrame.new(dx, 0.12, -0.6), Color3.fromRGB(40, 40, 50))
		end
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
		* (if proprio then CFrame.new(0, 3, -math.max(tamanho.Z / 2, 4) - 1) else CFrame.new(0, 4, -8.2))
	marco.Parent = modelo
	-- quem abre a loja é o botão "LOJA" da tela (aparece perto da barraca,
	-- veja Interface.luau); num modelo próprio sem esse botão, fica o prompt
	if proprio then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Loja"
		prompt.ActionText = "Abrir loja"
		prompt.ObjectText = "Trilhas"
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 14
		prompt:SetAttribute("AbreLoja", "Trilhas")
		prompt.Parent = marco
	end
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
		-- vendedora atrás do balcão, olhando para a rua
		local frente = CFrame.lookAt(POSICAO_LOJA, olhar)
		vendedor(frente * CFrame.new(0, 4.05, -3.6), modelo)
		-- passeio de pedra da calçada até os degraus
		local inicio = math.sign(POSICAO_LOJA.Z) * 13.6
		local fim = POSICAO_LOJA.Z - math.sign(POSICAO_LOJA.Z) * 6.5
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

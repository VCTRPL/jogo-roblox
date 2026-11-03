-- Loja de trilhas: uma barraca no mapa vende as trilhas de Config.TRILHAS,
-- uma depois da outra. A melhor que o jogador já comprou multiplica a
-- Velocidade ganha na esteira (Bases.luau usa o atributo "NivelTrilha"); a
-- equipada ("TrilhaEquipada") é só a aparência, um rastro de luz atrás dele.
-- O cliente abre a tela da loja pelo botão da barraca (atributo "AbreLoja").
-- Para usar um modelo seu na barraca, ponha um Model chamado "LojaTrilhas"
-- em ServerStorage: ele vai para o lugar da barraca de blocos.
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

-- Na beira da estrada, entre a primeira e a segunda base e de frente para a
-- estrada (um lugar sem decoração em volta).
local POSICAO_LOJA = Vector3.new(-65, 1, -27)

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

-- Barraca de blocos: balcão, colunas, toldo listrado e placa.
local function barracaDeBlocos(): Model
	local modelo = Instance.new("Model")
	local function bloco(nome, tamanho, posicao, cor, material)
		local p = Mapa.parte({
			Name = nome,
			Size = tamanho,
			CFrame = CFrame.new(posicao),
			Color = cor,
			Material = material or Enum.Material.Plastic,
			Parent = modelo,
		})
		p.TopSurface = Enum.SurfaceType.Studs
		return p
	end
	local madeira = Color3.fromRGB(150, 100, 60)
	local piso = bloco("Piso", Vector3.new(18, 1, 12), Vector3.new(0, 0.5, 0), Color3.fromRGB(110, 110, 125))
	bloco("Balcao", Vector3.new(14, 4, 3), Vector3.new(0, 3, -3), madeira)
	bloco("TampoBalcao", Vector3.new(15, 0.6, 3.6), Vector3.new(0, 5.3, -3), Color3.fromRGB(240, 240, 245))
	for _, x in { -7.5, 7.5 } do
		for _, z in { -4.5, 4.5 } do
			bloco("Coluna", Vector3.new(1, 10, 1), Vector3.new(x, 6, z), Color3.fromRGB(240, 240, 245))
		end
	end
	-- toldo com listras nas cores das trilhas
	for i, trilha in Config.TRILHAS do
		local largura = 18 / #Config.TRILHAS
		local x = -9 + largura * (i - 0.5)
		bloco("Toldo", Vector3.new(largura, 1, 12), Vector3.new(x, 11.5, 0), trilha.cores[1])
	end
	-- vitrine: três faixas de neon mostrando as trilhas
	for i, z in { -1, 0, 1 } do
		local trilha = Config.TRILHAS[i * 2]
		bloco("Vitrine", Vector3.new(0.4, 3, 0.4), Vector3.new(z * 4, 7.3, -3), trilha.cores[1], Enum.Material.Neon)
	end
	modelo.PrimaryPart = piso
	return modelo
end

local function montarLoja()
	local proprio = ServerStorage:FindFirstChild("LojaTrilhas")
	local modelo: Model = if proprio and proprio:IsA("Model") then proprio:Clone() else barracaDeBlocos()
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
	marco.CFrame = CFrame.lookAt(POSICAO_LOJA, olhar) * CFrame.new(0, 3, -math.max(tamanho.Z / 2, 4) - 1)
	marco.Parent = modelo
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Loja"
	prompt.ActionText = "Abrir loja"
	prompt.ObjectText = "Trilhas"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 14
	prompt:SetAttribute("AbreLoja", "Trilhas")
	prompt.Parent = marco
	-- placa grande em cima da barraca
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

	modelo.Parent = Workspace:FindFirstChild("Mapa") or Workspace
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

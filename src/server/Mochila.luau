-- Mochila: os ovos levados para a base vão para a mochila do Roblox (a barra
-- de ferramentas embaixo da tela), um item para cada ovo. O jogador escolhe
-- quando pôr cada um para chocar: equipa o ovo e clica dentro da própria base.
-- A lista fica em Dados.mochila (é salva); as ferramentas são refeitas sempre
-- que o personagem nasce de novo, porque o Roblox esvazia a mochila.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Bases = require(script.Parent.Bases)
local Dados = require(script.Parent.Dados)
local Modelos = require(script.Parent.Modelos)

local Mochila = {}

local VERMELHO = Color3.fromRGB(255, 90, 90)
local VERDE = Color3.fromRGB(90, 255, 120)
local ESCALA_NA_MAO = 0.45

-- Ferramenta de cada ovo, para achar o item quando o jogador usa ela.
local ferramentas: { [Player]: { [Tool]: any } } = {}
local prontos: { [Player]: boolean } = {}

local function atualizarContagem(player: Player)
	player:SetAttribute("OvosMochila", #Dados.mochila(player))
end

local function colocarParaChocar(player: Player, ferramenta: Tool)
	local item = ferramentas[player] and ferramentas[player][ferramenta]
	local lista = Dados.mochila(player)
	local indice = item and table.find(lista, item)
	if not indice then
		return
	end
	local base = Bases.doJogador(player)
	local personagem = player.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not base or not raiz or not Bases.dentro(base, raiz.Position) then
		Avisos.enviar(player, "Vá até a sua base para pôr o ovo para chocar!", VERMELHO)
		Avisos.som(player, "Erro")
		return
	end
	if not Bases.vagaLivre(base) then
		Avisos.enviar(player, "Sua base está cheia! Venda um Brainrot para abrir vaga.", VERMELHO)
		Avisos.som(player, "Erro")
		return
	end
	table.remove(lista, indice)
	ferramentas[player][ferramenta] = nil
	ferramenta:Destroy()
	Bases.colocar(base, item)
	atualizarContagem(player)
	local def = Config.ovo(item.id)
	Avisos.enviar(player, `{def.nome} está chocando!`, VERDE)
	Avisos.som(player, "Entregou")
	Avisos.efeito("Entregou", { posicao = raiz.Position, raridade = def.raridade, roubo = false, userId = player.UserId })
end

-- O ovo de blocos, pequeno, preso na mão.
local function criarFerramenta(player: Player, item: any): Tool
	local def = Config.ovo(item.id)
	local ferramenta = Instance.new("Tool")
	ferramenta.Name = def.nome
	ferramenta.ToolTip = `{def.raridade} · {item.tamanho or "Normal"}: clique na sua base para chocar`
	ferramenta.CanBeDropped = false
	ferramenta:SetAttribute("OvoMochila", true)
	ferramenta:SetAttribute("Raridade", def.raridade)

	local modelo = Modelos.criar(item)
	-- sem placa, sem botão e sem os efeitos de ovo do chão
	for _, objeto in modelo:GetDescendants() do
		if objeto:IsA("BillboardGui") or objeto:IsA("ProximityPrompt") then
			objeto:Destroy()
		end
	end
	CollectionService:RemoveTag(modelo, "Ovo")
	modelo:ScaleTo(modelo:GetScale() * ESCALA_NA_MAO)
	local principal = modelo.PrimaryPart :: BasePart
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("BasePart") then
			parte.Anchored = false
			parte.CanCollide = false
			parte.CanQuery = false
			parte.CanTouch = false
			parte.Massless = true
		end
	end
	-- a peça principal vira o "Handle" (as outras já estão soldadas nela)
	modelo.Parent = ferramenta
	principal.Name = "Handle"
	principal.Parent = ferramenta
	ferramenta.Grip = CFrame.new(0, 0.2, 0)

	ferramenta.Activated:Connect(function()
		colocarParaChocar(player, ferramenta)
	end)
	ferramentas[player] = ferramentas[player] or {}
	ferramentas[player][ferramenta] = item
	return ferramenta
end

-- Refaz todas as ferramentas da mochila (o personagem nasceu de novo).
local function refazer(player: Player)
	local mochila = player:FindFirstChildOfClass("Backpack")
	if not mochila or not prontos[player] then
		return
	end
	local antigas = ferramentas[player] or {}
	ferramentas[player] = {}
	for ferramenta in antigas do
		ferramenta:Destroy()
	end
	for _, item in Dados.mochila(player) do
		criarFerramenta(player, item).Parent = mochila
	end
	atualizarContagem(player)
end

function Mochila.cheia(player: Player): boolean
	return #Dados.mochila(player) >= Config.MOCHILA_MAXIMO
end

-- Guarda um ovo na mochila. Devolve false se ela estiver cheia.
function Mochila.adicionar(player: Player, item: any): boolean
	if not prontos[player] or Mochila.cheia(player) or item.tipo ~= "ovo" then
		return false
	end
	table.insert(Dados.mochila(player), item)
	local mochila = player:FindFirstChildOfClass("Backpack")
	if mochila then
		criarFerramenta(player, item).Parent = mochila
	end
	atualizarContagem(player)
	return true
end

-- Chamado quando os dados do jogador já foram carregados.
function Mochila.entrar(player: Player)
	prontos[player] = true
	refazer(player)
end

function Mochila.iniciar()
	local function aoEntrar(player: Player)
		player.CharacterAdded:Connect(function()
			-- a mochila nova é criada junto com o personagem
			player:WaitForChild("Backpack")
			refazer(player)
		end)
	end
	Players.PlayerAdded:Connect(aoEntrar)
	for _, player in Players:GetPlayers() do
		aoEntrar(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ferramentas[player] = nil
		prontos[player] = nil
	end)
end

return Mochila

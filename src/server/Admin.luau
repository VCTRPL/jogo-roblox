-- Comandos de admin no chat (só o dono do jogo e quem estiver em Config.ADMINS):
--   /dar 1M            dá $1M para você
--   /dar NOME 1M       dá $1M para o jogador (nome ou apelido, pode ser só o começo)
--   /salvar            salva agora e mostra o resultado
--   /status            mostra o que está carregado (dinheiro, trilha, salvamento)
-- Valores aceitam K, M, B e T (1.5M = 1500000).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)

local Admin = {}

local AMARELO = Color3.fromRGB(255, 220, 90)
local VERMELHO = Color3.fromRGB(255, 90, 90)
local SUFIXOS = { K = 1e3, M = 1e6, B = 1e9, T = 1e12 }

function Admin.eh(player: Player): boolean
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
		if ok and rank == 255 then
			return true
		end
	end
	return table.find(Config.ADMINS, player.UserId) ~= nil
end

-- Mensagem que só o admin vê.
function Admin.avisar(player: Player, texto: string, cor: Color3?)
	if Admin.eh(player) then
		Avisos.enviar(player, `[Admin] {texto}`, cor or AMARELO)
	end
end

-- "1.5M" -> 1500000
local function valor(texto: string?): number?
	if not texto then
		return nil
	end
	local numero, sufixo = string.match(string.upper(texto), "^([%d%.]+)([KMBT]?)$")
	local n = tonumber(numero)
	if not n then
		return nil
	end
	return math.floor(n * (SUFIXOS[sufixo] or 1))
end

local function acharJogador(nome: string): Player?
	nome = string.lower(nome)
	for _, player in Players:GetPlayers() do
		if string.lower(player.Name) == nome or string.lower(player.DisplayName) == nome then
			return player
		end
	end
	for _, player in Players:GetPlayers() do
		if
			string.sub(string.lower(player.Name), 1, #nome) == nome
			or string.sub(string.lower(player.DisplayName), 1, #nome) == nome
		then
			return player
		end
	end
	return nil
end

-- acoes: dar(alvo, quantia), salvar(player) -> boolean, status(player) -> string
function Admin.iniciar(acoes)
	local function executar(player: Player, texto: string)
		if not Admin.eh(player) then
			return
		end
		local partes = string.split(texto, " ")
		local comando = string.lower(partes[1] or "")
		if comando == "/dar" then
			local alvo, quantia = player, valor(partes[2])
			if not quantia and partes[2] then
				alvo = acharJogador(partes[2])
				quantia = valor(partes[3])
			end
			if not alvo then
				Admin.avisar(player, `Não achei o jogador "{partes[2]}".`, VERMELHO)
			elseif not quantia or quantia <= 0 then
				Admin.avisar(player, "Use: /dar 1M  ou  /dar NOME 1M", VERMELHO)
			else
				acoes.dar(alvo, quantia)
				Admin.avisar(player, `Deu ${Config.formatar(quantia)} para {alvo.DisplayName}.`)
			end
		elseif comando == "/salvar" then
			if acoes.salvar(player) then
				Admin.avisar(player, "Salvou!")
			else
				Admin.avisar(player, "NÃO salvou. Veja /status.", VERMELHO)
			end
		elseif comando == "/status" then
			Admin.avisar(player, acoes.status(player))
		end
	end

	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		for _, nome in { "dar", "salvar", "status" } do
			local comando = Instance.new("TextChatCommand")
			comando.Name = `Admin_{nome}`
			comando.PrimaryAlias = `/{nome}`
			comando.Triggered:Connect(function(origem: TextSource, texto: string)
				local player = Players:GetPlayerByUserId(origem.UserId)
				if player then
					executar(player, texto)
				end
			end)
			comando.Parent = TextChatService
		end
	else
		local function aoEntrar(player: Player)
			player.Chatted:Connect(function(texto)
				if string.sub(texto, 1, 1) == "/" then
					executar(player, texto)
				end
			end)
		end
		Players.PlayerAdded:Connect(aoEntrar)
		for _, player in Players:GetPlayers() do
			aoEntrar(player)
		end
	end
end

return Admin

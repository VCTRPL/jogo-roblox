-- Ranking: o do servidor (quem está aqui agora) e o global (todo mundo,
-- guardado em OrderedDataStores). Só o servidor calcula e grava; o cliente
-- pede a foto pronta pelo RemoteFunction "Ranking". As categorias e os
-- intervalos ficam em Config.RANKING.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Bases = require(script.Parent.Bases)
local Dados = require(script.Parent.Dados)

local Ranking = {}

type Linha = { id: number, nome: string, valor: number }

local CATEGORIAS = Config.RANKING.categorias
local QUANTOS = Config.RANKING.quantos

local ordenados: { [string]: OrderedDataStore } = {}
-- O ranking global para de tentar quando o DataStore não existe (no Studio
-- sem acesso às APIs, por exemplo). Nunca mostramos o do servidor no lugar.
local globalDesligado = false
local globalErro: string? = "Carregando o ranking global..."

local fotoServidor: { [string]: { Linha } } = {}
local fotoGlobal: { [string]: { Linha } }? = nil
local globalEm = 0
local nomes: { [number]: string } = {}
-- O que já foi gravado de cada jogador, para não gravar o mesmo número de novo.
local gravado: { [Player]: { [string]: number } } = {}
local ultimoPedido: { [Player]: number } = {}

local function desligarGlobal(erro: any)
	local texto = tostring(erro)
	if string.find(texto, "Studio access to APIs") or string.find(texto, "StudioAccessToApisNotAllowed") then
		globalDesligado = true
		globalErro = "O ranking global só funciona no jogo publicado."
	else
		globalErro = "Ranking global indisponível agora. Tente de novo daqui a pouco."
	end
	warn("Ranking global:", texto)
end

for _, categoria in CATEGORIAS do
	local ok, resultado = pcall(function()
		return DataStoreService:GetOrderedDataStore(`Ranking_{categoria.chave}_v1`)
	end)
	if ok then
		ordenados[categoria.chave] = resultado
	else
		desligarGlobal(resultado)
		break
	end
end

local function valorDe(player: Player, chave: string): number
	if chave == "ValorBase" then
		local base = Bases.doJogador(player)
		return if base then Bases.valor(base) else 0
	end
	return Dados.estatistica(player, chave)
end

-- Ranking de quem está no servidor agora (todos, do maior para o menor).
local function montarServidor()
	local foto = {}
	for _, categoria in CATEGORIAS do
		local lista: { Linha } = {}
		for _, player in Players:GetPlayers() do
			if Dados.pronto(player) then
				table.insert(lista, { id = player.UserId, nome = player.DisplayName, valor = valorDe(player, categoria.chave) })
			end
		end
		table.sort(lista, function(a, b)
			if a.valor ~= b.valor then
				return a.valor > b.valor
			end
			return a.id < b.id
		end)
		foto[categoria.chave] = lista
	end
	fotoServidor = foto
end

local function nomeDe(id: number): string
	if nomes[id] then
		return nomes[id]
	end
	local player = Players:GetPlayerByUserId(id)
	if player then
		return player.DisplayName
	end
	local ok, nome = pcall(function()
		return Players:GetNameFromUserIdAsync(id)
	end)
	nomes[id] = if ok and nome then nome else `Jogador {id}`
	return nomes[id]
end

-- Lê o top de cada categoria nas OrderedDataStores.
local function lerGlobal()
	if globalDesligado then
		return
	end
	local foto = {}
	for _, categoria in CATEGORIAS do
		local store = ordenados[categoria.chave]
		local ok, pagina = pcall(function()
			return store:GetSortedAsync(false, QUANTOS):GetCurrentPage()
		end)
		if not ok then
			desligarGlobal(pagina)
			return -- fica com a foto anterior (ou nenhuma)
		end
		local lista: { Linha } = {}
		for _, entrada in pagina do
			local id = tonumber(entrada.key)
			if id then
				table.insert(lista, { id = id, nome = nomeDe(id), valor = entrada.value })
			end
		end
		foto[categoria.chave] = lista
		task.wait(1) -- espaça as leituras
	end
	fotoGlobal = foto
	globalEm = os.time()
	globalErro = nil
end

-- Grava os números do jogador no ranking global. Só de quem teve os dados
-- carregados do DataStore: senão um jogador que caiu no carregamento
-- apareceria com zero.
function Ranking.gravar(player: Player)
	if globalDesligado or not Dados.carregado(player) then
		return
	end
	local ja = gravado[player] or {}
	gravado[player] = ja
	for _, categoria in CATEGORIAS do
		local valor = math.floor(valorDe(player, categoria.chave))
		if valor > 0 and ja[categoria.chave] ~= valor then
			local ok, erro = pcall(function()
				ordenados[categoria.chave]:SetAsync(tostring(player.UserId), valor)
			end)
			if ok then
				ja[categoria.chave] = valor
			else
				desligarGlobal(erro)
				return
			end
		end
	end
end

function Ranking.sair(player: Player)
	Ranking.gravar(player)
	gravado[player] = nil
	ultimoPedido[player] = nil
end

function Ranking.iniciar()
	local remoto = Instance.new("RemoteFunction")
	remoto.Name = "Ranking"
	remoto.Parent = ReplicatedStorage:WaitForChild("Remotes")
	remoto.OnServerInvoke = function(player: Player)
		-- no máximo um pedido por segundo; a foto já vem pronta
		local agora = os.clock()
		if agora - (ultimoPedido[player] or 0) < 1 then
			return nil
		end
		ultimoPedido[player] = agora
		return {
			servidor = fotoServidor,
			global = fotoGlobal,
			globalEm = globalEm,
			globalErro = globalErro,
			agora = os.time(),
		}
	end

	task.spawn(function()
		while true do
			montarServidor()
			task.wait(Config.RANKING.servidorSegundos)
		end
	end)
	task.spawn(function()
		while not globalDesligado do
			lerGlobal()
			task.wait(Config.RANKING.globalSegundos)
		end
	end)
	-- grava cada jogador de tempos em tempos, um de cada vez
	task.spawn(function()
		while not globalDesligado do
			task.wait(Config.RANKING.gravarSegundos)
			for _, player in Players:GetPlayers() do
				Ranking.gravar(player)
				task.wait(2)
			end
		end
	end)
end

return Ranking

-- Placar (Dinheiro, Velocidade, Roubos e Renascimentos), estatísticas do
-- ranking e salvamento com DataStore.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Dados = {}

local store = nil
if Config.SALVAR_DADOS then
	local ok, resultado = pcall(function()
		return DataStoreService:GetDataStore("RoubeUmOvoBrainrot_v1")
	end)
	if ok then
		store = resultado
	else
		warn("DataStore indisponível, o progresso não será salvo:", resultado)
	end
end

-- Estatísticas do ranking que ficam salvas. Cada uma vira o atributo
-- "Est_<nome>" no jogador (só o servidor escreve; o cliente só lê).
--   Brainrots: Brainrots ganhos (chocados e comprados; roubar não conta,
--     senão dois amigos subiam no ranking roubando um do outro)
--   Ovos: ovos chocados
--   DinheiroTotal: todo o dinheiro ganho, mesmo o já gasto
--   VelocidadeMax: a maior Velocidade que já teve (o renascimento não zera)
Dados.ESTATISTICAS = { "Brainrots", "Ovos", "DinheiroTotal", "VelocidadeMax" }

-- Quantas compras com Robux ficam lembradas por jogador (para não dar duas vezes).
local MAX_COMPRAS = 100
local MAXIMO = 2 ^ 53

-- Se o carregamento falhar, não salvamos por cima para não apagar o progresso.
local podeSalvar: { [Player]: boolean } = {}
-- Brainrots comprados que ainda não couberam na base.
local pendentes: { [Player]: { any } } = {}
-- PurchaseIds de compras com Robux já entregues.
local compras: { [Player]: { string } } = {}

local function chave(player: Player): string
	return `jogador_{player.UserId}`
end

local function stat(player: Player, nome: string): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(nome) :: IntValue?
end

-- Número inteiro e não negativo, ou "padrao" se o valor salvo estiver estranho.
local function numero(valor: any, padrao: number): number
	if typeof(valor) ~= "number" or valor ~= valor or valor < 0 then
		return padrao
	end
	return math.min(math.floor(valor), MAXIMO)
end

function Dados.temStore(): boolean
	return store ~= nil
end

-- true se os dados vieram do DataStore (então dá para salvar e entrar no ranking global).
function Dados.carregado(player: Player): boolean
	return podeSalvar[player] == true
end

-- true depois que Dados.carregar terminou (com ou sem DataStore).
function Dados.pronto(player: Player): boolean
	return compras[player] ~= nil
end

-- Cria o placar e devolve os itens salvos da base.
function Dados.carregar(player: Player): { any }
	local salvo = nil
	if store then
		local ok, resultado = pcall(function()
			return store:GetAsync(chave(player))
		end)
		if ok then
			salvo = resultado
			podeSalvar[player] = true
		else
			warn(`Não consegui carregar os dados de {player.Name}:`, resultado)
		end
	end
	if typeof(salvo) ~= "table" then
		salvo = {}
	end

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local dinheiro = Instance.new("IntValue")
	dinheiro.Name = "Dinheiro"
	dinheiro.Value = numero(salvo.dinheiro, Config.DINHEIRO_INICIAL)
	dinheiro.Parent = stats
	local velocidade = Instance.new("IntValue")
	velocidade.Name = "Velocidade"
	velocidade.Value = numero(salvo.velocidade, 0)
	velocidade.Parent = stats
	local roubos = Instance.new("IntValue")
	roubos.Name = "Roubos"
	roubos.Value = numero(salvo.roubos, 0)
	roubos.Parent = stats
	local renascimentos = Instance.new("IntValue")
	renascimentos.Name = "Renascimentos"
	renascimentos.Value = math.min(numero(salvo.renascimentos, 0), Config.RENASCER.maximo)
	renascimentos.Parent = stats
	stats.Parent = player

	local nivel = numero(salvo.nivelEsteira, 1)
	player:SetAttribute("NivelEsteira", math.clamp(nivel, 1, #Config.NIVEIS_ESTEIRA))

	local estatisticas = if typeof(salvo.estatisticas) == "table" then salvo.estatisticas else {}
	for _, nome in Dados.ESTATISTICAS do
		player:SetAttribute(`Est_{nome}`, numero(estatisticas[nome], 0))
	end
	-- quem já jogava antes do ranking começa com o que tem agora
	Dados.recorde(player, "DinheiroTotal", dinheiro.Value)
	Dados.recorde(player, "VelocidadeMax", velocidade.Value)

	pendentes[player] = {}
	if typeof(salvo.pendentes) == "table" then
		for _, item in salvo.pendentes do
			if typeof(item) == "table" and item.tipo == "brainrot" and Config.brainrot(item.id) then
				table.insert(pendentes[player], item)
			end
		end
	end
	compras[player] = {}
	if typeof(salvo.compras) == "table" then
		for _, id in salvo.compras do
			if typeof(id) == "string" then
				table.insert(compras[player], id)
			end
		end
	end

	return if typeof(salvo.itens) == "table" then salvo.itens else {}
end

-- Salva tudo. Devolve true se gravou no DataStore.
function Dados.salvar(player: Player, itens: { any }): boolean
	local dinheiro = stat(player, "Dinheiro")
	local velocidade = stat(player, "Velocidade")
	if not store or not dinheiro or not velocidade or not podeSalvar[player] then
		return false
	end
	local estatisticas = {}
	for _, nome in Dados.ESTATISTICAS do
		estatisticas[nome] = Dados.estatistica(player, nome)
	end
	local ok, erro = pcall(function()
		store:SetAsync(chave(player), {
			dinheiro = dinheiro.Value,
			velocidade = velocidade.Value,
			roubos = Dados.valor(player, "Roubos"),
			renascimentos = Dados.valor(player, "Renascimentos"),
			nivelEsteira = player:GetAttribute("NivelEsteira"),
			itens = itens,
			estatisticas = estatisticas,
			pendentes = pendentes[player],
			compras = compras[player],
		}, { player.UserId })
	end)
	if not ok then
		warn(`Não consegui salvar os dados de {player.Name}:`, erro)
	end
	return ok
end

function Dados.esquecer(player: Player)
	podeSalvar[player] = nil
	pendentes[player] = nil
	compras[player] = nil
end

-- nome: "Dinheiro", "Velocidade", "Roubos" ou "Renascimentos"
function Dados.valor(player: Player, nome: string): number
	local valor = stat(player, nome)
	return if valor then valor.Value else 0
end

function Dados.adicionar(player: Player, nome: string, quantia: number)
	local valor = stat(player, nome)
	if valor then
		valor.Value += quantia
		if nome == "Dinheiro" and quantia > 0 then
			Dados.somarEstatistica(player, "DinheiroTotal", quantia)
		elseif nome == "Velocidade" then
			Dados.recorde(player, "VelocidadeMax", valor.Value)
		end
	end
end

function Dados.definir(player: Player, nome: string, quantia: number)
	local valor = stat(player, nome)
	if valor then
		valor.Value = quantia
		if nome == "Velocidade" then
			Dados.recorde(player, "VelocidadeMax", quantia)
		end
	end
end

-- Estatísticas do ranking (Dados.ESTATISTICAS).
function Dados.estatistica(player: Player, nome: string): number
	return player:GetAttribute(`Est_{nome}`) or 0
end

function Dados.somarEstatistica(player: Player, nome: string, quantia: number)
	if quantia > 0 then
		player:SetAttribute(`Est_{nome}`, math.min(Dados.estatistica(player, nome) + math.floor(quantia), MAXIMO))
	end
end

-- Guarda "valor" se for maior que o recorde.
function Dados.recorde(player: Player, nome: string, valor: number)
	if valor > Dados.estatistica(player, nome) then
		player:SetAttribute(`Est_{nome}`, math.min(math.floor(valor), MAXIMO))
	end
end

-- Brainrots comprados esperando vaga na base.
function Dados.pendentes(player: Player): { any }
	return pendentes[player] or {}
end

function Dados.adicionarPendente(player: Player, item: any)
	if pendentes[player] then
		table.insert(pendentes[player], item)
	end
end

function Dados.tirarPendente(player: Player): any?
	local lista = pendentes[player]
	return lista and table.remove(lista, 1)
end

-- Compras com Robux já entregues (pelo PurchaseId do recibo).
function Dados.jaEntregue(player: Player, compraId: string): boolean
	return compras[player] ~= nil and table.find(compras[player], compraId) ~= nil
end

function Dados.registrarCompra(player: Player, compraId: string)
	local lista = compras[player]
	if not lista then
		return
	end
	table.insert(lista, compraId)
	while #lista > MAX_COMPRAS do
		table.remove(lista, 1)
	end
end

return Dados

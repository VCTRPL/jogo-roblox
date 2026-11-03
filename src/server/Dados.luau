-- Placar (Dinheiro, Velocidade, Roubos e Renascimentos), estatísticas do
-- ranking e salvamento com DataStore.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Admin = require(script.Parent.Admin)

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
-- Inventário: ovos e Brainrots (comprados ou trazidos com a base cheia) que
-- ainda não couberam na base. Entram sozinhos quando abre uma vaga.
local pendentes: { [Player]: { any } } = {}
-- Mochila: ovos trazidos para a base que o jogador ainda não pôs para chocar.
local mochila: { [Player]: { any } } = {}
-- PurchaseIds de compras com Robux já entregues.
local compras: { [Player]: { string } } = {}
-- Pilha de dinheiro do farm AFK que ainda está na base esperando ser coletada.
local pilha: { [Player]: number } = {}
-- Quanto da pilha veio desta vez (para o aviso) e quanto tempo ficou fora.
local offline: { [Player]: { ganho: number, segundos: number } } = {}

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
			local trilha = if typeof(resultado) == "table" then resultado.nivelTrilha else nil
			local texto = `Carregou: save {if resultado then "encontrado" else "novo"}, trilha {trilha or 0}`
			print(`[Dados] {player.Name} {texto}`)
			task.delay(6, Admin.avisar, player, texto)
		else
			warn(`Não consegui carregar os dados de {player.Name}:`, resultado)
			task.delay(6, Admin.avisar, player, `Falhou ao carregar: {resultado}`, Color3.fromRGB(255, 90, 90))
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
	-- trilhas: quantas já comprou (sempre em ordem) e qual está usando
	local nivelTrilha = math.clamp(numero(salvo.nivelTrilha, 0), 0, #Config.TRILHAS)
	player:SetAttribute("NivelTrilha", nivelTrilha)
	local equipada = if typeof(salvo.trilha) == "number" then math.floor(salvo.trilha) else nivelTrilha
	player:SetAttribute("TrilhaEquipada", math.clamp(equipada, 0, nivelTrilha))

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
			local valido = typeof(item) == "table"
				and ((item.tipo == "brainrot" and Config.brainrot(item.id)) or (item.tipo == "ovo" and Config.ovo(item.id)))
			if valido then
				table.insert(pendentes[player], item)
			end
		end
	end
	mochila[player] = {}
	if typeof(salvo.mochila) == "table" then
		for _, item in salvo.mochila do
			if typeof(item) == "table" and item.tipo == "ovo" and Config.ovo(item.id) and #mochila[player] < Config.MOCHILA_MAXIMO then
				table.insert(mochila[player], item)
			end
		end
	end
	-- Brainrots que o jogador já teve (o Índice mostra a foto deles)
	if typeof(salvo.indice) == "table" then
		for _, id in salvo.indice do
			if typeof(id) == "string" and Config.brainrot(id) then
				player:SetAttribute(`Ind_{id}`, true)
			end
		end
	end

	player:SetAttribute("Pendentes", #pendentes[player])

	-- Farm AFK: a base rendeu enquanto ele estava fora. Soma com a pilha que
	-- ele deixou sem coletar da última vez.
	local guardado = numero(salvo.pilha, 0)
	local ganho, segundos = 0, 0
	local farm = Config.FARM_OFFLINE
	if typeof(salvo.saidaEm) == "number" and typeof(salvo.rendaOffline) == "number" then
		segundos = math.clamp(os.time() - salvo.saidaEm, 0, farm.maximoHoras * 3600)
		if segundos >= farm.minimoSegundos then
			ganho = numero(numero(salvo.rendaOffline, 0) * segundos * farm.porcentagem, 0)
		end
	end
	pilha[player] = math.min(guardado + ganho, MAXIMO)
	offline[player] = { ganho = ganho, segundos = segundos }

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

-- Salva tudo. "renda" é o dinheiro por segundo da base agora (para o farm
-- AFK). Devolve true se gravou no DataStore.
function Dados.salvar(player: Player, itens: { any }, renda: number): boolean
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
			nivelTrilha = player:GetAttribute("NivelTrilha") or 0,
			trilha = player:GetAttribute("TrilhaEquipada") or 0,
			itens = itens,
			estatisticas = estatisticas,
			pendentes = pendentes[player],
			mochila = mochila[player],
			compras = compras[player],
			indice = Dados.indice(player),
			-- farm AFK: quanto rendia por segundo e quando foi a última vez
			-- que estava no jogo (o autosave também atualiza, caso o servidor caia)
			rendaOffline = numero(renda, 0),
			saidaEm = os.time(),
			pilha = pilha[player] or 0,
		}, { player.UserId })
	end)
	if ok then
		local texto = `Salvou: ${Config.formatar(dinheiro.Value)}, trilha {player:GetAttribute("NivelTrilha") or 0}`
		print(`[Dados] {player.Name} {texto}`)
		Admin.avisar(player, texto)
	else
		warn(`Não consegui salvar os dados de {player.Name}:`, erro)
		Admin.avisar(player, `Falhou ao salvar: {erro}`, Color3.fromRGB(255, 90, 90))
	end
	return ok
end

function Dados.esquecer(player: Player)
	podeSalvar[player] = nil
	pendentes[player] = nil
	mochila[player] = nil
	compras[player] = nil
	pilha[player] = nil
	offline[player] = nil
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

-- Índice: marca o Brainrot como descoberto. Devolve true se for a primeira vez.
function Dados.descobrir(player: Player, id: string): boolean
	if player:GetAttribute(`Ind_{id}`) or not Config.brainrot(id) then
		return false
	end
	player:SetAttribute(`Ind_{id}`, true)
	return true
end

function Dados.indice(player: Player): { string }
	local lista = {}
	for _, def in Config.BRAINROTS do
		if player:GetAttribute(`Ind_{def.id}`) then
			table.insert(lista, def.id)
		end
	end
	return lista
end

-- Inventário (itens esperando vaga na base). O atributo "Pendentes" é a
-- quantidade, para o cliente mostrar.
function Dados.pendentes(player: Player): { any }
	return pendentes[player] or {}
end

function Dados.adicionarPendente(player: Player, item: any)
	if pendentes[player] then
		table.insert(pendentes[player], item)
		player:SetAttribute("Pendentes", #pendentes[player])
	end
end

function Dados.tirarPendente(player: Player): any?
	local lista = pendentes[player]
	local item = lista and table.remove(lista, 1)
	if lista then
		player:SetAttribute("Pendentes", #lista)
	end
	return item
end

-- Ovos da mochila (Mochila.luau cria uma ferramenta para cada um).
function Dados.mochila(player: Player): { any }
	return mochila[player] or {}
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

-- Farm AFK: quanto tem na pilha da base esperando ser coletado.
function Dados.pilha(player: Player): number
	return pilha[player] or 0
end

-- Esvazia a pilha e devolve quanto tinha.
function Dados.esvaziarPilha(player: Player): number
	local quantia = pilha[player] or 0
	if pilha[player] then
		pilha[player] = 0
	end
	return quantia
end

-- Quanto rendeu desta última vez fora e por quantos segundos.
function Dados.offline(player: Player): (number, number)
	local info = offline[player]
	if not info then
		return 0, 0
	end
	return info.ganho, info.segundos
end

return Dados

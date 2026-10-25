-- Configurações do jogo. Mude os números aqui para balancear o jogo.
local Config = {}

Config.DINHEIRO_INICIAL = 50
Config.VAGAS_POR_BASE = 10
Config.TEMPO_TRANCA = 60 -- segundos que a base fica trancada
Config.TEMPO_NINHOS = 180 -- segundos para os ninhos ganharem ovos novos
Config.SALVAR_DADOS = true

-- Velocidade: o atributo principal. A velocidade de andar é
-- VELOCIDADE_BASE + Velocidade / PONTOS_POR_VELOCIDADE (até VELOCIDADE_MAXIMA).
Config.VELOCIDADE_BASE = 16
Config.PONTOS_POR_VELOCIDADE = 5
Config.VELOCIDADE_MAXIMA = 120
Config.TEMPO_ATORDOADO = 2 -- segundos parado depois que o guardião te pega

-- Esteira de corrida da base: quanto de Velocidade ganha a cada meio segundo em cima dela.
Config.NIVEIS_ESTEIRA = {
	{ ganho = 1, preco = 0 },
	{ ganho = 2, preco = 500 },
	{ ganho = 5, preco = 15000 },
	{ ganho = 12, preco = 250000 },
	{ ganho = 30, preco = 5000000 },
}

Config.CORES_RARIDADE = {
	Comum = Color3.fromRGB(190, 190, 190),
	Raro = Color3.fromRGB(70, 140, 255),
	Epico = Color3.fromRGB(170, 80, 255),
	Lendario = Color3.fromRGB(255, 190, 40),
	Mitico = Color3.fromRGB(255, 60, 80),
}

-- Velocidade ganha quando um ovo choca, por raridade.
Config.BONUS_VELOCIDADE = { Comum = 2, Raro = 5, Epico = 10, Lendario = 25, Mitico = 60 }

-- Tamanho do ovo: mais renda, mas quem carrega fica mais lento.
Config.TAMANHOS = {
	{ nome = "Pequeno", chance = 40, renda = 1, peso = 1, escala = 0.8 },
	{ nome = "Medio", chance = 35, renda = 1.5, peso = 0.9, escala = 1 },
	{ nome = "Grande", chance = 18, renda = 2.5, peso = 0.75, escala = 1.3 },
	{ nome = "Gigante", chance = 7, renda = 4, peso = 0.6, escala = 1.7 },
}

-- Mutação sorteada quando o ovo choca.
Config.MUTACOES = {
	{ nome = "Normal", chance = 80, renda = 1, cor = nil },
	{ nome = "Prata", chance = 12, renda = 1.2, cor = Color3.fromRGB(220, 225, 235) },
	{ nome = "Dourado", chance = 6, renda = 2.5, cor = Color3.fromRGB(255, 200, 40) },
	{ nome = "Arco-iris", chance = 2, renda = 3.5, cor = Color3.fromRGB(255, 90, 200) },
}

-- Os Brainrots que nascem dos ovos. "renda" é dinheiro por segundo.
-- "cor" é a cor do corpo e "corCabeca" a da cabeça no boneco padrão.
-- O "id" é o nome do modelo em ReplicatedStorage.ModelosBrainrot (opcional, veja o README).
Config.BRAINROTS = {
	{ id = "Patapim", nome = "Brr Brr Patapim", raridade = "Comum", renda = 1,
		cor = Color3.fromRGB(110, 150, 70), corCabeca = Color3.fromRGB(150, 110, 70) },
	{ id = "Larila", nome = "Lirilì Larilà", raridade = "Comum", renda = 3,
		cor = Color3.fromRGB(120, 170, 90), corCabeca = Color3.fromRGB(170, 160, 150) },
	{ id = "Bananini", nome = "Chimpanzini Bananini", raridade = "Raro", renda = 10,
		cor = Color3.fromRGB(255, 220, 60), corCabeca = Color3.fromRGB(110, 80, 50) },
	{ id = "Cappuccina", nome = "Ballerina Cappuccina", raridade = "Epico", renda = 40,
		cor = Color3.fromRGB(255, 170, 200), corCabeca = Color3.fromRGB(120, 80, 50) },
	{ id = "Tralalero", nome = "Tralalero Tralala", raridade = "Lendario", renda = 150,
		cor = Color3.fromRGB(80, 160, 230), corCabeca = Color3.fromRGB(70, 140, 210) },
	{ id = "Bombardiro", nome = "Bombardiro Crocodilo", raridade = "Mitico", renda = 800,
		cor = Color3.fromRGB(90, 110, 80), corCabeca = Color3.fromRGB(60, 140, 60) },
}

-- Os ovos: qual Brainrot nasce e quantos segundos leva para chocar.
-- O "id" é o nome do modelo em ReplicatedStorage.ModelosOvo (opcional).
Config.OVOS = {
	{ id = "OvoPatapim", nome = "Ovo Patapim", raridade = "Comum", brainrot = "Patapim", chocar = 20 },
	{ id = "OvoLarila", nome = "Ovo Larilà", raridade = "Comum", brainrot = "Larila", chocar = 30 },
	{ id = "OvoBananini", nome = "Ovo Bananini", raridade = "Raro", brainrot = "Bananini", chocar = 45 },
	{ id = "OvoCappuccina", nome = "Ovo Cappuccina", raridade = "Epico", brainrot = "Cappuccina", chocar = 90 },
	{ id = "OvoTralalero", nome = "Ovo Tralalero", raridade = "Lendario", brainrot = "Tralalero", chocar = 180 },
	{ id = "OvoBombardiro", nome = "Ovo Bombardiro", raridade = "Mitico", brainrot = "Bombardiro", chocar = 300 },
}

-- Raridades que, ao chocar, são anunciadas para o servidor inteiro.
Config.ANUNCIAR_RARIDADES = { Lendario = true, Mitico = true }
Config.ANUNCIAR_MUTACOES = { ["Arco-iris"] = true }

-- Biomas, na ordem da estrada. Cada um precisa de uma Velocidade mínima para entrar.
-- "estilo" escolhe a decoração ("floresta" ou "praia") e "guardiao" é quem
-- persegue quem pega um ovo. "ovos" lista os ovos dos ninhos e a chance de cada um.
Config.BIOMAS = {
	{
		nome = "Selva Sahur",
		estilo = "floresta",
		guardiao = "Tung Tung Tung Sahur",
		corGuardiao = Color3.fromRGB(150, 100, 60),
		velocidadeMinima = 0,
		velocidadeGuardiao = 14,
		cor = Color3.fromRGB(80, 160, 70),
		ovos = { OvoPatapim = 50, OvoLarila = 30, OvoBananini = 15, OvoCappuccina = 5 },
	},
	{
		nome = "Praia Tralalá",
		estilo = "praia",
		guardiao = "Cappuccino Assassino",
		corGuardiao = Color3.fromRGB(70, 40, 30),
		velocidadeMinima = 150,
		velocidadeGuardiao = 30,
		cor = Color3.fromRGB(70, 150, 210),
		ovos = { OvoBananini = 40, OvoCappuccina = 35, OvoTralalero = 20, OvoBombardiro = 5 },
	},
}

local brainrotPorId = {}
for _, brainrot in Config.BRAINROTS do
	brainrotPorId[brainrot.id] = brainrot
end
local ovoPorId = {}
for _, ovo in Config.OVOS do
	ovoPorId[ovo.id] = ovo
end
local tamanhoPorNome = {}
for _, tamanho in Config.TAMANHOS do
	tamanhoPorNome[tamanho.nome] = tamanho
end
local mutacaoPorNome = {}
for _, mutacao in Config.MUTACOES do
	mutacaoPorNome[mutacao.nome] = mutacao
end

local aleatorio = Random.new()

-- Sorteia um item de uma lista em que cada item tem "chance".
local function sortearLista(lista)
	local total = 0
	for _, item in lista do
		total += item.chance
	end
	local sorteio = aleatorio:NextNumber(0, total)
	for _, item in lista do
		sorteio -= item.chance
		if sorteio <= 0 then
			return item
		end
	end
	return lista[1]
end

function Config.brainrot(id: string)
	return brainrotPorId[id]
end

function Config.ovo(id: string)
	return ovoPorId[id]
end

function Config.tamanho(nome: string)
	return tamanhoPorNome[nome] or Config.TAMANHOS[1]
end

function Config.mutacao(nome: string?)
	return mutacaoPorNome[nome or "Normal"] or Config.MUTACOES[1]
end

function Config.sortearTamanho()
	return sortearLista(Config.TAMANHOS)
end

function Config.sortearMutacao()
	return sortearLista(Config.MUTACOES)
end

function Config.sortearOvo(bioma)
	local lista = {}
	for id, chance in bioma.ovos do
		table.insert(lista, { id = id, chance = chance })
	end
	table.sort(lista, function(a, b)
		return a.id < b.id
	end)
	return Config.ovo(sortearLista(lista).id)
end

-- Renda por segundo de um Brainrot já chocado, contando tamanho e mutação.
function Config.renda(item): number
	local brainrot = Config.brainrot(item.id)
	if not brainrot then
		return 0
	end
	return math.floor(brainrot.renda * Config.tamanho(item.tamanho).renda * Config.mutacao(item.mutacao).renda)
end

-- 1500 -> "1.5K", 2000000 -> "2M"
function Config.formatar(valor: number): string
	local sufixos = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, item in sufixos do
		if valor >= item[1] then
			local texto = string.format("%.1f", valor / item[1]):gsub("%.0$", "")
			return texto .. item[2]
		end
	end
	return tostring(math.floor(valor))
end

return Config

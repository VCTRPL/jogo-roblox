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
-- Cada nível tem um modelo de esteira diferente (veja src/server/Esteiras.luau).
Config.NIVEIS_ESTEIRA = {
	{ nome = "Esteira Básica", ganho = 1, preco = 0 },
	{ nome = "Esteira Intermediária", ganho = 2, preco = 500 },
	{ nome = "Esteira Avançada", ganho = 5, preco = 15000 },
	{ nome = "Esteira Épica", ganho = 12, preco = 250000 },
	{ nome = "Esteira Lendária", ganho = 30, preco = 5000000 },
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

-- Os Verities que nascem dos ovos. "renda" é dinheiro por segundo.
-- O "id" é o nome do modelo em ReplicatedStorage.ModelosVerity (opcional, veja o README).
Config.VERITIES = {
	{ id = "VerityComum", nome = "Verity", raridade = "Comum", renda = 1 },
	{ id = "VerityFeliz", nome = "Verity Feliz", raridade = "Comum", renda = 3 },
	{ id = "VerityDourado", nome = "Verity Dourado", raridade = "Raro", renda = 10 },
	{ id = "VerityNinja", nome = "Verity Ninja", raridade = "Epico", renda = 40 },
	{ id = "VerityGigante", nome = "Verity Gigante", raridade = "Lendario", renda = 150 },
	{ id = "VerityCosmico", nome = "Verity Cósmico", raridade = "Mitico", renda = 800 },
}

-- Os ovos: qual Verity nasce e quantos segundos leva para chocar.
-- O "id" é o nome do modelo em ReplicatedStorage.ModelosOvo (opcional).
Config.OVOS = {
	{ id = "OvoComum", nome = "Ovo Comum", raridade = "Comum", verity = "VerityComum", chocar = 20 },
	{ id = "OvoFeliz", nome = "Ovo Feliz", raridade = "Comum", verity = "VerityFeliz", chocar = 30 },
	{ id = "OvoDourado", nome = "Ovo Dourado", raridade = "Raro", verity = "VerityDourado", chocar = 45 },
	{ id = "OvoNinja", nome = "Ovo Ninja", raridade = "Epico", verity = "VerityNinja", chocar = 90 },
	{ id = "OvoGigante", nome = "Ovo Gigante", raridade = "Lendario", verity = "VerityGigante", chocar = 180 },
	{ id = "OvoCosmico", nome = "Ovo Cósmico", raridade = "Mitico", verity = "VerityCosmico", chocar = 300 },
}

-- Biomas, na ordem da estrada. Cada um precisa de uma Velocidade mínima para entrar.
-- "ovos" lista os ovos que aparecem nos ninhos e a chance de cada um.
Config.BIOMAS = {
	{
		nome = "Floresta",
		velocidadeMinima = 0,
		velocidadeGuardiao = 14,
		cor = Color3.fromRGB(80, 160, 70),
		ovos = { OvoComum = 50, OvoFeliz = 30, OvoDourado = 15, OvoNinja = 5 },
	},
	{
		nome = "Lago",
		velocidadeMinima = 150,
		velocidadeGuardiao = 30,
		cor = Color3.fromRGB(70, 150, 210),
		ovos = { OvoDourado = 40, OvoNinja = 35, OvoGigante = 20, OvoCosmico = 5 },
	},
}

local verityPorId = {}
for _, verity in Config.VERITIES do
	verityPorId[verity.id] = verity
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

function Config.verity(id: string)
	return verityPorId[id]
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

-- Renda por segundo de um Verity já chocado, contando tamanho e mutação.
function Config.renda(item): number
	local verity = Config.verity(item.id)
	if not verity then
		return 0
	end
	return math.floor(verity.renda * Config.tamanho(item.tamanho).renda * Config.mutacao(item.mutacao).renda)
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

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

-- Vender: um Brainrot vale "VENDA_SEGUNDOS" segundos da renda dele.
Config.VENDA_SEGUNDOS = 60

-- Fôlego: quanto mais tempo correndo sem parar na esteira, mais Velocidade
-- ganha. Começa em 1x e chega em FOLEGO_MAXIMO depois de FOLEGO_TEMPO segundos.
Config.FOLEGO_TEMPO = 30
Config.FOLEGO_MAXIMO = 2

-- Renascer: zera dinheiro, Velocidade, esteira e a base, e em troca ganha
-- para sempre mais renda e mais Velocidade na esteira.
Config.RENASCER = {
	preco = 2000000, -- preço do primeiro renascimento
	fator = 6, -- cada renascimento custa "fator" vezes o anterior
	bonusRenda = 0.5, -- +50% de dinheiro por renascimento
	bonusEsteira = 0.25, -- +25% de Velocidade na esteira por renascimento
	maximo = 20,
}

-- Esteira de corrida da base: quanto de Velocidade ganha a cada meio segundo em cima dela.
-- Cada nível tem um modelo de esteira diferente (veja src/server/Esteiras.luau).
Config.NIVEIS_ESTEIRA = {
	-- "cor" é a cor do rastro e dos efeitos de quem corre nela.
	{ nome = "Esteira Básica", ganho = 1, preco = 0, cor = Color3.fromRGB(235, 235, 240) },
	{ nome = "Esteira Intermediária", ganho = 2, preco = 500, cor = Color3.fromRGB(0, 170, 255) },
	{ nome = "Esteira Avançada", ganho = 5, preco = 15000, cor = Color3.fromRGB(115, 60, 255) },
	{ nome = "Esteira Épica", ganho = 12, preco = 250000, cor = Color3.fromRGB(255, 165, 20) },
	{ nome = "Esteira Lendária", ganho = 30, preco = 5000000, cor = Color3.fromRGB(255, 35, 45) },
	{ nome = "Esteira Cósmica", ganho = 75, preco = 80000000, cor = Color3.fromRGB(80, 220, 255) },
	{ nome = "Esteira Divina", ganho = 200, preco = 1500000000, cor = Color3.fromRGB(255, 235, 150) },
}

Config.CORES_RARIDADE = {
	Comum = Color3.fromRGB(190, 190, 190),
	Raro = Color3.fromRGB(70, 140, 255),
	Epico = Color3.fromRGB(170, 80, 255),
	Lendario = Color3.fromRGB(255, 190, 40),
	Mitico = Color3.fromRGB(255, 60, 80),
	Secreto = Color3.fromRGB(40, 255, 225),
}

-- Raridades da mais comum para a mais rara, e o nome com acento para a tela.
Config.RARIDADES = { "Comum", "Raro", "Epico", "Lendario", "Mitico", "Secreto" }
Config.NOME_RARIDADE = {
	Comum = "Comum",
	Raro = "Raro",
	Epico = "Épico",
	Lendario = "Lendário",
	Mitico = "Mítico",
	Secreto = "Secreto",
}

-- Velocidade ganha quando um ovo choca, por raridade.
Config.BONUS_VELOCIDADE = { Comum = 2, Raro = 5, Epico = 10, Lendario = 25, Mitico = 60, Secreto = 150 }

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
	{ id = "Ambalabu", nome = "Boneca Ambalabu", raridade = "Raro", renda = 18,
		cor = Color3.fromRGB(45, 45, 50), corCabeca = Color3.fromRGB(95, 175, 70) },
	{ id = "Trippi", nome = "Trippi Troppi", raridade = "Epico", renda = 60,
		cor = Color3.fromRGB(255, 140, 110), corCabeca = Color3.fromRGB(190, 180, 170) },
	{ id = "Frigo", nome = "Frigo Camelo", raridade = "Epico", renda = 90,
		cor = Color3.fromRGB(235, 240, 245), corCabeca = Color3.fromRGB(200, 160, 100) },
	{ id = "Glorbo", nome = "Glorbo Fruttodrillo", raridade = "Lendario", renda = 300,
		cor = Color3.fromRGB(60, 150, 60), corCabeca = Color3.fromRGB(235, 75, 85) },
	{ id = "Cocofanto", nome = "Cocofanto Elefanto", raridade = "Lendario", renda = 450,
		cor = Color3.fromRGB(115, 78, 48), corCabeca = Color3.fromRGB(150, 150, 162) },
	{ id = "Gusini", nome = "Bombombini Gusini", raridade = "Mitico", renda = 1500,
		cor = Color3.fromRGB(110, 120, 100), corCabeca = Color3.fromRGB(242, 242, 242) },
	{ id = "Svinino", nome = "Svinino Bombondino", raridade = "Mitico", renda = 2500,
		cor = Color3.fromRGB(255, 170, 190), corCabeca = Color3.fromRGB(55, 55, 65) },
	{ id = "Udin", nome = "Udin Din Din Dun", raridade = "Secreto", renda = 8000,
		cor = Color3.fromRGB(255, 150, 40), corCabeca = Color3.fromRGB(240, 200, 160) },
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
	{ id = "OvoAmbalabu", nome = "Ovo Ambalabu", raridade = "Raro", brainrot = "Ambalabu", chocar = 50 },
	{ id = "OvoTrippi", nome = "Ovo Trippi", raridade = "Epico", brainrot = "Trippi", chocar = 100 },
	{ id = "OvoFrigo", nome = "Ovo Frigo", raridade = "Epico", brainrot = "Frigo", chocar = 110 },
	{ id = "OvoGlorbo", nome = "Ovo Glorbo", raridade = "Lendario", brainrot = "Glorbo", chocar = 200 },
	{ id = "OvoCocofanto", nome = "Ovo Cocofanto", raridade = "Lendario", brainrot = "Cocofanto", chocar = 220 },
	{ id = "OvoGusini", nome = "Ovo Gusini", raridade = "Mitico", brainrot = "Gusini", chocar = 330 },
	{ id = "OvoSvinino", nome = "Ovo Svinino", raridade = "Mitico", brainrot = "Svinino", chocar = 360 },
	{ id = "OvoUdin", nome = "Ovo Udin", raridade = "Secreto", brainrot = "Udin", chocar = 480 },
}

-- Raridades que, ao chocar, são anunciadas para o servidor inteiro.
Config.ANUNCIAR_RARIDADES = { Lendario = true, Mitico = true, Secreto = true }
Config.ANUNCIAR_MUTACOES = { ["Arco-iris"] = true }

-- Biomas, na ordem da estrada. Cada um precisa de uma Velocidade mínima para entrar.
-- "estilo" escolhe a decoração ("floresta", "praia", "deserto", "vulcao" ou
-- "espaco") e "guardiao" é quem persegue quem pega um ovo. "ovos" lista os
-- ovos dos ninhos e a chance de cada um. "musica" (opcional) é o id de uma
-- música que toca dentro do bioma (veja Config.MUSICA).
Config.BIOMAS = {
	{
		nome = "Selva Sahur",
		estilo = "floresta",
		guardiao = "Tung Tung Tung Sahur",
		corGuardiao = Color3.fromRGB(150, 100, 60),
		velocidadeMinima = 0,
		velocidadeGuardiao = 14,
		cor = Color3.fromRGB(80, 160, 70),
		ovos = { OvoPatapim = 45, OvoLarila = 30, OvoAmbalabu = 12, OvoBananini = 10, OvoCappuccina = 3 },
	},
	{
		nome = "Praia Tralalá",
		estilo = "praia",
		guardiao = "Cappuccino Assassino",
		corGuardiao = Color3.fromRGB(70, 40, 30),
		velocidadeMinima = 150,
		velocidadeGuardiao = 30,
		cor = Color3.fromRGB(70, 150, 210),
		ovos = { OvoBananini = 30, OvoTrippi = 25, OvoCappuccina = 25, OvoTralalero = 15, OvoBombardiro = 5 },
	},
	{
		nome = "Deserto Frigo",
		estilo = "deserto",
		guardiao = "Il Cacto Hipopotamo",
		corGuardiao = Color3.fromRGB(90, 160, 80),
		velocidadeMinima = 600,
		velocidadeGuardiao = 36,
		cor = Color3.fromRGB(230, 190, 110),
		ovos = { OvoTrippi = 30, OvoFrigo = 30, OvoTralalero = 18, OvoGlorbo = 14, OvoBombardiro = 6, OvoGusini = 2 },
	},
	{
		nome = "Vulcão Toasterino",
		estilo = "vulcao",
		guardiao = "Rhino Toasterino",
		corGuardiao = Color3.fromRGB(150, 150, 160),
		velocidadeMinima = 2000,
		velocidadeGuardiao = 44,
		cor = Color3.fromRGB(110, 45, 35),
		ovos = { OvoFrigo = 25, OvoGlorbo = 25, OvoCocofanto = 22, OvoBombardiro = 15, OvoGusini = 9, OvoSvinino = 4 },
	},
	{
		nome = "Espaço Saturnita",
		estilo = "espaco",
		guardiao = "La Vaca Saturno Saturnita",
		corGuardiao = Color3.fromRGB(245, 245, 245),
		velocidadeMinima = 6000,
		velocidadeGuardiao = 52,
		cor = Color3.fromRGB(70, 50, 130),
		ovos = { OvoCocofanto = 30, OvoGusini = 28, OvoSvinino = 22, OvoBombardiro = 15, OvoUdin = 5 },
	},
}

-- Sons do jogo. Os "rbxasset://" já vêm com o Roblox e funcionam em qualquer
-- lugar. Para trocar, ponha o id de um som da Creator Store ("rbxassetid://123").
Config.SONS = {
	Clique = { id = "rbxasset://sounds/button.wav", volume = 0.5 },
	Erro = { id = "rbxasset://sounds/button.wav", volume = 0.5, tom = 0.6 },
	Pegou = { id = "rbxasset://sounds/swoosh.wav", volume = 0.7, tom = 1.2 },
	Guardiao = { id = "rbxasset://sounds/unsheath.wav", volume = 0.8, tom = 0.8 },
	Derrubado = { id = "rbxasset://sounds/uuhhh.mp3", volume = 0.8 },
	Entregou = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.6, tom = 1.3 },
	Chocou = { id = "rbxasset://sounds/snap.wav", volume = 0.8 },
	Brilho = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, tom = 1.6 },
	ChocouRaro = { id = "rbxasset://sounds/victory.wav", volume = 0.7 },
	Vendeu = { id = "rbxasset://sounds/clickfast.wav", volume = 0.8, tom = 1.2 },
	Melhorou = { id = "rbxasset://sounds/victory.wav", volume = 0.6, tom = 1.15 },
	Roubando = { id = "rbxasset://sounds/swordslash.wav", volume = 0.8 },
	Trancou = { id = "rbxasset://sounds/button.wav", volume = 0.7, tom = 0.8 },
	Anuncio = { id = "rbxasset://sounds/victory.wav", volume = 0.35, tom = 0.9 },
	Renasceu = { id = "rbxasset://sounds/impact_explosion_03.mp3", volume = 0.6 },
}

-- Músicas de fundo (tocam em sequência). Ponha ids de músicas da Creator
-- Store que podem ser usadas em jogos (as publicadas pela conta "Roblox" são
-- liberadas), no formato "rbxassetid://<número>". Vazio = sem música.
Config.MUSICA = {}
Config.VOLUME_MUSICA = 0.3

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

-- Quanto o jogador vende um Brainrot (sem contar o renascimento).
function Config.precoVenda(item): number
	return Config.renda(item) * Config.VENDA_SEGUNDOS
end

-- Renascimento: preço do próximo e os multiplicadores de quem já renasceu "n" vezes.
function Config.precoRenascer(n: number): number
	return Config.RENASCER.preco * Config.RENASCER.fator ^ n
end

function Config.multiplicadorRenda(n: number): number
	return 1 + n * Config.RENASCER.bonusRenda
end

function Config.multiplicadorEsteira(n: number): number
	return 1 + n * Config.RENASCER.bonusEsteira
end

-- Posição da raridade na lista (1 = Comum). Serve para comparar raridades.
function Config.nivelRaridade(raridade: string): number
	return table.find(Config.RARIDADES, raridade) or 1
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

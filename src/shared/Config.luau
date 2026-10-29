-- Configurações do jogo. Mude os números aqui para balancear o jogo.
local Config = {}

Config.DINHEIRO_INICIAL = 50
Config.VAGAS_POR_BASE = 10
Config.TEMPO_TRANCA = 60 -- segundos que a base fica trancada
Config.TEMPO_NINHOS = 180 -- segundos para os ninhos ganharem ovos novos
Config.SALVAR_DADOS = true

-- Velocidade: o atributo principal. A velocidade de andar cresce cada vez
-- mais devagar: VELOCIDADE_BASE + VELOCIDADE_FATOR * ln(1 + Velocidade / VELOCIDADE_ESCALA),
-- até VELOCIDADE_MAXIMA. Exemplos: 0 → 16, 150 → 35, 600 → 52, 2K → 68, 6K → 83.
Config.VELOCIDADE_BASE = 16
Config.VELOCIDADE_FATOR = 14
Config.VELOCIDADE_ESCALA = 50
Config.VELOCIDADE_MAXIMA = 130
Config.TEMPO_ATORDOADO = 2 -- segundos parado depois que o guardião te pega

-- Guardiões (chefes): o tamanho deles e até onde perseguem. Eles correm
-- atrás de quem pegou um ovo até a pessoa chegar na área das bases.
Config.ESCALA_CHEFE = 1.8

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
		velocidadeGuardiao = 31,
		cor = Color3.fromRGB(70, 150, 210),
		ovos = { OvoBananini = 30, OvoTrippi = 25, OvoCappuccina = 25, OvoTralalero = 15, OvoBombardiro = 5 },
	},
	{
		nome = "Deserto Frigo",
		estilo = "deserto",
		guardiao = "Il Cacto Hipopotamo",
		corGuardiao = Color3.fromRGB(90, 160, 80),
		velocidadeMinima = 600,
		velocidadeGuardiao = 46,
		cor = Color3.fromRGB(230, 190, 110),
		ovos = { OvoTrippi = 30, OvoFrigo = 30, OvoTralalero = 18, OvoGlorbo = 14, OvoBombardiro = 6, OvoGusini = 2 },
	},
	{
		nome = "Vulcão Toasterino",
		estilo = "vulcao",
		guardiao = "Rhino Toasterino",
		corGuardiao = Color3.fromRGB(150, 150, 160),
		velocidadeMinima = 2000,
		velocidadeGuardiao = 60,
		cor = Color3.fromRGB(110, 45, 35),
		ovos = { OvoFrigo = 25, OvoGlorbo = 25, OvoCocofanto = 22, OvoBombardiro = 15, OvoGusini = 9, OvoSvinino = 4 },
	},
	{
		nome = "Espaço Saturnita",
		estilo = "espaco",
		guardiao = "La Vaca Saturno Saturnita",
		corGuardiao = Color3.fromRGB(245, 245, 245),
		velocidadeMinima = 6000,
		velocidadeGuardiao = 73,
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
	Rugido = { id = "rbxasset://sounds/swordlunge.wav", volume = 1, tom = 0.35 },
	Passo = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.9, tom = 0.45 },
	Comprou = { id = "rbxasset://sounds/victory.wav", volume = 0.6, tom = 1.25 },
}

-- Gamepasses. Crie cada um no Creator Dashboard (Monetização > Passes),
-- copie o número do passe e ponha em "id". Com id = 0 ele aparece na loja
-- como "Em breve". O preço em Robux é o que estiver no Dashboard.
Config.GAMEPASSES = {
	{ chave = "Dinheiro2x", id = 0, nome = "2x Dinheiro", icone = "💰", descricao = "Seus Brainrots rendem o dobro." },
	{ chave = "Velocidade2x", id = 0, nome = "2x Velocidade", icone = "⚡", descricao = "Ganha o dobro de Velocidade na esteira." },
	{ chave = "Turbo", id = 0, nome = "Tênis Turbo", icone = "👟", descricao = "Anda 25% mais rápido. Fuja dos chefes!" },
	{ chave = "Sorte", id = 0, nome = "Sorte", icone = "🍀", descricao = "Mais chance de mutação Prata, Dourado e Arco-íris." },
	{ chave = "TrancaLonga", id = 0, nome = "Tranca Longa", icone = "🔒", descricao = "Sua base fica trancada por 2x mais tempo." },
	{ chave = "VIP", id = 0, nome = "VIP", icone = "👑", descricao = "+50% de dinheiro e etiqueta VIP em cima da cabeça." },
	{ chave = "ChocarRapido", id = 0, nome = "Chocar Rápido", icone = "🐣", descricao = "Os ovos da sua base chocam na metade do tempo." },
}

-- Ovos especiais comprados com Robux. Cada um é um Developer Product: crie no
-- Creator Dashboard (Monetização > Developer Products), com o preço de
-- "robux", e ponha o número em "produtoId". Com produtoId = 0 o ovo aparece
-- na loja como "Em breve" e não dá para comprar.
--   chances: Brainrot (id) = peso. A loja mostra a porcentagem de cada um.
--   tamanhoMinimo / mutacaoMinima: o sorteio nunca sai abaixo disso.
--   sorte: sorteia a mutação duas vezes e fica com a melhor.
--   quantidade: quantos ovos vêm no pacote.
--   ate: oferta limitada (dia/mês/ano, fim do dia no horário UTC). Sem "ate" é permanente.
--   cores: as duas cores do ovo (cima e baixo); efeito: "brilho", "arco-iris" ou "cosmico".
Config.OVOS_ROBUX = {
	{
		chave = "Dourado", nome = "Ovo Dourado", produtoId = 0, robux = 49, raridade = "Lendario",
		cores = { Color3.fromRGB(255, 235, 120), Color3.fromRGB(235, 150, 20) }, efeito = "brilho",
		chances = { Tralalero = 35, Glorbo = 30, Cocofanto = 20, Bombardiro = 10, Gusini = 5 },
		tamanhoMinimo = "Medio", mutacaoMinima = "Prata", quantidade = 1,
	},
	{
		chave = "PacoteDourado", nome = "Pacote 3 Ovos Dourados", produtoId = 0, robux = 129, raridade = "Lendario",
		cores = { Color3.fromRGB(255, 235, 120), Color3.fromRGB(235, 150, 20) }, efeito = "brilho",
		chances = { Tralalero = 35, Glorbo = 30, Cocofanto = 20, Bombardiro = 10, Gusini = 5 },
		tamanhoMinimo = "Medio", mutacaoMinima = "Prata", quantidade = 3,
	},
	{
		chave = "Cosmico", nome = "Ovo Cósmico", produtoId = 0, robux = 149, raridade = "Mitico",
		cores = { Color3.fromRGB(150, 110, 255), Color3.fromRGB(40, 20, 110) }, efeito = "cosmico",
		chances = { Bombardiro = 30, Gusini = 30, Svinino = 25, Udin = 15 },
		tamanhoMinimo = "Grande", mutacaoMinima = "Prata", sorte = true, quantidade = 1,
	},
	{
		chave = "ArcoIris", nome = "Ovo Arco-íris", produtoId = 0, robux = 99, raridade = "Mitico",
		cores = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(90, 200, 255) }, efeito = "arco-iris",
		chances = { Cocofanto = 35, Bombardiro = 30, Gusini = 20, Svinino = 12, Udin = 3 },
		tamanhoMinimo = "Medio", mutacaoMinima = "Arco-iris", quantidade = 1,
		ate = { dia = 31, mes = 12, ano = 2026 },
	},
	{
		chave = "Supremo", nome = "Ovo Secreto Supremo", produtoId = 0, robux = 399, raridade = "Secreto",
		cores = { Color3.fromRGB(120, 255, 235), Color3.fromRGB(20, 120, 140) }, efeito = "cosmico",
		chances = { Udin = 60, Svinino = 25, Gusini = 15 },
		tamanhoMinimo = "Gigante", mutacaoMinima = "Dourado", quantidade = 1,
	},
}

-- Ranking: de quantos em quantos segundos atualiza e quantos aparecem.
Config.RANKING = {
	categorias = {
		{ chave = "Brainrots", nome = "Brainrots", icone = "🧠", descricao = "Brainrots coletados" },
		{ chave = "DinheiroTotal", nome = "Dinheiro", icone = "💰", descricao = "Dinheiro ganho no total", dinheiro = true },
		{ chave = "VelocidadeMax", nome = "Velocidade", icone = "⚡", descricao = "Maior Velocidade" },
		{ chave = "Ovos", nome = "Ovos", icone = "🥚", descricao = "Ovos chocados" },
		{ chave = "ValorBase", nome = "Base", icone = "🏠", descricao = "Valor dos Brainrots da base", dinheiro = true },
	},
	servidorSegundos = 15, -- ranking do servidor
	globalSegundos = 300, -- leitura do ranking global (OrderedDataStore)
	gravarSegundos = 300, -- gravação de cada jogador no ranking global
	quantos = 10,
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

-- Com "sorte", sorteia duas vezes e fica com a melhor.
function Config.sortearMutacao(sorte: boolean?)
	local mutacao = sortearLista(Config.MUTACOES)
	if sorte then
		local outra = sortearLista(Config.MUTACOES)
		if outra.renda > mutacao.renda then
			mutacao = outra
		end
	end
	return mutacao
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

-- Velocidade de andar (studs por segundo) para quem tem "pontos" de Velocidade.
function Config.velocidadeAndar(pontos: number): number
	local andar = Config.VELOCIDADE_BASE + Config.VELOCIDADE_FATOR * math.log(1 + math.max(pontos, 0) / Config.VELOCIDADE_ESCALA)
	return math.min(andar, Config.VELOCIDADE_MAXIMA)
end

function Config.gamepass(chave: string)
	for _, passe in Config.GAMEPASSES do
		if passe.chave == chave then
			return passe
		end
	end
	return nil
end

function Config.ovoRobux(chave: string)
	for _, ovo in Config.OVOS_ROBUX do
		if ovo.chave == chave then
			return ovo
		end
	end
	return nil
end

-- Fim da oferta limitada (os.time, UTC) ou nil se for permanente.
function Config.fimOferta(ovo): number?
	if not ovo.ate then
		return nil
	end
	return os.time({ year = ovo.ate.ano, month = ovo.ate.mes, day = ovo.ate.dia, hour = 23, min = 59, sec = 59 })
end

-- Chance (de 0 a 100) de cada Brainrot de um ovo de Robux, do mais provável ao menos.
function Config.chancesOvoRobux(ovo): { { id: string, chance: number } }
	local total = 0
	for _, peso in ovo.chances do
		total += peso
	end
	local lista = {}
	for id, peso in ovo.chances do
		table.insert(lista, { id = id, chance = peso / total * 100 })
	end
	table.sort(lista, function(a, b)
		if a.chance ~= b.chance then
			return a.chance > b.chance
		end
		return a.id < b.id
	end)
	return lista
end

-- Só os itens de "lista" a partir de "minimo" (pelo nome).
local function aPartirDe(lista, minimo: string?)
	local inicio = 1
	for i, item in lista do
		if item.nome == minimo then
			inicio = i
		end
	end
	return table.move(lista, inicio, #lista, 1, {})
end

-- Sorteia o Brainrot que sai de um ovo de Robux (só o servidor chama).
function Config.sortearOvoRobux(ovo)
	local lista = {}
	for _, item in Config.chancesOvoRobux(ovo) do
		table.insert(lista, { id = item.id, chance = item.chance })
	end
	local mutacoes = aPartirDe(Config.MUTACOES, ovo.mutacaoMinima)
	local mutacao = sortearLista(mutacoes)
	if ovo.sorte then
		local outra = sortearLista(mutacoes)
		if outra.renda > mutacao.renda then
			mutacao = outra
		end
	end
	return {
		tipo = "brainrot",
		id = sortearLista(lista).id,
		tamanho = sortearLista(aPartirDe(Config.TAMANHOS, ovo.tamanhoMinimo)).nome,
		mutacao = mutacao.nome,
	}
end

function Config.categoriaRanking(chave: string)
	for _, categoria in Config.RANKING.categorias do
		if categoria.chave == chave then
			return categoria
		end
	end
	return nil
end

-- string.upper do Roblox não mexe nas letras com acento ("vulcão" vira
-- "VULCãO"). Esta deixa tudo maiúsculo, com acento.
local MAIUSCULAS = {
	["á"] = "Á", ["à"] = "À", ["â"] = "Â", ["ã"] = "Ã", ["ä"] = "Ä",
	["é"] = "É", ["ê"] = "Ê", ["è"] = "È", ["í"] = "Í", ["ì"] = "Ì",
	["ó"] = "Ó", ["ô"] = "Ô", ["õ"] = "Õ", ["ò"] = "Ò", ["ú"] = "Ú",
	["ù"] = "Ù", ["ü"] = "Ü", ["ç"] = "Ç", ["ñ"] = "Ñ",
}
function Config.maiusculas(texto: string): string
	local resultado = string.upper(texto)
	for minuscula, maiuscula in MAIUSCULAS do
		resultado = string.gsub(resultado, minuscula, maiuscula)
	end
	return resultado
end

-- Tira os acentos ("Vulcão" → "Vulcao"), para fontes que não têm essas letras.
local SEM_ACENTO = {
	["á"] = "a", ["à"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a",
	["é"] = "e", ["ê"] = "e", ["è"] = "e", ["í"] = "i", ["ì"] = "i",
	["ó"] = "o", ["ô"] = "o", ["õ"] = "o", ["ò"] = "o", ["ú"] = "u",
	["ù"] = "u", ["ü"] = "u", ["ç"] = "c", ["ñ"] = "n",
}
function Config.semAcento(texto: string): string
	local resultado = texto
	for comAcento, letra in SEM_ACENTO do
		resultado = string.gsub(resultado, comAcento, letra)
		resultado = string.gsub(resultado, Config.maiusculas(comAcento), string.upper(letra))
	end
	return resultado
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

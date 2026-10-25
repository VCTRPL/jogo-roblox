-- Configurações do jogo. Mude os números aqui para balancear o jogo.
local Config = {}

Config.DINHEIRO_INICIAL = 100
Config.INTERVALO_ESTEIRA = 2.5 -- segundos entre cada Verity que aparece na esteira
Config.TEMPO_ESTEIRA = 30 -- segundos que um Verity leva para atravessar a esteira
Config.VAGAS_POR_BASE = 10
Config.TEMPO_TRANCA = 60 -- segundos que a base fica trancada
Config.VELOCIDADE_NORMAL = 16
Config.VELOCIDADE_CARREGANDO = 10 -- quem está carregando um Verity anda mais devagar
Config.SALVAR_DADOS = true

Config.CORES_RARIDADE = {
	Comum = Color3.fromRGB(190, 190, 190),
	Raro = Color3.fromRGB(70, 140, 255),
	Epico = Color3.fromRGB(170, 80, 255),
	Lendario = Color3.fromRGB(255, 190, 40),
	Mitico = Color3.fromRGB(255, 60, 80),
}

-- Cada Verity: preço para comprar, renda por segundo e chance de aparecer na esteira.
-- O "id" é o nome do modelo em ReplicatedStorage.ModelosVerity (opcional, veja o README).
Config.VERITIES = {
	{ id = "VerityComum", nome = "Verity", raridade = "Comum", preco = 25, renda = 1, chance = 50 },
	{ id = "VerityFeliz", nome = "Verity Feliz", raridade = "Comum", preco = 75, renda = 3, chance = 25 },
	{ id = "VerityDourado", nome = "Verity Dourado", raridade = "Raro", preco = 300, renda = 10, chance = 12 },
	{ id = "VerityNinja", nome = "Verity Ninja", raridade = "Epico", preco = 1500, renda = 40, chance = 7 },
	{ id = "VerityGigante", nome = "Verity Gigante", raridade = "Lendario", preco = 8000, renda = 150, chance = 4 },
	{ id = "VerityCosmico", nome = "Verity Cósmico", raridade = "Mitico", preco = 50000, renda = 800, chance = 2 },
}

local porId = {}
local chanceTotal = 0
for _, verity in Config.VERITIES do
	porId[verity.id] = verity
	chanceTotal += verity.chance
end

local aleatorio = Random.new()

function Config.buscar(id: string)
	return porId[id]
end

-- Escolhe um Verity aleatório respeitando as chances.
function Config.sortear()
	local sorteio = aleatorio:NextNumber(0, chanceTotal)
	for _, verity in Config.VERITIES do
		sorteio -= verity.chance
		if sorteio <= 0 then
			return verity
		end
	end
	return Config.VERITIES[1]
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

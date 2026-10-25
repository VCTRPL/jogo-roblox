-- Dinheiro do jogador (leaderstats) e salvamento com DataStore.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Dados = {}

local store = nil
if Config.SALVAR_DADOS then
	local ok, resultado = pcall(function()
		return DataStoreService:GetDataStore("RoubeUmVerity_v1")
	end)
	if ok then
		store = resultado
	else
		warn("DataStore indisponível, o progresso não será salvo:", resultado)
	end
end

-- Se o carregamento falhar, não salvamos por cima para não apagar o progresso.
local podeSalvar: { [Player]: boolean } = {}

local function chave(player: Player): string
	return `jogador_{player.UserId}`
end

local function valorDinheiro(player: Player): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Dinheiro") :: IntValue?
end

-- Cria o placar e devolve os Verities salvos (lista de ids).
function Dados.carregar(player: Player): { string }
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

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local dinheiro = Instance.new("IntValue")
	dinheiro.Name = "Dinheiro"
	dinheiro.Value = if salvo then salvo.dinheiro else Config.DINHEIRO_INICIAL
	dinheiro.Parent = stats
	stats.Parent = player

	return if salvo then salvo.verities or {} else {}
end

function Dados.salvar(player: Player, verities: { string })
	local dinheiro = valorDinheiro(player)
	if not store or not dinheiro or not podeSalvar[player] then
		return
	end
	local ok, erro = pcall(function()
		store:SetAsync(chave(player), { dinheiro = dinheiro.Value, verities = verities })
	end)
	if not ok then
		warn(`Não consegui salvar os dados de {player.Name}:`, erro)
	end
end

function Dados.esquecer(player: Player)
	podeSalvar[player] = nil
end

function Dados.dinheiro(player: Player): number
	local valor = valorDinheiro(player)
	return if valor then valor.Value else 0
end

function Dados.adicionar(player: Player, quantia: number)
	local valor = valorDinheiro(player)
	if valor then
		valor.Value += quantia
	end
end

return Dados

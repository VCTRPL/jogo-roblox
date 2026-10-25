-- Placar (Dinheiro e Velocidade) e salvamento com DataStore.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Dados = {}

local store = nil
if Config.SALVAR_DADOS then
	local ok, resultado = pcall(function()
		return DataStoreService:GetDataStore("RoubeUmVerity_v2")
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

local function stat(player: Player, nome: string): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(nome) :: IntValue?
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
	salvo = salvo or {}

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local dinheiro = Instance.new("IntValue")
	dinheiro.Name = "Dinheiro"
	dinheiro.Value = salvo.dinheiro or Config.DINHEIRO_INICIAL
	dinheiro.Parent = stats
	local velocidade = Instance.new("IntValue")
	velocidade.Name = "Velocidade"
	velocidade.Value = salvo.velocidade or 0
	velocidade.Parent = stats
	stats.Parent = player

	player:SetAttribute("NivelEsteira", salvo.nivelEsteira or 1)

	return salvo.itens or {}
end

function Dados.salvar(player: Player, itens: { any })
	local dinheiro = stat(player, "Dinheiro")
	local velocidade = stat(player, "Velocidade")
	if not store or not dinheiro or not velocidade or not podeSalvar[player] then
		return
	end
	local ok, erro = pcall(function()
		store:SetAsync(chave(player), {
			dinheiro = dinheiro.Value,
			velocidade = velocidade.Value,
			nivelEsteira = player:GetAttribute("NivelEsteira"),
			itens = itens,
		})
	end)
	if not ok then
		warn(`Não consegui salvar os dados de {player.Name}:`, erro)
	end
end

function Dados.esquecer(player: Player)
	podeSalvar[player] = nil
end

-- nome: "Dinheiro" ou "Velocidade"
function Dados.valor(player: Player, nome: string): number
	local valor = stat(player, nome)
	return if valor then valor.Value else 0
end

function Dados.adicionar(player: Player, nome: string, quantia: number)
	local valor = stat(player, nome)
	if valor then
		valor.Value += quantia
	end
end

return Dados

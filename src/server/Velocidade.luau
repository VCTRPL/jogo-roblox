-- Calcula a velocidade de andar de cada jogador a partir do atributo Velocidade,
-- do peso do que ele está carregando e se está atordoado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Dados = require(script.Parent.Dados)

local Velocidade = {}

local peso: { [Player]: number } = {}
local atordoadoAte: { [Player]: number } = {}

function Velocidade.andar(player: Player): number
	local andar = Config.velocidadeAndar(Dados.valor(player, "Velocidade"))
	if player:GetAttribute("Pass_Turbo") then
		andar *= 1.25
	end
	return andar * (peso[player] or 1)
end

function Velocidade.atualizar(player: Player)
	local personagem = player.Character
	local hum = personagem and personagem:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local atordoado = os.clock() < (atordoadoAte[player] or 0)
	hum.WalkSpeed = if atordoado then 0 else Velocidade.andar(player)
end

function Velocidade.adicionar(player: Player, pontos: number)
	Dados.adicionar(player, "Velocidade", pontos)
	Velocidade.atualizar(player)
end

-- 1 = normal, 0.6 = 40% mais lento
function Velocidade.definirPeso(player: Player, fator: number)
	peso[player] = fator
	Velocidade.atualizar(player)
end

function Velocidade.atordoar(player: Player, segundos: number)
	atordoadoAte[player] = os.clock() + segundos
	Velocidade.atualizar(player)
	task.delay(segundos, Velocidade.atualizar, player)
end

function Velocidade.iniciar()
	local function aoEntrar(player: Player)
		player.CharacterAdded:Connect(function(personagem)
			personagem:WaitForChild("Humanoid")
			Velocidade.atualizar(player)
		end)
		-- comprou o Tênis Turbo
		player:GetAttributeChangedSignal("Pass_Turbo"):Connect(function()
			Velocidade.atualizar(player)
		end)
	end
	Players.PlayerAdded:Connect(aoEntrar)
	for _, player in Players:GetPlayers() do
		aoEntrar(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		peso[player] = nil
		atordoadoAte[player] = nil
	end)
end

return Velocidade

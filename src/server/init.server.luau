-- Script principal do servidor: liga todos os sistemas do jogo.
local Players = game:GetService("Players")

local Avisos = require(script.Avisos)
local Bases = require(script.Bases)
local Dados = require(script.Dados)
local Esteira = require(script.Esteira)
local Roubo = require(script.Roubo)

Bases.iniciar()
Esteira.iniciar()
Roubo.iniciar()

local function salvar(player: Player)
	local base = Bases.doJogador(player)
	if base then
		Dados.salvar(player, Bases.ids(base))
	end
end

local function aoEntrar(player: Player)
	local salvos = Dados.carregar(player)
	if player.Parent == nil then
		return -- saiu enquanto carregava
	end
	local base = Bases.atribuir(player)
	if not base then
		player:Kick("O servidor está cheio, tente outro.")
		return
	end
	for _, id in salvos do
		Bases.colocar(base, id)
	end

	local function nascerNaBase(personagem: Model)
		personagem:WaitForChild("HumanoidRootPart")
		task.wait()
		personagem:PivotTo(base.spawn)
	end
	player.CharacterAdded:Connect(nascerNaBase)
	if player.Character then
		task.spawn(nascerNaBase, player.Character)
	end

	Avisos.enviar(player, "Compre Verities na esteira e roube os dos outros!")
end

Players.PlayerAdded:Connect(aoEntrar)
for _, player in Players:GetPlayers() do
	task.spawn(aoEntrar, player)
end

Players.PlayerRemoving:Connect(function(player)
	Roubo.jogadorSaiu(player)
	salvar(player)
	Dados.esquecer(player)
	Bases.liberar(player)
end)

-- Salva todo mundo a cada 2 minutos e quando o servidor fecha.
task.spawn(function()
	while true do
		task.wait(120)
		for _, player in Players:GetPlayers() do
			task.spawn(salvar, player)
		end
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		salvar(player)
	end
end)

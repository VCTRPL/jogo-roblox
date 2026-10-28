-- Script principal do servidor: liga todos os sistemas do jogo.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Avisos = require(script.Avisos)
local Bases = require(script.Bases)
local Carregar = require(script.Carregar)
local Dados = require(script.Dados)
local Decoracao = require(script.Decoracao)
local Mapa = require(script.Mapa)
local Ninhos = require(script.Ninhos)
local Passes = require(script.Passes)
local Renascer = require(script.Renascer)
local Velocidade = require(script.Velocidade)

-- Todo mundo nasce na própria base: tira o SpawnLocation que vem no lugar
-- (ficava no meio da estrada) e deixa um escondido na saída do túnel, só
-- para quem ainda não ganhou base.
for _, objeto in Workspace:GetDescendants() do
	if objeto:IsA("SpawnLocation") then
		objeto:Destroy()
	end
end
local nascer = Instance.new("SpawnLocation")
nascer.Name = "SpawnEscondido"
nascer.Anchored = true
nascer.Transparency = 1
nascer.CanCollide = false
nascer.Size = Vector3.new(6, 1, 6)
nascer.Position = Vector3.new(Mapa.TUNEL_BOCA + 8, 1, 0)
nascer.Neutral = true
nascer.Parent = Workspace
for _, decal in nascer:GetChildren() do
	decal:Destroy()
end

local infoBases, infoBiomas = Mapa.construir()
Decoracao.construir(infoBases, infoBiomas)
Passes.iniciar()
Velocidade.iniciar()
Bases.iniciar(infoBases)
Carregar.iniciar()
Ninhos.iniciar(infoBiomas)
Renascer.iniciar()

local function salvar(player: Player)
	local base = Bases.doJogador(player)
	if base then
		Dados.salvar(player, Bases.itens(base))
	end
end

local function aoEntrar(player: Player)
	local itens = Dados.carregar(player)
	if player.Parent == nil then
		return -- saiu enquanto carregava
	end
	local base = Bases.atribuir(player)
	if not base then
		player:Kick("O servidor está cheio, tente outro.")
		return
	end
	for _, item in itens do
		Bases.colocar(base, item)
	end
	Velocidade.atualizar(player)

	local function nascerNaBase(personagem: Model)
		personagem:WaitForChild("HumanoidRootPart")
		task.wait()
		personagem:PivotTo(base.spawn)
	end
	player.CharacterAdded:Connect(nascerNaBase)
	if player.Character then
		task.spawn(nascerNaBase, player.Character)
	end

	Avisos.enviar(player, "Pegue ovos brainrot nos ninhos e leve para a sua base! Cuidado com o Tung Tung Tung Sahur!")
end

Players.PlayerAdded:Connect(aoEntrar)
for _, player in Players:GetPlayers() do
	task.spawn(aoEntrar, player)
end

Players.PlayerRemoving:Connect(function(player)
	Carregar.perder(player)
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

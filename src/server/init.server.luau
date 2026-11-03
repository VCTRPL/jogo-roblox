-- Script principal do servidor: liga todos os sistemas do jogo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Admin = require(script.Admin)
local Avisos = require(script.Avisos)
local Bases = require(script.Bases)
local Carregar = require(script.Carregar)
local Compras = require(script.Compras)
local Dados = require(script.Dados)
local Decoracao = require(script.Decoracao)
local Guardioes = require(script.Guardioes)
local Mapa = require(script.Mapa)
local Mochila = require(script.Mochila)
local Modelos = require(script.Modelos)
local Ninhos = require(script.Ninhos)
local Passes = require(script.Passes)
local Pilha = require(script.Pilha)
local Ranking = require(script.Ranking)
local Renascer = require(script.Renascer)
local Taco = require(script.Taco)
local Trilhas = require(script.Trilhas)
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
Guardioes.monumentos(infoBiomas) -- estátuas dos chefes na frente de cada bioma
Modelos.publicarIndice()
Passes.iniciar()
Velocidade.iniciar()
Bases.iniciar(infoBases)
Carregar.iniciar()
Taco.iniciar() -- antes da mochila, para o taco ser o primeiro da barra
Mochila.iniciar()
Trilhas.iniciar()
Ninhos.iniciar(infoBiomas)
Renascer.iniciar()
Ranking.iniciar()
Compras.iniciar()

-- Quantos salvamentos estão gravando agora. Quando o servidor fecha (o
-- último jogador saiu, ou o Stop do Studio), o BindToClose espera esses
-- terminarem; senão o servidor desligava no meio do SetAsync do
-- PlayerRemoving e a compra feita depois do último autosave se perdia.
local salvandoAgora = 0

local function salvar(player: Player): boolean
	local base = Bases.doJogador(player)
	if not base then
		return false
	end
	salvandoAgora += 1
	local ok, resultado = pcall(Dados.salvar, player, Bases.itens(base), Bases.renda(base))
	salvandoAgora -= 1
	if not ok then
		warn(`Erro ao salvar {player.Name}:`, resultado)
		return false
	end
	return resultado
end

Admin.iniciar({
	dar = function(alvo: Player, quantia: number)
		Dados.adicionar(alvo, "Dinheiro", quantia)
	end,
	salvar = salvar,
	status = function(player: Player): string
		local estado = if not Dados.temStore()
			then "DESLIGADO (sem DataStore)"
			elseif not Dados.carregado(player) then "DESLIGADO (falhou ao carregar)"
			else "ligado"
		return `Salvamento {estado} · ${Config.formatar(Dados.valor(player, "Dinheiro"))} · trilha {player:GetAttribute("NivelTrilha") or 0}`
	end,
})

-- Salva daqui a pouco (compras importantes, como trilhas e esteira). Junta
-- várias mudanças seguidas num salvamento só, para não estourar o limite
-- do DataStore.
local agendado: { [Player]: boolean } = {}
local function salvarLogo(player: Player)
	if agendado[player] then
		return
	end
	agendado[player] = true
	task.delay(6, function()
		agendado[player] = nil
		if player.Parent ~= nil then
			salvar(player)
		end
	end)
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
		-- não coube (vagas a menos que no save): espera no inventário
		if not Bases.colocar(base, item) then
			Dados.adicionarPendente(player, item)
		end
	end
	-- daqui para a frente, Brainrot novo avisa "Novo no Índice"
	player:SetAttribute("BaseCarregada", true)
	-- comprou ou trocou trilha, ou melhorou a esteira: salva logo
	for _, atributo in { "NivelTrilha", "TrilhaEquipada", "NivelEsteira" } do
		player:GetAttributeChangedSignal(atributo):Connect(function()
			salvarLogo(player)
		end)
	end
	if not Dados.temStore() then
		-- DataStore desligado: nada é salvo (no Studio, falta ligar o acesso às APIs)
		Avisos.enviar(
			player,
			"O progresso NÃO está sendo salvo! No Studio: Game Settings > Security > Enable Studio Access to API Services (o jogo precisa estar publicado).",
			Color3.fromRGB(255, 90, 90)
		)
	elseif not Dados.carregado(player) then
		Avisos.enviar(
			player,
			"Não consegui carregar seu progresso salvo. Nada será salvo nesta partida; entre de novo.",
			Color3.fromRGB(255, 90, 90)
		)
	end
	-- ovos que estavam na mochila
	Mochila.entrar(player)
	-- ovos comprados com Robux que estavam esperando vaga
	Compras.entrar(player)
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

	-- farm AFK: a pilha de dinheiro que a base rendeu enquanto ele estava fora
	Pilha.entrar(player, base)
end

Players.PlayerAdded:Connect(aoEntrar)
for _, player in Players:GetPlayers() do
	task.spawn(aoEntrar, player)
end

Players.PlayerRemoving:Connect(function(player)
	Carregar.perder(player)
	salvar(player)
	Pilha.sair(player)
	Ranking.sair(player)
	Compras.sair(player)
	Dados.esquecer(player)
	Bases.liberar(player)
	agendado[player] = nil
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
	local tarefas = 0
	for _, player in Players:GetPlayers() do
		tarefas += 1
		task.spawn(function()
			salvar(player)
			Ranking.gravar(player)
			tarefas -= 1
		end)
	end
	-- espera os salvamentos (estes e os do PlayerRemoving) terminarem;
	-- o Roblox dá no máximo 30 segundos
	local inicio = os.clock()
	while (tarefas > 0 or salvandoAgora > 0) and os.clock() - inicio < 25 do
		task.wait(0.1)
	end
end)

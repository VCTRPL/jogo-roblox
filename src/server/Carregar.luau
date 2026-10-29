-- Carregar: o jogador leva um ovo ou Brainrot em cima da cabeça até a própria base.
-- Serve tanto para ovos pegos nos ninhos quanto para roubos de outras bases.
-- Se for pego pelo guardião, morrer ou sair do jogo, perde o que carregava.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Bases = require(script.Parent.Bases)
local Dados = require(script.Parent.Dados)
local Modelos = require(script.Parent.Modelos)
local Velocidade = require(script.Parent.Velocidade)

local Carregar = {}

type Carga = {
	item: Modelos.Item,
	modelo: Model,
	aoPerder: () -> (), -- devolve o item para onde ele estava
	roubo: boolean, -- veio da base de outro jogador
}

local carregando: { [Player]: Carga } = {}

local VERMELHO = Color3.fromRGB(255, 90, 90)
local VERDE = Color3.fromRGB(90, 255, 120)

local function raizDe(player: Player): BasePart?
	local personagem = player.Character
	return personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nomeDo(item: Modelos.Item): string
	local def = if item.tipo == "ovo" then Config.ovo(item.id) else Config.brainrot(item.id)
	return def.nome
end

function Carregar.estaCarregando(player: Player): boolean
	return carregando[player] ~= nil
end

-- Põe o item em cima da cabeça do jogador. aoPerder é chamado se ele não conseguir entregar.
function Carregar.pegar(player: Player, item: Modelos.Item, aoPerder: () -> ()): boolean
	if carregando[player] then
		Avisos.enviar(player, "Você já está carregando algo!", VERMELHO)
		return false
	end
	local personagem = player.Character
	local hum = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = raizDe(player)
	if not personagem or not hum or hum.Health <= 0 or not raiz then
		return false
	end

	local modelo = Modelos.criar(item)
	Modelos.prompt(modelo):Destroy()
	modelo.Parent = personagem
	Modelos.grudar(modelo, raiz)

	carregando[player] = { item = item, modelo = modelo, aoPerder = aoPerder, roubo = false }
	Velocidade.definirPeso(player, Config.tamanho(item.tamanho).peso)
	-- o cliente mostra a faixa "Carregando" e a seta até a base
	local def = if item.tipo == "ovo" then Config.ovo(item.id) else Config.brainrot(item.id)
	player:SetAttribute("Carregando", nomeDo(item))
	player:SetAttribute("CorCarregando", Config.CORES_RARIDADE[def.raridade])
	Avisos.som(nil, "Pegou", raiz.Position)
	Avisos.efeito("Pegou", { posicao = raiz.Position, raridade = def.raridade })
	return true
end

local function soltar(player: Player): Carga?
	local carga = carregando[player]
	if not carga then
		return nil
	end
	carregando[player] = nil
	carga.modelo:Destroy()
	Velocidade.definirPeso(player, 1)
	player:SetAttribute("Carregando", nil)
	player:SetAttribute("CorCarregando", nil)
	return carga
end

-- Perde o que estava carregando (o item volta para onde estava).
function Carregar.perder(player: Player)
	local carga = soltar(player)
	if carga then
		carga.aoPerder()
	end
end

-- O guardião (ou outro perigo) derrubou o jogador.
function Carregar.derrubar(player: Player, motivo: string)
	if not carregando[player] then
		return
	end
	Carregar.perder(player)
	Velocidade.atordoar(player, Config.TEMPO_ATORDOADO)
	Avisos.enviar(player, motivo, VERMELHO)
	local raiz = raizDe(player)
	if raiz then
		Avisos.som(nil, "Derrubado", raiz.Position)
		Avisos.efeito("Derrubado", { posicao = raiz.Position })
	end
end

local function tentarRoubar(ladrao: Player, base: Bases.Base, vaga: number)
	local dono = base.dono
	if not dono or dono == ladrao then
		return
	end
	if Bases.estaTrancada(base) then
		Avisos.enviar(ladrao, "Essa base está trancada!", VERMELHO)
		return
	end
	if carregando[ladrao] or not Bases.doJogador(ladrao) or not raizDe(ladrao) then
		return
	end

	local item = Bases.remover(base, vaga)
	if not item then
		return
	end
	local function devolver()
		-- Só devolve se o dono ainda estiver no jogo com a mesma base.
		if base.dono == dono and Bases.colocar(base, item, vaga) then
			Avisos.enviar(dono, "Recuperou o que tinham roubado!", VERDE)
		end
	end
	if not Carregar.pegar(ladrao, item, devolver) then
		devolver()
		return
	end
	carregando[ladrao].roubo = true
	Avisos.enviar(ladrao, `Você pegou {nomeDo(item)}! Leve para a sua base!`, VERDE)
	Avisos.enviar(dono, `{ladrao.DisplayName} está roubando seu {nomeDo(item)}!`, VERMELHO)
	Avisos.som(dono, "Roubando")
end

local function verificarEntregas()
	for player, carga in carregando do
		local minhaBase = Bases.doJogador(player)
		local raiz = raizDe(player)
		if minhaBase and raiz and Bases.dentro(minhaBase, raiz.Position) then
			if Bases.vagaLivre(minhaBase) then
				soltar(player)
				Bases.colocar(minhaBase, carga.item)
				Avisos.enviar(player, `{nomeDo(carga.item)} guardado na sua base!`, VERDE)
				Avisos.som(player, "Entregou")
				if carga.roubo then
					Dados.adicionar(player, "Roubos", 1)
				end
			else
				-- Base cheia: vai para o inventário (e entra na base quando
				-- abrir vaga), para ele poder pegar outro ovo.
				soltar(player)
				Dados.adicionarPendente(player, carga.item)
				Avisos.enviar(player, `Base cheia! {nomeDo(carga.item)} foi para o seu inventário.`, Color3.fromRGB(255, 215, 80))
				Avisos.som(player, "Entregou")
				if carga.roubo then
					Dados.adicionar(player, "Roubos", 1)
				end
			end
		end
	end
end

function Carregar.iniciar()
	Bases.aoTentarRoubar = tentarRoubar

	local function aoEntrar(player: Player)
		player.CharacterAdded:Connect(function(personagem)
			local hum = personagem:WaitForChild("Humanoid") :: Humanoid
			hum.Died:Connect(function()
				Carregar.perder(player)
			end)
		end)
		player.CharacterRemoving:Connect(function()
			Carregar.perder(player)
		end)
	end
	Players.PlayerAdded:Connect(aoEntrar)
	for _, player in Players:GetPlayers() do
		aoEntrar(player)
	end

	task.spawn(function()
		while true do
			task.wait(0.2)
			verificarEntregas()
		end
	end)
end

return Carregar

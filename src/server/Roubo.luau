-- Roubo: pegar um Verity da base de outro jogador e levar para a sua.
-- Se o ladrão morrer ou sair do jogo no caminho, o Verity volta para o dono.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Bases = require(script.Parent.Bases)
local Verities = require(script.Parent.Verities)

local Roubo = {}

type Carga = {
	id: string,
	modelo: Model,
	origem: Bases.Base,
	dono: Player,
	avisouCheia: boolean,
}

local carregando: { [Player]: Carga } = {}

local VERMELHO = Color3.fromRGB(255, 90, 90)
local VERDE = Color3.fromRGB(90, 255, 120)

local function humanoide(player: Player): Humanoid?
	local personagem = player.Character
	return personagem and personagem:FindFirstChildOfClass("Humanoid")
end

local function soltar(ladrao: Player): Carga?
	local carga = carregando[ladrao]
	if not carga then
		return nil
	end
	carregando[ladrao] = nil
	carga.modelo:Destroy()
	local hum = humanoide(ladrao)
	if hum then
		hum.WalkSpeed = Config.VELOCIDADE_NORMAL
	end
	return carga
end

local function devolver(ladrao: Player)
	local carga = soltar(ladrao)
	if not carga then
		return
	end
	-- Só devolve se o dono ainda estiver no jogo com a mesma base.
	if carga.origem.dono == carga.dono and Bases.colocar(carga.origem, carga.id) then
		Avisos.enviar(carga.dono, "Seu Verity voltou para a base!", VERDE)
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
	if carregando[ladrao] then
		Avisos.enviar(ladrao, "Você já está carregando um Verity!", VERMELHO)
		return
	end
	if not Bases.doJogador(ladrao) then
		return
	end
	local hum = humanoide(ladrao)
	local raiz = ladrao.Character and ladrao.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or hum.Health <= 0 or not raiz then
		return
	end

	local id = Bases.remover(base, vaga)
	if not id then
		return
	end
	local def = Config.buscar(id)
	local modelo = Verities.criar(def)
	Verities.prompt(modelo):Destroy()
	modelo.Parent = ladrao.Character
	Verities.grudar(modelo, raiz)
	hum.WalkSpeed = Config.VELOCIDADE_CARREGANDO

	carregando[ladrao] = { id = id, modelo = modelo, origem = base, dono = dono, avisouCheia = false }
	Avisos.enviar(ladrao, `Você pegou {def.nome}! Leve para a sua base!`, VERDE)
	Avisos.enviar(dono, `{ladrao.DisplayName} está roubando seu {def.nome}!`, VERMELHO)
end

local function verificarEntregas()
	for ladrao, carga in carregando do
		local minhaBase = Bases.doJogador(ladrao)
		local raiz = ladrao.Character and ladrao.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if minhaBase and raiz and Bases.dentro(minhaBase, raiz.Position) then
			if Bases.vagaLivre(minhaBase) then
				soltar(ladrao)
				Bases.colocar(minhaBase, carga.id)
				Avisos.enviar(ladrao, "Roubo concluído!", VERDE)
				Avisos.enviar(carga.dono, `{ladrao.DisplayName} roubou seu Verity!`, VERMELHO)
			elseif not carga.avisouCheia then
				carga.avisouCheia = true
				Avisos.enviar(ladrao, "Sua base está cheia!", VERMELHO)
			end
		end
	end
end

function Roubo.iniciar()
	Bases.aoTentarRoubar = tentarRoubar

	local function aoEntrar(player: Player)
		player.CharacterAdded:Connect(function(personagem)
			local hum = personagem:WaitForChild("Humanoid") :: Humanoid
			hum.Died:Connect(function()
				devolver(player)
			end)
		end)
		player.CharacterRemoving:Connect(function()
			devolver(player)
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

-- Precisa ser chamado antes de liberar a base de quem saiu.
function Roubo.jogadorSaiu(player: Player)
	devolver(player)
end

return Roubo

-- Esteira: Verities aparecem de um lado, atravessam o mapa e podem ser comprados.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Bases = require(script.Parent.Bases)
local Dados = require(script.Parent.Dados)
local Mapa = require(script.Parent.Mapa)
local Verities = require(script.Parent.Verities)

local Esteira = {}

type Andando = { modelo: Model, def: any, inicio: number, vendido: boolean }

local andando: { Andando } = {}
local pasta: Folder

local function tirar(item: Andando)
	local indice = table.find(andando, item)
	if indice then
		table.remove(andando, indice)
	end
	item.modelo:Destroy()
end

local function comprar(player: Player, item: Andando)
	if item.vendido then
		return
	end
	local base = Bases.doJogador(player)
	if not base then
		return
	end
	if Dados.dinheiro(player) < item.def.preco then
		Avisos.enviar(player, "Dinheiro insuficiente!", Color3.fromRGB(255, 90, 90))
		return
	end
	if not Bases.vagaLivre(base) then
		Avisos.enviar(player, "Sua base está cheia!", Color3.fromRGB(255, 90, 90))
		return
	end

	item.vendido = true
	Dados.adicionar(player, -item.def.preco)
	tirar(item)
	Bases.colocar(base, item.def.id)
	Avisos.enviar(player, `Você comprou {item.def.nome}!`, Config.CORES_RARIDADE[item.def.raridade])
end

local function criarNaEsteira()
	local def = Config.sortear()
	local modelo = Verities.criar(def)
	local item: Andando = { modelo = modelo, def = def, inicio = os.clock(), vendido = false }

	local prompt = Verities.prompt(modelo)
	prompt.ActionText = `Comprar ${Config.formatar(def.preco)}`
	prompt.Triggered:Connect(function(player)
		comprar(player, item)
	end)

	modelo:PivotTo(CFrame.lookAt(Mapa.ESTEIRA_INICIO, Mapa.ESTEIRA_FIM))
	modelo.Parent = pasta
	table.insert(andando, item)
end

function Esteira.iniciar()
	pasta = Instance.new("Folder")
	pasta.Name = "Esteira"
	pasta.Parent = Workspace

	local direcao = CFrame.lookAt(Vector3.zero, Mapa.ESTEIRA_FIM - Mapa.ESTEIRA_INICIO).Rotation

	RunService.Heartbeat:Connect(function()
		local agora = os.clock()
		for i = #andando, 1, -1 do
			local item = andando[i]
			local progresso = (agora - item.inicio) / Config.TEMPO_ESTEIRA
			if progresso >= 1 then
				tirar(item)
			else
				local posicao = Mapa.ESTEIRA_INICIO:Lerp(Mapa.ESTEIRA_FIM, progresso)
				item.modelo:PivotTo(CFrame.new(posicao) * direcao)
			end
		end
	end)

	task.spawn(function()
		while true do
			criarNaEsteira()
			task.wait(Config.INTERVALO_ESTEIRA)
		end
	end)
end

return Esteira

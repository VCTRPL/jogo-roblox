-- Biomas: ninhos com ovos, o guardião que persegue quem pega um ovo
-- e o bloqueio para quem não tem Velocidade suficiente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Carregar = require(script.Parent.Carregar)
local Dados = require(script.Parent.Dados)
local Mapa = require(script.Parent.Mapa)
local Modelos = require(script.Parent.Modelos)

local Ninhos = {}

local NINHOS_POR_BIOMA = 8
local RAIO_NINHOS = 32
local DISTANCIA_PEGAR = 5 -- o guardião derruba quem chegar a essa distância
local TEMPO_ACORDAR = 1 -- segundos até o guardião começar a correr

type Ninho = {
	cframe: CFrame,
	item: Modelos.Item?,
	modelo: Model?,
}

type Guardiao = {
	modelo: Model,
	casa: CFrame,
	posicao: Vector3,
	alvo: Player?,
	correEm: number,
	velocidade: number,
}

type Bioma = {
	info: Mapa.InfoBioma,
	ninhos: { Ninho },
	guardiao: Guardiao,
	textoTempo: TextLabel,
}

local biomas: { Bioma } = {}
local ultimoAvisoPortao: { [Player]: number } = {}

local VERMELHO = Color3.fromRGB(255, 90, 90)
local VERDE = Color3.fromRGB(90, 255, 120)

local function criarGuardiao(info: Mapa.InfoBioma): Guardiao
	local modelo = Instance.new("Model")
	modelo.Name = "Guardiao"

	local corpo = Instance.new("Part")
	corpo.Name = "Corpo"
	corpo.Size = Vector3.new(7, 8, 7)
	corpo.Color = Color3.fromRGB(60, 30, 30)
	corpo.Material = Enum.Material.Slate
	corpo.Anchored = true
	corpo.CanCollide = false
	corpo.Parent = modelo

	for _, x in { -1.6, 1.6 } do
		local olho = Instance.new("Part")
		olho.Name = "Olho"
		olho.Shape = Enum.PartType.Ball
		olho.Size = Vector3.new(1.4, 1.4, 1.4)
		olho.Color = Color3.fromRGB(255, 40, 40)
		olho.Material = Enum.Material.Neon
		olho.Anchored = true
		olho.CanCollide = false
		olho.CFrame = corpo.CFrame * CFrame.new(x, 1.8, -3.5)
		olho.Parent = modelo
	end

	modelo.PrimaryPart = corpo
	-- pivot nos pés
	modelo.WorldPivot = corpo.CFrame * CFrame.new(0, -4, 0)
	Mapa.placa(corpo, `Guardião da {info.config.nome}`, 6, 220)

	local casa = CFrame.lookAt(info.centro, info.centro + Vector3.new(-1, 0, 0))
	modelo:PivotTo(casa)
	modelo.Parent = info.pasta

	return {
		modelo = modelo,
		casa = casa,
		posicao = info.centro,
		alvo = nil,
		correEm = 0,
		velocidade = info.config.velocidadeGuardiao,
	}
end

local function encherNinho(bioma: Bioma, ninho: Ninho, item: Modelos.Item?)
	if ninho.modelo then
		return
	end
	if not item then
		local ovo = Config.sortearOvo(bioma.info.config)
		item = { tipo = "ovo", id = ovo.id, tamanho = Config.sortearTamanho().nome }
	end
	local itemNinho = item :: Modelos.Item

	local modelo = Modelos.criar(itemNinho)
	local prompt = Modelos.prompt(modelo)
	prompt.ActionText = "Pegar"
	prompt.HoldDuration = 0.5
	prompt.Triggered:Connect(function(player)
		if ninho.modelo ~= modelo or Carregar.estaCarregando(player) then
			return
		end
		ninho.modelo = nil
		ninho.item = nil
		modelo:Destroy()
		local function devolver()
			encherNinho(bioma, ninho, itemNinho)
		end
		if not Carregar.pegar(player, itemNinho, devolver) then
			devolver()
			return
		end
		Avisos.enviar(player, "Corra para a sua base! O guardião acordou!", VERDE)
		local guardiao = bioma.guardiao
		if not guardiao.alvo then
			guardiao.correEm = os.clock() + TEMPO_ACORDAR
		end
		guardiao.alvo = player
	end)

	modelo:PivotTo(ninho.cframe)
	modelo.Parent = bioma.info.pasta
	ninho.modelo = modelo
	ninho.item = itemNinho
end

local function criarBioma(info: Mapa.InfoBioma): Bioma
	local bioma: Bioma = {
		info = info,
		ninhos = {},
		guardiao = criarGuardiao(info),
		textoTempo = nil :: any,
	}

	for i = 1, NINHOS_POR_BIOMA do
		local angulo = (i - 1) / NINHOS_POR_BIOMA * math.pi * 2
		local pos = info.centro + Vector3.new(math.cos(angulo), 0, math.sin(angulo)) * RAIO_NINHOS

		local base = Instance.new("Part")
		base.Name = "Ninho"
		base.Shape = Enum.PartType.Cylinder
		base.Anchored = true
		base.Size = Vector3.new(1, 5, 5)
		base.CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
		base.Color = Color3.fromRGB(120, 85, 50)
		base.Material = Enum.Material.WoodPlanks
		base.Parent = info.pasta

		local ninho: Ninho = {
			cframe = CFrame.lookAt(pos + Vector3.new(0, 1, 0), info.centro + Vector3.new(0, 1, 0)),
			item = nil,
			modelo = nil,
		}
		table.insert(bioma.ninhos, ninho)
	end

	local marco = Instance.new("Part")
	marco.Name = "Relogio"
	marco.Anchored = true
	marco.CanCollide = false
	marco.Transparency = 1
	marco.Size = Vector3.new(1, 1, 1)
	marco.Position = info.entrada + Vector3.new(14, 0, -10)
	marco.Parent = info.pasta
	bioma.textoTempo = Mapa.placa(marco, "", 3, 220)

	return bioma
end

local function moverGuardiao(bioma: Bioma, dt: number)
	local guardiao = bioma.guardiao
	local info = bioma.info
	local destino = guardiao.casa.Position

	local alvo = guardiao.alvo
	if alvo then
		local personagem = alvo.Character
		local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
		local margem = Mapa.TAMANHO_BIOMA + 30
		if
			not raiz
			or alvo.Parent == nil
			or not Carregar.estaCarregando(alvo)
			or not Mapa.dentroQuadrado(info.centro, margem, raiz.Position)
		then
			-- fugiu, entregou ou perdeu o ovo: volta para casa
			guardiao.alvo = nil
		elseif os.clock() >= guardiao.correEm then
			destino = Vector3.new(raiz.Position.X, info.centro.Y, raiz.Position.Z)
			local distancia = (Vector3.new(raiz.Position.X, 0, raiz.Position.Z) - Vector3.new(
				guardiao.posicao.X,
				0,
				guardiao.posicao.Z
			)).Magnitude
			if distancia <= DISTANCIA_PEGAR then
				Carregar.derrubar(alvo, "O guardião te pegou! Você perdeu o ovo.")
				guardiao.alvo = nil
			end
		else
			return -- ainda acordando
		end
	end

	local delta = destino - guardiao.posicao
	local passo = guardiao.velocidade * dt
	if delta.Magnitude < 0.1 then
		return
	end
	if delta.Magnitude <= passo then
		guardiao.posicao = destino
	else
		guardiao.posicao += delta.Unit * passo
	end
	local olhar = if delta.Magnitude > 0.1 then guardiao.posicao + delta.Unit else guardiao.posicao + Vector3.xAxis
	guardiao.modelo:PivotTo(CFrame.lookAt(guardiao.posicao, Vector3.new(olhar.X, guardiao.posicao.Y, olhar.Z)))
end

-- Quem não tem Velocidade suficiente é empurrado de volta para a entrada.
local function verificarPortoes()
	for _, player in Players:GetPlayers() do
		local personagem = player.Character
		local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
		if raiz then
			for _, bioma in biomas do
				local minimo = bioma.info.config.velocidadeMinima
				if
					minimo > 0
					and Dados.valor(player, "Velocidade") < minimo
					and Mapa.dentroQuadrado(bioma.info.centro, Mapa.TAMANHO_BIOMA, raiz.Position)
				then
					personagem:PivotTo(CFrame.lookAt(bioma.info.entrada, bioma.info.entrada - Vector3.xAxis))
					if os.clock() - (ultimoAvisoPortao[player] or 0) > 3 then
						ultimoAvisoPortao[player] = os.clock()
						Avisos.enviar(
							player,
							`Você precisa de {Config.formatar(minimo)} de Velocidade para entrar no {bioma.info.config.nome}!`,
							VERMELHO
						)
					end
				end
			end
		end
	end
end

function Ninhos.iniciar(infos: { Mapa.InfoBioma })
	for _, info in infos do
		table.insert(biomas, criarBioma(info))
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, bioma in biomas do
			moverGuardiao(bioma, dt)
		end
	end)

	task.spawn(function()
		local proximaRenovacao = 0
		while true do
			local agora = os.clock()
			if agora >= proximaRenovacao then
				proximaRenovacao = agora + Config.TEMPO_NINHOS
				for _, bioma in biomas do
					for _, ninho in bioma.ninhos do
						encherNinho(bioma, ninho)
					end
				end
			end
			local falta = math.ceil(proximaRenovacao - agora)
			for _, bioma in biomas do
				bioma.textoTempo.Text = `Ovos novos em {falta}s`
			end
			verificarPortoes()
			task.wait(0.5)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		ultimoAvisoPortao[player] = nil
	end)
end

return Ninhos

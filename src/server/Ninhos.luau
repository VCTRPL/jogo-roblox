-- Biomas: ninhos com ovos, o guardião que persegue quem pega um ovo
-- e o bloqueio para quem não tem Velocidade suficiente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Carregar = require(script.Parent.Carregar)
local Dados = require(script.Parent.Dados)
local Guardioes = require(script.Parent.Guardioes)
local Mapa = require(script.Parent.Mapa)
local Modelos = require(script.Parent.Modelos)

local Ninhos = {}

local NINHOS_POR_BIOMA = 8
local RAIO_NINHOS = 32
local TEMPO_ACORDAR = 1 -- segundos até o guardião começar a correr
local VOLTA_MAIS_RAPIDO = 1.6 -- na volta para casa o guardião corre mais

type Ninho = {
	cframe: CFrame,
	item: Modelos.Item?,
	modelo: Model?,
}

type Guardiao = {
	modelo: Model,
	visual: Guardioes.Visual,
	casa: CFrame,
	posicao: Vector3,
	alvo: Player?,
	correEm: number,
	velocidade: number,
	alcance: number, -- derruba quem chegar a essa distância (depende do tamanho)
	bravo: boolean, -- mostrando o "!" e os olhos vermelhos
}

type Bioma = {
	info: Mapa.InfoBioma,
	ninhos: { Ninho },
	guardiao: Guardiao,
	textoTempo: TextLabel,
}

local biomas: { Bioma } = {}
local trocarAlvo: (guardiao: Guardiao, alvo: Player?) -> ()
local ultimoAvisoPortao: { [Player]: number } = {}

local VERMELHO = Color3.fromRGB(255, 90, 90)
local VERDE = Color3.fromRGB(90, 255, 120)

local function criarGuardiao(info: Mapa.InfoBioma): Guardiao
	local visual = Guardioes.criar(info.config)
	local casa = CFrame.lookAt(info.centro, info.centro + Vector3.new(-1, 0, 0))
	visual.modelo:PivotTo(casa)
	visual.modelo.Parent = info.pasta

	return {
		modelo = visual.modelo,
		visual = visual,
		casa = casa,
		posicao = info.centro,
		alvo = nil,
		correEm = 0,
		velocidade = info.config.velocidadeGuardiao,
		alcance = visual.raio + 2.5,
		bravo = false,
	}
end

-- Coluna de luz em cima dos ovos raros, para todo mundo ver de longe.
local function colunaDeLuz(modelo: Model, cor: Color3)
	local centro = modelo:GetPivot().Position
	Mapa.parte({
		Name = "ColunaDeLuz",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(60, 1.8, 1.8),
		CFrame = CFrame.new(centro + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = cor,
		Material = Enum.Material.Neon,
		Transparency = 0.55,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Parent = modelo,
	})
end

local function encherNinho(bioma: Bioma, ninho: Ninho, item: Modelos.Item?)
	if ninho.modelo then
		return
	end
	local novo = item == nil
	if not item then
		local ovo = Config.sortearOvo(bioma.info.config)
		item = { tipo = "ovo", id = ovo.id, tamanho = Config.sortearTamanho().nome }
	end
	local itemNinho = item :: Modelos.Item
	local ovo = Config.ovo(itemNinho.id)

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
		Avisos.enviar(player, `Corra para a sua base! {bioma.info.config.guardiao} acordou!`, VERDE)
		local guardiao = bioma.guardiao
		Avisos.som(nil, "Rugido", guardiao.posicao)
		if not guardiao.alvo then
			guardiao.correEm = os.clock() + TEMPO_ACORDAR
		end
		trocarAlvo(guardiao, player)
	end)

	modelo:PivotTo(ninho.cframe)
	if Config.nivelRaridade(ovo.raridade) >= Config.nivelRaridade("Lendario") then
		colunaDeLuz(modelo, Config.CORES_RARIDADE[ovo.raridade])
	end
	-- o cliente faz o ovo flutuar e girar em cima do ninho
	modelo:SetAttribute("NoNinho", true)
	modelo.Parent = bioma.info.pasta
	ninho.modelo = modelo
	ninho.item = itemNinho
	if novo and Config.nivelRaridade(ovo.raridade) >= Config.nivelRaridade("Mitico") then
		Avisos.todos(`Um {ovo.nome} apareceu na {bioma.info.config.nome}! Corra!`, Config.CORES_RARIDADE[ovo.raridade])
	end
end

-- Como é o ninho em cada bioma: palha no meio e o que fica em volta.
local NINHOS = {
	floresta = { palha = Color3.fromRGB(196, 150, 85), galhos = { Color3.fromRGB(120, 82, 48), Color3.fromRGB(160, 112, 66) }, neon = false },
	praia = { palha = Color3.fromRGB(235, 215, 160), galhos = { Color3.fromRGB(205, 185, 150), Color3.fromRGB(255, 170, 180) }, neon = false },
	deserto = { palha = Color3.fromRGB(215, 175, 115), galhos = { Color3.fromRGB(245, 240, 225), Color3.fromRGB(225, 215, 195) }, neon = false },
	vulcao = { palha = Color3.fromRGB(70, 55, 50), galhos = { Color3.fromRGB(35, 30, 35), Color3.fromRGB(255, 110, 30) }, neon = true },
	espaco = { palha = Color3.fromRGB(90, 90, 120), galhos = { Color3.fromRGB(80, 220, 255), Color3.fromRGB(200, 90, 255) }, neon = true },
}

-- Ninho com um círculo de luz na cor do bioma embaixo: galhos na Selva,
-- conchas na Praia, ossos no Deserto, pedra e lava no Vulcão e cristais no Espaço.
local function criarModeloNinho(info: Mapa.InfoBioma, pos: Vector3)
	local tema = NINHOS[info.config.estilo] or NINHOS.floresta
	local modelo = Instance.new("Model")
	modelo.Name = "Ninho"
	local deitado = CFrame.Angles(0, 0, math.rad(90)) -- cilindros do Roblox deitam no eixo X
	Mapa.parte({
		Name = "Luz",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.15, 7.5, 7.5),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * deitado,
		Color = info.config.cor:Lerp(Color3.new(1, 1, 1), 0.35),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		CastShadow = false,
		Parent = modelo,
	})
	Mapa.parte({
		Name = "Palha",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 5.5, 5.5),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * deitado,
		Color = tema.palha,
		Material = Enum.Material.Grass,
		Parent = modelo,
	})
	-- galhos em volta da borda
	local galhos = 12
	for i = 1, galhos do
		local angulo = i / galhos * math.pi * 2
		local borda = pos + Vector3.new(math.cos(angulo), 0, math.sin(angulo)) * 2.6
		Mapa.parte({
			Name = "Galho",
			Size = Vector3.new(0.55, 0.55, 2.6),
			CFrame = CFrame.lookAt(borda + Vector3.new(0, 1.15, 0), borda + Vector3.new(0, 1.15, 0) + Vector3.new(-math.sin(angulo), 0, math.cos(angulo)))
				* CFrame.Angles(0, 0, math.rad(i * 37 % 60 - 30))
				* CFrame.Angles(math.rad(i % 2 * 16 - 8), 0, 0),
			Color = tema.galhos[i % 2 + 1],
			-- no Vulcão e no Espaço um galho sim, um não brilha (lava e cristal)
			Material = if tema.neon and i % 2 == 1 then Enum.Material.Neon else Enum.Material.Wood,
			CanCollide = false,
			Parent = modelo,
		})
	end
	modelo.Parent = info.pasta
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

		criarModeloNinho(info, pos)

		local ninho: Ninho = {
			cframe = CFrame.lookAt(pos + Vector3.new(0, 1, 0), info.centro + Vector3.new(0, 1, 0)),
			item = nil,
			modelo = nil,
		}
		table.insert(bioma.ninhos, ninho)
	end

	-- placa de madeira logo depois da entrada, virada para quem chega
	local chao = Vector3.new(info.centro.X - Mapa.TAMANHO_BIOMA / 2 + 5, info.centro.Y, -11)
	Mapa.parte({
		Name = "PostePlaca",
		Size = Vector3.new(0.8, 5, 0.8),
		Position = chao + Vector3.new(0, 2.5, 0),
		Color = Color3.fromRGB(105, 70, 42),
		Material = Enum.Material.Wood,
		Parent = info.pasta,
	})
	local placa = Mapa.parte({
		Name = "Relogio",
		Size = Vector3.new(7, 2.6, 0.5),
		CFrame = CFrame.lookAt(chao + Vector3.new(0, 5, 0), chao + Vector3.new(-1, 5, 0)),
		Color = Color3.fromRGB(170, 120, 72),
		Material = Enum.Material.WoodPlanks,
		Parent = info.pasta,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.Parent = placa
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0.05, 0.1)
	label.Size = UDim2.fromScale(0.9, 0.8)
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 245, 210)
	local contorno = Instance.new("UIStroke")
	contorno.Thickness = 3
	contorno.Color = Color3.fromRGB(70, 45, 25)
	contorno.Parent = label
	label.Parent = gui
	bioma.textoTempo = label

	return bioma
end

-- Quem está sendo perseguido fica marcado (o cliente mostra o aviso vermelho).
function trocarAlvo(guardiao: Guardiao, alvo: Player?)
	local antigo = guardiao.alvo
	if antigo == alvo then
		return
	end
	if antigo and antigo:GetAttribute("Perseguido") == guardiao.modelo.Name then
		antigo:SetAttribute("Perseguido", nil)
	end
	guardiao.alvo = alvo
	if alvo then
		alvo:SetAttribute("Perseguido", guardiao.modelo.Name)
	end
end

local function ficarBravo(guardiao: Guardiao, bravo: boolean)
	if guardiao.bravo ~= bravo then
		guardiao.bravo = bravo
		Guardioes.bravo(guardiao.visual, bravo)
	end
end

local function moverGuardiao(bioma: Bioma, dt: number)
	local guardiao = bioma.guardiao
	local info = bioma.info
	local destino = guardiao.casa.Position

	local alvo = guardiao.alvo
	if alvo then
		local personagem = alvo.Character
		local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
		if
			not raiz
			or alvo.Parent == nil
			or not Carregar.estaCarregando(alvo)
			or raiz.Position.X < Mapa.FIM_BASES
		then
			-- chegou na área das bases, entregou ou perdeu o ovo: volta para casa
			trocarAlvo(guardiao, nil)
		elseif os.clock() >= guardiao.correEm then
			destino = Vector3.new(raiz.Position.X, info.centro.Y, raiz.Position.Z)
			local distancia = (Vector3.new(raiz.Position.X, 0, raiz.Position.Z) - Vector3.new(
				guardiao.posicao.X,
				0,
				guardiao.posicao.Z
			)).Magnitude
			if distancia <= guardiao.alcance then
				Carregar.derrubar(alvo, `{info.config.guardiao} te pegou! Você perdeu o ovo.`)
				trocarAlvo(guardiao, nil)
			end
		else
			ficarBravo(guardiao, true)
			return -- ainda acordando
		end
	end
	ficarBravo(guardiao, guardiao.alvo ~= nil)

	local delta = destino - guardiao.posicao
	local passo = guardiao.velocidade * dt * (if guardiao.alvo then 1 else VOLTA_MAIS_RAPIDO)
	if delta.Magnitude < 0.1 then
		return
	end
	local chegou = delta.Magnitude <= passo
	if chegou and not guardiao.alvo then
		-- voltou para casa: vira de novo para a entrada
		guardiao.posicao = destino
		guardiao.modelo:PivotTo(guardiao.casa)
		return
	elseif chegou then
		guardiao.posicao = destino
	else
		guardiao.posicao += delta.Unit * passo
	end
	local olhar = if delta.Magnitude > 0.1 then guardiao.posicao + delta.Unit else guardiao.posicao + Vector3.xAxis
	-- passos pesados: pulinhos que ficam mais rápidos quanto mais rápido ele é
	local pulo = if chegou then 0 else math.abs(math.sin(os.clock() * guardiao.velocidade / 6)) * 1.2
	guardiao.modelo:PivotTo(
		CFrame.lookAt(guardiao.posicao, Vector3.new(olhar.X, guardiao.posicao.Y, olhar.Z)) + Vector3.new(0, pulo, 0)
	)
end

-- Quem não tem Velocidade suficiente é empurrado de volta para a entrada.
-- Também marca em que bioma cada um está (o cliente troca a música).
local function verificarPortoes()
	for _, player in Players:GetPlayers() do
		local personagem = player.Character
		local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
		if raiz then
			local onde = nil
			for _, bioma in biomas do
				if Mapa.dentroQuadrado(bioma.info.centro, Mapa.TAMANHO_BIOMA, raiz.Position) then
					onde = bioma.info.config.nome
				end
			end
			if player:GetAttribute("Bioma") ~= onde then
				player:SetAttribute("Bioma", onde)
			end
			-- o primeiro bioma trancado para essa pessoa barra a estrada inteira
			-- dali para a frente (não dá para passar pelo lado)
			for _, bioma in biomas do
				local minimo = bioma.info.config.velocidadeMinima
				local inicioBioma = bioma.info.centro.X - Mapa.TAMANHO_BIOMA / 2
				local trancado = minimo > 0 and Dados.valor(player, "Velocidade") < minimo
				if trancado and raiz.Position.X > inicioBioma - 0.5 and math.abs(raiz.Position.Z) < Mapa.Z_PAREDE + 12 then
					personagem:PivotTo(CFrame.lookAt(bioma.info.entrada, bioma.info.entrada - Vector3.xAxis))
					if os.clock() - (ultimoAvisoPortao[player] or 0) > 3 then
						ultimoAvisoPortao[player] = os.clock()
						Avisos.enviar(
							player,
							`Você precisa de {Config.formatar(minimo)} de Velocidade para entrar em {bioma.info.config.nome}!`,
							VERMELHO
						)
					end
					break
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
				bioma.textoTempo.Text = `OVOS NOVOS EM {falta}s`
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

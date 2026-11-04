-- Farm AFK: o dinheiro que a base rendeu enquanto o jogador estava fora do
-- jogo aparece numa pilha de notas na base dele. Só o dono pega: chegando
-- perto e apertando "Coletar" (ou encostando nela). O valor fica em
-- Dados.pilha e é salvo, então a pilha volta se ele sair sem coletar.
-- Ajuste o limite de horas e a porcentagem em Config.FARM_OFFLINE.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Bases = require(script.Parent.Bases)
local Dados = require(script.Parent.Dados)
local Paineis = require(script.Parent.Paineis)

local Pilha = {}

local VERDE_NOTA = Color3.fromRGB(85, 190, 95)
local VERDE_ESCURO = Color3.fromRGB(45, 130, 60)
local DOURADO = Color3.fromRGB(255, 215, 70)
local VERDE = Color3.fromRGB(90, 255, 120)

local pilhas: { [Player]: Model } = {}
local aparecer: (Model, BasePart) -> ()

-- "2h 15min", "40min", "50s"
local function tempo(segundos: number): string
	local horas = segundos // 3600
	local minutos = (segundos % 3600) // 60
	if horas > 0 then
		return if minutos > 0 then `{horas}h {minutos}min` else `{horas}h`
	elseif minutos > 0 then
		return `{minutos}min`
	end
	return `{segundos}s`
end

local function parte(modelo: Model, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for chave, valor in props do
		(p :: any)[chave] = valor
	end
	p.Parent = modelo
	return p
end

-- Uma pirâmide de maços de notas com moedas em volta. Quanto mais
-- dinheiro, mais alta (de 1 a 6 camadas).
local function montar(centro: CFrame, quantia: number): (Model, Part)
	local modelo = Instance.new("Model")
	modelo.Name = "PilhaDinheiro"

	local base = parte(modelo, {
		Name = "Base",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 9, 9),
		CFrame = centro * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = DOURADO,
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanTouch = true,
	})

	local camadas = math.clamp(math.floor(math.log10(math.max(quantia, 10))) - 1, 1, 6)
	local altura = 0.4
	for camada = 1, camadas do
		local lado = camadas - camada + 2 -- maços por lado nesta camada
		for i = 1, lado do
			for j = 1, lado do
				local x = (i - (lado + 1) / 2) * 1.5
				local z = (j - (lado + 1) / 2) * 2.3
				local giro = math.rad(math.random(-8, 8))
				local cf = centro * CFrame.new(x, altura + 0.3, z) * CFrame.Angles(0, giro, 0)
				parte(modelo, {
					Name = "Maco",
					Size = Vector3.new(1.3, 0.6, 2.1),
					CFrame = cf,
					Color = VERDE_NOTA,
					Material = Enum.Material.SmoothPlastic,
				})
				-- a cinta de papel no meio do maço
				parte(modelo, {
					Name = "Cinta",
					Size = Vector3.new(1.35, 0.65, 0.4),
					CFrame = cf,
					Color = if (i + j) % 2 == 0 then Color3.new(1, 1, 1) else VERDE_ESCURO,
					Material = Enum.Material.SmoothPlastic,
				})
			end
		end
		altura += 0.6
	end

	-- moedas espalhadas em volta
	for i = 1, 8 do
		local angulo = i / 8 * math.pi * 2 + math.random() * 0.4
		local raio = 3.4 + math.random() * 0.6
		parte(modelo, {
			Name = "Moeda",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.25, 1, 1),
			CFrame = centro
				* CFrame.new(math.cos(angulo) * raio, 0.55, math.sin(angulo) * raio)
				* CFrame.Angles(0, 0, math.rad(90 + math.random(-15, 15))),
			Color = DOURADO,
			Material = Enum.Material.Metal,
		})
	end

	-- ponto do botão, do painel e do brilho, em cima da pilha
	local topo = parte(modelo, {
		Name = "Topo",
		Size = Vector3.one,
		CFrame = centro * CFrame.new(0, altura + 1, 0),
		Transparency = 1,
	})
	local luz = Instance.new("PointLight")
	luz.Color = DOURADO
	luz.Range = 14
	luz.Brightness = 2
	luz.Parent = topo
	local brilho = Instance.new("Sparkles")
	brilho.SparkleColor = DOURADO
	brilho.Parent = topo

	modelo.PrimaryPart = base
	return modelo, topo
end

-- A pilha aparece crescendo do chão com um pulinho, um estouro de moedas
-- douradas e uma coluna de luz que some devagar (para o dono achar a pilha).
function aparecer(modelo: Model, topo: BasePart)
	local escala = Instance.new("NumberValue")
	escala.Value = 0.05
	modelo:ScaleTo(0.05)
	escala.Changed:Connect(function(valor)
		if modelo.Parent then
			modelo:ScaleTo(math.max(valor, 0.05))
		end
	end)
	local tween = TweenService:Create(escala, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 })
	tween.Completed:Once(function()
		escala:Destroy()
	end)
	task.delay(0.4, function()
		tween:Play()
	end)
	local estouro = Instance.new("ParticleEmitter")
	estouro.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	estouro.Color = ColorSequence.new(DOURADO, Color3.new(1, 1, 1))
	estouro.LightEmission = 1
	estouro.Size = NumberSequence.new(1, 0)
	estouro.Lifetime = NumberRange.new(0.8, 1.4)
	estouro.Speed = NumberRange.new(12, 20)
	estouro.SpreadAngle = Vector2.new(60, 60)
	estouro.Acceleration = Vector3.new(0, -30, 0)
	estouro.Rate = 0
	estouro.Parent = topo
	task.delay(0.6, function()
		if estouro.Parent then
			estouro:Emit(40)
		end
	end)
	local coluna = parte(modelo, {
		Name = "ColunaLuz",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(40, 4, 4),
		CFrame = CFrame.new(topo.Position.X, modelo:GetPivot().Y + 20, topo.Position.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = DOURADO,
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		CastShadow = false,
	})
	coluna:SetAttribute("ManterForma", true)
	coluna.Parent = modelo.Parent -- fora do modelo, para não crescer junto
	task.delay(6.5, function()
		coluna:Destroy()
	end)
	TweenService:Create(coluna, TweenInfo.new(6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
end

local function coletar(player: Player)
	local modelo = pilhas[player]
	if not modelo then
		return
	end
	pilhas[player] = nil
	local posicao = modelo:GetPivot().Position
	modelo:Destroy()
	local quantia = Dados.esvaziarPilha(player)
	if quantia <= 0 then
		return
	end
	Dados.adicionar(player, "Dinheiro", quantia)
	Avisos.enviar(player, `Coletou ${Config.formatar(quantia)} do farm AFK!`, VERDE)
	Avisos.som(player, "Vendeu")
	Avisos.efeito("Coletou", { posicao = posicao, ganho = quantia })
end

-- Chamado quando o jogador entra e já tem base: monta a pilha se tiver
-- dinheiro esperando.
function Pilha.entrar(player: Player, base: Bases.Base)
	local quantia = Dados.pilha(player)
	if quantia <= 0 or pilhas[player] then
		return
	end
	local info = base.info
	-- entre o lugar onde ele nasce e a estrada, um pouco para o lado
	local posicao = info.centro + Vector3.new(-6, 0, -info.lado * 10)
	local centro = CFrame.lookAt(posicao, posicao + Vector3.new(0, 0, -info.lado))
	local modelo, topo = montar(centro, quantia)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Coletar"
	prompt.ActionText = "Coletar"
	prompt.ObjectText = `${Config.formatar(quantia)}`
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 12
	prompt.Parent = topo
	prompt.Triggered:Connect(function(quem)
		if quem == player then
			coletar(player)
		end
	end)
	-- encostar na pilha também coleta
	local chao = modelo.PrimaryPart :: BasePart
	chao.Touched:Connect(function(outra)
		local personagem = outra:FindFirstAncestorOfClass("Model")
		if personagem and Players:GetPlayerFromCharacter(personagem) == player then
			coletar(player)
		end
	end)

	local ganho, segundos = Dados.offline(player)
	local painel = Paineis.criar(topo, {
		altura = 3.5,
		largura = 11,
		alto = 3.6,
		cores = { Color3.fromRGB(120, 230, 110), Color3.fromRGB(30, 140, 70) },
		distancia = 150,
	})
	painel.icone.Text = "💰"
	painel.titulo.Text = "FARM AFK"
	painel.linha.Text = `${Config.formatar(quantia)}`
	painel.barra.Visible = false

	modelo.Parent = info.pasta
	pilhas[player] = modelo
	aparecer(modelo, topo)

	if ganho > 0 then
		Avisos.enviar(
			player,
			`Sua base rendeu ${Config.formatar(ganho)} em {tempo(segundos)} fora! Pegue a pilha de dinheiro na sua base.`,
			DOURADO
		)
	else
		Avisos.enviar(player, `Tem ${Config.formatar(quantia)} esperando na sua base! Pegue a pilha de dinheiro.`, DOURADO)
	end
end

-- Saiu do jogo: a pilha some do mapa (o valor continua salvo).
function Pilha.sair(player: Player)
	local modelo = pilhas[player]
	pilhas[player] = nil
	if modelo then
		modelo:Destroy()
	end
end

return Pilha

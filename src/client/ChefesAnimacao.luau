-- Animação dos chefes (guardiões), só neste computador. O servidor só anda
-- com o modelo e vira para onde ele vai; aqui as pernas dão passos, os
-- braços balançam, o corpo sobe e desce e inclina, o anel da Saturnita gira,
-- ele ruge quando acorda (fica bravo) e dá um golpe quando pega alguém.
--
-- Funciona com os chefes de blocos do Blender: cada membro (BracoD, BracoE,
-- PernaD, PernaE, PernaFD, PernaTE..., Anel) é uma peça com um Attachment
-- "Junta" na articulação. O resto (corpo, olhos, placa) segue o tronco.
-- Tudo é calculado a partir da pose que veio do servidor (a de descanso),
-- então nada acumula e o servidor continua mandando só a posição.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Tremor = require(script.Parent.Tremor)

local ChefesAnimacao = {}

local LONGE = 420 -- chefes mais longe que isso da câmera ficam parados
local TEMPO_RUGIDO = 1.1
local TEMPO_GOLPE = 0.6

type Membro = {
	parte: BasePart,
	nome: string,
	junta: CFrame, -- articulação, no espaço do pivot (pés)
	descanso: CFrame,
	perna: boolean,
	lado: number, -- +1 ou -1: em que lado do corpo está (X)
	fase: number, -- +1 ou -1: em que meio passo ele vai para a frente
	maoAcima: boolean, -- braço que já fica levantado (taco do Sahur, braços do cacto)
}

type Rig = {
	modelo: Model,
	tronco: { BasePart },
	descansoTronco: { CFrame },
	membros: { Membro },
	altura: number,
	quadril: number,
	quadrupede: boolean,
	temBracos: boolean,
	-- estado
	fase: number,
	velocidade: number,
	ultima: Vector3?,
	bravo: boolean,
	rugidoEm: number,
	golpeEm: number,
	golpeVisto: number,
	golpeFeito: boolean,
	giroAnel: number,
	ultimoSinal: number,
	-- círculo de runas na casa e anel do alcance em volta dele (só aqui)
	casa: Circulo?,
	perigo: Circulo?,
	brilho: number, -- 0 calmo, 1 bravo (suavizado)
	-- listas reaproveitadas para o BulkMoveTo
	pecas: { BasePart },
	cframes: { CFrame },
}

type Circulo = {
	partes: { BasePart },
	locais: { CFrame }, -- de cada peça, a partir do centro do círculo
	giro: number,
	transparencia: number,
}

local rigs: { [Model]: Rig | false } = {}
local pastaEfeitos: Folder? = nil
local aoPisar: { (Model, Vector3, number) -> () } = {}

-- Monta o rig a partir da pose atual (a do servidor). Devolve false se o
-- modelo não tem membros com "Junta" (chefe antigo, montado com peças).
local function montar(modelo: Model): Rig | false | nil
	local raiz = modelo.PrimaryPart
	if not raiz then
		return nil -- ainda chegando
	end
	local pivot = modelo:GetPivot()
	local tronco, descansoTronco, membros = {}, {}, {}
	local quadris, temBracos, temPernaFrente = {}, false, false
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("BasePart") and parte ~= raiz then
			local junta = parte:FindFirstChild("Junta")
			if junta and junta:IsA("Attachment") then
				local posJunta = pivot:PointToObjectSpace(junta.WorldPosition)
				local descanso = pivot:ToObjectSpace(parte.CFrame)
				local nome = parte.Name
				local perna = nome:match("^Perna") ~= nil
				local lado = if posJunta.X >= 0 then 1 else -1
				-- PernaD/PernaFD/PernaTE vão juntas; braço vai com a perna do outro lado
				local fase = 1
				if nome == "PernaE" or nome == "PernaFE" or nome == "PernaTD" or nome == "BracoD" then
					fase = -1
				end
				if perna then
					table.insert(quadris, posJunta.Y)
					if nome:match("^PernaF") then
						temPernaFrente = true
					end
				elseif nome:match("^Braco") then
					temBracos = true
				end
				table.insert(membros, {
					parte = parte,
					nome = nome,
					junta = CFrame.new(posJunta),
					descanso = descanso,
					perna = perna,
					lado = lado,
					fase = fase,
					maoAcima = descanso.Position.Y > posJunta.Y + 0.2,
				})
			else
				table.insert(tronco, parte)
				table.insert(descansoTronco, pivot:ToObjectSpace(parte.CFrame))
			end
		end
	end
	if #membros == 0 then
		return false
	end
	local altura = modelo:GetAttribute("Altura") or modelo:GetExtentsSize().Y
	local quadril = altura * 0.3
	if #quadris > 0 then
		local soma = 0
		for _, y in quadris do
			soma += y
		end
		quadril = soma / #quadris
	end
	return {
		modelo = modelo,
		tronco = tronco,
		descansoTronco = descansoTronco,
		membros = membros,
		altura = altura,
		quadril = quadril,
		quadrupede = temPernaFrente,
		temBracos = temBracos,
		fase = 0,
		velocidade = 0,
		ultima = nil,
		bravo = modelo:GetAttribute("Bravo") == true,
		rugidoEm = -100,
		golpeEm = -100,
		golpeVisto = modelo:GetAttribute("Ataque") or 0,
		golpeFeito = false,
		giroAnel = 0,
		ultimoSinal = 1,
		casa = nil,
		perigo = nil,
		brilho = 0,
		pecas = table.create(#tronco + #membros),
		cframes = table.create(#tronco + #membros),
	}
end

-- Efeitos -----------------------------------------------------------------------

-- Anel de choque que se abre no chão (golpe e rugido).
local function onda(posicao: Vector3, raio: number, cor: Color3, duracao: number)
	local anel = Instance.new("Part")
	anel.Name = "OndaChefe"
	anel.Anchored = true
	anel.CanCollide = false
	anel.CanQuery = false
	anel.CanTouch = false
	anel.CastShadow = false
	anel.Shape = Enum.PartType.Cylinder
	anel.Material = Enum.Material.Neon
	anel.Color = cor
	anel.Transparency = 0.15
	anel.Size = Vector3.new(0.25, raio * 0.3, raio * 0.3)
	anel.CFrame = CFrame.new(posicao + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	anel.Parent = Workspace
	local info = TweenInfo.new(duracao, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(anel, info, { Size = Vector3.new(0.12, raio * 2, raio * 2), Transparency = 1 }):Play()
	Debris:AddItem(anel, duracao + 0.1)
end

-- Poeira e pedrinhas que voam do chão.
local function poeira(posicao: Vector3, largura: number, quantidade: number, cor: Color3)
	local base = Instance.new("Part")
	base.Name = "PoeiraGolpe"
	base.Anchored = true
	base.CanCollide = false
	base.CanQuery = false
	base.CanTouch = false
	base.Transparency = 1
	base.Size = Vector3.new(largura, 0.2, largura)
	base.Position = posicao + Vector3.new(0, 0.3, 0)
	base.Parent = Workspace
	local nuvem = Instance.new("ParticleEmitter")
	nuvem.Texture = "rbxasset://textures/particles/smoke_main.dds"
	nuvem.Color = ColorSequence.new(cor)
	nuvem.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.6, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	nuvem.Size = NumberSequence.new(largura * 0.25, largura * 0.6)
	nuvem.Lifetime = NumberRange.new(0.6, 1.1)
	nuvem.Speed = NumberRange.new(largura * 0.8, largura * 1.4)
	nuvem.SpreadAngle = Vector2.new(180, 10)
	nuvem.Drag = 5
	nuvem.Rotation = NumberRange.new(0, 360)
	nuvem.RotSpeed = NumberRange.new(-60, 60)
	nuvem.Rate = 0
	nuvem.Shape = Enum.ParticleEmitterShape.Box
	nuvem.Parent = base
	nuvem:Emit(math.ceil(quantidade * Tremor.qualidade))
	local pedras = Instance.new("ParticleEmitter")
	pedras.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pedras.Color = ColorSequence.new(cor:Lerp(Color3.new(0, 0, 0), 0.35))
	pedras.Size = NumberSequence.new(0.6, 0.2)
	pedras.Lifetime = NumberRange.new(0.5, 0.9)
	pedras.Speed = NumberRange.new(largura * 1.2, largura * 2)
	pedras.SpreadAngle = Vector2.new(60, 60)
	pedras.EmissionDirection = Enum.NormalId.Top
	pedras.Acceleration = Vector3.new(0, -60, 0)
	pedras.Rate = 0
	pedras.Parent = base
	pedras:Emit(math.ceil(quantidade * 0.8 * Tremor.qualidade))
	Debris:AddItem(base, 1.4)
end

local function golpeVfx(rig: Rig, pivot: CFrame)
	local frente = pivot.Position + pivot.LookVector * rig.altura * 0.35
	onda(frente, rig.altura * 0.9, Color3.fromRGB(255, 70, 50), 0.55)
	onda(frente, rig.altura * 0.55, Color3.fromRGB(255, 220, 160), 0.35)
	poeira(frente, rig.altura * 0.3, 14, Color3.fromRGB(205, 185, 150))
	Tremor.perto(frente, 1, 80, 0.45)
	Tremor.soco(-4)
end

local function rugidoVfx(rig: Rig, pivot: CFrame)
	onda(pivot.Position, rig.altura * 1.1, Color3.fromRGB(200, 20, 20), 0.8)
	Tremor.perto(pivot.Position, 0.6, 90, 0.7)
end

-- Curva do golpe: puxa para trás (preparo), desce rápido e volta.
local function curvaGolpe(t: number, preparo: number, batida: number): number
	if t < 0.35 then
		local p = t / 0.35
		return preparo * (1 - (1 - p) ^ 2)
	elseif t < 0.5 then
		local p = (t - 0.35) / 0.15
		return preparo + (batida - preparo) * (p * p)
	else
		local p = (t - 0.5) / 0.5
		return batida * (1 - p) ^ 2
	end
end

-- Círculos no chão ------------------------------------------------------------

local function pasta(): Folder
	if not (pastaEfeitos and pastaEfeitos.Parent) then
		local nova = Instance.new("Folder")
		nova.Name = "EfeitosChefes"
		nova.Parent = Workspace
		pastaEfeitos = nova
	end
	return pastaEfeitos :: Folder
end

-- Anel de traços de neon (como runas) deitado no chão.
local function anel(c: Circulo, raio: number, quantos: number, largura: number, cheio: number, losango: boolean)
	local comprimento = 2 * math.pi * raio / quantos * cheio
	for i = 1, quantos do
		local angulo = (i / quantos) * math.pi * 2
		local parte = Instance.new("Part")
		parte.Name = "Runa"
		parte.Anchored = true
		parte.CanCollide = false
		parte.CanQuery = false
		parte.CanTouch = false
		parte.CastShadow = false
		parte.Material = Enum.Material.Neon
		parte.Transparency = 1
		parte.Size = if losango then Vector3.new(largura, 0.12, largura) else Vector3.new(comprimento, 0.12, largura)
		parte.Parent = pasta()
		table.insert(c.partes, parte)
		local giro = if losango then CFrame.Angles(0, math.rad(45), 0) else CFrame.identity
		table.insert(c.locais, CFrame.Angles(0, angulo, 0) * CFrame.new(0, 0, -raio) * giro)
	end
end

local function criarCirculo(raio: number, cor: Color3, casa: boolean): Circulo
	local c: Circulo = { partes = {}, locais = {}, giro = 0, transparencia = -1 }
	if casa then
		anel(c, raio, 30, 0.7, 0.62, false)
		anel(c, raio * 0.72, 12, 1.1, 0, true)
		anel(c, raio * 0.45, 18, 0.45, 0.55, false)
	else
		anel(c, raio, 22, 0.55, 0.6, false)
	end
	for _, parte in c.partes do
		parte.Color = cor
	end
	return c
end

local function destruirCirculo(c: Circulo?)
	if c then
		for _, parte in c.partes do
			parte:Destroy()
		end
	end
end

-- Põe o círculo no lugar (girando) e muda a transparência só se mudou bem.
local function moverCirculo(c: Circulo, centro: CFrame, transparencia: number, cor: Color3?, pecas: { BasePart }, cframes: { CFrame })
	local mudou = math.abs(transparencia - c.transparencia) > 0.03
	if mudou then
		c.transparencia = transparencia
	end
	local base = centro * CFrame.Angles(0, c.giro, 0)
	for i, parte in c.partes do
		-- o anel de dentro (losangos) gira ao contrário
		local local_ = c.locais[i]
		if i > 30 and i <= 42 then
			local_ = CFrame.Angles(0, -2.4 * c.giro, 0) * local_
		end
		table.insert(pecas, parte)
		table.insert(cframes, base * local_)
		if mudou then
			parte.Transparency = transparencia
			if cor then
				parte.Color = cor
			end
		end
	end
end

local VERMELHO = Color3.fromRGB(255, 35, 35)

local function circulos(rig: Rig, dt: number, agora: number, pivot: CFrame, bravo: boolean, pecas: { BasePart }, cframes: { CFrame })
	local modelo = rig.modelo
	local alcance = modelo:GetAttribute("Alcance")
	local casa = modelo:GetAttribute("Casa")
	if typeof(alcance) ~= "number" then
		return
	end
	rig.brilho += ((if bravo then 1 else 0) - rig.brilho) * math.min(1, dt * 4)
	local corBioma = modelo:GetAttribute("Cor")
	local calmo = if typeof(corBioma) == "Color3" then corBioma:Lerp(VERMELHO, 0.45) else VERMELHO
	local cor = calmo:Lerp(VERMELHO, rig.brilho)

	if typeof(casa) == "Vector3" then
		if not rig.casa then
			rig.casa = criarCirculo(alcance * 1.3, calmo, true)
		end
		local c = rig.casa :: Circulo
		c.giro += dt * math.rad(8 + 50 * rig.brilho)
		local pulso = (math.sin(agora * (2 + 6 * rig.brilho)) + 1) / 2
		moverCirculo(c, CFrame.new(casa + Vector3.new(0, 0.08, 0)), 0.55 - rig.brilho * 0.4 + pulso * 0.12, cor, pecas, cframes)
	end

	-- anel do alcance: só aparece com ele bravo, embaixo dele
	if not rig.perigo then
		rig.perigo = criarCirculo(alcance, VERMELHO, false)
	end
	local p = rig.perigo :: Circulo
	p.giro -= dt * math.rad(70)
	local pulso = (math.sin(agora * 10) + 1) / 2
	local chao = CFrame.new(pivot.Position + Vector3.new(0, 0.15, 0))
	moverCirculo(p, chao, 1 - rig.brilho * (0.55 + pulso * 0.3), nil, pecas, cframes)
end

-- Pose -------------------------------------------------------------------------

local function animar(rig: Rig, dt: number, agora: number)
	local modelo = rig.modelo
	local pivot = modelo:GetPivot()
	local posicao = pivot.Position

	-- velocidade (suavizada) a partir de quanto o servidor andou com ele
	local v = 0
	if rig.ultima and dt > 0 then
		local d = posicao - rig.ultima
		v = Vector3.new(d.X, 0, d.Z).Magnitude / dt
	end
	rig.ultima = posicao
	v = math.min(v, 200)
	rig.velocidade += (v - rig.velocidade) * math.min(1, dt * 6)
	local altura = rig.altura
	local passada = altura * (if rig.quadrupede then 0.32 else 0.42)
	rig.fase += dt * rig.velocidade / passada * math.pi
	local anda = math.clamp(rig.velocidade / (altura * 0.3), 0, 1)
	local s = math.sin(rig.fase)

	-- acordou (ficou bravo): ruge
	local bravo = modelo:GetAttribute("Bravo") == true
	if bravo and not rig.bravo then
		rig.rugidoEm = agora
		rugidoVfx(rig, pivot)
	end
	rig.bravo = bravo
	local tRugido = (agora - rig.rugidoEm) / TEMPO_RUGIDO
	local rugido = if tRugido < 1 then math.sin(tRugido * math.pi) * (1 - anda * 0.7) else 0
	local tremido = rugido * math.noise(agora * 30, 5) * math.rad(4)

	-- pegou alguém: golpe
	local ataque = modelo:GetAttribute("Ataque") or 0
	if ataque ~= rig.golpeVisto then
		rig.golpeVisto = ataque
		rig.golpeEm = agora
	end
	local tGolpe = (agora - rig.golpeEm) / TEMPO_GOLPE
	local golpe = tGolpe >= 0 and tGolpe < 1
	-- a batida no chão (onda, poeira, tremor) sai no meio do golpe
	if golpe and tGolpe >= 0.42 and not rig.golpeFeito then
		rig.golpeFeito = true
		golpeVfx(rig, pivot)
	elseif not golpe then
		rig.golpeFeito = false
	end

	-- passo: o pé encosta no chão quando o seno passa pelo zero
	local sinal = if s >= 0 then 1 else -1
	if sinal ~= rig.ultimoSinal then
		rig.ultimoSinal = sinal
		if anda > 0.35 then
			for _, f in aoPisar do
				task.spawn(f, modelo, posicao, anda)
			end
		end
	end

	-- corpo: sobe e desce a cada passo, respira parado, inclina para a frente
	-- correndo (mais ainda bravo), para trás no rugido, e balança de lado
	local respira = math.sin(agora * 2.2) * altura * 0.008 * (1 - anda)
	local pulo = math.abs(s) * altura * (if rig.quadrupede then 0.025 else 0.04) * anda
	local inclina = -math.rad(if bravo then 9 else 5) * anda + math.rad(12) * rugido
	local balanco = s * math.rad(if rig.temBracos then 3 else 8) * anda + tremido
	if golpe then
		local g = curvaGolpe(tGolpe, 1, -1)
		inclina += math.rad(if rig.quadrupede then 20 else 9) * g
	end
	local sobe = CFrame.new(0, pulo + respira, 0)
	local quadril = CFrame.new(0, rig.quadril, 0)
	local troncoCF = sobe * quadril * CFrame.Angles(inclina, 0, balanco) * quadril:Inverse()

	local pecas, cframes = rig.pecas, rig.cframes
	table.clear(pecas)
	table.clear(cframes)
	for i, parte in rig.tronco do
		table.insert(pecas, parte)
		table.insert(cframes, pivot * troncoCF * rig.descansoTronco[i])
	end

	for _, m in rig.membros do
		local giro: CFrame
		local pai = troncoCF
		if m.nome == "Anel" then
			local rapido = if bravo then 220 else 55
			rig.giroAnel += dt * math.rad(rapido)
			giro = CFrame.Angles(math.sin(agora * 1.3) * math.rad(7), rig.giroAnel, math.cos(agora * 1.1) * math.rad(7))
		elseif m.perna then
			pai = sobe -- as pernas não inclinam com o tronco
			local amplitude = math.rad(if rig.quadrupede then 30 else 34)
			local angulo = s * m.fase * amplitude * anda
			if golpe and rig.quadrupede and m.nome:match("^PernaF") then
				-- empina: as patas da frente sobem e batem no chão
				angulo += math.rad(35) * curvaGolpe(tGolpe, 1, -0.3)
			end
			giro = CFrame.Angles(angulo, 0, 0)
		else
			-- braço: balança ao contrário da perna do mesmo lado
			local angulo = -s * m.fase * math.rad(26) * anda
			local abre = 0
			if bravo then
				-- bravo: agita os braços (o taco, as espadas)
				angulo += math.sin(agora * 8 + m.lado) * math.rad(if m.maoAcima then 22 else 30) * (0.4 + anda * 0.6)
			else
				angulo += math.sin(agora * 1.6 + m.lado) * math.rad(4) * (1 - anda)
			end
			-- rugido: abre os braços
			abre = m.lado * math.rad(55) * rugido + m.lado * tremido * 3
			if golpe then
				if m.maoAcima then
					angulo += math.rad(curvaGolpe(tGolpe, 50, -95))
				else
					angulo += math.rad(curvaGolpe(tGolpe, 150, 40))
				end
			end
			giro = CFrame.Angles(angulo, 0, abre)
		end
		table.insert(pecas, m.parte)
		table.insert(cframes, pivot * pai * m.junta * giro * m.junta:Inverse() * m.descanso)
	end
	circulos(rig, dt, agora, pivot, bravo, pecas, cframes)
	Workspace:BulkMoveTo(pecas, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

-- Liga ------------------------------------------------------------------------

-- Quem quiser saber quando o pé de um chefe bate no chão (som, poeira, tremor).
function ChefesAnimacao.aoPisar(funcao: (Model, Vector3, number) -> ())
	table.insert(aoPisar, funcao)
end

-- true se este chefe é animado aqui (os passos vêm de aoPisar)
function ChefesAnimacao.animado(modelo: Model): boolean
	return rigs[modelo] ~= nil and rigs[modelo] ~= false
end

function ChefesAnimacao.iniciar()
	CollectionService:GetInstanceRemovedSignal("Guardiao"):Connect(function(modelo)
		local rig = rigs[modelo :: Model]
		if rig then
			destruirCirculo(rig.casa)
			destruirCirculo(rig.perigo)
		end
		rigs[modelo :: Model] = nil
	end)
	RunService.RenderStepped:Connect(function(dt)
		local camera = Workspace.CurrentCamera
		local olho = if camera then camera.CFrame.Position else Vector3.zero
		local agora = os.clock()
		for _, modelo in CollectionService:GetTagged("Guardiao") do
			if modelo:IsA("Model") and modelo:IsDescendantOf(Workspace) then
				local rig = rigs[modelo]
				if rig == nil then
					local novo = montar(modelo)
					if novo == nil then
						continue
					end
					rigs[modelo] = novo
					rig = novo
				end
				if rig and (modelo:GetPivot().Position - olho).Magnitude < LONGE then
					animar(rig, dt, agora)
				elseif rig then
					rig.ultima = nil
				end
			end
		end
	end)
end

return ChefesAnimacao

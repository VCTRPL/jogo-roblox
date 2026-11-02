-- Esteira em modo turbo, só neste computador: quando alguém corre numa
-- esteira, as partículas dela ficam mais fortes, anéis de velocidade passam
-- pela pista, a luz acende e um anel brilhante gira em volta de quem corre.
-- Sem ninguém correndo, a esteira "respira" devagar. As esteiras são achadas
-- pelo nome ("Esteira" com uma "Pista" dentro).
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Tremor = require(script.Parent.Tremor)

local EsteiraVfx = {}

local BRANCO = Color3.new(1, 1, 1)
local ALCANCE = 160

type Esteira = {
	modelo: Model,
	pista: BasePart,
	cor: Color3,
	taxas: { [ParticleEmitter]: number }, -- Rate original de cada emissor
	luz: PointLight,
	turbo: boolean,
	proximoAnel: number,
	corredor: BasePart?, -- raiz de quem está correndo
	anelCorredor: BasePart?,
}

local esteiras: { [Model]: Esteira } = {}
local pasta = Instance.new("Folder")
pasta.Name = "EsteiraVfx"
pasta.Parent = Workspace

local function peca(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for chave, valor in props do
		(p :: any)[chave] = valor
	end
	p.Parent = pasta
	return p
end

-- a cor do nível: a das faixas de neon da esteira (ou branco na Básica)
local function corDa(modelo: Model): Color3
	for _, parte in modelo:GetDescendants() do
		if parte:IsA("BasePart") and parte.Material == Enum.Material.Neon and parte.Name ~= "Faixa" then
			return parte.Color
		end
	end
	return Color3.fromRGB(235, 235, 240)
end

local function esquecer(modelo: Model)
	local e = esteiras[modelo]
	if not e then
		return
	end
	esteiras[modelo] = nil
	e.luz:Destroy()
	if e.anelCorredor then
		e.anelCorredor:Destroy()
	end
end

local function considerar(objeto: Instance)
	-- com streaming, a pista pode chegar bem depois do modelo
	if objeto.Name == "Pista" and objeto.Parent and objeto.Parent.Name == "Esteira" then
		objeto = objeto.Parent
	end
	if not objeto:IsA("Model") or objeto.Name ~= "Esteira" or esteiras[objeto] then
		return
	end
	task.delay(1, function()
		-- espera as peças chegarem do servidor
		local pista = objeto:FindFirstChild("Pista")
		if not objeto.Parent or not pista or not pista:IsA("BasePart") or esteiras[objeto] then
			return
		end
		local luz = Instance.new("PointLight")
		luz.Name = "VfxTurbo"
		luz.Range = 16
		luz.Brightness = 0
		luz.Parent = pista
		local e: Esteira = {
			modelo = objeto,
			pista = pista,
			cor = corDa(objeto),
			taxas = {},
			luz = luz,
			turbo = false,
			proximoAnel = 0,
			corredor = nil,
			anelCorredor = nil,
		}
		luz.Color = e.cor
		for _, em in objeto:GetDescendants() do
			if em:IsA("ParticleEmitter") then
				e.taxas[em] = em.Rate
			end
		end
		esteiras[objeto] = e
		objeto.Destroying:Once(function()
			esquecer(objeto)
		end)
		objeto.AncestryChanged:Connect(function(_, pai)
			if not pai then
				esquecer(objeto)
			end
		end)
	end)
end

local function ligarTurbo(e: Esteira, ligado: boolean)
	if e.turbo == ligado then
		return
	end
	e.turbo = ligado
	for em, taxa in e.taxas do
		if em.Parent then
			em.Rate = if ligado then taxa * 2.5 else taxa
		end
	end
	TweenService:Create(e.luz, TweenInfo.new(0.4), { Brightness = if ligado then 3 else 0 }):Play()
	if ligado then
		e.anelCorredor = peca({
			Name = "AnelCorredor",
			Shape = Enum.PartType.Cylinder,
			Color = e.cor:Lerp(BRANCO, 0.3),
			Transparency = 0.35,
			Size = Vector3.new(0.12, 4.5, 4.5),
		})
	elseif e.anelCorredor then
		e.anelCorredor:Destroy()
		e.anelCorredor = nil
	end
end

-- Anel de velocidade: nasce na frente da pista e corre para trás, abrindo.
local function anelVelocidade(e: Esteira)
	local pista = e.pista
	local frente = pista.CFrame * CFrame.new(0, 2.6, -pista.Size.Z / 2)
	local tras = pista.CFrame * CFrame.new(0, 2.6, pista.Size.Z / 2 + 3)
	local anel = peca({
		Name = "AnelVelocidade",
		Shape = Enum.PartType.Cylinder,
		Color = e.cor:Lerp(BRANCO, 0.25),
		Transparency = 0.25,
		Size = Vector3.new(0.15, 3, 3),
		-- o cilindro tem o eixo em X: gira para ficar ao longo da pista (Z)
		CFrame = frente * CFrame.Angles(0, math.rad(90), 0),
	})
	TweenService:Create(anel, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = tras * CFrame.Angles(0, math.rad(90), 0),
		Size = Vector3.new(0.05, 6.5, 6.5),
		Transparency = 1,
	}):Play()
	Debris:AddItem(anel, 0.5)
end

-- Quem está correndo numa esteira agora: { [Model] = raiz }
local function corredores(): { [Model]: BasePart }
	local lista = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("NaEsteira") then
			local personagem = player.Character
			local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
			if raiz and raiz:IsA("BasePart") then
				for modelo, e in esteiras do
					local ponto = e.pista.CFrame:PointToObjectSpace(raiz.Position)
					if math.abs(ponto.X) < 4 and math.abs(ponto.Z) < e.pista.Size.Z / 2 + 2 and ponto.Y > -1 and ponto.Y < 8 then
						lista[modelo] = raiz
					end
				end
			end
		end
	end
	return lista
end

function EsteiraVfx.iniciar()
	Workspace.DescendantAdded:Connect(considerar)
	task.spawn(function()
		for i, objeto in Workspace:GetDescendants() do
			considerar(objeto)
			if i % 4000 == 0 then
				task.wait()
			end
		end
	end)

	-- quem está correndo (quatro vezes por segundo basta)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local camera = Workspace.CurrentCamera
			local olho = if camera then camera.CFrame.Position else Vector3.zero
			local agora = corredores()
			for modelo, e in esteiras do
				if not e.pista.Parent then
					esquecer(modelo) -- a pista saiu do streaming; volta quando chegar de novo
					continue
				end
				local raiz = agora[modelo]
				e.corredor = raiz
				ligarTurbo(e, raiz ~= nil and (e.pista.Position - olho).Magnitude < ALCANCE)
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		local agora = os.clock()
		for _, e in esteiras do
			if e.turbo then
				if agora >= e.proximoAnel then
					e.proximoAnel = agora + (if Tremor.celular then 0.4 else 0.22)
					anelVelocidade(e)
				end
				local raiz = e.corredor
				local anel = e.anelCorredor
				if raiz and anel then
					-- anel deitado girando na cintura de quem corre
					anel.CFrame = CFrame.new(raiz.Position + Vector3.new(0, math.sin(agora * 6) * 0.8 - 0.5, 0))
						* CFrame.Angles(0, agora * 4, math.rad(90))
					anel.Transparency = 0.35 + (math.sin(agora * 10) + 1) * 0.15
				end
				e.luz.Brightness = 2.5 + math.sin(agora * 12) * 0.8
			end
		end
	end)
end

return EsteiraVfx

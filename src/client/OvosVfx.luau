-- Efeitos dos ovos, só neste computador:
--  * no ninho: o ovo flutua e gira em cima de um quadrado de luz na cor da
--    raridade, com cubinhos em órbita (mais quanto mais raro), brilhos
--    subindo (Épico e acima), luz (Lendário e acima) e raios (Mítico e Secreto);
--  * na base: barra de tempo até chocar, e perto do fim o ovo treme cada vez
--    mais e aparecem rachaduras brilhando;
--  * quem carrega um ovo deixa um rastro na cor da raridade.
-- O servidor marca os ovos com a tag "Ovo" (e "OvoChocando" nos da base).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local OvosVfx = {}

local FAISCA = "rbxasset://textures/particles/sparkles_main.dds"
local DISTANCIA = 180 -- longe disso não anima (ninguém vê)
local BRANCO = Color3.new(1, 1, 1)

type Ovo = {
	modelo: Model,
	inicio: CFrame, -- onde o servidor pôs o ovo
	altura: number,
	cor: Color3,
	nivel: number, -- 1 = Comum ... 6 = Secreto
	fase: number, -- para os ovos não balançarem todos juntos
	pecas: { Instance }, -- tudo que este módulo criou (some junto com o ovo)
	aura: { { parte: BasePart, offset: CFrame } },
	orbitas: { BasePart },
	centro: BasePart?, -- peça invisível no meio do ovo (partículas e luz)
	barra: Frame?,
	rachou: boolean,
	proximoRaio: number,
}

local ovos: { [Model]: Ovo } = {}
local pasta = Instance.new("Folder")
pasta.Name = "OvosVfx"
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
	if not p.Parent then
		p.Parent = pasta
	end
	return p
end

-- Tamanho do ovo sem a coluna de luz dos raros (que tem 60 de altura).
local function tamanhoDo(modelo: Model): Vector3
	local menor = Vector3.one * math.huge
	local maior = -Vector3.one * math.huge
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "ColunaDeLuz" and p.Name ~= "Rachadura" then
			local meio = p.Size / 2
			menor = menor:Min(p.Position - meio)
			maior = maior:Max(p.Position + meio)
		end
	end
	if menor.X > maior.X then
		return Vector3.one
	end
	return maior - menor
end

local function chocando(ovo: Ovo): number?
	local chocaEm = ovo.modelo:GetAttribute("ChocaEm")
	local duracao = ovo.modelo:GetAttribute("Duracao")
	if typeof(chocaEm) ~= "number" or typeof(duracao) ~= "number" or duracao <= 0 then
		return nil
	end
	return math.clamp(1 - (chocaEm - Workspace:GetServerTimeNow()) / duracao, 0, 1)
end

-- Barra de tempo em cima do ovo da base.
local function criarBarra(ovo: Ovo, primaria: BasePart)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BarraChocar"
	gui.Size = UDim2.fromScale(3, 0.4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, ovo.inicio.Position.Y + ovo.altura - primaria.Position.Y + 0.6, 0)
	gui.MaxDistance = 70
	gui.Parent = primaria
	local fundo = Instance.new("Frame")
	fundo.Size = UDim2.fromScale(1, 1)
	fundo.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
	fundo.Parent = gui
	local canto = Instance.new("UICorner")
	canto.CornerRadius = UDim.new(0.5, 0)
	canto.Parent = fundo
	local enchimento = Instance.new("Frame")
	enchimento.Size = UDim2.fromScale(0, 1)
	enchimento.BackgroundColor3 = ovo.cor
	enchimento.Parent = fundo
	canto:Clone().Parent = enchimento
	table.insert(ovo.pecas, gui)
	ovo.barra = enchimento
end

-- Rachaduras brilhando nos quatro lados do ovo (andam junto com ele).
local function rachar(ovo: Ovo)
	ovo.rachou = true
	local tamanho = tamanhoDo(ovo.modelo)
	local pivot = ovo.modelo:GetPivot()
	local meio = math.max(tamanho.X, tamanho.Z) / 2
	for lado = 0, 3 do
		local giro = CFrame.Angles(0, lado * math.pi / 2, 0)
		local y = tamanho.Y * 0.55
		for i = 0, 2 do
			-- zigue-zague
			local inclinacao = if i % 2 == 0 then 35 else -35
			table.insert(
				ovo.pecas,
				peca({
					Name = "Rachadura",
					Color = ovo.cor:Lerp(BRANCO, 0.4),
					Size = Vector3.new(0.08, tamanho.Y * 0.16, 0.06),
					CFrame = pivot
						* CFrame.new(0, y - i * tamanho.Y * 0.11, 0)
						* giro
						* CFrame.new((i - 1) * 0.12, 0, -meio * 0.82)
						* CFrame.Angles(0, 0, math.rad(inclinacao)),
					Parent = ovo.modelo,
				})
			)
		end
	end
end

-- Raio rápido entre o ovo e um ponto em volta (Mítico e Secreto).
local function raio(ovo: Ovo, centro: Vector3)
	local angulo = math.random() * math.pi * 2
	local ate = centro + Vector3.new(math.cos(angulo) * 3, math.random() * 2 - 0.5, math.sin(angulo) * 3)
	-- dois trechos com uma dobra no meio, para parecer um raio
	local dobra = centro:Lerp(ate, 0.5) + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 0.8
	for _, trecho in { { centro, dobra }, { dobra, ate } } do
		local a, b = trecho[1], trecho[2]
		local p = peca({
			Name = "Raio",
			Color = ovo.cor:Lerp(BRANCO, 0.5),
			Size = Vector3.new(0.12, 0.12, (b - a).Magnitude),
			CFrame = CFrame.lookAt((a + b) / 2, b),
		})
		task.delay(0.12, p.Destroy, p)
	end
end

local function esquecer(modelo: Model)
	local ovo = ovos[modelo]
	if not ovo then
		return
	end
	ovos[modelo] = nil
	for _, objeto in ovo.pecas do
		objeto:Destroy()
	end
end

local function montar(modelo: Instance, tentativa: number?)
	if not modelo:IsA("Model") or ovos[modelo] or not modelo.Parent then
		return
	end
	local mapa = Workspace:FindFirstChild("Mapa")
	-- ovo carregado na cabeça de alguém: só o rastro (veja abaixo)
	if not mapa or not modelo:IsDescendantOf(mapa) then
		return
	end
	local primaria = modelo.PrimaryPart
	if not primaria then
		-- as peças ainda estão chegando do servidor
		if (tentativa or 0) < 10 then
			task.delay(0.5, montar, modelo, (tentativa or 0) + 1)
		end
		return
	end

	local raridade = modelo:GetAttribute("Raridade") or "Comum"
	local tamanho = tamanhoDo(modelo)
	local ovo: Ovo = {
		modelo = modelo,
		inicio = modelo:GetPivot(),
		altura = tamanho.Y,
		cor = Config.CORES_RARIDADE[raridade] or BRANCO,
		nivel = Config.nivelRaridade(raridade),
		fase = math.random() * math.pi * 2,
		pecas = {},
		aura = {},
		orbitas = {},
		centro = nil,
		barra = nil,
		rachou = false,
		proximoRaio = os.clock() + math.random() * 2,
	}
	ovos[modelo] = ovo
	local base = ovo.inicio.Position
	local raioAura = math.max(tamanho.X, tamanho.Z) * 0.75 + 0.6

	-- quadrado de luz no chão (estilo Lego), girando devagar
	for lado = 0, 3 do
		local offset = CFrame.Angles(0, lado * math.pi / 2, 0) * CFrame.new(0, 0, -raioAura)
		local barra = peca({ Name = "Aura", Color = ovo.cor, Transparency = 0.25, Size = Vector3.new(raioAura * 2 + 0.25, 0.12, 0.25) })
		table.insert(ovo.aura, { parte = barra, offset = offset })
		table.insert(ovo.pecas, barra)
	end

	-- cubinhos em órbita, um a mais por raridade
	for _ = 2, ovo.nivel do
		local cubo = peca({ Name = "Orbita", Color = ovo.cor:Lerp(BRANCO, 0.3), Size = Vector3.one * 0.35 })
		table.insert(ovo.orbitas, cubo)
		table.insert(ovo.pecas, cubo)
	end

	if ovo.nivel >= 3 then
		local centro = peca({ Name = "CentroOvo", Transparency = 1, Size = Vector3.one, Position = base + Vector3.new(0, tamanho.Y / 2, 0) })
		ovo.centro = centro
		table.insert(ovo.pecas, centro)
		local brilho = Instance.new("ParticleEmitter")
		brilho.Texture = FAISCA
		brilho.Color = ColorSequence.new(ovo.cor, BRANCO)
		brilho.LightEmission = 1
		brilho.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		brilho.Lifetime = NumberRange.new(1, 1.8)
		brilho.Speed = NumberRange.new(1.5, 3)
		brilho.SpreadAngle = Vector2.new(25, 25)
		brilho.Rate = ovo.nivel * 3
		brilho.Shape = Enum.ParticleEmitterShape.Box
		brilho.Parent = centro
		if ovo.nivel >= 4 then
			local luz = Instance.new("PointLight")
			luz.Color = ovo.cor
			luz.Range = 8 + ovo.nivel
			luz.Brightness = 1.2
			luz.Parent = centro
		end
	end

	if CollectionService:HasTag(modelo, "OvoChocando") then
		criarBarra(ovo, primaria)
	end
end

-- Rastro de quem carrega um ovo ---------------------------------------------

local rastros: { [Player]: { Instance } } = {}

local function atualizarRastro(player: Player)
	local antigos = rastros[player]
	if antigos then
		for _, objeto in antigos do
			objeto:Destroy()
		end
		rastros[player] = nil
	end
	local cor = player:GetAttribute("CorCarregando")
	local personagem = player.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
	if not player:GetAttribute("Carregando") or typeof(cor) ~= "Color3" or not raiz then
		return
	end
	local cima = Instance.new("Attachment")
	cima.Name = "RastroOvoCima"
	cima.Position = Vector3.new(0, 0.9, 0.5)
	cima.Parent = raiz
	local baixo = Instance.new("Attachment")
	baixo.Name = "RastroOvoBaixo"
	baixo.Position = Vector3.new(0, -0.9, 0.5)
	baixo.Parent = raiz
	local rastro = Instance.new("Trail")
	rastro.Attachment0 = cima
	rastro.Attachment1 = baixo
	rastro.Color = ColorSequence.new(cor, BRANCO)
	rastro.Transparency = NumberSequence.new(0.25, 1)
	rastro.Lifetime = 0.45
	rastro.LightEmission = 0.8
	rastro.FaceCamera = true
	rastro.Parent = raiz
	rastros[player] = { cima, baixo, rastro }
end

local function acompanhar(player: Player)
	player:GetAttributeChangedSignal("Carregando"):Connect(function()
		atualizarRastro(player)
	end)
	player.CharacterAdded:Connect(function()
		rastros[player] = nil -- sumiu com o personagem antigo
	end)
	atualizarRastro(player)
end

-- Animação ---------------------------------------------------------------------

local function animar()
	local agora = os.clock()
	local camera = Workspace.CurrentCamera
	local olho = if camera then camera.CFrame.Position else Vector3.zero
	for modelo, ovo in ovos do
		if not modelo.Parent then
			esquecer(modelo)
			continue
		end
		local base = ovo.inicio.Position
		if (olho - base).Magnitude > DISTANCIA then
			continue
		end

		local pivot = ovo.inicio
		if modelo:GetAttribute("NoNinho") then
			-- flutua e gira em cima do ninho
			pivot = ovo.inicio
				* CFrame.new(0, 0.5 + math.sin(agora * 2 + ovo.fase) * 0.35, 0)
				* CFrame.Angles(0, agora * 0.9 + ovo.fase, 0)
		else
			local progresso = chocando(ovo)
			if progresso then
				if ovo.barra then
					ovo.barra.Size = UDim2.fromScale(progresso, 1)
					ovo.barra.BackgroundColor3 = ovo.cor:Lerp(Color3.fromRGB(120, 255, 120), progresso)
				end
				-- treme cada vez mais perto de chocar, com uns trancos de vez em quando
				local forca = math.clamp((progresso - 0.6) / 0.4, 0, 1)
				if math.sin(agora * 3 + ovo.fase) > 0.85 then
					forca *= 2
				end
				pivot = ovo.inicio
					* CFrame.Angles(math.sin(agora * 21 + ovo.fase) * 0.08 * forca, 0, math.sin(agora * 25) * 0.12 * forca)
				if progresso >= 0.75 and not ovo.rachou then
					rachar(ovo)
				end
			end
		end
		modelo:PivotTo(pivot)

		-- aura no chão e cubinhos em volta do meio do ovo
		local giroAura = CFrame.new(base + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, agora * 0.6, 0)
		for _, item in ovo.aura do
			item.parte.CFrame = giroAura * item.offset
		end
		local meio = pivot.Position + Vector3.new(0, ovo.altura / 2, 0)
		local quantos = #ovo.orbitas
		for i, cubo in ovo.orbitas do
			local angulo = agora * 1.8 + i / quantos * math.pi * 2
			local raioOrbita = 1.6 + ovo.altura * 0.25
			cubo.CFrame = CFrame.new(meio + Vector3.new(math.cos(angulo) * raioOrbita, math.sin(agora * 3 + i) * 0.5, math.sin(angulo) * raioOrbita))
				* CFrame.Angles(agora * 2, agora * 3, 0)
		end
		if ovo.centro then
			ovo.centro.Position = meio
		end
		if ovo.nivel >= 5 and agora >= ovo.proximoRaio then
			ovo.proximoRaio = agora + 0.8 + math.random() * 1.8
			raio(ovo, meio)
		end
	end
end

function OvosVfx.iniciar()
	CollectionService:GetInstanceAddedSignal("Ovo"):Connect(function(modelo)
		-- espera as peças chegarem (o modelo vem do servidor)
		task.defer(montar, modelo)
	end)
	CollectionService:GetInstanceRemovedSignal("Ovo"):Connect(function(modelo)
		if modelo:IsA("Model") then
			esquecer(modelo)
		end
	end)
	for _, modelo in CollectionService:GetTagged("Ovo") do
		task.spawn(montar, modelo)
	end

	Players.PlayerAdded:Connect(acompanhar)
	for _, player in Players:GetPlayers() do
		acompanhar(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		rastros[player] = nil
	end)

	RunService.RenderStepped:Connect(animar)
end

return OvosVfx

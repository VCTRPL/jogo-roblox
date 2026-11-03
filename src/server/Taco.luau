-- Taco de beisebol: todo jogador nasce com um. A tacada empurra e deixa tonto
-- quem estiver na frente; quem estava carregando um ovo ou Brainrot deixa cair
-- (volta para o ninho ou para a base de onde foi roubado). É a defesa contra
-- quem tenta roubar a sua base.
-- O modelo 3D é o ServerStorage.ModeloTaco (um taco grátis da Creator Store,
-- só as malhas, sem scripts); sem ele, o taco é montado com blocos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Bases = require(script.Parent.Bases)
local Carregar = require(script.Parent.Carregar)
local Velocidade = require(script.Parent.Velocidade)

local Taco = {}

local NOME = "Taco"
local AMARELO = Color3.fromRGB(255, 215, 80)

local ultimaTacada: { [Player]: number } = {}

local function blocoDeTaco(): { BasePart }
	local function peca(nome, tamanho, y, cor, material)
		local p = Instance.new("Part")
		p.Name = nome
		p.Size = tamanho
		p.CFrame = CFrame.new(0, y, 0)
		p.Color = cor
		p.Material = material
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		return p
	end
	local madeira = Color3.fromRGB(190, 140, 90)
	return {
		peca("Handle", Vector3.new(0.3, 1.4, 0.3), -1.5, Color3.fromRGB(40, 40, 45), Enum.Material.Fabric),
		peca("Corpo", Vector3.new(0.4, 1.6, 0.4), 0, madeira, Enum.Material.Wood),
		peca("Ponta", Vector3.new(0.55, 1.8, 0.55), 1.6, madeira, Enum.Material.Wood),
	}
end

local function criarFerramenta(): Tool
	local ferramenta = Instance.new("Tool")
	ferramenta.Name = NOME
	ferramenta.ToolTip = "Bata em quem tenta roubar você!"
	ferramenta.CanBeDropped = false
	ferramenta:SetAttribute("Taco", true)

	local molde = ServerStorage:FindFirstChild("ModeloTaco")
	local pecas: { BasePart } = {}
	if molde then
		for _, objeto in molde:Clone():GetChildren() do
			if objeto:IsA("BasePart") then
				table.insert(pecas, objeto)
			end
		end
	else
		pecas = blocoDeTaco()
	end
	local handle: BasePart? = nil
	for _, parte in pecas do
		if parte.Name == "Handle" then
			handle = parte
		end
	end
	assert(handle, "o taco precisa de uma peça Handle")
	for _, parte in pecas do
		parte.Anchored = false
		parte.CanCollide = false
		parte.CanQuery = false
		parte.CanTouch = false
		parte.Massless = true
		for _, solda in parte:GetChildren() do
			if solda:IsA("JointInstance") then
				solda:Destroy()
			end
		end
		if parte ~= handle then
			local solda = Instance.new("WeldConstraint")
			solda.Part0 = handle
			solda.Part1 = parte
			solda.Parent = parte
		end
		parte.Parent = ferramenta
	end
	-- segura pelo cabo, com o taco apontando para cima e um pouco para frente
	ferramenta.Grip = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(-15), 0, 0)
	return ferramenta
end

local function bater(player: Player, ferramenta: Tool)
	local agora = os.clock()
	if agora - (ultimaTacada[player] or 0) < Config.TACO.recarga then
		return
	end
	ultimaTacada[player] = agora
	local personagem = player.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = personagem and personagem:FindFirstChildOfClass("Humanoid")
	if not raiz or not hum or hum.Health <= 0 or ferramenta.Parent ~= personagem then
		return
	end

	-- o Animate padrão do Roblox toca o golpe quando aparece este valor
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = ferramenta
	Avisos.som(nil, "Tacada", raiz.Position)

	local frente = raiz.CFrame.LookVector
	for _, outro in Players:GetPlayers() do
		local alvo = outro.Character
		local raizAlvo = alvo and alvo:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humAlvo = alvo and alvo:FindFirstChildOfClass("Humanoid")
		if outro ~= player and raizAlvo and humAlvo and humAlvo.Health > 0 then
			local diferenca = raizAlvo.Position - raiz.Position
			local plano = Vector3.new(diferenca.X, 0, diferenca.Z)
			local naFrente = plano.Magnitude < 0.5 or plano.Unit:Dot(frente) > 0.2
			if diferenca.Magnitude <= Config.TACO.alcance and naFrente and math.abs(diferenca.Y) < 6 then
				-- quem está correndo na esteira cai dela
				Bases.sairDaEsteira(outro)
				if Carregar.estaCarregando(outro) then
					Carregar.derrubar(outro, `{player.DisplayName} te deu uma tacada e você deixou cair!`)
					Avisos.enviar(player, `Você derrubou {outro.DisplayName}!`, AMARELO)
				else
					Velocidade.atordoar(outro, Config.TACO.tonto)
					Avisos.efeito("Derrubado", { posicao = raizAlvo.Position })
				end
				-- o empurrão é feito no computador de quem apanhou (é ele que move o próprio personagem)
				local direcao = if plano.Magnitude > 0.5 then plano.Unit else frente
				Avisos.efeitoPara(outro, "Tacada", { direcao = direcao, forca = Config.TACO.empurrao, tempo = Config.TACO.tonto })
				Avisos.som(nil, "Acertou", raizAlvo.Position)
			end
		end
	end
	task.delay(0.5, anim.Destroy, anim)
end

local function darTaco(player: Player)
	local mochila = player:WaitForChild("Backpack")
	local personagem = player.Character
	if mochila:FindFirstChild(NOME) or (personagem and personagem:FindFirstChild(NOME)) then
		return
	end
	local ferramenta = criarFerramenta()
	ferramenta.Activated:Connect(function()
		bater(player, ferramenta)
	end)
	ferramenta.Parent = mochila
end

function Taco.iniciar()
	local function aoEntrar(player: Player)
		player.CharacterAdded:Connect(function()
			darTaco(player)
		end)
		if player.Character then
			task.spawn(darTaco, player)
		end
	end
	Players.PlayerAdded:Connect(aoEntrar)
	for _, player in Players:GetPlayers() do
		aoEntrar(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		ultimaTacada[player] = nil
	end)
end

return Taco

-- Script do cliente: mostra os avisos na tela, esconde o botão
-- "Roubar" dos seus próprios Verities e anima as esteiras.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local jogador = Players.LocalPlayer
local eventoAviso = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Aviso") :: RemoteEvent

-- Avisos -----------------------------------------------------------------

local tela = Instance.new("ScreenGui")
tela.Name = "Avisos"
tela.ResetOnSpawn = false
tela.Parent = jogador:WaitForChild("PlayerGui")

local texto = Instance.new("TextLabel")
texto.AnchorPoint = Vector2.new(0.5, 0)
texto.Position = UDim2.new(0.5, 0, 0.12, 0)
texto.Size = UDim2.new(0.6, 0, 0, 40)
texto.BackgroundTransparency = 1
texto.TextScaled = true
texto.Font = Enum.Font.FredokaOne
texto.TextTransparency = 1
texto.TextStrokeTransparency = 1
texto.Parent = tela

local ultimoAviso = 0
eventoAviso.OnClientEvent:Connect(function(mensagem: string, cor: Color3)
	ultimoAviso += 1
	local esteAviso = ultimoAviso
	texto.Text = mensagem
	texto.TextColor3 = cor
	texto.TextTransparency = 0
	texto.TextStrokeTransparency = 0
	task.delay(3, function()
		if esteAviso == ultimoAviso then
			TweenService:Create(texto, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end)

-- Esconde "Roubar" nos Verities da sua própria base -----------------------

local function verificarPrompt(objeto: Instance)
	if objeto:IsA("ProximityPrompt") and objeto:GetAttribute("DonoId") == jogador.UserId then
		-- Mudança só no seu computador: os outros jogadores continuam vendo o botão.
		objeto.MaxActivationDistance = 0
	end
end

Workspace.DescendantAdded:Connect(verificarPrompt)
for _, objeto in Workspace:GetDescendants() do
	verificarPrompt(objeto)
end

-- Anima as esteiras ---------------------------------------------------------
-- As faixas andam pela pista e o que tem a tag "GirarEsteira" gira. Só neste
-- computador: o servidor não precisa mandar nada.

local inicios: { [BasePart]: CFrame } = {}

local function esquecer(parte: Instance)
	inicios[parte :: BasePart] = nil
end
CollectionService:GetInstanceRemovedSignal("FaixaEsteira"):Connect(esquecer)
CollectionService:GetInstanceRemovedSignal("GirarEsteira"):Connect(esquecer)

RunService.RenderStepped:Connect(function()
	local agora = os.clock()
	for _, faixa in CollectionService:GetTagged("FaixaEsteira") do
		if faixa:IsA("BasePart") and faixa:IsDescendantOf(Workspace) then
			local fase = faixa:GetAttribute("Fase") or 0
			local inicio = inicios[faixa]
			if not inicio then
				inicio = faixa.CFrame * CFrame.new(0, 0, -fase)
				inicios[faixa] = inicio
			end
			local andou = (fase + agora * (faixa:GetAttribute("Velocidade") or 10)) % (faixa:GetAttribute("Curso") or 10)
			faixa.CFrame = inicio * CFrame.new(0, 0, andou)
		end
	end
	for _, parte in CollectionService:GetTagged("GirarEsteira") do
		if parte:IsA("BasePart") and parte:IsDescendantOf(Workspace) then
			local inicio = inicios[parte]
			if not inicio then
				inicio = parte.CFrame
				inicios[parte] = inicio
			end
			local giro = CFrame.Angles(0, math.rad(agora * (parte:GetAttribute("Giro") or 45)), 0)
			parte.CFrame = (giro * inicio.Rotation) + inicio.Position + Vector3.new(0, math.sin(agora * 2) * 0.3, 0)
		end
	end
end)

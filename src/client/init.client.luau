-- Script do cliente: mostra os avisos na tela e esconde o botão
-- "Roubar" dos seus próprios Verities.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

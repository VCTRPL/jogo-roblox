-- Script do cliente: mostra os avisos na tela e esconde o botão
-- "Roubar" dos seus próprios Verities.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local jogador = Players.LocalPlayer

-- Tela (dinheiro, avisos e anúncios) e efeitos visuais -------------------

require(script.Hud).iniciar()
require(script.Efeitos).iniciar()

-- Esconde "Roubar" nos Brainrots da sua própria base ----------------------

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

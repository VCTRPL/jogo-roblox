-- Script do cliente: mostra os avisos na tela, esconde o botão
-- "Roubar" dos seus próprios Verities e anima as esteiras.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local jogador = Players.LocalPlayer

-- Tela (dinheiro, avisos, anúncios, barra do próximo bioma, Índice e Ajuda)
-- e efeitos visuais (ovo chocando e corrida na esteira) ---------------------

require(script.Hud).iniciar()
require(script.Efeitos).iniciar()
require(script.Interface).iniciar()
require(script.Corrida).iniciar()
local Prompts = require(script.Prompts)
Prompts.iniciar()

-- Esconde "Roubar" nos Brainrots da sua própria base ----------------------

local function verificarPrompt(objeto: Instance)
	if objeto:IsA("ProximityPrompt") then
		Prompts.estilizar(objeto)
	end
	if objeto:IsA("ProximityPrompt") and objeto:GetAttribute("DonoId") == jogador.UserId then
		-- Mudança só no seu computador: os outros jogadores continuam vendo o botão.
		objeto.MaxActivationDistance = 0
	end
	-- "Vender" é só para o dono: some para os outros jogadores.
	local soDono = objeto:IsA("ProximityPrompt") and objeto:GetAttribute("SoDonoId")
	if soDono and soDono ~= jogador.UserId then
		(objeto :: ProximityPrompt).MaxActivationDistance = 0
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
			-- gira em volta do "Centro" (ou dele mesmo) e sobe e desce um pouco
			local centro = parte:GetAttribute("Centro") or inicio.Position
			local giro = CFrame.Angles(0, math.rad(agora * (parte:GetAttribute("Giro") or 45)), 0)
			local flutua = Vector3.new(0, math.sin(agora * 2 + inicio.Position.X) * (parte:GetAttribute("Flutua") or 0), 0)
			parte.CFrame = (CFrame.new(centro) * giro * CFrame.new(-centro) * inicio) + flutua
		end
	end
end)

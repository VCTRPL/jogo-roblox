-- Script do cliente: liga a tela, os sons e os efeitos, esconde o botão
-- "Roubar" dos seus próprios Brainrots (e o "Vender" dos dos outros) e
-- anima as esteiras.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local jogador = Players.LocalPlayer

-- Sons, tela (dinheiro, avisos, anúncios, barra do próximo bioma, Índice,
-- Ajuda e Renascer) e efeitos visuais (ovos, corrida na esteira) ------------

require(script.Sons).iniciar()
require(script.Hud).iniciar()
require(script.Efeitos).iniciar()
require(script.OvosVfx).iniciar()
require(script.Chefes).iniciar()
require(script.Ambiente).iniciar()
require(script.Interface).iniciar()
require(script.LojaOvos).iniciar()
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

-- Tranca da base: o dono atravessa as paredes da própria base -----------------
-- O personagem é simulado neste computador, então desligar a colisão só aqui
-- deixa o dono passar enquanto as paredes seguram os outros.

local function liberarDono(parede: Instance)
	if not parede:IsA("BasePart") then
		return
	end
	local function ajustar()
		if parede:GetAttribute("DonoId") == jogador.UserId and parede.CanCollide then
			parede.CanCollide = false
		end
	end
	parede:GetPropertyChangedSignal("CanCollide"):Connect(ajustar)
	parede:GetAttributeChangedSignal("DonoId"):Connect(ajustar)
	ajustar()
end
CollectionService:GetInstanceAddedSignal("TrancaBase"):Connect(liberarDono)
for _, parede in CollectionService:GetTagged("TrancaBase") do
	liberarDono(parede)
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
CollectionService:GetInstanceRemovedSignal("GirarPortal"):Connect(esquecer)

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
	-- raios do portal do fim do mapa: giram em volta do próprio eixo X
	for _, parte in CollectionService:GetTagged("GirarPortal") do
		if parte:IsA("BasePart") and parte:IsDescendantOf(Workspace) then
			local inicio = inicios[parte]
			if not inicio then
				inicio = parte.CFrame
				inicios[parte] = inicio
			end
			parte.CFrame = inicio * CFrame.Angles(math.rad(agora * (parte:GetAttribute("Giro") or 90)), 0, 0)
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

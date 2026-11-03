-- Todo botão da tela ganha vida: cresce um pouco com o mouse em cima, afunda
-- quando é apertado e faz o som de clique. Só nos botões que ainda não se
-- animam sozinhos (quem já tem um UIScale, como o menu da direita e os
-- botões de compra, cuida de si). Um botão com o atributo "SemVida" fica
-- como está.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Sons = require(script.Parent.Sons)

local BotoesVivos = {}

local RAPIDO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local VOLTA = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local vistos: { [GuiButton]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function animar(escala: UIScale, ate: number, info: TweenInfo)
	TweenService:Create(escala, info, { Scale = ate }):Play()
end

local function darVida(botao: GuiButton)
	if vistos[botao] then
		return
	end
	vistos[botao] = true
	-- espera o botão ficar pronto: quem cria às vezes põe o UIScale depois
	task.defer(function()
		if not botao.Parent or botao:GetAttribute("SemVida") or botao:FindFirstChildOfClass("UIScale") then
			return
		end
		local escala = Instance.new("UIScale")
		escala.Name = "EscalaVida"
		escala.Parent = botao
		local dentro = false
		botao.MouseEnter:Connect(function()
			dentro = true
			animar(escala, 1.06, RAPIDO)
		end)
		botao.MouseLeave:Connect(function()
			dentro = false
			animar(escala, 1, RAPIDO)
		end)
		botao.MouseButton1Down:Connect(function()
			animar(escala, 0.9, RAPIDO)
		end)
		botao.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				animar(escala, if dentro then 1.06 else 1, VOLTA)
			end
		end)
		botao.Activated:Connect(function()
			Sons.tocar("Clique")
		end)
	end)
end

function BotoesVivos.iniciar()
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui.DescendantAdded:Connect(function(objeto)
		if objeto:IsA("GuiButton") then
			darVida(objeto)
		end
	end)
	for _, objeto in gui:GetDescendants() do
		if objeto:IsA("GuiButton") then
			darVida(objeto)
		end
	end
end

return BotoesVivos

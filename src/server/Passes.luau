-- Gamepasses (Config.GAMEPASSES): vê quais cada jogador tem quando entra e
-- quando compra um durante o jogo. Quem tem fica com o atributo
-- "Pass_<chave>" (por exemplo "Pass_Dinheiro2x"), que o resto do jogo e o
-- cliente usam. O VIP ganha uma etiqueta em cima da cabeça.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)

local Passes = {}

function Passes.tem(player: Player, chave: string): boolean
	return player:GetAttribute(`Pass_{chave}`) == true
end

local function etiquetaVip(personagem: Model)
	local cabeca = personagem:WaitForChild("Head", 10)
	if not cabeca or cabeca:FindFirstChild("EtiquetaVip") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "EtiquetaVip"
	gui.Size = UDim2.fromScale(4, 1)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 80
	gui.Parent = cabeca
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.Text = "👑 VIP"
	label.TextColor3 = Color3.fromRGB(255, 215, 70)
	label.TextStrokeTransparency = 0
	label.Parent = gui
end

local function liberar(player: Player, passe)
	player:SetAttribute(`Pass_{passe.chave}`, true)
	if passe.chave == "VIP" and player.Character then
		task.spawn(etiquetaVip, player.Character)
	end
end

local function verificar(player: Player)
	for _, passe in Config.GAMEPASSES do
		if passe.id ~= 0 then
			local ok, tem = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passe.id)
			end)
			if ok and tem then
				liberar(player, passe)
			end
		end
	end
end

function Passes.iniciar()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(personagem)
			if Passes.tem(player, "VIP") then
				etiquetaVip(personagem)
			end
		end)
		verificar(player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(verificar, player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, comprou)
		if not comprou then
			return
		end
		for _, passe in Config.GAMEPASSES do
			if passe.id == id then
				liberar(player, passe)
				Avisos.enviar(player, `Obrigado! Você ganhou {passe.nome}!`, Color3.fromRGB(255, 215, 70))
				Avisos.som(player, "Comprou")
			end
		end
	end)
end

return Passes

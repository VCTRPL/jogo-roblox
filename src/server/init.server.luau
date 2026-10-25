-- Script do servidor: roda uma vez no servidor quando o jogo começa.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hello = require(ReplicatedStorage.Shared.Hello)

print(Hello.saudar("servidor"))

Players.PlayerAdded:Connect(function(player)
	print(Hello.saudar(player.Name) .. " Entrou no jogo.")
end)

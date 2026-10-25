-- Script do cliente: roda no computador de cada jogador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hello = require(ReplicatedStorage.Shared.Hello)

print(Hello.saudar(Players.LocalPlayer.Name) .. " (mensagem do cliente)")

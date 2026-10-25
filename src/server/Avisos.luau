-- Manda mensagens que aparecem na tela do jogador (o cliente mostra).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Avisos = {}

local pasta = Instance.new("Folder")
pasta.Name = "Remotes"
local evento = Instance.new("RemoteEvent")
evento.Name = "Aviso"
evento.Parent = pasta
pasta.Parent = ReplicatedStorage

function Avisos.enviar(player: Player, texto: string, cor: Color3?)
	if player.Parent == nil then
		return -- já saiu do jogo
	end
	evento:FireClient(player, texto, cor or Color3.new(1, 1, 1))
end

return Avisos

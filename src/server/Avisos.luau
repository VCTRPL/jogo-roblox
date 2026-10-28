-- Manda mensagens que aparecem na tela do jogador e pede efeitos
-- visuais para os clientes (o cliente mostra tudo, veja src/client).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Avisos = {}

local pasta = Instance.new("Folder")
pasta.Name = "Remotes"
local evento = Instance.new("RemoteEvent")
evento.Name = "Aviso"
evento.Parent = pasta
local eventoEfeito = Instance.new("RemoteEvent")
eventoEfeito.Name = "Efeito"
eventoEfeito.Parent = pasta
pasta.Parent = ReplicatedStorage

function Avisos.enviar(player: Player, texto: string, cor: Color3?)
	if player.Parent == nil then
		return -- já saiu do jogo
	end
	evento:FireClient(player, texto, cor or Color3.new(1, 1, 1))
end

-- Anúncio grande para todo mundo no servidor (por exemplo, quando nasce um raro).
function Avisos.todos(texto: string, cor: Color3?)
	evento:FireAllClients(texto, cor or Color3.new(1, 1, 1), "anuncio")
end

-- Pede para todos os clientes mostrarem um efeito, como a explosão quando um ovo choca.
function Avisos.efeito(nome: string, ...: any)
	eventoEfeito:FireAllClients(nome, ...)
end

-- Efeito só para um jogador.
function Avisos.efeitoPara(player: Player, nome: string, ...: any)
	if player.Parent ~= nil then
		eventoEfeito:FireClient(player, nome, ...)
	end
end

-- Toca um som de Config.SONS. Com "posicao", o som sai daquele lugar e
-- todo mundo por perto ouve; sem, só o jogador ouve.
function Avisos.som(player: Player?, nome: string, posicao: Vector3?)
	local dados = { nome = nome, posicao = posicao }
	if player then
		Avisos.efeitoPara(player, "Som", dados)
	else
		eventoEfeito:FireAllClients("Som", dados)
	end
end

return Avisos

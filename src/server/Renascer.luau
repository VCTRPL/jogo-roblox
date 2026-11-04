-- Renascer: quem junta dinheiro suficiente zera o progresso (dinheiro,
-- Velocidade, esteira, as trilhas compradas e a base) e ganha para sempre mais renda e mais
-- Velocidade na esteira, mais vagas na base e mais tempo de tranca. Os
-- números ficam em Config.RENASCER.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Bases = require(script.Parent.Bases)
local Carregar = require(script.Parent.Carregar)
local Dados = require(script.Parent.Dados)
local Velocidade = require(script.Parent.Velocidade)

local Renascer = {}

local VERMELHO = Color3.fromRGB(255, 90, 90)
local DOURADO = Color3.fromRGB(255, 215, 80)

local function renascer(player: Player)
	local vezes = Dados.valor(player, "Renascimentos")
	local base = Bases.doJogador(player)
	if not base then
		return
	end
	if vezes >= Config.RENASCER.maximo then
		Avisos.enviar(player, "Você já renasceu o máximo de vezes!", VERMELHO)
		Avisos.som(player, "Erro")
		return
	end
	local preco = Config.precoRenascer(vezes)
	if Dados.valor(player, "Dinheiro") < preco then
		Avisos.enviar(player, `Você precisa de ${Config.formatar(preco)} para renascer!`, VERMELHO)
		Avisos.som(player, "Erro")
		return
	end

	Carregar.perder(player)
	Bases.sairDaEsteira(player)
	Bases.limpar(base)
	Dados.definir(player, "Dinheiro", Config.DINHEIRO_INICIAL)
	Dados.definir(player, "Velocidade", 0)
	Dados.definir(player, "Renascimentos", vezes + 1)
	player:SetAttribute("NivelEsteira", 1)
	-- as trilhas compradas também vão embora: volta para a trilha inicial
	-- (nenhuma). Mudar esses atributos já agenda um salvamento (init), então
	-- elas não voltam quando ele sai e entra de novo.
	local tinhaTrilha = (player:GetAttribute("NivelTrilha") or 0) > 0
	player:SetAttribute("TrilhaEquipada", 0)
	player:SetAttribute("NivelTrilha", 0)
	Velocidade.atualizar(player)
	Bases.atualizarPlaca(base)

	local personagem = player.Character
	if personagem then
		personagem:PivotTo(base.spawn)
	end
	local renda = Config.multiplicadorRenda(vezes + 1)
	Avisos.enviar(
		player,
		`Você renasceu! Agora ganha {renda}x de dinheiro, tem {Config.vagas(vezes + 1)} vagas e {Config.tempoTranca(vezes + 1)}s de tranca!`,
		DOURADO
	)
	if tinhaTrilha then
		Avisos.enviar(player, "Suas trilhas foram zeradas: compre de novo na Loja de Trilhas!", Color3.fromRGB(255, 150, 255))
	end
	Avisos.todos(`{player.DisplayName} renasceu pela {vezes + 1}ª vez!`, DOURADO)
	-- espera o teleporte chegar no cliente (senão a câmera ainda está longe
	-- e o efeito não aparece); quem renasceu vê sempre, os outros se estiverem perto
	task.delay(0.35, function()
		-- quem renasceu ouve na tela; os outros ouvem na base, no mundo
		Avisos.som(player, "Renasceu")
		for _, outro in Players:GetPlayers() do
			if outro ~= player then
				Avisos.som(outro, "Renasceu", base.spawn.Position)
			end
		end
		Avisos.efeito("Renasceu", { posicao = base.spawn.Position, jogador = player.UserId })
	end)
end

function Renascer.iniciar()
	local evento = Instance.new("RemoteEvent")
	evento.Name = "Renascer"
	evento.Parent = ReplicatedStorage:WaitForChild("Remotes")
	evento.OnServerEvent:Connect(renascer)
end

return Renascer

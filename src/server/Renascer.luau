-- Renascer: quem junta dinheiro suficiente zera o progresso (dinheiro,
-- Velocidade, esteira e a base) e ganha para sempre mais renda e mais
-- Velocidade na esteira. Os números ficam em Config.RENASCER.
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
	Velocidade.atualizar(player)
	Bases.atualizarPlaca(base)

	local personagem = player.Character
	if personagem then
		personagem:PivotTo(base.spawn)
	end
	local renda = Config.multiplicadorRenda(vezes + 1)
	Avisos.enviar(player, `Você renasceu! Agora ganha {renda}x de dinheiro!`, DOURADO)
	Avisos.todos(`{player.DisplayName} renasceu pela {vezes + 1}ª vez!`, DOURADO)
	Avisos.som(nil, "Renasceu", base.info.centro)
	Avisos.efeito("Renasceu", { posicao = base.spawn.Position })
end

function Renascer.iniciar()
	local evento = Instance.new("RemoteEvent")
	evento.Name = "Renascer"
	evento.Parent = ReplicatedStorage:WaitForChild("Remotes")
	evento.OnServerEvent:Connect(renascer)
end

return Renascer

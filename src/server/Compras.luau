-- Ovos especiais comprados com Robux (Config.OVOS_ROBUX, Developer Products).
-- Só o ProcessReceipt dá o prêmio: o cliente pede para comprar, o servidor
-- confere a oferta e abre a janela de compra, e o Roblox avisa o servidor
-- quando o pagamento passou. Cada recibo (PurchaseId) fica guardado nos dados
-- do jogador junto com o prêmio, então o mesmo recibo nunca dá duas vezes.
-- O Brainrot sorteado vai para a base; se ela estiver cheia, espera no
-- inventário (Dados.pendentes), que este módulo esvazia quando abre vaga.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Bases = require(script.Parent.Bases)
local Dados = require(script.Parent.Dados)

local Compras = {}

local DOURADO = Color3.fromRGB(255, 215, 80)
local VERMELHO = Color3.fromRGB(255, 90, 90)

-- Quem já está com a base montada (os itens salvos já foram colocados).
local prontos: { [Player]: boolean } = {}
local ultimoPedido: { [Player]: number } = {}
local avisouCheia: { [Player]: number } = {}

local function ovoDoProduto(produtoId: number)
	for _, ovo in Config.OVOS_ROBUX do
		if ovo.produtoId ~= 0 and ovo.produtoId == produtoId then
			return ovo
		end
	end
	return nil
end

local function ofertaAtiva(ovo): boolean
	local fim = Config.fimOferta(ovo)
	return fim == nil or os.time() <= fim
end

local function atualizarContagem(player: Player)
	player:SetAttribute("Pendentes", #Dados.pendentes(player))
end

-- Põe na base o que estava no inventário esperando vaga.
local function entregarPendentes(player: Player)
	local base = Bases.doJogador(player)
	if not base or not prontos[player] then
		return
	end
	while #Dados.pendentes(player) > 0 and Bases.vagaLivre(base) do
		local item = Dados.tirarPendente(player)
		if item then
			Bases.colocar(base, item)
		end
	end
	atualizarContagem(player)
end

local function nomeDo(item): string
	local def = Config.brainrot(item.id)
	local nome = if def then def.nome else item.id
	return if item.mutacao and item.mutacao ~= "Normal" then `{nome} {item.mutacao}` else nome
end

local function processar(recibo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(recibo.PlayerId)
	-- fora do jogo ou ainda carregando: o Roblox tenta de novo depois
	if not player or not prontos[player] or not Dados.pronto(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ovo = ovoDoProduto(recibo.ProductId)
	if not ovo then
		warn("Produto desconhecido no ProcessReceipt:", recibo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local compraId = tostring(recibo.PurchaseId)
	if Dados.jaEntregue(player, compraId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- Sem os dados do DataStore não dá para guardar o recibo. No Studio (onde o
	-- DataStore não funciona e as compras são de teste) entrega mesmo assim.
	local teste = RunService:IsStudio() and not Dados.carregado(player)
	if not Dados.carregado(player) and not teste then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local sorteados = {}
	for _ = 1, ovo.quantidade or 1 do
		local item = Config.sortearOvoRobux(ovo)
		Dados.adicionarPendente(player, item)
		Dados.somarEstatistica(player, "Ovos", 1)
		Dados.somarEstatistica(player, "Brainrots", 1)
		table.insert(sorteados, item)
	end
	Dados.registrarCompra(player, compraId)

	-- Grava o prêmio e o recibo juntos antes de confirmar para o Roblox.
	local base = Bases.doJogador(player)
	local salvou = teste or (base ~= nil and Dados.salvar(player, Bases.itens(base)))

	entregarPendentes(player)
	Avisos.efeitoPara(player, "OvoRobux", { chave = ovo.chave, itens = sorteados })
	Avisos.som(player, "Comprou")
	for _, item in sorteados do
		local def = Config.brainrot(item.id)
		if def and (Config.ANUNCIAR_RARIDADES[def.raridade] or Config.ANUNCIAR_MUTACOES[item.mutacao]) then
			Avisos.todos(`{player.DisplayName} abriu um {ovo.nome} e ganhou {nomeDo(item)}!`, Config.CORES_RARIDADE[def.raridade])
		end
	end

	if not salvou then
		-- O prêmio já está com o jogador e o recibo está anotado: se o Roblox
		-- mandar de novo nesta sessão, cai no "jaEntregue". Se nada chegar a
		-- ser salvo, ele recebe de novo da próxima vez, o que está certo.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- O cliente pede para comprar: confere tudo e abre a janela de compra do Roblox.
local function pedirCompra(player: Player, chave: any)
	if typeof(chave) ~= "string" then
		return
	end
	local agora = os.clock()
	if agora - (ultimoPedido[player] or 0) < 1 then
		return
	end
	ultimoPedido[player] = agora
	local ovo = Config.ovoRobux(chave)
	if not ovo or ovo.produtoId == 0 then
		Avisos.enviar(player, "Esse ovo ainda não está à venda.", VERMELHO)
		return
	end
	if not ofertaAtiva(ovo) then
		Avisos.enviar(player, "Essa oferta já acabou!", VERMELHO)
		return
	end
	MarketplaceService:PromptProductPurchase(player, ovo.produtoId)
end

-- Chamado quando a base do jogador já tem os itens salvos.
function Compras.entrar(player: Player)
	prontos[player] = true
	entregarPendentes(player)
end

function Compras.sair(player: Player)
	prontos[player] = nil
	ultimoPedido[player] = nil
	avisouCheia[player] = nil
end

function Compras.iniciar()
	local evento = Instance.new("RemoteEvent")
	evento.Name = "ComprarOvo"
	evento.Parent = ReplicatedStorage:WaitForChild("Remotes")
	evento.OnServerEvent:Connect(pedirCompra)

	MarketplaceService.ProcessReceipt = processar

	-- Vaga nova na base (vendeu ou chocou e foi roubado): entrega o que falta.
	task.spawn(function()
		while true do
			task.wait(2)
			for player in prontos do
				if #Dados.pendentes(player) > 0 then
					entregarPendentes(player)
					local agora = os.clock()
					if #Dados.pendentes(player) > 0 and agora - (avisouCheia[player] or 0) > 60 then
						avisouCheia[player] = agora
						Avisos.enviar(player, `Base cheia! {#Dados.pendentes(player)} item(ns) no inventário esperando vaga.`, DOURADO)
					end
				end
			end
		end
	end)

	-- Só no Studio: ServerStorage.TesteCompra:Invoke(player, chave) simula um
	-- recibo, para testar a entrega sem ids de produto de verdade.
	if RunService:IsStudio() then
		local teste = Instance.new("BindableFunction")
		teste.Name = "TesteCompra"
		teste.OnInvoke = function(player: Player, chave: string, compraId: string?)
			local ovo = Config.ovoRobux(chave)
			if not ovo then
				return "ovo não existe"
			end
			local produtoOriginal = ovo.produtoId
			ovo.produtoId = if produtoOriginal ~= 0 then produtoOriginal else -1
			local decisao = processar({
				PlayerId = player.UserId,
				ProductId = ovo.produtoId,
				PurchaseId = compraId or `teste_{os.clock()}`,
				CurrencySpent = ovo.robux,
			})
			ovo.produtoId = produtoOriginal
			return decisao.Name
		end
		teste.Parent = ServerStorage
	end
end

return Compras

-- Bases dos jogadores: vagas, ovos chocando, renda por segundo,
-- esteira de corrida e a tranca.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Dados = require(script.Parent.Dados)
local Esteiras = require(script.Parent.Esteiras)
local Mapa = require(script.Parent.Mapa)
local Modelos = require(script.Parent.Modelos)
local Velocidade = require(script.Parent.Velocidade)

local Bases = {}

type ItemNaBase = {
	item: Modelos.Item,
	modelo: Model,
	chocaEm: number?, -- só ovos (os.clock)
}

export type Base = {
	info: Mapa.InfoBase,
	dono: Player?,
	vagas: { CFrame },
	itens: { [number]: ItemNaBase },
	trancadaAte: number,
	spawn: CFrame,
	escudo: Part,
	esteira: BasePart, -- a "Pista" do modelo atual
	modeloEsteira: Model,
	cframeEsteira: CFrame,
	nivelEsteira: number, -- nível do modelo que está montado
	textoBotao: TextLabel,
	textoPlaca: TextLabel,
	textoEsteira: TextLabel,
}

local bases: { Base } = {}
local porJogador: { [Player]: Base } = {}

local VERMELHO = Color3.fromRGB(255, 90, 90)
local VERDE = Color3.fromRGB(90, 255, 120)

-- Chamado quando alguém tenta roubar algo de uma base (o módulo Carregar preenche isso).
Bases.aoTentarRoubar = nil :: ((ladrao: Player, base: Base, vaga: number) -> ())?

function Bases.renda(base: Base): number
	local total = 0
	for _, dados in base.itens do
		if dados.item.tipo == "verity" then
			total += Config.renda(dados.item)
		end
	end
	return total
end

local function atualizarPlaca(base: Base)
	if base.dono then
		base.textoPlaca.Text = `Base de {base.dono.DisplayName}\n${Config.formatar(Bases.renda(base))}/s`
	else
		base.textoPlaca.Text = "Base livre"
	end
end

-- Troca o modelo da esteira quando o nível muda.
local function montarEsteira(base: Base, nivel: number)
	if base.nivelEsteira == nivel then
		return
	end
	base.modeloEsteira:Destroy()
	local modelo = Esteiras.criar(nivel, base.cframeEsteira)
	modelo.Parent = base.info.pasta
	base.modeloEsteira = modelo
	base.esteira = modelo:FindFirstChild("Pista") :: BasePart
	base.nivelEsteira = nivel
end

local function atualizarEsteira(base: Base)
	local nivel = if base.dono then base.dono:GetAttribute("NivelEsteira") or 1 else 1
	montarEsteira(base, nivel)
	if not base.dono then
		base.textoEsteira.Text = "Esteira"
		return
	end
	local atual = Config.NIVEIS_ESTEIRA[nivel]
	local proximo = Config.NIVEIS_ESTEIRA[nivel + 1]
	local texto = `{atual.nome}\n+{atual.ganho} Velocidade`
	if proximo then
		texto ..= `\nMelhorar: ${Config.formatar(proximo.preco)}`
	end
	base.textoEsteira.Text = texto
end

function Bases.estaTrancada(base: Base): boolean
	return os.clock() < base.trancadaAte
end

local function trancar(player: Player, base: Base)
	if base.dono ~= player then
		Avisos.enviar(player, "Essa não é a sua base!", VERMELHO)
	elseif Bases.estaTrancada(base) then
		Avisos.enviar(player, "Sua base já está trancada.")
	else
		base.trancadaAte = os.clock() + Config.TEMPO_TRANCA
		Avisos.enviar(player, `Base trancada por {Config.TEMPO_TRANCA} segundos!`, Color3.fromRGB(90, 200, 255))
	end
end

local function melhorarEsteira(player: Player, base: Base)
	if base.dono ~= player then
		Avisos.enviar(player, "Essa não é a sua esteira!", VERMELHO)
		return
	end
	local nivel = player:GetAttribute("NivelEsteira") or 1
	local proximo = Config.NIVEIS_ESTEIRA[nivel + 1]
	if not proximo then
		Avisos.enviar(player, "Sua esteira já está no nível máximo!")
	elseif Dados.valor(player, "Dinheiro") < proximo.preco then
		Avisos.enviar(player, "Dinheiro insuficiente!", VERMELHO)
	else
		Dados.adicionar(player, "Dinheiro", -proximo.preco)
		player:SetAttribute("NivelEsteira", nivel + 1)
		atualizarEsteira(base)
		Avisos.enviar(player, `Esteira melhorada: +{proximo.ganho} Velocidade!`, VERDE)
	end
end

local function chocar(base: Base, vaga: number)
	local dados = base.itens[vaga]
	local dono = base.dono
	if not dados or not dono then
		return
	end
	local ovo = Config.ovo(dados.item.id)
	local verity = Config.verity(ovo.verity)
	local nascido: Modelos.Item = {
		tipo = "verity",
		id = verity.id,
		tamanho = dados.item.tamanho,
		mutacao = Config.sortearMutacao().nome,
	}
	Bases.remover(base, vaga)
	Bases.colocar(base, nascido, vaga)

	local renda = Config.renda(nascido)
	local bonus = Config.BONUS_VELOCIDADE[verity.raridade] or 0
	Dados.adicionar(dono, "Dinheiro", renda * 30)
	Velocidade.adicionar(dono, bonus)
	local nome = if nascido.mutacao == "Normal" then verity.nome else `{verity.nome} {nascido.mutacao}`
	Avisos.enviar(
		dono,
		`Nasceu um {nome}! +${Config.formatar(renda * 30)} e +{bonus} Velocidade`,
		Config.CORES_RARIDADE[verity.raridade]
	)
end

local function criarBase(info: Mapa.InfoBase): Base
	local tamanho = Mapa.TAMANHO_BASE
	local lado = info.lado
	local topo = info.centro
	-- de frente para a estrada (z = 0)
	local olhar = Vector3.new(0, 0, -lado)

	local vagas = {}
	local colunas = math.ceil(Config.VAGAS_POR_BASE / 2)
	for i = 0, Config.VAGAS_POR_BASE - 1 do
		local coluna = i % colunas
		local linha = i // colunas
		local x = (coluna - (colunas - 1) / 2) * 6.5
		local pos = topo + Vector3.new(x, 0, lado * (6 + linha * 7))
		table.insert(vagas, CFrame.lookAt(pos, pos + olhar))
	end

	local escudo = Instance.new("Part")
	escudo.Name = "Escudo"
	escudo.Anchored = true
	escudo.CanCollide = false
	escudo.CanQuery = false
	escudo.Size = Vector3.new(tamanho, 14, 1)
	escudo.Position = topo + Vector3.new(0, 7, -lado * tamanho / 2)
	escudo.Color = Color3.fromRGB(80, 170, 255)
	escudo.Material = Enum.Material.ForceField
	escudo.Transparency = 1
	escudo.Parent = info.pasta

	local botao = Instance.new("Part")
	botao.Name = "BotaoTrancar"
	botao.Anchored = true
	botao.Size = Vector3.new(4, 1, 4)
	botao.Position = topo + Vector3.new(tamanho / 2 - 4, 0, -lado * (tamanho / 2 - 4))
	botao.Color = Color3.fromRGB(255, 80, 80)
	botao.Material = Enum.Material.Neon
	botao.Parent = info.pasta
	local promptTrancar = Instance.new("ProximityPrompt")
	promptTrancar.ActionText = "Trancar base"
	promptTrancar.ObjectText = "Tranca"
	promptTrancar.RequiresLineOfSight = false
	promptTrancar.Parent = botao

	-- Esteira de corrida: o modelo muda a cada nível (veja Esteiras.luau).
	-- O botão de melhorar e a placa ficam numa peça invisível que não muda.
	local centroEsteira = topo + Vector3.new(-(tamanho / 2 - 5), 0.2, -lado * (tamanho / 2 - 8))
	local cframeEsteira = CFrame.lookAt(centroEsteira, centroEsteira + olhar)
	local modeloEsteira = Esteiras.criar(1, cframeEsteira)
	modeloEsteira.Parent = info.pasta
	local marcoEsteira = Instance.new("Part")
	marcoEsteira.Name = "MarcoEsteira"
	marcoEsteira.Anchored = true
	marcoEsteira.CanCollide = false
	marcoEsteira.CanQuery = false
	marcoEsteira.CanTouch = false
	marcoEsteira.Transparency = 1
	marcoEsteira.Size = Vector3.new(1, 1, 1)
	marcoEsteira.CFrame = cframeEsteira
	marcoEsteira.Parent = info.pasta
	local promptEsteira = Instance.new("ProximityPrompt")
	promptEsteira.ActionText = "Melhorar esteira"
	promptEsteira.ObjectText = "Esteira"
	promptEsteira.RequiresLineOfSight = false
	promptEsteira.HoldDuration = 0.5
	promptEsteira.Parent = marcoEsteira

	local base: Base = {
		info = info,
		dono = nil,
		vagas = vagas,
		itens = {},
		trancadaAte = 0,
		spawn = CFrame.lookAt(topo + Vector3.new(0, 3, -lado * 4), topo + Vector3.new(0, 3, -lado * 20)),
		escudo = escudo,
		esteira = modeloEsteira:FindFirstChild("Pista") :: BasePart,
		modeloEsteira = modeloEsteira,
		cframeEsteira = cframeEsteira,
		nivelEsteira = 1,
		textoBotao = Mapa.placa(botao, "Trancar", 3, 160),
		textoPlaca = Mapa.placa(info.piso, "Base livre", 14),
		textoEsteira = Mapa.placa(marcoEsteira, "Esteira", 9, 220),
	}
	promptTrancar.Triggered:Connect(function(player)
		trancar(player, base)
	end)
	promptEsteira.Triggered:Connect(function(player)
		melhorarEsteira(player, base)
	end)
	return base
end

local function emCimaDaEsteira(base: Base, posicao: Vector3): boolean
	local esteira = base.esteira
	local local_ = esteira.CFrame:PointToObjectSpace(posicao)
	local meio = esteira.Size / 2
	return math.abs(local_.X) <= meio.X and math.abs(local_.Z) <= meio.Z and local_.Y < 6
end

function Bases.iniciar(infos: { Mapa.InfoBase })
	for _, info in infos do
		local base = criarBase(info)
		atualizarPlaca(base)
		table.insert(bases, base)
	end

	-- Renda por segundo
	task.spawn(function()
		while true do
			task.wait(1)
			for _, base in bases do
				if base.dono then
					Dados.adicionar(base.dono, "Dinheiro", Bases.renda(base))
				end
			end
		end
	end)

	-- Esteiras de corrida: quem está em cima ganha Velocidade
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in Players:GetPlayers() do
				local personagem = player.Character
				local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
				local minha = porJogador[player]
				if raiz and minha and emCimaDaEsteira(minha, raiz.Position) then
					local nivel = player:GetAttribute("NivelEsteira") or 1
					Velocidade.adicionar(player, Config.NIVEIS_ESTEIRA[nivel].ganho)
				end
			end
		end
	end)

	-- Tranca e ovos chocando
	task.spawn(function()
		while true do
			task.wait(0.25)
			local agora = os.clock()
			for _, base in bases do
				local trancada = Bases.estaTrancada(base)
				base.escudo.Transparency = if trancada then 0.3 else 1
				base.textoBotao.Text = if trancada then `Trancada: {math.ceil(base.trancadaAte - agora)}s` else "Trancar"
				local prontos = {}
				for vaga, dados in base.itens do
					Modelos.prompt(dados.modelo).Enabled = not trancada
					if dados.chocaEm then
						local falta = dados.chocaEm - agora
						if falta <= 0 then
							table.insert(prontos, vaga)
						else
							Modelos.textoPlaca(dados.modelo, "Tempo", `Choca em {math.ceil(falta)}s`)
						end
					end
				end
				for _, vaga in prontos do
					chocar(base, vaga)
				end
			end
		end
	end)
end

function Bases.atribuir(player: Player): Base?
	for _, base in bases do
		if not base.dono then
			base.dono = player
			base.trancadaAte = 0
			porJogador[player] = base
			atualizarPlaca(base)
			atualizarEsteira(base)
			return base
		end
	end
	return nil
end

function Bases.liberar(player: Player)
	local base = porJogador[player]
	if not base then
		return
	end
	for vaga in base.itens do
		Bases.remover(base, vaga)
	end
	base.dono = nil
	base.trancadaAte = 0
	porJogador[player] = nil
	atualizarPlaca(base)
	atualizarEsteira(base)
end

function Bases.doJogador(player: Player): Base?
	return porJogador[player]
end

function Bases.vagaLivre(base: Base): number?
	for vaga = 1, #base.vagas do
		if not base.itens[vaga] then
			return vaga
		end
	end
	return nil
end

-- Coloca um ovo ou Verity numa vaga livre (ou na vaga pedida, se estiver livre).
-- Retorna false se a base estiver cheia.
function Bases.colocar(base: Base, item: Modelos.Item, vagaPreferida: number?): boolean
	local vaga = if vagaPreferida and not base.itens[vagaPreferida] then vagaPreferida else Bases.vagaLivre(base)
	local dono = base.dono
	if not vaga or not dono then
		return false
	end
	if item.tipo == "ovo" and not Config.ovo(item.id) then
		return false
	end
	if item.tipo == "verity" and not Config.verity(item.id) then
		return false
	end

	local modelo = Modelos.criar(item)
	local prompt = Modelos.prompt(modelo)
	prompt.ActionText = "Roubar"
	prompt.HoldDuration = 1.5
	-- O cliente usa isto para esconder o botão "Roubar" das suas próprias coisas.
	prompt:SetAttribute("DonoId", dono.UserId)
	prompt.Triggered:Connect(function(ladrao)
		if Bases.aoTentarRoubar then
			Bases.aoTentarRoubar(ladrao, base, vaga)
		end
	end)

	local chocaEm = nil
	if item.tipo == "ovo" then
		chocaEm = os.clock() + (item.restante or Config.ovo(item.id).chocar)
	end

	modelo:PivotTo(base.vagas[vaga])
	modelo.Parent = base.info.pasta
	base.itens[vaga] = { item = item, modelo = modelo, chocaEm = chocaEm }
	atualizarPlaca(base)
	return true
end

-- Tira o item da vaga e devolve ele (ovos guardam quanto falta para chocar).
function Bases.remover(base: Base, vaga: number): Modelos.Item?
	local dados = base.itens[vaga]
	if not dados then
		return nil
	end
	base.itens[vaga] = nil
	dados.modelo:Destroy()
	local item = table.clone(dados.item)
	if dados.chocaEm then
		item.restante = math.max(0, math.ceil(dados.chocaEm - os.clock()))
	end
	atualizarPlaca(base)
	return item
end

-- Lista de itens para salvar.
function Bases.itens(base: Base): { Modelos.Item }
	local lista = {}
	for _, dados in base.itens do
		local item = table.clone(dados.item)
		if dados.chocaEm then
			item.restante = math.max(0, math.ceil(dados.chocaEm - os.clock()))
		end
		table.insert(lista, item)
	end
	return lista
end

function Bases.dentro(base: Base, posicao: Vector3): boolean
	return Mapa.dentroQuadrado(base.info.centro, Mapa.TAMANHO_BASE, posicao)
end

return Bases

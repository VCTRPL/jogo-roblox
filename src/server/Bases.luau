-- Bases dos jogadores: vagas, ovos chocando, renda por segundo, vender
-- Brainrots, esteira de corrida (com fôlego) e a tranca.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Dados = require(script.Parent.Dados)
local Esteiras = require(script.Parent.Esteiras)
local Mapa = require(script.Parent.Mapa)
local Modelos = require(script.Parent.Modelos)
local Passes = require(script.Parent.Passes)
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
-- Quem está correndo na esteira da própria base.
local correndo: { [Player]: Base } = {}
-- Quem já saiu de cima da pista desde a última corrida (pode subir de novo).
local desceu: { [Player]: boolean } = {}
-- Quando cada um começou a correr (para o fôlego).
local inicioCorrida: { [Player]: number } = {}

local VERMELHO = Color3.fromRGB(255, 90, 90)
local VERDE = Color3.fromRGB(90, 255, 120)

-- Chamado quando alguém tenta roubar algo de uma base (o módulo Carregar preenche isso).
Bases.aoTentarRoubar = nil :: ((ladrao: Player, base: Base, vaga: number) -> ())?

-- Multiplicador de dinheiro: renascimentos e os passes 2x Dinheiro e VIP.
local function multiplicador(player: Player?): number
	if not player then
		return 1
	end
	local total = Config.multiplicadorRenda(Dados.valor(player, "Renascimentos"))
	if Passes.tem(player, "Dinheiro2x") then
		total *= 2
	end
	if Passes.tem(player, "VIP") then
		total *= 1.5
	end
	return total
end

-- Renda por segundo da base, já contando o renascimento do dono.
function Bases.renda(base: Base): number
	local total = 0
	for _, dados in base.itens do
		if dados.item.tipo == "brainrot" then
			total += Config.renda(dados.item)
		end
	end
	return math.floor(total * multiplicador(base.dono))
end

-- Quanto valem, juntos, os Brainrots da base (o preço de venda de cada um).
function Bases.valor(base: Base): number
	local total = 0
	for _, dados in base.itens do
		if dados.item.tipo == "brainrot" then
			total += Config.precoVenda(dados.item)
		end
	end
	return math.floor(total * multiplicador(base.dono))
end

local function atualizarPlaca(base: Base)
	if base.dono then
		base.textoPlaca.Text = `Base de {base.dono.DisplayName}\n${Config.formatar(Bases.renda(base))}/s`
	else
		base.textoPlaca.Text = "Base livre"
	end
end
Bases.atualizarPlaca = atualizarPlaca

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
		Avisos.som(player, "Erro")
	elseif Bases.estaTrancada(base) then
		Avisos.enviar(player, "Sua base já está trancada.")
	else
		local tempo = Config.TEMPO_TRANCA * (if Passes.tem(player, "TrancaLonga") then 2 else 1)
		base.trancadaAte = os.clock() + tempo
		Avisos.enviar(player, `Base trancada por {tempo} segundos!`, Color3.fromRGB(90, 200, 255))
		Avisos.som(nil, "Trancou", base.escudo.Position)
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
		Avisos.som(player, "Erro")
	else
		-- quem está correndo desce: o modelo da esteira vai ser trocado
		Bases.sairDaEsteira(player)
		Dados.adicionar(player, "Dinheiro", -proximo.preco)
		player:SetAttribute("NivelEsteira", nivel + 1)
		atualizarEsteira(base)
		Esteiras.celebrar(base.modeloEsteira, nivel + 1)
		Avisos.enviar(player, `{proximo.nome}! +{proximo.ganho} Velocidade!`, VERDE)
		Avisos.som(nil, "Melhorou", base.cframeEsteira.Position)
		Avisos.efeito("EsteiraNova", { posicao = base.cframeEsteira.Position, nivel = nivel + 1 })
	end
end

local function chocar(base: Base, vaga: number)
	local dados = base.itens[vaga]
	local dono = base.dono
	if not dados or not dono then
		return
	end
	local ovo = Config.ovo(dados.item.id)
	local brainrot = Config.brainrot(ovo.brainrot)
	local nascido: Modelos.Item = {
		tipo = "brainrot",
		id = brainrot.id,
		tamanho = dados.item.tamanho,
		mutacao = Config.sortearMutacao(Passes.tem(dono, "Sorte")).nome,
	}
	Bases.remover(base, vaga)
	Bases.colocar(base, nascido, vaga)

	local ganho = math.floor(Config.renda(nascido) * 30 * multiplicador(dono))
	local bonus = Config.BONUS_VELOCIDADE[brainrot.raridade] or 0
	Dados.adicionar(dono, "Dinheiro", ganho)
	Velocidade.adicionar(dono, bonus)
	Dados.somarEstatistica(dono, "Ovos", 1)
	Dados.somarEstatistica(dono, "Brainrots", 1)
	local nome = if nascido.mutacao == "Normal" then brainrot.nome else `{brainrot.nome} {nascido.mutacao}`
	Avisos.enviar(
		dono,
		`Nasceu um {nome}! +${Config.formatar(ganho)} e +{bonus} Velocidade`,
		Config.CORES_RARIDADE[brainrot.raridade]
	)
	-- explosão de partículas na vaga, que todo mundo por perto vê
	local posicao = base.vagas[vaga].Position
	Avisos.efeito("Chocou", {
		posicao = posicao,
		raridade = brainrot.raridade,
		mutacao = nascido.mutacao,
		ganho = ganho,
	})
	local raro = Config.nivelRaridade(brainrot.raridade) >= Config.nivelRaridade("Lendario") or nascido.mutacao ~= "Normal"
	Avisos.som(nil, if raro then "ChocouRaro" else "Chocou", posicao)
	if Config.ANUNCIAR_RARIDADES[brainrot.raridade] or Config.ANUNCIAR_MUTACOES[nascido.mutacao] then
		Avisos.todos(`{dono.DisplayName} chocou um {nome}!`, Config.CORES_RARIDADE[brainrot.raridade])
	end
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
		local x = (coluna - (colunas - 1) / 2) * 12
		local pos = topo + Vector3.new(x, 0, lado * (4 + linha * 15))
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

	-- Esteira de corrida: do lado de fora da base, à direita da entrada (de
	-- quem chega pela estrada), em cima de uma plataforma, com quem corre
	-- olhando para a estrada. O modelo muda a cada nível (veja Esteiras.luau).
	-- O botão de melhorar e a placa ficam numa peça invisível que não muda.
	local direita = -lado -- olhando da estrada para a base, a direita fica em -lado no eixo X
	local frente = topo.Z - lado * tamanho / 2 -- z da frente da base (lado da estrada)
	local meioFora = (frente + lado * 7.4) / 2 -- entre a frente da base e o meio-fio
	local plataforma = Instance.new("Part")
	plataforma.Name = "PlataformaEsteira"
	plataforma.Anchored = true
	plataforma.Size = Vector3.new(14, 1, 21)
	plataforma.Position = Vector3.new(topo.X + direita * 20, 0.5, meioFora)
	plataforma.Color = Color3.fromRGB(120, 120, 130)
	plataforma.Material = Enum.Material.SmoothPlastic
	plataforma.Parent = info.pasta
	local centroEsteira = Vector3.new(plataforma.Position.X, 1.2, meioFora)
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
		textoEsteira = Mapa.placa(marcoEsteira, "Esteira", 12, 220),
	}
	promptTrancar.Triggered:Connect(function(player)
		trancar(player, base)
	end)
	promptEsteira.Triggered:Connect(function(player)
		melhorarEsteira(player, base)
	end)
	return base
end

-- Correr na esteira: quem sobe na pista da própria esteira fica preso
-- (ancorado) em cima dela, olhando para o painel, e o cliente toca a
-- animação de corrida. Assim ninguém atravessa a esteira, por mais rápido
-- que seja.
function Bases.entrarNaEsteira(player: Player, base: Base)
	if base.dono ~= player or correndo[player] then
		return
	end
	local personagem = player.Character
	local hum = personagem and personagem:FindFirstChildOfClass("Humanoid")
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not raiz or hum.Health <= 0 then
		return
	end
	correndo[player] = base
	inicioCorrida[player] = os.clock()
	hum.Sit = false
	local pista = base.esteira
	local altura = hum.HipHeight + raiz.Size.Y / 2
	raiz.Anchored = true
	raiz.CFrame = pista.CFrame * CFrame.new(0, pista.Size.Y / 2 + altura, -1)
	player:SetAttribute("NaEsteira", true)
end

function Bases.sairDaEsteira(player: Player)
	local base = correndo[player]
	if not base then
		return
	end
	correndo[player] = nil
	inicioCorrida[player] = nil
	-- só volta a correr depois de descer da pista
	desceu[player] = nil
	player:SetAttribute("NaEsteira", false)
	player:SetAttribute("Folego", nil)
	local personagem = player.Character
	local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
	if raiz then
		-- desce por trás da esteira
		raiz.CFrame = base.cframeEsteira * CFrame.new(0, 3, 9)
		raiz.Anchored = false
	end
end

function Bases.iniciar(infos: { Mapa.InfoBase })
	-- o cliente pede para sair da esteira (pulo ou botão "Sair")
	local sair = Instance.new("RemoteEvent")
	sair.Name = "SairEsteira"
	sair.Parent = ReplicatedStorage:WaitForChild("Remotes")
	sair.OnServerEvent:Connect(function(player)
		Bases.sairDaEsteira(player)
	end)

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
					local renda = Bases.renda(base)
					Dados.adicionar(base.dono, "Dinheiro", renda)
					-- o cliente mostra a renda por segundo no painel de dinheiro
					base.dono:SetAttribute("Renda", renda)
				end
			end
		end
	end)

	-- Subiu na pista da própria esteira: começa a correr sozinho
	task.spawn(function()
		while true do
			task.wait(0.1)
			for player, base in porJogador do
				if not correndo[player] then
					local personagem = player.Character
					local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart") :: BasePart?
					local pista = base.esteira
					local emCima = false
					if raiz and pista then
						local ponto = pista.CFrame:PointToObjectSpace(raiz.Position)
						emCima = math.abs(ponto.X) <= pista.Size.X / 2 + 0.5
							and math.abs(ponto.Z) <= pista.Size.Z / 2
							and ponto.Y > 0
							and ponto.Y < 7
					end
					if not emCima then
						desceu[player] = true
					elseif desceu[player] then
						Bases.entrarNaEsteira(player, base)
					end
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
				if correndo[player] and (not raiz or correndo[player] ~= minha) then
					Bases.sairDaEsteira(player) -- morreu ou perdeu a base
				elseif correndo[player] then
					local nivel = player:GetAttribute("NivelEsteira") or 1
					-- fôlego: vai de 1x até FOLEGO_MAXIMO correndo sem parar
					local tempo = os.clock() - (inicioCorrida[player] or os.clock())
					local folego = 1 + (Config.FOLEGO_MAXIMO - 1) * math.min(tempo / Config.FOLEGO_TEMPO, 1)
					local renascimentos = Dados.valor(player, "Renascimentos")
					local ganho = Config.NIVEIS_ESTEIRA[nivel].ganho * folego * Config.multiplicadorEsteira(renascimentos)
					if Passes.tem(player, "Velocidade2x") then
						ganho *= 2
					end
					Velocidade.adicionar(player, math.floor(ganho))
					player:SetAttribute("Folego", math.floor(folego * 10) / 10)
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
					-- quando a renda muda (renascimento), o preço também muda
					local promptVender = (dados.modelo.PrimaryPart :: BasePart):FindFirstChild("Vender") :: ProximityPrompt?
					if promptVender and base.dono then
						promptVender.ObjectText = `${Config.formatar(math.floor(Config.precoVenda(dados.item) * multiplicador(base.dono)))}`
					end
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
			-- o cliente usa para a seta que leva de volta para a base
			player:SetAttribute("BaseCentro", base.info.centro)
			-- o nível pode chegar depois (dados carregados): troca o modelo
			player:GetAttributeChangedSignal("NivelEsteira"):Connect(function()
				if base.dono == player then
					atualizarEsteira(base)
				end
			end)
			atualizarPlaca(base)
			atualizarEsteira(base)
			return base
		end
	end
	return nil
end

function Bases.liberar(player: Player)
	correndo[player] = nil
	desceu[player] = nil
	inicioCorrida[player] = nil
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

-- Tira tudo da base (renascimento).
function Bases.limpar(base: Base)
	for vaga in base.itens do
		Bases.remover(base, vaga)
	end
end

-- O dono vende o Brainrot da vaga.
local function vender(player: Player, base: Base, vaga: number, modelo: Model)
	local dados = base.itens[vaga]
	if base.dono ~= player or not dados or dados.modelo ~= modelo or dados.item.tipo ~= "brainrot" then
		return
	end
	local preco = math.floor(Config.precoVenda(dados.item) * multiplicador(player))
	local def = Config.brainrot(dados.item.id)
	local posicao = base.vagas[vaga].Position
	Bases.remover(base, vaga)
	Dados.adicionar(player, "Dinheiro", preco)
	Avisos.enviar(player, `Vendeu {def.nome} por ${Config.formatar(preco)}!`, VERDE)
	Avisos.efeito("Vendeu", { posicao = posicao, ganho = preco })
	Avisos.som(nil, "Vendeu", posicao)
end

function Bases.vagaLivre(base: Base): number?
	for vaga = 1, #base.vagas do
		if not base.itens[vaga] then
			return vaga
		end
	end
	return nil
end

-- Coloca um ovo ou Brainrot numa vaga livre (ou na vaga pedida, se estiver livre).
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
	if item.tipo == "brainrot" and not Config.brainrot(item.id) then
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

	-- Botão "Vender" que só o dono vê (o cliente esconde dos outros).
	if item.tipo == "brainrot" then
		local preco = math.floor(Config.precoVenda(item) * multiplicador(dono))
		local promptVender = Instance.new("ProximityPrompt")
		promptVender.Name = "Vender"
		promptVender.ActionText = "Vender"
		promptVender.ObjectText = `${Config.formatar(preco)}`
		promptVender.HoldDuration = 1
		promptVender.RequiresLineOfSight = false
		promptVender.MaxActivationDistance = 10
		promptVender:SetAttribute("SoDonoId", dono.UserId)
		promptVender.Parent = prompt.Parent
		promptVender.Triggered:Connect(function(player)
			vender(player, base, vaga, modelo)
		end)
	end

	local chocaEm = nil
	if item.tipo == "ovo" then
		local falta = item.restante or Config.ovo(item.id).chocar
		if Passes.tem(dono, "ChocarRapido") then
			falta = math.min(falta, math.ceil(Config.ovo(item.id).chocar / 2))
		end
		chocaEm = os.clock() + falta
		-- o cliente usa para os efeitos do ovo chocando (tremer, rachar, barra)
		modelo:SetAttribute("ChocaEm", Workspace:GetServerTimeNow() + falta)
		modelo:SetAttribute("Duracao", Config.ovo(item.id).chocar)
		CollectionService:AddTag(modelo, "OvoChocando")
	end

	modelo:PivotTo(base.vagas[vaga])
	modelo.Parent = base.info.pasta
	base.itens[vaga] = { item = item, modelo = modelo, chocaEm = chocaEm }

	-- Brainrot novo na base (chocou, roubou ou comprou): entra no Índice
	if item.tipo == "brainrot" and Dados.descobrir(dono, item.id) and dono:GetAttribute("BaseCarregada") then
		local def = Config.brainrot(item.id)
		Avisos.enviar(dono, `📖 Novo no Índice: {def.nome}!`, Config.CORES_RARIDADE[def.raridade])
	end
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

-- Bases dos jogadores: vagas, renda por segundo e a tranca.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Avisos = require(script.Parent.Avisos)
local Dados = require(script.Parent.Dados)
local Mapa = require(script.Parent.Mapa)
local Verities = require(script.Parent.Verities)

local Bases = {}

export type Base = {
	info: Mapa.InfoBase,
	dono: Player?,
	vagas: { CFrame },
	itens: { [number]: { id: string, modelo: Model } },
	trancadaAte: number,
	spawn: CFrame,
	escudo: Part,
	textoBotao: TextLabel,
	textoPlaca: TextLabel,
}

local bases: { Base } = {}
local porJogador: { [Player]: Base } = {}

-- Chamado quando alguém tenta roubar um Verity (o módulo Roubo preenche isso).
Bases.aoTentarRoubar = nil :: ((ladrao: Player, base: Base, vaga: number) -> ())?

local function criarTextoFlutuante(parent: Instance, tamanho: UDim2, altura: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = tamanho
	gui.StudsOffsetWorldSpace = Vector3.new(0, altura, 0)
	gui.MaxDistance = 150
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return label
end

function Bases.renda(base: Base): number
	local total = 0
	for _, item in base.itens do
		total += Config.buscar(item.id).renda
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

function Bases.estaTrancada(base: Base): boolean
	return os.clock() < base.trancadaAte
end

local function trancar(player: Player, base: Base)
	if base.dono ~= player then
		Avisos.enviar(player, "Essa não é a sua base!", Color3.fromRGB(255, 90, 90))
	elseif Bases.estaTrancada(base) then
		Avisos.enviar(player, "Sua base já está trancada.")
	else
		base.trancadaAte = os.clock() + Config.TEMPO_TRANCA
		Avisos.enviar(player, `Base trancada por {Config.TEMPO_TRANCA} segundos!`, Color3.fromRGB(90, 200, 255))
	end
end

function Bases.iniciar()
	local tamanho = Mapa.TAMANHO_BASE
	for _, info in Mapa.construir() do
		local lado = info.lado
		local topo = info.centro + Vector3.new(0, 0.5, 0)
		-- olhando para a esteira (z = 0)
		local olhar = Vector3.new(0, 0, -lado)

		local vagas = {}
		for linha = 0, 1 do
			for coluna = 0, Config.VAGAS_POR_BASE / 2 - 1 do
				local x = -14 + coluna * 7
				local z = lado * (8 + linha * 6)
				local pos = topo + Vector3.new(x, 0, z)
				table.insert(vagas, CFrame.lookAt(pos, pos + olhar))
			end
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
		botao.Position = topo + Vector3.new(tamanho / 2 - 4, 0.5, -lado * (tamanho / 2 - 4))
		botao.Color = Color3.fromRGB(255, 80, 80)
		botao.Material = Enum.Material.Neon
		botao.Parent = info.pasta

		local promptTrancar = Instance.new("ProximityPrompt")
		promptTrancar.ActionText = "Trancar base"
		promptTrancar.ObjectText = "Tranca"
		promptTrancar.RequiresLineOfSight = false
		promptTrancar.Parent = botao

		local base: Base = {
			info = info,
			dono = nil,
			vagas = vagas,
			itens = {},
			trancadaAte = 0,
			spawn = CFrame.lookAt(topo + Vector3.new(0, 3, -lado * 4), topo + Vector3.new(0, 3, -lado * 20)),
			escudo = escudo,
			textoBotao = criarTextoFlutuante(botao, UDim2.fromOffset(160, 40), 3),
			textoPlaca = criarTextoFlutuante(info.piso, UDim2.fromOffset(260, 80), 14),
		}
		promptTrancar.Triggered:Connect(function(player)
			trancar(player, base)
		end)
		atualizarPlaca(base)
		table.insert(bases, base)
	end

	-- Renda por segundo
	task.spawn(function()
		while true do
			task.wait(1)
			for _, base in bases do
				if base.dono then
					Dados.adicionar(base.dono, Bases.renda(base))
				end
			end
		end
	end)

	-- Tranca: mostra o tempo e liga/desliga o escudo e os botões de roubar
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, base in bases do
				local trancada = Bases.estaTrancada(base)
				base.escudo.Transparency = if trancada then 0.3 else 1
				base.textoBotao.Text = if trancada
					then `Trancada: {math.ceil(base.trancadaAte - os.clock())}s`
					else "Trancar"
				for _, item in base.itens do
					Verities.prompt(item.modelo).Enabled = not trancada
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

-- Coloca um Verity numa vaga livre da base. Retorna false se a base estiver cheia.
function Bases.colocar(base: Base, id: string): boolean
	local vaga = Bases.vagaLivre(base)
	local def = Config.buscar(id)
	if not vaga or not def or not base.dono then
		return false
	end

	local modelo = Verities.criar(def)
	local placa = (modelo.PrimaryPart :: BasePart):FindFirstChild("Placa")
	if placa then
		(placa :: any).Preco.Visible = false
	end
	local prompt = Verities.prompt(modelo)
	prompt.ActionText = "Roubar"
	prompt.HoldDuration = 1.5
	-- O cliente usa isto para esconder o botão "Roubar" dos seus próprios Verities.
	prompt:SetAttribute("DonoId", base.dono.UserId)
	prompt.Triggered:Connect(function(ladrao)
		if Bases.aoTentarRoubar then
			Bases.aoTentarRoubar(ladrao, base, vaga)
		end
	end)

	modelo:PivotTo(base.vagas[vaga])
	modelo.Parent = base.info.pasta
	base.itens[vaga] = { id = id, modelo = modelo }
	atualizarPlaca(base)
	return true
end

-- Tira o Verity da vaga e devolve o id dele.
function Bases.remover(base: Base, vaga: number): string?
	local item = base.itens[vaga]
	if not item then
		return nil
	end
	base.itens[vaga] = nil
	item.modelo:Destroy()
	atualizarPlaca(base)
	return item.id
end

function Bases.ids(base: Base): { string }
	local lista = {}
	for _, item in base.itens do
		table.insert(lista, item.id)
	end
	return lista
end

function Bases.dentro(base: Base, posicao: Vector3): boolean
	local meio = Mapa.TAMANHO_BASE / 2
	local centro = base.info.centro
	return math.abs(posicao.X - centro.X) <= meio and math.abs(posicao.Z - centro.Z) <= meio
end

return Bases

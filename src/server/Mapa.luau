-- Monta o mapa por código: 6 bases grandes perto do começo (3 de cada lado)
-- e uma estrada que leva aos biomas, um depois do outro.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local Mapa = {}

Mapa.TAMANHO_BASE = 72
-- Bases bem separadas (de lado e da estrada) para roubar dar trabalho mesmo
-- com muita Velocidade.
Mapa.ESPACO_BASES = 190 -- de um centro de base ao próximo (no eixo X)
Mapa.Z_BASES = 110 -- distância do centro das bases até o meio da estrada
Mapa.INICIO_ESTRADA = -313
Mapa.TUNEL_BOCA = -290 -- a estrada sai de um túnel na montanha
Mapa.TUNEL_LARGURA = 22 -- por dentro
Mapa.TUNEL_ALTURA = 20
-- Lado (em X e em Z) de cada bioma. Grande de propósito: os ovos ficam
-- espalhados longe da entrada e o chefe num canto do fundo.
Mapa.TAMANHO_BIOMA = 170
Mapa.INICIO_BIOMAS = 330 -- x onde começa o primeiro bioma
Mapa.ESPACO_BIOMAS = 70 -- transição entre um bioma e o próximo
Mapa.FIM_BASES = Mapa.INICIO_BIOMAS - 18 -- daqui para trás é a área das bases (os chefes param aqui)
Mapa.Z_PAREDE = Mapa.TAMANHO_BIOMA / 2 + 2 -- paredes dos lados dos biomas
-- Pontos de destaque da área das bases: as duas praças com chafariz (do lado
-- sul da rua, cada uma no meio do espaço entre duas bases) e a Loja de
-- Trilhas (do lado norte, no meio do espaço entre as bases 5 e 6).
Mapa.FONTES = { Vector3.new(-Mapa.ESPACO_BASES / 2, 0.05, -78), Vector3.new(Mapa.ESPACO_BASES / 2, 0.05, -78) }
Mapa.RAIO_PRACA = 20
Mapa.LOJA_TRILHAS = Vector3.new(Mapa.ESPACO_BASES / 2, 0.05, 52)
Mapa.FIM_ESTRADA = Mapa.INICIO_BIOMAS + #Config.BIOMAS * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)

-- Onde começa (x) o bioma de número "i".
function Mapa.inicioBioma(i: number): number
	return Mapa.INICIO_BIOMAS + (i - 1) * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS)
end

-- Arrumação de dentro de cada bioma: onde fica o chefe (num canto do fundo,
-- longe da entrada), onde ficam os ninhos (espalhados, nenhum colado na
-- entrada nem no chefe nem no meio, que é do enfeite principal) e as
-- trilhas que ligam a entrada aos ninhos e à arena do chefe. O sorteio usa
-- uma semente por bioma, então Ninhos e Decoracao recebem a mesma arrumação.
Mapa.NINHOS_POR_BIOMA = 8
Mapa.RAIO_ARENA = 20 -- área do chefe (sem enfeite nem ninho)
Mapa.RAIO_MEIO = 20 -- o meio do bioma fica para o enfeite principal (lago, oásis...)
Mapa.RAIO_MARCO = 26 -- o outro canto do fundo fica para um enfeite grande (vulcão, mesa...)

export type Arrumacao = {
	chefe: Vector3, -- casa do chefe (no chão do bioma)
	marco: Vector3, -- o outro canto do fundo, para o enfeite grande do bioma
	ninhos: { Vector3 },
	entrada: Vector3, -- onde a trilha começa, logo depois do arco
	trilhas: { { Vector3 } }, -- cada uma é uma lista de pontos
}

local arrumacoes: { [number]: Arrumacao } = {}

local function plano(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function Mapa.arrumacao(i: number): Arrumacao
	if arrumacoes[i] then
		return arrumacoes[i]
	end
	local T = Mapa.TAMANHO_BIOMA
	local inicio = Mapa.inicioBioma(i)
	local y = 1
	local centro = Vector3.new(inicio + T / 2, y, 0)
	local sorteio = Random.new(9100 + i * 37)
	-- o canto do chefe troca de lado a cada bioma
	local ladoChefe = if i % 2 == 1 then 1 else -1
	local chefe = Vector3.new(inicio + T - 32, y, ladoChefe * (T / 2 - 32))
	local entrada = Vector3.new(inicio + 6, y, 0)
	local marco = Vector3.new(inicio + T - 36, y, -ladoChefe * (T / 2 - 36))

	local ninhos: { Vector3 } = {}
	local distanciaMinima = 34
	local tentativas = 0
	while #ninhos < Mapa.NINHOS_POR_BIOMA do
		tentativas += 1
		if tentativas % 600 == 0 then
			distanciaMinima -= 2 -- não coube: aperta um pouco
		end
		local p = Vector3.new(sorteio:NextNumber(inicio + 44, inicio + T - 14), y, sorteio:NextNumber(-T / 2 + 14, T / 2 - 14))
		local ok = plano(p, entrada) > 46
			and plano(p, chefe) > Mapa.RAIO_ARENA + 24
			and plano(p, centro) > Mapa.RAIO_MEIO + 10
			and plano(p, marco) > Mapa.RAIO_MARCO + 8
			and math.abs(p.Z) > 6 -- não em cima da trilha principal
		if ok then
			for _, outro in ninhos do
				if plano(p, outro) < distanciaMinima then
					ok = false
					break
				end
			end
		end
		if ok then
			table.insert(ninhos, p)
		end
	end

	-- Trilhas: a principal sai da entrada, contorna o meio e vai até a arena;
	-- de cada ninho sai uma trilha até o ponto mais perto da rede (árvore
	-- mínima, sem cruzar o meio).
	local function torta(de: Vector3, ate: Vector3): { Vector3 }
		local pontos = { de }
		local direcao = ate - de
		local normal = Vector3.new(-direcao.Z, 0, direcao.X).Unit
		local partes = math.max(2, math.round(direcao.Magnitude / 22))
		for k = 1, partes - 1 do
			local t = k / partes
			local p = de + direcao * t + normal * sorteio:NextNumber(-5, 5)
			-- desvia do meio e do enfeite grande do canto
			for _, evitar in { { centro, Mapa.RAIO_MEIO + 6 }, { marco, Mapa.RAIO_MARCO + 4 } } do
				local onde, raio = evitar[1], evitar[2]
				if plano(p, onde) < raio then
					local fora = Vector3.new(p.X - onde.X, 0, p.Z - onde.Z)
					if fora.Magnitude < 0.1 then
						fora = Vector3.new(0, 0, -ladoChefe)
					end
					p = Vector3.new(onde.X, y, onde.Z) + fora.Unit * raio
				end
			end
			table.insert(pontos, p)
		end
		table.insert(pontos, ate)
		return pontos
	end
	local trilhas = {}
	-- principal: entrada -> lado oposto ao chefe do meio -> arena
	local volta = Vector3.new(centro.X, y, -ladoChefe * (Mapa.RAIO_MEIO + 8))
	local principal = torta(entrada, volta)
	local resto = torta(volta, chefe + (entrada - chefe).Unit * (Mapa.RAIO_ARENA - 4))
	for k = 2, #resto do
		table.insert(principal, resto[k])
	end
	table.insert(trilhas, principal)
	local rede = table.clone(principal)
	local faltam = table.clone(ninhos)
	while #faltam > 0 do
		local melhor, melhorNinho, melhorPonto = math.huge, 1, rede[1]
		for k, ninho in faltam do
			for _, ponto in rede do
				local d = plano(ninho, ponto)
				if d < melhor then
					melhor, melhorNinho, melhorPonto = d, k, ponto
				end
			end
		end
		local ninho = table.remove(faltam, melhorNinho) :: Vector3
		local trilha = torta(melhorPonto, ninho)
		table.insert(trilhas, trilha)
		for _, ponto in trilha do
			table.insert(rede, ponto)
		end
	end

	local arrumacao = { chefe = chefe, marco = marco, ninhos = ninhos, entrada = entrada, trilhas = trilhas }
	arrumacoes[i] = arrumacao
	return arrumacao
end

-- Distância (no chão) de "p" até a trilha mais perto.
function Mapa.distanciaTrilha(arrumacao: Arrumacao, p: Vector3): number
	local melhor = math.huge
	local q = Vector3.new(p.X, 0, p.Z)
	for _, trilha in arrumacao.trilhas do
		for k = 1, #trilha - 1 do
			local a = Vector3.new(trilha[k].X, 0, trilha[k].Z)
			local b = Vector3.new(trilha[k + 1].X, 0, trilha[k + 1].Z)
			local ab = b - a
			local t = if ab.Magnitude > 0 then math.clamp((q - a):Dot(ab) / ab:Dot(ab), 0, 1) else 0
			melhor = math.min(melhor, (q - (a + ab * t)).Magnitude)
		end
	end
	return melhor
end

-- Lugar livre para enfeite dentro do bioma "i": longe dos ninhos, da arena,
-- do meio e das trilhas. "folga" afasta mais (árvores grandes).
function Mapa.livreNoBioma(i: number, p: Vector3, folga: number?): boolean
	local f = folga or 0
	local arrumacao = Mapa.arrumacao(i)
	local T = Mapa.TAMANHO_BIOMA
	local inicio = Mapa.inicioBioma(i)
	if p.X < inicio + 3 + f or p.X > inicio + T - 3 - f or math.abs(p.Z) > T / 2 - 3 - f then
		return false
	end
	if p.X < inicio + 16 and math.abs(p.Z) < 18 then
		return false -- passagem do arco
	end
	if plano(p, Vector3.new(inicio + T / 2, 0, 0)) < Mapa.RAIO_MEIO + 2 + f then
		return false
	end
	if plano(p, arrumacao.chefe) < Mapa.RAIO_ARENA + 3 + f then
		return false
	end
	if plano(p, arrumacao.marco) < Mapa.RAIO_MARCO + f then
		return false
	end
	for _, ninho in arrumacao.ninhos do
		if plano(p, ninho) < 9 + f then
			return false
		end
	end
	return Mapa.distanciaTrilha(arrumacao, p) > 5 + f
end

local function parte(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local parent = props.Parent
	props.Parent = nil
	for chave, valor in props do
		(p :: any)[chave] = valor
	end
	p.Parent = parent
	return p
end
Mapa.parte = parte

-- Placa flutuante. O tamanho é em studs (não em pixels), então as placas
-- longe ficam pequenas e não enchem a tela. "largura" segue a escala antiga:
-- 260 dá uma placa de 10 studs.
function Mapa.placa(parent: BasePart, texto: string, altura: number, largura: number?): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale((largura or 260) / 26, 3.5)
	gui.StudsOffsetWorldSpace = Vector3.new(0, altura, 0)
	gui.MaxDistance = 120
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Text = texto
	label.Parent = gui
	return label
end

export type InfoBase = {
	piso: Part,
	centro: Vector3, -- topo do piso
	lado: number, -- -1 ou 1: de que lado da estrada a base está
	pasta: Folder,
}

export type InfoBioma = {
	config: any,
	indice: number, -- posição em Config.BIOMAS (para Mapa.arrumacao)
	centro: Vector3, -- topo do piso
	entrada: Vector3, -- ponto na estrada logo antes do bioma
	pasta: Folder,
}

function Mapa.construir(): ({ InfoBase }, { InfoBioma })
	local pasta = Instance.new("Folder")
	pasta.Name = "Mapa"

	-- Estrada de asfalto só até a entrada do primeiro bioma. Entre um bioma e
	-- o próximo o chão é a transição de um para o outro (Decoracao).
	local fimEstrada = Mapa.FIM_ESTRADA
	local inicioEstrada = Mapa.INICIO_ESTRADA
	local primeiroBioma = Mapa.inicioBioma(1)
	parte({
		Name = "Estrada",
		Size = Vector3.new(primeiroBioma - inicioEstrada, 1, 14),
		Position = Vector3.new((primeiroBioma + inicioEstrada) / 2, 0.5, 0),
		Color = Color3.fromRGB(58, 60, 66),
		Material = Enum.Material.Asphalt,
		Parent = pasta,
	}):SetAttribute("SemLego", true) -- asfalto de verdade, sem pinos

	local bases = {}
	for i = 1, 6 do
		local lado = if i <= 3 then -1 else 1
		local x = ((i - 1) % 3 - 1) * Mapa.ESPACO_BASES
		local pastaBase = Instance.new("Folder")
		pastaBase.Name = `Base{i}`
		pastaBase.Parent = pasta

		-- o piso é de grama, igual ao chão do mapa (Decoracao); a cor de cada
		-- base fica nas lanternas, faixa e bandeiras (Decoracao)
		local matiz = (i - 1) / 6
		local piso = parte({
			Name = "Piso",
			Size = Vector3.new(Mapa.TAMANHO_BASE, 1, Mapa.TAMANHO_BASE),
			Position = Vector3.new(x, 0.5, lado * Mapa.Z_BASES),
			Color = Color3.fromRGB(125, 195, 90),
			Material = Enum.Material.Grass,
			Parent = pastaBase,
		})
		piso:SetAttribute("CorBase", Color3.fromHSV(matiz, 0.4, 0.85))
		table.insert(bases, { piso = piso, centro = Vector3.new(x, 1, lado * Mapa.Z_BASES), lado = lado, pasta = pastaBase })
	end
	-- caminho de pedra da estrada até a entrada de cada base
	for _, base in bases do
		local de = 7.4
		local ate = Mapa.Z_BASES - Mapa.TAMANHO_BASE / 2
		parte({
			Name = "Caminho",
			Size = Vector3.new(12, 1, ate - de + 1),
			Position = Vector3.new(base.centro.X, 0.45, base.lado * (de + ate) / 2),
			Color = Color3.fromRGB(200, 194, 182),
			Material = Enum.Material.Pavement,
			Parent = pasta,
		}):SetAttribute("SemLego", true)
	end

	local biomas = {}
	for i, config in Config.BIOMAS do
		local inicio = Mapa.inicioBioma(i)
		local centro = Vector3.new(inicio + Mapa.TAMANHO_BIOMA / 2, 1, 0)
		local pastaBioma = Instance.new("Folder")
		pastaBioma.Name = config.nome
		pastaBioma.Parent = pasta

		parte({
			Name = "Piso",
			-- um pouquinho acima da estrada para não piscar onde as duas se encontram
			Size = Vector3.new(Mapa.TAMANHO_BIOMA, 1.3, Mapa.TAMANHO_BIOMA),
			Position = centro - Vector3.new(0, 0.6, 0),
			Color = config.cor,
			Material = Enum.Material.Grass,
			Parent = pastaBioma,
		})

		-- Portal na entrada com o nome e a velocidade necessária
		local portal = parte({
			Name = "Portal",
			Size = Vector3.new(1, 28, 33),
			Position = Vector3.new(inicio, 15, 0),
			Color = config.cor,
			Material = Enum.Material.ForceField,
			Transparency = 0.5,
			CanCollide = false,
			CanQuery = false,
			Parent = pastaBioma,
		})
		-- o nome e a Velocidade necessária ficam na placa do arco (Decoracao)
		portal:SetAttribute("Bioma", config.nome)

		table.insert(biomas, {
			config = config,
			indice = i,
			centro = centro,
			entrada = Vector3.new(inicio - 8, 4, 0),
			pasta = pastaBioma,
		})
	end

	pasta.Parent = Workspace
	return bases, biomas
end

function Mapa.dentroQuadrado(centro: Vector3, tamanho: number, posicao: Vector3): boolean
	local meio = tamanho / 2
	return math.abs(posicao.X - centro.X) <= meio and math.abs(posicao.Z - centro.Z) <= meio
end

return Mapa

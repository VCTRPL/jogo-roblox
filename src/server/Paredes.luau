-- Paredes dos biomas: uma parede só, dos dois lados da estrada, que vai da
-- área das bases até o fim do mapa (como no "Roube um Ovo!"). Em cada
-- trecho ela tem a cara do bioma: troncos na Selva, rochedo na Praia,
-- arenito em camadas no Deserto, basalto com rachaduras de lava no Vulcão e
-- painéis de metal com neon no Espaço. Em cima tem uma parede invisível
-- bem alta, então ninguém passa para o bioma seguinte pelo lado.
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Mapa = require(script.Parent.Mapa)

local Paredes = {}

local GROSSURA = 4
local TRECHO = 8 -- comprimento de cada pedaço de parede

local aleatorio = Random.new(777)

local function escolher<T>(lista: { T }): T
	return lista[aleatorio:NextInteger(1, #lista)]
end

local function bloco(pasta: Instance, nome: string, tamanho: Vector3, posicao: Vector3, cor: Color3, props: any?): BasePart
	local p = Mapa.parte({
		Name = nome,
		Size = tamanho,
		Position = posicao,
		Color = cor,
		Material = Enum.Material.Plastic,
		Parent = pasta,
	})
	if props then
		for chave, valor in props do
			(p :: any)[chave] = valor
		end
	end
	return p
end

-- Cada estilo monta um pedaço de parede com o meio em "x", na linha "z".
-- "fora" é 1 ou -1: para que lado do eixo Z fica o lado de fora do mapa
-- (o lado de dentro, que o jogador vê, é z - fora * ...).
type Montador = (pasta: Instance, x: number, z: number, fora: number) -> ()

local ESTILOS: { [string]: Montador } = {
	-- troncos em pé, de alturas diferentes, com folhas em cima de alguns
	floresta = function(pasta, x, z, fora)
		local TRONCOS = { Color3.fromRGB(115, 78, 46), Color3.fromRGB(100, 68, 40), Color3.fromRGB(130, 90, 55) }
		local FOLHAS = { Color3.fromRGB(75, 170, 60), Color3.fromRGB(60, 145, 65), Color3.fromRGB(95, 190, 70) }
		for i = 0, 3 do
			local altura = aleatorio:NextNumber(13, 18)
			local px = x - TRECHO / 2 + 1 + i * 2
			bloco(pasta, "Tronco", Vector3.new(2, altura, GROSSURA), Vector3.new(px, altura / 2, z), escolher(TRONCOS), { Material = Enum.Material.Wood })
			bloco(pasta, "PontaTronco", Vector3.new(1.4, 1, GROSSURA - 1), Vector3.new(px, altura + 0.5, z), Color3.fromRGB(150, 110, 70))
		end
		if aleatorio:NextNumber() < 0.5 then
			bloco(pasta, "Folhas", Vector3.new(TRECHO + 2, 4, GROSSURA + 3), Vector3.new(x, aleatorio:NextNumber(15, 18), z), escolher(FOLHAS), { CanCollide = false })
		end
		-- musgo na base
		bloco(pasta, "Musgo", Vector3.new(TRECHO, 1.6, 0.6), Vector3.new(x, 0.8, z - fora * (GROSSURA / 2 + 0.3)), escolher(FOLHAS))
	end,

	-- rochedo cinza-areia em degraus, com conchas e coral
	praia = function(pasta, x, z, fora)
		local ROCHA = { Color3.fromRGB(175, 165, 145), Color3.fromRGB(155, 148, 132), Color3.fromRGB(190, 180, 158) }
		local altura = aleatorio:NextNumber(14, 19)
		bloco(pasta, "Rochedo", Vector3.new(TRECHO, altura, GROSSURA), Vector3.new(x, altura / 2, z), escolher(ROCHA))
		local degrau = aleatorio:NextNumber(4, 8)
		bloco(pasta, "Rochedo", Vector3.new(TRECHO * 0.8, degrau, 2), Vector3.new(x + aleatorio:NextNumber(-1, 1), degrau / 2, z - fora * (GROSSURA / 2 + 1)), escolher(ROCHA))
		bloco(pasta, "Areia", Vector3.new(TRECHO, 1.2, GROSSURA + 0.4), Vector3.new(x, altura + 0.6, z), Color3.fromRGB(240, 220, 165))
		if aleatorio:NextNumber() < 0.35 then
			local cor = escolher({ Color3.fromRGB(255, 120, 140), Color3.fromRGB(255, 170, 90), Color3.fromRGB(250, 240, 230) })
			bloco(pasta, "Concha", Vector3.new(1.2, 0.8, 0.5), Vector3.new(x, degrau + 0.4, z - fora * (GROSSURA / 2 + 1.5)), cor, { CanCollide = false })
		end
	end,

	-- arenito em camadas laranja e bege, com o topo irregular
	deserto = function(pasta, x, z, fora)
		local CAMADAS = { Color3.fromRGB(225, 175, 115), Color3.fromRGB(205, 140, 85), Color3.fromRGB(235, 195, 140), Color3.fromRGB(190, 120, 70) }
		local altura = aleatorio:NextNumber(14, 20)
		local y = 0
		local i = aleatorio:NextInteger(1, #CAMADAS)
		while y < altura do
			local h = math.min(aleatorio:NextNumber(2, 4), altura - y)
			bloco(pasta, "Arenito", Vector3.new(TRECHO, h, GROSSURA + (i % 2) * 0.4), Vector3.new(x, y + h / 2, z), CAMADAS[i % #CAMADAS + 1])
			y += h
			i += 1
		end
		if aleatorio:NextNumber() < 0.4 then
			bloco(pasta, "Pico", Vector3.new(TRECHO * 0.5, 3, GROSSURA * 0.8), Vector3.new(x + aleatorio:NextNumber(-2, 2), altura + 1.5, z), CAMADAS[1])
		end
	end,

	-- basalto preto com rachaduras de lava brilhando e pontas em cima
	vulcao = function(pasta, x, z, fora)
		local BASALTO = { Color3.fromRGB(45, 38, 38), Color3.fromRGB(60, 48, 46), Color3.fromRGB(38, 32, 34) }
		local altura = aleatorio:NextNumber(15, 21)
		bloco(pasta, "Basalto", Vector3.new(TRECHO, altura, GROSSURA), Vector3.new(x, altura / 2, z), escolher(BASALTO))
		if aleatorio:NextNumber() < 0.6 then
			local alturaRacha = aleatorio:NextNumber(4, altura - 2)
			local racha = bloco(
				pasta,
				"Lava",
				Vector3.new(0.6, alturaRacha, 0.3),
				Vector3.new(x + aleatorio:NextNumber(-3, 3), alturaRacha / 2, z - fora * (GROSSURA / 2 + 0.1)),
				Color3.fromRGB(255, 110, 30),
				{ Material = Enum.Material.Neon, CanCollide = false, CastShadow = false }
			)
			CollectionService:AddTag(racha, "PulsarEsteira")
		end
		for _ = 1, aleatorio:NextInteger(1, 2) do
			bloco(pasta, "Ponta", Vector3.new(1.4, aleatorio:NextNumber(2, 4), 1.4), Vector3.new(x + aleatorio:NextNumber(-3, 3), altura + 1.5, z), escolher(BASALTO))
		end
	end,

	-- painéis de metal com faixas de neon, janelas e luzes em cima
	espaco = function(pasta, x, z, fora)
		local altura = 18
		bloco(pasta, "Painel", Vector3.new(TRECHO - 0.2, altura, GROSSURA), Vector3.new(x, altura / 2, z), escolher({ Color3.fromRGB(70, 72, 95), Color3.fromRGB(60, 62, 85) }), {
			Material = Enum.Material.Metal,
		})
		local frente = z - fora * (GROSSURA / 2 + 0.1)
		local faixa = bloco(pasta, "Neon", Vector3.new(TRECHO - 0.4, 0.4, 0.3), Vector3.new(x, 4, frente), Color3.fromRGB(80, 220, 255), {
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
		})
		CollectionService:AddTag(faixa, "PulsarEsteira")
		if aleatorio:NextNumber() < 0.5 then
			bloco(pasta, "Janela", Vector3.new(4, 3, 0.3), Vector3.new(x, 11, frente), Color3.fromRGB(30, 20, 70), {
				Material = Enum.Material.Glass,
				Transparency = 0.2,
				CanCollide = false,
			})
		end
		bloco(pasta, "Topo", Vector3.new(TRECHO, 1, GROSSURA + 0.6), Vector3.new(x, altura + 0.5, z), Color3.fromRGB(150, 150, 170), { Material = Enum.Material.Metal })
		if aleatorio:NextNumber() < 0.3 then
			local luz = bloco(pasta, "Luz", Vector3.new(1, 1, 1), Vector3.new(x, altura + 1.5, z), Color3.fromRGB(255, 70, 90), {
				Material = Enum.Material.Neon,
				CanCollide = false,
			})
			CollectionService:AddTag(luz, "PulsarEsteira")
		end
	end,
}

-- Parede invisível bem alta ao longo da linha (ninguém pula por cima).
local function barreira(pasta: Instance, de: number, ate: number, z: number)
	bloco(pasta, "Barreira", Vector3.new(ate - de, 200, GROSSURA), Vector3.new((de + ate) / 2, 100, z), Color3.new(1, 1, 1), {
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
	})
end

function Paredes.construir(biomas: { Mapa.InfoBioma })
	local pasta = Instance.new("Folder")
	pasta.Name = "Paredes"

	local inicio = Mapa.FIM_BASES
	local fim = Mapa.FIM_ESTRADA + 14
	for i, info in biomas do
		-- cada bioma cuida do trecho dele e da metade das estradas em volta
		local comeco = if i == 1 then inicio else Mapa.inicioBioma(i) - Mapa.ESPACO_BIOMAS / 2
		local final = if i == #biomas then fim else Mapa.inicioBioma(i) + Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS / 2
		local montar = ESTILOS[info.config.estilo] or ESTILOS.floresta
		for _, lado in { -1, 1 } do
			local z = lado * (Mapa.Z_PAREDE + GROSSURA / 2)
			local x = comeco + TRECHO / 2
			while x < final do
				montar(pasta, x, z, lado)
				x += TRECHO
			end
		end
	end
	for _, lado in { -1, 1 } do
		barreira(pasta, inicio, fim, lado * (Mapa.Z_PAREDE + GROSSURA / 2))
	end

	pasta.Parent = Workspace
	return pasta
end

return Paredes

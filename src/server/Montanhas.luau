-- Montanhas quadradas fechando o mapa: em volta da área das bases e dos
-- dois lados da estrada das fases, para ninguém sair pelas laterais. Atrás
-- de cada fileira tem uma parede invisível bem alta, então nem pulando pelos
-- degraus dá para passar.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Mapa = require(script.Parent.Mapa)

local Montanhas = {}

-- Até onde vai cada área (as linhas internas das montanhas).
Montanhas.INICIO = -150 -- atrás da entrada
Montanhas.Z_BASES = 94 -- bases vão até z = 79, sobra espaço para árvores
Montanhas.Z_FASES = 56 -- o piso das fases vai até z = 50
Montanhas.TRANSICAO = Mapa.INICIO_BIOMAS - 16 -- onde a área das bases vira estrada das fases

local aleatorio = Random.new(4321)

local GRAMA = { Color3.fromRGB(100, 185, 75), Color3.fromRGB(85, 165, 65), Color3.fromRGB(115, 195, 85) }
local TERRA = Color3.fromRGB(150, 110, 75)
local PEDRA = { Color3.fromRGB(150, 150, 160), Color3.fromRGB(128, 128, 140), Color3.fromRGB(165, 160, 152) }
local NEVE = Color3.fromRGB(245, 248, 255)

local function escolher<T>(lista: { T }): T
	return lista[aleatorio:NextInteger(1, #lista)]
end

-- Uma montanha em degraus: blocos cada vez menores, um em cima do outro,
-- grama embaixo, pedra no meio e neve no topo das mais altas.
local function montanha(pasta: Instance, chao: Vector3, largura: number, altura: number)
	local andares = aleatorio:NextInteger(3, 5)
	local y = 0
	local w, d = largura, largura * aleatorio:NextNumber(0.8, 1.05)
	local centro = chao
	for andar = 1, andares do
		local h = altura / andares * aleatorio:NextNumber(0.85, 1.2)
		local fracao = andar / andares
		local cor = if fracao <= 0.34 then escolher(GRAMA) elseif fracao <= 0.5 then TERRA else escolher(PEDRA)
		Mapa.parte({
			Name = "Montanha",
			Size = Vector3.new(w, h, d),
			Position = centro + Vector3.new(0, y + h / 2, 0),
			Color = cor,
			Material = Enum.Material.Plastic,
			Parent = pasta,
		})
		-- um bloquinho de grama "escorrendo" em alguns degraus
		if fracao <= 0.5 and aleatorio:NextNumber() < 0.6 then
			local lado = Vector3.new(aleatorio:NextNumber(-0.5, 0.5) * w, 0, aleatorio:NextNumber(-0.5, 0.5) * d)
			Mapa.parte({
				Name = "Montanha",
				Size = Vector3.new(w * 0.3, h * 0.6, d * 0.3),
				Position = centro + lado + Vector3.new(0, y + h * 0.3, 0),
				Color = escolher(GRAMA),
				Material = Enum.Material.Plastic,
				Parent = pasta,
			})
		end
		y += h
		w *= aleatorio:NextNumber(0.62, 0.78)
		d *= aleatorio:NextNumber(0.62, 0.78)
		centro += Vector3.new(aleatorio:NextNumber(-0.12, 0.12) * w, 0, aleatorio:NextNumber(-0.12, 0.12) * d)
	end
	if altura >= 34 then
		Mapa.parte({
			Name = "Neve",
			Size = Vector3.new(w * 1.25, 2, d * 1.25),
			Position = centro + Vector3.new(0, y + 0.6, 0),
			Color = NEVE,
			Material = Enum.Material.Plastic,
			Parent = pasta,
		})
	end
end

-- Parede invisível e alta ao longo de uma linha.
local function barreira(pasta: Instance, de: Vector3, ate: Vector3)
	local meio = (de + ate) / 2
	local comprimento = (ate - de).Magnitude
	Mapa.parte({
		Name = "Barreira",
		Size = Vector3.new(2, 200, comprimento + 2),
		CFrame = CFrame.lookAt(meio, ate) + Vector3.new(0, 100, 0),
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
		Parent = pasta,
	})
end

-- Fileira de montanhas de "de" até "ate" (no chão), crescendo para o lado "fora".
-- Uma segunda fileira, mais alta, fica atrás para dar profundidade.
local function cordilheira(pasta: Instance, de: Vector3, ate: Vector3, fora: Vector3, alturaMin: number, alturaMax: number)
	local direcao = (ate - de).Unit
	local comprimento = (ate - de).Magnitude
	local andou = -8
	while andou < comprimento + 8 do
		local largura = aleatorio:NextNumber(22, 32)
		local ponto = de + direcao * andou + fora * (largura / 2 + aleatorio:NextNumber(-1, 3))
		montanha(pasta, ponto, largura, aleatorio:NextNumber(alturaMin, alturaMax))
		andou += largura * aleatorio:NextNumber(0.55, 0.75)
	end
	andou = 0
	while andou < comprimento do
		local largura = aleatorio:NextNumber(30, 42)
		local ponto = de + direcao * andou + fora * (largura / 2 + 22)
		montanha(pasta, ponto, largura, aleatorio:NextNumber(alturaMax, alturaMax * 1.5))
		andou += largura * aleatorio:NextNumber(0.6, 0.8)
	end
	barreira(pasta, de, ate)
end

function Montanhas.construir()
	local pasta = Instance.new("Folder")
	pasta.Name = "Montanhas"

	local fim = Mapa.INICIO_BIOMAS + #Config.BIOMAS * (Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS) + 14
	local inicio = Montanhas.INICIO
	local zb, zf, t = Montanhas.Z_BASES, Montanhas.Z_FASES, Montanhas.TRANSICAO

	for _, lado in { -1, 1 } do
		local fora = Vector3.new(0, 0, lado)
		-- atrás das bases
		cordilheira(pasta, Vector3.new(inicio, 0, lado * zb), Vector3.new(t, 0, lado * zb), fora, 30, 46)
		-- degrau onde a área das bases encontra a estrada das fases
		cordilheira(pasta, Vector3.new(t, 0, lado * (zf + 4)), Vector3.new(t, 0, lado * zb), Vector3.xAxis, 28, 40)
		-- laterais das fases
		cordilheira(pasta, Vector3.new(t, 0, lado * zf), Vector3.new(fim, 0, lado * zf), fora, 24, 38)
	end
	-- começo (atrás do arco) e fim da estrada
	cordilheira(pasta, Vector3.new(inicio, 0, -zb), Vector3.new(inicio, 0, zb), -Vector3.xAxis, 34, 50)
	cordilheira(pasta, Vector3.new(fim, 0, -zf), Vector3.new(fim, 0, zf), Vector3.xAxis, 30, 44)

	pasta.Parent = Workspace
	return pasta
end

return Montanhas

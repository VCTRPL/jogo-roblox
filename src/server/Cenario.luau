-- Cenário de fundo dos biomas: o que se vê por cima das paredes, do lado
-- de fora da estrada das fases. Sem ele o corredor dos biomas ficava
-- flutuando no céu. Cada bioma ganha o chão dele até o horizonte e
-- enfeites grandes no estilo dele: morros e árvores gigantes na Selva, o
-- mar com ilhas e um farol na Praia, pirâmide, mesas e dunas no Deserto,
-- vulcões e lagos de lava no Vulcão, e planetas e asteroides no Espaço.
-- Ninguém chega lá (as paredes têm barreira invisível), então nada aqui
-- tem colisão nem entra em raios: é só para olhar.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Biblioteca = require(script.Parent.Biblioteca)
local Mapa = require(script.Parent.Mapa)

local Cenario = {}

local aleatorio = Random.new(9090)

-- até onde vai o chão de fora (para cada lado da estrada)
local Z_DENTRO = Mapa.Z_PAREDE + 4
local Z_FORA = 420
-- depois do último bioma o Espaço continua um pouco (atrás do portal do fim)
local SOBRA_FIM = 260

local function escolher<T>(lista: { T }): T
	return lista[aleatorio:NextInteger(1, #lista)]
end

local function enfeite(pasta: Instance, nome: string, tamanho: Vector3, cf: CFrame, cor: Color3, props: any?): BasePart
	local p = Mapa.parte({
		Name = nome,
		Size = tamanho,
		CFrame = cf,
		Color = cor,
		Material = Enum.Material.Plastic,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = pasta,
	})
	if props then
		for chave, valor in props do
			(p :: any)[chave] = valor
		end
	end
	return p
end

local function girar(): CFrame
	return CFrame.Angles(0, aleatorio:NextNumber(0, math.pi / 2), 0)
end

-- Ponto sorteado do lado de fora: x entre "de" e "ate", distância da
-- estrada entre "perto" e "longe", no lado "lado".
local function ponto(de: number, ate: number, perto: number, longe: number, lado: number): Vector3
	return Vector3.new(aleatorio:NextNumber(de, ate), 0, lado * aleatorio:NextNumber(perto, longe))
end

-- Morro em degraus: blocos cada vez menores empilhados.
local function degraus(pasta: Instance, chao: Vector3, largura: number, altura: number, andares: number, cores: { Color3 }, nome: string?)
	local h = altura / andares
	local giro = girar()
	for andar = 0, andares - 1 do
		local w = largura * (1 - andar / (andares + 0.6))
		enfeite(
			pasta,
			nome or "Morro",
			Vector3.new(w, h, w * aleatorio:NextNumber(0.75, 1)),
			CFrame.new(chao + Vector3.new(0, h * andar + h / 2, 0)) * giro,
			cores[math.min(andar + 1, #cores)],
			{ CastShadow = false }
		)
	end
end

-- Modelo da biblioteca (montanhas, árvores) se alguém colocou no ReplicatedStorage.
local function daBiblioteca(pasta: Instance, caminho: { string }, chao: Vector3, altura: number): boolean
	local atual: Instance? = ReplicatedStorage
	for _, nome in caminho do
		atual = atual and atual:FindFirstChild(nome)
	end
	local moldes = Biblioteca.moldes(atual)
	if #moldes == 0 then
		return false
	end
	local modelo = Biblioteca.preparar(escolher(moldes), altura)
	if not modelo then
		return false
	end
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			p.CastShadow = false
		end
	end
	modelo:PivotTo(CFrame.new(chao) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0) * modelo:GetPivot())
	modelo.Parent = pasta
	return true
end

-- Árvore gigante de blocos: tronco grosso e copa em camadas.
local function arvoreGigante(pasta: Instance, chao: Vector3, escala: number)
	local altura = 34 * escala
	local verdes = { Color3.fromRGB(60, 150, 60), Color3.fromRGB(80, 175, 65), Color3.fromRGB(50, 130, 60) }
	enfeite(pasta, "Tronco", Vector3.new(5, altura, 5) * Vector3.new(escala, 1, escala), CFrame.new(chao + Vector3.new(0, altura / 2, 0)), Color3.fromRGB(105, 72, 44))
	local giro = girar()
	for camada = 0, 2 do
		local w = (26 - camada * 7) * escala
		enfeite(
			pasta,
			"Copa",
			Vector3.new(w, 8 * escala, w),
			CFrame.new(chao + Vector3.new(0, altura - 4 * escala + camada * 7 * escala, 0)) * giro,
			verdes[camada + 1],
			{ CastShadow = false }
		)
	end
end

-- Palmeira simples de blocos (para as ilhas da praia).
local function palmeira(pasta: Instance, chao: Vector3, escala: number)
	local altura = 16 * escala
	local inclina = CFrame.Angles(math.rad(aleatorio:NextNumber(-10, 10)), 0, math.rad(aleatorio:NextNumber(-10, 10)))
	local base = CFrame.new(chao) * inclina
	enfeite(pasta, "Tronco", Vector3.new(1.6, altura, 1.6) * escala, base * CFrame.new(0, altura / 2, 0), Color3.fromRGB(150, 110, 70))
	for i = 1, 5 do
		enfeite(
			pasta,
			"Folha",
			Vector3.new(2, 0.6, 9) * escala,
			base * CFrame.new(0, altura, 0) * CFrame.Angles(0, math.rad(i * 72), 0) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.new(0, 0, -4 * escala),
			Color3.fromRGB(70, 175, 90),
			{ CastShadow = false }
		)
	end
end

-- Floresta: morros verdes em degraus no fundo e árvores gigantes perto da parede.
local function floresta(pasta: Instance, de: number, ate: number, lado: number)
	local VERDES = { Color3.fromRGB(70, 150, 60), Color3.fromRGB(85, 165, 70), Color3.fromRGB(100, 180, 80), Color3.fromRGB(240, 245, 255) }
	for _ = 1, 3 do
		local chao = ponto(de, ate, 150, 260, lado)
		if not daBiblioteca(pasta, { "ModelosMontanha", "Picos" }, chao, aleatorio:NextNumber(90, 130)) then
			degraus(pasta, chao, aleatorio:NextNumber(80, 120), aleatorio:NextNumber(60, 95), 4, VERDES)
		end
	end
	for _ = 1, 4 do
		degraus(pasta, ponto(de, ate, 95, 150, lado), aleatorio:NextNumber(50, 75), aleatorio:NextNumber(25, 40), 3, VERDES)
	end
	for x = de + 8, ate - 8, 22 do
		arvoreGigante(pasta, Vector3.new(x + aleatorio:NextNumber(-5, 5), 0, lado * aleatorio:NextNumber(68, 88)), aleatorio:NextNumber(0.9, 1.3))
	end
end

-- Praia: o mar até o horizonte, com ilhas de palmeiras, boias e um farol.
local function praia(pasta: Instance, de: number, ate: number, lado: number)
	local AREIA = Color3.fromRGB(235, 215, 160)
	-- faixa de areia encostada na parede e nas pontas
	enfeite(pasta, "Areia", Vector3.new(ate - de, 1, 22), CFrame.new((de + ate) / 2, -0.45, lado * (Z_DENTRO + 11)), AREIA)
	local mar = enfeite(pasta, "Mar", Vector3.new(ate - de - 20, 1, Z_FORA - Z_DENTRO - 22), CFrame.new((de + ate) / 2, -0.2, lado * (Z_DENTRO + 22 + (Z_FORA - Z_DENTRO - 22) / 2)), Color3.fromRGB(45, 160, 225), {
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		Reflectance = 0.1,
	})
	mar:SetAttribute("ManterForma", true)
	for _, x in { de, ate } do
		enfeite(pasta, "Areia", Vector3.new(10, 1, Z_FORA - Z_DENTRO), CFrame.new(x + (if x == de then 5 else -5), -0.45, lado * (Z_DENTRO + (Z_FORA - Z_DENTRO) / 2)), AREIA)
	end
	-- ilhas com palmeiras
	for _ = 1, 3 do
		local chao = ponto(de + 30, ate - 30, 110, 240, lado)
		local raio = aleatorio:NextNumber(14, 24)
		enfeite(pasta, "Ilha", Vector3.new(raio * 2, 2, raio * 1.6), CFrame.new(chao + Vector3.new(0, 0.6, 0)) * girar(), AREIA)
		enfeite(pasta, "Ilha", Vector3.new(raio * 1.3, 2, raio), CFrame.new(chao + Vector3.new(0, 2, 0)) * girar(), Color3.fromRGB(245, 225, 170))
		for _ = 1, aleatorio:NextInteger(2, 3) do
			palmeira(pasta, chao + Vector3.new(aleatorio:NextNumber(-raio / 2, raio / 2), 3, aleatorio:NextNumber(-raio / 3, raio / 3)), aleatorio:NextNumber(1, 1.5))
		end
	end
	-- farol listrado numa pedra, com a luz girando no topo
	local chao = Vector3.new((de + ate) / 2 + lado * 20, 0, lado * 150)
	degraus(pasta, chao, 30, 8, 2, { Color3.fromRGB(140, 135, 125), Color3.fromRGB(160, 155, 145) }, "Pedra")
	for andar = 0, 5 do
		enfeite(pasta, "Farol", Vector3.new(9 - andar * 0.6, 7, 9 - andar * 0.6), CFrame.new(chao + Vector3.new(0, 8 + andar * 7 + 3.5, 0)), if andar % 2 == 0 then Color3.fromRGB(235, 60, 60) else Color3.fromRGB(245, 245, 245))
	end
	local luz = enfeite(pasta, "LuzFarol", Vector3.new(6, 5, 6), CFrame.new(chao + Vector3.new(0, 52.5, 0)), Color3.fromRGB(255, 240, 150), { Material = Enum.Material.Neon })
	luz:SetAttribute("Giro", 90)
	CollectionService:AddTag(luz, "GirarEsteira")
	enfeite(pasta, "TetoFarol", Vector3.new(8, 3, 8), CFrame.new(chao + Vector3.new(0, 56.5, 0)), Color3.fromRGB(40, 40, 50))
	-- boias
	for _ = 1, 6 do
		local boia = ponto(de + 20, ate - 20, 70, 110, lado)
		enfeite(pasta, "Boia", Vector3.new(2.4, 3, 2.4), CFrame.new(boia + Vector3.new(0, 1, 0)), escolher({ Color3.fromRGB(255, 120, 40), Color3.fromRGB(250, 220, 60), Color3.fromRGB(240, 60, 60) }))
	end
end

-- Deserto: dunas, mesas de pedra em camadas e uma pirâmide.
local function deserto(pasta: Instance, de: number, ate: number, lado: number)
	local ARENITO = { Color3.fromRGB(205, 120, 70), Color3.fromRGB(225, 150, 90), Color3.fromRGB(190, 105, 65), Color3.fromRGB(235, 175, 110) }
	local AREIA = { Color3.fromRGB(230, 190, 120), Color3.fromRGB(240, 205, 140), Color3.fromRGB(220, 180, 110) }
	-- pirâmide de um lado, mesas do outro
	if lado == 1 then
		local chao = Vector3.new((de + ate) / 2, 0, 190)
		local andares = 10
		for andar = 0, andares - 1 do
			local w = 110 * (1 - andar / andares)
			enfeite(pasta, "Piramide", Vector3.new(w, 7, w), CFrame.new(chao + Vector3.new(0, andar * 7 + 3.5, 0)), if andar % 2 == 0 then Color3.fromRGB(225, 185, 115) else Color3.fromRGB(210, 170, 100), { CastShadow = false })
		end
		enfeite(pasta, "TopoPiramide", Vector3.new(8, 6, 8), CFrame.new(chao + Vector3.new(0, andares * 7 + 3, 0)), Color3.fromRGB(255, 210, 60), { Material = Enum.Material.Neon })
	else
		for _ = 1, 3 do
			degraus(pasta, ponto(de, ate, 140, 240, lado), aleatorio:NextNumber(50, 80), aleatorio:NextNumber(50, 80), 4, ARENITO, "Mesa")
		end
	end
	for _ = 1, 3 do
		degraus(pasta, ponto(de, ate, 90, 140, lado), aleatorio:NextNumber(40, 60), aleatorio:NextNumber(30, 45), 3, ARENITO, "Mesa")
	end
	-- dunas baixas e compridas
	for _ = 1, 8 do
		local chao = ponto(de, ate, 64, 260, lado)
		local comprimento = aleatorio:NextNumber(40, 80)
		local giro = girar()
		enfeite(pasta, "Duna", Vector3.new(comprimento, 6, 22), CFrame.new(chao + Vector3.new(0, 3, 0)) * giro, escolher(AREIA), { CastShadow = false })
		enfeite(pasta, "Duna", Vector3.new(comprimento * 0.6, 5, 12), CFrame.new(chao + Vector3.new(0, 8, 0)) * giro, escolher(AREIA), { CastShadow = false })
	end
	-- cactos gigantes perto da parede
	for x = de + 15, ate - 10, 30 do
		local chao = Vector3.new(x + aleatorio:NextNumber(-6, 6), 0, lado * aleatorio:NextNumber(66, 85))
		local altura = aleatorio:NextNumber(38, 50)
		local verde = Color3.fromRGB(70, 150, 70)
		local giro = CFrame.new(chao) * girar()
		enfeite(pasta, "Cacto", Vector3.new(6, altura, 6), giro * CFrame.new(0, altura / 2, 0), verde)
		for _, s in { -1, 1 } do
			local y = altura * aleatorio:NextNumber(0.4, 0.6)
			enfeite(pasta, "Cacto", Vector3.new(8, 4, 4), giro * CFrame.new(s * 7, y, 0), verde)
			enfeite(pasta, "Cacto", Vector3.new(4, 14, 4), giro * CFrame.new(s * 9, y + 7, 0), verde)
		end
	end
end

-- Vulcão: vulcões grandes soltando fumaça, lagos de lava e espinhos de pedra.
local function vulcao(pasta: Instance, de: number, ate: number, lado: number)
	local ROCHA = { Color3.fromRGB(70, 55, 55), Color3.fromRGB(60, 48, 48), Color3.fromRGB(80, 62, 60), Color3.fromRGB(52, 42, 42), Color3.fromRGB(90, 60, 50) }
	local LAVA = Color3.fromRGB(255, 110, 30)
	-- o vulcão grande
	local chao = Vector3.new((de + ate) / 2 + lado * 25, 0, lado * 200)
	local andares = 8
	local altura = 110
	for andar = 0, andares - 1 do
		local w = 150 * (1 - andar / (andares + 1.5))
		local h = altura / andares
		enfeite(pasta, "Vulcao", Vector3.new(w, h, w * 0.9), CFrame.new(chao + Vector3.new(0, andar * h + h / 2, 0)) * CFrame.Angles(0, andar * 0.08, 0), ROCHA[andar % #ROCHA + 1], { CastShadow = false })
	end
	local cratera = enfeite(pasta, "LavaVulcao", Vector3.new(26, 2, 24), CFrame.new(chao + Vector3.new(0, altura + 0.5, 0)), LAVA, { Material = Enum.Material.Neon })
	local luz = Instance.new("PointLight")
	luz.Color = LAVA
	luz.Range = 60
	luz.Brightness = 3
	luz.Parent = cratera
	local fumaca = Instance.new("ParticleEmitter")
	fumaca.Texture = "rbxasset://textures/particles/smoke_main.dds"
	fumaca.Color = ColorSequence.new(Color3.fromRGB(70, 60, 60), Color3.fromRGB(130, 120, 120))
	fumaca.Size = NumberSequence.new(14, 40)
	fumaca.Transparency = NumberSequence.new(0.3, 1)
	fumaca.Lifetime = NumberRange.new(8, 12)
	fumaca.Rate = 3
	fumaca.Speed = NumberRange.new(8, 12)
	fumaca.EmissionDirection = Enum.NormalId.Top
	fumaca.Parent = cratera
	-- rios de lava descendo a encosta
	for _, giro in { 0, math.pi * 0.7, math.pi * 1.3 } do
		local direcao = CFrame.Angles(0, giro, 0)
		enfeite(pasta, "RioLava", Vector3.new(6, 1, 70), CFrame.new(chao) * direcao * CFrame.new(0, altura * 0.45, -38) * CFrame.Angles(math.rad(48), 0, 0), LAVA, { Material = Enum.Material.Neon, CastShadow = false })
	end
	-- vulcões menores
	for _ = 1, 3 do
		degraus(pasta, ponto(de, ate, 100, 170, lado), aleatorio:NextNumber(40, 60), aleatorio:NextNumber(30, 50), 4, ROCHA, "Vulcao")
	end
	-- lagos de lava rentes ao chão
	for _ = 1, 4 do
		local lago = ponto(de + 10, ate - 10, 66, 140, lado)
		enfeite(pasta, "LagoLava", Vector3.new(aleatorio:NextNumber(18, 32), 1, aleatorio:NextNumber(12, 22)), CFrame.new(lago + Vector3.new(0, 0.1, 0)) * girar(), LAVA, { Material = Enum.Material.Neon, CastShadow = false })
	end
	-- espinhos de pedra tortos
	for _ = 1, 10 do
		local chao2 = ponto(de, ate, 62, 120, lado)
		local h = aleatorio:NextNumber(25, 55)
		enfeite(pasta, "Espinho", Vector3.new(5, h, 5), CFrame.new(chao2 + Vector3.new(0, h / 2 - 2, 0)) * girar() * CFrame.Angles(math.rad(aleatorio:NextNumber(-12, 12)), 0, math.rad(aleatorio:NextNumber(-12, 12))), escolher(ROCHA))
	end
end

-- Espaço: chão de lua com crateras, um planeta com anel, uma lua e asteroides.
local function espaco(pasta: Instance, de: number, ate: number, lado: number)
	local LUA = { Color3.fromRGB(70, 58, 115), Color3.fromRGB(85, 70, 135), Color3.fromRGB(60, 50, 100) }
	-- crateras: anel de blocos e o fundo escuro
	for _ = 1, 6 do
		local c = ponto(de, ate + SOBRA_FIM, 70, 260, lado)
		local r = aleatorio:NextNumber(12, 26)
		enfeite(pasta, "Cratera", Vector3.new(r * 2, 0.4, r * 2), CFrame.new(c + Vector3.new(0, 0.1, 0)), Color3.fromRGB(35, 28, 60))
		for i = 0, 7 do
			local a = i / 8 * math.pi * 2
			enfeite(pasta, "Cratera", Vector3.new(r * 0.85, 3, 4), CFrame.new(c) * CFrame.Angles(0, a, 0) * CFrame.new(0, 1, -r), escolher(LUA))
		end
	end
	-- planeta grande com anel, de um lado; lua cheia do outro
	if lado == 1 then
		local centro = Vector3.new(ate + 120, 110, 280)
		local roxo = Color3.fromRGB(150, 90, 230)
		for _, tamanho in { Vector3.new(90, 60, 90), Vector3.new(60, 90, 60), Vector3.new(75, 75, 75) } do
			enfeite(pasta, "Planeta", tamanho, CFrame.new(centro), roxo, { CastShadow = false })
		end
		enfeite(pasta, "Faixa", Vector3.new(92, 10, 92), CFrame.new(centro + Vector3.new(0, 14, 0)), Color3.fromRGB(190, 130, 255), { CastShadow = false })
		local anel = enfeite(pasta, "Anel", Vector3.new(170, 2, 170), CFrame.new(centro) * CFrame.Angles(math.rad(18), 0, math.rad(10)), Color3.fromRGB(255, 200, 120), { Transparency = 0.25, CastShadow = false })
		anel:SetAttribute("ManterForma", true)
	else
		local centro = Vector3.new(ate + 60, 170, -280)
		for _, tamanho in { Vector3.new(60, 40, 60), Vector3.new(40, 60, 40), Vector3.new(50, 50, 50) } do
			enfeite(pasta, "Lua", tamanho, CFrame.new(centro), Color3.fromRGB(230, 230, 245), { CastShadow = false })
		end
	end
	-- asteroides flutuando e girando (o cliente anima)
	for _ = 1, 5 do
		local p = ponto(de, ate + SOBRA_FIM, 80, 260, lado) + Vector3.new(0, aleatorio:NextNumber(50, 120), 0)
		local t = aleatorio:NextNumber(8, 20)
		local asteroide = enfeite(pasta, "Asteroide", Vector3.new(t, t * 0.8, t * 1.1), CFrame.new(p) * CFrame.Angles(aleatorio:NextNumber(0, 1), aleatorio:NextNumber(0, 3), 0), escolher(LUA), { CastShadow = false })
		asteroide:SetAttribute("Giro", aleatorio:NextNumber(8, 20))
		asteroide:SetAttribute("Flutua", aleatorio:NextNumber(1, 3))
		CollectionService:AddTag(asteroide, "GirarEsteira")
	end
	-- cristais de neon grandes perto da parede
	for x = de + 10, ate + SOBRA_FIM, 26 do
		local chao = Vector3.new(x + aleatorio:NextNumber(-6, 6), 0, lado * aleatorio:NextNumber(66, 100))
		local cor = escolher({ Color3.fromRGB(80, 220, 255), Color3.fromRGB(200, 90, 255), Color3.fromRGB(255, 100, 200) })
		for _ = 1, 3 do
			local h = aleatorio:NextNumber(14, 34)
			enfeite(pasta, "Cristal", Vector3.new(4, h, 4), CFrame.new(chao + Vector3.new(aleatorio:NextNumber(-4, 4), h / 2 - 2, aleatorio:NextNumber(-4, 4))) * CFrame.Angles(math.rad(aleatorio:NextNumber(-18, 18)), aleatorio:NextNumber(0, 1), math.rad(aleatorio:NextNumber(-18, 18))), cor, { Material = Enum.Material.Neon, CastShadow = false })
		end
	end
end

local ESTILOS = {
	floresta = floresta,
	praia = praia,
	deserto = deserto,
	vulcao = vulcao,
	espaco = espaco,
}

-- Cor do chão de fora de cada bioma (o mar da praia fica por cima).
local CHAO = {
	floresta = { Color3.fromRGB(85, 160, 70), Enum.Material.Grass },
	praia = { Color3.fromRGB(235, 215, 160), Enum.Material.Sand },
	deserto = { Color3.fromRGB(230, 192, 125), Enum.Material.Sand },
	vulcao = { Color3.fromRGB(58, 45, 45), Enum.Material.Basalt },
	espaco = { Color3.fromRGB(55, 45, 90), Enum.Material.Slate },
}

function Cenario.construir(biomas: { Mapa.InfoBioma })
	local pasta = Instance.new("Folder")
	pasta.Name = "Cenario"

	for i, info in biomas do
		local estilo = info.config.estilo
		-- mesmo trecho das paredes de cada bioma (veja Paredes.construir)
		local de = if i == 1 then Mapa.inicioBioma(1) else Mapa.inicioBioma(i) - Mapa.ESPACO_BIOMAS / 2
		local ate = if i == #biomas then Mapa.FIM_ESTRADA + 14 else Mapa.inicioBioma(i) + Mapa.TAMANHO_BIOMA + Mapa.ESPACO_BIOMAS / 2
		local chaoAte = if i == #biomas then ate + SOBRA_FIM else ate
		local chao = CHAO[estilo] or CHAO.floresta
		local pastaBioma = Instance.new("Folder")
		pastaBioma.Name = info.config.nome
		pastaBioma.Parent = pasta
		for _, lado in { -1, 1 } do
			if estilo ~= "praia" then
				enfeite(pastaBioma, "Chao", Vector3.new(chaoAte - de, 1, Z_FORA - Z_DENTRO), CFrame.new((de + chaoAte) / 2, -0.45, lado * (Z_DENTRO + Z_FORA) / 2), chao[1], { Material = chao[2], CastShadow = false })
			end
			;(ESTILOS[estilo] or floresta)(pastaBioma, de, ate, lado)
		end
		if i == #biomas then
			-- atrás da parede do fim, de um lado ao outro
			local x = ate + 14
			enfeite(pastaBioma, "Chao", Vector3.new(chaoAte - x, 1, Z_DENTRO * 2), CFrame.new((x + chaoAte) / 2, -0.45, 0), chao[1], { Material = chao[2], CastShadow = false })
		end
	end

	pasta.Parent = Workspace
	return pasta
end

return Cenario

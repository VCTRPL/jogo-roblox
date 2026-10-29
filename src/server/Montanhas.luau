-- Montanhas de blocos fechando o mapa: em volta da área das bases e dos
-- dois lados da estrada das fases, para ninguém sair pelas laterais. Cada
-- montanha tem dois ou três picos em degraus (grama embaixo, pedra no meio
-- e neve no alto), pinheiros nas encostas, pedras no pé e, de vez em
-- quando, uma cachoeira. Atrás de cada fileira tem uma parede invisível bem
-- alta, então nem pulando pelos degraus dá para passar.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Biblioteca = require(script.Parent.Biblioteca)
local Mapa = require(script.Parent.Mapa)

local Montanhas = {}

-- Até onde vai cada área (as linhas internas das montanhas).
Montanhas.INICIO = Mapa.INICIO_ESTRADA - 20 -- atrás do túnel da entrada
Montanhas.Z_BASES = Mapa.Z_BASES + Mapa.TAMANHO_BASE / 2 + 18 -- sobra espaço para árvores atrás das bases
Montanhas.Z_FASES = Mapa.Z_PAREDE + 8 -- atrás das paredes dos biomas
Montanhas.TRANSICAO = Mapa.FIM_BASES -- onde a área das bases vira estrada das fases

local aleatorio = Random.new(4321)

local GRAMA = { Color3.fromRGB(100, 185, 75), Color3.fromRGB(85, 165, 65), Color3.fromRGB(115, 195, 85) }
local TERRA = { Color3.fromRGB(150, 110, 75), Color3.fromRGB(135, 98, 66) }
local PEDRA = { Color3.fromRGB(150, 150, 160), Color3.fromRGB(128, 128, 140), Color3.fromRGB(165, 160, 152), Color3.fromRGB(140, 132, 125) }
local NEVE = Color3.fromRGB(245, 248, 255)
local PINHEIRO = { Color3.fromRGB(40, 120, 70), Color3.fromRGB(55, 140, 75), Color3.fromRGB(35, 105, 60) }

local function escolher<T>(lista: { T }): T
	return lista[aleatorio:NextInteger(1, #lista)]
end

local function bloco(pasta: Instance, nome: string, tamanho: Vector3, cf: CFrame, cor: Color3, props: any?): BasePart
	local p = Mapa.parte({
		Name = nome,
		Size = tamanho,
		CFrame = cf,
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

-- Pinheirinho de blocos: tronco e três andares de folhas.
local function pinheiro(pasta: Instance, chao: Vector3, escala: number)
	local cor = escolher(PINHEIRO)
	bloco(pasta, "Pinheiro", Vector3.new(0.8, 2, 0.8) * escala, CFrame.new(chao + Vector3.new(0, escala, 0)), Color3.fromRGB(110, 75, 45), { CanCollide = false })
	local giro = aleatorio:NextNumber(0, math.pi / 2)
	for andar = 0, 2 do
		local largura = (4.2 - andar * 1.2) * escala
		bloco(
			pasta,
			"Pinheiro",
			Vector3.new(largura, 1.4 * escala, largura),
			CFrame.new(chao + Vector3.new(0, (2.3 + andar * 1.3) * escala, 0)) * CFrame.Angles(0, giro + andar * 0.4, 0),
			cor:Lerp(Color3.new(1, 1, 1), andar * 0.05),
			{ CanCollide = false }
		)
	end
end

-- Cachoeira descendo pela encosta virada para "dentro", com espuma e um laguinho.
local function cachoeira(pasta: Instance, topo: Vector3, dentro: Vector3, altura: number)
	local olhar = CFrame.lookAt(topo, topo + dentro)
	local queda = bloco(pasta, "Cachoeira", Vector3.new(3.5, altura, 1), olhar * CFrame.new(0, -altura / 2, -0.6), Color3.fromRGB(110, 190, 255), {
		Material = Enum.Material.Glass,
		Transparency = 0.25,
		CanCollide = false,
		CastShadow = false,
	})
	local espuma = bloco(pasta, "Espuma", Vector3.new(6, 1, 4), olhar * CFrame.new(0, -altura + 0.4, -2.5), Color3.fromRGB(240, 250, 255), { CanCollide = false })
	bloco(pasta, "Lago", Vector3.new(10, 0.3, 7), olhar * CFrame.new(0, -altura + 0.1, -5), Color3.fromRGB(80, 170, 235), {
		Material = Enum.Material.Glass,
		Transparency = 0.2,
		CanCollide = false,
		CastShadow = false,
	})
	local respingo = Instance.new("ParticleEmitter")
	respingo.Texture = "rbxasset://textures/particles/smoke_main.dds"
	respingo.Color = ColorSequence.new(Color3.new(1, 1, 1))
	respingo.Transparency = NumberSequence.new(0.4, 1)
	respingo.Size = NumberSequence.new(1.5, 4)
	respingo.Lifetime = NumberRange.new(0.8, 1.4)
	respingo.Speed = NumberRange.new(2, 4)
	respingo.Rate = 8
	respingo.Parent = espuma
	CollectionService:AddTag(queda, "PulsarEsteira") -- brilha de leve, como água correndo
end

-- Um pico em degraus. Devolve o ponto no topo dele e a altura do primeiro degrau.
local function pico(pasta: Instance, chao: Vector3, largura: number, altura: number, enfeitar: boolean): (Vector3, number)
	local andares = aleatorio:NextInteger(3, 5)
	local y = 0
	local w, d = largura, largura * aleatorio:NextNumber(0.8, 1.05)
	local centro = chao
	local giro = CFrame.Angles(0, aleatorio:NextNumber(-0.15, 0.15), 0)
	local primeiro = 0
	for andar = 1, andares do
		local h = altura / andares * aleatorio:NextNumber(0.85, 1.2)
		if andar == 1 then
			primeiro = h
		end
		local fracao = andar / andares
		local neve = altura >= 30 and fracao > 0.8
		local cor = if neve then NEVE elseif fracao <= 0.34 then escolher(GRAMA) elseif fracao <= 0.5 then escolher(TERRA) else escolher(PEDRA)
		bloco(pasta, "Montanha", Vector3.new(w, h, d), CFrame.new(centro + Vector3.new(0, y + h / 2, 0)) * giro, cor)
		-- tampa de grama nos degraus de baixo e neve nos de cima
		if not neve and fracao <= 0.5 then
			bloco(pasta, "Montanha", Vector3.new(w + 0.6, 0.8, d + 0.6), CFrame.new(centro + Vector3.new(0, y + h - 0.3, 0)) * giro, escolher(GRAMA))
		elseif not neve and altura >= 30 and fracao > 0.6 then
			bloco(pasta, "Neve", Vector3.new(w * 0.9, 0.6, d * 0.9), CFrame.new(centro + Vector3.new(0, y + h + 0.2, 0)) * giro, NEVE)
		end
		-- pinheiros na borda dos degraus de grama
		if enfeitar and fracao <= 0.5 and aleatorio:NextNumber() < 0.6 then
			for _ = 1, aleatorio:NextInteger(1, 2) do
				local angulo = aleatorio:NextNumber(0, math.pi * 2)
				-- perto da borda do degrau (o de cima é mais estreito)
				local borda = Vector3.new(math.cos(angulo) * w, 0, math.sin(angulo) * d) * 0.42
				pinheiro(pasta, centro + borda + Vector3.new(0, y + h + 0.1, 0), aleatorio:NextNumber(0.8, 1.3))
			end
		end
		y += h
		w *= aleatorio:NextNumber(0.62, 0.78)
		d *= aleatorio:NextNumber(0.62, 0.78)
		centro += Vector3.new(aleatorio:NextNumber(-0.12, 0.12) * w, 0, aleatorio:NextNumber(-0.12, 0.12) * d)
	end
	if altura >= 34 then
		bloco(pasta, "Neve", Vector3.new(w * 1.25, 2, d * 1.25), CFrame.new(centro + Vector3.new(0, y + 0.6, 0)) * giro, NEVE)
	end
	return centro + Vector3.new(0, y, 0), primeiro
end

-- Montanhas da biblioteca do Roblox (ReplicatedStorage.ModelosMontanha, veja
-- docs/modelos-da-biblioteca.md): "Penhascos" na fileira da frente e "Picos"
-- nevados atrás. Sem essa pasta, ficam as montanhas de blocos daqui de cima.
local pastaModelos = ReplicatedStorage:FindFirstChild("ModelosMontanha")
local PENHASCOS = Biblioteca.moldes(pastaModelos and pastaModelos:FindFirstChild("Penhascos"))
local PICOS = Biblioteca.moldes(pastaModelos and pastaModelos:FindFirstChild("Picos"))
local cachoeirasPendentes: { () -> () } = {}

-- Põe um modelo da biblioteca com "largura" de base e "altura", girado ao
-- acaso, com o pé no meio em "chao". As peças desses modelos só giram em
-- volta do eixo Y, então dá para esticar cada uma na altura.
local function modeloMontanha(pasta: Instance, moldes: { Model }, chao: Vector3, largura: number, altura: number): Model?
	local modelo = Biblioteca.preparar(escolher(moldes), 10)
	if not modelo then
		return nil
	end
	modelo:PivotTo(CFrame.Angles(0, aleatorio:NextNumber(0, math.pi * 2), 0) * modelo:GetPivot())
	local menor, maior = Biblioteca.limites(modelo)
	modelo:ScaleTo(modelo:GetScale() * largura / math.max(maior.X - menor.X, maior.Z - menor.Z))
	menor, maior = Biblioteca.limites(modelo)
	local fator = altura / (maior.Y - menor.Y)
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			local y = p.Position.Y - menor.Y
			p.Size = Vector3.new(p.Size.X, p.Size.Y * fator, p.Size.Z)
			p.Position = Vector3.new(p.Position.X, menor.Y + y * fator, p.Position.Z)
		end
	end
	menor, maior = Biblioteca.limites(modelo)
	local pes = Vector3.new((menor.X + maior.X) / 2, menor.Y, (menor.Z + maior.Z) / 2)
	modelo:PivotTo(modelo:GetPivot() + (chao - pes))
	modelo.Parent = pasta
	return modelo
end

-- Empurra o modelo na direção "fora" até a borda de dentro dele ficar na
-- "linha" (medida ao longo de "fora").
local function encostar(modelo: Model, fora: Vector3, linha: number)
	local menor, maior = Biblioteca.limites(modelo)
	local borda = math.min(menor:Dot(fora), maior:Dot(fora))
	modelo:PivotTo(modelo:GetPivot() + fora * (linha - borda))
end

-- Cachoeira presa na encosta de verdade: um raio sai de dentro do mapa, na
-- altura escolhida, até bater numa face do modelo virada para dentro e perto
-- da "linha" (nada de fresta lá no fundo). A água desce dali até o primeiro
-- degrau do modelo que tiver embaixo, ou até o chão.
local function cachoeiraNaEncosta(pasta: Instance, modelo: Model, ponto: Vector3, fora: Vector3, linha: number)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { modelo }
	local pecas = {}
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanQuery = true
			table.insert(pecas, p)
		end
	end
	local _, maior = Biblioteca.limites(modelo)
	local altura = (maior.Y - ponto.Y) * aleatorio:NextNumber(0.3, 0.45)
	local inicio = ponto - fora * 30 + Vector3.new(0, altura, 0)
	local batida = Workspace:Raycast(inicio, fora * 120, params)
	local embaixo = nil
	local valida = batida ~= nil
		and batida.Position.Y > 8
		and batida.Position:Dot(fora) < linha + 8
		and batida.Normal:Dot(-fora) > 0.6
	if valida then
		embaixo = Workspace:Raycast(batida.Position - fora * 1.2, Vector3.new(0, -200, 0), params)
	end
	for _, p in pecas do
		p.CanQuery = false
	end
	if valida then
		local base = if embaixo then embaixo.Position.Y else ponto.Y
		local queda = batida.Position.Y - base
		if queda > 6 then
			cachoeira(pasta, batida.Position, -fora, queda)
		end
	end
end

-- Uma montanha: um pico principal e um ou dois menores encostados, pedras
-- no pé e, às vezes, uma cachoeira virada para "dentro" (onde o jogador está).
local function montanha(pasta: Instance, chao: Vector3, largura: number, altura: number, dentro: Vector3?)
	if #PENHASCOS > 0 then
		modeloMontanha(pasta, PENHASCOS, chao, largura, altura)
		return
	end
	local enfeitar = dentro ~= nil
	local _, primeiro = pico(pasta, chao, largura, altura, enfeitar)
	for _ = 1, aleatorio:NextInteger(1, 2) do
		local angulo = aleatorio:NextNumber(0, math.pi * 2)
		local lado = Vector3.new(math.cos(angulo), 0, math.sin(angulo)) * largura * aleatorio:NextNumber(0.3, 0.45)
		pico(pasta, chao + lado, largura * aleatorio:NextNumber(0.45, 0.65), altura * aleatorio:NextNumber(0.45, 0.7), enfeitar)
	end
	if dentro then
		-- pedras no pé, do lado de dentro
		for _ = 1, aleatorio:NextInteger(1, 3) do
			local deLado = Vector3.new(-dentro.Z, 0, dentro.X) -- ao longo da fileira
			local p = chao + dentro * largura * 0.55 + deLado * aleatorio:NextNumber(-0.4, 0.4) * largura
			local t = aleatorio:NextNumber(1.5, 3.5)
			bloco(pasta, "Pedra", Vector3.new(t * 1.4, t, t * 1.1), CFrame.new(p + Vector3.new(0, t * 0.4, 0)) * CFrame.Angles(0, aleatorio:NextNumber(0, math.pi), 0), escolher(PEDRA))
		end
		if altura >= 32 and aleatorio:NextNumber() < 0.12 then
			-- desce do alto do primeiro degrau (os de cima são mais estreitos e a
			-- água ficava solta no ar na frente deles)
			local alturaQueda = primeiro
			cachoeira(pasta, chao + dentro * (largura * 0.5 - 0.5) + Vector3.new(0, alturaQueda, 0), dentro, alturaQueda)
		end
	end
end

-- Parede invisível e alta ao longo de uma linha.
local function barreira(pasta: Instance, de: Vector3, ate: Vector3, grossura: number?)
	local meio = (de + ate) / 2
	local comprimento = (ate - de).Magnitude
	Mapa.parte({
		Name = "Barreira",
		Size = Vector3.new(grossura or 2, 200, comprimento + 2),
		CFrame = CFrame.lookAt(meio, ate) + Vector3.new(0, 100, 0),
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
		Parent = pasta,
	})
end

-- Fileira de montanhas de "de" até "ate" (no chão), crescendo para o lado "fora".
-- Uma segunda fileira, mais alta e sem enfeites, fica atrás para dar profundidade.
local function cordilheira(pasta: Instance, de: Vector3, ate: Vector3, fora: Vector3, alturaMin: number, alturaMax: number)
	if #PENHASCOS > 0 and #PICOS > 0 then
		-- com os modelos da biblioteca: penhascos encostados na linha e picos
		-- nevados mais altos atrás, sem buraco entre eles
		local direcao = (ate - de).Unit
		local comprimento = (ate - de).Magnitude
		local linha = de:Dot(fora)
		local andou = -10
		while andou < comprimento + 10 do
			local largura = aleatorio:NextNumber(32, 46)
			local ponto = de + direcao * andou
			local modelo = modeloMontanha(pasta, PENHASCOS, ponto, largura, aleatorio:NextNumber(alturaMin, alturaMax))
			if modelo then
				encostar(modelo, fora, linha + 1)
				if aleatorio:NextNumber() < 0.3 then
					-- o raio só acha o modelo depois que ele estiver no Workspace
					table.insert(cachoeirasPendentes, function()
						cachoeiraNaEncosta(pasta, modelo, ponto, fora, linha)
					end)
				end
			end
			andou += largura * aleatorio:NextNumber(0.5, 0.65)
		end
		andou = -20
		while andou < comprimento + 20 do
			local largura = aleatorio:NextNumber(55, 75)
			local modelo = modeloMontanha(pasta, PICOS, de + direcao * andou, largura, aleatorio:NextNumber(alturaMax * 1.25, alturaMax * 1.7))
			if modelo then
				encostar(modelo, fora, linha + 16)
			end
			andou += largura * aleatorio:NextNumber(0.45, 0.6)
		end
		barreira(pasta, de, ate)
		return
	end
	local direcao = (ate - de).Unit
	local comprimento = (ate - de).Magnitude
	local andou = -8
	while andou < comprimento + 8 do
		local largura = aleatorio:NextNumber(22, 32)
		local ponto = de + direcao * andou + fora * (largura / 2 + aleatorio:NextNumber(-1, 3))
		montanha(pasta, ponto, largura, aleatorio:NextNumber(alturaMin, alturaMax), -fora)
		andou += largura * aleatorio:NextNumber(0.55, 0.75)
	end
	andou = 0
	while andou < comprimento do
		local largura = aleatorio:NextNumber(30, 42)
		local ponto = de + direcao * andou + fora * (largura / 2 + 22)
		pico(pasta, ponto, largura, aleatorio:NextNumber(alturaMax, alturaMax * 1.5), false)
		andou += largura * aleatorio:NextNumber(0.6, 0.8)
	end
	barreira(pasta, de, ate)
end

-- Montanha da frente, onde a estrada sai do túnel: uma fileira que vai de
-- uma lateral à outra encostada na boca do túnel (sem cobrir a passagem),
-- um morro em cima do túnel e uma parede invisível na frente, para ninguém
-- escalar e sair do mapa.
local function montanhaDoTunel(pasta: Instance)
	local boca = Mapa.TUNEL_BOCA
	local fundo = Montanhas.INICIO
	local zb = Montanhas.Z_BASES
	local meia = Mapa.TUNEL_LARGURA / 2
	local altura = Mapa.TUNEL_ALTURA
	local LIVRE = meia + 3 -- metade do túnel com as paredes, com folga

	local z = -zb - 8
	while z < zb + 8 do
		local largura = aleatorio:NextNumber(22, 32)
		-- até onde a montanha (com os picos menores do lado) pode ir para os lados
		local alcance = largura * 0.85
		local zc = z
		if math.abs(zc) < LIVRE + alcance then
			zc = (if zc < 0 then -1 else 1) * (LIVRE + alcance)
		end
		local ponto = Vector3.new(boca - largura / 2 + 1, 0, zc)
		montanha(pasta, ponto, largura, aleatorio:NextNumber(32, 44), Vector3.xAxis)
		z += largura * aleatorio:NextNumber(0.55, 0.75)
	end

	-- terra dos lados e em cima do túnel, fechando os buracos
	local comprimento = boca - fundo
	local meio = (boca + fundo) / 2
	for _, lado in { -1, 1 } do
		Mapa.parte({
			Name = "Montanha",
			Size = Vector3.new(comprimento, altura + 4, 8),
			Position = Vector3.new(meio, (altura + 4) / 2, lado * (meia + 6.5)),
			Color = TERRA[1],
			Material = Enum.Material.Plastic,
			Parent = pasta,
		})
	end
	Mapa.parte({
		Name = "Montanha",
		Size = Vector3.new(comprimento, 10, meia * 2 + 18),
		Position = Vector3.new(meio, altura + 9, 0),
		Color = escolher(GRAMA),
		Material = Enum.Material.Plastic,
		Parent = pasta,
	})
	if #PICOS > 0 then
		modeloMontanha(pasta, PICOS, Vector3.new(meio - 4, altura + 14, 0), 34, 30)
	else
		pico(pasta, Vector3.new(meio - 4, altura + 14, 0), 32, 28, true)
	end

	-- parede invisível na frente da montanha, deixando a boca do túnel livre.
	-- Bem grossa (para dentro da montanha) para ninguém atravessar correndo.
	local GROSSURA = 16
	local x = boca + 1.5 - GROSSURA / 2
	for _, lado in { -1, 1 } do
		barreira(pasta, Vector3.new(x, 0, lado * (meia + 1)), Vector3.new(x, 0, lado * (zb + 2)), GROSSURA)
	end
	Mapa.parte({
		Name = "Barreira",
		Size = Vector3.new(GROSSURA, 200, meia * 2 + 4),
		Position = Vector3.new(x, altura + 100, 0),
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
		Parent = pasta,
	})
end

function Montanhas.construir()
	local pasta = Instance.new("Folder")
	pasta.Name = "Montanhas"

	local fim = Mapa.FIM_ESTRADA + 14
	local inicio = Montanhas.INICIO
	local zb, t = Montanhas.Z_BASES, Montanhas.TRANSICAO

	for _, lado in { -1, 1 } do
		local fora = Vector3.new(0, 0, lado)
		-- atrás das bases
		cordilheira(pasta, Vector3.new(inicio, 0, lado * zb), Vector3.new(t, 0, lado * zb), fora, 30, 46)
		-- degrau onde a área das bases encontra a estrada das fases
		cordilheira(pasta, Vector3.new(t, 0, lado * Mapa.Z_PAREDE), Vector3.new(t, 0, lado * zb), Vector3.xAxis, 28, 40)
		-- nas laterais dos biomas não tem montanha: as paredes deles são altas (Paredes)
	end
	-- começo (o túnel entra na montanha) e fim da estrada
	montanhaDoTunel(pasta)
	cordilheira(pasta, Vector3.new(inicio, 0, -zb), Vector3.new(inicio, 0, zb), -Vector3.xAxis, 34, 50)
	-- o fim da estrada é a parede com o portal "em breve" (Decoracao)

	pasta.Parent = Workspace
	for _, fazer in cachoeirasPendentes do
		fazer()
	end
	table.clear(cachoeirasPendentes)
	return pasta
end

return Montanhas

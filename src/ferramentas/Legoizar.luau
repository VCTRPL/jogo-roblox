-- Conversor Lego: transforma modelos da biblioteca do Roblox (Toolbox /
-- Creator Store) em modelos feitos só de blocos com pinos, no estilo do
-- resto do mapa. O modelo é "fatiado" numa grade de cubinhos; cada cubinho
-- que fica dentro do modelo vira um bloco com a cor da peça daquele lugar, e
-- os blocos vizinhos da mesma cor são juntados em blocos maiores.
--
-- Como usar (no Studio, com o jogo parado):
--   1. Crie em ServerStorage a pasta "Originais" com as subpastas
--      "Brainrot", "Ovo" e "Chefao".
--   2. Ponha os modelos da Toolbox nelas, com o nome igual ao do Config:
--      o "id" do Brainrot (ex.: "Tralalero"), o "id" do ovo (ex.:
--      "OvoTralalero") ou o nome do guardião (ex.: "Tung Tung Tung Sahur").
--   3. Na barra de comandos (View > Command Bar), rode:
--        require(game.ServerStorage.Ferramentas.Legoizar).converterTudo()
--   4. Os modelos de blocos aparecem em ReplicatedStorage.ModelosBrainrot,
--      ModelosOvo e ModelosChefao, e a pasta "Originais" é apagada (os
--      originais não vão junto quando você publicar o jogo).
--   5. Salve com File > Publish to Roblox.
--
-- Cor: o jogo não consegue ler a imagem (textura) de um modelo. Peças com
-- textura ficam com as cores do Config (corpo embaixo, cabeça em cima);
-- depois dá para pintar os blocos à mão no Studio.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Legoizar = {}

export type Opcoes = {
	altura: number, -- altura final em studs
	resolucao: number?, -- quantos blocos de altura (mais = mais detalhe e mais peças)
	corBaixo: Color3?, -- cor das peças com textura, na parte de baixo
	corCima: Color3?, -- e na parte de cima
	divisa: number?, -- de 0 a 1: onde muda de corBaixo para corCima
	alturaMaximaBloco: number?, -- quantos cubinhos um bloco pode juntar na vertical
}

-- Cores de peças de Lego. Cada cubinho pega a mais parecida, para o
-- modelo ficar com cara de brinquedo e juntar mais blocos.
local PALETA = {
	Color3.fromRGB(242, 243, 243), -- branco
	Color3.fromRGB(160, 165, 169), -- cinza claro
	Color3.fromRGB(99, 95, 98), -- cinza escuro
	Color3.fromRGB(27, 42, 53), -- preto
	Color3.fromRGB(196, 40, 28), -- vermelho
	Color3.fromRGB(255, 102, 204), -- rosa
	Color3.fromRGB(255, 176, 196), -- rosa claro
	Color3.fromRGB(218, 133, 65), -- laranja
	Color3.fromRGB(245, 205, 48), -- amarelo
	Color3.fromRGB(248, 241, 132), -- amarelo claro
	Color3.fromRGB(75, 151, 75), -- verde
	Color3.fromRGB(164, 189, 71), -- verde-limão
	Color3.fromRGB(39, 70, 45), -- verde escuro
	Color3.fromRGB(13, 105, 172), -- azul
	Color3.fromRGB(110, 153, 202), -- azul claro
	Color3.fromRGB(0, 143, 156), -- turquesa
	Color3.fromRGB(107, 50, 124), -- roxo
	Color3.fromRGB(124, 92, 70), -- marrom
	Color3.fromRGB(86, 66, 54), -- marrom escuro
	Color3.fromRGB(215, 197, 154), -- areia
	Color3.fromRGB(234, 184, 146), -- pele
	Color3.fromRGB(204, 142, 105), -- pele escura
}

local function maisParecida(cor: Color3): number
	local melhor, menor = 1, math.huge
	for i, opcao in PALETA do
		local dr, dg, db = cor.R - opcao.R, cor.G - opcao.G, cor.B - opcao.B
		-- o olho vê mais diferença no verde
		local distancia = dr * dr * 0.3 + dg * dg * 0.59 + db * db * 0.11
		if distancia < menor then
			melhor, menor = i, distancia
		end
	end
	return melhor
end

-- Caixa alinhada com o mundo em volta das peças visíveis.
local function limites(modelo: Instance): (Vector3, Vector3)
	local menor = Vector3.one * math.huge
	local maior = -Vector3.one * math.huge
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.9 then
			local cf, meio = p.CFrame, p.Size / 2
			local alcance = Vector3.new(
				math.abs(cf.XVector.X) * meio.X + math.abs(cf.YVector.X) * meio.Y + math.abs(cf.ZVector.X) * meio.Z,
				math.abs(cf.XVector.Y) * meio.X + math.abs(cf.YVector.Y) * meio.Y + math.abs(cf.ZVector.Y) * meio.Z,
				math.abs(cf.XVector.Z) * meio.X + math.abs(cf.YVector.Z) * meio.Y + math.abs(cf.ZVector.Z) * meio.Z
			)
			menor = menor:Min(cf.Position - alcance)
			maior = maior:Max(cf.Position + alcance)
		end
	end
	return menor, maior
end

-- A peça tem textura (imagem)? Aí a cor dela não diz nada.
local function temTextura(p: BasePart): boolean
	if p:FindFirstChildOfClass("SurfaceAppearance") then
		return true
	end
	if p:IsA("MeshPart") and p.TextureID ~= "" then
		return true
	end
	local malha = p:FindFirstChildOfClass("SpecialMesh")
	return malha ~= nil and malha.TextureId ~= ""
end

-- Deixa a cópia pronta para ser "fatiada": sem scripts, ancorada, olhando
-- para -Z, do tamanho pedido e com a colisão igual ao desenho.
local function prepararCopia(molde: Model, altura: number): Model
	local copia = molde:Clone()
	for _, objeto in copia:GetDescendants() do
		if objeto:IsA("LuaSourceContainer") or objeto:IsA("Sound") then
			objeto:Destroy()
		end
	end
	local avisouMalha = false
	for _, p in copia:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = p.Transparency < 0.9
			-- colisão precisa (só funciona no Studio, por isso o pcall)
			pcall(function()
				(p :: any).CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
			end)
			if not avisouMalha and p:FindFirstChildOfClass("SpecialMesh") then
				avisouMalha = true
				warn(`{molde.Name}: tem SpecialMesh; essas peças viram caixas. Prefira modelos com MeshPart.`)
			end
		end
	end

	-- vira para -Z pela frente da peça principal
	local raiz = copia.PrimaryPart or copia:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		local olhar = raiz.CFrame.LookVector * Vector3.new(1, 0, 1)
		if olhar.Magnitude > 0.1 then
			copia:PivotTo(CFrame.lookAt(Vector3.zero, olhar.Unit):Inverse() * copia:GetPivot())
		end
	end
	local menor, maior = limites(copia)
	if maior.Y - menor.Y > 0.01 then
		copia:ScaleTo(copia:GetScale() * altura / (maior.Y - menor.Y))
	end
	-- longe de tudo, para as consultas só acharem o próprio modelo
	menor, maior = limites(copia)
	local pes = Vector3.new((menor.X + maior.X) / 2, menor.Y, (menor.Z + maior.Z) / 2)
	copia:PivotTo(copia:GetPivot() + (Vector3.new(0, 5000, 0) - pes))
	copia.Parent = Workspace
	return copia
end

function Legoizar.converter(molde: Model, opcoes: Opcoes): Model
	local resolucao = opcoes.resolucao or 22
	local tamanho = opcoes.altura / resolucao
	local corBaixo = opcoes.corBaixo or Color3.fromRGB(160, 165, 169)
	local corCima = opcoes.corCima or corBaixo
	local divisa = opcoes.divisa or 0.55
	local alturaMaxima = opcoes.alturaMaximaBloco or 2

	local copia = prepararCopia(molde, opcoes.altura)
	task.wait() -- deixa o Studio refazer a colisão das peças
	local menor, maior = limites(copia)
	local nx = math.max(1, math.ceil((maior.X - menor.X) / tamanho))
	local ny = math.max(1, math.ceil((maior.Y - menor.Y) / tamanho))
	local nz = math.max(1, math.ceil((maior.Z - menor.Z) / tamanho))
	local origem = Vector3.new(
		(menor.X + maior.X) / 2 - nx * tamanho / 2,
		menor.Y,
		(menor.Z + maior.Z) / 2 - nz * tamanho / 2
	)

	local sonda = Instance.new("Part")
	sonda.Anchored = true
	sonda.CanCollide = false
	sonda.CanQuery = false
	sonda.Transparency = 1
	sonda.Size = Vector3.one * tamanho * 0.8
	sonda.Parent = Workspace
	local parametros = OverlapParams.new()
	parametros.FilterType = Enum.RaycastFilterType.Include
	parametros.FilterDescendantsInstances = { copia }

	-- grade[x][y][z] = índice da cor na paleta (nil = vazio)
	local grade: { { { number? } } } = {}
	local cheios = 0
	for x = 1, nx do
		grade[x] = {}
		for y = 1, ny do
			grade[x][y] = {}
			for z = 1, nz do
				sonda.Position = origem + Vector3.new(x - 0.5, y - 0.5, z - 0.5) * tamanho
				local pecas = Workspace:GetPartsInPart(sonda, parametros)
				-- a menor peça ganha: olhos e detalhes ficam por cima do corpo
				local escolhida: BasePart? = nil
				for _, p in pecas do
					if not escolhida or p.Size.Magnitude < escolhida.Size.Magnitude then
						escolhida = p
					end
				end
				if escolhida then
					local cor = escolhida.Color
					if temTextura(escolhida) then
						cor = if (y - 0.5) / ny < divisa then corBaixo else corCima
					end
					grade[x][y][z] = maisParecida(cor)
					cheios += 1
				end
			end
		end
		if x % 4 == 0 then
			task.wait()
		end
	end
	sonda:Destroy()
	copia:Destroy()

	-- Junta cubinhos da mesma cor em blocos (primeiro em X, depois Z, depois Y).
	local usado: { [number]: boolean } = {}
	local function chave(x: number, y: number, z: number): number
		return (y * (nz + 1) + z) * (nx + 1) + x
	end
	local function livre(x: number, y: number, z: number, cor: number): boolean
		return x <= nx and y <= ny and z <= nz and grade[x][y][z] == cor and not usado[chave(x, y, z)]
	end

	local modelo = Instance.new("Model")
	modelo.Name = molde.Name
	local pecas = 0
	for y = 1, ny do
		for z = 1, nz do
			for x = 1, nx do
				local cor = grade[x][y][z]
				if cor and not usado[chave(x, y, z)] then
					local w = 1
					while livre(x + w, y, z, cor) do
						w += 1
					end
					local d = 1
					local function linhaLivre(zz: number, yy: number): boolean
						for xx = x, x + w - 1 do
							if not livre(xx, yy, zz, cor) then
								return false
							end
						end
						return true
					end
					while linhaLivre(z + d, y) do
						d += 1
					end
					local h = 1
					local function camadaLivre(yy: number): boolean
						for zz = z, z + d - 1 do
							if not linhaLivre(zz, yy) then
								return false
							end
						end
						return true
					end
					while h < alturaMaxima and camadaLivre(y + h) do
						h += 1
					end
					for yy = y, y + h - 1 do
						for zz = z, z + d - 1 do
							for xx = x, x + w - 1 do
								usado[chave(xx, yy, zz)] = true
							end
						end
					end

					local bloco = Instance.new("Part")
					bloco.Name = "Bloco"
					bloco.Anchored = true
					bloco.CanCollide = false
					bloco.CanTouch = false
					bloco.Size = Vector3.new(w, h, d) * tamanho
					bloco.Position = origem + (Vector3.new(x - 1, y - 1, z - 1) + Vector3.new(w, h, d) / 2) * tamanho - Vector3.new(0, 5000, 0)
					bloco.Color = PALETA[cor]
					bloco.Material = Enum.Material.Plastic
					bloco.TopSurface = Enum.SurfaceType.Studs
					bloco.BottomSurface = Enum.SurfaceType.Inlet
					bloco.Parent = modelo
					pecas += 1
				end
			end
		end
	end

	if pecas == 0 then
		warn(`{molde.Name}: nenhum bloco gerado (o modelo tem peças visíveis?).`)
	end
	-- peça principal: a maior, perto do meio
	local maiorBloco: BasePart? = nil
	for _, p in modelo:GetChildren() do
		if p:IsA("BasePart") and (not maiorBloco or p.Size.Magnitude > maiorBloco.Size.Magnitude) then
			maiorBloco = p
		end
	end
	modelo.PrimaryPart = maiorBloco
	modelo:SetAttribute("Legoizado", true)
	print(`{molde.Name}: {cheios} cubinhos viraram {pecas} blocos.`)
	return modelo
end

-- Converte tudo que estiver em ServerStorage.Originais (veja o começo do arquivo).
function Legoizar.converterTudo(apagarOriginais: boolean?)
	local originais = ServerStorage:FindFirstChild("Originais")
	if not originais then
		warn("Crie a pasta ServerStorage.Originais (com Brainrot, Ovo e Chefao) e ponha os modelos nela.")
		return
	end

	local function destino(nome: string): Folder
		local pasta = ReplicatedStorage:FindFirstChild(nome)
		if not pasta then
			pasta = Instance.new("Folder")
			pasta.Name = nome
			pasta.Parent = ReplicatedStorage
		end
		return pasta :: Folder
	end

	local function guardar(pasta: Folder, modelo: Model)
		local antigo = pasta:FindFirstChild(modelo.Name)
		if antigo then
			antigo:Destroy()
		end
		modelo.Parent = pasta
	end

	local function cada(subpasta: string, fazer: (Model) -> ())
		local pasta = originais:FindFirstChild(subpasta)
		if not pasta then
			return
		end
		for _, molde in pasta:GetChildren() do
			if molde:IsA("Model") then
				local ok, erro = pcall(fazer, molde)
				if not ok then
					warn(`{molde.Name}: não consegui converter: {erro}`)
				end
			end
		end
	end

	cada("Brainrot", function(molde)
		local def = Config.brainrot(molde.Name)
		if not def then
			warn(`{molde.Name}: não existe Brainrot com esse id no Config.`)
			return
		end
		guardar(destino("ModelosBrainrot"), Legoizar.converter(molde, {
			altura = 7,
			corBaixo = def.cor,
			corCima = def.corCabeca,
		}))
	end)
	cada("Ovo", function(molde)
		local def = Config.ovo(molde.Name)
		if not def then
			warn(`{molde.Name}: não existe ovo com esse id no Config.`)
			return
		end
		local brainrot = Config.brainrot(def.brainrot)
		local cor = if brainrot then brainrot.cor:Lerp(Color3.new(1, 1, 1), 0.3) else Config.CORES_RARIDADE[def.raridade]
		guardar(destino("ModelosOvo"), Legoizar.converter(molde, {
			altura = 3.2,
			resolucao = 12,
			corBaixo = cor,
			corCima = cor,
		}))
	end)
	cada("Chefao", function(molde)
		local corGuardiao = Color3.fromRGB(150, 100, 60)
		for _, bioma in Config.BIOMAS do
			if bioma.guardiao == molde.Name then
				corGuardiao = bioma.corGuardiao
			end
		end
		guardar(destino("ModelosChefao"), Legoizar.converter(molde, {
			altura = 11,
			resolucao = 28,
			corBaixo = corGuardiao,
			corCima = corGuardiao,
			alturaMaximaBloco = 3,
		}))
	end)

	if apagarOriginais ~= false then
		originais:Destroy()
		print("Pronto! Os originais foram apagados. Confira os modelos e publique o jogo.")
	else
		print("Pronto! Os originais continuam em ServerStorage.Originais.")
	end
end

return Legoizar

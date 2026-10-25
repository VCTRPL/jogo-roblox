-- Estilo "Lego" do jogo todo: as peças viram plástico com pinos em cima
-- (Studs) e encaixes embaixo (Inlet), e bolas e cilindros viram blocos
-- quadrados. Roda nos modelos que o jogo monta por código. Os modelos da
-- biblioteca do Roblox (atributo "Biblioteca") ficam como vieram.
local Blocos = {}

-- Materiais que continuam iguais: luz, vidro e o campo de força dos portais.
local MANTER = {
	[Enum.Material.Neon] = true,
	[Enum.Material.Glass] = true,
	[Enum.Material.ForceField] = true,
}

local function temMalha(p: BasePart): boolean
	return p:FindFirstChildWhichIsA("DataModelMesh") ~= nil
end

function Blocos.peca(p: BasePart)
	if p.Transparency >= 1 or p:GetAttribute("ManterForma") then
		return
	end
	if p:IsA("Part") and not temMalha(p) then
		if p.Shape == Enum.PartType.Ball then
			p.Shape = Enum.PartType.Block
		elseif p.Shape == Enum.PartType.Cylinder then
			p.Shape = Enum.PartType.Block
			-- cilindro em pé (deitado no eixo X e girado): vira um bloco em pé,
			-- para os pinos ficarem em cima
			if math.abs(p.CFrame.RightVector.Y) > 0.9 then
				local altura, largura = p.Size.X, p.Size.Y
				-- o pivot (de quem usa esta peça como PrimaryPart) fica no mesmo lugar
				local pivo = p:GetPivot()
				p.Size = Vector3.new(largura, altura, p.Size.Z)
				p.CFrame = CFrame.new(p.Position)
				p.PivotOffset = p.CFrame:ToObjectSpace(pivo)
			end
		end
	end
	if not MANTER[p.Material] then
		p.Material = Enum.Material.Plastic
	end
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Inlet
end

local function daBiblioteca(objeto: Instance, raiz: Instance): boolean
	local atual: Instance? = objeto
	while atual and atual ~= raiz.Parent do
		if atual:GetAttribute("Biblioteca") then
			return true
		end
		atual = atual.Parent
	end
	return false
end

function Blocos.aplicar(raiz: Instance)
	if raiz:IsA("BasePart") then
		Blocos.peca(raiz)
	end
	for _, objeto in raiz:GetDescendants() do
		if objeto:IsA("BasePart") and not daBiblioteca(objeto, raiz) then
			Blocos.peca(objeto)
		end
	end
end

-- Aplica agora e em tudo que aparecer depois dentro da pasta.
function Blocos.vigiar(raiz: Instance)
	Blocos.aplicar(raiz)
	raiz.DescendantAdded:Connect(function(objeto)
		if objeto:IsA("BasePart") and not daBiblioteca(objeto, raiz) then
			Blocos.peca(objeto)
		end
	end)
end

return Blocos

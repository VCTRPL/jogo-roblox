-- Modelos tirados da biblioteca do Roblox (Toolbox / Creator Store) que
-- alguém colocou pelo Studio numa pasta do ReplicatedStorage
-- (ModelosChefao e ModelosArvore, veja o README).
-- Antes de usar, a cópia perde todos os scripts (modelo grátis às vezes traz
-- script escondido), fica ancorada, sem colisão, do tamanho pedido e de pé
-- na origem, olhando para -Z. O estilo Lego não mexe nela.
local Biblioteca = {}

-- Caixa alinhada com o mundo em volta de todas as peças.
function Biblioteca.limites(modelo: Instance): (Vector3, Vector3)
	local menor = Vector3.one * math.huge
	local maior = -Vector3.one * math.huge
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
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

-- Para onde o modelo olha: a frente da peça principal (ou da HumanoidRootPart).
local function frente(modelo: Model): Vector3?
	local raiz = modelo.PrimaryPart or modelo:FindFirstChild("HumanoidRootPart")
	if raiz and raiz:IsA("BasePart") then
		local olhar = raiz.CFrame.LookVector
		local plano = Vector3.new(olhar.X, 0, olhar.Z)
		if plano.Magnitude > 0.1 then
			return plano.Unit
		end
	end
	return nil
end

function Biblioteca.preparar(molde: Model, altura: number): Model?
	local modelo = molde:Clone()
	for _, objeto in modelo:GetDescendants() do
		if objeto:IsA("LuaSourceContainer") or objeto:IsA("Sound") then
			objeto:Destroy()
		end
	end
	local pecas = 0
	for _, objeto in modelo:GetDescendants() do
		if objeto:IsA("BasePart") then
			objeto.Anchored = true
			objeto.CanCollide = false
			objeto.CanTouch = false
			objeto.CanQuery = false
			pecas += 1
		elseif objeto:IsA("Humanoid") then
			objeto.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			objeto.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end
	end
	if pecas == 0 then
		warn(`O modelo {molde.Name} da biblioteca não tem peças; usando o padrão.`)
		modelo:Destroy()
		return nil
	end
	modelo:SetAttribute("Biblioteca", true)

	-- vira para -Z, girando em volta da origem
	local olhar = frente(modelo)
	if olhar then
		modelo:PivotTo(CFrame.lookAt(Vector3.zero, olhar):Inverse() * modelo:GetPivot())
	end
	-- do tamanho pedido
	local menor, maior = Biblioteca.limites(modelo)
	local alturaAtual = maior.Y - menor.Y
	if alturaAtual > 0.01 then
		modelo:ScaleTo(modelo:GetScale() * altura / alturaAtual)
	end
	-- pés na origem
	menor, maior = Biblioteca.limites(modelo)
	local pes = Vector3.new((menor.X + maior.X) / 2, menor.Y, (menor.Z + maior.Z) / 2)
	modelo:PivotTo(modelo:GetPivot() - pes)
	return modelo
end

-- Um modelo qualquer de uma pasta do ReplicatedStorage (ou de uma subpasta).
function Biblioteca.moldes(pasta: Instance?): { Model }
	local lista = {}
	if pasta then
		for _, objeto in pasta:GetDescendants() do
			if objeto:IsA("Model") and not objeto:FindFirstAncestorWhichIsA("Model") then
				table.insert(lista, objeto)
			end
		end
	end
	return lista
end

return Biblioteca

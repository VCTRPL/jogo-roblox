-- Modelos 3D do mapa feitos no Blender (low-poly, veja arte/mapa3d): árvores,
-- pedras, flores, palmeiras, cactos, montanhas, postes, o chafariz, a esteira
-- e os enfeites dos biomas. Ficam em ServerStorage.ModelosMapa, cada um um
-- Model com o pivot no pé (no chão) e as peças com o nome do que são
-- ("Tronco", "Copa", "Rocha", "Petala"...), para pintar cada parte de uma cor.
-- Sem a pasta (ou sem o modelo), quem chama usa os modelos de blocos antigos.
local ServerStorage = game:GetService("ServerStorage")

local Adereco = {}

local pasta = ServerStorage:FindFirstChild("ModelosMapa")

function Adereco.tem(nome: string): boolean
	return pasta ~= nil and pasta:FindFirstChild(nome) ~= nil
end

export type Opcoes = {
	escala: number?,
	cores: { [string]: Color3 }?, -- cor por nome de peça
	materiais: { [string]: Enum.Material }?,
	colide: boolean?, -- padrão: só o que é grande e sólido colide (veja "solidas")
	solidas: { string }?, -- nomes das peças que colidem (ex.: { "Tronco", "Rocha" })
	sombra: boolean?,
}

-- Põe uma cópia do modelo "nome" com o pé em "cf". Devolve nil se não tiver.
function Adereco.colocar(nome: string, cf: CFrame, parent: Instance, opcoes: Opcoes?): Model?
	local molde = pasta and pasta:FindFirstChild(nome)
	if not molde then
		return nil
	end
	local o = opcoes or {}
	local modelo = molde:Clone() :: Model
	-- os modelos do Blender ficam com o material e a forma deles (sem pinos)
	modelo:SetAttribute("SemLego", true)
	local escala = o.escala or 1
	if escala ~= 1 then
		modelo:ScaleTo(escala)
	end
	modelo:PivotTo(cf)
	for _, p in modelo:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanTouch = false
			local solida = o.colide
			if solida == nil then
				solida = o.solidas ~= nil and table.find(o.solidas, p.Name) ~= nil
			end
			p.CanCollide = solida
			p.CanQuery = solida
			if o.sombra == false then
				p.CastShadow = false
			end
			local cor = o.cores and o.cores[p.Name]
			if cor then
				p.Color = cor
			end
			local material = o.materiais and o.materiais[p.Name]
			if material then
				p.Material = material
			end
		elseif p:IsA("WeldConstraint") or p:IsA("Weld") then
			p:Destroy() -- tudo fica ancorado; solda só pesaria na física
		end
	end
	modelo.Parent = parent
	return modelo
end

-- A peça "nome" dentro do modelo colocado (para pôr luz ou partículas).
function Adereco.peca(modelo: Model, nome: string): BasePart?
	return modelo:FindFirstChild(nome, true) :: BasePart?
end

return Adereco

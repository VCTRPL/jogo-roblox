-- Tranco de câmera e "soco" no campo de visão, só neste computador. Quem
-- quiser sacudir a tela chama Tremor.sacudir(força, duração) ou
-- Tremor.soco(graus); tudo some sozinho. Também diz se o aparelho é fraco
-- (celular), para os outros módulos soltarem menos partículas.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Tremor = {}

-- celular: tela de toque sem teclado
Tremor.celular = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
-- multiplica a quantidade de partículas
Tremor.qualidade = if Tremor.celular then 0.5 else 1

type Sacudida = { forca: number, fim: number, duracao: number }
local sacudidas: { Sacudida } = {}
local soco = 0 -- graus a mais no campo de visão agora (volta a 0 sozinho)
local socoAplicado = 0

-- força 1 = tranco forte (explosão do lado); 0.2 = tremidinha
function Tremor.sacudir(forca: number, duracao: number?)
	if #sacudidas >= 6 then
		table.remove(sacudidas, 1)
	end
	local d = duracao or 0.35
	table.insert(sacudidas, { forca = forca, fim = os.clock() + d, duracao = d })
end

-- Sacode mais quanto mais perto da câmera estiver o ponto.
function Tremor.perto(posicao: Vector3, forca: number, alcance: number, duracao: number?)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local distancia = (camera.Focus.Position - posicao).Magnitude
	if distancia < alcance then
		Tremor.sacudir(forca * (1 - distancia / alcance), duracao)
	end
end

-- abre (graus > 0) ou fecha a câmera por um instante
function Tremor.soco(graus: number)
	soco = math.clamp(soco + graus, -12, 14)
end

function Tremor.iniciar()
	RunService:BindToRenderStep("TremorEfeitos", Enum.RenderPriority.Camera.Value + 2, function(dt)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local agora = os.clock()
		local forca = 0
		for i = #sacudidas, 1, -1 do
			local s = sacudidas[i]
			if agora >= s.fim then
				table.remove(sacudidas, i)
			else
				-- cai rápido no fim, como um tranco de verdade
				local resta = (s.fim - agora) / s.duracao
				forca = math.max(forca, s.forca * resta * resta)
			end
		end
		if forca > 0.001 then
			local q = forca * 1.6
			camera.CFrame *= CFrame.Angles(
				math.rad(math.noise(agora * 28, 11) * q * 3),
				math.rad(math.noise(agora * 28, 22) * q * 3),
				math.rad(math.noise(agora * 28, 33) * q * 1.5)
			)
		end
		-- o soco volta para 0 com uma mola amortecida; só mexe no que somou,
		-- para não brigar com quem tweena o FieldOfView (Corrida)
		soco *= math.exp(-dt * 7)
		if math.abs(soco) < 0.01 then
			soco = 0
		end
		local diferenca = soco - socoAplicado
		if diferenca ~= 0 then
			camera.FieldOfView = math.clamp(camera.FieldOfView + diferenca, 30, 110)
			socoAplicado = soco
		end
	end)
end

return Tremor

-- Sons e música. O servidor pede um som pelo nome (Config.SONS) e ele toca
-- aqui: com posição, sai daquele lugar no mundo; sem, toca só na sua tela.
-- A música de fundo segue Config.MUSICA, e dentro de um bioma com "musica"
-- toca a dele. O botão de som (Interface) liga e desliga tudo.
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Sons = {}

local jogador = Players.LocalPlayer
local mudo = false

-- Mixagem: três canais com volumes próprios (a interface mais baixa, para
-- o clique não brigar com o resto) e um canal geral com compressor, que
-- abaixa um pouco quando vários sons tocam juntos.
local geral = Instance.new("SoundGroup")
geral.Name = "SonsJogo"
geral.Volume = 0.9
geral.Parent = SoundService
local compressor = Instance.new("CompressorSoundEffect")
compressor.Threshold = -16
compressor.Ratio = 3
compressor.Attack = 0.01
compressor.Release = 0.15
compressor.Parent = geral
local VOLUME_GRUPO = { Interface = 0.7, Efeitos = 0.85, Mundo = 0.9 }
local grupos: { [string]: SoundGroup } = {}
for nome, volume in VOLUME_GRUPO do
	local g = Instance.new("SoundGroup")
	g.Name = nome
	g.Volume = volume
	g.Parent = geral
	grupos[nome] = g
end

-- Sons da Creator Store que não carregarem usam a "reserva" (que vem com o Roblox).
local falhou: { [string]: boolean } = {}
task.spawn(function()
	local lista = {}
	for _, def in Config.SONS do
		if string.find(def.id, "rbxassetid://", 1, true) and not table.find(lista, def.id) then
			table.insert(lista, def.id)
		end
	end
	pcall(function()
		ContentProvider:PreloadAsync(lista, function(id, estado)
			if estado ~= Enum.AssetFetchStatus.Success then
				falhou[id] = true
			end
		end)
	end)
end)

-- Para o mesmo som não empilhar (vários cliques no mesmo quadro somavam volume).
local ultimaVez: { [string]: number } = {}

function Sons.tocar(nome: string, posicao: Vector3?)
	local def = Config.SONS[nome]
	if mudo or not def then
		return
	end
	local agora = os.clock()
	if agora - (ultimaVez[nome] or 0) < 0.06 then
		return
	end
	ultimaVez[nome] = agora
	local som = Instance.new("Sound")
	som.SoundId = if falhou[def.id] and def.reserva then def.reserva else def.id
	som.Volume = def.volume or 0.5
	local variar = if def.semVariar then 0 else (math.random() - 0.5) * 0.06 -- um pouco diferente a cada vez
	som.PlaybackSpeed = (def.tom or 1) * (1 + variar)
	som.SoundGroup = grupos[def.grupo or "Efeitos"] or grupos.Efeitos
	local dono: Instance = som
	if posicao then
		local anexo = Instance.new("Attachment")
		anexo.Position = posicao
		anexo.Parent = Workspace.Terrain
		som.RollOffMinDistance = 12
		som.RollOffMaxDistance = 160
		som.Parent = anexo
		dono = anexo
	else
		som.Parent = SoundService
	end
	som.Ended:Connect(function()
		dono:Destroy()
	end)
	Debris:AddItem(dono, 12)
	som:Play()
end

-- Música -----------------------------------------------------------------------

local musica = Instance.new("Sound")
musica.Name = "Musica"
musica.Volume = 0
musica.Parent = SoundService
local faixaAtual: string? = nil
local proximaDaLista = 1

local function musicaDoBioma(): string?
	local nome = jogador:GetAttribute("Bioma")
	for _, bioma in Config.BIOMAS do
		if bioma.nome == nome and bioma.musica then
			return bioma.musica
		end
	end
	return nil
end

local function trocarPara(id: string?)
	if id == faixaAtual then
		return
	end
	faixaAtual = id
	local saida = TweenService:Create(musica, TweenInfo.new(0.8), { Volume = 0 })
	saida:Play()
	saida.Completed:Wait()
	if faixaAtual ~= id then
		return -- trocou de novo enquanto abaixava
	end
	musica:Stop()
	if id then
		musica.SoundId = id
		musica.Looped = musicaDoBioma() == id
		musica:Play()
		TweenService:Create(musica, TweenInfo.new(1.5), { Volume = if mudo then 0 else Config.VOLUME_MUSICA }):Play()
	end
end

local function escolherMusica()
	local doBioma = musicaDoBioma()
	if doBioma then
		task.spawn(trocarPara, doBioma)
	elseif #Config.MUSICA > 0 then
		-- volta para a lista (continua de onde parou)
		if faixaAtual == nil or not table.find(Config.MUSICA, faixaAtual) then
			task.spawn(trocarPara, Config.MUSICA[proximaDaLista])
		end
	else
		task.spawn(trocarPara, nil)
	end
end

musica.Ended:Connect(function()
	if #Config.MUSICA > 0 and table.find(Config.MUSICA, faixaAtual) then
		proximaDaLista = proximaDaLista % #Config.MUSICA + 1
		faixaAtual = nil
		escolherMusica()
	end
end)

-- Liga ou desliga o som do jogo. Devolve true se ficou mudo.
function Sons.alternar(): boolean
	mudo = not mudo
	musica.Volume = if mudo then 0 else Config.VOLUME_MUSICA
	return mudo
end

function Sons.mudo(): boolean
	return mudo
end

function Sons.iniciar()
	jogador:GetAttributeChangedSignal("Bioma"):Connect(escolherMusica)
	escolherMusica()
end

return Sons

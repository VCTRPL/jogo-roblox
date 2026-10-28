"""Transforma um modelo 3D (.glb do Sketchfab) num Brainrot de blocos Lego.

O modelo é fatiado numa grade de cubinhos. Cada cubinho da casca pega a cor
da textura no ponto mais perto da superfície, trocada pela cor de Lego mais
parecida. Cubinhos vizinhos da mesma cor viram um bloco só. O resultado é um
ModuleScript em src/server/Lego/<id>.luau que o jogo monta com pinos em cima.

Uso:
    python ferramentas/voxelizar.py <arquivo.glb> <id> [--resolucao 24] [--girar 0]

--resolucao: quantos cubinhos na maior medida do modelo (mais = mais detalhe).
--girar: graus em volta do eixo vertical, para o Brainrot olhar para frente.
"""

import argparse
import json
import os
import struct

import numpy as np
import trimesh
from PIL import Image
from scipy import ndimage

# Cores de peças de Lego (as mesmas do src/ferramentas/Legoizar.luau, mais
# algumas para os Brainrots ficarem parecidos com o original).
PALETA = [
    (242, 243, 243),  # branco
    (160, 165, 169),  # cinza claro
    (99, 95, 98),  # cinza escuro
    (27, 42, 53),  # preto
    (196, 40, 28),  # vermelho
    (255, 102, 204),  # rosa
    (255, 176, 196),  # rosa claro
    (218, 133, 65),  # laranja
    (245, 205, 48),  # amarelo
    (248, 241, 132),  # amarelo claro
    (75, 151, 75),  # verde
    (164, 189, 71),  # verde-limão
    (39, 70, 45),  # verde escuro
    (13, 105, 172),  # azul
    (110, 153, 202),  # azul claro
    (0, 143, 156),  # turquesa
    (107, 50, 124),  # roxo
    (124, 92, 70),  # marrom
    (86, 66, 54),  # marrom escuro
    (215, 197, 154),  # areia
    (234, 184, 146),  # pele
    (204, 142, 105),  # pele escura
    (90, 110, 130),  # azul acinzentado
    (60, 75, 95),  # azul escuro
    (120, 140, 60),  # oliva
    (160, 95, 55),  # caramelo
]
PALETA_NP = np.array(PALETA, dtype=float) / 255
VAZIO, MIOLO = -1, -2  # miolo: cubinho de dentro, que ninguém vê


def cores_de_brinquedo(cores: np.ndarray) -> np.ndarray:
    """Clareia modelos escuros e deixa as cores mais vivas, como plástico.
    Muitos modelos têm textura realista e escura, que viraria quase tudo preto."""
    maior = cores.max(axis=1)
    menor = cores.min(axis=1)
    brilho = maior
    saturacao = np.where(maior > 0, (maior - menor) / np.maximum(maior, 1e-6), 0)
    ganho = np.clip(0.85 / max(np.percentile(brilho, 75), 1e-3), 1.0, 3.0)
    novo_brilho = np.clip(brilho * ganho, 0, 1)
    nova_saturacao = np.clip(saturacao * 1.3, 0, 1)
    # monta de novo mantendo o tom (hue): cor = brilho * (1 - sat * (1 - normalizada))
    normalizada = np.where(
        (maior - menor)[:, None] > 0, (cores - menor[:, None]) / np.maximum(maior - menor, 1e-6)[:, None], 1
    )
    return novo_brilho[:, None] * (1 - nova_saturacao[:, None] * (1 - normalizada))


def mais_parecida(cores: np.ndarray) -> np.ndarray:
    d = cores[:, None, :] - PALETA_NP[None, :, :]
    # o olho vê mais diferença no verde
    dist = (d * d * np.array([0.3, 0.59, 0.11])).sum(axis=2)
    return dist.argmin(axis=1)


def textura(material):
    """Imagem (como array 0..1) e cor base do material."""
    imagem, fator = None, np.ones(4)
    if isinstance(material, trimesh.visual.material.PBRMaterial):
        if material.baseColorTexture is not None:
            imagem = np.asarray(material.baseColorTexture.convert("RGBA"), dtype=float) / 255
        if material.baseColorFactor is not None:
            fator = np.asarray(material.baseColorFactor, dtype=float)
            if fator.max() > 1:
                fator = fator / 255
    elif isinstance(material, trimesh.visual.material.SimpleMaterial):
        if material.image is not None:
            imagem = np.asarray(material.image.convert("RGBA"), dtype=float) / 255
        fator = np.asarray(material.diffuse, dtype=float) / 255
    return imagem, fator


def cores_dos_pontos(malha: trimesh.Trimesh, perto: np.ndarray, tri: np.ndarray) -> np.ndarray:
    """Cor (RGB 0..1) de pontos que estão na superfície da malha."""
    cores = np.full((len(perto), 3), 0.6)
    visual = malha.visual
    if isinstance(visual, trimesh.visual.TextureVisuals):
        imagem, fator = textura(visual.material)
        if imagem is not None and visual.uv is not None:
            bary = trimesh.triangles.points_to_barycentric(malha.triangles[tri], perto)
            uv = (visual.uv[malha.faces[tri]] * bary[:, :, None]).sum(axis=1)
            altura, largura = imagem.shape[:2]
            u = np.mod(uv[:, 0], 1.0)
            v = np.mod(uv[:, 1], 1.0)
            px = np.clip((u * (largura - 1)).round().astype(int), 0, largura - 1)
            py = np.clip(((1 - v) * (altura - 1)).round().astype(int), 0, altura - 1)
            cores = imagem[py, px, :3] * fator[:3]
        else:
            cores[:] = fator[:3]
    elif isinstance(visual, trimesh.visual.ColorVisuals) and visual.kind == "vertex":
        vc = visual.vertex_colors[:, :3].astype(float) / 255
        bary = trimesh.triangles.points_to_barycentric(malha.triangles[tri], perto)
        cores = (vc[malha.faces[tri]] * bary[:, :, None]).sum(axis=1)
    elif isinstance(visual, trimesh.visual.ColorVisuals) and visual.kind == "face":
        cores = visual.face_colors[tri, :3].astype(float) / 255
    return cores


def nos_com_esqueleto(caminho: str) -> set:
    """Nomes dos nós com malha de esqueleto (skin). O glTF manda ignorar a
    posição desses nós: a malha já está no lugar certo."""
    with open(caminho, "rb") as f:
        dados = f.read()
    tamanho = struct.unpack("<I", dados[12:16])[0]
    gltf = json.loads(dados[20 : 20 + tamanho])
    return {no.get("name") for no in gltf.get("nodes", []) if "mesh" in no and "skin" in no}


def carregar(caminho: str, girar: float, deitar: float):
    cena = trimesh.load(caminho, force="scene")
    esqueleto = nos_com_esqueleto(caminho)
    malhas = []
    for nome in cena.graph.nodes_geometry:
        transformacao, geometria = cena.graph[nome]
        malha = cena.geometry[geometria]
        if not isinstance(malha, trimesh.Trimesh) or len(malha.faces) == 0:
            continue
        malha = malha.copy()
        if nome not in esqueleto:
            malha.apply_transform(transformacao)
        malhas.append(malha)
    # alguns modelos vêm deitados (eixo de cima trocado): gira em volta de X
    deita = trimesh.transformations.rotation_matrix(np.radians(deitar), [1, 0, 0])
    # glTF olha para +Z; no Roblox a frente é -Z
    giro = trimesh.transformations.rotation_matrix(np.radians(180 + girar), [0, 1, 0])
    for malha in malhas:
        malha.apply_transform(giro @ deita)
    return malhas


def previa(grade: np.ndarray, destino: str):
    """Imagem com a frente, o lado e o topo, para conferir sem abrir o Studio."""
    vistas = []
    # frente: olhando de -Z para +Z; lado: de +X; topo: de cima
    for eixo, inverter, girar in ((2, False, False), (0, True, False), (1, True, True)):
        g = grade if not inverter else np.flip(grade, axis=eixo)
        cheio = g >= 0
        primeiro = cheio.argmax(axis=eixo)
        algum = cheio.any(axis=eixo)
        cor = np.take_along_axis(g, np.expand_dims(primeiro, eixo), axis=eixo).squeeze(eixo)
        rgb = np.full(cor.shape + (3,), 235, dtype=np.uint8)
        rgb[algum] = np.array(PALETA, dtype=np.uint8)[np.clip(cor[algum], 0, None)]
        if eixo == 2:  # (x, y) -> linhas = y de cima para baixo
            img = np.flip(rgb.transpose(1, 0, 2), axis=0)
        elif eixo == 0:  # (y, z)
            img = np.flip(rgb, axis=0)
        else:  # (x, z)
            img = rgb.transpose(1, 0, 2)
        vistas.append(Image.fromarray(np.ascontiguousarray(img)).resize((img.shape[1] * 12, img.shape[0] * 12), Image.NEAREST))
    largura = sum(v.width for v in vistas) + 20 * (len(vistas) - 1)
    folha = Image.new("RGB", (largura, max(v.height for v in vistas)), (255, 255, 255))
    x = 0
    for v in vistas:
        folha.paste(v, (x, 0))
        x += v.width + 20
    folha.save(destino)


def voxelizar(malhas, resolucao: int):
    juntas = trimesh.util.concatenate([trimesh.Trimesh(m.vertices, m.faces, process=False) for m in malhas])
    menor, maior = juntas.bounds
    passo = (maior - menor).max() / resolucao
    tamanho = np.ceil((maior - menor) / passo).astype(int) + 1

    # Pontos espalhados pela superfície de cada malha, cada um com a cor da
    # textura naquele lugar. Eles marcam a casca e votam na cor do cubinho.
    area_total = sum(m.area for m in malhas)
    todos_pontos, todas_cores = [], []
    for malha in malhas:
        quantos = max(2000, int(400000 * malha.area / area_total))
        pontos, tri = trimesh.sample.sample_surface(malha, quantos)
        todos_pontos.append(pontos)
        todas_cores.append(np.clip(cores_dos_pontos(malha, pontos, tri), 0, 1))
    pontos = np.vstack(todos_pontos)
    cores_pontos = mais_parecida(cores_de_brinquedo(np.vstack(todas_cores)))
    idx = np.floor((pontos - menor) / passo).astype(int)
    idx = np.clip(idx, 0, tamanho - 1)
    casca = np.zeros(tamanho, dtype=bool)
    casca[idx[:, 0], idx[:, 1], idx[:, 2]] = True

    # cor de cada cubinho da casca: a que mais aparece entre os pontos dele
    plano = np.ravel_multi_index(idx.T, tamanho)
    votos = np.zeros((casca.size, len(PALETA)), dtype=np.int32)
    np.add.at(votos, (plano, cores_pontos), 1)
    cor_casca = votos.argmax(axis=1).reshape(tamanho)
    # fecha buracos pequenos da casca e enche por dentro
    fechada = ndimage.binary_closing(casca, iterations=1) | casca
    cheio = ndimage.binary_fill_holes(fechada)
    miolo = cheio & ~ndimage.binary_dilation(~cheio)  # só vizinhos cheios em volta

    grade = np.full(tamanho, VAZIO, dtype=int)
    grade[miolo] = MIOLO
    # cubinhos que o fechamento criou (sem pontos) pegam a cor da casca mais perto
    _, mais_perto = ndimage.distance_transform_edt(~casca, return_indices=True)
    cor_perto = cor_casca[tuple(mais_perto)]
    visivel = cheio & ~miolo
    grade[visivel] = cor_perto[visivel]
    return grade, passo


def limpar_cores(grade: np.ndarray) -> np.ndarray:
    """Cubinho solto de uma cor no meio de outra vira a cor dos vizinhos."""
    saida = grade.copy()
    nx, ny, nz = grade.shape
    for x, y, z in np.argwhere(grade >= 0):
        vizinhos = []
        for dx, dy, dz in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)):
            a, b, c = x + dx, y + dy, z + dz
            if 0 <= a < nx and 0 <= b < ny and 0 <= c < nz and grade[a, b, c] >= 0:
                vizinhos.append(grade[a, b, c])
        if len(vizinhos) >= 4 and grade[x, y, z] not in vizinhos:
            valores, contagem = np.unique(vizinhos, return_counts=True)
            if contagem.max() >= 3:
                saida[x, y, z] = valores[contagem.argmax()]
    return saida


def juntar(grade: np.ndarray, altura_maxima: int = 3):
    """Junta cubinhos em blocos: primeiro em X, depois Z, depois Y. O miolo
    serve de coringa (pode entrar em qualquer bloco), porque ninguém vê."""
    nx, ny, nz = grade.shape
    usado = np.zeros(grade.shape, dtype=bool)
    blocos = []

    def livre(x, y, z, cor):
        return x < nx and y < ny and z < nz and not usado[x, y, z] and grade[x, y, z] in (cor, MIOLO)

    for y in range(ny):
        for z in range(nz):
            for x in range(nx):
                cor = grade[x, y, z]
                if cor < 0 or usado[x, y, z]:
                    continue
                w = 1
                while livre(x + w, y, z, cor):
                    w += 1
                d = 1
                while all(livre(xx, y, z + d, cor) for xx in range(x, x + w)):
                    d += 1
                h = 1
                while h < altura_maxima and all(
                    livre(xx, y + h, zz, cor) for xx in range(x, x + w) for zz in range(z, z + d)
                ):
                    h += 1
                usado[x : x + w, y : y + h, z : z + d] = True
                blocos.append((x, y, z, w, h, d, int(cor)))
    return blocos


def escrever(id_: str, origem: str, blocos, passo: float, grade: np.ndarray, destino: str):
    usadas = sorted({b[6] for b in blocos})
    indice = {cor: i + 1 for i, cor in enumerate(usadas)}
    nx, ny, nz = grade.shape
    linhas = [
        f"-- {id_} em blocos Lego, gerado por ferramentas/voxelizar.py a partir de",
        f"-- {origem} (veja docs/modelos-sketchfab.md). Não edite à mão: rode o script de novo.",
        "-- blocos: x, y, z, largura, altura, fundo, cor (em cubinhos; y = 0 nos pés)",
        "return {",
        f"\tgrade = Vector3.new({nx}, {ny}, {nz}),",
        "\tcores = {",
    ]
    for cor in usadas:
        r, g, b = PALETA[cor]
        linhas.append(f"\t\tColor3.fromRGB({r}, {g}, {b}),")
    linhas.append("\t},")
    linhas.append("\tblocos = {")
    for i in range(0, len(blocos), 6):
        trecho = blocos[i : i + 6]
        linhas.append("\t\t" + " ".join(f"{x},{y},{z},{w},{h},{d},{indice[c]}," for x, y, z, w, h, d, c in trecho))
    linhas.append("\t},")
    linhas.append("}")
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    with open(destino, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(linhas) + "\n")


def main():
    args = argparse.ArgumentParser()
    args.add_argument("glb")
    args.add_argument("id")
    args.add_argument("--resolucao", type=int, default=24)
    args.add_argument("--girar", type=float, default=0)
    args.add_argument("--deitar", type=float, default=0)
    args.add_argument("--origem", default="")
    args.add_argument("--previa", help="salva uma imagem da frente, do lado e do topo")
    a = args.parse_args()

    malhas = carregar(a.glb, a.girar, a.deitar)
    grade, passo = voxelizar(malhas, a.resolucao)
    grade = limpar_cores(grade)
    blocos = juntar(grade)
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    destino = os.path.join(raiz, "src", "server", "Lego", f"{a.id}.luau")
    escrever(a.id, a.origem or os.path.basename(a.glb), blocos, passo, grade, destino)
    if a.previa:
        previa(grade, a.previa)
    visiveis = int((grade >= 0).sum())
    print(f"{a.id}: grade {grade.shape}, {visiveis} cubinhos visíveis -> {len(blocos)} blocos -> {destino}")


if __name__ == "__main__":
    main()

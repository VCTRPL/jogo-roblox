# Gera os 19 Brainrots 3D (14 comuns + 5 chefes) no estilo LEGO/Roblox.
#
#   blender -b --factory-startup -P arte/brainrots3d/gerar_brainrots.py
#
# Saídas (ao lado deste script):
#   brainrots.blend          cena completa (coleção BRAINROTS > COMUNS / BOSSES)
#   fbx/<Id>.fbx             um FBX por personagem, pés na origem, olhando para -Z
#   renders/apresentacao.png os 19 juntos
#   renders/<Id>.png         um render de cada
#
# Escala: 1 unidade do Blender = 1 stud. O FBX sai com 1 stud = 0,28 m, que é a
# conversão que o importador 3D do Roblox usa.
# Variáveis de ambiente: BR_ENGINE (EEVEE/CYCLES/WORKBENCH), BR_SEM_RENDER=1.

import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector, Euler

PASTA = os.path.dirname(os.path.abspath(__file__))
STUD_EM_METROS = 0.28

# ---------------------------------------------------------------- materiais

MATS = {}


def _lin(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def mat(nome, rgb, rough=0.32, metal=0.0, emit=0.0):
    if nome in MATS:
        return MATS[nome]
    m = bpy.data.materials.new(nome)
    try:
        m.use_nodes = True
    except Exception:
        pass
    b = m.node_tree.nodes.get("Principled BSDF")
    lin = tuple(_lin(c) for c in rgb) + (1.0,)
    b.inputs["Base Color"].default_value = lin
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if "Coat Weight" in b.inputs:
        b.inputs["Coat Weight"].default_value = 0.25
        b.inputs["Coat Roughness"].default_value = 0.15
    if emit > 0:
        b.inputs["Emission Color"].default_value = lin
        b.inputs["Emission Strength"].default_value = emit
    m.diffuse_color = lin
    m["rgb"] = list(rgb)
    MATS[nome] = m
    return m


# Peças comuns a todos: mesmo olho, mesma boca, mesmo acabamento.
OLHO = lambda: mat("Olho_Branco", (250, 250, 250), 0.15)
PUPILA = lambda: mat("Olho_Pupila", (18, 18, 24), 0.1)
BRILHO = lambda: mat("Olho_Brilho", (255, 255, 255), 0.1, emit=1.5)
IRIS_CHEFE = lambda: mat("Olho_Iris_Chefe", (255, 40, 30), 0.2, emit=2.5)
SOBRANCELHA = lambda: mat("Sobrancelha", (30, 22, 20), 0.5)
BOCA = lambda: mat("Boca", (70, 18, 28), 0.5)
DENTE = lambda: mat("Dente", (255, 252, 235), 0.2)
LINGUA = lambda: mat("Lingua", (240, 90, 115), 0.4)
OURO = lambda: mat("Ouro", (255, 196, 40), 0.25, metal=0.8)
PRATA = lambda: mat("Metal_Prata", (195, 200, 210), 0.25, metal=0.8)
PRETO = lambda: mat("Preto", (34, 34, 40), 0.45)
BRANCO = lambda: mat("Branco", (245, 245, 245), 0.3)
BORRACHA = lambda: mat("Borracha", (30, 30, 34), 0.7)

# ---------------------------------------------------------------- geometria


def _xform(bm, loc, rot, esc):
    m = Matrix.Translation(loc) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
    m = m @ Matrix.Diagonal((*esc, 1.0))
    bmesh.ops.transform(bm, matrix=m, verts=bm.verts)


def _bm_caixa(tam, bev):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=tam, verts=bm.verts)
    if bev > 0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bev, offset_type="OFFSET",
                        segments=1, profile=0.5, affect="EDGES", clamp_overlap=True)
    return bm


def _bm_bola(seg):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg[0], v_segments=seg[1], radius=0.5)
    return bm


def _bm_cilindro(r1, r2, alt, seg):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg,
                          radius1=r1, radius2=r2, depth=alt)
    return bm


def _bm_anel(R, r, n=20, m=8):
    bm = bmesh.new()
    vs = []
    for i in range(n):
        a = 2 * math.pi * i / n
        linha = []
        for j in range(m):
            b = 2 * math.pi * j / m
            linha.append(bm.verts.new(((R + r * math.cos(b)) * math.cos(a),
                                       (R + r * math.cos(b)) * math.sin(a), r * math.sin(b))))
        vs.append(linha)
    for i in range(n):
        for j in range(m):
            bm.faces.new((vs[i][j], vs[(i + 1) % n][j], vs[(i + 1) % n][(j + 1) % m], vs[i][(j + 1) % m]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


class Personagem:
    def __init__(self, ident, nome, raridade, colecao_pai, chefe=False, escala=1.0):
        self.id, self.nome, self.raridade, self.chefe, self.escala = ident, nome, raridade, chefe, escala
        self.col = bpy.data.collections.new(ident)
        colecao_pai.children.link(self.col)
        self.raiz = bpy.data.objects.new(ident, None)
        self.raiz.empty_display_type = "PLAIN_AXES"
        self.raiz["nome"], self.raiz["raridade"] = nome, raridade
        self.col.objects.link(self.raiz)
        self.partes = []
        self._usados = {}

    def _add(self, nome, bm, material):
        n = self._usados.get(nome, 0)
        self._usados[nome] = n + 1
        nome_final = f"{self.id}_{nome}" + (f"_{n + 1}" if n else "")
        me = bpy.data.meshes.new(nome_final)
        bm.to_mesh(me)
        bm.free()
        me.materials.append(material)
        for p in me.polygons:
            p.use_smooth = True
        try:
            me.set_sharp_from_angle(angle=math.radians(35))
        except Exception:
            pass
        # A cor também vai como cor de vértice: o Roblox mostra mesmo sem textura.
        rgb = [c / 255 for c in material["rgb"]] + [1.0]
        attr = me.color_attributes.new("Cor", "BYTE_COLOR", "CORNER")
        for d in attr.data:
            d.color_srgb = rgb
        ob = bpy.data.objects.new(nome_final, me)
        self.col.objects.link(ob)
        ob.parent = self.raiz
        self.partes.append(ob)
        return ob

    def caixa(self, nome, tam, loc, m, rot=(0, 0, 0), bev=None):
        if bev is None:
            bev = min(tam) * 0.12
        bm = _bm_caixa(tam, bev)
        _xform(bm, loc, rot, (1, 1, 1))
        return self._add(nome, bm, m)

    def bola(self, nome, tam, loc, m, rot=(0, 0, 0), seg=(14, 9)):
        if not isinstance(tam, (tuple, list)):
            tam = (tam, tam, tam)
        bm = _bm_bola(seg)
        _xform(bm, loc, rot, tam)
        return self._add(nome, bm, m)

    def cil(self, nome, r, alt, loc, m, rot=(0, 0, 0), r2=None, seg=12, esc=(1, 1, 1)):
        bm = _bm_cilindro(r, r if r2 is None else r2, alt, seg)
        _xform(bm, loc, rot, esc)
        return self._add(nome, bm, m)

    def cone(self, nome, r, alt, loc, m, rot=(0, 0, 0), seg=4, esc=(1, 1, 1)):
        return self.cil(nome, r, alt, loc, m, rot, r2=0.0, seg=seg, esc=esc)

    def anel(self, nome, R, r, loc, m, rot=(0, 0, 0), n=20, esc=(1, 1, 1)):
        bm = _bm_anel(R, r, n)
        _xform(bm, loc, rot, esc)
        return self._add(nome, bm, m)

    # ---- padrões repetidos em todos os personagens

    def olhos(self, z, y, sep, d=0.62, x0=0.0, bravo=None, olhar=(0.0, 0.0), triste=False):
        """Olhões de desenho: branco, pupila, brilho. Chefes ganham íris vermelha e sobrancelha."""
        bravo = self.chefe if bravo is None else bravo
        for s, lado in ((-1, "E"), (1, "D")):
            x = x0 + s * sep / 2
            self.bola(f"Olho_{lado}", (d, d * 0.6, d * 1.12), (x, y, z), OLHO())
            px, pz = x + olhar[0] * d * 0.14, z + olhar[1] * d * 0.14
            if self.chefe:
                self.bola(f"Iris_{lado}", (d * 0.66, d * 0.3, d * 0.72), (px, y - d * 0.2, pz), IRIS_CHEFE())
                self.bola(f"Pupila_{lado}", (d * 0.32, d * 0.3, d * 0.5), (px, y - d * 0.27, pz), PUPILA())
            else:
                self.bola(f"Pupila_{lado}", (d * 0.52, d * 0.32, d * 0.6), (px, y - d * 0.22, pz), PUPILA())
            self.bola(f"Brilho_{lado}", d * 0.17, (px - d * 0.1, y - d * 0.4, pz + d * 0.17), BRILHO())
            if bravo:
                self.caixa(f"Sobrancelha_{lado}", (d * 1.05, d * 0.3, d * 0.24),
                           (x, y - d * 0.2, z + d * 0.62), SOBRANCELHA(), rot=(0, (s if triste else -s) * 22, 0))

    def boca(self, z, y, larg, alt=0.32, dentes=True, lingua=False, presas=False, rot=(0, 0, 0)):
        self.caixa("Boca", (larg, 0.24, alt), (0, y, z), BOCA(), rot=rot, bev=0.06)
        if dentes:
            n = max(2, int(larg / 0.28))
            for i in range(n):
                x = -larg / 2 + larg * (i + 0.5) / n
                if presas:
                    self.cone("Dente", 0.11, alt * 0.75, (x, y - 0.1, z + alt * 0.12), DENTE(), rot=(180, 0, 45))
                else:
                    self.caixa("Dente", (larg / n * 0.8, 0.12, alt * 0.38), (x, y - 0.09, z + alt * 0.28), DENTE(), bev=0.02)
        if lingua:
            self.bola("Lingua", (larg * 0.45, 0.2, alt * 0.55), (0, y - 0.07, z - alt * 0.2), LINGUA())

    def finalizar(self):
        """Pés em z=0, centrado, e escala de chefe aplicada direto nos vértices."""
        menor = min((ob.matrix_world @ v.co).z for ob in self.partes for v in ob.data.vertices)
        xs = [(ob.matrix_world @ v.co).x for ob in self.partes for v in ob.data.vertices]
        cx = (min(xs) + max(xs)) / 2
        m = Matrix.Diagonal((self.escala,) * 3 + (1,)) @ Matrix.Translation((-cx, 0, -menor))
        for ob in self.partes:
            ob.data.transform(m)
            ob.data.update()
        cs = [(ob.matrix_world @ v.co) for ob in self.partes for v in ob.data.vertices]
        self.min = Vector((min(c.x for c in cs), min(c.y for c in cs), 0))
        self.max = Vector((max(c.x for c in cs), max(c.y for c in cs), max(c.z for c in cs)))


# ---- pedaços de corpo que vários usam (cada personagem escolhe tamanho e cor)

def pernas(p, cor, sep=0.7, alt=0.7, r=0.16, pe=None, pe_tam=(0.55, 0.8, 0.28), z0=0.0):
    for s, lado in ((-1, "E"), (1, "D")):
        x = s * sep / 2
        p.cil(f"Perna_{lado}", r, alt, (x, 0.0, z0 + pe_tam[2] + alt / 2 - 0.05), cor, seg=10)
        p.caixa(f"Pe_{lado}", pe_tam, (x, -0.1, z0 + pe_tam[2] / 2), pe or cor)


def bracos(p, cor, x, z, comp=0.8, r=0.13, abre=55, frente=0, mao=None):
    for s, lado in ((-1, "E"), (1, "D")):
        ang = math.radians(abre)
        cx = s * (x + math.sin(ang) * comp / 2)
        cz = z - math.cos(ang) * comp / 2
        p.cil(f"Braco_{lado}", r, comp, (cx, -frente, cz), cor, rot=(frente * 40, -s * abre, 0), seg=10)
        p.bola(f"Mao_{lado}", r * 2.4, (s * (x + math.sin(ang) * comp), -frente * 1.6, z - math.cos(ang) * comp), mao or cor)


# ---------------------------------------------------------------- os 14 comuns
# Cada um segue o visual do meme original (imagens do Google/Bing), só que de
# blocos. Frente para -Y, pés em z=0.

LADOS = ((-1, "E"), (1, "D"))


def pinos(p, cx, cy, z, nx, ny, passo, m, r=0.14):
    """Pinos de LEGO num topo plano, todos numa peça só."""
    bm = bmesh.new()
    for i in range(nx):
        for j in range(ny):
            x = cx + (i - (nx - 1) / 2) * passo
            y = cy + (j - (ny - 1) / 2) * passo
            bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=10, radius1=r, radius2=r,
                                  depth=0.12, matrix=Matrix.Translation((x, y, z + 0.06)))
    return p._add("Pinos", bm, m)


def dobrar(ob, dobradica, eixo, graus):
    """Gira uma peça já criada em volta de uma dobradiça (para cascas, pétalas...)."""
    ob.data.transform(Matrix.Translation(dobradica) @ Matrix.Rotation(math.radians(graus), 4, Vector(eixo))
                      @ Matrix.Translation(-Vector(dobradica)))


def pe_humano(p, lado, x, pele, tam=(0.8, 1.3, 0.38), y=-0.2):
    p.caixa(f"Pe_{lado}", tam, (x, y, tam[2] / 2), pele)
    frente = y - tam[1] / 2
    for k in range(5):
        dx = (k - 2) * tam[0] * 0.19 * (-1 if x < 0 else 1)
        d = 0.24 if k == 0 else 0.17
        p.bola(f"Dedo_{lado}", (d, d * 1.1, d), (x - dx, frente, tam[2] * 0.42), pele)


def manchas(p, nome, pontos, tam, cores):
    """Blocos soltos de outra cor por cima (musgo, pintas, textura de coco...)."""
    for i, (x, y, z) in enumerate(pontos):
        p.caixa(nome, tam, (x, y, z), cores[i % len(cores)], rot=(0, 0, (i * 37) % 90))


def patapim(p):
    pele, nariz = mat("Patapim_Pele", (230, 188, 142)), mat("Patapim_Nariz", (238, 150, 140))
    musgo, musgo2 = mat("Patapim_Musgo", (72, 122, 40)), mat("Patapim_Musgo_Claro", (128, 172, 52))
    casca, rosto = mat("Patapim_Casca", (112, 76, 40)), mat("Patapim_Rosto", (214, 172, 128))
    for s, lado in LADOS:
        pe_humano(p, lado, s * 0.55, pele, tam=(0.95, 1.5, 0.42), y=-0.3)
        p.caixa(f"Perna_{lado}", (0.6, 0.6, 1.2), (s * 0.45, 0, 1.0), musgo)
    p.caixa("Tronco", (1.4, 0.95, 1.5), (0, 0, 2.3), musgo)
    for s, lado in LADOS:
        p.caixa(f"Braco_{lado}", (0.36, 0.38, 1.75), (s * 0.95, 0, 2.15), musgo, rot=(0, -s * 6, 0))
        for k in (-1, 0, 1):
            p.caixa(f"Cipo_{lado}", (0.08, 0.08, 0.6), (s * 1.02 + k * 0.1, -0.05 + k * 0.05, 1.05), casca, bev=0.02)
    p.caixa("Cabeca", (1.55, 1.35, 1.45), (0, 0, 3.75), musgo)
    p.caixa("Rosto", (1.0, 0.2, 1.0), (0, -0.65, 3.7), rosto)
    pontos = [(-0.45, -0.5, 2.6), (0.4, -0.5, 2.0), (0.0, -0.5, 1.75), (-0.5, -0.32, 1.2), (0.5, -0.32, 0.8),
              (-0.95, -0.2, 2.7), (0.95, -0.2, 1.8), (-0.5, -0.65, 4.35), (0.55, -0.65, 4.2), (0.0, 0.3, 4.55),
              (-0.6, 0.0, 4.5), (0.6, 0.2, 4.5), (0.4, -0.5, 2.85), (-0.3, -0.5, 1.95)]
    manchas(p, "Musgo", pontos, (0.38, 0.22, 0.32), (musgo2, casca, musgo2))
    for x in (-0.55, 0.55):
        p.caixa("Cabelo", (0.35, 0.3, 0.9), (x, -0.62, 3.55), musgo2)
    p.cil("Nariz", 0.2, 0.75, (0, -0.95, 3.45), nariz, rot=(-30, 0, 0), r2=0.16, seg=10)
    p.bola("Ponta_Nariz", (0.6, 0.55, 0.65), (0, -1.15, 3.05), nariz)
    p.olhos(3.95, -0.8, 0.52, d=0.36)


def larila(p):
    cinza, cacto = mat("Larila_Elefante", (152, 156, 162)), mat("Larila_Cacto", (58, 150, 48))
    listra, ponto = mat("Larila_Listra", (128, 196, 62)), mat("Larila_Ponto", (232, 222, 92))
    sandalia, marfim = mat("Larila_Sandalia", (130, 74, 34)), mat("Larila_Presa", (246, 242, 225))
    for s, lado in LADOS:
        x = s * 0.5
        p.caixa(f"Sandalia_{lado}", (0.8, 1.05, 0.16), (x, -0.12, 0.08), sandalia, bev=0.05)
        p.caixa(f"Pe_{lado}", (0.65, 0.85, 0.3), (x, -0.1, 0.3), cacto)
        p.caixa(f"Tira_{lado}", (0.74, 0.2, 0.18), (x, -0.32, 0.38), sandalia, bev=0.05)
        p.caixa(f"Perna_{lado}", (0.55, 0.55, 0.7), (x, 0, 0.75), cacto)
    p.bola("Corpo", (1.8, 1.5, 2.0), (0, 0, 1.95), cacto, seg=(16, 12))
    for a in (-50, -20, 20, 50):
        p.bola("Listra", (0.16, 1.54, 2.04), (0, 0, 1.95), listra, rot=(0, 0, a), seg=(16, 12))
    for x, z in ((-0.45, 2.4), (0.45, 2.3), (0.0, 1.8), (-0.6, 1.5), (0.6, 1.6), (-0.2, 1.2), (0.3, 2.7), (0.0, 2.75)):
        y = -math.sqrt(max(0.05, 1 - (x / 0.9) ** 2 - ((z - 1.95) / 1.0) ** 2)) * 0.75
        p.bola("Espinho", 0.14, (x, y - 0.03, z), ponto, seg=(8, 6))
    # Braço esquerdo (do personagem) erguendo o despertador; o direito cinza, para baixo.
    p.caixa("Braco_D", (0.4, 0.4, 0.9), (-1.0, -0.15, 2.65), cacto, rot=(-20, -35, 0))
    p.caixa("Braco_E", (0.4, 0.4, 1.0), (0.98, 0, 2.05), cacto, rot=(0, -12, 0))
    p.caixa("Mao_E", (0.45, 0.45, 0.4), (1.05, 0, 1.45), cinza)
    rel = mat("Larila_Relogio", (215, 35, 35))
    cx, cz = -1.3, 3.25
    p.cil("Relogio", 0.42, 0.3, (cx, -0.45, cz), rel, rot=(90, 0, 0), seg=16)
    p.cil("Relogio_Mostrador", 0.33, 0.05, (cx, -0.61, cz), BRANCO(), rot=(90, 0, 0), seg=16)
    p.caixa("Ponteiro", (0.05, 0.04, 0.24), (cx, -0.65, cz + 0.08), PRETO(), bev=0.01)
    p.caixa("Ponteiro_2", (0.18, 0.04, 0.05), (cx + 0.07, -0.65, cz), PRETO(), bev=0.01)
    for s in (-1, 1):
        p.bola("Sino", (0.26, 0.26, 0.2), (cx + s * 0.25, -0.45, cz + 0.42), rel)
    p.bola("Cabeca", (1.7, 1.5, 1.6), (0, -0.05, 3.55), cinza)
    for s, lado in LADOS:
        p.caixa(f"Orelha_{lado}", (0.22, 1.15, 1.45), (s * 1.12, 0.15, 3.55), cinza, rot=(0, 0, s * -22))
        p.cone(f"Presa_{lado}", 0.08, 0.45, (s * 0.38, -0.82, 2.95), marfim, rot=(60, 0, s * 10), seg=8)
    p.cil("Tromba", 0.26, 0.8, (0, -0.85, 3.0), cinza, rot=(-12, 0, 0), r2=0.22, seg=10)
    p.cil("Tromba_Ponta", 0.2, 0.6, (0, -1.05, 2.45), cinza, rot=(30, 0, 0), r2=0.16, seg=10)
    p.olhos(3.78, -0.72, 0.62, d=0.46)


def bananini(p):
    marrom, bege = mat("Bananini_Macaco", (118, 70, 30)), mat("Bananini_Rosto", (230, 186, 128))
    banana, dentro = mat("Bananini_Banana", (252, 214, 50)), mat("Bananini_Casca_Dentro", (250, 238, 175))
    for s, lado in LADOS:
        p.caixa(f"Pe_{lado}", (0.5, 0.75, 0.22), (s * 0.4, -0.12, 0.11), bege)
        p.caixa(f"Perna_{lado}", (0.42, 0.45, 0.7), (s * 0.4, 0, 0.55), marrom)
    p.caixa("Tronco", (1.15, 0.85, 1.35), (0, 0, 1.55), marrom)
    for s, lado in LADOS:
        p.caixa(f"Braco_{lado}", (0.34, 0.36, 1.15), (s * 0.85, 0, 1.6), marrom, rot=(0, -s * 12, 0))
        p.caixa(f"Mao_{lado}", (0.4, 0.4, 0.32), (s * 0.95, -0.05, 0.92), bege)
    p.bola("Banana", (0.95, 0.65, 1.75), (0, -0.55, 1.3), banana, seg=(12, 10))
    for x, y, rx, ry in ((-0.5, -0.75, 0, -28), (0.5, -0.75, 0, 28), (0.0, -1.02, -25, 0)):
        p.caixa("Casca", (0.42, 0.12, 0.85), (x, y, 1.82), banana, rot=(rx, ry, 0), bev=0.04)
        p.caixa("Casca_Dentro", (0.32, 0.05, 0.7), (x * 0.95, y + 0.07, 1.85), dentro, rot=(rx, ry, 0), bev=0.02)
    p.bola("Cabeca", (1.35, 1.25, 1.3), (0, 0, 2.85), marrom)
    p.bola("Rosto", (0.95, 0.55, 0.85), (0, -0.42, 2.78), bege)
    p.bola("Focinho", (0.7, 0.45, 0.42), (0, -0.62, 2.5), bege)
    p.bola("Narina_E", 0.06, (-0.08, -0.84, 2.58), PRETO())
    p.bola("Narina_D", 0.06, (0.08, -0.84, 2.58), PRETO())
    for s, lado in LADOS:
        p.bola(f"Orelha_{lado}", (0.22, 0.38, 0.4), (s * 0.72, 0, 2.9), bege)
    p.olhos(2.95, -0.7, 0.48, d=0.4)
    p.boca(2.38, -0.84, 0.3, alt=0.08, dentes=False)


def ambalabu(p):
    sapo, labio = mat("Ambalabu_Sapo", (40, 150, 50)), mat("Ambalabu_Labio", (226, 196, 130))
    pele, pneu = mat("Ambalabu_Pele", (230, 190, 140)), BORRACHA()
    for s, lado in LADOS:
        pe_humano(p, lado, s * 0.42, pele, tam=(0.6, 0.95, 0.3), y=-0.15)
        p.caixa(f"Perna_{lado}", (0.34, 0.36, 1.0), (s * 0.4, 0, 0.75), pele)
    p.anel("Pneu", 0.6, 0.42, (0, 0, 2.05), pneu, rot=(90, 0, 0), n=18, esc=(1, 1, 1.5))
    for i in range(18):
        a = math.radians(i * 20)
        p.caixa("Cravo_Pneu", (0.18, 1.1, 0.14), (math.cos(a) * 1.04, 0, 2.05 + math.sin(a) * 1.04), pneu,
                rot=(0, -math.degrees(a) + 90, 0), bev=0.03)
    p.bola("Cabeca", (2.1, 1.6, 0.95), (0, 0.05, 3.42), sapo)
    p.caixa("Labio", (1.9, 1.35, 0.3), (0, -0.1, 3.1), labio, bev=0.12)
    p.caixa("Boca", (1.9, 0.08, 0.06), (0, -0.78, 3.26), PRETO(), bev=0.0)
    for s in (-1, 1):
        p.bola("Palpebra", (0.75, 0.7, 0.7), (s * 0.52, -0.2, 3.85), sapo)
        p.bola("Narina", 0.06, (s * 0.15, -0.75, 3.5), PRETO())
    p.olhos(3.92, -0.55, 1.04, d=0.56)


def cappuccina(p):
    rosa, rosa2 = mat("Cappuccina_Tutu", (255, 168, 200)), mat("Cappuccina_Tutu_Claro", (255, 205, 225))
    xicara, cafe = mat("Cappuccina_Xicara", (246, 242, 236)), mat("Cappuccina_Cafe", (150, 96, 56))
    espuma, pele = mat("Cappuccina_Espuma", (240, 220, 186)), mat("Cappuccina_Pele", (242, 202, 172))
    for s, lado in LADOS:
        p.cone(f"Sapatilha_{lado}", 0.14, 0.35, (s * 0.08, 0, 0.18), rosa, rot=(180, 0, 0), seg=8)
        p.cil(f"Perna_{lado}", 0.09, 1.25, (s * 0.12, 0, 0.95), pele, rot=(0, -s * 4, 0), seg=8)
    p.cil("Tutu", 1.2, 0.18, (0, 0, 1.62), rosa, r2=0.95, seg=16)
    p.cil("Tutu_2", 1.0, 0.18, (0, 0, 1.76), rosa2, r2=0.65, seg=16)
    p.cil("Corpete", 0.3, 0.75, (0, 0, 2.15), rosa, r2=0.36, seg=10)
    for s, lado in LADOS:
        p.cil(f"Braco_{lado}", 0.075, 0.85, (s * 0.7, 0, 2.38), pele, rot=(0, s * 78, 0), seg=8)
        p.cil(f"Antebraco_{lado}", 0.07, 1.1, (s * 1.18, 0, 2.95), pele, rot=(0, -s * 8, 0), seg=8)
        p.bola(f"Mao_{lado}", 0.18, (s * 1.12, 0, 3.52), pele)
    p.cil("Pires", 0.95, 0.08, (0, 0, 2.58), xicara, seg=16)
    p.cil("Xicara", 0.68, 1.2, (0, 0, 3.2), xicara, r2=0.9, seg=16)
    p.cil("Cafe", 0.84, 0.08, (0, 0, 3.77), cafe, seg=16)
    p.bola("Espuma", (1.15, 1.15, 0.28), (0, 0, 3.82), espuma, seg=(16, 8))
    p.bola("Coracao", (0.4, 0.4, 0.08), (0, -0.1, 3.95), cafe)
    p.anel("Alca", 0.28, 0.08, (0.97, 0, 3.25), xicara, rot=(90, 0, 0))
    p.olhos(3.3, -0.79, 0.62, d=0.44)
    for s in (-1, 1):
        p.bola("Bochecha", (0.24, 0.08, 0.14), (s * 0.5, -0.8, 3.0), rosa)
    p.bola("Boca", (0.28, 0.12, 0.14), (0, -0.8, 2.92), mat("Cappuccina_Batom", (225, 70, 110)))


def trippi(p):
    camarao, faixa = mat("Trippi_Camarao", (250, 110, 40)), mat("Trippi_Faixa", (255, 160, 80))
    gato, listra = mat("Trippi_Gato", (245, 145, 50)), mat("Trippi_Listra", (200, 96, 30))
    focinho, rosa = mat("Trippi_Focinho", (252, 236, 210)), mat("Trippi_Rosa", (240, 140, 155))
    segs = [((1.3, 0.62, 1.05), 0.35, 1.3, 0), ((1.18, 0.58, 0.98), 0.9, 1.35, -6), ((1.05, 0.52, 0.88), 1.4, 1.27, -18),
            ((0.9, 0.48, 0.75), 1.82, 1.08, -35), ((0.72, 0.42, 0.6), 2.12, 0.82, -55)]
    for tam, y, z, r in segs:
        p.caixa("Segmento", tam, (0, y, z), camarao, rot=(r, 0, 0))
        p.caixa("Listra", (tam[0] + 0.03, 0.1, tam[2] + 0.03), (0, y + tam[1] / 2 - 0.05, z), faixa, rot=(r, 0, 0), bev=0.02)
    p.cone("Leque", 0.65, 0.6, (0, 2.42, 0.5), camarao, rot=(-140, 0, 0), seg=4, esc=(1.5, 0.25, 1))
    for y in (-0.1, 0.25, 0.6, 0.95, 1.3, 1.6):
        for s in (-1, 1):
            p.cil("Patinha", 0.055, 0.5, (s * 0.55, y, 0.62), camarao, rot=(0, s * 35, 0), seg=6)
            p.cil("Patinha_Ponta", 0.045, 0.45, (s * 0.72, y - 0.05, 0.2), camarao, rot=(15, -s * 10, 0), seg=6)
    p.bola("Cabeca", (1.9, 1.6, 1.6), (0, -0.6, 2.05), gato)
    for k in (-1, 0, 1):
        p.caixa("Listra_Gato", (0.14, 1.0, 0.1), (k * 0.32, -0.5, 2.8), listra, rot=(0, k * 22, 0), bev=0.02)
    for s in (-1, 1):
        for k in (0, 1):
            p.caixa("Listra_Bochecha", (0.3, 0.1, 0.08), (s * 0.85, -0.9, 2.0 + k * 0.22), listra, rot=(0, s * 15, 0), bev=0.02)
    p.bola("Focinho", (0.95, 0.5, 0.58), (0, -1.3, 1.72), focinho)
    p.cone("Nariz", 0.14, 0.12, (0, -1.56, 1.9), rosa, rot=(180, 0, 0), seg=3)
    for s, lado in LADOS:
        p.cone(f"Orelha_{lado}", 0.4, 0.6, (s * 0.6, -0.55, 2.9), gato, rot=(0, s * 15, 45))
        p.cone(f"Orelha_Dentro_{lado}", 0.24, 0.4, (s * 0.6, -0.68, 2.85), rosa, rot=(0, s * 15, 45))
        for k in (-1, 0, 1):
            p.caixa(f"Bigode_{lado}", (0.95, 0.03, 0.03), (s * 0.85, -1.4, 1.72 + k * 0.08), focinho, rot=(0, s * k * 10, 0), bev=0.0)
        p.cil(f"Antena_{lado}", 0.035, 2.6, (s * 0.45, 0.35, 3.55), camarao, rot=(-42, s * 15, 0), seg=6)
    p.olhos(2.25, -1.3, 0.72, d=0.52)


def frigo(p):
    geladeira, camelo = mat("Frigo_Geladeira", (242, 243, 246)), mat("Frigo_Camelo", (210, 165, 105))
    focinho, bota = mat("Frigo_Focinho", (232, 198, 145)), mat("Frigo_Bota", (120, 72, 38))
    for x, y in ((-0.45, -0.3), (0.45, -0.3), (-0.45, 0.4), (0.45, 0.4)):
        p.caixa("Sola", (0.48, 0.7, 0.1), (x, y - 0.1, 0.05), PRETO(), bev=0.03)
        p.caixa("Bota", (0.45, 0.65, 0.35), (x, y - 0.1, 0.27), bota)
        p.caixa("Cano_Bota", (0.36, 0.38, 0.35), (x, y, 0.62), bota)
        p.cil("Perna", 0.11, 0.7, (x, y, 1.1), camelo, seg=8)
    p.caixa("Geladeira", (1.5, 1.3, 1.8), (0, 0, 2.3), geladeira, bev=0.12)
    p.caixa("Porta", (1.4, 0.05, 1.65), (0, -0.66, 2.3), mat("Frigo_Porta", (232, 234, 238)), bev=0.0)
    p.caixa("Puxador", (0.08, 0.12, 0.75), (0.5, -0.72, 2.3), PRATA(), bev=0.02)
    pinos(p, 0, 0, 3.2, 3, 3, 0.4, geladeira)
    p.cil("Pescoco", 0.34, 1.5, (0.35, 0.25, 3.95), camelo, rot=(-8, 0, 0), seg=10)
    p.caixa("Cabeca", (0.95, 1.25, 0.9), (0.35, -0.1, 5.05), camelo)
    p.caixa("Focinho", (0.72, 0.5, 0.55), (0.35, -0.8, 4.9), focinho)
    p.caixa("Boca", (0.5, 0.06, 0.05), (0.35, -1.06, 4.75), PRETO(), bev=0.0)
    p.bola("Narina_E", 0.07, (0.22, -1.05, 5.02), PRETO())
    p.bola("Narina_D", 0.07, (0.48, -1.05, 5.02), PRETO())
    for s, lado in LADOS:
        p.bola(f"Orelha_{lado}", (0.3, 0.16, 0.2), (0.35 + s * 0.5, 0.0, 5.5), camelo, rot=(0, s * 30, 0))
    p.olhos(5.28, -0.72, 0.48, d=0.38, x0=0.35)


def tralalero(p):
    azul, barriga = mat("Tralalero_Pele", (30, 112, 214)), mat("Tralalero_Barriga", (242, 245, 248))
    tenis = mat("Tralalero_Tenis", (35, 95, 230))
    for x, y in ((-0.42, -0.5), (0.42, -0.5), (0.0, 1.0)):
        p.caixa("Sola", (0.55, 1.0, 0.14), (x, y - 0.15, 0.07), BRANCO(), bev=0.04)
        p.caixa("Tenis", (0.5, 0.92, 0.36), (x, y - 0.15, 0.3), tenis)
        p.caixa("Perna", (0.32, 0.36, 0.95), (x, y, 0.95), azul)
    p.bola("Corpo", (1.5, 3.4, 1.5), (0, 0.25, 1.95), azul, seg=(14, 10))
    p.bola("Barriga", (1.3, 3.0, 0.85), (0, 0.0, 1.62), barriga, seg=(14, 10))
    p.bola("Focinho", (1.25, 1.1, 1.0), (0, -1.3, 2.0), azul)
    p.bola("Queixo", (1.05, 0.85, 0.5), (0, -1.35, 1.6), barriga)
    p.cone("Barbatana", 0.6, 1.0, (0, 0.05, 2.95), azul, rot=(-25, 0, 0), seg=3, esc=(0.3, 1.3, 1))
    p.cone("Cauda_Cima", 0.45, 1.3, (0, 2.15, 2.5), azul, rot=(-40, 0, 0), seg=3, esc=(0.25, 1, 1))
    p.cone("Cauda_Baixo", 0.35, 0.8, (0, 2.05, 1.45), azul, rot=(-140, 0, 0), seg=3, esc=(0.25, 1, 1))
    for s, lado in LADOS:
        p.cone(f"Nadadeira_{lado}", 0.4, 0.95, (s * 0.9, -0.3, 1.55), azul, rot=(-20, s * 110, 0), seg=3, esc=(1, 0.3, 1))
        for k in range(3):
            p.caixa(f"Guelra_{lado}", (0.04, 0.05, 0.4), (s * 0.73, -0.7 + k * 0.16, 1.95), mat("Tralalero_Guelra", (20, 80, 160)), bev=0.0)
    p.olhos(2.3, -1.45, 0.75, d=0.42)


def glorbo(p):
    casca, listra = mat("Glorbo_Melancia", (70, 168, 52)), mat("Glorbo_Listra", (24, 92, 34))
    polpa, croc = mat("Glorbo_Polpa", (225, 50, 55)), mat("Glorbo_Croco", (54, 150, 50))
    claro, boca = mat("Glorbo_Barriga", (150, 205, 90)), mat("Glorbo_Boca", (180, 40, 50))
    for x, y in ((-0.85, -0.4), (0.85, -0.4), (-0.85, 1.2), (0.85, 1.2)):
        p.caixa("Perna", (0.42, 0.45, 0.6), (x, y, 0.42), croc)
        p.caixa("Pe", (0.55, 0.7, 0.2), (x, y - 0.15, 0.1), croc)
        for k in (-1, 0, 1):
            p.cone("Garra", 0.06, 0.2, (x + k * 0.17, y - 0.55, 0.08), DENTE(), rot=(90, 0, 0), seg=6)
    p.bola("Melancia", (2.1, 2.9, 2.0), (0, 0.4, 1.55), casca, seg=(16, 12))
    for a in range(0, 180, 30):
        p.bola("Listra", (0.2, 2.94, 2.04), (0, 0.4, 1.55), listra, rot=(0, a, 0), seg=(16, 12))
    p.cil("Corte", 0.9, 0.1, (0, 1.78, 1.55), polpa, rot=(90, 0, 0), seg=16)
    p.anel("Corte_Borda", 0.92, 0.06, (0, 1.79, 1.55), mat("Glorbo_Borda", (240, 245, 220)), rot=(90, 0, 0))
    for x, z in ((-0.4, 1.8), (0.35, 1.9), (0.0, 1.35), (-0.5, 1.25), (0.5, 1.3), (0.05, 2.05)):
        p.bola("Semente", (0.1, 0.06, 0.16), (x, 1.84, z), PRETO())
    p.cone("Rabo", 0.4, 1.4, (0, 2.3, 0.75), croc, rot=(-80, 0, 0), seg=6)
    p.caixa("Cabeca", (1.3, 1.1, 0.95), (0, -1.15, 1.95), croc)
    p.caixa("Focinho", (1.0, 1.3, 0.35), (0, -2.1, 2.0), croc, rot=(-10, 0, 0))
    p.caixa("Mandibula", (0.95, 1.25, 0.28), (0, -2.0, 1.48), claro, rot=(8, 0, 0))
    p.caixa("Dentro_Boca", (0.85, 1.1, 0.25), (0, -1.95, 1.72), boca, bev=0.04)
    for i in range(6):
        y = -1.55 - i * 0.2
        for s in (-1, 1):
            p.cone("Dente", 0.05, 0.16, (s * 0.42, y, 1.84), DENTE(), rot=(180, 0, 45))
            p.cone("Dente", 0.05, 0.14, (s * 0.4, y, 1.64), DENTE(), seg=4)
    p.bola("Narina_E", 0.08, (-0.2, -2.7, 2.28), PRETO())
    p.bola("Narina_D", 0.08, (0.2, -2.7, 2.28), PRETO())
    for s in (-1, 1):
        p.bola("Calombo", (0.55, 0.55, 0.5), (s * 0.35, -1.3, 2.45), croc)
    p.olhos(2.55, -1.55, 0.72, d=0.46)


def cocofanto(p):
    coco, coco2 = mat("Cocofanto_Coco", (120, 66, 30)), mat("Cocofanto_Coco_Escuro", (88, 46, 22))
    cinza, marfim = mat("Cocofanto_Elefante", (160, 164, 170)), mat("Cocofanto_Marfim", (250, 246, 230))
    for x, y in ((-0.75, -0.55), (0.75, -0.55), (-0.75, 1.2), (0.75, 1.2)):
        p.caixa("Pata", (0.6, 0.6, 1.0), (x, y, 0.5), cinza)
        for k in (-1, 0, 1):
            p.bola("Unha", (0.14, 0.08, 0.12), (x + k * 0.17, y - 0.3, 0.1), marfim)
    p.bola("Coco", (2.4, 2.7, 2.3), (0, 0.4, 2.0), coco, seg=(14, 10))
    pontos = []
    for i in range(18):
        a = math.radians(i * 41)
        z = 1.3 + (i * 0.29) % 1.5
        rz = math.sqrt(max(0.1, 1 - ((z - 2.0) / 1.15) ** 2))
        pontos.append((math.sin(a) * 1.2 * rz, 0.4 + math.cos(a) * 1.35 * rz, z))
    manchas(p, "Fibra", pontos, (0.32, 0.32, 0.18), (coco2,))
    p.bola("Cabeca", (1.55, 1.4, 1.5), (0, -1.0, 2.75), cinza)
    for s, lado in LADOS:
        p.caixa(f"Orelha_{lado}", (0.2, 1.2, 1.5), (s * 1.05, -0.75, 2.9), cinza, rot=(0, 0, s * -25))
        p.cone(f"Presa_{lado}", 0.09, 0.6, (s * 0.38, -1.75, 2.3), marfim, rot=(75, 0, s * 12), seg=8)
    p.cil("Tromba", 0.24, 0.9, (0, -1.7, 2.35), cinza, rot=(-25, 0, 0), r2=0.2, seg=10)
    p.cil("Tromba_Ponta", 0.19, 0.55, (0, -1.95, 1.8), cinza, rot=(20, 0, 0), r2=0.16, seg=10)
    p.olhos(3.0, -1.62, 0.66, d=0.46)


def bombardiro(p):
    aviao, croc = mat("Bombardiro_Aviao", (98, 112, 58)), mat("Bombardiro_Croco", (64, 128, 48))
    barriga, vidro = mat("Bombardiro_Mandibula", (190, 200, 120)), mat("Bombardiro_Vidro", (120, 180, 220), rough=0.1)
    boca = mat("Bombardiro_Boca", (180, 40, 50))
    for x in (-0.7, 0.7):
        p.cil("Roda", 0.3, 0.22, (x, -0.1, 0.3), BORRACHA(), rot=(0, 90, 0), seg=12)
        p.caixa("Trem", (0.1, 0.1, 0.55), (x, -0.1, 0.75), PRATA())
    p.cil("Roda_Cauda", 0.15, 0.12, (0, 2.2, 0.55), BORRACHA(), rot=(0, 90, 0), seg=10)
    p.caixa("Fuselagem", (1.15, 3.4, 1.05), (0, 0.6, 1.45), aviao)
    p.caixa("Cabine", (0.85, 0.7, 0.35), (0, -0.35, 2.05), vidro, bev=0.08)
    p.caixa("Asas", (5.6, 1.1, 0.16), (0, 0.45, 1.55), aviao, bev=0.06)
    pinos(p, 0, 0.45, 1.63, 8, 1, 0.65, aviao, r=0.13)
    p.caixa("Estabilizador", (2.0, 0.55, 0.12), (0, 2.15, 1.75), aviao)
    p.caixa("Leme", (0.12, 0.7, 1.0), (0, 2.2, 2.25), aviao)
    for s in (-1, 1):
        x = s * 1.6
        p.cil("Motor", 0.28, 1.0, (x, 0.0, 1.45), aviao, rot=(90, 0, 0), seg=12)
        p.cone("Cubo_Helice", 0.16, 0.3, (x, -0.65, 1.45), PRATA(), rot=(90, 0, 0), seg=10)
        for k in range(3):
            p.caixa("Pa_Helice", (0.14, 0.05, 0.6), (x, -0.6, 1.45), PRETO(), bev=0.02)
            dobrar(p.partes[-1], (x, -0.6, 1.45), (0, 1, 0), k * 120)
        for k in (-1, 1):
            p.cil("Bomba", 0.13, 0.55, (x * 0.6 + k * 0.18, 0.5, 1.2), aviao, rot=(90, 0, 0), seg=10)
    p.caixa("Cabeca", (1.3, 1.1, 1.05), (0, -1.45, 1.65), croc)
    p.caixa("Focinho", (0.95, 1.5, 0.32), (0, -2.65, 1.72), croc, rot=(-8, 0, 0))
    p.caixa("Mandibula", (0.9, 1.45, 0.25), (0, -2.55, 1.18), barriga, rot=(6, 0, 0))
    p.caixa("Dentro_Boca", (0.8, 1.3, 0.25), (0, -2.5, 1.42), boca, bev=0.04)
    for i in range(6):
        y = -2.0 - i * 0.2
        for s in (-1, 1):
            p.cone("Dente", 0.05, 0.16, (s * 0.42, y, 1.55), DENTE(), rot=(180, 0, 45), seg=4)
            p.cone("Dente", 0.05, 0.14, (s * 0.4, y, 1.33), DENTE(), seg=4)
    p.bola("Narina_E", 0.09, (-0.18, -3.35, 1.98), PRETO())
    p.bola("Narina_D", 0.09, (0.18, -3.35, 1.98), PRETO())
    for s in (-1, 1):
        p.bola("Calombo", (0.5, 0.5, 0.45), (s * 0.35, -1.75, 2.12), croc)
    p.olhos(2.22, -1.98, 0.7, d=0.45)


def gusini(p):
    ganso, jato = mat("Gusini_Ganso", (246, 246, 246)), mat("Gusini_Jato", (140, 146, 156), metal=0.4)
    bico, escuro = mat("Gusini_Bico", (255, 140, 30)), mat("Gusini_Jato_Escuro", (70, 74, 82))
    vidro = mat("Gusini_Vidro", (120, 140, 160), rough=0.1)
    for s, lado in LADOS:
        p.caixa(f"Perna_{lado}", (0.2, 0.2, 0.6), (s * 0.4, 0, 0.45), bico)
        p.cone(f"Pe_{lado}", 0.48, 0.14, (s * 0.42, -0.25, 0.07), bico, seg=3, rot=(0, 0, 90), esc=(1, 1.2, 1))
    p.bola("Corpo", (1.55, 1.45, 2.3), (0, 0.1, 1.85), ganso, seg=(14, 10))
    p.cil("Pescoco", 0.3, 1.3, (0, -0.15, 3.35), ganso, seg=10)
    p.bola("Cabeca", (1.0, 1.05, 0.95), (0, -0.25, 4.15), ganso)
    p.caixa("Bico", (0.55, 0.85, 0.26), (0, -1.05, 4.05), bico, bev=0.08)
    p.caixa("Bico_Baixo", (0.46, 0.7, 0.14), (0, -0.98, 3.88), mat("Gusini_Bico_Escuro", (225, 110, 20)), bev=0.05)
    p.caixa("Cabine", (0.7, 0.9, 0.4), (0, 0.7, 2.75), vidro, bev=0.12)
    for s, lado in LADOS:
        p.caixa(f"Asa_{lado}", (1.9, 1.1, 0.14), (s * 1.6, 0.25, 2.35), jato, rot=(0, s * -8, s * 18), bev=0.05)
        p.cone(f"Asa_Ponta_{lado}", 0.25, 0.6, (s * 2.4, 0.5, 2.55), jato, rot=(0, 0, 0), seg=3, esc=(0.3, 1, 1))
        p.cil(f"Turbina_{lado}", 0.4, 1.1, (s * 1.1, 0.1, 2.05), jato, rot=(90, 0, 0), seg=12)
        p.cil(f"Entrada_{lado}", 0.3, 0.05, (s * 1.1, -0.47, 2.05), escuro, rot=(90, 0, 0), seg=12)
        p.cil(f"Missil_{lado}", 0.1, 1.0, (s * 1.95, 0.2, 1.95), BRANCO(), rot=(90, 0, 0), seg=8)
        p.cone(f"Missil_Ponta_{lado}", 0.1, 0.25, (s * 1.95, -0.42, 1.95), mat("Gusini_Vermelho", (220, 40, 40)), rot=(90, 0, 0), seg=8)
    p.olhos(4.3, -0.62, 0.5, d=0.38)


def svinino(p):
    porco, granada = mat("Svinino_Porco", (250, 160, 185)), mat("Svinino_Granada", (82, 96, 40))
    sulco, focinho = mat("Svinino_Sulco", (52, 64, 26)), mat("Svinino_Focinho", (240, 125, 155))
    for x, y in ((-0.6, -0.35), (0.6, -0.35), (-0.6, 1.05), (0.6, 1.05)):
        p.caixa("Pata", (0.38, 0.4, 0.75), (x, y, 0.42), porco)
        p.caixa("Casco", (0.4, 0.42, 0.12), (x, y, 0.06), mat("Svinino_Casco", (200, 90, 120)), bev=0.03)
    p.bola("Granada", (2.0, 2.2, 2.1), (0, 0.4, 1.75), granada, seg=(16, 12))
    for z in (-0.5, 0.0, 0.5):
        r = math.sqrt(max(0.0, 1 - (z / 1.05) ** 2))
        p.anel("Sulco", 1.0 * r + 0.01, 0.04, (0, 0.4, 1.75 + z), sulco, esc=(1, 1.1, 1), n=24)
    for a in (0, 45, 90, 135):
        p.bola("Sulco", (0.06, 2.24, 2.14), (0, 0.4, 1.75), sulco, rot=(0, 0, a), seg=(16, 12))
    p.cil("Espoleta", 0.3, 0.4, (0, 0.45, 2.95), granada, seg=12)
    p.caixa("Alavanca", (0.22, 0.25, 1.6), (0, 1.0, 2.4), granada, rot=(-25, 0, 0), bev=0.05)
    p.anel("Argola", 0.28, 0.05, (0.35, 0.3, 3.0), PRATA(), rot=(0, 90, 0), n=14)
    p.bola("Cabeca", (1.35, 1.15, 1.25), (0, -0.85, 2.0), porco)
    p.cil("Focinho", 0.34, 0.3, (0, -1.5, 1.85), focinho, rot=(90, 0, 0), seg=12)
    p.bola("Narina_E", (0.1, 0.06, 0.14), (-0.12, -1.66, 1.85), mat("Svinino_Narina", (150, 60, 80)))
    p.bola("Narina_D", (0.1, 0.06, 0.14), (0.12, -1.66, 1.85), mat("Svinino_Narina", (150, 60, 80)))
    for s, lado in LADOS:
        p.caixa(f"Orelha_{lado}", (0.55, 0.12, 0.5), (s * 0.65, -0.8, 2.65), porco, rot=(15, 0, s * -30))
        p.caixa(f"Orelha_Dentro_{lado}", (0.35, 0.05, 0.3), (s * 0.63, -0.86, 2.62), focinho, rot=(15, 0, s * -30), bev=0.02)
    p.olhos(2.3, -1.35, 0.6, d=0.42)


def udin(p):
    laranja, laranja2 = mat("Udin_Laranja", (255, 130, 20)), mat("Udin_Laranja_Escura", (232, 104, 12))
    folha, talo = mat("Udin_Folha", (70, 160, 50)), mat("Udin_Talo", (95, 70, 35))
    for s, lado in LADOS:
        x = s * 0.5
        p.caixa(f"Tenis_{lado}", (0.6, 1.0, 0.38), (x, -0.15, 0.24), BRANCO())
        p.caixa(f"Sola_{lado}", (0.62, 1.02, 0.1), (x, -0.15, 0.05), mat("Udin_Sola", (220, 220, 225)), bev=0.03)
        p.caixa(f"Perna_{lado}", (0.4, 0.42, 0.9), (x, 0, 0.85), laranja)
    p.bola("Laranja", (2.4, 2.2, 2.4), (0, 0, 2.4), laranja, seg=(16, 12))
    for i in range(14):
        a = math.radians(i * 47 + 10)
        z = 1.7 + (i * 0.23) % 1.4
        rz = math.sqrt(max(0.1, 1 - ((z - 2.4) / 1.2) ** 2))
        p.bola("Poro", 0.14, (math.sin(a) * 1.18 * rz, -math.cos(a) * 1.08 * rz, z), laranja2, seg=(6, 4))
    p.cil("Talo", 0.08, 0.35, (0, 0, 3.7), talo, seg=6)
    p.bola("Folha", (0.8, 0.35, 0.14), (0.4, 0, 3.8), folha, rot=(0, -20, 0))
    for s, lado in LADOS:
        p.bola(f"Ombro_{lado}", (0.75, 0.75, 0.75), (s * 1.25, 0, 2.5), laranja)
        p.bola(f"Biceps_{lado}", (1.0, 0.7, 0.7), (s * 1.75, 0, 2.6), laranja)
        p.caixa(f"Antebraco_{lado}", (0.45, 0.45, 0.85), (s * 2.12, 0, 3.05), laranja, rot=(0, -s * 10, 0))
        p.caixa(f"Punho_{lado}", (0.6, 0.6, 0.55), (s * 2.15, 0, 3.55), laranja2)
    p.olhos(2.7, -1.0, 0.75, d=0.52, bravo=True, triste=True)
    p.caixa("Boca", (0.45, 0.1, 0.08), (0, -1.12, 2.05), PRETO(), bev=0.0)
    for s in (-1, 1):
        p.caixa("Canto_Boca", (0.22, 0.1, 0.08), (s * 0.3, -1.1, 1.99), PRETO(), rot=(0, s * 40, 0), bev=0.0)


# ---------------------------------------------------------------- os 5 chefes

def sahur(p):
    madeira, escura = mat("Sahur_Madeira", (178, 96, 44)), mat("Sahur_Madeira_Escura", (130, 66, 28))
    for s, lado in LADOS:
        p.caixa(f"Pe_{lado}", (0.5, 0.8, 0.2), (s * 0.42, -0.15, 0.1), madeira)
        p.caixa(f"Perna_{lado}", (0.28, 0.3, 1.3), (s * 0.42, 0, 0.85), madeira)
    p.caixa("Tronco", (1.35, 1.05, 3.4), (0, 0, 3.15), madeira, bev=0.1)
    for x in (-0.45, 0.0, 0.45):
        p.caixa("Veio", (0.06, 1.07, 3.2), (x, 0, 3.15), escura, bev=0.0)
    pinos(p, 0, 0, 4.85, 2, 2, 0.5, madeira)
    p.caixa("Braco_E", (0.25, 0.28, 1.6), (-0.95, 0, 3.2), madeira, rot=(0, 18, 0))
    p.caixa("Mao_E", (0.3, 0.3, 0.3), (-1.2, 0, 2.38), madeira)
    p.caixa("Braco_D", (0.25, 0.28, 1.3), (1.0, -0.15, 3.45), madeira, rot=(-20, -40, 0))
    mao, ang = Vector((1.4, -0.35, 3.0)), math.radians(-25)
    p.caixa("Mao_D", (0.32, 0.32, 0.32), tuple(mao), madeira)
    eixo = Vector((math.sin(ang), 0, math.cos(ang)))
    c = mao + eixo * 1.1
    p.cil("Taco", 0.1, 2.6, tuple(c), escura, rot=(0, -25, 0), r2=0.28, seg=10)
    for t in (1.4, 1.65, 1.9, 2.15):
        for sinal in (-1, 1):
            q = mao + eixo * t + Vector((math.cos(ang), 0, -math.sin(ang))) * 0.27 * sinal
            p.cone("Prego", 0.04, 0.25, tuple(q), PRATA(), rot=(0, sinal * 90 - 25, 0), seg=6)
    p.olhos(4.3, -0.55, 0.6, d=0.5)
    p.caixa("Nariz", (0.22, 0.25, 0.4), (0, -0.62, 3.85), madeira)
    p.caixa("Boca", (0.6, 0.2, 0.55), (0, -0.53, 3.25), BOCA(), bev=0.06)
    for x in (-0.18, 0.0, 0.18):
        p.caixa("Dente", (0.14, 0.1, 0.14), (x, -0.62, 3.45), DENTE(), bev=0.02)
    p.bola("Lingua", (0.35, 0.15, 0.2), (0, -0.6, 3.08), LINGUA())


def assassino(p):
    copo, tampa = mat("Assassino_Copo", (240, 226, 196)), mat("Assassino_Tampa", (30, 28, 30))
    ninja = mat("Assassino_Ninja", (26, 26, 30))
    lamina = mat("Assassino_Lamina", (215, 222, 232), rough=0.1, metal=0.9)
    for s, lado in LADOS:
        p.caixa(f"Pe_{lado}", (0.45, 0.7, 0.25), (s * 0.4, -0.12, 0.13), ninja)
        p.caixa(f"Perna_{lado}", (0.25, 0.28, 0.8), (s * 0.4, 0, 0.65), ninja)
    p.cil("Copo", 0.75, 2.2, (0, 0, 2.15), copo, r2=0.95, seg=18)
    p.cil("Mascara", 0.83, 0.6, (0, 0, 2.05), ninja, r2=0.87, seg=18)
    p.cil("Bandana", 0.92, 0.38, (0, 0, 2.95), ninja, r2=0.94, seg=18)
    p.cil("Tampa", 1.0, 0.18, (0, 0, 3.32), tampa, seg=18)
    p.cil("Tampa_Domo", 0.94, 0.3, (0, 0, 3.55), tampa, r2=0.78, seg=18)
    pinos(p, 0, 0, 3.7, 3, 3, 0.42, tampa)
    p.caixa("Bandana_Ponta", (0.14, 0.75, 0.14), (1.05, 0.3, 3.0), ninja, rot=(20, 0, -40))
    p.caixa("Bandana_Ponta", (0.14, 0.65, 0.14), (1.05, 0.1, 2.85), ninja, rot=(-15, 0, -55))
    for s, lado in LADOS:
        p.caixa(f"Braco_{lado}", (0.24, 0.26, 1.0), (s * 1.1, -0.1, 1.85), ninja, rot=(0, -s * 45, 0))
        p.caixa(f"Mao_{lado}", (0.3, 0.3, 0.3), (s * 1.45, -0.15, 1.5), ninja)
        lam = p.caixa(f"Katana_{lado}", (0.1, 0.04, 2.0), (s * 1.45, -0.15, 2.65), lamina, bev=0.02)
        dobrar(lam, (s * 1.45, -0.15, 1.5), (0, 1, 0), s * 25)
        gua = p.caixa(f"Guarda_{lado}", (0.32, 0.18, 0.06), (s * 1.45, -0.15, 1.65), OURO(), bev=0.02)
        dobrar(gua, (s * 1.45, -0.15, 1.5), (0, 1, 0), s * 25)
        cab = p.caixa(f"Cabo_{lado}", (0.1, 0.1, 0.45), (s * 1.45, -0.15, 1.4), ninja, bev=0.02)
        dobrar(cab, (s * 1.45, -0.15, 1.5), (0, 1, 0), s * 25)
    p.olhos(2.62, -0.88, 0.72, d=0.48)


def cacto(p):
    verde, verde2 = mat("Cacto_Cacto", (40, 140, 40)), mat("Cacto_Cacto_Escuro", (28, 105, 30))
    hipo, hipo2 = mat("Cacto_Hipopotamo", (140, 118, 168)), mat("Cacto_Focinho", (172, 150, 196))
    espinho, sandalia = mat("Cacto_Espinho", (240, 222, 140)), mat("Cacto_Sandalia", (130, 78, 36))
    for s, lado in LADOS:
        x = s * 0.48
        p.caixa(f"Sandalia_{lado}", (0.75, 1.0, 0.15), (x, -0.1, 0.08), sandalia, bev=0.05)
        p.caixa(f"Pe_{lado}", (0.62, 0.85, 0.32), (x, -0.08, 0.3), verde)
        p.caixa(f"Tira_{lado}", (0.7, 0.18, 0.18), (x, -0.32, 0.4), sandalia, bev=0.05)
    p.caixa("Corpo", (1.5, 1.3, 3.2), (0, 0, 2.05), verde, bev=0.25)
    for x in (-0.45, 0.0, 0.45):
        p.caixa("Gomo", (0.08, 1.32, 3.0), (x, 0, 2.05), verde2, bev=0.0)
    for s, lado in LADOS:
        p.caixa(f"Braco_{lado}", (0.75, 0.5, 0.5), (s * 1.05, 0, 2.0), verde)
        p.caixa(f"Braco_Sobe_{lado}", (0.5, 0.5, 1.5), (s * 1.3, 0, 2.75), verde, bev=0.15)
    pts = [(-0.6, -0.68, 1.0), (0.2, -0.68, 1.35), (0.6, -0.68, 1.8), (-0.25, -0.68, 2.2), (0.35, -0.68, 2.7),
           (-0.55, -0.68, 3.0), (0.0, -0.68, 3.3), (-0.2, -0.68, 0.7), (0.55, -0.68, 0.85)]
    for x, y, z in pts:
        p.cone("Espinho", 0.05, 0.22, (x, y - 0.08, z), espinho, rot=(90, 0, 0), seg=6)
    for s in (-1, 1):
        for z in (2.5, 3.0, 3.4):
            p.cone("Espinho", 0.05, 0.22, (s * 1.58, 0, z), espinho, rot=(0, s * 90, 0), seg=6)
    p.caixa("Cabeca", (1.3, 1.1, 0.95), (0, -0.1, 4.05), hipo, bev=0.2)
    p.caixa("Focinho", (1.4, 0.75, 0.75), (0, -0.75, 3.85), hipo2, bev=0.2)
    p.bola("Narina_E", (0.18, 0.1, 0.1), (-0.32, -0.95, 4.22), mat("Cacto_Narina", (90, 70, 110)))
    p.bola("Narina_D", (0.18, 0.1, 0.1), (0.32, -0.95, 4.22), mat("Cacto_Narina", (90, 70, 110)))
    for s, lado in LADOS:
        p.bola(f"Orelha_{lado}", (0.3, 0.18, 0.3), (s * 0.55, 0.05, 4.6), hipo)
        p.cone(f"Presa_{lado}", 0.08, 0.25, (s * 0.5, -1.1, 3.62), DENTE(), seg=6)
    p.olhos(4.4, -0.65, 0.62, d=0.44)


def toasterino(p):
    lata, rino = mat("Toasterino_Torradeira", (182, 186, 192), rough=0.2, metal=0.6), mat("Toasterino_Rino", (140, 142, 150))
    chifre, torrada = mat("Toasterino_Chifre", (210, 210, 215)), mat("Toasterino_Torrada", (238, 196, 120))
    crosta = mat("Toasterino_Crosta", (150, 85, 35))
    for x, y in ((-0.65, -0.35), (0.65, -0.35), (-0.65, 0.95), (0.65, 0.95)):
        p.caixa("Pata", (0.5, 0.55, 0.85), (x, y, 0.42), rino)
    p.caixa("Torradeira", (1.9, 1.9, 1.5), (0, 0.4, 1.55), lata, bev=0.2)
    for s in (-1, 1):
        p.caixa("Fenda", (0.3, 1.2, 0.06), (s * 0.4, 0.45, 2.3), PRETO(), bev=0.0)
        p.caixa("Torrada", (0.26, 1.1, 0.9), (s * 0.4, 0.45, 2.7), torrada, bev=0.06)
        p.caixa("Torrada_Crosta", (0.28, 1.14, 0.14), (s * 0.4, 0.45, 3.17), crosta, bev=0.04)
        p.caixa("Fenda_Lado", (0.05, 0.25, 0.7), (s * 0.96, 0.6, 1.65), PRETO(), bev=0.0)
        p.caixa("Alavanca", (0.12, 0.3, 0.12), (s * 1.0, 0.6, 1.95), PRETO())
    p.caixa("Cabeca", (1.3, 1.2, 1.2), (0, -0.85, 1.9), rino)
    p.caixa("Focinho", (1.1, 0.75, 0.8), (0, -1.6, 1.6), rino)
    p.cone("Chifre", 0.32, 1.15, (0, -1.85, 2.4), chifre, rot=(22, 0, 0), seg=8)
    p.cone("Chifre_2", 0.16, 0.42, (0, -1.25, 2.6), chifre, rot=(10, 0, 0), seg=8)
    p.bola("Narina_E", 0.09, (-0.25, -1.99, 1.62), PRETO())
    p.bola("Narina_D", 0.09, (0.25, -1.99, 1.62), PRETO())
    for s, lado in LADOS:
        p.cone(f"Orelha_{lado}", 0.2, 0.45, (s * 0.55, -0.55, 2.65), rino, rot=(0, s * 25, 0))
    p.olhos(2.15, -1.47, 0.82, d=0.4)
    p.caixa("Boca", (0.7, 0.06, 0.05), (0, -1.99, 1.35), PRETO(), bev=0.0)


def saturnita(p):
    planeta, faixa = mat("Saturnita_Planeta", (242, 232, 205)), mat("Saturnita_Faixa", (222, 210, 180))
    ouro, pele = mat("Saturnita_Anel", (240, 186, 40), rough=0.25, metal=0.5), mat("Saturnita_Pe", (232, 182, 142))
    vaca = mat("Saturnita_Vaca", (248, 248, 246))
    for s, lado in LADOS:
        pe_humano(p, lado, s * 0.6, pele, tam=(0.85, 1.4, 0.42), y=-0.3)
        p.caixa(f"Perna_{lado}", (0.5, 0.55, 0.7), (s * 0.55, 0, 0.75), pele)
    p.bola("Planeta", (2.5, 2.5, 2.3), (0, 0, 2.05), planeta, seg=(18, 12))
    for z in (-0.6, -0.2, 0.25):
        r = math.sqrt(max(0.0, 1 - (z / 1.15) ** 2)) * 2.5 + 0.03
        p.bola("Faixa", (r, r, 0.12), (0, 0, 2.05 + z), faixa, seg=(18, 6))
    p.anel("Anel", 1.9, 0.45, (0, 0, 2.0), ouro, rot=(6, 0, 0), n=32, esc=(1, 1, 0.28))
    p.bola("Cabeca", (1.2, 1.1, 1.05), (0, -0.25, 3.45), vaca)
    for x, y, z, t in ((-0.35, -0.75, 3.75, 0.4), (0.4, -0.65, 3.2, 0.35), (0.5, -0.2, 3.8, 0.4), (-0.5, -0.3, 3.2, 0.3)):
        p.bola("Mancha", (t, 0.15, t * 0.8), (x, y, z), PRETO())
    p.caixa("Focinho", (0.8, 0.45, 0.45), (0, -0.85, 3.15), mat("Saturnita_Focinho", (255, 172, 186)))
    p.bola("Narina_E", (0.1, 0.06, 0.08), (-0.18, -1.08, 3.18), PRETO())
    p.bola("Narina_D", (0.1, 0.06, 0.08), (0.18, -1.08, 3.18), PRETO())
    for s, lado in LADOS:
        p.cone(f"Chifre_{lado}", 0.11, 0.55, (s * 0.55, -0.2, 4.05), mat("Saturnita_Chifre", (236, 222, 176)), rot=(0, s * 35, 0), seg=8)
        p.caixa(f"Orelha_{lado}", (0.5, 0.12, 0.28), (s * 0.75, -0.3, 3.65), vaca, rot=(0, s * 20, 0))
        p.caixa(f"Orelha_Dentro_{lado}", (0.32, 0.05, 0.16), (s * 0.75, -0.37, 3.65), mat("Saturnita_Focinho", (255, 172, 186)), rot=(0, s * 20, 0), bev=0.02)
    p.olhos(3.6, -0.72, 0.5, d=0.38)


# Ordem e dados vindos de src/shared/Config.luau (BRAINROTS e BIOMAS).
COMUNS = [
    ("Patapim", "Brr Brr Patapim", "Comum", patapim),
    ("Larila", "Lirilì Larilà", "Comum", larila),
    ("Bananini", "Chimpanzini Bananini", "Raro", bananini),
    ("Ambalabu", "Boneca Ambalabu", "Raro", ambalabu),
    ("Cappuccina", "Ballerina Cappuccina", "Epico", cappuccina),
    ("Trippi", "Trippi Troppi", "Epico", trippi),
    ("Frigo", "Frigo Camelo", "Epico", frigo),
    ("Tralalero", "Tralalero Tralala", "Lendario", tralalero),
    ("Glorbo", "Glorbo Fruttodrillo", "Lendario", glorbo),
    ("Cocofanto", "Cocofanto Elefanto", "Lendario", cocofanto),
    ("Bombardiro", "Bombardiro Crocodilo", "Mitico", bombardiro),
    ("Gusini", "Bombombini Gusini", "Mitico", gusini),
    ("Svinino", "Svinino Bombondino", "Mitico", svinino),
    ("Udin", "Udin Din Din Dun", "Secreto", udin),
]
CHEFES = [
    ("Sahur", "Tung Tung Tung Sahur", "Chefe", sahur, 2.0),
    ("Assassino", "Cappuccino Assassino", "Chefe", assassino, 1.9),
    ("Cacto", "Il Cacto Hipopotamo", "Chefe", cacto, 1.8),
    ("Toasterino", "Rhino Toasterino", "Chefe", toasterino, 1.8),
    ("Saturnita", "La Vaca Saturno Saturnita", "Chefe", saturnita, 1.7),
]

# ---------------------------------------------------------------- cena


def limpar():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)
    for blocos in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras):
        for b in list(blocos):
            blocos.remove(b)


def olhar_para(ob, alvo):
    d = Vector(alvo) - ob.location
    ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


def montar_estudio(cena):
    col = bpy.data.collections.new("APRESENTACAO")
    cena.collection.children.link(col)
    chao_m = mat("Estudio_Fundo", (214, 216, 222), rough=0.6)
    me = bpy.data.meshes.new("Estudio_Chao")
    bm = bmesh.new()
    # Fundo infinito: chão que sobe em curva atrás dos personagens.
    perfil = [(-60, 0)] + [(34 + 25 * math.sin(math.radians(a)), 25 - 25 * math.cos(math.radians(a))) for a in range(0, 91, 10)] + [(55, 80)]
    linhas = []
    for x in (-120, 120):
        linhas.append([bm.verts.new((x, y, z)) for y, z in perfil])
    for i in range(len(perfil) - 1):
        bm.faces.new((linhas[0][i], linhas[1][i], linhas[1][i + 1], linhas[0][i + 1]))
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    me.materials.append(chao_m)
    chao = bpy.data.objects.new("Estudio_Chao", me)
    col.objects.link(chao)

    def luz(nome, tipo, energia, loc, alvo, tam=10.0, cor=(1, 1, 1)):
        ld = bpy.data.lights.new(nome, tipo)
        ld.energy = energia
        ld.color = cor
        if tipo == "AREA":
            ld.size = tam
        elif tipo == "SUN":
            ld.angle = math.radians(8)
        ob = bpy.data.objects.new(nome, ld)
        ob.location = loc
        olhar_para(ob, alvo)
        col.objects.link(ob)
        return ob

    luz("Luz_Principal", "SUN", 3.2, (-20, -30, 40), (0, 0, 0), cor=(1.0, 0.97, 0.92))
    luz("Luz_Preenchimento", "SUN", 1.0, (30, -25, 12), (0, 0, 0), cor=(0.9, 0.95, 1.0))
    luz("Luz_Recorte", "SUN", 1.8, (0, 40, 25), (0, 0, 0))

    w = cena.world or bpy.data.worlds.new("Mundo")
    cena.world = w
    try:
        w.use_nodes = True
    except Exception:
        pass
    bg = w.node_tree.nodes.get("Background")
    bg.inputs[0].default_value = (0.62, 0.64, 0.68, 1)
    bg.inputs[1].default_value = 0.9

    cam_d = bpy.data.cameras.new("Camera")
    cam = bpy.data.objects.new("Camera", cam_d)
    col.objects.link(cam)
    cena.camera = cam
    return col, cam


def configurar_render(cena):
    motor = os.environ.get("BR_ENGINE", "EEVEE").upper()
    if motor == "EEVEE":
        for nome in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
            try:
                cena.render.engine = nome
                break
            except TypeError:
                continue
        try:
            cena.eevee.taa_render_samples = 64
            cena.eevee.use_shadows = True
        except Exception:
            pass
    elif motor == "CYCLES":
        cena.render.engine = "CYCLES"
        cena.cycles.samples = 64
        cena.cycles.use_denoising = True
    else:
        cena.render.engine = "BLENDER_WORKBENCH"
    cena.view_settings.view_transform = "Standard"
    try:
        cena.view_settings.look = "None"
    except Exception:
        pass
    cena.render.image_settings.file_format = "PNG"
    cena.render.film_transparent = False


def main():
    limpar()
    cena = bpy.context.scene
    cena.name = "Brainrots"
    cena.unit_settings.system = "METRIC"
    raiz = bpy.data.collections.new("BRAINROTS")
    cena.collection.children.link(raiz)
    col_comuns, col_chefes = bpy.data.collections.new("COMUNS"), bpy.data.collections.new("BOSSES")
    raiz.children.link(col_comuns)
    raiz.children.link(col_chefes)

    personagens = []
    for ident, nome, rar, fn in COMUNS:
        p = Personagem(ident, nome, rar, col_comuns)
        fn(p)
        p.finalizar()
        personagens.append(p)
    for ident, nome, rar, fn, esc in CHEFES:
        p = Personagem(ident, nome, rar, col_chefes, chefe=True, escala=esc)
        fn(p)
        p.finalizar()
        personagens.append(p)

    col_estudio, cam = montar_estudio(cena)
    configurar_render(cena)

    # Grade: 2 fileiras de 7 comuns na frente, chefes atrás num palco.
    palco_m, podio_m = mat("Estudio_Palco", (60, 55, 80), rough=0.4), mat("Estudio_Podio", (255, 196, 40), rough=0.25, metal=0.6)
    palco = bpy.data.objects.new("Estudio_Palco", bpy.data.meshes.new("Estudio_Palco"))
    bm = _bm_caixa((48, 9, 1.0), 0.15)
    _xform(bm, (0, 25, 0.5), (0, 0, 0), (1, 1, 1))
    bm.to_mesh(palco.data)
    bm.free()
    palco.data.materials.append(palco_m)
    col_estudio.objects.link(palco)
    for i, p in enumerate(personagens):
        if not p.chefe:
            linha, coluna = divmod(i, 7)
            p.raiz.location = ((coluna - 3) * 5.6 + linha * 2.8 - 1.4, linha * 9.0, 0)
        else:
            k = i - len(COMUNS)
            x = (k - 2) * 9.2
            p.raiz.location = (x, 25, 1.25)
            pod = bpy.data.objects.new(f"Estudio_Podio_{p.id}", bpy.data.meshes.new(f"Estudio_Podio_{p.id}"))
            bm = _bm_cilindro(3.4, 3.2, 0.25, 24)
            _xform(bm, (x, 25, 1.12), (0, 0, 0), (1, 1, 1))
            bm.to_mesh(pod.data)
            bm.free()
            pod.data.materials.append(podio_m)
            col_estudio.objects.link(pod)
    bpy.context.view_layer.update()

    renders = os.path.join(PASTA, "renders")
    fbx = os.path.join(PASTA, "fbx")
    os.makedirs(renders, exist_ok=True)
    os.makedirs(fbx, exist_ok=True)

    # Exporta um FBX por personagem, com os pés na origem.
    for p in personagens:
        guardado = p.raiz.location.copy()
        p.raiz.location = (0, 0, 0)
        bpy.context.view_layer.update()
        bpy.ops.object.select_all(action="DESELECT")
        for ob in p.partes:
            ob.select_set(True)
        bpy.context.view_layer.objects.active = p.partes[0]
        bpy.ops.export_scene.fbx(
            filepath=os.path.join(fbx, f"{p.id}.fbx"), use_selection=True, object_types={"MESH"},
            global_scale=STUD_EM_METROS, apply_unit_scale=True, apply_scale_options="FBX_SCALE_NONE",
            axis_forward="Z", axis_up="Y", mesh_smooth_type="FACE", colors_type="SRGB",
            use_mesh_modifiers=True, add_leaf_bones=False, bake_anim=False, path_mode="AUTO")
        p.raiz.location = guardado
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.update()

    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(PASTA, "brainrots.blend"), compress=True)

    if os.environ.get("BR_SEM_RENDER"):
        return

    # Render de apresentação.
    cena.render.resolution_x, cena.render.resolution_y = 2400, 1350
    cam.data.lens = 38
    cam.location = (0, -40, 30)
    olhar_para(cam, (0, 11.5, 3.0))
    for p in personagens:
        p.raiz.rotation_euler.z = math.radians(-28)
    cena.render.filepath = os.path.join(renders, "apresentacao.png")
    bpy.ops.render.render(write_still=True)
    print("RENDER apresentacao", flush=True)

    for p in personagens:
        p.raiz.rotation_euler.z = 0
    # Um render de cada, com os outros escondidos.
    cena.render.resolution_x = cena.render.resolution_y = 1024
    cam.data.lens = 50
    for ob in col_estudio.objects:
        if ob.name.startswith(("Estudio_Palco", "Estudio_Podio")):
            ob.hide_render = True
    for p in personagens:
        for q in personagens:
            q.col.hide_render = q is not p
        base = p.raiz.location
        centro = base + (p.min + p.max) / 2
        tam = max(p.max.z, p.max.x - p.min.x, p.max.y - p.min.y) * 1.1
        dist = tam / (2 * math.tan(math.atan(18 / 50))) + (p.max.y - p.min.y) / 2
        ang = math.radians(12)
        giro = math.radians(32)
        cam.location = centro + Vector((-math.sin(giro) * dist * math.cos(ang), -math.cos(giro) * dist * math.cos(ang), dist * math.sin(ang)))
        olhar_para(cam, centro)
        cena.render.filepath = os.path.join(renders, f"{p.id}.png")
        bpy.ops.render.render(write_still=True)
        print("RENDER", p.id, flush=True)
    for q in personagens:
        q.col.hide_render = False
    for ob in col_estudio.objects:
        ob.hide_render = False


main()

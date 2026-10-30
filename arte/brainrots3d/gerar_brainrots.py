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

    def anel(self, nome, R, r, loc, m, rot=(0, 0, 0), n=20):
        bm = _bm_anel(R, r, n)
        _xform(bm, loc, rot, (1, 1, 1))
        return self._add(nome, bm, m)

    # ---- padrões repetidos em todos os personagens

    def olhos(self, z, y, sep, d=0.62, x0=0.0, bravo=None, olhar=(0.0, 0.0)):
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
                           (x, y - d * 0.2, z + d * 0.62), SOBRANCELHA(), rot=(0, s * 22, 0))

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


def patapim(p):
    pele, nariz = mat("Patapim_Pele", (228, 175, 135)), mat("Patapim_Nariz", (214, 140, 112))
    musgo, musgo2 = mat("Patapim_Musgo", (78, 112, 42)), mat("Patapim_Musgo_Claro", (122, 156, 62))
    casca, rosto = mat("Patapim_Casca", (100, 72, 44)), mat("Patapim_Rosto", (196, 150, 108))
    for s, lado in LADOS:
        pe_humano(p, lado, s * 0.55, pele, tam=(0.85, 1.4, 0.4), y=-0.3)
        p.cil(f"Raiz_Perna_{lado}", 0.15, 0.95, (s * 0.45, 0, 0.85), casca, rot=(0, -s * 8, 0), seg=8)
        p.cil(f"Raiz_{lado}", 0.07, 0.6, (s * 0.75, 0.1, 0.55), casca, rot=(0, s * 35, 0), seg=6)
    p.caixa("Tronco", (1.2, 0.9, 1.05), (0, 0, 1.75), casca)
    for x, y, z, r in ((-0.35, -0.47, 1.9, 10), (0.4, -0.47, 1.55, -15), (0.5, 0.3, 2.0, 30), (-0.55, 0.2, 1.4, -5)):
        p.caixa("Musgo", (0.5, 0.25, 0.4), (x, y, z), musgo2, rot=(0, r, 0))
    bracos(p, casca, 0.6, 2.1, comp=0.95, r=0.09, abre=40, mao=casca)
    p.caixa("Cabeca", (2.0, 1.7, 1.8), (0, 0, 3.1), musgo)
    p.caixa("Rosto", (1.45, 0.3, 1.25), (0, -0.78, 3.05), rosto)
    for i, (x, y, r) in enumerate([(-0.65, -0.3, 15), (0.0, 0.0, -20), (0.65, -0.2, 35), (-0.3, 0.5, 50), (0.45, 0.5, -10)]):
        p.caixa("Cabelo_Musgo", (0.75, 0.75, 0.45), (x, y, 4.05 + (i % 2) * 0.12), musgo2 if i % 2 else musgo, rot=(0, 0, r))
    for x, z, w in ((0, 2.25, 1.7), (-0.55, 2.05, 0.5), (0.5, 2.0, 0.55), (0.0, 1.95, 0.6)):
        p.caixa("Barba", (w, 0.55, 0.55), (x, -0.62, z), musgo2)
    p.cil("Nariz", 0.36, 0.95, (0, -1.15, 2.85), nariz, rot=(-35, 0, 0), r2=0.24, seg=10)
    p.bola("Ponta_Nariz", (0.8, 0.7, 0.75), (0, -1.38, 2.42), nariz)
    p.olhos(3.35, -0.95, 0.75, d=0.5)


def larila(p):
    cacto, cacto2 = mat("Larila_Cacto", (112, 162, 72)), mat("Larila_Cacto_Escuro", (78, 124, 50))
    espinho, sandalia = mat("Larila_Espinho", (242, 236, 200)), mat("Larila_Sandalia", (140, 92, 50))
    tira = mat("Larila_Tira", (98, 60, 30))
    for s, lado in LADOS:
        x = s * 0.45
        p.caixa(f"Sandalia_{lado}", (0.8, 1.05, 0.14), (x, -0.1, 0.07), sandalia, bev=0.04)
        p.cil(f"Pata_{lado}", 0.33, 0.85, (x, 0, 0.56), cacto, seg=10)
        p.caixa(f"Tira_{lado}", (0.74, 0.16, 0.16), (x, -0.32, 0.3), tira, bev=0.04)
        p.caixa(f"Tira_Cruzada_{lado}", (0.16, 0.7, 0.14), (x, -0.05, 0.42), tira, rot=(25, 0, 0), bev=0.04)
        for k in (-1, 0, 1):
            p.bola(f"Unha_{lado}", (0.16, 0.08, 0.12), (x + k * 0.18, -0.34, 0.2), espinho)
    p.caixa("Corpo", (1.55, 1.25, 1.6), (0, 0, 1.75), cacto)
    for x in (-0.5, 0.0, 0.5):
        p.caixa("Gomo", (0.1, 0.06, 1.5), (x, -0.64, 1.75), cacto2, bev=0.0)
    bracos(p, cacto, 0.75, 2.3, comp=0.85, r=0.2, abre=22)
    p.bola("Cabeca", (2.0, 1.8, 1.8), (0, 0, 3.25), cacto)
    for s, lado in LADOS:
        orelha = p.caixa(f"Orelha_{lado}", (0.16, 1.1, 1.3), (s * 1.12, 0.15, 3.25), cacto2, rot=(0, 0, s * -25))
        for k in (-0.25, 0.25):
            p.caixa(f"Gomo_Orelha_{lado}", (0.18, 0.05, 1.0), (s * 1.12 + k * 0.1, -0.1 + k, 3.25), cacto, rot=(0, 0, s * -25), bev=0.0)
    p.cil("Tromba", 0.27, 0.9, (0, -0.95, 2.7), cacto, rot=(-15, 0, 0), r2=0.22, seg=10)
    p.cil("Tromba_Ponta", 0.2, 0.55, (0, -1.15, 2.1), cacto, rot=(25, 0, 0), r2=0.17, seg=10)
    for x, y, z in ((-0.55, -0.66, 2.2), (0.55, -0.66, 2.2), (-0.25, -0.66, 1.45), (0.25, -0.66, 1.45), (-0.55, -0.66, 1.2),
                    (0.55, -0.66, 1.6), (-0.6, -0.55, 3.75), (0.6, -0.55, 3.75), (0.0, -0.3, 4.1), (-0.85, -0.2, 3.0), (0.85, -0.2, 3.0)):
        p.cone("Espinho", 0.05, 0.22, (x, y - 0.08, z), espinho, rot=(90, 0, 0), seg=6)
    # Despertador ao lado.
    rel = mat("Larila_Relogio", (220, 60, 50))
    p.cil("Relogio", 0.45, 0.32, (1.55, -0.1, 0.62), rel, rot=(90, 0, 0), seg=16)
    p.cil("Relogio_Mostrador", 0.36, 0.05, (1.55, -0.27, 0.62), BRANCO(), rot=(90, 0, 0), seg=16)
    p.caixa("Ponteiro", (0.05, 0.04, 0.26), (1.55, -0.31, 0.7), PRETO(), bev=0.01)
    p.caixa("Ponteiro_2", (0.2, 0.04, 0.05), (1.62, -0.31, 0.62), PRETO(), bev=0.01)
    for s in (-1, 1):
        p.bola("Sino", (0.3, 0.3, 0.22), (1.55 + s * 0.28, -0.1, 1.05), OURO())
        p.cil("Pe_Relogio", 0.05, 0.2, (1.55 + s * 0.28, -0.1, 0.1), PRETO(), seg=6)
    p.olhos(3.45, -0.82, 0.8, d=0.52)


def bananini(p):
    banana, dentro = mat("Bananini_Banana", (255, 214, 50)), mat("Bananini_Casca_Dentro", (250, 238, 170))
    talo, pelo = mat("Bananini_Talo", (95, 70, 35)), mat("Bananini_Macaco", (118, 138, 56))
    rosto = mat("Bananini_Rosto", (226, 186, 146))
    p.cil("Talo", 0.18, 0.25, (0, 0, 0.12), talo, seg=8)
    p.cil("Banana", 0.5, 1.1, (0, 0, 0.8), banana, r2=0.64, seg=8)
    for i in range(4):
        a = math.radians(i * 90 + 45)
        x, y = math.sin(a) * 0.62, -math.cos(a) * 0.62
        c = p.caixa("Casca", (0.62, 0.14, 1.2), (x, y, 0.8), banana, rot=(0, 0, math.degrees(-a)), bev=0.05)
        dobrar(c, (x, y, 1.35), (math.cos(a), math.sin(a), 0), 28)
        d = p.caixa("Casca_Dentro", (0.5, 0.06, 1.05), (x * 0.9, y * 0.9, 0.85), dentro, rot=(0, 0, math.degrees(-a)), bev=0.02)
        dobrar(d, (x, y, 1.35), (math.cos(a), math.sin(a), 0), 28)
        ponta = p.caixa("Casca_Ponta", (0.5, 0.15, 0.15), (x, y, 0.22), talo, rot=(0, 0, math.degrees(-a)), bev=0.04)
        dobrar(ponta, (x, y, 1.35), (math.cos(a), math.sin(a), 0), 28)
    p.caixa("Peito", (1.15, 0.9, 0.9), (0, 0, 1.75), pelo)
    p.caixa("Barriga", (0.7, 0.1, 0.6), (0, -0.46, 1.7), rosto)
    for s, lado in LADOS:
        p.cil(f"Braco_{lado}", 0.15, 0.9, (s * 0.75, -0.2, 1.55), pelo, rot=(25, -s * 30, 0), seg=8)
        p.bola(f"Mao_{lado}", (0.35, 0.35, 0.3), (s * 0.95, -0.45, 1.2), rosto)
    p.bola("Cabeca", (1.8, 1.6, 1.7), (0, 0, 2.95), pelo)
    p.caixa("Testa", (1.5, 0.4, 0.35), (0, -0.6, 3.35), pelo)
    p.bola("Rosto", (1.3, 0.7, 1.2), (0, -0.55, 2.85), rosto)
    p.bola("Focinho", (0.95, 0.55, 0.6), (0, -0.85, 2.5), rosto)
    p.bola("Narina_E", 0.08, (-0.12, -1.12, 2.62), PRETO())
    p.bola("Narina_D", 0.08, (0.12, -1.12, 2.62), PRETO())
    for s, lado in LADOS:
        p.bola(f"Orelha_{lado}", (0.3, 0.5, 0.55), (s * 0.95, 0, 3.0), rosto)
    p.olhos(3.02, -0.95, 0.62, d=0.5)
    p.boca(2.35, -1.1, 0.5, alt=0.14, dentes=False)


def ambalabu(p):
    sapo, papo = mat("Ambalabu_Sapo", (92, 172, 62)), mat("Ambalabu_Papo", (205, 222, 120))
    pele, pneu = mat("Ambalabu_Pele", (232, 186, 148)), BORRACHA()
    for s, lado in LADOS:
        pe_humano(p, lado, s * 0.35, pele, tam=(0.45, 0.8, 0.26), y=-0.12)
        p.cil(f"Perna_{lado}", 0.14, 1.0, (s * 0.35, 0, 0.75), pele, seg=10)
        p.bola(f"Joelho_{lado}", 0.32, (s * 0.35, -0.02, 0.75), pele)
    p.anel("Pneu", 0.72, 0.36, (0, 0, 1.95), pneu, rot=(90, 0, 0), n=18)
    for i in range(18):
        a = math.radians(i * 20)
        p.caixa("Cravo_Pneu", (0.2, 0.62, 0.12), (math.cos(a) * 1.08, 0, 1.95 + math.sin(a) * 1.08), pneu, rot=(0, -math.degrees(a) + 90, 0), bev=0.03)
    p.cil("Calota", 0.42, 0.34, (0, 0, 1.95), PRATA(), rot=(90, 0, 0), seg=12)
    p.cil("Calota_Furo", 0.15, 0.36, (0, 0, 1.95), PRETO(), rot=(90, 0, 0), seg=10)
    p.bola("Cabeca", (2.4, 1.8, 1.15), (0, 0.05, 3.3), sapo)
    p.bola("Papo", (2.0, 1.4, 0.6), (0, -0.2, 3.0), papo)
    for s in (-1, 1):
        p.bola("Palpebra", (0.85, 0.8, 0.8), (s * 0.6, -0.25, 3.75), sapo)
    p.olhos(3.82, -0.62, 1.2, d=0.62)
    p.caixa("Boca", (1.9, 0.18, 0.1), (0, -0.85, 3.12), mat("Ambalabu_Boca", (190, 55, 75)), bev=0.04)
    for s in (-1, 1):
        p.caixa("Canto_Boca", (0.3, 0.18, 0.1), (s * 1.0, -0.75, 3.18), mat("Ambalabu_Boca", (190, 55, 75)), rot=(0, s * -30, s * 30), bev=0.04)


def cappuccina(p):
    rosa, rosa2 = mat("Cappuccina_Tutu", (255, 168, 200)), mat("Cappuccina_Tutu_Claro", (255, 210, 228))
    xicara, cafe = mat("Cappuccina_Xicara", (246, 242, 236)), mat("Cappuccina_Cafe", (125, 82, 50))
    espuma, pele = mat("Cappuccina_Espuma", (238, 210, 170)), mat("Cappuccina_Pele", (242, 202, 172))
    p.cone("Sapatilha_E", 0.17, 0.4, (-0.22, 0, 0.2), rosa, rot=(180, 0, 0), seg=8)
    p.cil("Perna_E", 0.1, 1.05, (-0.22, 0, 0.9), pele, seg=8)
    p.cil("Perna_D", 0.1, 0.8, (0.35, -0.2, 0.95), pele, rot=(-30, -25, 0), seg=8)
    p.cone("Sapatilha_D", 0.15, 0.35, (0.55, -0.45, 0.55), rosa, rot=(150, -25, 0), seg=8)
    p.cil("Tutu", 1.15, 0.2, (0, 0, 1.45), rosa, r2=0.9, seg=16)
    p.cil("Tutu_2", 0.95, 0.18, (0, 0, 1.6), rosa2, r2=0.6, seg=16)
    p.cil("Corpete", 0.32, 0.65, (0, 0, 1.95), rosa, r2=0.36, seg=10)
    for s, lado in LADOS:
        p.cil(f"Braco_{lado}", 0.08, 0.9, (s * 0.7, 0, 2.1), pele, rot=(0, s * 75, 0), seg=8)
        p.cil(f"Antebraco_{lado}", 0.07, 1.4, (s * 1.25, 0, 2.85), pele, rot=(0, -s * 12, 0), seg=8)
        p.bola(f"Mao_{lado}", 0.2, (s * 1.12, 0, 3.55), pele)
    p.cil("Pires", 1.0, 0.1, (0, 0, 2.33), xicara, seg=16)
    p.cil("Xicara", 0.72, 1.3, (0, 0, 3.0), xicara, r2=0.95, seg=16)
    p.cil("Cafe", 0.88, 0.08, (0, 0, 3.62), cafe, seg=16)
    p.bola("Espuma", (1.2, 1.2, 0.35), (0, 0, 3.67), espuma, seg=(16, 8))
    p.bola("Coracao", (0.35, 0.35, 0.1), (0, -0.1, 3.84), cafe)
    p.anel("Alca", 0.3, 0.09, (1.02, 0, 3.05), xicara, rot=(90, 0, 0))
    p.olhos(3.15, -0.83, 0.72, d=0.5)
    for s in (-1, 1):
        p.bola("Bochecha", (0.28, 0.08, 0.16), (s * 0.58, -0.84, 2.82), rosa)
    p.bola("Boca", (0.32, 0.12, 0.16), (0, -0.84, 2.72), mat("Cappuccina_Batom", (220, 50, 90)))


def trippi(p):
    camarao, faixa = mat("Trippi_Camarao", (255, 128, 88)), mat("Trippi_Faixa", (255, 188, 150))
    gato, listra = mat("Trippi_Gato", (236, 140, 58)), mat("Trippi_Listra", (186, 92, 34))
    focinho, rosa = mat("Trippi_Focinho", (250, 240, 225)), mat("Trippi_Rosa", (240, 130, 150))
    segs = [((1.15, 0.6, 0.95), 0.3, 1.45, 0), ((1.05, 0.55, 0.9), 0.82, 1.5, -6), ((0.95, 0.5, 0.82), 1.3, 1.42, -18),
            ((0.82, 0.45, 0.7), 1.72, 1.22, -35), ((0.68, 0.4, 0.58), 2.02, 0.95, -55)]
    for tam, y, z, r in segs:
        p.caixa("Segmento", tam, (0, y, z), camarao, rot=(r, 0, 0))
        p.caixa("Listra", (tam[0] + 0.03, 0.1, tam[2] + 0.03), (0, y + tam[1] / 2 - 0.05, z), faixa, rot=(r, 0, 0), bev=0.02)
    p.cone("Leque", 0.6, 0.55, (0, 2.3, 0.6), camarao, rot=(-140, 0, 0), seg=4, esc=(1.5, 0.25, 1))
    for i, y in enumerate((0.15, 0.6, 1.05, 1.45)):
        for s in (-1, 1):
            p.cil("Patinha", 0.06, 0.85, (s * 0.3, y - 0.05, 0.45), camarao, rot=(10, s * 6, 0), seg=6)
    p.cil("Patinha_Frente", 0.07, 0.9, (-0.3, -0.5, 0.45), camarao, rot=(10, -10, 0), seg=6)
    p.cil("Patinha_Frente", 0.07, 0.9, (0.3, -0.5, 0.45), camarao, rot=(10, 10, 0), seg=6)
    p.bola("Cabeca", (1.75, 1.5, 1.5), (0, -0.55, 1.95), gato)
    for k in (-1, 0, 1):
        p.caixa("Listra_Gato", (0.12, 0.9, 0.08), (k * 0.3, -0.5, 2.68), listra, rot=(0, k * 20, 0), bev=0.02)
    p.bola("Focinho", (0.95, 0.5, 0.6), (0, -1.22, 1.65), focinho)
    p.bola("Nariz", (0.22, 0.12, 0.15), (0, -1.47, 1.82), rosa)
    for s, lado in LADOS:
        p.cone(f"Orelha_{lado}", 0.38, 0.55, (s * 0.55, -0.5, 2.75), gato, rot=(0, s * 15, 45))
        p.cone(f"Orelha_Dentro_{lado}", 0.22, 0.38, (s * 0.55, -0.62, 2.7), rosa, rot=(0, s * 15, 45))
        for k in (-1, 1):
            p.caixa(f"Bigode_{lado}", (0.75, 0.03, 0.03), (s * 0.75, -1.3, 1.68 + k * 0.08), PRETO(), rot=(0, s * k * 12, 0), bev=0.0)
        p.cil(f"Antena_{lado}", 0.035, 2.4, (s * 0.35, 0.3, 3.4), camarao, rot=(-40, s * 12, 0), seg=6)
    p.olhos(2.15, -1.2, 0.7, d=0.52)
    p.boca(1.4, -1.3, 0.35, alt=0.12, dentes=False)


def frigo(p):
    geladeira, camelo = mat("Frigo_Geladeira", (240, 242, 245)), mat("Frigo_Camelo", (205, 160, 100))
    focinho, bota = mat("Frigo_Focinho", (225, 190, 135)), mat("Frigo_Bota", (120, 75, 40))
    for s, lado in LADOS:
        x = s * 0.4
        p.caixa(f"Sola_{lado}", (0.62, 1.0, 0.12), (x, -0.15, 0.06), PRETO(), bev=0.04)
        p.caixa(f"Bota_{lado}", (0.58, 0.95, 0.4), (x, -0.15, 0.3), bota)
        p.caixa(f"Cano_{lado}", (0.46, 0.5, 0.55), (x, 0.05, 0.75), bota)
        p.cil(f"Perna_{lado}", 0.12, 0.5, (x, 0.05, 1.2), camelo, seg=8)
    p.caixa("Geladeira", (1.4, 1.15, 2.3), (0, 0, 2.55), geladeira)
    p.caixa("Divisao", (1.42, 0.05, 0.05), (0, -0.58, 3.05), mat("Frigo_Junta", (160, 170, 180)), bev=0.0)
    p.caixa("Puxador", (0.08, 0.12, 0.7), (0.5, -0.62, 2.3), PRATA(), bev=0.02)
    p.caixa("Puxador_2", (0.08, 0.12, 0.35), (0.5, -0.62, 3.3), PRATA(), bev=0.02)
    pinos(p, 0.35, 0.3, 3.7, 2, 2, 0.35, geladeira)
    p.cil("Pescoco", 0.28, 1.3, (-0.2, -0.55, 4.15), camelo, rot=(20, 0, 0), seg=10)
    p.caixa("Cabeca", (1.1, 1.5, 0.95), (-0.2, -1.2, 4.85), camelo)
    p.caixa("Focinho", (0.95, 0.55, 0.7), (-0.2, -2.05, 4.68), focinho)
    p.caixa("Labio", (0.9, 0.35, 0.2), (-0.2, -2.08, 4.32), focinho)
    p.bola("Narina_E", 0.11, (-0.42, -2.34, 4.85), PRETO())
    p.bola("Narina_D", 0.11, (0.02, -2.34, 4.85), PRETO())
    for s, lado in LADOS:
        p.bola(f"Orelha_{lado}", (0.35, 0.18, 0.22), (-0.2 + s * 0.6, -0.7, 5.3), camelo, rot=(0, s * 30, 0))
    p.olhos(5.15, -1.98, 0.62, d=0.46, x0=-0.2)


def tralalero(p):
    azul, barriga = mat("Tralalero_Pele", (112, 150, 188)), mat("Tralalero_Barriga", (240, 244, 248))
    tenis, sola = mat("Tralalero_Tenis", (40, 105, 230)), BRANCO()
    for x, y in ((-0.38, -0.45), (0.38, -0.45), (0.0, 0.95)):
        p.caixa("Sola", (0.5, 0.95, 0.12), (x, y - 0.12, 0.06), sola, bev=0.04)
        p.caixa("Tenis", (0.46, 0.88, 0.32), (x, y - 0.12, 0.26), tenis)
        p.caixa("Faixa_Tenis", (0.48, 0.45, 0.08), (x, y - 0.05, 0.3), sola, rot=(20, 0, 0), bev=0.02)
        p.cil("Perna", 0.13, 0.95, (x, y, 0.85), azul, seg=8)
    p.bola("Corpo", (1.35, 3.3, 1.35), (0, 0.25, 1.85), azul, seg=(14, 10))
    p.bola("Barriga", (1.15, 2.9, 0.8), (0, 0.05, 1.6), barriga, seg=(14, 10))
    p.bola("Focinho", (1.05, 1.0, 0.85), (0, -1.35, 1.95), azul)
    p.cone("Barbatana", 0.55, 0.9, (0, 0.1, 2.8), azul, rot=(-25, 0, 0), seg=3, esc=(0.3, 1.3, 1))
    p.cone("Cauda_Cima", 0.4, 1.1, (0, 2.1, 2.3), azul, rot=(-45, 0, 0), seg=3, esc=(0.25, 1, 1))
    p.cone("Cauda_Baixo", 0.3, 0.7, (0, 2.0, 1.45), azul, rot=(-140, 0, 0), seg=3, esc=(0.25, 1, 1))
    for s, lado in LADOS:
        p.cone(f"Nadadeira_{lado}", 0.35, 0.85, (s * 0.85, -0.3, 1.5), azul, rot=(-20, s * 110, 0), seg=3, esc=(1, 0.3, 1))
        for k in range(3):
            p.caixa(f"Guelra_{lado}", (0.04, 0.05, 0.35), (s * 0.66, -0.75 + k * 0.15, 1.9), mat("Tralalero_Guelra", (80, 110, 140)), bev=0.0)
    p.olhos(2.3, -1.2, 0.75, d=0.5)
    p.boca(1.62, -1.72, 0.8, alt=0.3, presas=True)


def glorbo(p):
    casca, listra = mat("Glorbo_Melancia", (70, 160, 62)), mat("Glorbo_Listra", (30, 92, 34))
    croc, barriga = mat("Glorbo_Croco", (88, 150, 64)), mat("Glorbo_Mandibula", (206, 214, 140))
    for x, y in ((-0.8, -0.5), (0.8, -0.5), (-0.8, 1.1), (0.8, 1.1)):
        p.cil("Perna", 0.24, 0.6, (x, y, 0.4), croc, seg=10)
        p.caixa("Pe", (0.55, 0.7, 0.2), (x, y - 0.15, 0.1), croc)
        for k in (-1, 0, 1):
            p.cone("Garra", 0.06, 0.2, (x + k * 0.17, y - 0.55, 0.08), DENTE(), rot=(90, 0, 0), seg=6)
    p.bola("Melancia", (2.3, 2.6, 2.1), (0, 0.3, 1.6), casca, seg=(16, 12))
    for a in range(0, 180, 30):
        p.bola("Listra", (0.18, 2.64, 2.14), (0, 0.3, 1.6), listra, rot=(0, a, 0), seg=(16, 12))
    p.cone("Rabo", 0.45, 1.7, (0, 2.2, 0.85), croc, rot=(-80, 0, 0), seg=6)
    p.caixa("Cabeca", (1.35, 1.2, 1.0), (0, -1.05, 2.2), croc)
    p.caixa("Focinho", (1.05, 1.3, 0.45), (0, -2.1, 2.0), croc)
    p.caixa("Mandibula", (1.0, 1.25, 0.3), (0, -2.0, 1.62), barriga)
    for i in range(5):
        x = -0.4 + i * 0.2
        p.cone("Dente", 0.06, 0.2, (x, -2.68, 1.85), DENTE(), rot=(180, 0, 45))
    p.bola("Narina_E", 0.1, (-0.2, -2.72, 2.25), PRETO())
    p.bola("Narina_D", 0.1, (0.2, -2.72, 2.25), PRETO())
    for s in (-1, 1):
        p.bola("Calombo", (0.6, 0.6, 0.55), (s * 0.35, -1.25, 2.72), croc)
    p.olhos(2.78, -1.5, 0.72, d=0.48)


def cocofanto(p):
    coco, fibra = mat("Cocofanto_Coco", (112, 72, 40)), mat("Cocofanto_Fibra", (80, 50, 28))
    polpa, elefante = mat("Cocofanto_Polpa", (250, 246, 232)), mat("Cocofanto_Elefante", (150, 138, 130))
    marfim, rosa = mat("Cocofanto_Marfim", (250, 245, 225)), mat("Cocofanto_Rosa", (230, 165, 170))
    for x, y in ((-0.7, -0.5), (0.7, -0.5), (-0.7, 1.15), (0.7, 1.15)):
        p.cil("Pata", 0.33, 0.85, (x, y, 0.42), elefante, seg=10)
        for k in (-1, 0, 1):
            p.bola("Unha", (0.14, 0.08, 0.12), (x + k * 0.16, y - 0.32, 0.1), marfim)
    p.bola("Coco", (2.1, 2.4, 1.9), (0, 0.35, 1.7), coco, seg=(14, 10))
    for i in range(16):
        a = math.radians(i * 22.5)
        p.caixa("Fibra", (0.35, 0.05, 0.05), (math.sin(a) * 1.03, 0.35 + math.cos(a) * 1.18, 1.7 + (i % 3 - 1) * 0.45), fibra,
                rot=(0, 25 * (i % 2 * 2 - 1), -math.degrees(a)), bev=0.0)
    p.anel("Polpa", 0.98, 0.07, (0, -0.68, 1.75), polpa, rot=(90, 0, 0))
    p.bola("Cabeca", (1.6, 1.4, 1.5), (0, -1.05, 2.5), elefante)
    for s, lado in LADOS:
        p.cil(f"Orelha_{lado}", 0.75, 0.12, (s * 1.0, -0.75, 2.6), elefante, rot=(90, 0, s * 30), seg=10)
        p.cil(f"Orelha_Dentro_{lado}", 0.52, 0.06, (s * 0.97, -0.82, 2.6), rosa, rot=(90, 0, s * 30), seg=10)
        p.cone(f"Presa_{lado}", 0.09, 0.6, (s * 0.35, -1.85, 1.95), marfim, rot=(70, 0, s * 15), seg=8)
    p.cil("Tromba", 0.24, 0.9, (0, -1.85, 2.15), elefante, rot=(-20, 0, 0), r2=0.2, seg=10)
    p.cil("Tromba_Ponta", 0.19, 0.5, (0, -2.0, 1.55), elefante, rot=(25, 0, 0), r2=0.16, seg=10)
    p.olhos(2.8, -1.68, 0.7, d=0.48)


def bombardiro(p):
    aviao, croc = mat("Bombardiro_Aviao", (108, 118, 92)), mat("Bombardiro_Croco", (74, 140, 62))
    barriga, vidro = mat("Bombardiro_Mandibula", (200, 210, 140)), mat("Bombardiro_Vidro", (120, 180, 220), rough=0.1)
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
        p.cil("Bomba", 0.18, 0.7, (s * 0.85, 0.5, 1.15), PRETO(), rot=(90, 0, 0), seg=10)
        p.cone("Bomba_Ponta", 0.18, 0.25, (s * 0.85, 0.02, 1.15), PRETO(), rot=(90, 0, 0), seg=10)
    p.caixa("Cabeca", (1.3, 1.1, 1.05), (0, -1.45, 1.65), croc)
    p.caixa("Focinho", (0.95, 1.5, 0.38), (0, -2.65, 1.55), croc)
    p.caixa("Mandibula", (0.9, 1.45, 0.25), (0, -2.55, 1.2), barriga)
    for i in range(6):
        y = -2.0 - i * 0.2
        for s in (-1, 1):
            p.cone("Dente", 0.05, 0.16, (s * 0.42, y, 1.36), DENTE(), rot=(180, 0, 45), seg=4)
    p.bola("Narina_E", 0.09, (-0.18, -3.35, 1.76), PRETO())
    p.bola("Narina_D", 0.09, (0.18, -3.35, 1.76), PRETO())
    for k in range(3):
        p.caixa("Escama", (0.25, 0.25, 0.15), (0, -1.1 + k * 0.35, 2.2), croc, rot=(0, 0, 45))
    for s in (-1, 1):
        p.bola("Calombo", (0.5, 0.5, 0.45), (s * 0.35, -1.75, 2.12), croc)
    p.olhos(2.22, -1.98, 0.7, d=0.45)


def gusini(p):
    ganso, jato = mat("Gusini_Ganso", (244, 244, 244)), mat("Gusini_Jato", (130, 140, 150), metal=0.5)
    bico, fogo = mat("Gusini_Bico", (255, 150, 30)), mat("Gusini_Fogo", (255, 120, 20), emit=4.0)
    for s, lado in LADOS:
        p.cil(f"Perna_{lado}", 0.08, 0.7, (s * 0.35, 0.2, 0.45), bico, seg=6)
        p.cone(f"Pe_{lado}", 0.32, 0.12, (s * 0.35, 0.0, 0.06), bico, seg=3, rot=(0, 0, 90))
    p.bola("Corpo", (1.35, 2.5, 1.25), (0, 0.45, 1.35), ganso, seg=(14, 10))
    p.cone("Rabo", 0.4, 0.6, (0, 1.75, 1.6), ganso, rot=(-70, 0, 0), seg=6)
    for s, lado in LADOS:
        asa = p.caixa(f"Asa_{lado}", (2.1, 1.1, 0.12), (s * 1.55, 0.55, 1.45), jato, rot=(0, s * -6, s * 25), bev=0.05)
        p.cil(f"Turbina_{lado}", 0.24, 0.9, (s * 0.95, 0.75, 1.0), jato, rot=(90, 0, 0), seg=10)
        p.cone(f"Fogo_{lado}", 0.2, 0.6, (s * 0.95, 1.5, 1.0), fogo, rot=(-90, 0, 0), seg=8)
        p.cil(f"Missil_{lado}", 0.1, 0.9, (s * 1.9, 0.4, 1.28), BRANCO(), rot=(90, 0, 0), seg=8)
        p.cone(f"Missil_Ponta_{lado}", 0.1, 0.25, (s * 1.9, -0.17, 1.28), mat("Gusini_Vermelho", (220, 40, 40)), rot=(90, 0, 0), seg=8)
    for s in (-1, 1):
        p.caixa("Leme", (0.1, 0.6, 0.7), (s * 0.3, 1.6, 2.05), jato, rot=(0, s * 15, 0))
    p.cil("Pescoco", 0.24, 1.4, (0, -0.85, 2.15), ganso, rot=(25, 0, 0), seg=10)
    p.bola("Cabeca", (1.2, 1.3, 1.1), (0, -1.25, 2.95), ganso)
    p.caixa("Bico", (0.55, 0.85, 0.24), (0, -2.15, 2.82), bico, bev=0.08)
    p.caixa("Bico_Baixo", (0.48, 0.7, 0.14), (0, -2.08, 2.64), mat("Gusini_Bico_Escuro", (225, 115, 20)), bev=0.05)
    p.olhos(3.15, -1.78, 0.58, d=0.45)


def svinino(p):
    porco, granada = mat("Svinino_Porco", (250, 168, 182)), mat("Svinino_Granada", (70, 76, 66), metal=0.4)
    focinho, metal = mat("Svinino_Focinho", (238, 132, 152)), PRATA()
    for x, y in ((-0.55, -0.4), (0.55, -0.4), (-0.55, 1.0), (0.55, 1.0)):
        p.cil("Pata", 0.18, 0.65, (x, y, 0.38), porco, seg=8)
        p.cil("Casco", 0.19, 0.14, (x, y, 0.07), PRETO(), seg=8)
    p.caixa("Granada", (1.55, 2.1, 1.45), (0, 0.3, 1.4), granada, bev=0.32)
    for i in range(3):
        for k in range(2):
            y, z = -0.35 + i * 0.65, 1.1 + k * 0.6
            for s in (-1, 1):
                p.caixa("Gomo", (0.1, 0.5, 0.45), (s * 0.78, y, z), granada, bev=0.05)
            p.caixa("Gomo", (0.45, 0.5, 0.1), (-0.3 + k * 0.6, y, 2.13), granada, bev=0.05)
    p.cil("Espoleta", 0.25, 0.35, (0, 0.95, 2.3), metal, seg=10)
    p.caixa("Alavanca", (0.25, 1.2, 0.08), (0, 0.6, 2.45), metal, rot=(-12, 0, 0), bev=0.03)
    p.anel("Argola", 0.2, 0.04, (0.35, 1.0, 2.4), metal, rot=(0, 90, 0), n=12)
    p.anel("Rabo", 0.15, 0.06, (0, 1.42, 1.6), porco, rot=(90, 0, 0), n=12)
    p.bola("Cabeca", (1.45, 1.25, 1.35), (0, -1.0, 1.6), porco)
    p.cil("Focinho", 0.32, 0.3, (0, -1.68, 1.45), focinho, rot=(90, 0, 0), seg=12)
    p.bola("Narina_E", (0.09, 0.06, 0.13), (-0.11, -1.84, 1.45), PRETO())
    p.bola("Narina_D", (0.09, 0.06, 0.13), (0.11, -1.84, 1.45), PRETO())
    for s, lado in LADOS:
        p.cone(f"Orelha_{lado}", 0.3, 0.45, (s * 0.5, -0.9, 2.35), porco, rot=(25, s * 35, 0))
    p.olhos(1.95, -1.55, 0.62, d=0.45)


def udin(p):
    laranja, laranja2 = mat("Udin_Laranja", (255, 140, 22)), mat("Udin_Laranja_Escura", (230, 110, 15))
    folha, talo = mat("Udin_Folha", (70, 150, 50)), mat("Udin_Talo", (95, 70, 35))
    for s, lado in LADOS:
        x = s * 0.5
        p.caixa(f"Tenis_{lado}", (0.55, 0.95, 0.35), (x, -0.12, 0.22), BRANCO())
        p.caixa(f"Sola_{lado}", (0.58, 0.98, 0.1), (x, -0.12, 0.05), PRETO(), bev=0.03)
        p.cil(f"Canela_{lado}", 0.2, 0.6, (x, 0, 0.65), laranja, seg=10)
        p.bola(f"Coxa_{lado}", (0.65, 0.65, 0.9), (x, 0, 1.15), laranja)
    p.bola("Laranja", (2.4, 2.2, 2.4), (0, 0, 2.55), laranja, seg=(16, 12))
    for i in range(10):
        a = math.radians(i * 36 + 10)
        p.bola("Poro", 0.12, (math.sin(a) * 1.0, -math.cos(a) * 0.95, 2.55 + (i % 3 - 1) * 0.6), laranja2, seg=(6, 4))
    p.cil("Talo", 0.08, 0.3, (0, 0, 3.8), talo, seg=6)
    p.bola("Folha", (0.7, 0.3, 0.12), (0.35, 0, 3.85), folha, rot=(0, -20, 0))
    for s, lado in LADOS:
        p.bola(f"Ombro_{lado}", (0.7, 0.7, 0.7), (s * 1.25, 0, 2.6), laranja)
        p.bola(f"Biceps_{lado}", (0.95, 0.65, 0.65), (s * 1.75, 0, 2.7), laranja)
        p.cil(f"Antebraco_{lado}", 0.24, 0.85, (s * 2.15, 0, 3.15), laranja, rot=(0, -s * 10, 0), seg=10)
        p.bola(f"Punho_{lado}", 0.58, (s * 2.2, 0, 3.6), laranja2)
    p.olhos(2.95, -1.0, 0.75, d=0.5, bravo=True)
    p.bola("Nariz", (0.4, 0.35, 0.35), (0, -1.15, 2.6), laranja2)
    p.boca(2.15, -1.08, 0.75, alt=0.25)


# ---------------------------------------------------------------- os 5 chefes

def sahur(p):
    madeira, escura = mat("Sahur_Madeira", (206, 138, 78)), mat("Sahur_Madeira_Escura", (160, 100, 55))
    taco = mat("Sahur_Taco", (178, 120, 66))
    for s, lado in LADOS:
        p.cil(f"Perna_{lado}", 0.12, 0.95, (s * 0.35, 0, 0.55), madeira, seg=8)
        p.caixa(f"Pe_{lado}", (0.35, 0.6, 0.18), (s * 0.35, -0.12, 0.09), madeira)
    p.cil("Tronco", 0.72, 3.0, (0, 0, 2.5), madeira, seg=14)
    p.cil("Topo", 0.66, 0.06, (0, 0, 4.02), mat("Sahur_Anel", (232, 186, 130)), seg=14)
    p.anel("Anel_Madeira", 0.35, 0.04, (0, 0, 4.04), escura, n=12)
    for z in (1.4, 1.9):
        p.anel("Veio", 0.73, 0.025, (0, 0, z), escura, n=14)
    p.cil("Braco_E", 0.08, 1.4, (-0.85, 0, 2.55), madeira, rot=(0, 15, 0), seg=8)
    p.bola("Mao_E", 0.25, (-1.03, 0, 1.88), madeira)
    p.cil("Braco_D", 0.08, 1.0, (0.95, -0.1, 2.75), madeira, rot=(0, -50, 0), seg=8)
    p.bola("Mao_D", 0.25, (1.33, -0.2, 2.42), madeira)
    mao, ang = Vector((1.33, -0.2, 2.42)), math.radians(18)
    eixo = Vector((math.sin(ang), 0, math.cos(ang)))
    c = mao + eixo * 1.0
    p.cil("Taco", 0.09, 2.6, (c.x, c.y, c.z), taco, rot=(0, 18, 0), r2=0.24, seg=10)
    normal = Vector((math.cos(ang), 0, -math.sin(ang)))
    for t in (1.5, 1.75, 2.0):
        q = mao + eixo * t + normal * 0.25
        p.cone("Prego", 0.04, 0.25, (q.x, q.y, q.z), PRATA(), rot=(0, 90 + 18, 0), seg=6)
    p.olhos(3.35, -0.72, 0.62, d=0.55)
    p.cil("Nariz", 0.1, 0.3, (0, -0.8, 2.95), madeira, rot=(90, 0, 0), seg=8)
    p.boca(2.55, -0.72, 0.85, alt=0.3, rot=(0, 0, 0))


def assassino(p):
    copo, luva = mat("Assassino_Copo", (240, 228, 205)), mat("Assassino_Luva", (196, 104, 44))
    tampa, ninja = mat("Assassino_Tampa", (35, 30, 30)), mat("Assassino_Ninja", (28, 28, 34))
    lamina = mat("Assassino_Lamina", (225, 230, 240), rough=0.1, metal=0.9)
    placa = mat("Assassino_Placa", (175, 180, 190), rough=0.25, metal=0.8)
    for s, lado in LADOS:
        p.cil(f"Perna_{lado}", 0.09, 0.9, (s * 0.32, 0, 0.6), ninja, seg=8)
        p.caixa(f"Pe_{lado}", (0.32, 0.55, 0.18), (s * 0.32, -0.1, 0.09), ninja)
    p.cil("Copo", 0.68, 2.1, (0, 0, 2.1), copo, r2=0.9, seg=18)
    p.cil("Luva", 0.77, 0.65, (0, 0, 1.75), luva, r2=0.84, seg=18)
    p.cil("Tampa", 0.95, 0.14, (0, 0, 3.2), tampa, seg=18)
    p.cil("Tampa_Domo", 0.88, 0.3, (0, 0, 3.42), tampa, r2=0.68, seg=18)
    p.cil("Bico_Tampa", 0.12, 0.08, (0.3, -0.35, 3.6), PRETO(), seg=8)
    p.cil("Bandana", 0.89, 0.32, (0, 0, 2.82), ninja, r2=0.91, seg=18)
    p.caixa("Placa_Ninja", (0.62, 0.1, 0.28), (0, -0.9, 2.82), placa, bev=0.04)
    p.caixa("Risco_Placa", (0.3, 0.04, 0.05), (0, -0.96, 2.82), PRETO(), bev=0.0)
    p.caixa("Bandana_Ponta", (0.14, 0.75, 0.12), (0.2, 1.2, 2.75), ninja, rot=(25, 0, 12))
    p.caixa("Bandana_Ponta", (0.14, 0.7, 0.12), (-0.15, 1.15, 2.65), ninja, rot=(40, 0, -12))
    for s, lado in LADOS:
        p.cil(f"Braco_{lado}", 0.08, 1.0, (s * 1.05, -0.1, 2.0), ninja, rot=(0, -s * 55, 0), seg=8)
        p.bola(f"Mao_{lado}", 0.22, (s * 1.45, -0.15, 1.72), ninja)
        lam = p.caixa(f"Katana_{lado}", (0.09, 0.04, 1.8), (s * 1.45, -0.15, 2.7), lamina, bev=0.02)
        dobrar(lam, (s * 1.45, -0.15, 1.72), (0, 1, 0), s * 20)
        gua = p.caixa(f"Guarda_{lado}", (0.32, 0.18, 0.06), (s * 1.45, -0.15, 1.82), OURO(), bev=0.02)
        dobrar(gua, (s * 1.45, -0.15, 1.72), (0, 1, 0), s * 20)
        cab = p.caixa(f"Cabo_{lado}", (0.09, 0.09, 0.4), (s * 1.45, -0.15, 1.62), ninja, bev=0.02)
        dobrar(cab, (s * 1.45, -0.15, 1.72), (0, 1, 0), s * 20)
    p.olhos(2.38, -0.83, 0.72, d=0.5)
    p.boca(2.0, -0.85, 0.55, alt=0.16, presas=True)


def cacto(p):
    verde, verde2 = mat("Cacto_Cacto", (88, 152, 70)), mat("Cacto_Cacto_Escuro", (60, 115, 48))
    hipo, hipo2 = mat("Cacto_Hipopotamo", (140, 122, 132)), mat("Cacto_Focinho", (172, 148, 158))
    espinho, sandalia = mat("Cacto_Espinho", (245, 240, 200)), mat("Cacto_Sandalia", (140, 92, 50))
    for s, lado in LADOS:
        x = s * 0.42
        p.caixa(f"Sandalia_{lado}", (0.7, 0.95, 0.14), (x, -0.1, 0.07), sandalia, bev=0.04)
        p.cil(f"Pata_{lado}", 0.3, 0.45, (x, 0, 0.36), hipo, seg=10)
        p.caixa(f"Tira_{lado}", (0.66, 0.16, 0.16), (x, -0.28, 0.32), mat("Cacto_Tira", (98, 60, 30)), bev=0.04)
    p.cil("Corpo", 0.8, 3.0, (0, 0, 2.05), verde, seg=10)
    p.bola("Topo", (1.6, 1.6, 0.9), (0, 0, 3.55), verde)
    for i in range(10):
        a = math.radians(i * 36)
        p.caixa("Gomo", (0.08, 0.08, 2.9), (math.sin(a) * 0.8, math.cos(a) * 0.8, 2.05), verde2, bev=0.0)
    for i in range(14):
        a = math.radians(i * 51 + 10)
        z = 0.9 + (i * 0.37) % 2.6
        if abs(math.degrees(a) % 360 - 180) < 40 and z > 2.2:
            continue
        p.cone("Espinho", 0.04, 0.25, (math.sin(a) * 0.86, -math.cos(a) * 0.86, z), espinho,
               rot=(90, 0, math.degrees(a)), seg=6)
    for s, lado in LADOS:
        p.caixa(f"Braco_{lado}", (0.7, 0.45, 0.42), (s * 1.0, 0, 2.0), verde)
        p.caixa(f"Braco_Sobe_{lado}", (0.45, 0.45, 1.2), (s * 1.25, 0, 2.6), verde)
        p.bola(f"Braco_Topo_{lado}", (0.45, 0.45, 0.3), (s * 1.25, 0, 3.2), verde)
    p.caixa("Cabeca", (1.4, 1.0, 1.1), (0, -0.7, 3.05), hipo)
    p.caixa("Focinho", (1.55, 0.75, 0.8), (0, -1.3, 2.8), hipo2)
    p.bola("Narina_E", (0.2, 0.12, 0.1), (-0.4, -1.5, 3.2), PRETO())
    p.bola("Narina_D", (0.2, 0.12, 0.1), (0.4, -1.5, 3.2), PRETO())
    for s, lado in LADOS:
        p.bola(f"Orelha_{lado}", (0.3, 0.18, 0.25), (s * 0.6, -0.5, 3.7), hipo)
        p.cone(f"Presa_{lado}", 0.1, 0.35, (s * 0.55, -1.62, 2.65), DENTE(), seg=6)
    p.olhos(3.58, -1.05, 0.68, d=0.48)
    p.boca(2.5, -1.68, 1.2, alt=0.16, dentes=False)


def toasterino(p):
    lata, cromo = mat("Toasterino_Torradeira", (222, 214, 196), rough=0.2, metal=0.5), PRATA()
    rino, chifre = mat("Toasterino_Rino", (142, 142, 152)), mat("Toasterino_Chifre", (240, 232, 210))
    torrada, crosta = mat("Toasterino_Torrada", (236, 192, 112)), mat("Toasterino_Crosta", (150, 90, 40))
    for x, y in ((-0.65, -0.3), (0.65, -0.3), (-0.65, 0.85), (0.65, 0.85)):
        p.cil("Pata", 0.26, 0.6, (x, y, 0.3), rino, seg=10)
    p.caixa("Torradeira", (2.0, 1.6, 1.5), (0, 0.3, 1.35), lata, bev=0.28)
    p.caixa("Faixa_Cromo", (2.04, 1.64, 0.14), (0, 0.3, 0.9), cromo, bev=0.05)
    for s in (-1, 1):
        p.caixa("Fenda", (0.3, 1.1, 0.06), (s * 0.42, 0.35, 2.1), PRETO(), bev=0.0)
        p.caixa("Torrada", (0.24, 1.0, 0.85), (s * 0.42, 0.35, 2.45), torrada, bev=0.06)
        p.caixa("Torrada_Crosta", (0.26, 1.04, 0.12), (s * 0.42, 0.35, 2.9), crosta, bev=0.04)
    p.cil("Botao", 0.18, 0.12, (1.04, 0.5, 1.6), PRETO(), rot=(0, 90, 0), seg=12)
    p.caixa("Alavanca", (0.18, 0.15, 0.35), (1.05, 0.0, 1.7), PRETO())
    p.caixa("Cabeca", (1.35, 1.2, 1.2), (0, -0.85, 1.75), rino)
    p.caixa("Focinho", (1.15, 0.75, 0.75), (0, -1.65, 1.5), rino)
    p.cone("Chifre", 0.28, 1.05, (0, -1.85, 2.3), chifre, rot=(20, 0, 0), seg=8)
    p.cone("Chifre_2", 0.15, 0.4, (0, -1.25, 2.45), chifre, rot=(10, 0, 0), seg=8)
    p.bola("Narina_E", 0.09, (-0.25, -2.04, 1.55), PRETO())
    p.bola("Narina_D", 0.09, (0.25, -2.04, 1.55), PRETO())
    for s, lado in LADOS:
        p.cone(f"Orelha_{lado}", 0.18, 0.4, (s * 0.55, -0.6, 2.5), rino, rot=(0, s * 25, 0))
    p.olhos(2.08, -1.42, 0.85, d=0.42)
    p.boca(1.25, -2.04, 0.8, alt=0.2, presas=True)


def saturnita(p):
    planeta, faixa = mat("Saturnita_Planeta", (214, 224, 204)), mat("Saturnita_Faixa", (190, 204, 184))
    aneis, aneis2 = mat("Saturnita_Anel", (232, 188, 112)), mat("Saturnita_Anel_2", (196, 132, 72))
    pele, vaca = mat("Saturnita_Pe", (232, 182, 142)), mat("Saturnita_Vaca", (248, 248, 246))
    for s, lado in LADOS:
        pe_humano(p, lado, s * 0.55, pele, tam=(0.8, 1.35, 0.4), y=-0.3)
        p.cil(f"Tornozelo_{lado}", 0.22, 0.5, (s * 0.5, 0, 0.55), pele, seg=10)
    p.bola("Planeta", 2.4, (0, 0, 1.85), planeta, seg=(18, 12))
    for z in (-0.45, 0.4):
        r = math.sqrt(1.2 ** 2 - z ** 2) * 2 + 0.04
        p.bola("Faixa", (r, r, 0.22), (0, 0, 1.85 + z), faixa, seg=(18, 6))
    p.anel("Anel", 1.85, 0.12, (0, 0, 1.85), aneis, rot=(12, -8, 0), n=28)
    p.anel("Anel_2", 2.2, 0.07, (0, 0, 1.85), aneis2, rot=(12, -8, 0), n=28)
    p.bola("Cabeca", (1.35, 1.15, 1.15), (0, -0.55, 3.25), vaca)
    for x, y, z, t in ((-0.4, -1.05, 3.55, 0.45), (0.45, -0.95, 3.0, 0.35), (0.55, -0.4, 3.7, 0.4)):
        p.bola("Mancha", (t, 0.12, t * 0.8), (x, y, z), PRETO())
    p.caixa("Focinho", (0.85, 0.45, 0.5), (0, -1.15, 2.95), mat("Saturnita_Focinho", (255, 172, 186)))
    p.bola("Narina_E", (0.12, 0.06, 0.1), (-0.2, -1.4, 3.0), PRETO())
    p.bola("Narina_D", (0.12, 0.06, 0.1), (0.2, -1.4, 3.0), PRETO())
    for s, lado in LADOS:
        p.cone(f"Chifre_{lado}", 0.1, 0.5, (s * 0.5, -0.45, 3.95), mat("Saturnita_Chifre", (240, 225, 180)), rot=(0, s * 35, 0), seg=8)
        p.bola(f"Orelha_{lado}", (0.55, 0.18, 0.25), (s * 0.8, -0.45, 3.5), vaca, rot=(0, s * 25, 0))
    p.olhos(3.45, -1.05, 0.55, d=0.42)


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

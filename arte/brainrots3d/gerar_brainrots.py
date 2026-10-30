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

def patapim(p):
    pele, corpo = mat("Patapim_Madeira", (150, 110, 70)), mat("Patapim_Musgo", (110, 150, 70))
    folha, folha2 = mat("Patapim_Folha", (80, 175, 60)), mat("Patapim_Folha_Escura", (55, 130, 45))
    pernas(p, pele, sep=0.75, alt=0.75, r=0.12, pe_tam=(0.65, 1.0, 0.28))
    p.caixa("Corpo", (1.0, 0.8, 0.85), (0, 0, 1.4), corpo)
    bracos(p, pele, 0.5, 1.65, comp=0.75, r=0.1, abre=65)
    p.caixa("Cabeca", (2.1, 1.7, 1.75), (0, 0, 2.65), pele)
    p.cil("Nariz", 0.24, 1.3, (0, -1.4, 2.45), mat("Patapim_Nariz", (175, 128, 82)), rot=(90, 0, 0), r2=0.3)
    p.bola("Ponta_Nariz", 0.62, (0, -2.05, 2.45), mat("Patapim_Nariz", (175, 128, 82)))
    for i, (x, y, r) in enumerate([(-0.6, -0.2, 10), (0.1, 0.1, -15), (0.7, -0.1, 25), (-0.2, 0.5, 40), (0.5, 0.5, -30)]):
        p.caixa("Folha", (0.8, 0.8, 0.45), (x, y, 3.65 + (i % 2) * 0.15), folha if i % 2 else folha2, rot=(0, 0, r))
    p.olhos(3.05, -0.86, 0.95)
    p.boca(1.95, -0.86, 0.9, alt=0.28, lingua=True)


def larila(p):
    pele, cacto = mat("Larila_Elefante", (170, 160, 150)), mat("Larila_Cacto", (120, 170, 90))
    sandalia, espinho = mat("Larila_Sandalia", (150, 95, 50)), mat("Larila_Espinho", (245, 240, 200))
    for s, lado in ((-1, "E"), (1, "D")):
        p.caixa(f"Sandalia_{lado}", (0.6, 0.9, 0.12), (s * 0.35, -0.08, 0.06), sandalia, bev=0.03)
        p.cil(f"Perna_{lado}", 0.22, 0.55, (s * 0.35, 0, 0.38), pele, seg=10)
        p.caixa(f"Tira_{lado}", (0.5, 0.12, 0.12), (s * 0.35, -0.3, 0.18), sandalia, bev=0.03)
    p.cil("Corpo_Cacto", 0.6, 1.2, (0, 0, 1.2), cacto, seg=8)
    for s, lado in ((-1, "E"), (1, "D")):
        p.caixa(f"Braco_{lado}", (0.5, 0.35, 0.3), (s * 0.75, 0, 1.25), cacto)
        p.caixa(f"Braco_Sobe_{lado}", (0.3, 0.35, 0.6), (s * 0.95, 0, 1.55), cacto)
    for i in range(8):
        a = math.radians(i * 45 + 22)
        p.cone("Espinho", 0.05, 0.25, (math.sin(a) * 0.62, math.cos(a) * 0.62, 1.0 + (i % 2) * 0.35), espinho,
               rot=(math.degrees(-math.cos(a) * 1.57), math.degrees(math.sin(a) * 1.57), 0))
    p.bola("Cabeca", (2.1, 1.75, 1.85), (0, 0, 2.65), pele)
    for s, lado in ((-1, "E"), (1, "D")):
        p.cil(f"Orelha_{lado}", 0.8, 0.12, (s * 1.15, 0.15, 2.75), pele, rot=(90, 0, s * 20), seg=10)
        p.cil(f"Orelha_Dentro_{lado}", 0.55, 0.06, (s * 1.12, 0.06, 2.75), mat("Larila_Rosa", (235, 160, 165)), rot=(90, 0, s * 20), seg=10)
    p.cil("Tromba", 0.24, 0.8, (0, -0.95, 2.15), pele, rot=(30, 0, 0), r2=0.2)
    p.cil("Tromba_Ponta", 0.2, 0.5, (0, -1.25, 1.75), pele, rot=(-25, 0, 0), r2=0.17)
    p.cil("Relogio", 0.38, 0.1, (1.05, -0.35, 1.95), BRANCO(), rot=(90, 0, 0), seg=14)
    p.anel("Relogio_Aro", 0.38, 0.06, (1.05, -0.35, 1.95), mat("Larila_Relogio", (220, 50, 50)), rot=(90, 0, 0))
    p.caixa("Ponteiro", (0.05, 0.04, 0.28), (1.05, -0.42, 2.05), PRETO(), bev=0.01)
    p.olhos(3.0, -0.75, 0.85, d=0.58)


def bananini(p):
    banana, macaco = mat("Bananini_Banana", (255, 220, 60)), mat("Bananini_Macaco", (110, 80, 50))
    rosto = mat("Bananini_Rosto", (232, 190, 140))
    pernas(p, macaco, sep=0.6, alt=0.5, r=0.14, pe=rosto, pe_tam=(0.5, 0.75, 0.25))
    p.cil("Banana", 0.55, 1.4, (0, 0, 1.35), banana, r2=0.7, seg=8)
    p.cil("Banana_Ponta", 0.15, 0.25, (0, 0, 0.55), mat("Bananini_Talo", (90, 70, 30)), seg=8)
    for i in range(4):
        a = i * 90 + 45
        x, y = math.sin(math.radians(a)) * 0.85, math.cos(math.radians(a)) * 0.85
        p.caixa("Casca", (0.6, 0.15, 1.1), (x, y, 2.05), banana, rot=(0, 0, -a), bev=0.05)
        p.partes[-1].data.transform(Matrix.Translation((x, y, 1.6)) @ Matrix.Rotation(math.radians(30), 4, Vector((math.cos(math.radians(a)), -math.sin(math.radians(a)), 0))) @ Matrix.Translation((-x, -y, -1.6)))
    p.bola("Cabeca", (1.9, 1.65, 1.75), (0, 0, 2.75), macaco)
    p.bola("Rosto", (1.35, 0.8, 1.15), (0, -0.55, 2.6), rosto)
    for s, lado in ((-1, "E"), (1, "D")):
        p.bola(f"Orelha_{lado}", (0.3, 0.55, 0.55), (s * 1.0, 0, 2.8), macaco)
        p.bola(f"Orelha_Dentro_{lado}", (0.2, 0.4, 0.4), (s * 1.06, -0.06, 2.8), rosto)
    bracos(p, macaco, 0.5, 1.85, comp=0.7, r=0.11, abre=50, mao=rosto)
    p.olhos(2.95, -0.88, 0.7, d=0.55)
    p.boca(2.3, -0.95, 0.75, alt=0.24, lingua=False)


def cappuccina(p):
    rosa, xicara = mat("Cappuccina_Tutu", (255, 170, 200)), mat("Cappuccina_Xicara", (245, 240, 232))
    cafe, espuma = mat("Cappuccina_Cafe", (120, 80, 50)), mat("Cappuccina_Espuma", (235, 205, 165))
    pele = mat("Cappuccina_Pele", (240, 200, 170))
    for s, lado in ((-1, "E"), (1, "D")):
        p.cone(f"Sapatilha_{lado}", 0.18, 0.35, (s * 0.25, 0, 0.18), rosa, rot=(180, 0, 0), seg=8)
        p.cil(f"Perna_{lado}", 0.1, 0.9, (s * 0.25, 0, 0.75), pele, seg=8)
    p.cil("Tutu", 1.05, 0.2, (0, 0, 1.2), rosa, r2=0.85, seg=16)
    p.cil("Tutu_2", 0.85, 0.16, (0, 0, 1.36), mat("Cappuccina_Tutu_Claro", (255, 205, 225)), r2=0.6, seg=16)
    p.cil("Corpo", 0.35, 0.55, (0, 0, 1.65), rosa, r2=0.3, seg=10)
    for s, lado in ((-1, "E"), (1, "D")):
        p.cil(f"Braco_{lado}", 0.08, 0.95, (s * 0.65, 0, 2.15), pele, rot=(0, -s * 50, 0), seg=8)
    p.cil("Pires", 1.0, 0.1, (0, 0, 1.97), xicara, seg=16)
    p.cil("Xicara", 0.75, 1.35, (0, 0, 2.7), xicara, r2=0.98, seg=16)
    p.cil("Cafe", 0.9, 0.08, (0, 0, 3.33), cafe, seg=16)
    p.bola("Espuma", (1.25, 1.25, 0.4), (0, 0, 3.4), espuma, seg=(16, 8))
    p.bola("Coracao", (0.35, 0.35, 0.12), (0, -0.1, 3.58), cafe)
    p.anel("Alca", 0.32, 0.09, (1.05, 0, 2.75), xicara, rot=(90, 0, 0))
    p.olhos(2.85, -0.84, 0.75, d=0.55)
    p.bola("Bochecha_E", (0.3, 0.1, 0.18), (-0.6, -0.88, 2.45), rosa)
    p.bola("Bochecha_D", (0.3, 0.1, 0.18), (0.6, -0.88, 2.45), rosa)
    p.boca(2.42, -0.86, 0.35, alt=0.22, dentes=False, lingua=True)


def tralalero(p):
    azul, barriga = mat("Tralalero_Pele", (80, 160, 230)), mat("Tralalero_Barriga", (240, 245, 250))
    tenis, sola = mat("Tralalero_Tenis", (40, 90, 255)), BRANCO()
    for i, x in enumerate((-0.5, 0.0, 0.5)):
        y = 0.25 if i == 1 else 0.0
        p.caixa("Sola", (0.42, 0.75, 0.1), (x, y - 0.1, 0.05), sola, bev=0.03)
        p.caixa("Tenis", (0.4, 0.7, 0.3), (x, y - 0.1, 0.23), tenis)
        p.cil("Perna", 0.1, 0.55, (x, y, 0.62), azul, seg=8)
    p.bola("Corpo", (1.85, 1.55, 2.6), (0, 0, 2.15), azul)
    p.bola("Barriga", (1.3, 0.7, 1.9), (0, -0.48, 1.95), barriga)
    p.cone("Barbatana", 0.6, 1.0, (0, 0.15, 3.65), azul, rot=(0, 0, 0), seg=3, esc=(0.35, 1.3, 1))
    for s, lado in ((-1, "E"), (1, "D")):
        p.cone(f"Nadadeira_{lado}", 0.35, 0.8, (s * 1.05, 0, 1.9), azul, rot=(0, s * 120, 0), seg=3, esc=(1, 0.35, 1))
    p.cone("Rabo", 0.45, 0.9, (0, 0.95, 1.0), azul, rot=(-60, 0, 0), seg=3, esc=(1, 0.3, 1))
    p.olhos(2.95, -0.62, 1.0, d=0.6)
    p.boca(2.1, -0.75, 1.0, alt=0.42, presas=True)


def bombardiro(p):
    aviao, croc = mat("Bombardiro_Aviao", (90, 110, 80)), mat("Bombardiro_Croco", (60, 140, 60))
    barriga = mat("Bombardiro_Barriga", (200, 210, 140))
    for x in (-0.6, 0.6):
        p.cil("Roda", 0.28, 0.2, (x, -0.2, 0.28), BORRACHA(), rot=(0, 90, 0), seg=12)
        p.caixa("Trem", (0.1, 0.1, 0.4), (x, -0.2, 0.6), PRATA())
    p.caixa("Fuselagem", (1.3, 2.4, 1.1), (0, 0.3, 1.25), aviao)
    p.caixa("Asas", (5.0, 1.0, 0.16), (0, 0.2, 1.3), aviao, bev=0.06)
    p.caixa("Cauda", (0.15, 0.7, 0.9), (0, 1.35, 2.0), aviao)
    p.caixa("Estabilizador", (1.6, 0.5, 0.12), (0, 1.35, 1.6), aviao)
    for s in (-1, 1):
        p.cil("Motor", 0.22, 0.6, (s * 1.6, -0.2, 1.2), PRATA(), rot=(90, 0, 0), seg=10)
        p.caixa("Helice", (0.9, 0.05, 0.12), (s * 1.6, -0.55, 1.2), PRETO(), rot=(0, 30, 0), bev=0.02)
        p.cil("Bomba", 0.17, 0.6, (s * 1.0, 0.1, 0.95), PRETO(), rot=(90, 0, 0), seg=10)
    p.caixa("Cabeca", (1.9, 1.6, 1.5), (0, -0.55, 2.35), croc)
    p.caixa("Focinho", (1.45, 1.3, 0.45), (0, -1.75, 2.0), croc)
    p.caixa("Queixo", (1.35, 1.2, 0.3), (0, -1.65, 1.62), barriga)
    for i in range(5):
        x = -0.55 + i * 0.275
        p.cone("Dente", 0.08, 0.22, (x, -2.3, 1.75), DENTE(), rot=(180, 0, 45))
    p.bola("Narina_E", 0.12, (-0.25, -2.4, 2.22), PRETO())
    p.bola("Narina_D", 0.12, (0.25, -2.4, 2.22), PRETO())
    for s in (-1, 1):
        p.bola("Calombo", (0.75, 0.7, 0.6), (s * 0.45, -0.3, 3.05), croc)
    p.olhos(2.75, -1.36, 0.9, d=0.58)
    p.caixa("Oculos_Aviador", (1.7, 0.12, 0.14), (0, -1.38, 3.2), mat("Bombardiro_Couro", (110, 70, 40)), bev=0.03)


def ambalabu(p):
    sapo, pele = mat("Ambalabu_Sapo", (95, 175, 70)), mat("Ambalabu_Pele", (232, 185, 145))
    pneu = BORRACHA()
    pernas(p, pele, sep=0.6, alt=0.85, r=0.13, pe=mat("Ambalabu_Sapato", (60, 40, 30)), pe_tam=(0.45, 0.75, 0.25))
    p.anel("Pneu", 0.68, 0.32, (0, 0, 1.55), pneu, rot=(90, 0, 0), n=16)
    p.cil("Calota", 0.42, 0.3, (0, 0, 1.55), PRATA(), rot=(90, 0, 0), seg=12)
    for s, lado in ((-1, "E"), (1, "D")):
        p.cil(f"Braco_{lado}", 0.09, 0.6, (s * 1.0, 0, 1.45), sapo, rot=(0, s * 40, 0), seg=8)
        p.bola(f"Mao_{lado}", (0.35, 0.25, 0.2), (s * 1.2, 0, 1.2), sapo)
    p.bola("Cabeca", (2.4, 1.7, 1.3), (0, 0, 2.75), sapo)
    p.bola("Barriga_Cabeca", (1.9, 1.2, 0.7), (0, -0.25, 2.45), mat("Ambalabu_Papo", (200, 225, 140)))
    for s in (-1, 1):
        p.bola("Palpebra", (0.85, 0.8, 0.75), (s * 0.55, -0.25, 3.3), sapo)
    p.olhos(3.35, -0.62, 1.1, d=0.62)
    p.caixa("Boca", (1.8, 0.2, 0.14), (0, -0.82, 2.6), mat("Ambalabu_Boca", (200, 60, 80)), bev=0.05)


def trippi(p):
    camarao, faixa = mat("Trippi_Camarao", (255, 140, 110)), mat("Trippi_Faixa", (255, 205, 185))
    gato, focinho = mat("Trippi_Gato", (190, 180, 170)), mat("Trippi_Focinho", (240, 235, 230))
    for i in range(4):
        x = -0.45 + i * 0.3
        p.cil("Patinha", 0.06, 0.5, (x, -0.1, 0.3), camarao, rot=(15, 0, 0), seg=6)
    for i, (w, z, y) in enumerate([(1.3, 0.75, 0.0), (1.15, 1.2, 0.12), (1.0, 1.6, 0.28)]):
        p.caixa("Segmento", (w, 0.95, 0.42), (0, y, z), camarao, rot=(-10 * i, 0, 0))
        p.caixa("Listra", (w + 0.02, 0.97, 0.08), (0, y, z + 0.2), faixa, rot=(-10 * i, 0, 0), bev=0.02)
    p.cone("Leque", 0.6, 0.6, (0, 0.85, 0.5), camarao, rot=(-110, 0, 0), seg=4, esc=(1.4, 0.2, 1))
    p.bola("Cabeca", (2.0, 1.6, 1.65), (0, 0, 2.6), gato)
    p.bola("Focinho", (0.9, 0.5, 0.55), (0, -0.72, 2.3), focinho)
    p.bola("Nariz", (0.25, 0.15, 0.18), (0, -0.98, 2.45), mat("Trippi_Nariz", (240, 120, 150)))
    for s, lado in ((-1, "E"), (1, "D")):
        p.cone(f"Orelha_{lado}", 0.42, 0.6, (s * 0.62, 0, 3.45), gato, rot=(0, s * 12, 45))
        for k in (-1, 1):
            p.caixa(f"Bigode_{lado}", (0.7, 0.03, 0.03), (s * 0.75, -0.85, 2.35 + k * 0.08), PRETO(), rot=(0, s * k * 12, 0), bev=0.0)
        p.cil(f"Antena_{lado}", 0.04, 1.3, (s * 0.35, -0.1, 3.85), camarao, rot=(-20, s * 25, 0), seg=6)
    p.olhos(2.85, -0.7, 0.85, d=0.6)
    p.boca(2.05, -0.75, 0.45, alt=0.18, dentes=False)


def frigo(p):
    geladeira, camelo = mat("Frigo_Geladeira", (235, 240, 245)), mat("Frigo_Camelo", (200, 160, 100))
    bota = mat("Frigo_Bota", (110, 70, 40))
    pernas(p, camelo, sep=0.85, alt=0.6, r=0.14, pe=bota, pe_tam=(0.5, 0.7, 0.35))
    p.caixa("Geladeira", (1.45, 1.05, 1.7), (0, 0, 1.75), geladeira)
    p.caixa("Divisao", (1.47, 1.07, 0.05), (0, 0, 2.15), mat("Frigo_Junta", (160, 170, 180)), bev=0.0)
    p.caixa("Puxador", (0.08, 0.1, 0.6), (0.55, -0.56, 1.6), PRATA(), bev=0.02)
    p.caixa("Puxador_2", (0.08, 0.1, 0.3), (0.55, -0.56, 2.35), PRATA(), bev=0.02)
    p.bola("Corcova", (0.9, 0.8, 0.7), (-0.3, 0.3, 2.65), camelo)
    p.bola("Corcova_2", (0.75, 0.7, 0.55), (0.35, 0.35, 2.6), camelo)
    p.cil("Pescoco", 0.25, 0.6, (0, -0.35, 2.8), camelo, seg=10)
    p.caixa("Cabeca", (1.6, 1.4, 1.35), (0, -0.4, 3.55), camelo)
    p.caixa("Focinho", (1.1, 0.6, 0.65), (0, -1.3, 3.2), mat("Frigo_Focinho", (225, 190, 135)))
    p.bola("Narina_E", 0.12, (-0.25, -1.6, 3.35), PRETO())
    p.bola("Narina_D", 0.12, (0.25, -1.6, 3.35), PRETO())
    for s, lado in ((-1, "E"), (1, "D")):
        p.bola(f"Orelha_{lado}", (0.4, 0.2, 0.25), (s * 0.85, -0.2, 4.1), camelo, rot=(0, s * 30, 0))
    p.olhos(3.85, -1.1, 0.75, d=0.55)
    p.caixa("Boca", (0.7, 0.15, 0.08), (0, -1.6, 3.0), BOCA(), bev=0.03)


def glorbo(p):
    casca, polpa = mat("Glorbo_Casca", (60, 150, 60)), mat("Glorbo_Polpa", (235, 75, 85))
    listra, croc = mat("Glorbo_Listra", (30, 95, 35)), mat("Glorbo_Croco", (85, 160, 70))
    for s, lado in ((-1, "E"), (1, "D")):
        p.caixa(f"Pe_{lado}", (0.6, 0.8, 0.25), (s * 0.6, -0.15, 0.13), croc)
        for k in (-1, 0, 1):
            p.cone(f"Garra_{lado}", 0.06, 0.18, (s * 0.6 + k * 0.17, -0.6, 0.1), DENTE(), rot=(90, 0, 0))
        p.cil(f"Perna_{lado}", 0.2, 0.4, (s * 0.6, 0, 0.42), croc, seg=10)
    p.bola("Melancia", (2.4, 2.1, 2.1), (0, 0.1, 1.65), casca, seg=(16, 10))
    for a in (0, 36, 72, 108, 144):
        p.bola("Listra", (0.16, 2.14, 2.14), (0, 0.1, 1.65), listra, rot=(0, 0, a), seg=(16, 10))
    p.bola("Polpa", (2.05, 0.5, 1.8), (0, -0.82, 1.65), polpa, seg=(16, 10))
    p.bola("Borda_Branca", (2.25, 0.45, 1.98), (0, -0.74, 1.65), mat("Glorbo_Borda", (240, 245, 220)), seg=(16, 10))
    for x, z in ((-0.7, 1.15), (0.7, 1.15), (-0.35, 0.95), (0.35, 0.95), (-0.85, 1.6), (0.85, 1.6)):
        p.bola("Semente", (0.12, 0.08, 0.2), (x, -1.05, z), PRETO())
    p.cone("Rabo", 0.4, 1.4, (0, 1.4, 0.7), croc, rot=(-75, 0, 0), seg=6)
    p.olhos(2.1, -1.0, 0.9, d=0.62)
    p.boca(1.4, -1.05, 0.9, alt=0.28, presas=True)


def cocofanto(p):
    coco, elefante = mat("Cocofanto_Coco", (115, 78, 48)), mat("Cocofanto_Elefante", (150, 150, 162))
    fibra, marfim = mat("Cocofanto_Fibra", (85, 55, 35)), mat("Cocofanto_Marfim", (250, 245, 225))
    for s, lado in ((-1, "E"), (1, "D")):
        p.cil(f"Pata_{lado}", 0.3, 0.55, (s * 0.55, 0, 0.28), elefante, seg=10)
        for k in (-1, 0, 1):
            p.bola(f"Unha_{lado}", (0.14, 0.08, 0.12), (s * 0.55 + k * 0.15, -0.3, 0.1), marfim)
    p.bola("Coco", (2.0, 1.9, 1.8), (0, 0.05, 1.35), coco, seg=(12, 8))
    for i in range(10):
        a = math.radians(i * 36)
        p.caixa("Fibra", (0.25, 0.05, 0.05), (math.sin(a) * 0.9, math.cos(a) * 0.85, 1.35 + (i % 3 - 1) * 0.35), fibra,
                rot=(0, 30 * (i % 2 * 2 - 1), -math.degrees(a)), bev=0.0)
    p.bola("Cabeca", (2.0, 1.7, 1.7), (0, -0.2, 2.75), elefante)
    for s, lado in ((-1, "E"), (1, "D")):
        p.cil(f"Orelha_{lado}", 0.85, 0.12, (s * 1.2, 0.05, 2.85), elefante, rot=(90, 0, s * 25), seg=10)
        p.cil(f"Orelha_Dentro_{lado}", 0.6, 0.06, (s * 1.16, -0.03, 2.85), mat("Cocofanto_Rosa", (230, 165, 170)), rot=(90, 0, s * 25), seg=10)
        p.cone(f"Presa_{lado}", 0.1, 0.6, (s * 0.4, -1.05, 2.05), marfim, rot=(70, 0, s * 15), seg=8)
    p.cil("Tromba", 0.26, 0.9, (0, -1.1, 2.3), elefante, rot=(25, 0, 0), r2=0.2)
    p.cil("Tromba_Ponta", 0.2, 0.5, (0, -1.45, 1.85), elefante, rot=(-30, 0, 0), r2=0.18)
    p.olhos(3.1, -0.95, 0.85, d=0.56)


def gusini(p):
    jato, ganso = mat("Gusini_Jato", (110, 120, 100)), mat("Gusini_Ganso", (242, 242, 242))
    bico, fogo = mat("Gusini_Bico", (255, 150, 30)), mat("Gusini_Fogo", (255, 120, 20), emit=4.0)
    for x in (-0.5, 0.5):
        p.cil("Roda", 0.22, 0.18, (x, 0.1, 0.22), BORRACHA(), rot=(0, 90, 0), seg=10)
        p.caixa("Trem", (0.08, 0.08, 0.35), (x, 0.1, 0.5), PRATA())
    p.caixa("Fuselagem", (1.2, 2.3, 0.95), (0, 0.4, 1.05), jato)
    for s, lado in ((-1, "E"), (1, "D")):
        p.caixa(f"Asa_{lado}", (2.0, 1.1, 0.12), (s * 1.4, 0.55, 1.05), jato, rot=(0, s * -8, s * 22), bev=0.04)
        p.cil(f"Missil_{lado}", 0.12, 0.9, (s * 1.5, 0.3, 0.85), BRANCO(), rot=(90, 0, 0), seg=8)
        p.cone(f"Missil_Ponta_{lado}", 0.12, 0.25, (s * 1.5, -0.27, 0.85), mat("Gusini_Vermelho", (220, 40, 40)), rot=(90, 0, 0), seg=8)
        p.cil(f"Turbina_{lado}", 0.25, 0.5, (s * 0.38, 1.6, 1.05), PRATA(), rot=(90, 0, 0), seg=10)
        p.cone(f"Fogo_{lado}", 0.2, 0.5, (s * 0.38, 2.05, 1.05), fogo, rot=(-90, 0, 0), seg=8)
    p.caixa("Leme", (0.12, 0.6, 0.8), (0, 1.35, 1.8), jato)
    p.cil("Pescoco", 0.28, 1.0, (0, -0.25, 1.85), ganso, rot=(-15, 0, 0), seg=10)
    p.bola("Cabeca", (1.75, 1.55, 1.55), (0, -0.45, 2.85), ganso)
    p.caixa("Bico", (0.8, 0.85, 0.28), (0, -1.45, 2.65), bico, bev=0.1)
    p.caixa("Bico_Baixo", (0.65, 0.7, 0.16), (0, -1.38, 2.42), mat("Gusini_Bico_Escuro", (225, 115, 20)), bev=0.06)
    p.caixa("Capacete", (1.2, 1.1, 0.25), (0, -0.25, 3.6), jato, bev=0.1)
    p.olhos(3.12, -1.12, 0.78, d=0.55)


def svinino(p):
    porco, bomba = mat("Svinino_Porco", (255, 170, 190)), mat("Svinino_Bomba", (55, 55, 65))
    focinho, faisca = mat("Svinino_Focinho", (255, 140, 165)), mat("Svinino_Faisca", (255, 220, 60), emit=6.0)
    for x, y in ((-0.45, -0.25), (0.45, -0.25), (-0.45, 0.35), (0.45, 0.35)):
        p.cil("Pata", 0.16, 0.45, (x, y, 0.3), porco, seg=8)
        p.cil("Casco", 0.17, 0.12, (x, y, 0.06), PRETO(), seg=8)
    p.bola("Corpo", (1.5, 1.4, 1.05), (0, 0.05, 0.95), porco)
    for s in (-1, 1):
        p.caixa("Aleta", (0.08, 0.6, 0.6), (s * 0.3, 0.8, 1.05), PRATA(), rot=(0, 0, s * 25))
    p.bola("Cabeca_Bomba", 2.0, (0, 0, 2.35), bomba, seg=(16, 10))
    p.anel("Faixa", 0.98, 0.07, (0, 0, 2.35), mat("Svinino_Faixa", (200, 40, 40)), rot=(0, 0, 0))
    p.cil("Bocal", 0.28, 0.25, (0, 0, 3.4), PRATA(), seg=10)
    p.cil("Pavio", 0.06, 0.45, (0.1, 0, 3.7), mat("Svinino_Pavio", (200, 180, 150)), rot=(0, 25, 0), seg=6)
    p.bola("Faisca", 0.32, (0.2, 0, 3.95), faisca, seg=(8, 6))
    p.cil("Focinho", 0.38, 0.35, (0, -0.95, 2.05), focinho, rot=(90, 0, 0), seg=12)
    p.bola("Narina_E", (0.1, 0.06, 0.14), (-0.13, -1.13, 2.05), PRETO())
    p.bola("Narina_D", (0.1, 0.06, 0.14), (0.13, -1.13, 2.05), PRETO())
    for s, lado in ((-1, "E"), (1, "D")):
        p.cone(f"Orelha_{lado}", 0.3, 0.45, (s * 0.7, 0, 3.25), porco, rot=(15, s * 30, 0))
    p.olhos(2.65, -0.8, 0.85, d=0.55)
    p.boca(1.65, -0.85, 0.5, alt=0.16, dentes=False)


def udin(p):
    laranja, pele = mat("Udin_Roupa", (255, 150, 40)), mat("Udin_Pele", (240, 200, 160))
    tambor, couro = mat("Udin_Tambor", (210, 40, 50), rough=0.25), mat("Udin_Couro", (250, 240, 215))
    pernas(p, mat("Udin_Calca", (60, 70, 130)), sep=0.6, alt=0.55, r=0.15, pe=PRETO(), pe_tam=(0.45, 0.7, 0.25))
    p.caixa("Corpo", (1.2, 0.85, 1.0), (0, 0, 1.25), laranja)
    p.cil("Tambor", 0.55, 0.55, (0, -0.75, 1.15), tambor, seg=14)
    p.cil("Pele_Tambor", 0.52, 0.05, (0, -0.75, 1.45), couro, seg=14)
    p.anel("Aro", 0.55, 0.05, (0, -0.75, 1.42), OURO(), n=16)
    for s, lado in ((-1, "E"), (1, "D")):
        p.cil(f"Braco_{lado}", 0.13, 0.6, (s * 0.65, -0.3, 1.45), laranja, rot=(60, -s * 20, 0), seg=8)
        p.bola(f"Mao_{lado}", 0.3, (s * 0.55, -0.6, 1.62), pele)
        p.cil(f"Baqueta_{lado}", 0.04, 0.8, (s * 0.45, -0.75, 1.85), mat("Udin_Baqueta", (225, 190, 130)), rot=(-40, s * 25, 0), seg=6)
    p.bola("Cabeca", (2.1, 1.85, 2.0), (0, 0, 2.75), pele)
    p.bola("Gorro", (2.15, 1.9, 1.3), (0, 0.05, 3.35), laranja)
    p.cil("Gorro_Barra", 1.05, 0.25, (0, 0.03, 3.25), mat("Udin_Gorro_Barra", (230, 120, 25)), seg=16)
    p.bola("Pompom", 0.5, (0, 0.05, 4.05), couro)
    p.caixa("Bigode", (1.0, 0.25, 0.18), (0, -0.95, 2.45), mat("Udin_Bigode", (90, 55, 30)))
    p.bola("Nariz", (0.35, 0.3, 0.3), (0, -0.98, 2.68), mat("Udin_Nariz", (235, 170, 140)))
    p.olhos(3.0, -0.8, 0.8, d=0.56)
    p.bola("Boca", (0.55, 0.25, 0.42), (0, -0.88, 2.1), BOCA())
    p.bola("Lingua", (0.32, 0.15, 0.18), (0, -0.98, 2.0), LINGUA())
    p.cone("Estrela_Secreta", 0.25, 0.08, (0.75, -0.55, 3.75), mat("Udin_Brilho", (255, 235, 120), emit=5.0), rot=(90, 0, 0), seg=5)


# ---------------------------------------------------------------- os 5 chefes

def sahur(p):
    madeira, casca = mat("Sahur_Madeira", (150, 100, 60)), mat("Sahur_Casca", (105, 68, 40))
    anel = mat("Sahur_Anel", (215, 170, 115))
    pernas(p, madeira, sep=0.7, alt=0.6, r=0.11, pe=casca, pe_tam=(0.45, 0.65, 0.22))
    p.caixa("Tronco", (1.6, 1.3, 2.7), (0, 0, 2.15), madeira)
    for x in (-0.55, -0.15, 0.3, 0.65):
        p.caixa("Casca", (0.12, 1.34, 2.5), (x, 0, 2.1), casca, bev=0.03)
    p.caixa("Topo", (1.45, 1.15, 0.08), (0, 0, 3.5), anel, bev=0.02)
    p.anel("Anel_Madeira", 0.3, 0.04, (0, 0, 3.55), casca, n=12)
    # Coroa de ouro
    p.caixa("Coroa", (1.7, 1.4, 0.3), (0, 0, 3.65), OURO(), bev=0.05)
    for x in (-0.6, -0.2, 0.2, 0.6):
        p.cone("Coroa_Ponta", 0.18, 0.5, (x, -0.55, 4.05), OURO(), seg=4)
        p.cone("Coroa_Ponta", 0.18, 0.5, (x, 0.55, 4.05), OURO(), seg=4)
    for x in (-0.4, 0.4):
        p.bola("Joia", (0.22, 0.1, 0.22), (x, -0.73, 3.65), mat("Joia_Vermelha", (230, 20, 40), emit=1.5))
    bracos(p, madeira, 0.8, 2.3, comp=0.8, r=0.1, abre=60, mao=casca)
    # Taco com pregos na mão direita
    p.cil("Taco", 0.1, 2.4, (1.55, -0.3, 2.35), mat("Sahur_Taco", (190, 140, 85)), rot=(0, -25, 0), r2=0.24, seg=10)
    for k in range(4):
        z = 2.6 + k * 0.28
        x = 1.55 - math.sin(math.radians(25)) * (z - 2.35)
        p.cone("Prego", 0.05, 0.3, (x + 0.22, -0.3, z), PRATA(), rot=(0, 90, 0), seg=6)
    p.olhos(2.85, -0.66, 0.8, d=0.68)
    p.boca(1.85, -0.66, 1.0, alt=0.42, presas=True)


def assassino(p):
    xicara, cafe = mat("Assassino_Xicara", (70, 40, 30)), mat("Assassino_Cafe", (40, 22, 15))
    ninja, armadura = mat("Assassino_Ninja", (30, 30, 38)), mat("Assassino_Armadura", (120, 125, 140), metal=0.7)
    lamina, faixa = mat("Assassino_Lamina", (225, 230, 240), rough=0.1, metal=0.9), mat("Assassino_Faixa", (200, 25, 30))
    pernas(p, ninja, sep=0.6, alt=0.6, r=0.14, pe=ninja, pe_tam=(0.45, 0.7, 0.22))
    p.caixa("Corpo", (1.1, 0.8, 1.0), (0, 0, 1.3), ninja)
    p.caixa("Peitoral", (1.2, 0.3, 0.75), (0, -0.4, 1.4), armadura)
    for s, lado in ((-1, "E"), (1, "D")):
        p.bola(f"Ombreira_{lado}", (0.6, 0.65, 0.4), (s * 0.7, 0, 1.78), armadura)
        p.cone(f"Ombreira_Espinho_{lado}", 0.1, 0.3, (s * 0.8, 0, 2.05), PRATA(), seg=6)
    bracos(p, ninja, 0.6, 1.65, comp=0.75, r=0.12, abre=55)
    # Espadas: uma em cada mão.
    for s, lado in ((-1, "E"), (1, "D")):
        p.caixa(f"Espada_{lado}", (0.1, 0.05, 1.7), (s * 1.35, -0.15, 1.8), lamina, rot=(0, s * -20, 0), bev=0.02)
        p.caixa(f"Guarda_{lado}", (0.35, 0.15, 0.08), (s * 1.18, -0.15, 1.05), OURO(), rot=(0, s * -20, 0), bev=0.02)
    p.cil("Pires", 1.05, 0.1, (0, 0, 2.0), xicara, seg=16)
    p.cil("Xicara", 0.8, 1.4, (0, 0, 2.75), xicara, r2=1.02, seg=16)
    p.cil("Cafe", 0.95, 0.08, (0, 0, 3.4), cafe, seg=16)
    p.anel("Alca", 0.33, 0.1, (1.1, 0, 2.8), xicara, rot=(90, 0, 0))
    p.cil("Mascara", 0.94, 0.42, (0, 0, 3.0), ninja, seg=16)
    p.caixa("Faixa_Ponta", (0.15, 0.7, 0.12), (0.25, 1.15, 3.0), faixa, rot=(20, 0, 10))
    p.caixa("Faixa_Ponta", (0.15, 0.7, 0.12), (-0.15, 1.1, 2.9), faixa, rot=(35, 0, -10))
    p.anel("Faixa", 0.98, 0.05, (0, 0, 3.24), faixa, n=16)
    p.olhos(3.0, -0.92, 0.75, d=0.55)
    p.boca(2.4, -0.88, 0.7, alt=0.3, presas=True)


def cacto(p):
    cacto, hipo = mat("Cacto_Cacto", (90, 160, 80)), mat("Cacto_Hipopotamo", (165, 135, 160))
    espinho, armadura = mat("Cacto_Espinho", (245, 240, 200)), mat("Cacto_Armadura", (95, 70, 50), rough=0.6)
    pernas(p, hipo, sep=0.85, alt=0.45, r=0.25, pe=hipo, pe_tam=(0.6, 0.75, 0.25))
    p.cil("Corpo", 0.65, 1.6, (0, 0, 1.45), cacto, seg=8)
    for s, lado in ((-1, "E"), (1, "D")):
        p.caixa(f"Braco_{lado}", (0.7, 0.4, 0.35), (s * 0.95, 0, 1.6), cacto)
        p.caixa(f"Braco_Sobe_{lado}", (0.4, 0.4, 1.4), (s * 1.2, 0, 2.3), cacto)
        p.bola(f"Flor_{lado}", (0.35, 0.35, 0.2), (s * 1.2, 0, 3.05), mat("Cacto_Flor", (255, 90, 160)))
        p.caixa(f"Ombreira_{lado}", (0.6, 0.6, 0.25), (s * 0.7, 0, 2.2), armadura, rot=(0, s * 20, 0))
        for k in (-1, 1):
            p.cone(f"Ombreira_Cravo_{lado}", 0.08, 0.3, (s * 0.75, k * 0.18, 2.4), PRATA(), seg=6)
    for i in range(10):
        a = math.radians(i * 36 + 18)
        p.cone("Espinho", 0.05, 0.3, (math.sin(a) * 0.66, math.cos(a) * 0.66, 0.9 + (i % 3) * 0.4), espinho,
               rot=(math.degrees(-math.cos(a) * 1.57), math.degrees(math.sin(a) * 1.57), 0))
    p.caixa("Cinto", (1.45, 1.4, 0.2), (0, 0, 1.2), armadura, rot=(0, 15, 0), bev=0.05)
    p.caixa("Cabeca", (2.1, 1.7, 1.4), (0, -0.1, 3.0), hipo)
    p.caixa("Focinho", (1.9, 0.9, 0.9), (0, -1.05, 2.7), mat("Cacto_Focinho", (190, 160, 180)))
    p.bola("Narina_E", (0.2, 0.1, 0.12), (-0.45, -1.52, 3.0), PRETO())
    p.bola("Narina_D", (0.2, 0.1, 0.12), (0.45, -1.52, 3.0), PRETO())
    for s, lado in ((-1, "E"), (1, "D")):
        p.cone(f"Presa_{lado}", 0.13, 0.5, (s * 0.65, -1.45, 2.65), DENTE(), seg=6)
        p.cone(f"Chifre_{lado}", 0.2, 0.9, (s * 0.75, 0, 4.05), mat("Cacto_Chifre", (240, 230, 200)), rot=(0, s * 30, 0), seg=8)
        p.bola(f"Orelha_{lado}", (0.35, 0.2, 0.3), (s * 0.95, 0.2, 3.75), hipo)
    p.olhos(3.75, -0.85, 0.85, d=0.62)
    p.boca(2.35, -1.5, 1.4, alt=0.25, dentes=False)


def toasterino(p):
    inox, rino = mat("Toasterino_Inox", (190, 195, 205), rough=0.2, metal=0.85), mat("Toasterino_Rino", (150, 150, 160))
    torrada, crosta = mat("Toasterino_Torrada", (235, 190, 110)), mat("Toasterino_Crosta", (150, 90, 40))
    neon, chifre = mat("Toasterino_Neon", (255, 110, 20), emit=5.0), mat("Toasterino_Chifre", (240, 232, 210))
    ciano = mat("Toasterino_Tech", (40, 230, 255), emit=4.0)
    for x, y in ((-0.6, -0.3), (0.6, -0.3), (-0.6, 0.4), (0.6, 0.4)):
        p.cil("Pata", 0.25, 0.55, (x, y, 0.28), rino, seg=10)
    p.caixa("Torradeira", (2.0, 1.4, 1.5), (0, 0.05, 1.3), inox)
    for s in (-1, 1):
        p.caixa("Faixa_Tech", (0.05, 1.42, 0.1), (s * 1.0, 0.05, 1.0), ciano, bev=0.0)
        p.caixa("Fenda", (0.3, 1.0, 0.06), (s * 0.4, 0.15, 2.05), neon, bev=0.0)
        p.caixa("Torrada", (0.22, 0.9, 0.9), (s * 0.4, 0.15, 2.4), torrada, bev=0.05)
        p.caixa("Torrada_Crosta", (0.24, 0.92, 0.12), (s * 0.4, 0.15, 2.82), crosta, bev=0.03)
    p.caixa("Alavanca", (0.15, 0.3, 0.1), (1.08, 0.3, 1.6), PRETO())
    p.cil("Antena", 0.04, 0.6, (-0.8, 0.5, 2.3), PRETO(), seg=6)
    p.bola("Antena_Luz", 0.18, (-0.8, 0.5, 2.65), ciano)
    p.caixa("Cabeca", (1.8, 1.5, 1.45), (0, -0.85, 2.45), rino)
    p.caixa("Focinho", (1.3, 0.8, 0.85), (0, -1.75, 2.2), rino)
    p.cone("Chifre", 0.3, 1.0, (0, -2.0, 3.0), chifre, rot=(-20, 0, 0), seg=8)
    p.cone("Chifre_2", 0.17, 0.45, (0, -1.6, 3.0), chifre, rot=(-10, 0, 0), seg=8)
    for s, lado in ((-1, "E"), (1, "D")):
        p.cone(f"Orelha_{lado}", 0.2, 0.4, (s * 0.7, -0.5, 3.3), rino, rot=(0, s * 25, 0))
        p.caixa(f"Placa_{lado}", (0.25, 1.2, 1.0), (s * 1.0, -0.85, 2.45), inox, bev=0.06)
    p.caixa("Visor", (1.6, 0.12, 0.12), (0, -1.62, 3.32), ciano, bev=0.03)
    p.olhos(2.9, -1.6, 0.85, d=0.58)
    p.boca(1.95, -2.18, 1.0, alt=0.25, presas=True)


def saturnita(p):
    planeta, mancha = mat("Saturnita_Planeta", (245, 245, 240)), PRETO()
    aneis, jeans = mat("Saturnita_Anel", (235, 185, 110)), mat("Saturnita_Jeans", (60, 90, 170))
    asa, estrela = mat("Saturnita_Asa", (130, 70, 230), emit=1.5), mat("Saturnita_Estrela", (255, 230, 90), emit=5.0)
    pernas(p, jeans, sep=0.7, alt=0.8, r=0.15, pe=mat("Saturnita_Tenis", (230, 40, 60)), pe_tam=(0.45, 0.75, 0.3))
    p.bola("Planeta", 2.4, (0, 0, 2.35), planeta, seg=(18, 12))
    for x, y, z, t in ((-0.7, -0.75, 2.9, 0.7), (0.8, -0.6, 1.8, 0.6), (-0.95, -0.35, 1.6, 0.5), (0.9, 0.3, 3.0, 0.7), (0.0, 0.9, 2.5, 0.8)):
        v = Vector((x, y, z - 2.35)).normalized()
        p.bola("Mancha", (t, 0.15, t * 0.8), (v.x * 1.17, v.y * 1.17, 2.35 + v.z * 1.17), mancha,
               rot=(0, 0, math.degrees(math.atan2(v.x, -v.y))))
    p.anel("Anel", 1.85, 0.13, (0, 0, 2.15), aneis, rot=(14, -8, 0), n=28)
    p.anel("Anel_2", 2.2, 0.07, (0, 0, 2.15), mat("Saturnita_Anel_2", (200, 130, 70)), rot=(14, -8, 0), n=28)
    p.caixa("Focinho", (1.2, 0.5, 0.75), (0, -1.15, 1.9), mat("Saturnita_Focinho", (255, 170, 185)))
    p.bola("Narina_E", (0.15, 0.08, 0.12), (-0.25, -1.42, 1.95), PRETO())
    p.bola("Narina_D", (0.15, 0.08, 0.12), (0.25, -1.42, 1.95), PRETO())
    for s, lado in ((-1, "E"), (1, "D")):
        p.cone(f"Chifre_{lado}", 0.15, 0.75, (s * 0.85, 0, 3.75), mat("Saturnita_Chifre", (240, 225, 180)), rot=(0, s * 35, 0), seg=8)
        p.bola(f"Orelha_{lado}", (0.55, 0.2, 0.3), (s * 1.25, 0, 3.15), planeta, rot=(0, s * 25, 0))
        for k in range(3):
            p.caixa(f"Asa_{lado}", (1.5 - k * 0.3, 0.08, 0.35), (s * (1.5 + k * 0.1), 0.6, 3.0 - k * 0.4), asa,
                    rot=(0, s * (-35 + k * 22), 0), bev=0.04)
        bracos(p, planeta, 1.1, 2.1, comp=0.6, r=0.12, abre=70) if s == 1 else None
    for i in range(5):
        a = math.radians(-50 + i * 25)
        p.cone("Estrela", 0.15, 0.4, (math.sin(a) * 0.9, 0.0, 3.55 + math.cos(a) * 0.35), estrela, rot=(0, math.degrees(a), 0), seg=4)
    p.olhos(2.75, -1.05, 0.9, d=0.62)
    p.boca(1.45, -1.05, 0.7, alt=0.22, presas=True)


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
    cena.render.filepath = os.path.join(renders, "apresentacao.png")
    bpy.ops.render.render(write_still=True)
    print("RENDER apresentacao", flush=True)

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
        tam = max(p.max.z, p.max.x - p.min.x) * 1.15
        dist = tam / (2 * math.tan(math.atan(18 / 50))) + (p.max.y - p.min.y) / 2
        ang = math.radians(12)
        cam.location = centro + Vector((0.0, -dist * math.cos(ang), dist * math.sin(ang)))
        olhar_para(cam, centro)
        cena.render.filepath = os.path.join(renders, f"{p.id}.png")
        bpy.ops.render.render(write_still=True)
        print("RENDER", p.id, flush=True)
    for q in personagens:
        q.col.hide_render = False
    for ob in col_estudio.objects:
        ob.hide_render = False


main()

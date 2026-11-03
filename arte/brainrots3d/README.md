# Brainrots 3D (Blender)

19 personagens no estilo LEGO/Roblox: os 14 Brainrots que nascem dos ovos
(`Config.BRAINROTS`) e os 5 guardiões dos biomas como chefes (`Config.BIOMAS`).
Tudo é gerado por `gerar_brainrots.py`; para mudar um personagem, edite a função
dele no script e rode de novo.

```bash
blender -b --factory-startup -P arte/brainrots3d/gerar_brainrots.py
```

(`BR_SEM_RENDER=1` pula os renders; `BR_ENGINE=CYCLES` ou `WORKBENCH` troca o motor.)

## O que sai

| Arquivo | Conteúdo |
| --- | --- |
| `brainrots.blend` | Coleção `BRAINROTS` > `COMUNS` (14) e `BOSSES` (5), mais `APRESENTACAO` (fundo, luzes, câmera, palco) |
| `fbx/<Id>.fbx` | Um personagem por arquivo, pés na origem |
| `renders/apresentacao.png` | Os 14 comuns em grade e os 5 chefes atrás, no palco |
| `renders/<Id>.png` | Um render de cada |

## Personagens

Comuns: Patapim, Larila, Bananini, Ambalabu, Cappuccina, Trippi, Frigo,
Tralalero, Glorbo, Cocofanto, Bombardiro, Gusini, Svinino, Udin.

Cada um segue o visual do meme original (pesquisado por imagem), só que de
blocos: o Udin é a laranja musculosa, o Tralalero é o tubarão de 3 pernas de
tênis, o Bombardiro é o bombardeiro com cabeça de crocodilo, e assim por diante.

Chefes (1,7x a 2x maiores, íris vermelha e sobrancelha brava):

| Id | Guardião | Visual |
| --- | --- | --- |
| Sahur | Tung Tung Tung Sahur | tora de madeira com taco de pregos |
| Assassino | Cappuccino Assassino | copo de papel ninja com duas katanas |
| Cacto | Il Cacto Hipopotamo | cacto com cabeça de hipopótamo e sandálias |
| Toasterino | Rhino Toasterino | torradeira com cabeça de rinoceronte e torradas |
| Saturnita | La Vaca Saturno Saturnita | Saturno com cabeça de vaca e pés de gente |

## Organização

- Cada personagem tem um Empty com o `Id` (com as propriedades `nome` e
  `raridade`) e as partes como filhas, nomeadas `<Id>_<Parte>` (`Patapim_Cabeca`,
  `Sahur_Taco`...).
- As partes não têm transform: a origem de todas é o ponto entre os pés. Só o
  Empty é movido para montar a grade de apresentação.
- Sem modificadores. Materiais nomeados (`Patapim_Madeira`, `Olho_Branco`...) e a
  mesma cor gravada como cor de vértice (`Cor`), para o Roblox mostrar a cor
  mesmo sem material.

## Importar no Roblox Studio

- 1 unidade do Blender = 1 stud. O FBX sai em metros com 1 stud = 0,28 m; um
  comum tem uns 4 studs de altura e um chefe uns 7 a 8.
- Frente do personagem para -Z (frente do Roblox). Se vier de costas, gire 180°
  no importador.
- Cada parte vira uma MeshPart dentro de um Model.

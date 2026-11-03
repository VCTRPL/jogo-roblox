# Chefes (guardiões) em blocos LEGO

Os 5 chefes que estão em `ReplicatedStorage.ModelosChefao` no Studio, feitos no
Blender com blocos, pinos (studs) e textura pixel art, a partir das folhas de
referência em `referencias/` (frente, costas, lados, topo e 3/4).

| Arquivo | Guardião | Bioma |
| --- | --- | --- |
| `Sahur.blend` | Tung Tung Tung Sahur | Selva Sahur |
| `Assassino.blend` | Cappuccino Assassino | Praia Tralalá |
| `Cacto.blend` | Il Cacto Hipopotamo | Deserto Frigo |
| `Toasterino.blend` | Rhino Toasterino | Vulcão Toasterino |
| `Saturnita.blend` | La Vaca Saturno Saturnita | Espaço Saturnita |

## Como eles são montados (para animar)

Cada chefe é um Model com poucas peças, para o cliente conseguir animar:

- `Corpo`: tronco e cabeça (tudo que não mexe sozinho).
- `OlhoD` e `OlhoE`: os olhos, em Neon. Acendem forte quando ele fica bravo.
- `BracoD`, `BracoE`: braços (com o taco, as espadas...). D = direita do chefe.
- `PernaD`, `PernaE` (bípedes) ou `PernaFD`, `PernaFE`, `PernaTD`, `PernaTE`
  (o Rhino Toasterino, de 4 patas: F = frente, T = trás).
- `Anel`: o anel da Saturnita, que gira.
- Cada membro tem um `Attachment` chamado `Junta` na articulação (ombro,
  quadril). É em volta dele que `src/client/ChefesAnimacao.luau` gira o membro.
- `Raiz`: peça invisível nos pés, olhando para -Z (a frente do chefe).

1 unidade do Blender = 1 stud. No jogo eles ficam maiores
(`ALTURA_CHEFAO` em `src/server/Guardioes.luau` vezes `Config.ESCALA_CHEFE`).

## Trocar um chefe

Um Model novo em `ReplicatedStorage.ModelosChefao` com o nome exato do guardião
substitui o atual. Para ter animação, siga os nomes acima (membros com
`Junta`). Sem membros com `Junta`, o chefe só anda, sem mexer braços e pernas.

# Modelos 3D do mapa (low-poly)

Feitos no Blender (`MapaAssets.blend`) e importados para `ServerStorage.ModelosMapa`
no Studio. Cada um é um Model com o pivot no pé e as peças com o nome do que são,
para o código (`src/server/Adereco.luau`) pintar cada parte de uma cor.

| Modelo | Peças | Onde aparece |
| --- | --- | --- |
| `ArvoreRedonda`, `ArvoreLarga`, `ArvoreAlta`, `Pinheiro` | Tronco, Copa | área das bases, Selva |
| `Arbusto` | Copa | em todo lugar |
| `Pedra1..3` | Rocha | em todo lugar (com a cor do bioma) |
| `Margarida`, `Tulipa` | Caule, Petala (Miolo) | canteiros |
| `Palmeira`, `PalmeiraBaixa` | Tronco, Copa, Coco | Praia, oásis do Deserto |
| `Cacto`, `CactoBola`, `Mesa` | Cacto, Flor / Rocha, Faixa | Deserto |
| `ArvoreQueimada`, `Vulcao` | Tronco / Rocha, Lava | Vulcão |
| `Cristais`, `Meteoro`, `Planeta` | Cristal, Rocha / Planeta, Anel | Espaço |
| `Montanha1..3` | Rocha, Grama, Neve | montanhas em volta do mapa |
| `Poste`, `Luminaria` | Ferro, Dourado, Vidro | rua, caminhos e praças |
| `Chafariz` | Pedra, Base, Dourado, Agua | as duas praças |
| `Esteira` | Estrutura, Metal, Escuro, Neon | corpo das 7 esteiras (cores por nível) |

Sem a pasta `ModelosMapa` o jogo continua funcionando, só sem esses modelos.
Como ela é criada no Studio, publique o lugar para não perder.

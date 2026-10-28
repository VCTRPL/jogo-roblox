# Roube um Ovo Brainrot

Simulador para Roblox no estilo "Roube um Ovo" (Steal an Egg): pegue ovos nos ninhos dos biomas, fuja do guardião, leve para a sua base, espere chocar e ganhe dinheiro com os Brainrots que nascem (Brr Brr Patapim, Chimpanzini Bananini, Tralalero Tralala, Bombardiro Crocodilo, Udin Din Din Dun...).

## Como o jogo funciona

- **Base**: cada jogador recebe uma das 6 bases ao entrar. Ela tem 10 vagas, uma esteira de corrida e um botão de tranca. O mapa é criado por código quando o jogo começa.
- **Biomas**: seguindo a estrada, chega à Selva Sahur, Praia Tralalá (150 de Velocidade), Deserto Frigo (600), Vulcão Toasterino (2K) e Espaço Saturnita (6K). Cada bioma tem 8 ninhos com ovos, que se renovam a cada 3 minutos.
- **Pegar ovos**: segure **E** num ovo. Ele vai para cima da sua cabeça e o **guardião** do bioma acorda (Tung Tung Tung Sahur, Cappuccino Assassino, Il Cacto Hipopotamo, Rhino Toasterino e La Vaca Saturno Saturnita) e corre atrás de você. Se ele te pegar, você fica parado 2 segundos e o ovo volta para o ninho. Ovos maiores rendem mais, mas te deixam mais lento.
- **Chocar**: entre na sua base com o ovo e ele vai para uma vaga. Perto de chocar ele treme e racha. Depois ele vira um Brainrot, que dá dinheiro por segundo. Ao nascer, você ganha um bônus de dinheiro e de Velocidade. O Brainrot pode nascer com mutação: Prata (1.2x), Dourado (2.5x) ou Arco-íris (3.5x). Quando nasce um Lendário, Mítico, Secreto ou Arco-íris, o servidor inteiro fica sabendo.
- **Vender**: segure **E** num Brainrot da sua base para vender (vale 60 segundos da renda dele). Bom para abrir vaga para um melhor.
- **Velocidade**: corra em cima da esteira da sua base para ganhar Velocidade. Correndo sem parar, o **fôlego** sobe e o ganho chega a 2x. Segure **E** nela para melhorar (7 níveis, até a Esteira Divina). Mais Velocidade = anda mais rápido = foge do guardião e entra em biomas melhores.
- **Roubar**: segure **E** num ovo ou Brainrot da base de outro jogador e leve para a sua. Se morrer no caminho, ele volta para o dono. Cada roubo entregue conta no placar de **Roubos**.
- **Tranca**: o botão vermelho na entrada da base bloqueia roubos por 60 segundos.
- **Renascer**: com bastante dinheiro (2M no primeiro), o botão 🔄 zera dinheiro, Velocidade, esteira e a base, e dá para sempre +50% de dinheiro e +25% de Velocidade na esteira por renascimento.
- **Sons**: tudo tem som (pegar, chocar, vender, roubar...). O botão 🔊 liga e desliga. Música de fundo: ponha ids em `Config.MUSICA` (ou `musica` num bioma).
- Dinheiro, Velocidade, nível da esteira, renascimentos e o que está na base ficam salvos (DataStore).

Preços, rendas, chances, tempos e os biomas ficam todos em `src/shared/Config.luau`. Para criar um bioma novo, basta adicionar mais um item em `Config.BIOMAS`.

## Código

| Arquivo | O que faz |
| --- | --- |
| `src/shared/Config.luau` | Brainrots, ovos, biomas e números do jogo |
| `src/server/init.server.luau` | Liga tudo e cuida de quem entra e sai |
| `src/server/Mapa.luau` | Cria as bases, a estrada e os biomas |
| `src/server/Ninhos.luau` | Ninhos de ovos, guardião e bloqueio por Velocidade |
| `src/server/Guardioes.luau` | Modelos dos guardiões (Tung Tung Tung Sahur, Cappuccino Assassino) |
| `src/server/Carregar.luau` | Carregar ovos/Brainrots, entregar na base e roubar |
| `src/server/Bases.luau` | Vagas, chocar ovos, renda, esteira de corrida e tranca |
| `src/server/Velocidade.luau` | Velocidade de andar (atributo, peso do ovo, atordoado) |
| `src/server/Dados.luau` | Placar e salvamento |
| `src/server/Modelos.luau` | Cria os modelos 3D de ovos e Brainrots |
| `src/server/Decoracao.luau` | Céu, árvores, praia, arco de entrada, estátuas e portais |
| `src/server/Avisos.luau` | Mensagens na tela, anúncios e pedidos de efeitos para os clientes |
| `src/server/Blocos.luau` | Estilo Lego: pinos em cima das peças, bolas e cilindros viram blocos |
| `src/server/Montanhas.luau` | Montanhas quadradas em volta das bases e dos lados das fases |
| `src/server/Biblioteca.luau` | Prepara chefões e árvores da biblioteca do Roblox (sem scripts, no tamanho certo) |
| `src/server/Esteiras.luau` | Modelos e efeitos das 7 esteiras de corrida |
| `src/server/Renascer.luau` | Renascimento: zera o progresso e dá multiplicadores |
| `src/ferramentas/Legoizar.luau` | Ferramenta do Studio: transforma modelos da biblioteca em blocos (veja abaixo) |
| `src/client/init.client.luau` | Liga a tela e os efeitos e esconde "Roubar" nas suas próprias coisas |
| `src/client/Hud.luau` | Cartões de Dinheiro, Velocidade e Roubos, avisos e anúncio arco-íris |
| `src/client/Efeitos.luau` | Explosão de partículas quando um ovo choca |
| `src/client/Interface.luau` | Barra do próximo bioma, faixa "Carregando" com trilha até a base, Índice, Ajuda, Renascer e Som |
| `src/client/Corrida.luau` | Efeitos de quem corre na esteira, barra do fôlego, linhas de velocidade e luzes pulsando |
| `src/client/Ui.luau` | Peças de interface usadas por todas as telas |
| `src/client/Prompts.luau` | Botões "Pegar", "Roubar" etc. no estilo do jogo (tocar funciona no celular) |
| `src/client/Sons.luau` | Toca os sons pedidos pelo servidor e a música de fundo |
| `src/client/OvosVfx.luau` | Efeitos dos ovos: flutuar, aura, órbitas, raios, rachar e barra de tempo |

## Trocar os bonecos pelos modelos de verdade

Por enquanto cada Brainrot é um boneco feito de peças com as cores e um detalhe do personagem, e cada ovo é uma esfera com pintas. Para usar modelos de verdade:

1. No Studio, crie as pastas `ModelosBrainrot` e `ModelosOvo` dentro de `ReplicatedStorage`.
2. Coloque dentro delas **Models** com o mesmo nome do `id` no `Config.luau` (por exemplo `Tralalero` em `ModelosBrainrot`, `OvoTralalero` em `ModelosOvo`).
3. Pronto: o jogo passa a usar os seus modelos. Os que não tiverem modelo continuam com o boneco.

Do mesmo jeito, os chefões e as árvores podem vir da biblioteca do Roblox (Toolbox):

- `ReplicatedStorage.ModelosChefao`: um Model com o nome exato do guardião (`Tung Tung Tung Sahur`, `Cappuccino Assassino`).
- `ReplicatedStorage.ModelosArvore.Floresta` e `ReplicatedStorage.ModelosArvore.Praia`: árvores e palmeiras.

O jogo tira os scripts, ancora e ajusta o tamanho sozinho. Sem essas pastas ele usa os modelos de blocos.

### Transformar modelos da biblioteca em Lego

Para usar um modelo da Toolbox sem copiar o modelo de outra pessoa (e com a cara do resto do mapa), converta ele em blocos antes:

1. No Studio, crie `ServerStorage.Originais` com as subpastas `Brainrot`, `Ovo` e `Chefao`.
2. Ponha os modelos nelas com o nome do Config: o `id` do Brainrot (`Tralalero`), o `id` do ovo (`OvoTralalero`) ou o nome do guardião (`Tung Tung Tung Sahur`).
3. Na barra de comandos (**View > Command Bar**), com o jogo parado, rode:
   ```lua
   require(game.ServerStorage.Ferramentas.Legoizar).converterTudo()
   ```
4. Os modelos de blocos vão para `ModelosBrainrot`, `ModelosOvo` e `ModelosChefao`, e a pasta `Originais` é apagada.
5. Confira, pinte o que precisar e publique.

O conversor lê a cor de cada peça. Peças pintadas com textura (imagem) não dá para ler, então elas ficam com as cores do Brainrot no `Config.luau` e depois podem ser pintadas à mão.

Como essas pastas são criadas no Studio (e não no código), salve o lugar com **File > Publish to Roblox** para não perder.

## Salvamento no Studio

Para o DataStore funcionar quando você testa no Studio, o jogo precisa estar publicado e com a opção **Game Settings > Security > Enable Studio Access to API Services** ligada. Sem isso o jogo funciona normalmente, só não salva (aparece um aviso amarelo no Output).

---

Projeto de jogo para Roblox usando [Rojo](https://rojo.space), que sincroniza o código deste repositório com o Roblox Studio. Assim você escreve o código no seu editor (como o VS Code), guarda tudo no GitHub e vê as mudanças no Studio na hora.

## Estrutura

```
default.project.json   -> diz ao Rojo onde cada pasta vai parar dentro do jogo
rokit.toml             -> versão do Rojo usada no projeto
src/
  server/              -> ServerScriptService.Server  (código que roda no servidor)
  client/              -> StarterPlayer.StarterPlayerScripts.Client  (código de cada jogador)
  shared/              -> ReplicatedStorage.Shared  (módulos usados pelos dois lados)
```

Convenção de nomes dos arquivos:

| Arquivo              | Vira no Studio |
| -------------------- | -------------- |
| `algo.server.luau`   | `Script`       |
| `algo.client.luau`   | `LocalScript`  |
| `algo.luau`          | `ModuleScript` |
| `init.server.luau`   | a própria pasta vira um `Script` |

## Passo a passo

### 1. Instalar o Rojo (linha de comando)

Escolha **uma** das opções:

**Opção A: Rokit (recomendado)**

1. Instale o [Rokit](https://github.com/rojo-rbx/rokit#installation):
   - Windows (PowerShell):
     ```powershell
     Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
     ```
   - macOS / Linux:
     ```bash
     curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
     ```
2. Feche e abra o terminal de novo.
3. Dentro da pasta do projeto, rode:
   ```bash
   rokit install
   ```
   Isso instala a versão do Rojo indicada no `rokit.toml`.

**Opção B: Aftman (alternativa mais antiga)**

Se você já usa [Aftman](https://github.com/LPGhatguy/aftman), crie um `aftman.toml` com:

```toml
[tools]
rojo = "rojo-rbx/rojo@7.4.4"
```

e rode `aftman install`.

**Opção C: download direto**

Baixe o executável na [página de releases do Rojo](https://github.com/rojo-rbx/rojo/releases), descompacte e coloque o `rojo` em uma pasta que esteja no seu `PATH`.

Para conferir se deu certo:

```bash
rojo --version
```

### 2. Instalar o plugin do Rojo no Roblox Studio

O jeito mais fácil:

```bash
rojo plugin install
```

Ou instale pela [página do plugin na Creator Store](https://create.roblox.com/store/asset/13916111004/Rojo). Depois, reinicie o Studio. Vai aparecer um botão **Rojo** na aba **Plugins**.

### 3. Baixar o projeto

```bash
git clone https://github.com/VCTRPL/jogo-roblox.git
cd jogo-roblox
```

### 4. Iniciar o servidor do Rojo

Na pasta do projeto:

```bash
rojo serve
```

Deixe esse terminal aberto. Ele fica observando os arquivos e manda as mudanças para o Studio.

### 5. Conectar no Studio

1. Abra o Roblox Studio e crie um lugar novo (por exemplo, **Baseplate**).
2. Vá em **Plugins > Rojo** e clique em **Connect**.
3. Pronto: as pastas `Server`, `Client` e `Shared` aparecem no Explorer.
4. Aperte **Play**. O mapa aparece e você nasce na sua base.

Agora é só editar os arquivos em `src/` e salvar: o Studio atualiza sozinho.

> Dica: o Rojo sincroniza código. O que você montar direto no Studio (decoração, modelos, terreno) fica no lugar do Studio, não no GitHub. Salve o lugar com **File > Publish to Roblox** para não perder o que construiu.

### 6. (Opcional) Gerar um arquivo do jogo

```bash
rojo build -o jogo.rbxl
```

Isso cria um `jogo.rbxl` que pode ser aberto direto no Studio.

## Editor recomendado

No VS Code, instale as extensões sugeridas pelo projeto (aparece um aviso ao abrir a pasta):

- **Rojo** (`evaera.vscode-rojo`)
- **Luau Language Server** (`JohnnyMorganz.luau-lsp`), para autocompletar e checar erros

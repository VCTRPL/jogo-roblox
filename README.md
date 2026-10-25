# Roube um Ovo Brainrot

Simulador para Roblox no estilo "Roube um Ovo" (Steal an Egg): pegue ovos nos ninhos dos biomas, fuja do guardião, leve para a sua base, espere chocar e ganhe dinheiro com os Brainrots que nascem (Brr Brr Patapim, Chimpanzini Bananini, Tralalero Tralala, Bombardiro Crocodilo...).

## Como o jogo funciona

- **Base**: cada jogador recebe uma das 8 bases ao entrar. Ela tem 10 vagas, uma esteira de corrida e um botão de tranca. O mapa é criado por código quando o jogo começa.
- **Biomas**: seguindo a estrada, chega à Selva Sahur e depois à Praia Tralalá. Cada bioma tem 8 ninhos com ovos, que se renovam a cada 3 minutos. A Praia só deixa entrar quem tem 150 de Velocidade.
- **Pegar ovos**: segure **E** num ovo. Ele vai para cima da sua cabeça e o **guardião** do bioma acorda (Tung Tung Tung Sahur na Selva, Cappuccino Assassino na Praia) e corre atrás de você. Se ele te pegar, você fica parado 2 segundos e o ovo volta para o ninho. Ovos maiores rendem mais, mas te deixam mais lento.
- **Chocar**: entre na sua base com o ovo e ele vai para uma vaga. Depois de um tempo ele choca e vira um Brainrot, que dá dinheiro por segundo. Ao nascer, você ganha um bônus de dinheiro e de Velocidade. O Brainrot pode nascer com mutação: Prata (1.2x), Dourado (2.5x) ou Arco-íris (3.5x). Quando nasce um Lendário, um Mítico ou um Arco-íris, o servidor inteiro fica sabendo.
- **Velocidade**: corra em cima da esteira da sua base para ganhar Velocidade. Segure **E** nela para melhorar (5 níveis). Mais Velocidade = anda mais rápido = foge do guardião e entra em biomas melhores.
- **Roubar**: segure **E** num ovo ou Brainrot da base de outro jogador e leve para a sua. Se morrer no caminho, ele volta para o dono. Cada roubo entregue conta no placar de **Roubos**.
- **Tranca**: o botão vermelho na entrada da base bloqueia roubos por 60 segundos.
- Dinheiro, Velocidade, nível da esteira e o que está na base ficam salvos (DataStore).

Preços, rendas, chances, tempos e os biomas ficam todos em `src/shared/Config.luau`. Para criar um bioma novo, basta adicionar mais um item em `Config.BIOMAS`.

## Código

| Arquivo | O que faz |
| --- | --- |
| `src/shared/Config.luau` | Verities, ovos, biomas e números do jogo |
| `src/server/init.server.luau` | Liga tudo e cuida de quem entra e sai |
| `src/server/Mapa.luau` | Cria as bases, a estrada e os biomas |
| `src/server/Ninhos.luau` | Ninhos de ovos, guardião e bloqueio por Velocidade |
| `src/server/Carregar.luau` | Carregar ovos/Verities, entregar na base e roubar |
| `src/server/Bases.luau` | Vagas, chocar ovos, renda, esteira de corrida e tranca |
| `src/server/Velocidade.luau` | Velocidade de andar (atributo, peso do ovo, atordoado) |
| `src/server/Dados.luau` | Placar e salvamento |
| `src/server/Modelos.luau` | Cria os modelos 3D de ovos e Verities |
| `src/server/Avisos.luau` | Mensagens na tela do jogador |
| `src/client/init.client.luau` | Mostra os avisos e esconde "Roubar" nas suas próprias coisas |

## Trocar os bonecos pelos modelos de verdade

Por enquanto cada Brainrot é um boneco simples com as cores do personagem, e cada ovo é uma esfera. Para usar modelos de verdade:

1. No Studio, crie as pastas `ModelosBrainrot` e `ModelosOvo` dentro de `ReplicatedStorage`.
2. Coloque dentro delas **Models** com o mesmo nome do `id` no `Config.luau` (por exemplo `Tralalero` em `ModelosBrainrot`, `OvoTralalero` em `ModelosOvo`).
3. Pronto: o jogo passa a usar os seus modelos. Os que não tiverem modelo continuam com o boneco.

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
4. Aperte **Play**. O mapa aparece, você nasce na sua base e os Verities começam a passar na esteira.

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

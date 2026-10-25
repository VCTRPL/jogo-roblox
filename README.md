# Roube um Verity

Simulador para Roblox no estilo "roube um ...": Verities passam numa esteira, você compra com dinheiro, eles geram renda na sua base, e os outros jogadores podem roubar.

## Como o jogo funciona

- Cada jogador recebe uma das 8 bases ao entrar (o mapa é criado por código quando o jogo começa).
- Verities passam pela esteira no meio do mapa. Chegue perto e aperte **E** para comprar. Ele vai direto para uma vaga da sua base.
- Cada Verity na base gera dinheiro por segundo (aparece no placar e na placa da base).
- Na base de outro jogador, segure **E** em um Verity para roubar. Ele fica em cima da sua cabeça, você anda mais devagar, e precisa chegar até a sua base. Se morrer no caminho, o Verity volta para o dono.
- O botão vermelho na entrada da base tranca a base por 60 segundos: ninguém consegue roubar enquanto o escudo azul estiver ligado.
- Dinheiro e Verities ficam salvos (DataStore).

Os preços, rendas, chances e tempos ficam todos em `src/shared/Config.luau`.

## Código

| Arquivo | O que faz |
| --- | --- |
| `src/shared/Config.luau` | Lista de Verities e números do jogo |
| `src/server/init.server.luau` | Liga tudo e cuida de quem entra e sai |
| `src/server/Mapa.luau` | Cria a esteira e as bases |
| `src/server/Esteira.luau` | Verities andando na esteira e a compra |
| `src/server/Bases.luau` | Vagas, renda por segundo e tranca |
| `src/server/Roubo.luau` | Roubar, carregar e entregar |
| `src/server/Dados.luau` | Dinheiro e salvamento |
| `src/server/Verities.luau` | Cria o modelo 3D de cada Verity |
| `src/server/Avisos.luau` | Mensagens na tela do jogador |
| `src/client/init.client.luau` | Mostra os avisos e esconde "Roubar" nos seus próprios Verities |

## Trocar o boneco pelo modelo do Verity

Por enquanto cada Verity é um boneco simples colorido pela raridade. Para usar um modelo de verdade:

1. No Studio, crie uma pasta chamada `ModelosVerity` dentro de `ReplicatedStorage`.
2. Coloque dentro dela um **Model** com o mesmo nome do `id` do Verity no `Config.luau` (por exemplo `VerityComum`, `VerityNinja`).
3. Pronto: o jogo passa a usar o seu modelo. Os que não tiverem modelo continuam com o boneco.

Como essa pasta é criada no Studio (e não no código), salve o lugar com **File > Publish to Roblox** para não perder.

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

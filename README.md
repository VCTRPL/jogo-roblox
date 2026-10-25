# jogo-roblox

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
4. Aperte **Play**. Na janela **Output** você deve ver:
   ```
   Olá, servidor!
   Olá, <seu nome>! Entrou no jogo.
   Olá, <seu nome>! (mensagem do cliente)
   ```

Agora é só editar os arquivos em `src/` e salvar: o Studio atualiza sozinho.

> Dica: o Rojo sincroniza código, mas o mapa (peças, modelos, terreno) você monta no próprio Studio. Salve o lugar com **File > Publish to Roblox** para não perder o que construiu.

### 6. (Opcional) Gerar um arquivo do jogo

```bash
rojo build -o jogo.rbxl
```

Isso cria um `jogo.rbxl` que pode ser aberto direto no Studio.

## Editor recomendado

No VS Code, instale as extensões sugeridas pelo projeto (aparece um aviso ao abrir a pasta):

- **Rojo** (`evaera.vscode-rojo`)
- **Luau Language Server** (`JohnnyMorganz.luau-lsp`), para autocompletar e checar erros

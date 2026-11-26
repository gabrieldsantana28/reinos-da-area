# Reinos da Área · v0.3.0

**Jogo sério de estratégia territorial sobre estimativa e comparação de áreas.**
Feito em Godot 4.6 pelo grupo **Dominadores**: Gabriel Luis de Santana e Bruno Farias Travessini.

Compare a área do seu reino (azul, com malha) com a do reino inimigo (vermelho, **sem malha**) e decida: **Atacar**, **Defender** ou **Recuar**. Domine 70% do mapa em 10 rodadas. Nenhuma fórmula aparece na tela: a geometria é a sua arma.

📄 **GDD atualizado:** [`gdd/GDD_Reinos_da_Area.md`](gdd/GDD_Reinos_da_Area.md) ([PDF](gdd/GDD_Reinos_da_Area.pdf))

---

## Jogar agora

| Como | Passos |
|---|---|
| **No navegador** | Abra o link do GitHub Pages deste repositório (pasta [`docs/`](docs/)). Funciona no Chrome, Edge e Firefox. |
| **Windows** | Baixe `ReinosDaArea_v0.3.0_Windows.zip` em **Releases**, extraia e dê dois cliques em `ReinosDaArea.exe`. Se aparecer "O Windows protegeu o computador", clique em **Mais informações → Executar assim mesmo** (o executável não é assinado). |
| **Linux** | Baixe `ReinosDaArea_v0.3.0_Linux.zip` em **Releases**, extraia e rode `chmod +x ReinosDaArea.x86_64 && ./ReinosDaArea.x86_64`. |
| **Pelo código-fonte** | Instale o [Godot 4.6.x](https://godotengine.org/download/archive/4.6.3-stable/) (versão padrão, sem .NET), clique em **Importar**, escolha `project.godot` e aperte **F5**. |

Requisitos: 64 bits e placa de vídeo com OpenGL 3.3 (ou WebGL 2 no navegador). Não precisa instalar nada.

---

## Como jogar

1. No menu, clique em **JOGAR** e escolha o modo:
   - **Modo História:** 20 fases em 5 cenários, com prólogo, a Cartógrafa e estrelas por fase.
   - **Campanha Clássica:** a partida original de 10 rodadas.
2. Na primeira vez, o jogo oferece o **Tutorial** (cerca de 3 minutos, com rodada de treino sem relógio).
3. Em cada rodada, estime a área do inimigo e escolha uma ação antes do relógio zerar:

| Ação | Tecla | Vence quando | Se vencer | Se errar |
|---|---|---|---|---|
| Atacar | **A** | Sua área > área do inimigo × terreno | +10% de Domínio, área +10% | área −20% |
| Defender | **D** | Área do inimigo × terreno ≥ sua área | +10% de Domínio, área +5% | área −10% |
| Recuar | **R** | Sempre | Domínio igual, área −5% | — |

4. Depois da escolha, a malha aparece sobre o inimigo e mostra a área real.
5. Termine as 10 rodadas com **Domínio ≥ 70%** para concluir a fase.

**Terrenos (Modo História):** Serra faz o inimigo valer ×1,47 (defender fica forte) e Costeiro faz valer ×0,82 (atacar fica forte). O terreno aparece no painel antes da decisão.

**Estrelas:** ★ Domínio ≥ 70% · ★★ ≥ 80% · ★★★ ≥ 80% sem nenhuma derrota.

### Controles

| Tecla | Ação |
|---|---|
| A / D / R | Atacar / Defender / Recuar |
| Enter / Espaço | Próxima rodada |
| Esc / P | Pausar (o relógio para) |
| F11 | Tela cheia ↔ janela |
| Setas + Enter | Navegar nos menus e no tutorial |

---

## Modo História

| Cenário | Fases | Forma dos reinos | Grid ao redor do inimigo | Terreno | Tempo |
|---|---|---|---|---|---|
| I · Planícies de Aldrath | 1–4 | Retângulos | Completo | Planície | Da dificuldade |
| II · Vales de Kheldorn | 5–8 | Quinas recortadas | 1 célula | Planície e Serra | Da dificuldade |
| III · Serra das Pedras Vivas | 9–12 | Formas em L | Nenhum | Planície e Serra | Da dificuldade |
| IV · Arquipélago do Oblívio | 13–16 | Bordas em degrau | Nenhum | Costeiro | 45 s |
| V · Abismo Irregular | 17–20 | Sem padrão | Nenhum | Misturados | 30 s |

A Cartógrafa dá dicas nas fases 1–6, só comenta derrotas nas 7–9 e se despede na Fase 10. A Fase 20 é **Morte Súbita**: a primeira derrota encerra a fase. O progresso fica salvo no computador.

---

## O que mudou na v0.3.0

Ajustes feitos a partir da ficha técnica da outra equipe e do feedback do professor (detalhes e antes/depois na seção 19 do GDD):

1. **Jogar** abre a escolha entre Modo História e Campanha Clássica; a história do GDD agora está dentro do jogo.
2. **Terrenos** Serra e Costeiro mudam o cálculo de verdade (antes o modificador ficava sempre em "Nenhum").
3. **Formas por cenário** e **grid de referência que vai sumindo**, criando a curva de dificuldade do GDD.
4. **A Cartógrafa**, com dicas nas primeiras fases (iniciativa da equipe).
5. **Estrelas**, fases liberadas em sequência e progresso salvo.

Menu, Opções, Tutorial e as regras da Campanha Clássica continuam iguais aos da v0.2.

---

## Estrutura do projeto

```
├── project.godot              configuração (cena inicial: Menu.tscn)
├── export_presets.cfg         perfis de exportação: Windows, Linux e Web
├── scenes/                    Menu, Tutorial, StoryMap (Modo História) e Main (batalha)
├── scripts/
│   ├── Menu.gd                menu, escolha de modo, Opções e Créditos
│   ├── Tutorial.gd            tutorial interativo em 8 passos
│   ├── StoryMap.gd            mapa do Modo História e prólogo
│   ├── Story.gd               (autoload) cenários, 20 fases, terrenos, estrelas e progresso
│   ├── Main.gd                HUD, rodadas, resultado, resumo, pausa e Cartógrafa
│   ├── GameManager.gd         regras, relógio e pontuação
│   ├── TerritoryGenerator.gd  geração dos reinos (retângulo, recorte, L, degrau, orgânica)
│   ├── TerritoryRenderer.gd   desenho do mapa, malha, grid de referência e animações
│   ├── Settings.gd            (autoload) preferências e recordes
│   ├── AudioManager.gd        (autoload) música e efeitos
│   └── UIKit.gd               cores, fontes, botões e transições
├── assets/                    áudios, fontes, ícones e cursores
├── tests/                     testes automáticos (TestStory, TestClassic)
├── gdd/                       Game Design Document atualizado (Markdown e PDF)
└── docs/                      versão Web exportada (publicada pelo GitHub Pages)
```

### Testes automáticos

```bash
godot --path . res://tests/TestStory.tscn     # imprime RESULT: OK
godot --path . res://tests/TestClassic.tscn   # joga 10 rodadas da campanha clássica
```

### Exportar

Instale os modelos de exportação do Godot 4.6.3 (**Editor → Gerenciar Modelos de Exportação**) e use **Projeto → Exportar** com um dos perfis prontos, ou pela linha de comando:

```bash
godot --headless --path . --export-release "Windows Desktop"   # build/windows/ReinosDaArea.exe
godot --headless --path . --export-release "Linux"             # build/linux/ReinosDaArea.x86_64
godot --headless --path . --export-release "Web"               # build/web/index.html
```

O perfil Web é exportado sem threads, então funciona em hospedagem estática comum (como o GitHub Pages) sem cabeçalhos especiais. Para testar localmente, sirva a pasta com `python -m http.server` em vez de abrir o `index.html` direto do disco.

---

## Créditos

- **Equipe:** Gabriel Luis de Santana e Bruno Farias Travessini (grupo Dominadores)
- **Motor:** Godot Engine 4.6 (licença MIT)
- **Fontes:** Cinzel, Libre Baskerville e Source Sans 3 (SIL Open Font License)

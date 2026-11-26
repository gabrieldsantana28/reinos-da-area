# Reinos da Área — Game Design Document

**Conquiste territórios. Calcule para vencer. Pense para sobreviver.**

| Gênero | Plataforma | Público | Conteúdo |
|---|---|---|---|
| Strategy Puzzle | PC (Windows, Linux) e navegador (Web) | 12 a 16 anos | 20 fases em 5 cenários + campanha clássica |

**Grupo Dominadores:** Gabriel Luis de Santana e Bruno Farias Travessini  
**Versão do documento:** 2.0, alinhada à **versão 0.3.0** do jogo (entregue em novembro de 2026)  
**Motor:** Godot Engine 4.6 (renderizador Compatibility)

---

## Como ler este documento

Este GDD descreve **o jogo que foi entregue na v0.3.0**. Cada seção indica o que está implementado e o que continua só no papel:

- ✅ **Implementado**: está no executável entregue e pode ser visto jogando.
- 🔶 **Parcial**: existe no jogo, mas de forma diferente ou reduzida em relação ao plano original.
- ⬜ **Planejado**: continua sendo do projeto, mas não está na v0.3.0.

A seção 19 lista os ajustes feitos a partir da ficha técnica da outra equipe e do feedback do professor, com o antes e o depois.

### Histórico de versões

| Versão do GDD | Versão do jogo | O que mudou |
|---|---|---|
| 1.0 | — | Documento de concepção (Enzo Camelo Vieira, Gabriel Luis de Santana e Bruno Faria Travessini): conceito, 18 seções, arquétipos, cenários e narrativa. |
| 1.1 | 0.2.x | Protótipo jogável: partida de 10 rodadas, menu, tutorial, opções, pausa e créditos. |
| **2.0** | **0.3.0** | Documento reescrito para descrever a versão entregue: Modo História com 20 fases, terrenos com modificadores, formas por cenário, grid de referência que some, Cartógrafa, estrelas e ajustes da ficha técnica e do feedback. |

---

## 1. High Concept

*Reinos da Área* tem duplo sentido de propósito: "reino" evoca conquista e poder, e "área" é ao mesmo tempo o conceito matemático central e o espaço disputado no mapa.

É um jogo de conquista territorial em que a força de cada reino é a sua área. O reino inimigo aparece inteiro no mapa, mas **sem a malha quadriculada por cima**. O jogador olha a forma vermelha, estima quantos quadrados existem ali e decide se ataca, defende ou recua. Calcular bem significa conquistar; estimar mal significa perder território.

**Missão do jogador:** como Arquiteto-Rei, expandir as fronteiras do reino usando o raciocínio geométrico como arma. Cada fase tem 10 rodadas contra 10 reinos inimigos e começa com o Domínio do Mapa em 0%. A meta é chegar a 70%.

**Inovação central:** assimetria de informação visual. O território do jogador tem grade e área exata no HUD; o do inimigo é uma forma sólida sem grade. Isso obriga a estimar e decidir sob incerteza, com a geometria como ferramenta estratégica e não como exercício explícito.

## 2. Visão geral

| Item | Valor na v0.3.0 |
|---|---|
| Gênero | Strategy Puzzle · Stealth Learning |
| Plataformas | ✅ Windows (.exe), ✅ Linux, ✅ navegador (Web/WebGL 2) |
| Jogadores | 1 (singleplayer) |
| Público-alvo | 12 a 16 anos (7º ano do Fundamental ao 2º ano do Médio) |
| Conteúdo | Geometria plana: estimativa visual e comparação de áreas |
| Modos | ✅ Modo História (20 fases em 5 cenários) e ✅ Campanha Clássica (10 rodadas) |
| Duração | Uma fase dura de 5 a 10 minutos |
| Idioma | Português do Brasil |
| Classificação | Livre |

## 3. Pilares de design

| Pilar | Como aparece na v0.3.0 | Métrica |
|---|---|---|
| **01 · Aprendizado invisível** | Nenhuma fórmula na tela. O jogador recebe uma decisão de guerra e aprende contando a malha. | Jogador internaliza a estimativa de área sem aula formal. |
| **02 · Risco com consequência real** | Errar custa área visível no mapa e zera a sequência. O resultado é 100% determinístico. | 0% de aleatoriedade no resultado do combate. |
| **03 · Profundidade emergente** | Retângulos nas primeiras fases e formas sem padrão, com menos tempo, no fim. | Curva sem picos abruptos entre cenários. |
| **04 · Identidade narrativa medieval** | Prólogo, cartões de fase, a Cartógrafa e reinos rivais com nome dão peso às decisões. | Jogador nunca sente que está "estudando matemática". |
| **05 · Calibração progressiva** | 🔶 Estrelas por fase e recorde de pontuação recompensam jogar melhor. O Índice de Precisão das Estimativas ainda não foi implementado. | Jogadores repetem fases para conseguir 3 estrelas. |
| **06 · O que o jogo evita** | Nenhuma tela de exercício, nenhuma sorte que invalide um cálculo correto. | Nunca uma prova disfarçada de jogo. |

## 4. Core gameplay — sistema de combate ✅

O jogador é o único agente ativo. Não há turno inimigo: os reinos rivais aguardam a decisão do Arquiteto-Rei. O resultado depende apenas da comparação entre a área do jogador e a área do inimigo, filtrada pela ação escolhida e pelo terreno.

### As três ações

| Ação (tecla) | Vence quando | Se vencer | Se perder |
|---|---|---|---|
| **Atacar** (A) | Área do jogador > área do inimigo × modificador do terreno | +10% de Domínio e a área cresce 10% | A área cai 20% e a sequência zera |
| **Defender** (D) | Área do inimigo × modificador ≥ área do jogador | +10% de Domínio e a área cresce 5% | A área cai 10% e a sequência zera |
| **Recuar** (R) | Sempre (não há combate) | Domínio igual, a área cai 5% | — |
| **Tempo esgotado** | Conta como recuo forçado | Domínio igual, a área cai 5% | — |

O recuo custa bem menos que errar Atacar ou Defender. Isso incentiva o jogador a agir só quando confia na estimativa.

### Modificadores de terreno ✅ (Modo História)

O terreno muda o **limiar** da comparação, sem nenhuma aleatoriedade. A razão defensor ÷ atacante multiplica a área do inimigo antes da comparação.

| Terreno | Defensor | Atacante | Razão aplicada ao inimigo | Efeito prático |
|---|---|---|---|---|
| Planície | ×1,00 | ×1,00 | ×1,00 | Comparação direta |
| Serra | ×1,25 | ×0,85 | **×1,47** | Um inimigo que parece menor pode resistir ao ataque |
| Costeiro | ×0,90 | ×1,10 | **×0,82** | O atacante leva vantagem; defender exige área maior |

O painel "Informações de Batalha" mostra o terreno da rodada (por exemplo, "Serra ×1,47") e as forças de ataque e defesa. Depois do combate, a mensagem de resultado mostra a conta completa: "Inimigo: 31 × Serra (1,47) = 45".

### Objetivo, vitória e derrota

- **Objetivo:** terminar as 10 rodadas com **Domínio ≥ 70%**.
- **Vitória:** tela "Fase concluída!" com vitórias, derrotas, recuos, Domínio final e pontuação.
- **Derrota:** Domínio abaixo de 70% ao fim das 10 rodadas ("Fase fracassada"). Na **Fase 20 (Morte Súbita)**, a primeira derrota encerra a fase na hora.
- 🔶 A derrota por "área zerada" do GDD 1.0 não acontece: a área do jogador fica entre 10 e 90 células para manter o equilíbrio (ajuste de balanceamento da v0.2).

### Pontuação ✅

Vitória = 100 pontos + até 200 de bônus de velocidade + 50 por vitória seguida a partir da segunda. Derrota = −50 (mínimo 0). O recorde e o melhor Domínio ficam salvos no computador.

## 5. Mecânicas — passo a passo

### Mecânica 1 · Seleção e resolução de ataque ✅

1. A rodada começa: o mapa é desenhado, o ícone **VS** cai no centro e o relógio inicia.
2. Os botões Atacar, Defender e Recuar ficam disponíveis depois de 1,5 s, com legenda curta ("Sou maior", "Inimigo é maior", "Não arriscar") e atalho A / D / R.
3. O jogador escolhe. O cálculo acontece em segundo plano, sem mostrar números, para preservar a tensão.
4. A animação de resultado é disparada: faíscas verdes (vitória), marcas em "X" vermelhas (derrota) ou rajada de vento (recuo).
5. A **malha aparece sobre o inimigo** (revelação) e o painel mostra as duas áreas, o terreno e a diferença em porcentagem. O Domínio é atualizado no HUD.

> **Mudança em relação ao GDD 1.0:** não é preciso clicar no território inimigo antes de escolher a ação, porque só existe um inimigo por rodada. As ações vão direto nos botões ou no teclado.

### Mecânica 2 · Habilidades de arquétipo ⬜

O painel "Arquétipo ativo" mostra o **Guerreiro Nv. 2** com a passiva *Legião de Cativos* e a ativa *Aço Duplo*. Na v0.3.0 o painel é **só informativo**: as habilidades ainda não alteram o cálculo. A ativação dos três arquétipos é a próxima etapa do projeto (seção 6).

### Mecânica 3 · Avanço de rodada e fim de fase ✅

1. O jogador confirma em "Próxima rodada" (ou Enter). O contador de rodadas avança e o próximo reino é gerado.
2. Ao fim da 10ª rodada (ou na primeira derrota da Fase 20), o sistema compara o Domínio com 70%.
3. A tela de fim de fase mostra o resultado, a pontuação e, no Modo História, as **estrelas** e a próxima fase liberada.
4. Botões: Repetir fase, Próxima fase e Mapa da história (no Modo História); Jogar novamente e Menu principal (na Campanha Clássica).

```
Início da fase → Rodada N (1 a 10) → Atacar / Defender / Recuar → Revelação
      ↑                                                             │
      └──────────── não ── 10 rodadas concluídas? ─────────────────┘
                                   │ sim (ou derrota na Fase 20)
                          Domínio ≥ 70%? → Sim: vitória + estrelas · Não: fase fracassada
```

## 6. Sistemas — habilidades e arquétipos ⬜

Os três arquétipos continuam no design e são o foco da próxima versão. Na v0.3.0 só o Guerreiro aparece no painel, sem efeito no cálculo.

| Arquétipo | Passiva | Ativa | Situação |
|---|---|---|---|
| **Engenheiro** (expansão e fortificação) | *Fortificações de Batalha*: +5% de área ao Defender | *Espólios de Cerco* (a partir da Fase 3): +1 célula real por vitória em sequência | ⬜ Planejado |
| **Guerreiro** (ímpeto e força) | *Legião de Cativos*: +2% de área ao Atacar por vitória seguida (até +10%); zera na derrota | *Aço Duplo*: dobra o bônus da passiva por uma rodada | 🔶 Exibido no painel, sem efeito |
| **Estrategista** (inteligência e controle) | *Infiltração Noturna*: 4 células do inimigo reveladas no início da rodada | *Cartografia Roubada*: malha do inimigo visível por N segundos, N = vitórias em sequência | ⬜ Planejado |

## 6.1 Sistema de cálculo de área ✅

- A área de qualquer território é o **número de quadrados da malha** dentro da forma. Cada quadrado vale 1.
- O mapa tem 32 × 13 células: a metade esquerda é do jogador e a direita é do inimigo.
- **Território do jogador:** malha sempre visível e área exata no HUD ("Área total").
- **Território inimigo:** forma vermelha inteira, **sem malha por cima**.
- **Grid de referência:** as linhas da malha **ao redor** do inimigo servem de régua. No Modo História essa ajuda diminui por cenário (seção 8).
- **Revelação pós-combate:** a malha aparece sobre o inimigo e a mensagem mostra a área real, o modificador de terreno e a diferença. É o momento de aprendizagem mais rico do ciclo.

## 7. Core game loop ✅

**Observar → Estimar → Decidir → Combater → Aprender → Repetir**

1. **Observação:** o jogador vê o mapa inteiro, o seu território com malha e o reino inimigo sem malha. Nas primeiras fases, a Cartógrafa comenta a forma ("Retângulos não enganam: largura vezes altura").
2. **Estimativa visual:** conta mentalmente usando o grid ao redor (quando existe), compara colunas e linhas ou divide a forma em partes.
3. **Decisão tática:** Atacar, Defender ou Recuar, antes de o relógio zerar. O relógio fica vermelho e toca um tambor nos últimos 10 segundos.
4. **Resolução:** o sistema compara as áreas reais com o terreno. A animação comunica vitória, derrota ou recuo sem linguagem de "resposta errada".
5. **Revelação e aprendizado:** a malha aparece sobre o inimigo e o painel mostra a conta. A próxima rodada começa.

### Sistema de estrelas ✅ (Modo História)

| Estrelas | Condição na v0.3.0 |
|---|---|
| ★ | Concluir a fase (Domínio ≥ 70%) |
| ★★ | Domínio final ≥ 80% |
| ★★★ | Domínio final ≥ 80% **sem nenhuma derrota** |

> **Mudança em relação ao GDD 1.0:** o ouro dependia do Índice de Precisão (≥ 85%) e a prata, de vencer com até 60% das rodadas. Como as fases sempre têm 10 rodadas e o Índice de Precisão ainda não existe, as estrelas usam o Domínio final e as derrotas, que o jogador entende na hora. O melhor resultado de cada fase fica salvo.

## 8. Progressão ✅

Duas pressões crescem juntas: o reino do jogador começa maior a cada cenário (mais quadrados para contar) e a **diferença de tamanho** entre jogador e inimigo diminui, exigindo estimativas mais finas. A diferença também encolhe dentro da fase: na 10ª rodada ela é 60% da diferença da 1ª.

| Cenário | Fases | Forma dos reinos | Grid ao redor do inimigo | Terrenos | Tempo por rodada | Diferença entre reinos | Área inicial |
|---|---|---|---|---|---|---|---|
| I · Planícies de Aldrath | 1–4 | Retângulos | Completo | Planície | Da dificuldade (60 s no Normal) | ×1,3 (mais fácil) | 16–24 |
| II · Vales de Kheldorn | 5–8 | Quinas recortadas | 1 célula | Planície e Serra | Da dificuldade | ×1,1 | 26–36 |
| III · Serra das Pedras Vivas | 9–12 | Formas em L / compostas | Nenhum | Planície e Serra | Da dificuldade | ×1,0 | 32–44 |
| IV · Arquipélago do Oblívio | 13–16 | Bordas em degrau | Nenhum | Costeiro e Planície | **45 s** | ×0,9 | 36–48 |
| V · Abismo Irregular | 17–20 | Formas sem padrão | Nenhum | Os três, misturados | **30 s** | ×0,8 (mais difícil) | 40–55 |

**Fases liberadas em sequência:** cada fase concluída libera a próxima. O progresso fica salvo no computador.

**Dificuldade (menu Opções)** vale para os dois modos:

| Dificuldade | Diferença entre reinos | Tempo por rodada |
|---|---|---|
| Fácil | 12% a 25% | 75 s |
| Normal | 5% a 15% | 60 s |
| Difícil | 3% a 8% | 40 s |

> **Mudança em relação ao GDD 1.0:** o Cenário IV previa "polígonos com diagonais e células parciais". Como o território é feito de células inteiras, as diagonais viraram **bordas em degrau**, que mantêm a ideia de borda inclinada sem células fracionadas.

## 9. Personagens ✅

- **O Arquiteto-Rei (jogador):** jovem herdeiro de um pequeno reino retangular nas Planícies de Aldrath. Aprende a pensar geometricamente por necessidade.
- **A Cartógrafa (narradora e guia):** conta o prólogo e dá dicas na faixa dourada acima do mapa. Ensina a olhar e nunca dá a resposta.
- **Os reinos rivais:** aparecem nos títulos das fases (as quatro torres de Aldrasq, a fronteira do Ducado de Kermith).
- **O Império das Formas Irregulares:** antagonista final, com territórios sem padrão no Cenário V.

## 10. Mundo e level design ✅

O continente de Geometria tem 5 cenários e 20 fases. Cada cenário tem paleta própria (véu de cor sobre o mapa) e forma de reino própria.

| Fase | Título | Terreno |
|---|---|---|
| 1 | Os primeiros marcos | Planície |
| 2 | As quatro torres de Aldrasq | Planície |
| 3 | Fronteira do Ducado de Kermith | Planície |
| 4 | Senhor das Planícies | Planície |
| 5 | Névoa nos vales | Planície |
| 6 | Fortalezas no penhasco | Serra |
| 7 | Pontes de pedra | Planície / Serra |
| 8 | O passo de Kheldorn | Serra |
| 9 | Entre as árvores | Planície / Serra |
| 10 | Sem a Cartógrafa | Planície / Serra |
| 11 | Reinos em L | Serra / Planície |
| 12 | O coração da Serra | Serra |
| 13 | Pontes de cristal | Costeiro |
| 14 | Maré alta | Costeiro |
| 15 | Ilhas à deriva | Costeiro / Planície |
| 16 | O farol do Oblívio | Costeiro / Planície |
| 17 | Ruínas do Abismo | Os três |
| 18 | Polígonos sem nome | Os três |
| 19 | Às portas do Império | Serra / Costeiro |
| 20 | **Morte Súbita** | Os três (primeira derrota encerra a fase) |

Quando há mais de um terreno, ele é sorteado **a cada rodada** e aparece no HUD antes da decisão. O sorteio define o contexto, nunca o resultado.

Cada fase abre com um **cartão de abertura**: cenário, título, descrição, terreno, tempo por rodada, grid de referência, presença da Cartógrafa, objetivo e critérios de estrela.

⬜ **Castelos com silhueta por reino** e a evolução arquitetônica do castelo do jogador continuam planejados.

## 11. Narrativa ✅

**Prólogo** (exibido na primeira vez que o jogador entra no Modo História e disponível no botão "Prólogo"):

> No continente de Geometria, a força de um reino nunca foi medida por exércitos, mas pela extensão de suas terras. Durante séculos, as Leis da Forma mantiveram a paz: toda disputa era resolvida comparando áreas. O equilíbrio se rompeu quando o Império das Formas Irregulares começou a engolir os reinos vizinhos, com territórios deformados de propósito para que ninguém conseguisse calcular sua força. Você é o Arquiteto-Rei, herdeiro de um pequeno reino retangular nas Planícies de Aldrath. Guiado pela Cartógrafa, atravesse os cinco cenários do continente e prove que a área de um território é a sua maior arma.

**Despedida da Cartógrafa** (Fase 10): "Daqui em diante... você segue sem mim. Confie no que aprendeu a ver."

**Epílogo** (ao vencer a Fase 20): o Império recua e as Leis da Forma voltam ao continente.

A linha do tempo da campanha segue os cenários I a V da seção 8. O arco do jogador vai da inexperiência (retângulos com ajuda) à autonomia (formas sem padrão, sem ajuda e com pouco tempo).

## 12. Interface (UI) ✅

| Tela | Conteúdo na v0.3.0 |
|---|---|
| **Menu principal** | Jogar, Tutorial, Opções, Créditos e Sair. Fundo animado, dificuldade e recorde. Na primeira vez, o jogo oferece o tutorial. |
| **Escolha de modo** | Ao clicar em Jogar: Modo História, Campanha Clássica ou Voltar. |
| **Mapa da história** | 5 colunas de cenário com 4 fases cada, estrelas por fase, total de estrelas (de 60), botões Prólogo e Voltar ao menu. |
| **Cartão de fase** | Cenário, título, regras da fase e botão Começar. |
| **HUD de batalha** | Em cima: área total, barra de Domínio com meta de 70%, 10 marcadores de rodada e mundo/fase/terreno. Embaixo: modificador de terreno, sequência, tempo, forças de ataque e defesa, pontos, os três botões de ação e o painel de arquétipo. Faixa da Cartógrafa acima do mapa. |
| **Resultado da rodada** | Título (Vitória / Derrota / Recuo / Tempo esgotado), explicação, áreas e diferença, botão Próxima rodada. |
| **Pausa** (Esc ou P) | Continuar, Reiniciar, Ver tutorial, Menu principal e volumes. O relógio para de verdade. |
| **Fim de fase** | Vitórias, derrotas e recuos, Domínio final, pontuação, estrelas e próxima fase. |
| **Opções** | Volume de música e de efeitos, tela cheia e dificuldade. |
| **Créditos** | Equipe, nome da equipe, motor e fontes. |

**Controles:** A / D / R (ações) · Enter ou Espaço (próxima rodada) · Esc ou P (pausa) · F11 (tela cheia) · setas e Enter (menus) · mouse em tudo.

> **Mudança em relação ao GDD 1.0:** os itens "Selecionar Arquétipo", "Recursos" e "XP" do wireframe ficam para a versão com arquétipos ativos.

## 13. Direção de arte ✅

Cartografia medieval iluminada com leitura de estratégia moderna: bordas douradas, painéis escuros, mapa em pixel art com relevo e tipografia serifada.

- **Tipografia:** Cinzel (títulos), Libre Baskerville (textos narrativos) e Source Sans 3 (números e HUD).
- **Cores:** azul para o jogador, vermelho para o inimigo e dourado para a interface. Cada cenário tem um véu de cor (amanhecer quente no I, névoa azulada no II, verde-escuro no III, azul e roxo no IV, chumbo no V).
- **Brasão** do reino do jogador no HUD e no menu.

## 14. Animações ✅

Todas são procedurais (tweens e desenho por código), sem sprite sheets.

| Animação | Objeto | Descrição | Duração |
|---|---|---|---|
| Queda do VS | Ícone VS | Cai do topo ao centro no início da rodada e some | 1,0 s |
| Revelação do inimigo | Malha | A malha surge sobre o território vermelho após a resolução | Instantânea |
| Brilho e faíscas | Overlay | Tela verde com faíscas girando (vitória) | 1,0 s |
| Marcação de erro | Overlay | Tela avermelhada com "X" pulsando (derrota) | 1,0 s |
| Rajada de vento | Overlay | Traços brancos da esquerda para a direita (recuo) | 1,0 s |
| Hover e clique | Botões | Clareiam no hover e "afundam" no clique | 0,15 s |
| Alerta de tempo | Relógio | Fica vermelho com 10 s ou menos | Contínuo |
| Transição de tela | Telas | Escurecimento suave entre menu, mapa e batalha | 0,35 s |

## 15. Áudio ✅

Controlado pelo autoload `AudioManager`, com barramentos separados de música e efeitos.

- **Música:** `background.mp3` (menu e rodadas), `resumo_vitoria.mp3` (fim de fase com ≥ 70%) e `resumo_derrota.mp3` (fase fracassada).
- **Efeitos:** `atacar`, `defender`, `recuar`, `hover`, `click`, `tempo_esgotando` (a cada segundo nos últimos 10), `brilho_da_vitoria`, `derrota`, `inicio_da_rodada` e `vento`.

## 16. Inteligência artificial ✅

Não há inimigo que reage em tempo real. O desafio vem da estimativa.

- **Geração dos reinos:** procedural, com a forma do cenário (retângulo, recorte, L, degrau ou orgânica) e uma diferença de tamanho controlada pela dificuldade, pelo cenário e pela rodada. O gerador garante que nunca haja empate efetivo depois do terreno.
- **FSM da Cartógrafa** (fixa por fase, não depende do desempenho):

| Estado | Fases | Comportamento |
|---|---|---|
| Presente · ativa | 1–6 | Dica antes de cada rodada e comentário sobre o resultado |
| Presente · silenciosa | 7–9 | Só comenta derrotas |
| Despedida | 10 | Mensagem de despedida no cartão da fase |
| Ausente | 10–20 | Nenhuma dica |

- ⬜ **FSM visual do reino inimigo** (Estável, Em Alerta, Vulnerável, Conquistado) continua planejada.

## 17. Exemplo de jogo (v0.3.0)

**Fase 6 · Vales de Kheldorn · terreno Serra.**

1. **Observação:** o HUD mostra a área do jogador (31), Domínio 20% e rodada 3/10. O painel mostra "Serra ×1,47". O inimigo tem quinas recortadas e só uma célula de grid ao redor.
2. **Estimativa:** o jogador conta a largura e a altura do bloco principal, desconta as quinas e estima uns 24 quadrados.
3. **Decisão:** 24 × 1,47 ≈ 35, que é mais que 31. Mesmo parecendo menor, o inimigo resiste. O jogador **defende**.
4. **Resolução:** vitória, +10% de Domínio e a área cresce 5%.
5. **Revelação:** a malha mostra 23 quadrados. A mensagem fecha a conta: "Inimigo: 23 × Serra (1,47) = 34". O jogador confirma o raciocínio e passa a levar o terreno em conta.

**O aprendizado oculto:** sem nenhuma instrução, o jogador usou largura × altura, decomposição e raciocínio proporcional para tomar uma decisão de guerra.

## 18. Tema e aspecto sério

**Tema:** geometria plana aplicada à estimativa e à comparação de áreas, com raciocínio proporcional nos terrenos.

**Como aparece no jogo:** a geometria nunca é nomeada. Calcular área é ter poder militar; errar é perder território. A progressão vai de retângulos (largura × altura), passa por quinas recortadas (estimativa parcial) e formas em L (decomposição e soma) e chega a bordas em degrau e formas sem padrão (estimativa sob pressão de tempo).

**Fechamento do ciclo de aprendizagem:** a revelação pós-combate mostra a área real e a conta com o terreno, e a próxima situação parecida é estimada com mais precisão.

**Relação com a literatura:** o design segue princípios de aprendizagem baseada em jogos (Gee, 2003), com contexto significativo, consequência das ações e feedback imediato. A retirada gradual da ajuda (grid e Cartógrafa) respeita a teoria da carga cognitiva (Sweller, 1988), introduzindo complexidade quando a habilidade anterior já foi praticada.

## 19. Ajustes da versão 0.3.0 (ficha técnica e feedback do professor)

Os ajustes abaixo foram feitos a partir da ficha técnica preenchida pela outra equipe e do feedback do professor, e aparecem no vídeo de apresentação com o antes (v0.2.1) e o depois (v0.3.0).

| # | Antes (v0.2.1) | Depois (v0.3.0) | Origem |
|---|---|---|---|
| 1 | "Jogar" ia direto para uma partida; a história do GDD não aparecia no jogo. | "Jogar" abre a escolha entre **Modo História** e **Campanha Clássica**. O Modo História tem prólogo, mapa com 5 cenários e 20 fases, cartões de fase e epílogo. | Ficha técnica / feedback |
| 2 | O "Modificador de terreno" ficava sempre em "Nenhum" e as forças em 1,0×. | Os terrenos **Serra** (×1,47) e **Costeiro** (×0,82) mudam de verdade o cálculo, e a conta aparece no resultado. | Ficha técnica / feedback |
| 3 | Todos os reinos eram manchas aleatórias e o grid ao redor do inimigo era sempre completo. | **Formas por cenário** (retângulo → recorte → L → degrau → sem padrão) e **grid de referência que vai sumindo** (completo → 1 célula → nenhum), criando a curva de dificuldade do GDD. Tempo de 45 s e 30 s nos cenários finais e Morte Súbita na Fase 20. | Ficha técnica / feedback |
| 4 | Sem nenhuma ajuda durante a partida. | **A Cartógrafa** dá dicas nas fases 1–6, só comenta derrotas nas 7–9 e se despede na 10. | Iniciativa da equipe |
| 5 | Sem objetivo além do recorde. | **Estrelas por fase** (1 a 3), fases liberadas em sequência e progresso salvo. | Complemento do Modo História |

**O que foi mantido sem mudanças**, a pedido da equipe: menu principal, Opções, Tutorial e as regras da Campanha Clássica.

### Ajustes de versões anteriores (v0.2.x)

- Menu principal, tutorial interativo em 8 passos, Opções com três dificuldades, pausa e créditos.
- Atalhos A / D / R funcionando (antes os botões mostravam outras teclas e nenhum script lia o teclado).
- Mensagem própria de "Tempo esgotado".
- Balanceamento: área do jogador entre 10 e 90 células e diferença entre os reinos diminuindo ao longo da fase.

### Próximos passos

1. Ativar os três arquétipos e a tela de seleção antes da fase.
2. Índice de Precisão das Estimativas e estrelas baseadas nele.
3. Castelos com silhueta por reino e evolução do castelo do jogador.
4. Estados visuais dos reinos inimigos.
5. Aplicação piloto com estudantes e ajuste da curva de dificuldade pelos dados coletados.

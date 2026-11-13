# KARTHA

Projeto de jogo de cartas criado no GameMaker (metadados da IDE: 2026.0.0.16).

## Como abrir e executar

1. Abra `KARTHA.yyp` no GameMaker 2026 ou versão compatível.
2. Aguarde a IDE importar os recursos e pressione **Run**.
3. A sala inicial configurada é `rm_menu`; a partida é carregada em `rm_jogo`.

## Organização do projeto

- `objects/` — comportamento e eventos do jogo.
- `scripts/` — dados e funções reutilizáveis, incluindo o sistema de tween.
- `sprites/`, `sounds/` e `fonts/` — recursos visuais e de áudio.
- `rooms/` — telas/cenas do menu e do jogo.
- `datafiles/livro_regras.json` — conteúdo do livro de regras exibido no jogo.
- `options/` — configurações de exportação por plataforma.

## Controle de versão

Os arquivos-fonte do GameMaker, recursos e dados devem ser versionados. A raiz inclui
um `.gitignore` para excluir apenas cache, saída local de build e pacotes exportados
que podem ser gerados novamente.

## Verificação rápida

Antes de enviar alterações, abra o projeto no GameMaker e execute uma partida pelo
menos até a tela `rm_jogo`. O projeto não contém um compilador GameMaker nesta pasta;
por isso essa execução precisa ser feita pela IDE instalada localmente.

## Cenários locais de teste

Com DEBUG_COMBATE ativo, pressione **F6** durante seu turno numa partida contra IA
ou local. Escolha um dos cinco cenários: cartas/recursos para custos e alvos,
uma tropa com três condições, duas tropas equipadas, esvaziar o baralho com
cópia temporária ou restaurá-lo. A preparação preserva os limites do turno.
Os cenários de tropas precisam de colunas livres; não removem tropas existentes.
O baralho salvo no editor de decks não é alterado. Os cenários não funcionam online.

Inspecione uma carta da mão com o botão direito para ver o custo e a disponibilidade.
Durante o arrasto, uma dica junto ao cursor mostra o custo e eventuais bloqueios.
Selos de condição usam duas letras e a duração restante; um traço indica duração
sem prazo fixo. A prévia lista todos os nomes e durações. O histórico guarda até
80 registros, com páginas navegáveis pela roda do mouse sobre o painel aberto.

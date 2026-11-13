# Laboratório e efeitos

Abra com F7 numa partida offline, sem rolagens ou escolhas pendentes. A partida fica preservada em sua sala; ESC ou F7 retorna à pausa. O laboratório é uma prévia de apresentação, não um teste das regras das habilidades.

- 1–8 ou clique: impacto, magia, criaturas, contra-ataque, final, equipamento, habilidades e sons.
- Espaço: repetir. P: pausar a prévia. R: repetição automática.
- Setas: escolher habilidade ou categoria de som nas respectivas abas.

Na partida, o histórico destaca as tropas ainda presentes ao passar o mouse sobre uma ação. Ataques e contra-ataques guardam referências das tropas; mensagens antigas que só têm nomes associam as tropas presentes com esses nomes.

Efeitos: marcas temporárias (máximo 24), movimento discreto de Mimic/Slime/voadores, antecipação do contra-ataque e quebra do castelo antes do resultado. Alterações cosméticas não mudam os valores dos dados.

Validação: testes automatizados e compilação GameMaker. A aparência, o retorno da sala persistente e a mixagem devem ser conferidos numa execução interativa.

## Sincronização do F7

Habilidades, rastros e pulso no alvo, Bola de Fogo e encaixe dos equipamentos usam funções de desenho/movimento compartilhadas com a partida. Na aba 2 (Magia), use as setas para selecionar o efeito; na aba 7, escolha a habilidade. O laboratório continua sem executar regras de dano ou condições.

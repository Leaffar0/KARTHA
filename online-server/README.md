# Servidor online do KARTHA

Servidor Colyseus para salas privadas de dois jogadores.

## Rodar no computador

1. Entre nesta pasta: `cd online-server`
2. Instale as dependências: `pnpm install`
3. Inicie: `pnpm dev`
4. Confira `http://localhost:2567/health`

No menu **ONLINE (BETA)** do jogo, use `ws://localhost:2567` quando os dois
clientes estiverem no mesmo computador. Em rede local, troque `localhost`
pelo IP do computador que está executando o servidor.

## Colocar na internet

Hospede esta pasta em um serviço Node.js, exponha a porta definida por
`PORT` e use um domínio com TLS. No jogo, informe o endereço
`wss://seu-dominio`. O servidor não precisa de contas para esta primeira
versão: quem cria compartilha o código da sala com a outra pessoa.

## O que já é autoritativo

- criação e entrada numa sala privada de duas pessoas;
- atribuição dos jogadores 1 e 2;
- d20 de iniciativa gerado no servidor;
- escolha de quem começa feita apenas pelo vencedor;
- validação de jogador ativo e revisão das ações;
- troca de turno confirmada para os dois clientes;
- concessão e janela de 20 segundos para reconexão.

## Protocolo

Mensagens do cliente: `ready`, `roll_initiative`, `choose_first`,
`action` e `concede`.

Mensagens do servidor: `seat`, `initiative_result`, `initiative_tie`,
`match_started`, `action_confirmed` e `action_rejected`.

A infraestrutura e a abertura da partida estão funcionais. A sincronização
autoritativa de cada carta, alvo, dado e efeito do tabuleiro ainda deve ser
migrada para o servidor antes de chamar o modo online de versão final.

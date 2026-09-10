# Servidor online do KARTHA

Servidor Colyseus para salas privadas de dois jogadores.

## Rodar no computador

1. Entre nesta pasta: `cd online-server`
2. Instale as dependências: `npm install`
3. Inicie: `npm run dev`
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

- salas privadas, nomes, reconexão, iniciativa, escolha de quem começa e revanche;
- mãos e baralhos privados, compra, descarte, recursos e custos;
- tropas, construções, terrenos, itens, armadilhas, bênçãos e maldições;
- movimento, combate, D20, críticos, Golpe Duplo, condições e habilidades cadastradas;
- resultados de dados e moedas gerados e validados pelo servidor;
- sincronização da perspectiva de cada jogador e respostas visuais das ações.

## Protocolo

Além da preparação da partida, as jogadas usam `action`, sempre acompanhadas
da revisão atual. O servidor responde com `action_confirmed` ou
`action_rejected` e envia estados público e privado separados.

## Limites atuais

O servidor precisa permanecer ligado e acessível por um endereço `wss://`.
Cartas futuras só entram no online depois que seus atributos e efeitos forem
cadastrados no servidor. Balanceamento e testes prolongados ainda dependem de
partidas reais entre dois jogadores.

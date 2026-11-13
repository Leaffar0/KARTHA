# Sons integrados

Foram importados 29 arquivos dos novos pacotes. Os originais foram preservados. Papel, tecido, madeira, metal e impactos foram priorizados; os sons mágicos numerados têm uma associação inicial que pode ser refinada ouvindo no jogo.

## Testar

Durante uma partida local, pressione F7 e escolha a aba Sons (tecla 8).

- Esquerda/direita: categoria.
- Cima/baixo: arquivo da categoria; o nome aparece na tela.
- Espaço: ouvir novamente o mesmo arquivo.
- R: ativar/desativar repetição automática.
- ESC ou F7: voltar à partida pausada.

As abas Magia e Habilidade permitem conferir o som junto da apresentação visual. O volume segue a configuração de efeitos do jogo.

## Distribuição

- Interface: cliques, ajustes e aviso de ação recusada.
- Livros/papel: abrir e fechar painéis e virar páginas do histórico.
- Impactos: dano corporal, defesa com escudo, golpes críticos e gelo.
- Lâminas/tecido/madeira: Golpe Duplo, Ferida Exposta, Sombra Translúcida e Imitação.
- Magia: os sete arquivos ficam disponíveis na categoria magia_arcana; alguns também foram associados a veneno, choque, cura, escudo e Visão do Véu.
- Os sons anteriores de bola de fogo, cartas, dados e outros efeitos foram preservados.

## Ajustar

Em scripts/scr_apresentacao/scr_apresentacao.gml, catalogo_sons_jogo define as variações, volume_grupo_som define os volumes padrão e grupo_som_magia associa os efeitos aos grupos. Alguns eventos usam volume próprio.

catalogo_novos.json registra a origem de cada arquivo. importar.cjs reproduz a importação usando o FFmpeg do runtime instalado. Os WAV foram preparados com ajuste limitado de ganho e pequenas suavizações nas extremidades; os cliques OGG foram preservados no formato original devido a uma limitação desse conversor.

Compilação e testes automatizados não substituem a avaliação auditiva no jogo.

## Complemento: criaturas e magia sombria

Mais 12 arquivos foram integrados, com origens e ganhos em catalogo_criaturas.json; importar_criaturas.cjs reproduz essa importação. A cópia idêntica de dark-magic com sufixo (1) não foi importada novamente. Os originais continuam preservados.

- Imitação: alterna os dois wooden-trunk-latch. Os rangidos anteriores continuam disponíveis no F7 em madeira_rangido.
- Slime, Slimet e Slime Digestão: slime_ataque ao causar dano físico; slime_dano quando recebem dano.
- Esqueleto: alterna os dois sons de ossos nos impactos.
- Lobo, Lobo Alfa, Urso e Mimic: mordida ao causar dano físico.
- Raio: duas variações em magia_choque; gelo: duas variações em gelo.
- Magia genérica ofensiva, veneno e Visão do Véu: magia sombria. As opções antigas continuam em magia_antiga para comparação.

Os sons corporais só disparam com dano positivo, inclusive em golpes letais. Bloqueio total mantém o som de defesa. As associações por criatura não alteram dano, condições ou outras regras. Os sons novos estão em F7 → Sons; a repetição automática espera o arquivo terminar.

## Prévia de combate e volumes

F7 → Combate (1): esquerda/direita escolhem o atacante; cima/baixo escolhem o alvo. B alterna bloqueio, C alterna crítico e M alterna físico/mágico. Espaço repete, P pausa animação e áudio, R alterna repetição. A prévia é uma apresentação controlada, não uma simulação de rolagens ou de dano real; não modifica a partida guardada. Os sons de criatura usam a mesma função dos impactos da partida.

Nas opções do menu e da pausa, clique no nome do canal sonoro para alternar Geral, Interface, Combate e Magias. Use as setas laterais para ajustar. Geral multiplica os outros três canais; música continua independente. Os valores são salvos em kartha_config.ini. Configurações antigas recebem os canais novos em 100%, preservando o volume anterior.

Ataques mágicos de tropas têm conjuração na antecipação e impacto curto no contato, evitando repetir a conjuração completa. A prévia também separa essas etapas. Bola de fogo mantém seus sons próprios de voo e impacto.

Validação automatizada: habilidades, condições simultâneas, equipamentos, posicionamento, limites de volume, persistência das configurações, disparo único no contato e pausa/limpeza dos áudios. Avaliação auditiva e visual em uma partida real permanece pendente. A checagem TypeScript completa do servidor não foi executada por ausência das dependências locais; os testes existentes executáveis com Node passaram.

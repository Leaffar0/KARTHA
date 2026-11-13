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

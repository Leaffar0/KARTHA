#region Conteúdo e navegação
paginas = paginar_livro_regras(carregar_livro_regras(), 520);
pagina_atual = 0;

// Sumário: 1 entrada por capítulo (parte == 1 marca onde ele começa em "paginas")
sumario = [];
for (var i = 0; i < array_length(paginas); i++) {
    if (paginas[i].parte == 1) {
        array_push(sumario, { titulo: paginas[i].titulo, indice_pagina: i });
    }
}
mostrando_sumario = true;
sumario_hover_index = -1;

virando = false;
flip_progresso = 0;
direcao_flip = 1;
trocou_pagina = false;
flip_velocidade = 0.04;
#endregion

#region Estado de interação e dimensões
arrastando = false;
preview_ativo = false;

// tamanho do livro FECHADO, como aparece solto pela room
livro_escala = 0.1;
livro_largura = 90 * livro_escala;
livro_altura = 128 * livro_escala;
livro_escala_atual = livro_escala;
livro_bob = 0;

// tamanho do livro ABERTO, só dentro do preview
preview_largura = min(760, display_get_gui_width() - 80);
preview_altura = min(540, display_get_gui_height() - 140);

sprite_index = spr_livro_fechado;
image_xscale = livro_escala;
image_yscale = livro_escala;
#endregion

#region Funções locais de navegação
function iniciar_flip(_direcao) {
    if (virando) return;
    if (mostrando_sumario) return;

    var _novo_index = pagina_atual + (_direcao * 2); // agora move de 2 em 2 (um par de páginas)
    if (_novo_index < 0 || _novo_index >= array_length(paginas)) return;

    virando = true;
    flip_progresso = 0;
    trocou_pagina = false;
    direcao_flip = _direcao;
}

// Clique num item do sumário: pula direto pra página do capítulo escolhido.
function abrir_pagina_do_sumario(_indice_pagina) {
    var _indice_alinhado = _indice_pagina - (_indice_pagina mod 2); // mantém a paginação em pares
    pagina_atual = clamp(_indice_alinhado, 0, max(0, array_length(paginas) - 1));
    mostrando_sumario = false;
    virando = false;
    flip_progresso = 0;
    trocou_pagina = false;
}
#endregion
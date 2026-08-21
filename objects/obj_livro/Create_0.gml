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
    if (mostrando_sumario) return;

    var _novo_index = pagina_atual + (_direcao * 2);
    if (_novo_index < 0 || _novo_index >= array_length(paginas)) return;

    pagina_atual = _novo_index;
}

// Clique num item do sumário: pula direto pra página do capítulo escolhido.
function abrir_pagina_do_sumario(_indice_pagina) {
    var _indice_alinhado = _indice_pagina - (_indice_pagina mod 2);
    pagina_atual = clamp(_indice_alinhado, 0, max(0, array_length(paginas) - 1));
    mostrando_sumario = false;
}
#endregion

#region Conteúdo e navegação
paginas = paginar_livro_regras(carregar_livro_regras(), 520);
pagina_atual = 0;

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

#region Função local de virada de página
function iniciar_flip(_direcao) {
    if (virando) return;
    var _novo_index = pagina_atual + _direcao;
    if (_novo_index < 0 || _novo_index >= array_length(paginas)) return;

    virando = true;
    flip_progresso = 0;
    trocou_pagina = false;
    direcao_flip = _direcao;
}
#endregion

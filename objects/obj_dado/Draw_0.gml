gpu_set_texfilter(false);
// Garante que o sprite continue sendo renderizado normalmente durante todo o voo.
draw_set_alpha(1);
draw_set_color(c_white);

if (image_alpha > 0) {
    desenhar_sombra_mesa(x, y + altura_voo + sprite_get_height(sprite_index) * escala_base_dado * 0.34,
        sprite_get_width(sprite_index) * escala_base_dado, altura_voo / max(1, altura_maxima_dado), image_alpha);
}
if (tamanho_dado == 20) {
    gpu_set_texfilter(true);
    var _face_d20 = interativo_iniciativa ? 0 : d20_face_visual(valor_final,girando,tempo_girando);
    desenhar_d20_visual(x,y,image_xscale,image_yscale,image_angle,_face_d20,image_alpha);
} else if (tamanho_dado == 4) {
    gpu_set_texfilter(true);
    desenhar_d4_visual(x,y,image_xscale,image_yscale,image_angle,
        d4_face_visual(valor_final,girando,tempo_girando),image_alpha);
} else if (tamanho_dado == 6) {
    gpu_set_texfilter(true);
    desenhar_d6_visual(x,y,image_xscale,image_yscale,image_angle,
        d6_face_visual(valor_final,girando,tempo_girando),image_alpha);
} else if (tamanho_dado == 8) {
    gpu_set_texfilter(true);
    desenhar_d8_visual(x,y,image_xscale,image_yscale,image_angle,
        d8_face_visual(valor_final,girando,tempo_girando),image_alpha);
} else if (tamanho_dado == 10) {
    gpu_set_texfilter(true);
    desenhar_d10_visual(x,y,image_xscale,image_yscale,image_angle,
        d10_face_visual(valor_final,girando,tempo_girando),image_alpha);
} else if (tamanho_dado == 12) {
    gpu_set_texfilter(true);
    desenhar_d12_visual(x,y,image_xscale,image_yscale,image_angle,
        d12_face_visual(valor_final,girando,tempo_girando),image_alpha);
} else draw_self();

// Somente o bônus permanece fora da face; não repete o valor sorteado.
if (!girando && progresso_revelacao > 0 && !ocultar_resultado_ate_rolar
    && modificador_exibido != 0 && !is_struct(grupo_soma)) {
    var _bonus = (modificador_exibido > 0 ? "+" : "") + string(modificador_exibido) + " BÔNUS";
    desenhar_legenda_mesa(x, y + sprite_get_height(sprite_index)*abs(image_yscale)/2 + 10,
        _bonus, progresso_revelacao);
}

// Os dados de outros tamanhos usam o corpo D6: substitui os pontos por seu
// valor real na própria face ao pousar (um D8 não pode parecer um D2).
if (tamanho_dado != 20 && tamanho_dado != 4 && tamanho_dado != 6 && tamanho_dado != 8 && tamanho_dado != 10 && tamanho_dado != 12 && !girando && !ocultar_resultado_ate_rolar) {
    var _fw = sprite_get_width(sprite_index)*abs(image_xscale)*0.82;
    var _fh = sprite_get_height(sprite_index)*abs(image_yscale)*0.82;
    var _font = draw_get_font(), _ha = draw_get_halign(), _va = draw_get_valign();
    draw_set_alpha(image_alpha); draw_set_color(make_color_rgb(220,220,216));
    draw_rectangle(x-_fw/2,y-_fh/2,x+_fw/2,y+_fh/2,false);
    draw_set_font(Fontenil); draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(22,22,22));
    var _numero = string(valor_final);
    var _esc = min(_fw*0.65/max(1,string_width(_numero)),_fh*0.65/max(1,string_height(_numero)));
    draw_text_transformed(x,y,_numero,_esc,_esc,0);
    draw_set_font(_font); draw_set_halign(_ha); draw_set_valign(_va);
    draw_set_alpha(1); draw_set_color(c_white);
}

// Quando todos os dados do grupo pousam, um deles desenha a soma uma única vez.
if (grupo_soma_responsavel && is_struct(grupo_soma)
    && grupo_soma.pousados >= grupo_soma.quantidade && !grupo_soma.aguarda_resultado_final) {
    var _texto_soma = "";
    for (var _i_soma = 0; _i_soma < array_length(grupo_soma.resultados); _i_soma++) {
        if (_i_soma > 0) _texto_soma += " + ";
        _texto_soma += string(grupo_soma.resultados[_i_soma]);
    }
    if (grupo_soma.modificador != 0) {
        _texto_soma += (grupo_soma.modificador > 0 ? " + " : " - ") + string(abs(grupo_soma.modificador));
    }
    _texto_soma += " = " + string(grupo_soma.total_visual + grupo_soma.modificador);

    var _soma_y = grupo_soma.destino_y + (sprite_height * escala_base_dado / 2) + 38;
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_black);
    draw_text(grupo_soma.destino_x - 1, _soma_y - 1, _texto_soma);
    draw_text(grupo_soma.destino_x + 1, _soma_y - 1, _texto_soma);
    draw_text(grupo_soma.destino_x - 1, _soma_y + 1, _texto_soma);
    draw_text(grupo_soma.destino_x + 1, _soma_y + 1, _texto_soma);
    draw_set_color(c_yellow);
    draw_text(grupo_soma.destino_x, _soma_y, _texto_soma);
    draw_set_color(c_white);
}
if (interativo_iniciativa) {
    var _meia_altura = sprite_get_height(sprite_index)*abs(image_yscale)/2;
    desenhar_legenda_mesa(x,y-_meia_altura-34,"DISPUTA · D20",1);
    var _instrucao = iniciativa_arrastando ? "MOVA E SOLTE PARA ROLAR" : "SEGURE E ARRASTE O DADO";
    desenhar_legenda_mesa(x,y+_meia_altura+10,_instrucao,1);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
gpu_set_texfilter(true);
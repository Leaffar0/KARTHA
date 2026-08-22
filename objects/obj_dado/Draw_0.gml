gpu_set_texfilter(false);
// Garante que o sprite continue sendo renderizado normalmente durante todo o voo.
draw_set_alpha(1);
draw_set_color(c_white);

draw_self();

// Não entrega nenhuma informação durante o voo: o resultado surge só após o impacto.
if (!girando && progresso_revelacao > 0) {
    draw_set_alpha(progresso_revelacao);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    var _texto_resultado = "D" + string(tamanho_dado) + ": " + string(valor_final);
    if (modificador_exibido != 0) {
        var _sinal = (modificador_exibido > 0) ? "+" : "";
        _texto_resultado += " " + _sinal + string(modificador_exibido) + " = " + string(valor_final + modificador_exibido);
    }

    var _texto_x = x;
    var _texto_y = y + (sprite_height * image_yscale / 2) + 10;

    // Borda preta: desenha o texto deslocado em 8 direções ao redor
    draw_set_color(c_black);
    draw_text(_texto_x - 1, _texto_y - 1, _texto_resultado);
    draw_text(_texto_x,     _texto_y - 1, _texto_resultado);
    draw_text(_texto_x + 1, _texto_y - 1, _texto_resultado);
    draw_text(_texto_x - 1, _texto_y,     _texto_resultado);
    draw_text(_texto_x + 1, _texto_y,     _texto_resultado);
    draw_text(_texto_x - 1, _texto_y + 1, _texto_resultado);
    draw_text(_texto_x,     _texto_y + 1, _texto_resultado);
    draw_text(_texto_x + 1, _texto_y + 1, _texto_resultado);

    // Texto branco por cima
    draw_set_color(c_white);
    draw_text(_texto_x, _texto_y, _texto_resultado);

    draw_set_alpha(1);
    draw_set_color(c_white); // reseta pro padrão, pra não vazar cor pra outros desenhos
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
gpu_set_texfilter(true);
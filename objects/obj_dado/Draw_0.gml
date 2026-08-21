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
    draw_text(x, y + (sprite_height * image_yscale / 2) + 10, "D" + string(tamanho_dado) + ": " + string(valor_final));
    draw_set_alpha(1);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
gpu_set_texfilter(true);
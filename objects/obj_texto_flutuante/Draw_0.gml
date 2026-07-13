var _progresso = vida_texto / vida_texto_max;
var _alpha = 1;

// fade in rápido (primeiros 15%) e fade out no final (últimos 40%)
if (_progresso < 0.15) {
    _alpha = _progresso / 0.15;
} else if (_progresso > 0.6) {
    _alpha = 1 - ((_progresso - 0.6) / 0.4);
}

draw_set_alpha(_alpha);
draw_set_color(cor_texto);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(x, y, texto);
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
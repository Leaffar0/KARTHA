var _gui_x = x;
var _gui_y = y;
var _camera = view_camera[0];
if (_camera != -1) {
    _gui_x = (x - camera_get_view_x(_camera)) * display_get_gui_width() / camera_get_view_width(_camera);
    _gui_y = (y - camera_get_view_y(_camera)) * display_get_gui_height() / camera_get_view_height(_camera);
}

var _progresso = vida_texto / vida_texto_max;
var _alpha = 1;
if (_progresso < 0.15) _alpha = _progresso / 0.15;
else if (_progresso > 0.6) _alpha = 1 - ((_progresso - 0.6) / 0.4);

// Pulso curto na entrada melhora a leitura sem aumentar demais o texto.
var _escala = 1 + sin(clamp(_progresso / 0.22, 0, 1) * pi) * 0.12;
draw_set_font(Fontenil);
draw_set_alpha(clamp(_alpha, 0, 1));
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_black);
draw_text_transformed(_gui_x + 2, _gui_y + 2, texto, _escala, _escala, 0);
draw_set_color(cor_texto);
draw_text_transformed(_gui_x, _gui_y, texto, _escala, _escala, 0);
draw_set_font(-1);
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

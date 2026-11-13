var _gui_x = x;
var _gui_y = y;
var _camera = view_camera[0];
if (view_enabled && view_visible[0] && _camera != -1) {
    _gui_x = (x - camera_get_view_x(_camera)) * display_get_gui_width() / camera_get_view_width(_camera);
    _gui_y = (y - camera_get_view_y(_camera)) * display_get_gui_height() / camera_get_view_height(_camera);
}

var _progresso = vida_texto / vida_texto_max;
var _alpha = 1;
if (_progresso < 0.12) _alpha = 1 - sqr(1 - _progresso / 0.12);
else if (_progresso > 0.67) {
    var _saida = clamp((_progresso - 0.67) / 0.33, 0, 1);
    _alpha = 1 - _saida * _saida * (3 - 2 * _saida);
}

// Pulso curto na entrada melhora a leitura sem aumentar demais o texto.
var _entrada = clamp(_progresso / 0.22, 0, 1);
var _escala = 1 - 0.10 * sqr(1 - _entrada) + sin(_entrada * pi) * 0.08;
draw_set_font(Fontenil);

// A câmera acompanha o mouse. Ao devolver a carta para a mão, a posição
// original do aviso pode sair da view; mantenha a mensagem inteira na GUI.
var _margem = 12;
var _largura_gui = display_get_gui_width();
var _altura_gui = display_get_gui_height();
var _largura_texto = max(1, string_width(texto));
_escala = min(_escala, max(1, _largura_gui - _margem * 2) / _largura_texto);
var _meia_largura = _largura_texto * _escala * 0.5;
var _meia_altura = string_height(texto) * _escala * 0.5;
_gui_x = clamp(_gui_x, _margem + _meia_largura, max(_margem + _meia_largura, _largura_gui - _margem - _meia_largura));
_gui_y = clamp(_gui_y, _margem + _meia_altura, max(_margem + _meia_altura, _altura_gui - _margem - _meia_altura));
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

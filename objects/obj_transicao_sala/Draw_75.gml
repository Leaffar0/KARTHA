var _cor = draw_get_color(), _alpha = draw_get_alpha();
draw_set_color(c_black);
draw_set_alpha(opacidade);
draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
// Um pequeno maço ritual: recolhe ao fechar e abre ao revelar a sala.
var _vis = clamp((opacidade - 0.25) / 0.75, 0, 1);
_vis = _vis * _vis * (3 - 2 * _vis);
if (_vis > 0) {
    var _gw = display_get_gui_width(), _gh = display_get_gui_height();
    var _w = clamp(_gw * 0.075, 38, 86), _h = _w * 1.50;
    var _abertura = 0.18 + (1 - _vis) * 0.82;
    var _cy = _gh * 0.5 + (1 - _vis) * 16;
    for (var _lado = -1; _lado <= 1; _lado += 2) {
        transicao_desenhar_carta(_gw * 0.5 + _lado * _w * 0.68 * _abertura,
            _cy + _h * 0.08, _w, _h, -_lado * (8 + 23 * _abertura), _vis, false);
    }
    transicao_desenhar_carta(_gw * 0.5, _cy - _w * 0.04,
        _w, _h, sin(tempo_visual * 2) * 2, _vis, true);
}
draw_set_alpha(_alpha);
draw_set_color(_cor);

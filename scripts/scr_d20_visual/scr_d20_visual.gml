// Zero significa face ainda sem resultado. A animação nunca sorteia a regra.
function d20_face_visual(_valor, _girando, _tempo) {
    if (_girando) return 1 + ((floor(_tempo / 4) * 7) mod 20);
    if (_valor >= 1 && _valor <= 20 && floor(_valor) == _valor) return _valor;
    return 0;
}

function desenhar_d20_visual(_x, _y, _sx, _sy, _angulo, _face, _alpha) {
    // Preserva o tamanho e a área de interação dos dados existentes (16 px base).
    draw_sprite_ext(spr_d20_corpo,0,_x,_y,
        16*_sx/sprite_get_width(spr_d20_corpo),16*_sy/sprite_get_height(spr_d20_corpo),
        _angulo,c_white,_alpha);
    if (_face == 0 || _alpha <= 0) return;
    var _fonte = draw_get_font(), _ha = draw_get_halign(), _va = draw_get_valign();
    var _cor = draw_get_color(), _a = draw_get_alpha();
    draw_set_font(Fontenil);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(18,18,18)); draw_set_alpha(_alpha);
    var _texto = string(_face);
    var _esc = min(16*abs(_sx)*0.29/max(1,string_width(_texto)),
        16*abs(_sy)*0.25/max(1,string_height(_texto)));
    draw_text_transformed(_x,_y,_texto,_esc,_esc,_angulo);
    // Marcação discreta distingue 6 e 9 quando o dado está girado.
    if (_face == 6 || _face == 9) {
        var _dist = 16*abs(_sy)*0.12;
        var _cx = _x + dsin(_angulo)*_dist;
        var _cy = _y + dcos(_angulo)*_dist;
        var _meia = 16*abs(_sx)*0.04;
        draw_line(_cx-dcos(_angulo)*_meia,_cy+dsin(_angulo)*_meia,
            _cx+dcos(_angulo)*_meia,_cy-dsin(_angulo)*_meia);
    }
    draw_set_font(_fonte); draw_set_halign(_ha); draw_set_valign(_va);
    draw_set_color(_cor); draw_set_alpha(_a);
}

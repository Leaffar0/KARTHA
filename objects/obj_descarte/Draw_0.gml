var _hover = point_in_rectangle(mouse_x, mouse_y, x, y, x + sprite_width, y + sprite_height);
var _carta_sobre_descarte = false;
for (var i = 0; i < instance_number(obj_carta); i++) {
    var _carta = instance_find(obj_carta, i);
    if (_carta.arrastando && _carta.dono == "jogador"
        && point_in_rectangle(_carta.x, _carta.y, x - 20, y - 20, x + sprite_width + 20, y + sprite_height + 20)) {
        _carta_sobre_descarte = true;
        break;
    }
}

var _ativo = _hover || _carta_sobre_descarte;
// Mantém a máscara antiga para o clique e a área de descarte.
var _cx = x + sprite_width/2;
var _cy = y + 30;
var _tamanho = 68;
var _bx = _cx - _tamanho/2;
var _by = y - 2;
// A arte já traz a sombra de contato, rente à base.
draw_set_alpha(1); draw_set_color(c_white);
draw_sprite_ext(spr_descarte_cesto, 0, _bx, _by,
    _tamanho/sprite_get_width(spr_descarte_cesto),
    _tamanho/sprite_get_height(spr_descarte_cesto), 0,
    c_white, 1);

for (var _i = 0; _i < array_length(cartas_caindo); _i++) {
    var _c = cartas_caindo[_i];
    var _voo = clamp(_c.tempo/22, 0, 1);
    var _suave = _voo*_voo*(3-2*_voo);
    var _queda = clamp((_c.tempo-22)/30, 0, 1);
    var _px = lerp(_c.x, _cx, _suave);
    var _py = lerp(_c.y, _cy, _suave) - sin(_voo*pi)*24 + _queda*7;
    var _encaixe = 28/max(1,sprite_get_width(_c.sprite));
    var _esc = lerp(_c.escala, _encaixe, _suave) * power(1-_queda, 1.5);
    var _angulo = lerp(_c.angulo, -12, _suave) + _queda*100;
    desenhar_carta_mesa(_c.sprite,0,_px,_py,_esc,_esc*(1-_queda*0.5),_angulo,
        merge_color(c_white,c_black,_queda*0.95),1-power(_queda,2));
}

draw_set_alpha(1);
draw_set_color(c_white);
// A borda frontal passa à frente da carta quando ela mergulha na abertura.
if (array_length(cartas_caindo)>0) {
    var _sw=sprite_get_width(spr_descarte_cesto), _sh=sprite_get_height(spr_descarte_cesto);
    var _corte=floor(_sh*0.69);
    draw_sprite_part_ext(spr_descarte_cesto,0,0,_corte,_sw,_sh-_corte,
        _bx,_by+_corte*_tamanho/_sh,_tamanho/_sw,_tamanho/_sh,c_white,1);
}

if (instance_exists(obj_controlador)) {
    var _total_descarte = array_length(obj_controlador.descarte_jogador);
    var _texto_legenda = _carta_sobre_descarte ? "SOLTE PARA DESCARTAR"
        : "DESCARTE · "+string(_total_descarte)+(_total_descarte==1?" carta":" cartas");
    desenhar_legenda_mesa(_cx,y+sprite_height+6,_texto_legenda,
        _carta_sobre_descarte ? 1 : legenda_alpha);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_font(-1);

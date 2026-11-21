var _pulso = 1 + 0.035 * sin(pulso_virada_timer / pulso_virada_duracao * pi);
desenhar_sombra_contato(sprite_index,image_index,x,y,escala_recurso*escala_animacao*_pulso,escala_recurso*escala_animacao*_pulso,rotacao_atual,0,alpha_animacao);
desenhar_carta_mesa(sprite_index, image_index, x, y, escala_recurso * escala_animacao * _pulso, escala_recurso * escala_animacao * _pulso, rotacao_atual, c_white, alpha_animacao);

if (quantidade > 1) {
    draw_set_halign(fa_right);
    draw_set_valign(fa_bottom);
    draw_set_color(c_white);
    draw_text_transformed(x + sprite_width * 0.28, y + sprite_height * 0.28, "×" + string(quantidade), 0.55, 0.55, 0);
}

var _texto = string_upper(tipo);
var _largura_maxima = sprite_width * 0.6;
var _largura_texto = string_width(_texto);
var _escala_texto = 0.7;

if (_largura_texto > _largura_maxima) {
    _escala_texto = _largura_maxima / _largura_texto;
}

// Cadeado compacto: acompanha o tamanho real do recurso, sem cobrir a arte.
if (bloqueio_visual_alpha > 0) {
    var _rw = sprite_get_width(sprite_index)*escala_recurso*escala_animacao*_pulso;
    var _rh = sprite_get_height(sprite_index)*escala_recurso*escala_animacao*_pulso;
    var _entrada = bloqueio_visual_entrada;
    var _salto = sin(_entrada*pi)*(1-_entrada);
    var _w = clamp(_rw*0.27,10,18)*(1+_salto*0.16);
    var _cx = x, _cy = y+_rh*0.23-(1-_entrada)*7;
    var _a = draw_get_alpha(), _cor = draw_get_color(), _f = draw_get_font();
    var _ha = draw_get_halign(), _va = draw_get_valign();
    draw_set_alpha(bloqueio_visual_alpha*alpha_animacao);
    // A haste desce para fechar; ao liberar, levanta antes de desaparecer.
    var _abertura = bloqueado_turnos>0 ? 1-_entrada : 1-bloqueio_visual_alpha;
    var _topo = _cy-_w*0.20-_abertura*_w*0.23;
    draw_set_color(make_color_rgb(38,40,42));
    draw_primitive_begin(pr_linestrip);
    for(var _i=0;_i<=16;_i++) {
        var _ang=180-_i/16*180;
        draw_vertex(_cx+dcos(_ang)*_w*0.29,_topo-dsin(_ang)*_w*0.42);
    }
    draw_primitive_end();
    draw_line(_cx-_w*0.29,_topo,_cx-_w*0.29,_cy+_w*0.08);
    draw_line(_cx+_w*0.29,_topo,_cx+_w*0.29,_cy+_w*0.08-_abertura*_w*0.20);
    draw_set_color(make_color_rgb(219,220,216));
    draw_roundrect(_cx-_w*0.5,_cy-_w*0.15,_cx+_w*0.5,_cy+_w*0.60,false);
    draw_set_color(make_color_rgb(38,40,42));
    draw_roundrect(_cx-_w*0.5,_cy-_w*0.15,_cx+_w*0.5,_cy+_w*0.60,true);
    draw_set_font(Fontenil);draw_set_halign(fa_center);draw_set_valign(fa_middle);
    var _numero=string(bloqueio_visual_turnos);
    var _esc=min(_w*0.50/max(1,string_width(_numero)),_w*0.52/max(1,string_height(_numero)));
    draw_text_transformed(_cx,_cy+_w*0.22,_numero,_esc,_esc,0);
    draw_set_alpha(_a);draw_set_color(_cor);draw_set_font(_f);
    draw_set_halign(_ha);draw_set_valign(_va);
}

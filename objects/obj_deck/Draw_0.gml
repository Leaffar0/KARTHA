#region Pilha visual de cartas
draw_set_font(Fontenil);
// A curva deixa a borda da penúltima folha visível até em uma janela pequena.
var _folhas = max(0, quantidade_cartas - 1);
var _max_visivel = min(12, quantidade_cartas);
var _espessura = min(7.5, 6 * sqrt(_folhas / 49));
var _cor_anterior = draw_get_color();
if (_max_visivel > 0) {
    desenhar_sombra_contato(sprite_index, 0, x, y, escala_pilha, escala_pilha, 0, 1, 1);
    for (var i = 0; i < _max_visivel; i++) {
        var _topo = i == _max_visivel - 1;
        var _altura = _espessura * i / max(1, _max_visivel - 1);
        var _cx = x - _altura * 0.35;
        var _cy = y - _altura + (_topo ? offset_y_bob : 0);
        var _w = sprite_width * (_topo ? escala_deck_x : 1);
        var _h = sprite_height * (_topo ? escala_deck_y : 1);
        if (_topo) {
            draw_sprite_ext(spr_verso_kartha, 0, _cx, _cy,
                _w / sprite_get_width(spr_verso_kartha), _h / sprite_get_height(spr_verso_kartha),
                0, c_white, 1);
        } else {
            // As folhas aparecem na borda inferior em duas tintas de papel.
            draw_set_color((i mod 2 == 0) ? make_color_rgb(70, 67, 62) : make_color_rgb(164, 158, 146));
            draw_roundrect_ext(_cx - _w/2, _cy - _h/2, _cx + _w/2, _cy + _h/2, 2, 2, false);
        }
    }
}
draw_set_color(_cor_anterior);
if (instance_exists(obj_controlador) && (obj_controlador.disputa_inicial_estado == "aguardando_deck" || obj_controlador.disputa_inicial_estado == "online_aguardando_mao")) {
    var _texto_compra_inicial = (obj_controlador.disputa_inicial_estado == "online_aguardando_mao")
        ? "AGUARDANDO O OUTRO JOGADOR"
        : "CLIQUE PARA COMPRAR A MÃO";
    desenhar_legenda_mesa(x,y-sprite_height/2-34,_texto_compra_inicial,1);
}
#endregion

#region Legenda ao passar o mouse
if (instance_exists(obj_controlador)
    && obj_controlador.disputa_inicial_estado != "aguardando_deck"
    && obj_controlador.disputa_inicial_estado != "online_aguardando_mao") {
    var _quantidade_contador = (obj_controlador.modo_partida == "online") ? global.online_deck_count
        : array_length(obj_controlador.monte);
    desenhar_legenda_mesa(x,y-sprite_height/2-34,
        "BARALHO · "+string(_quantidade_contador)+(_quantidade_contador==1?" carta":" cartas"),legenda_alpha);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);
#endregion

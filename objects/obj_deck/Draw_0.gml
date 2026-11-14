#region Pilha visual de cartas
draw_set_font(Fontenil);
var _max_visivel = min(quantidade_cartas, 12);
var _sx = sprite_get_width(sprite_index)*escala_pilha/sprite_get_width(spr_deck);
var _sy = sprite_get_height(sprite_index)*escala_pilha/sprite_get_height(spr_deck);
if (_max_visivel > 0) desenhar_sombra_contato(spr_deck,0,x,y,_sx,_sy,0,1,1);
for (var i = 0; i < _max_visivel; i++) {
    var _topo = i == _max_visivel-1;
    // Lâminas de papel juntas; irregularidade fixa, sem tremor em repouso.
    var _borda = _topo ? 0 : sin(i*2.4)*0.22;
    draw_sprite_ext(spr_deck,0,x-i*0.15+_borda,
        y-i*0.38+(_topo?offset_y_bob:0),
        _sx*(_topo?escala_deck_x:1),_sy*(_topo?escala_deck_y:1),0,
        _topo?c_white:make_color_rgb(155+i*4,155+i*4,155+i*4),1);
}
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
        : array_length((partida_local_ativa() && obj_controlador.turno == "inimigo")
            ? obj_controlador.monte_inimigo : obj_controlador.monte);
    desenhar_legenda_mesa(x,y-sprite_height/2-34,
        "BARALHO · "+string(_quantidade_contador)+(_quantidade_contador==1?" carta":" cartas"),legenda_alpha);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);
#endregion

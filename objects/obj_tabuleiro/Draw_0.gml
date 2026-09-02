var _largura = 1000;
var _altura = 560;

var _escala_x = _largura / sprite_get_width(sprite_index);
var _escala_y = _altura / sprite_get_height(sprite_index);

var _escala = min(_escala_x, _escala_y);

draw_sprite_ext(
    sprite_index,
    0,
    room_width / 2,
    room_height / 2,
    _escala,
    _escala,
    0,
    c_white,
    1
);

#region Espaços de efeitos ativos
// Esta instância está na camada do tabuleiro (depth 200), abaixo das cartas.
if (instance_exists(obj_controlador)) {
    var _controle_efeitos = instance_find(obj_controlador, 0);
    var _efeito_largura_slot = 42;
    var _efeito_altura_slot = 58;
    var _efeito_espaco_slot = 4;

    for (var _lado_efeito = 0; _lado_efeito < 2; _lado_efeito++) {
        var _efeito_painel_x = (_lado_efeito == 0) ? 302 : 678;
        var _efeito_painel_y = (_lado_efeito == 0) ? 487 : 225;
        var _efeito_bencaos = (_lado_efeito == 0) ? _controle_efeitos.bencaos_jogador : _controle_efeitos.bencaos_inimigo;
        var _efeito_maldicoes = (_lado_efeito == 0) ? _controle_efeitos.maldicoes_jogador : _controle_efeitos.maldicoes_inimigo;

        for (var _slot_efeito = 0; _slot_efeito < 4; _slot_efeito++) {
            var _efeito_categoria = (_slot_efeito < 2) ? "bencao" : "maldicao";
            var _efeito_indice = _slot_efeito mod 2;
            var _efeito_lista = (_efeito_categoria == "bencao") ? _efeito_bencaos : _efeito_maldicoes;
            var _efeito_ativo = _efeito_indice < array_length(_efeito_lista);
            var _efeito_entrada = _efeito_ativo ? _efeito_lista[_efeito_indice] : noone;
            var _efeito_cor = (_efeito_categoria == "bencao")
                ? make_color_rgb(235, 195, 65) : make_color_rgb(190, 45, 70);
            var _efeito_x1 = _efeito_painel_x + _slot_efeito * (_efeito_largura_slot + _efeito_espaco_slot);
            var _efeito_y1 = _efeito_painel_y - _efeito_altura_slot / 2;
            var _efeito_x2 = _efeito_x1 + _efeito_largura_slot;
            var _efeito_y2 = _efeito_y1 + _efeito_altura_slot;

            draw_set_alpha(_efeito_ativo ? 0.88 : 0.42);
            draw_set_color(c_black);
            draw_rectangle(_efeito_x1, _efeito_y1, _efeito_x2, _efeito_y2, false);
            draw_set_alpha(1);

            if (_efeito_ativo) {
                var _efeito_nome = is_struct(_efeito_entrada) ? _efeito_entrada.nome
                    : ((_efeito_categoria == "bencao") ? "Bênção ativa" : "Maldição ativa");
                var _efeito_sprite = (is_struct(_efeito_entrada) && variable_struct_exists(_efeito_entrada, "sprite"))
                    ? _efeito_entrada.sprite : noone;
                if (_efeito_sprite != noone) {
                    var _efeito_escala_sprite = min((_efeito_largura_slot - 5) / sprite_get_width(_efeito_sprite),
                        (_efeito_altura_slot - 5) / sprite_get_height(_efeito_sprite));
                    draw_sprite_ext(_efeito_sprite, 0, (_efeito_x1 + _efeito_x2) / 2,
                        (_efeito_y1 + _efeito_y2) / 2, _efeito_escala_sprite, _efeito_escala_sprite, 0, c_white, 1);
                }

                draw_set_alpha(0.72);
                draw_set_color(c_black);
                draw_rectangle(_efeito_x1 + 1, _efeito_y2 - 15, _efeito_x2 - 1, _efeito_y2 - 1, false);
                draw_set_alpha(1);
                draw_set_font(Fontenil);
                draw_set_color(c_white);
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_text_transformed((_efeito_x1 + _efeito_x2) / 2, _efeito_y2 - 8,
                    string_copy(_efeito_nome, 1, 11), 0.28, 0.28, 0);
            } else {
                draw_set_font(Fontenil);
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_set_color(_efeito_cor);
                draw_text_transformed((_efeito_x1 + _efeito_x2) / 2, (_efeito_y1 + _efeito_y2) / 2,
                    ((_efeito_categoria == "bencao") ? "B" : "M") + string(_efeito_indice + 1), 0.42, 0.42, 0);
            }

            draw_set_color(_efeito_cor);
            draw_rectangle(_efeito_x1, _efeito_y1, _efeito_x2, _efeito_y2, true);
        }
    }
}

draw_set_font(-1);
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
#endregion

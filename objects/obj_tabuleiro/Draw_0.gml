// A mesa cobre toda a sala; a câmera e os slots mantêm suas posições.
var _tempo_impacto = instance_exists(obj_controlador) ? current_time - obj_controlador.impacto_mesa_inicio : 1000;
var _tremor = _tempo_impacto < 165;
var _matriz_mesa;
if (_tremor) {
    var _t = 10 * (1 - _tempo_impacto / 165);
    var _amplitude = 2.4 * sqr(_t / 10) * fator_efeitos_visuais();
    _matriz_mesa = matrix_get(matrix_world);
    matrix_set(matrix_world, matrix_multiply(matrix_build(sin(_t * 2.1) * _amplitude,
        cos(_t * 1.7) * _amplitude, 0, 0, 0, 0, 1, 1, 1), _matriz_mesa));
}
mesa_ambiente_desenhar(ambiente_mesa, -3, -3, room_width + 6, room_height + 6);
tabuleiro_couro_desenhar(ambiente_mesa);
tabuleiro_couro_gravuras(tempo_piscada);
mesa_ambiente_atmosfera(ambiente_mesa,0,0,room_width,room_height);

if (_tremor) matrix_set(matrix_world, _matriz_mesa);

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

            desenhar_slot_gravado((_efeito_x1+_efeito_x2)/2,(_efeito_y1+_efeito_y2)/2,
                _efeito_largura_slot,_efeito_altura_slot,0,_efeito_cor,_efeito_ativo,_efeito_categoria,
                gravura_efeitos_hover[_lado_efeito*4+_slot_efeito],gravura_efeitos_pressao[_lado_efeito*4+_slot_efeito]);

            if (_efeito_ativo) {
                var _efeito_nome = is_struct(_efeito_entrada) ? _efeito_entrada.nome
                    : ((_efeito_categoria == "bencao") ? "Bênção ativa" : "Maldição ativa");
                var _efeito_sprite = (is_struct(_efeito_entrada) && variable_struct_exists(_efeito_entrada, "sprite"))
                    ? _efeito_entrada.sprite : noone;
                if (_efeito_sprite != noone) {
                    var _efeito_escala_sprite = min((_efeito_largura_slot - 5) / sprite_get_width(_efeito_sprite),
                        (_efeito_altura_slot - 5) / sprite_get_height(_efeito_sprite));
                    desenhar_carta_mesa(_efeito_sprite, 0, (_efeito_x1 + _efeito_x2) / 2,
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
            }

        }
    }
}

draw_set_font(-1);
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
#endregion

if (instance_exists(obj_controlador)) {
    var _marcas = obj_controlador.marcas_mesa;
    for (var _m = 0; _m < array_length(_marcas); _m++) {
        var _marca = _marcas[_m];
        desenhar_marca_mesa(_marca.x, _marca.y, _marca.tempo, _marca.magica);
    }
}

#region Informações da partida
draw_set_font(Fontenil);

draw_text(20, 20, "Vida jogador: " + string(vida_jogador));
draw_text(20, 50, "Vida inimigo: " + string(vida_inimigo));
draw_text(20, 80, (turno == "jogador") ? "Seu turno" : "Turno do inimigo");
#endregion

#region Prévia ampliada da carta
if (carta_preview != noone && instance_exists(carta_preview)) {
    var _carta = carta_preview;

    var _centro_x = display_get_gui_width() / 2;
    var _centro_y = display_get_gui_height() / 2;

    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);

    var _largura_real = sprite_get_width(_carta.sprite_index);
    var _altura_real = sprite_get_height(_carta.sprite_index);

    var _largura_preview_alvo = 350;
    var _escala_preview = _largura_preview_alvo / _largura_real;

    draw_sprite_ext(
        _carta.sprite_index,
        _carta.image_index,
        _centro_x,
        _centro_y,
        _escala_preview,
        _escala_preview,
        0,
        c_white,
        1
    );

    if (!_carta.tem_arte_propria) {
	    var _largura_maxima_preview = _largura_real * _escala_preview * 0.85;
	    var _largura_texto_preview = string_width(_carta.nome_carta);
	    var _escala_nome_preview = _escala_preview * 0.4;

    if (_largura_texto_preview * _escala_nome_preview > _largura_maxima_preview) {
        _escala_nome_preview = _largura_maxima_preview / _largura_texto_preview;
    }

	    draw_set_halign(fa_center);
	    draw_set_valign(fa_top);
	    draw_set_color(c_white);
	    draw_text_transformed(_centro_x, _centro_y - (_altura_real/2 * _escala_preview) + 10, _carta.nome_carta, _escala_nome_preview, _escala_nome_preview, 0);
	}

    if (_carta.categoria == "tropa") {
	    var _escala_stats_preview = _carta.tem_arte_propria ? _escala_preview : (_escala_preview * global.ESCALA_TEXTO_CARTA * 0.7);

	    desenhar_stat_preview(_carta, _carta.vida, _carta.vida_pos_x, _carta.vida_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview);
	    desenhar_stat_preview(_carta, string(_carta.nivel_inteligencia), _carta.int_pos_x, _carta.int_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview, true);
	    desenhar_stat_preview(_carta, _carta.mochila, _carta.mochila_pos_x, _carta.mochila_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview);
	    desenhar_stat_preview(_carta, _carta.defesa_fisica, _carta.def_pos_x, _carta.def_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview);
	    desenhar_stat_preview(_carta, _carta.defesa_magica, _carta.def_magico_pos_x, _carta.def_magico_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview);

	    if (_carta.dado_dano != 0) {
		    var _texto_atk = (_carta.qtd_dados_dano > 1 ? string(_carta.qtd_dados_dano) : "") + "D" + string(_carta.dado_dano) + "+" + string(_carta.mod_dano);
		    desenhar_stat_preview(_carta, _texto_atk, _carta.atk_pos_x, _carta.atk_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview * global.ESCALA_TEXTO_ATK, true);
		}
		if (_carta.dado_dano_magico != 0) {
		    var _texto_atk_m = (_carta.qtd_dados_dano_magico > 1 ? string(_carta.qtd_dados_dano_magico) : "") + "D" + string(_carta.dado_dano_magico) + "+" + string(_carta.mod_dano_magico);
		    desenhar_stat_preview(_carta, _texto_atk_m, _carta.atk_magico_pos_x, _carta.atk_magico_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview * global.ESCALA_TEXTO_ATK, true);
		}
	}

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(_centro_x - 200, display_get_gui_height() - 40, "Clique com o botão direito pra fechar");
}
#endregion

#region Mensagem de fim de partida
if (vida_jogador <= 0) {
    draw_set_font(fnt_vitoria)
    draw_text(room_width/2 - 150, room_height/2.5, "VOCÊ PERDEU");
	draw_set_font(-1)
}
	
if (vida_inimigo <= 0) {
	draw_set_font(fnt_vitoria)
    draw_text(room_width/2 - 150, room_height/2.5, "VOCÊ VENCEU");
	draw_set_font(-1)
}
draw_set_font(-1);
#endregion

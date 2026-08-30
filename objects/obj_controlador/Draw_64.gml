#region Informações da partida
draw_set_font(Fontenil);

var _escala_impacto_vida = 1 + (dano_castelo_impacto_timer / 10) * 0.28;
var _cor_vida = (dano_castelo_impacto_timer > 0) ? c_red : c_white;
draw_set_color(_cor_vida);
draw_text_transformed(20, 20, "Vida jogador: " + string(vida_jogador), _escala_impacto_vida, _escala_impacto_vida, 0);
draw_text_transformed(20, 50, "Vida inimigo: " + string(vida_inimigo), _escala_impacto_vida, _escala_impacto_vida, 0);
draw_set_color(c_white);
draw_text(20, 80, (turno == "jogador") ? "Seu turno" : "Turno do inimigo");

if (turno == "inimigo" && ia_ativa) {
    var _gui_largura = display_get_gui_width();
    draw_set_alpha(0.82);
    draw_set_color(c_black);
    draw_roundrect(_gui_largura / 2 - 145, 18, _gui_largura / 2 + 145, 58, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(_gui_largura / 2, 28, "INIMIGO: " + ia_texto_acao);
    draw_set_halign(fa_left);
}
#endregion

#region Ritual de bênção/maldição
if (ritual_timer > 0) {
    var _progresso_ritual = 1 - (ritual_timer / ritual_duracao);
    var _alpha_ritual = sin(_progresso_ritual * pi);
    var _gui_largura = display_get_gui_width();
    var _gui_altura = display_get_gui_height();
    var _centro_x = _gui_largura / 2;
    var _centro_y = _gui_altura / 2;
    var _raio = 45 + _progresso_ritual * 150;
    var _cor_ritual = (ritual_tipo == "bencao") ? make_color_rgb(255, 220, 95) : make_color_rgb(185, 35, 65);

    draw_set_alpha(_alpha_ritual * 0.65);
    draw_set_color(_cor_ritual);
    draw_circle(_centro_x, _centro_y, _raio, true);
    draw_circle(_centro_x, _centro_y, _raio * 0.66, true);

    if (ritual_tipo == "bencao") {
        // Halo e raios ascendentes para uma leitura angelical.
        for (var i = 0; i < 12; i++) {
            var _angulo = i * 30 + _progresso_ritual * 35;
            var _x1 = _centro_x + lengthdir_x(_raio * 0.55, _angulo);
            var _y1 = _centro_y + lengthdir_y(_raio * 0.55, _angulo);
            var _x2 = _centro_x + lengthdir_x(_raio, _angulo);
            var _y2 = _centro_y + lengthdir_y(_raio, _angulo);
            draw_line_width(_x1, _y1, _x2, _y2, 2);
        }
    } else {
        // Selo de cinco pontas pulsante para a maldição.
        var _pontos_x = [];
        var _pontos_y = [];
        for (var i = 0; i < 5; i++) {
            var _angulo = -90 + i * 72 - _progresso_ritual * 45;
            array_push(_pontos_x, _centro_x + lengthdir_x(_raio * 0.72, _angulo));
            array_push(_pontos_y, _centro_y + lengthdir_y(_raio * 0.72, _angulo));
        }
        for (var i = 0; i < 5; i++) {
            var _proximo = (i + 2) mod 5;
            draw_line_width(_pontos_x[i], _pontos_y[i], _pontos_x[_proximo], _pontos_y[_proximo], 3);
        }
    }

    draw_set_font(fnt_vitoria);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_alpha(_alpha_ritual);
    draw_set_color(c_black);
    draw_text_transformed(_centro_x + 3, _centro_y + 3, ritual_tipo == "bencao" ? "BÊNÇÃO" : "MALDIÇÃO", 1.4, 1.4, 0);
    draw_set_color(_cor_ritual);
    draw_text_transformed(_centro_x, _centro_y, ritual_tipo == "bencao" ? "BÊNÇÃO" : "MALDIÇÃO", 1.4, 1.4, 0);
    draw_set_font(Fontenil);
    draw_text_transformed(_centro_x, _centro_y + 42, ritual_texto, 0.9, 0.9, 0);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // Últimos 55 frames: abaixa o volume enquanto o ritual desaparece.
    if (ritual_timer <= 55 && !ritual_fade_final_iniciado) {
        audio_sound_gain(ritual_som, 0, 900);
        ritual_fade_final_iniciado = true;
    }
    ritual_timer -= 1;
}
#endregion

#region Anúncio grande de terreno ativado
if (terreno_anuncio_timer > 0) {
    var _progresso_anuncio = 1 - (terreno_anuncio_timer / terreno_anuncio_duracao);
    var _alpha_anuncio = 1;

    if (_progresso_anuncio < 0.2) {
        _alpha_anuncio = _progresso_anuncio / 0.2; // fade in
    } else if (_progresso_anuncio > 0.65) {
        _alpha_anuncio = 1 - ((_progresso_anuncio - 0.65) / 0.35); // fade out
    }

	var _gui_largura = display_get_gui_width();
	var _gui_altura = display_get_gui_height();

	var _escala_anuncio = 2.0; // ajuste esse número pra deixar maior/menor

	draw_set_font(fnt_vitoria);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_alpha(_alpha_anuncio);
	draw_set_color(c_black);
	draw_text_transformed(_gui_largura/2 + 3, _gui_altura/2 + 3, terreno_anuncio_texto, _escala_anuncio, _escala_anuncio, 0); // sombra
	draw_set_color(c_white);
	draw_text_transformed(_gui_largura/2, _gui_altura/2, terreno_anuncio_texto, _escala_anuncio, _escala_anuncio, 0);
	draw_set_alpha(1);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(-1);

    terreno_anuncio_timer -= 1;
}
#endregion

#region Prévia ampliada da carta
if (carta_preview != noone && instance_exists(carta_preview)) {
    var _carta = carta_preview;

    var _gui_largura_preview = display_get_gui_width();
    var _tem_painel_lateral = _gui_largura_preview >= 950;
    var _centro_x = _gui_largura_preview / 2 - (_tem_painel_lateral ? 165 : 0);
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
	    desenhar_stat_preview(_carta, string(_carta.mochila), _carta.mochila_pos_x, _carta.mochila_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview, true);
	    desenhar_stat_preview(_carta, calcular_defesa_fisica_total(_carta), _carta.def_pos_x, _carta.def_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview);
		desenhar_stat_preview(_carta, calcular_defesa_magica_total(_carta), _carta.def_magico_pos_x, _carta.def_magico_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview);

	    if (_carta.dado_dano != 0) {
		    var _texto_atk = (_carta.qtd_dados_dano > 1 ? string(_carta.qtd_dados_dano) : "") + "D" + string(_carta.dado_dano) + "+" + string(calcular_mod_dano_total(_carta));
		    desenhar_stat_preview(_carta, _texto_atk, _carta.atk_pos_x, _carta.atk_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview * global.ESCALA_TEXTO_ATK, true);
		}
		if (_carta.dado_dano_magico != 0) {
			var _texto_atk_m = (_carta.qtd_dados_dano_magico > 1 ? string(_carta.qtd_dados_dano_magico) : "") + "D" + string(_carta.dado_dano_magico) + "+" + string(calcular_mod_dano_total(_carta));
		    desenhar_stat_preview(_carta, _texto_atk_m, _carta.atk_magico_pos_x, _carta.atk_magico_pos_y, _centro_x, _centro_y, _largura_real, _altura_real, _escala_preview, _escala_stats_preview * global.ESCALA_TEXTO_ATK, true);
		}
	}

    #region Painel de detalhes da carta
    var _painel_largura = _tem_painel_lateral ? 300 : min(360, display_get_gui_width() - 40);
    var _painel_x = _tem_painel_lateral ? (_centro_x + 205) : ((display_get_gui_width() - _painel_largura) / 2);
    var _painel_y = _tem_painel_lateral ? 105 : (display_get_gui_height() - 245);
    var _painel_altura = _tem_painel_lateral ? 430 : 260;
    var _texto_detalhes = descricao_carta_preview(_carta);

    draw_set_alpha(0.92);
    draw_set_color(c_black);
    draw_roundrect(_painel_x, _painel_y, _painel_x + _painel_largura, _painel_y + _painel_altura, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_roundrect(_painel_x, _painel_y, _painel_x + _painel_largura, _painel_y + _painel_altura, true);
    draw_set_font(Fontenil);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    draw_text(_painel_x + 14, _painel_y + 12, "DETALHES DA CARTA");
    draw_set_color(c_white);
    draw_text_ext(_painel_x + 14, _painel_y + 42, _texto_detalhes, 28, _painel_largura - 28);
    #endregion

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(_centro_x - 200, display_get_gui_height() - 40, "Clique com o botão direito pra fechar");
}
#endregion

#region Dano do castelo - camada final do HUD
// Fica no fim do Draw GUI para não ser coberto por cartas, menus ou prévias.
if (dano_castelo_ativo) {
    var _tempo_decorrido = dano_castelo_duracao - dano_castelo_timer;
    var _progresso_dano = clamp(_tempo_decorrido / 30, 0, 1);
    var _progresso_suave = 1 - power(1 - _progresso_dano, 3);
    var _alvo_y = (dano_castelo_dono == "jogador") ? 32 : 62;
    var _x_dano = lerp(340, 185, _progresso_suave);
    var _escala_dano = 1 + sin(_progresso_dano * pi) * 0.35;

    draw_set_font(Fontenil);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_black);
    draw_text_transformed(_x_dano + 2, _alvo_y + 2, "-" + string(dano_castelo_valor), _escala_dano, _escala_dano, 0);
    draw_set_color(c_red);
    draw_text_transformed(_x_dano, _alvo_y, "-" + string(dano_castelo_valor), _escala_dano, _escala_dano, 0);
    draw_set_font(-1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
#endregion

#region Avisos de regra - camada final do HUD
with (obj_texto_flutuante) {
    var _gui_x = x;
    var _gui_y = y;
    var _camera = view_camera[0];
    if (_camera != -1) {
        _gui_x = (x - camera_get_view_x(_camera)) * display_get_gui_width() / camera_get_view_width(_camera);
        _gui_y = (y - camera_get_view_y(_camera)) * display_get_gui_height() / camera_get_view_height(_camera);
    }

    var _progresso_aviso = vida_texto / vida_texto_max;
    var _alpha_aviso = (_progresso_aviso < 0.15) ? (_progresso_aviso / 0.15) : ((_progresso_aviso > 0.6) ? (1 - ((_progresso_aviso - 0.6) / 0.4)) : 1);
    draw_set_font(Fontenil);
    draw_set_alpha(_alpha_aviso);
    draw_set_color(c_black);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_gui_x + 2, _gui_y + 2, texto);
    draw_set_color(cor_texto);
    draw_text(_gui_x, _gui_y, texto);
}
draw_set_font(-1);
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
#endregion

#region Histórico e cemitério
var _hud_largura = display_get_gui_width();
draw_set_font(Fontenil);

// Histórico fica recolhido até o jogador pedir, para não poluir a tela.
draw_set_color(c_black);
draw_roundrect(14, 112, 190, 144, false);
draw_set_color(c_yellow);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(102, 128, "HISTÓRICO  " + string(array_length(historico_combate)));
draw_set_color(c_white);
if (historico_aberto) {
    var _primeiro_evento = max(0, array_length(historico_combate) - 12);
    var _eventos_visiveis = array_length(historico_combate) - _primeiro_evento;
    draw_set_alpha(0.88);
    draw_set_color(c_black);
    draw_roundrect(14, 150, 330, 150 + 26 + _eventos_visiveis * 17, false);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    draw_text(24, 156, "ÚLTIMAS AÇÕES");
    draw_set_color(c_white);
    for (var i = _primeiro_evento; i < array_length(historico_combate); i++) {
        draw_text(24, 178 + (i - _primeiro_evento) * 17, "• " + historico_combate[i]);
    }
}

// Botão e lista das tropas que morreram durante a partida.
var _cem_x1 = _hud_largura - 205;
var _cem_x2 = _hud_largura - 15;
draw_set_color(c_black);
draw_roundrect(_cem_x1, 30, _cem_x2, 62, false);
draw_set_color(c_white);
draw_roundrect(_cem_x1, 30, _cem_x2, 62, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text((_cem_x1 + _cem_x2) / 2, 46, "TUTORIAL  (F1)");
draw_set_color(c_black);
draw_roundrect(_cem_x1, 72, _cem_x2, 104, false);
draw_set_color(c_white);
draw_roundrect(_cem_x1, 72, _cem_x2, 104, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text((_cem_x1 + _cem_x2) / 2, 88, "CEMITÉRIO  " + string(array_length(cemiterio_jogador)) + "/" + string(array_length(cemiterio_inimigo)));

if (cemiterio_aberto) {
    var _lista_y1 = 110;
    var _lista_y2 = 300;
    draw_set_alpha(0.9);
    draw_set_color(c_black);
    draw_roundrect(_cem_x1, _lista_y1, _cem_x2, _lista_y2, false);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_aqua);
    draw_text(_cem_x1 + 10, _lista_y1 + 8, "SUAS TROPAS");
    draw_set_color(c_white);
    var _linha_cemiterio = 0;
    for (var i = max(0, array_length(cemiterio_jogador) - 4); i < array_length(cemiterio_jogador); i++) {
        draw_text(_cem_x1 + 10, _lista_y1 + 28 + _linha_cemiterio * 16, "• " + cemiterio_jogador[i]);
        _linha_cemiterio += 1;
    }
    draw_set_color(c_red);
    draw_text(_cem_x1 + 10, _lista_y1 + 98, "INIMIGAS");
    draw_set_color(c_white);
    _linha_cemiterio = 0;
    for (var i = max(0, array_length(cemiterio_inimigo) - 4); i < array_length(cemiterio_inimigo); i++) {
        draw_text(_cem_x1 + 10, _lista_y1 + 118 + _linha_cemiterio * 16, "• " + cemiterio_inimigo[i]);
        _linha_cemiterio += 1;
    }
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_font(-1);
#endregion

#region Tutorial opcional
if (tutorial_ativo) {
    var _tutorial_largura = display_get_gui_width();
    var _tutorial_altura = display_get_gui_height();
    var _tutorial_cx = _tutorial_largura / 2;
    var _tutorial_cy = _tutorial_altura / 2;
    var _tutorial = tutorial_paginas[tutorial_pagina];

    draw_set_alpha(0.82);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _tutorial_largura, _tutorial_altura, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_roundrect(_tutorial_cx - 300, _tutorial_cy - 210, _tutorial_cx + 300, _tutorial_cy + 220, false);
    draw_set_color(c_black);
    draw_roundrect(_tutorial_cx - 300, _tutorial_cy - 210, _tutorial_cx + 300, _tutorial_cy + 220, true);

    draw_set_font(fnt_vitoria);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_black);
    draw_text_transformed(_tutorial_cx, _tutorial_cy - 145, _tutorial.titulo, 0.8, 0.8, 0);
    // Fontenil inclui os caracteres portugueses; o espaçamento maior mantém a leitura confortável.
    draw_set_font(Fontenil);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text_ext(_tutorial_cx - 245, _tutorial_cy - 95, _tutorial.texto, 20, 490);
    draw_set_font(Fontenil);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_tutorial_cx, _tutorial_cy + 105, string(tutorial_pagina + 1) + " / " + string(array_length(tutorial_paginas)));

    draw_set_color(c_black);
    draw_roundrect(_tutorial_cx - 230, _tutorial_cy + 150, _tutorial_cx - 70, _tutorial_cy + 195, false);
    draw_roundrect(_tutorial_cx + 70, _tutorial_cy + 150, _tutorial_cx + 230, _tutorial_cy + 195, false);
    draw_set_color(c_white);
    draw_roundrect(_tutorial_cx - 230, _tutorial_cy + 150, _tutorial_cx - 70, _tutorial_cy + 195, true);
    draw_roundrect(_tutorial_cx + 70, _tutorial_cy + 150, _tutorial_cx + 230, _tutorial_cy + 195, true);
    draw_text(_tutorial_cx - 150, _tutorial_cy + 172, "< ANTERIOR");
    draw_text(_tutorial_cx + 150, _tutorial_cy + 172, "PRÓXIMA >");

    draw_set_color(c_black);
    draw_roundrect(_tutorial_cx + 250, _tutorial_cy - 190, _tutorial_cx + 290, _tutorial_cy - 150, false);
    draw_set_color(c_white);
    draw_text(_tutorial_cx + 270, _tutorial_cy - 170, "X");
    draw_set_font(-1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
#endregion

#region Tela final da partida
if (vida_jogador <= 0 || vida_inimigo <= 0) {
    var _fim_largura = display_get_gui_width();
    var _fim_altura = display_get_gui_height();
    var _fim_x = _fim_largura / 2;
    var _fim_y = _fim_altura / 2;
    var _venceu = vida_inimigo <= 0 && vida_jogador > 0;

    draw_set_alpha(0.78);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _fim_largura, _fim_altura, false);
    draw_set_alpha(1);
    draw_set_font(fnt_vitoria);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(_venceu ? c_yellow : c_red);
    draw_text(_fim_x, _fim_y - 35, _venceu ? "VOCÊ VENCEU" : "VOCÊ PERDEU");
    draw_set_font(Fontenil);
    draw_set_color(c_white);
    draw_text(_fim_x, _fim_y, "O castelo " + (_venceu ? "inimigo caiu." : "foi destruído."));
    draw_set_color(c_black);
    draw_roundrect(_fim_x - 120, _fim_y + 35, _fim_x + 120, _fim_y + 80, false);
    draw_set_color(c_white);
    draw_roundrect(_fim_x - 120, _fim_y + 35, _fim_x + 120, _fim_y + 80, true);
    draw_text(_fim_x, _fim_y + 57, "REINICIAR PARTIDA");
    draw_set_font(-1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
#endregion

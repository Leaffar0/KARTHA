#region Informações da partida
draw_set_font(Fontenil);

var _cor_vida_jogador = make_color_rgb(45, 125, 255);
var _cor_vida_inimigo = make_color_rgb(225, 55, 55);
var _tremor_castelo = (dano_castelo_impacto_timer > 0) ? sin(dano_castelo_impacto_timer * 4.7) * dano_castelo_impacto_timer * 0.55 : 0;
var _barra_x1 = 20 + _tremor_castelo;
var _barra_x2 = 250 + _tremor_castelo;
var _barra_altura = 22;
var _barra_jogador_y1 = 16;
var _barra_inimigo_y1 = 48;
var _proporcao_jogador = clamp(vida_jogador / 20, 0, 1);
var _proporcao_inimigo = clamp(vida_inimigo / 20, 0, 1);
var _pulso_jogador = (dano_castelo_impacto_timer > 0 && dano_castelo_dono == "jogador") ? 2 : 0;
var _pulso_inimigo = (dano_castelo_impacto_timer > 0 && dano_castelo_dono == "inimigo") ? 2 : 0;

// Fundo, preenchimento e contorno das duas barras de castelo.
draw_set_color(c_black);
draw_roundrect(_barra_x1 - _pulso_jogador, _barra_jogador_y1 - _pulso_jogador,
    _barra_x2 + _pulso_jogador, _barra_jogador_y1 + _barra_altura + _pulso_jogador, false);
draw_roundrect(_barra_x1 - _pulso_inimigo, _barra_inimigo_y1 - _pulso_inimigo,
    _barra_x2 + _pulso_inimigo, _barra_inimigo_y1 + _barra_altura + _pulso_inimigo, false);
draw_set_color(_cor_vida_jogador);
draw_roundrect(_barra_x1, _barra_jogador_y1,
    _barra_x1 + (_barra_x2 - _barra_x1) * _proporcao_jogador, _barra_jogador_y1 + _barra_altura, false);
draw_set_color(_cor_vida_inimigo);
draw_roundrect(_barra_x1, _barra_inimigo_y1,
    _barra_x1 + (_barra_x2 - _barra_x1) * _proporcao_inimigo, _barra_inimigo_y1 + _barra_altura, false);
draw_set_color(c_white);
draw_roundrect(_barra_x1 - _pulso_jogador, _barra_jogador_y1 - _pulso_jogador,
    _barra_x2 + _pulso_jogador, _barra_jogador_y1 + _barra_altura + _pulso_jogador, true);
draw_roundrect(_barra_x1 - _pulso_inimigo, _barra_inimigo_y1 - _pulso_inimigo,
    _barra_x2 + _pulso_inimigo, _barra_inimigo_y1 + _barra_altura + _pulso_inimigo, true);

// Números permanecem dentro das barras para não perder precisão.
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_black);
draw_text_transformed((_barra_x1 + _barra_x2) / 2 + 1, _barra_jogador_y1 + _barra_altura / 2 + 1,
    "Jogador  " + string(vida_jogador) + "/20", 0.72, 0.72, 0);
draw_text_transformed((_barra_x1 + _barra_x2) / 2 + 1, _barra_inimigo_y1 + _barra_altura / 2 + 1,
    "Inimigo  " + string(vida_inimigo) + "/20", 0.72, 0.72, 0);
draw_set_color(c_white);
draw_text_transformed((_barra_x1 + _barra_x2) / 2, _barra_jogador_y1 + _barra_altura / 2,
    "Jogador  " + string(vida_jogador) + "/20", 0.72, 0.72, 0);
draw_text_transformed((_barra_x1 + _barra_x2) / 2, _barra_inimigo_y1 + _barra_altura / 2,
    "Inimigo  " + string(vida_inimigo) + "/20", 0.72, 0.72, 0);
// Rachaduras rápidas atravessam a barra atingida no instante do impacto.
if (dano_castelo_impacto_timer > 0) {
    var _rachadura_y = (dano_castelo_dono == "jogador") ? _barra_jogador_y1 : _barra_inimigo_y1;
    var _rachadura_x = _barra_x1 + (_barra_x2 - _barra_x1) * 0.72;
    draw_set_color(c_white); draw_set_alpha(dano_castelo_impacto_timer / 10);
    draw_line(_rachadura_x, _rachadura_y, _rachadura_x - 7, _rachadura_y + 8);
    draw_line(_rachadura_x - 7, _rachadura_y + 8, _rachadura_x + 3, _rachadura_y + 14);
    draw_line(_rachadura_x + 3, _rachadura_y + 14, _rachadura_x - 4, _rachadura_y + 22);
    draw_set_alpha(1);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(20, 82, (turno == "preparacao") ? "Disputa inicial" : ((turno == "jogador") ? "Seu turno" : "Turno do inimigo"));

var _hud_largura = display_get_gui_width();
var _hud_direita_x1 = _hud_largura - 205 + hud_deslocamento_direita;
var _hud_direita_x2 = _hud_largura - 15 + hud_deslocamento_direita;
draw_set_alpha(0.88);
draw_set_color(c_black);
draw_roundrect(_hud_direita_x1, 152, _hud_direita_x2, 184, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_roundrect(_hud_direita_x1, 152, _hud_direita_x2, 184, true);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text((_hud_direita_x1 + _hud_direita_x2) / 2, 168, "PAUSA  [P]");
draw_set_halign(fa_left);
draw_set_valign(fa_top);

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

#region Transição de turno
if (anuncio_turno_timer > 0) {
    var _progresso_turno = 1 - (anuncio_turno_timer / anuncio_turno_duracao);
    var _alpha_turno = sin(_progresso_turno * pi) * 0.92;
    var _largura_turno = display_get_gui_width();
    var _altura_turno = display_get_gui_height();
    var _cor_turno = (turno == "jogador") ? c_aqua : c_red;
    // Uma faixa luminosa varre o tabuleiro antes do título do turno.
    var _onda_x = lerp(-180, _largura_turno + 180, _progresso_turno);
    draw_set_alpha(_alpha_turno * 0.20); draw_set_color(_cor_turno);
    draw_triangle(_onda_x - 150, 0, _onda_x + 70, 0, _onda_x - 50, _altura_turno, false);
    draw_triangle(_onda_x + 70, 0, _onda_x + 150, _altura_turno, _onda_x - 50, _altura_turno, false);
    draw_set_font(fnt_vitoria);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_alpha(_alpha_turno);
    draw_set_color(c_black);
    draw_text_transformed(_largura_turno / 2 + 3, _altura_turno / 2 + 3, anuncio_turno_texto, 1.15, 1.15, 0);
    draw_set_color(_cor_turno);
    draw_text_transformed(_largura_turno / 2, _altura_turno / 2, anuncio_turno_texto, 1.15, 1.15, 0);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(Fontenil);
    anuncio_turno_timer -= 1;
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

// Avisos de regra possuem Draw GUI próprio e são renderizados acima deste HUD.

#region Histórico e cemitério
var _hud_largura = display_get_gui_width();
draw_set_font(Fontenil);

// Histórico fica recolhido até o jogador pedir, para não poluir a tela.
draw_set_color(c_black);
var _historico_x1 = 14 - hud_deslocamento_esquerda;
var _historico_x2 = 190 - hud_deslocamento_esquerda;
draw_roundrect(_historico_x1, 210, _historico_x2, 242, false);
draw_set_color(c_yellow);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text((_historico_x1 + _historico_x2) / 2, 226, "HISTÓRICO  " + string(array_length(historico_combate)));
draw_set_color(c_white);
if (historico_aberto) {
    var _primeiro_evento = max(0, array_length(historico_combate) - 12);
    var _eventos_visiveis = array_length(historico_combate) - _primeiro_evento;
    draw_set_alpha(0.88);
    draw_set_color(c_black);
    draw_roundrect(_historico_x1, 248, _historico_x1 + 316, 248 + 26 + _eventos_visiveis * 17, false);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_yellow);
    draw_text(_historico_x1 + 10, 254, "ÚLTIMAS AÇÕES");
    draw_set_color(c_white);
    for (var i = _primeiro_evento; i < array_length(historico_combate); i++) {
        draw_text(_historico_x1 + 10, 276 + (i - _primeiro_evento) * 17, "• " + historico_combate[i]);
    }
}

// Botão e lista das tropas que morreram durante a partida.
var _cem_x1 = _hud_largura - 205 + hud_deslocamento_direita;
var _cem_x2 = _hud_largura - 15 + hud_deslocamento_direita;
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

#region Confirmação de descarte manual
if (confirmacao_descarte_ativa && instance_exists(carta_pendente_descarte)) {
    var _confirmacao_largura = display_get_gui_width();
    var _confirmacao_altura = display_get_gui_height();
    var _confirmacao_cx = _confirmacao_largura / 2;
    var _confirmacao_cy = _confirmacao_altura / 2;

    draw_set_alpha(0.65);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _confirmacao_largura, _confirmacao_altura, false);
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_roundrect(_confirmacao_cx - 245, _confirmacao_cy - 110, _confirmacao_cx + 245, _confirmacao_cy + 110, false);
    draw_set_color(c_white);
    draw_roundrect(_confirmacao_cx - 245, _confirmacao_cy - 110, _confirmacao_cx + 245, _confirmacao_cy + 110, true);
    draw_set_font(fnt_botao);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_yellow);
    draw_text(_confirmacao_cx, _confirmacao_cy - 62, "DESCARTAR CARTA?");
    draw_set_font(-1);
    draw_set_color(c_white);
    draw_text(_confirmacao_cx, _confirmacao_cy - 25, carta_pendente_descarte.nome_carta);
    draw_set_color(c_black);
    draw_roundrect(_confirmacao_cx - 180, _confirmacao_cy + 42, _confirmacao_cx - 12, _confirmacao_cy + 82, false);
    draw_roundrect(_confirmacao_cx + 12, _confirmacao_cy + 42, _confirmacao_cx + 180, _confirmacao_cy + 82, false);
    draw_set_color(c_white);
    draw_roundrect(_confirmacao_cx - 180, _confirmacao_cy + 42, _confirmacao_cx - 12, _confirmacao_cy + 82, true);
    draw_roundrect(_confirmacao_cx + 12, _confirmacao_cy + 42, _confirmacao_cx + 180, _confirmacao_cy + 82, true);
    draw_text(_confirmacao_cx - 96, _confirmacao_cy + 62, "DESCARTAR");
    draw_text(_confirmacao_cx + 96, _confirmacao_cy + 62, "CANCELAR");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
#endregion

#region Pilha de descarte
if (descarte_aberto) {
    var _descarte_largura = display_get_gui_width();
    var _descarte_altura = display_get_gui_height();
    var _descarte_cx = _descarte_largura / 2;
    var _descarte_cy = _descarte_altura / 2;
    var _descarte_x1 = _descarte_cx - 280;
    var _descarte_x2 = _descarte_cx + 280;
    var _descarte_y1 = _descarte_cy - 200;
    var _descarte_y2 = _descarte_cy + 200;
    var _primeira_carta = max(0, array_length(descarte_jogador) - 12);

    draw_set_alpha(0.72);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _descarte_largura, _descarte_altura, false);
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_roundrect(_descarte_x1, _descarte_y1, _descarte_x2, _descarte_y2, false);
    draw_set_color(c_white);
    draw_roundrect(_descarte_x1, _descarte_y1, _descarte_x2, _descarte_y2, true);

    draw_set_font(fnt_botao);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_yellow);
    draw_text(_descarte_cx, _descarte_y1 + 32, "PILHA DE DESCARTE");
    draw_set_font(-1);
    draw_set_color(c_white);
    draw_text(_descarte_cx, _descarte_y1 + 58, string(array_length(descarte_jogador)) + " carta(s) usada(s)");

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    if (descarte_preview_indice >= 0 && descarte_preview_indice < array_length(descarte_jogador)) {
        var _carta_descartada = descarte_jogador[descarte_preview_indice];
        var _sprite_descartada = variable_struct_exists(_carta_descartada, "sprite") ? _carta_descartada.sprite : spr_carta_placeholder;
        var _escala_descartada = min(155 / sprite_get_width(_sprite_descartada), 210 / sprite_get_height(_sprite_descartada));
        var _descricao_descartada = variable_struct_exists(_carta_descartada, "descricao") ? _carta_descartada.descricao : "Informações da carta indisponíveis nesta partida.";

        draw_sprite_ext(_sprite_descartada, 0, _descarte_x1 + 28, _descarte_y1 + 94, _escala_descartada, _escala_descartada, 0, c_white, 1);
        draw_set_color(c_aqua);
        draw_text(_descarte_x1 + 205, _descarte_y1 + 94, _carta_descartada.nome);
        draw_set_color(c_white);
        draw_text_ext(_descarte_x1 + 205, _descarte_y1 + 120, _descricao_descartada, 16, _descarte_x2 - (_descarte_x1 + 225));

        draw_set_color(c_black);
        draw_roundrect(_descarte_x1 + 35, _descarte_y2 - 55, _descarte_x1 + 200, _descarte_y2 - 20, false);
        draw_set_color(c_white);
        draw_roundrect(_descarte_x1 + 35, _descarte_y2 - 55, _descarte_x1 + 200, _descarte_y2 - 20, true);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(_descarte_x1 + 117, _descarte_y2 - 37, "VOLTAR");
    } else if (array_length(descarte_jogador) <= 0) {
        draw_set_halign(fa_center);
        draw_text(_descarte_cx, _descarte_cy, "Nenhuma carta foi descartada ainda.");
    } else {
        for (var i = _primeira_carta; i < array_length(descarte_jogador); i++) {
            var _carta_descartada = descarte_jogador[i];
            draw_text(_descarte_x1 + 35, _descarte_y1 + 90 + (i - _primeira_carta) * 21, "• " + _carta_descartada.nome);
        }
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_set_color(c_gray);
        draw_text(_descarte_cx, _descarte_y2 - 48, "Clique em uma carta para ver os detalhes");
        draw_set_color(c_white);
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_black);
    draw_roundrect(_descarte_cx + 240, _descarte_cy - 180, _descarte_cx + 280, _descarte_cy - 140, false);
    draw_set_color(c_white);
    draw_roundrect(_descarte_cx + 240, _descarte_cy - 180, _descarte_cx + 280, _descarte_cy - 140, true);
    draw_text(_descarte_cx + 260, _descarte_cy - 160, "X");
    draw_set_color(c_gray);
    draw_text(_descarte_cx, _descarte_y2 - 22, descarte_preview_indice != -1 ? "ESC ou X para voltar" : "ESC ou X para fechar");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
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

#region Painel de pausa
if (pausa_ativa) {
    var _pausa_largura = display_get_gui_width();
    var _pausa_altura = display_get_gui_height();
    var _pausa_cx = _pausa_largura / 2;
    var _pausa_cy = _pausa_altura / 2;
    draw_set_alpha(0.78);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _pausa_largura, _pausa_altura, false);
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_roundrect(_pausa_cx - 235, _pausa_cy - 150, _pausa_cx + 235, _pausa_cy + 225, false);
    draw_set_color(c_white);
    draw_roundrect(_pausa_cx - 235, _pausa_cy - 150, _pausa_cx + 235, _pausa_cy + 225, true);
    draw_set_font(fnt_vitoria);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_pausa_cx, _pausa_cy - 88, opcoes_pausa_ativa ? "OPÇÕES" : "PAUSA");
    draw_set_font(Fontenil);
    if (opcoes_pausa_ativa) {
        draw_text(_pausa_cx - 125, _pausa_cy - 35, "<");
        draw_text(_pausa_cx + 125, _pausa_cy - 35, ">");
        draw_text(_pausa_cx, _pausa_cy - 35, "MÚSICA  " + string(round(global.volume_musica * 100)) + "%");
        draw_text(_pausa_cx - 125, _pausa_cy + 10, "<");
        draw_text(_pausa_cx + 125, _pausa_cy + 10, ">");
        draw_text(_pausa_cx, _pausa_cy + 10, "EFEITOS  " + string(round(global.volume_efeitos * 100)) + "%");
        draw_set_color(c_gray);
        draw_text(_pausa_cx, _pausa_cy + 55, "TELA CHEIA: " + (window_get_fullscreen() ? "SIM" : "NÃO"));
        draw_set_color(c_white);
        draw_text(_pausa_cx, _pausa_cy + 110, "VOLTAR");
    } else {
        draw_text(_pausa_cx, _pausa_cy - 38, "A partida está aguardando.");
    draw_set_color(c_black);
    draw_roundrect(_pausa_cx - 125, _pausa_cy + 35, _pausa_cx + 125, _pausa_cy + 75, false);
    draw_set_color(c_white);
    draw_roundrect(_pausa_cx - 125, _pausa_cy + 35, _pausa_cx + 125, _pausa_cy + 75, true);
    draw_text(_pausa_cx, _pausa_cy + 55, "CONTINUAR  [P / ESC]");
    draw_set_color(c_black);
    draw_roundrect(_pausa_cx - 125, _pausa_cy + 90, _pausa_cx + 125, _pausa_cy + 130, false);
    draw_set_color(c_white);
    draw_roundrect(_pausa_cx - 125, _pausa_cy + 90, _pausa_cx + 125, _pausa_cy + 130, true);
    draw_text(_pausa_cx, _pausa_cy + 110, "OPÇÕES");
    draw_set_color(c_black);
    draw_roundrect(_pausa_cx - 125, _pausa_cy + 145, _pausa_cx + 125, _pausa_cy + 185, false);
    draw_set_color(c_red);
    draw_roundrect(_pausa_cx - 125, _pausa_cy + 145, _pausa_cx + 125, _pausa_cy + 185, true);
    draw_text(_pausa_cx, _pausa_cy + 165, "SAIR DO JOGO");
    draw_set_color(c_gray);
    draw_text(_pausa_cx, _pausa_cy + 210, "F1 abre o tutorial");
    }
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
#endregion

#region Itens em movimento
for (var _i_voo = 0; _i_voo < array_length(animacoes_item); _i_voo++) {
    var _voo = animacoes_item[_i_voo];
    var _voo_p = clamp(_voo.timer / _voo.duracao, 0, 1);
    var _voo_s = _voo_p * _voo_p * (3 - 2 * _voo_p);
    var _voo_x = lerp(_voo.origem_x, _voo.destino_x, _voo_s);
    var _voo_y = lerp(_voo.origem_y, _voo.destino_y, _voo_s) - sin(_voo_p * pi) * 55;
    var _voo_esc = 0.34 + sin(_voo_p * pi) * 0.10;
    draw_set_alpha(sin(_voo_p * pi) * 0.92);
    draw_sprite_ext(_voo.sprite, 0, _voo_x, _voo_y, _voo_esc, _voo_esc, _voo_p * 360, _voo.cor, 1);
}
draw_set_alpha(1); draw_set_color(c_white);
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
    var _fim_p = clamp(fim_animacao_timer / 28, 0, 1);
    var _fim_escala = 1 + (1 - _fim_p) * 1.4 + sin(_fim_p * pi) * 0.10;
    draw_set_alpha(_fim_p);
    draw_text_transformed(_fim_x, _fim_y - 35, _venceu ? "VOCÊ VENCEU" : "VOCÊ PERDEU", _fim_escala, _fim_escala, 0);
    draw_set_alpha(1);
    draw_set_font(Fontenil);
    draw_set_color(c_white);
    draw_text(_fim_x, _fim_y, "O castelo " + (_venceu ? "inimigo caiu." : "foi destruído."));
    draw_text(_fim_x, _fim_y + 26, "Turnos completos: " + string(turnos_completos));
    draw_text(_fim_x, _fim_y + 50, "Tropas derrotadas — Você: " + string(array_length(cemiterio_jogador)) + " | Inimigo: " + string(array_length(cemiterio_inimigo)));
    draw_set_color(c_black);
    draw_roundrect(_fim_x - 120, _fim_y + 85, _fim_x + 120, _fim_y + 130, false);
    draw_set_color(c_white);
    draw_roundrect(_fim_x - 120, _fim_y + 85, _fim_x + 120, _fim_y + 130, true);
    draw_text(_fim_x, _fim_y + 107, "REINICIAR PARTIDA");
    draw_set_font(-1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
#endregion


#region Escolha de iniciativa
if (disputa_inicial_estado != "concluida" && !tutorial_ativo && !(instance_exists(obj_livro) && obj_livro.preview_ativo)) {
    var _ini_largura = display_get_gui_width();
    var _ini_altura = display_get_gui_height();
    var _ini_cx = _ini_largura / 2;
    var _ini_cy = _ini_altura / 2;

    var _abertura_mesa_visivel = (disputa_inicial_estado == "aguardando_deck" || disputa_inicial_estado == "distribuindo" || disputa_inicial_estado == "preparando_dado" || disputa_inicial_estado == "aguardando_arremesso" || disputa_inicial_estado == "rolando");
    draw_set_alpha(_abertura_mesa_visivel ? 0.18 : 0.76);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _ini_largura, _ini_altura, false);
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_roundrect(_ini_cx - 285, _ini_cy - 155, _ini_cx + 285, _ini_cy + 145, false);
    draw_set_color(c_white);
    draw_roundrect(_ini_cx - 285, _ini_cy - 155, _ini_cx + 285, _ini_cy + 145, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_vitoria);
    draw_set_color(c_yellow);
    draw_text(_ini_cx, _ini_cy - 108, disputa_inicial_estado == "aguardando_deck" ? "PREPARE SUA MÃO" : "DISPUTA DE INICIATIVA");
    draw_set_font(Fontenil);
    draw_set_color(c_aqua);
    draw_text(_ini_cx - 120, _ini_cy - 38, "VOCÊ\n" + (disputa_inicial_resultado_jogador >= 0 ? string(disputa_inicial_resultado_jogador) : "D20"));
    draw_set_color(c_red);
    draw_text(_ini_cx + 120, _ini_cy - 38, "INIMIGO\n" + (disputa_inicial_resultado_inimigo >= 0 ? string(disputa_inicial_resultado_inimigo) : "D20"));
    draw_set_color(c_white);

    if (disputa_inicial_estado == "aguardando_deck") {
        draw_set_color(c_yellow);
        draw_text(_ini_cx, _ini_cy + 25, "CLIQUE NO DECK PARA RECEBER SUAS CARTAS");
    } else if (disputa_inicial_estado == "distribuindo") {
        draw_text(_ini_cx, _ini_cy + 25, "Distribuindo a mão inicial...");
    } else if (disputa_inicial_estado == "preparando_dado") {
        draw_text(_ini_cx, _ini_cy + 25, "Preparando um novo D20 sobre a mesa...");
    } else if (disputa_inicial_estado == "aguardando_arremesso") {
        draw_set_color(c_yellow);
        draw_text(_ini_cx, _ini_cy + 25, "PEGUE O D20, MOVA E SOLTE PARA ARREMESSAR");
    } else if (disputa_inicial_estado == "rolando") {
        draw_text(_ini_cx, _ini_cy + 25, "Os dois D20 estão rolando...");
    } else if (disputa_inicial_estado == "resultado") {
        var _texto_resultado_ini = (disputa_inicial_resultado_jogador == disputa_inicial_resultado_inimigo)
            ? "EMPATE — NOVA ROLAGEM" : "O maior resultado escolhe quem começa";
        draw_text(_ini_cx, _ini_cy + 25, _texto_resultado_ini);
    } else if (disputa_inicial_estado == "escolha_jogador") {
        draw_set_color(c_yellow);
        draw_text(_ini_cx, _ini_cy + 18, "VOCÊ VENCEU. QUEM COMEÇA?");
        draw_set_color(c_black);
        draw_roundrect(_ini_cx - 215, _ini_cy + 55, _ini_cx - 15, _ini_cy + 105, false);
        draw_roundrect(_ini_cx + 15, _ini_cy + 55, _ini_cx + 215, _ini_cy + 105, false);
        draw_set_color(c_white);
        draw_roundrect(_ini_cx - 215, _ini_cy + 55, _ini_cx - 15, _ini_cy + 105, true);
        draw_roundrect(_ini_cx + 15, _ini_cy + 55, _ini_cx + 215, _ini_cy + 105, true);
        draw_text(_ini_cx - 115, _ini_cy + 80, "EU COMEÇO");
        draw_text(_ini_cx + 115, _ini_cy + 80, "INIMIGO COMEÇA");
    } else if (disputa_inicial_estado == "escolha_inimigo") {
        draw_set_color(c_red);
        draw_text(_ini_cx, _ini_cy + 25, "O INIMIGO VENCEU E ESTÁ ESCOLHENDO...");
    }

    draw_set_font(-1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
#endregion

#region Visão do Véu
if (visao_veu_ativa && instance_exists(visao_veu_origem) && !tutorial_ativo && !pausa_ativa) {
    var _veu_w = display_get_gui_width(); var _veu_h = display_get_gui_height();
    var _veu_cx = _veu_w / 2; var _veu_cy = _veu_h / 2;
    draw_set_alpha(0.78); draw_set_color(c_black); draw_rectangle(0, 0, _veu_w, _veu_h, false); draw_set_alpha(1);
    draw_set_color(c_black); draw_roundrect(_veu_cx - 300, _veu_cy - 165, _veu_cx + 300, _veu_cy + 185, false);
    draw_set_color(c_aqua); draw_roundrect(_veu_cx - 300, _veu_cy - 165, _veu_cx + 300, _veu_cy + 185, true);
    draw_set_halign(fa_center); draw_set_valign(fa_middle); draw_set_font(fnt_vitoria);
    draw_text(_veu_cx, _veu_cy - 135, "VISÃO DO VÉU"); draw_set_font(Fontenil); draw_set_color(c_white);
    draw_text(_veu_cx, _veu_cy - 112, "Mão inimiga revelada — clique numa armadilha para destruí-la");
    for (var i = 0; i < array_length(visao_veu_opcoes); i++) {
        var _revela_local = clamp((visao_veu_revelacao_timer - i * 7) / 12, 0, 1);
        if (_revela_local <= 0) continue;
        var _col = i mod 3; var _lin = floor(i / 3);
        var _x1 = _veu_cx - 270 + _col * 180; var _y1 = _veu_cy - 95 + _lin * 30;
        var _meia_revela = 85 * _revela_local;
        _x1 = _x1 + 85 - _meia_revela;
        draw_set_color(visao_veu_opcoes[i].armadilha ? c_maroon : make_color_rgb(45,45,45));
        draw_rectangle(_x1, _y1, _x1 + _meia_revela * 2, _y1 + 24, false);
        draw_set_color(visao_veu_opcoes[i].armadilha ? c_yellow : c_gray);
        draw_rectangle(_x1, _y1, _x1 + _meia_revela * 2, _y1 + 24, true);
        if (_revela_local > 0.58) draw_text_transformed(_x1 + _meia_revela, _y1 + 12, visao_veu_opcoes[i].nome, 0.34, 0.34, 0);
    }
    draw_set_color(c_black); draw_roundrect(_veu_cx - 190, _veu_cy + 125, _veu_cx + 190, _veu_cy + 170, false);
    draw_set_color(c_aqua); draw_roundrect(_veu_cx - 190, _veu_cy + 125, _veu_cx + 190, _veu_cy + 170, true);
    draw_set_color(c_white); draw_text(_veu_cx, _veu_cy + 147, "PROTEGER DA PRÓXIMA ARMADILHA");
    draw_set_font(-1); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white);
}
#endregion

#region Escolha de dano crítico
if (critico_escolha_ativa && is_struct(critico_contexto) && !tutorial_ativo && !pausa_ativa) {
    var _crit_largura = display_get_gui_width();
    var _crit_altura = display_get_gui_height();
    var _crit_cx = _crit_largura / 2;
    var _crit_cy = _crit_altura / 2;
    var _crit_qtd = critico_contexto.qtd_usada;
    var _crit_dado = critico_contexto.dado_usado;
    var _crit_nome = instance_exists(critico_contexto.atacante) ? critico_contexto.atacante.nome_carta : "Tropa";

    draw_set_alpha(0.74);
    draw_set_color(c_black);
    draw_rectangle(0, 0, _crit_largura, _crit_altura, false);
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_roundrect(_crit_cx - 285, _crit_cy - 155, _crit_cx + 285, _crit_cy + 150, false);
    draw_set_color(c_yellow);
    draw_roundrect(_crit_cx - 285, _crit_cy - 155, _crit_cx + 285, _crit_cy + 150, true);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_font(fnt_vitoria);
    draw_text(_crit_cx, _crit_cy - 105, "ACERTO CRÍTICO!");
    draw_set_font(Fontenil);
    draw_set_color(c_white);
    draw_text(_crit_cx, _crit_cy - 62, _crit_nome + " — escolha o dano original");

    draw_set_color(c_black);
    draw_roundrect(_crit_cx - 225, _crit_cy + 55, _crit_cx - 15, _crit_cy + 112, false);
    draw_roundrect(_crit_cx + 15, _crit_cy + 55, _crit_cx + 225, _crit_cy + 112, false);
    draw_set_color(c_white);
    draw_roundrect(_crit_cx - 225, _crit_cy + 55, _crit_cx - 15, _crit_cy + 112, true);
    draw_roundrect(_crit_cx + 15, _crit_cy + 55, _crit_cx + 225, _crit_cy + 112, true);
    draw_text(_crit_cx - 120, _crit_cy + 76, "DOBRAR OS DADOS");
    draw_text(_crit_cx - 120, _crit_cy + 96, string(_crit_qtd * 2) + "D" + string(_crit_dado));
    draw_text(_crit_cx + 120, _crit_cy + 76, "DOBRAR O RESULTADO");
    draw_text(_crit_cx + 120, _crit_cy + 96, string(_crit_qtd) + "D" + string(_crit_dado) + " × 2");

    draw_set_font(-1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
#endregion

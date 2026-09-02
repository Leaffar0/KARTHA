#region Indicadores da tropa selecionada
if (tropa_selecionada != noone && instance_exists(tropa_selecionada)) {
    var _selecionada = tropa_selecionada;
    var _pulso_selecao = 0.65 + sin(current_time / 110) * 0.25;
    var _meia_largura_selecao = global.CARTA_LARGURA * 0.28;
    var _meia_altura_selecao = global.CARTA_ALTURA * 0.28;

    // Moldura, nunca preenchimento: o círculo preenchido escondia a própria carta.
    draw_set_alpha(_pulso_selecao);
    draw_set_color(c_yellow);
    draw_roundrect(_selecionada.x - _meia_largura_selecao, _selecionada.y - _meia_altura_selecao,
        _selecionada.x + _meia_largura_selecao, _selecionada.y + _meia_altura_selecao, true);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_roundrect(_selecionada.x - _meia_largura_selecao - 2, _selecionada.y - _meia_altura_selecao - 2,
        _selecionada.x + _meia_largura_selecao + 2, _selecionada.y + _meia_altura_selecao + 2, true);

    var _posicao_frente = _selecionada.posicao_atual + direcao_avanco(_selecionada.dono);
    var _slot_frente = buscar_slot(_selecionada.lane_atual, _posicao_frente);
    var _na_posicao_assalto = _selecionada.posicao_atual == posicao_assalto(_selecionada.dono);
    var _pode_mover_visual = !_selecionada.moveu_este_turno && _selecionada.turnos_no_campo >= 1 && !_na_posicao_assalto;
    var _pode_atacar_visual = !_selecionada.atacou_este_turno && !(primeiro_turno_jogador);

    if (_slot_frente != noone) {
        var _cor_alvo = c_gray;
        var _texto_alvo = "BLOQUEADO";
        if (_slot_frente.ocupado && _slot_frente.carta_atual.dono != _selecionada.dono && _pode_atacar_visual) {
            _cor_alvo = c_red;
            _texto_alvo = "ATACAR";
        } else if (!_slot_frente.ocupado && _na_posicao_assalto && _pode_atacar_visual) {
            _cor_alvo = c_red;
            _texto_alvo = "ATACAR CASTELO";
        } else if (!_slot_frente.ocupado && _pode_mover_visual) {
            _cor_alvo = c_lime;
            _texto_alvo = (_selecionada.posicao_atual == posicao_ataque()) ? "AVANÇAR PARA ASSALTO" : "MOVER";
        }

        draw_set_alpha(0.25 + _pulso_selecao * 0.25);
        draw_set_color(_cor_alvo);
        draw_circle(_slot_frente.x, _slot_frente.y, 33, false);
        draw_set_alpha(1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_bottom);
        draw_set_color(_cor_alvo);
        draw_text_transformed(_slot_frente.x, _slot_frente.y - 38, _texto_alvo, 0.4, 0.4, 0);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
    draw_set_color(c_white);
}
#endregion

#region Menu contextual da carta
if (carta_menu_aberto != noone && instance_exists(carta_menu_aberto) && menu_escala > 0.01) {
	
    var _carta = carta_menu_aberto;
    var _opcoes = obter_opcoes_menu(_carta);
    var _n = array_length(_opcoes);
    
    var _largura_opcao = 100;
    var _altura_opcao = 20;
    var _espaco_opcao = 6;
    var _altura_total = _n * _altura_opcao + (_n - 1) * _espaco_opcao;
    
    var _base_x = _carta.x + (global.CARTA_LARGURA * 0.5);
	var _base_y = _carta.y - _altura_total/2;
    
    for (var i = 0; i < _n; i++) {
        var _opt_y = _base_y + i * (_altura_opcao + _espaco_opcao);
        var _centro_opt_y = _opt_y + _altura_opcao/2;
        
        // cresce a partir da esquerda (perto da carta), não do centro
        var _largura_atual = _largura_opcao * menu_escala;
        var _altura_atual = _altura_opcao * menu_escala;
        
        var _x1 = _base_x;
        var _y1 = _centro_opt_y - _altura_atual/2;
        var _x2 = _base_x + _largura_atual;
        var _y2 = _centro_opt_y + _altura_atual/2;
        
        var _opcao_indisponivel = string_pos("[", _opcoes[i]) > 0;
        draw_set_alpha(menu_escala);
        draw_set_color(c_black);
        draw_rectangle(_x1, _y1, _x2, _y2, false);
        draw_set_color(_opcao_indisponivel ? c_gray : c_white);
        draw_rectangle(_x1, _y1, _x2, _y2, true);
        
		// tooltip com o nome da habilidade, mostrado só quando o mouse está exatamente nesta opção
		if (i == opcao_hover_index && tooltip_escala > 0.01 && _opcoes[i] == "Habilidade") {
	    var _nome_habilidade = obter_nome_exibicao_habilidade(tem_habilidade_ativa(_carta))
    
	    var _tooltip_x_base = _base_x + _largura_opcao + 10;
	    var _tooltip_y_centro = _base_y + opcao_hover_index * (_altura_opcao + _espaco_opcao) + _altura_opcao/2;
    
	    var _largura_tooltip_final = string_width(_nome_habilidade) + 20;
	    var _altura_tooltip_final = 28;
    
	    var _largura_tooltip_atual = _largura_tooltip_final * tooltip_escala;
	    var _altura_tooltip_atual = _altura_tooltip_final * tooltip_escala;
    
	    var _tx1 = _tooltip_x_base;
	    var _ty1 = _tooltip_y_centro - _altura_tooltip_atual/2;
	    var _tx2 = _tooltip_x_base + _largura_tooltip_atual;
	    var _ty2 = _tooltip_y_centro + _altura_tooltip_atual/2;
    
	    draw_set_alpha(tooltip_escala);
	    draw_set_color(c_black);
	    draw_rectangle(_tx1, _ty1, _tx2, _ty2, false);
	    draw_set_color(c_yellow);
	    draw_rectangle(_tx1, _ty1, _tx2, _ty2, true);
    
    if (tooltip_escala > 0.7) {
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text((_tx1 + _tx2)/2, (_ty1 + _ty2)/2, _nome_habilidade);
    }
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_set_alpha(1);
}
		
        if (menu_escala > 0.7) {
		    draw_set_halign(fa_center);
		    draw_set_valign(fa_middle);
		    var _escala_texto_opcao = _opcao_indisponivel ? 0.32 : 0.5;
		    draw_text_transformed((_x1 + _x2)/2, (_y1 + _y2)/2, _opcoes[i], _escala_texto_opcao, _escala_texto_opcao, 0);
		}
        draw_set_alpha(1);
    }
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(-1)
}
#endregion

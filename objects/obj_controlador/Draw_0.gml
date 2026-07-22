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
        
        draw_set_alpha(menu_escala);
        draw_set_color(c_black);
        draw_rectangle(_x1, _y1, _x2, _y2, false);
        draw_set_color(c_white);
        draw_rectangle(_x1, _y1, _x2, _y2, true);
        
		// tooltip com o nome da habilidade, se o mouse estiver em cima da opção certa
		if (tooltip_escala > 0.01 && opcao_hover_index != -1 && opcao_hover_index < array_length(_opcoes) && _opcoes[opcao_hover_index] == "Habilidade") {
	    var _nome_habilidade = obter_nome_exibicao_habilidade(_carta.habilidade);
    
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
            draw_text((_x1 + _x2)/2, (_y1 + _y2)/2, _opcoes[i]);
        }
        draw_set_alpha(1);
    }
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
	draw_set_font(-1)
}
if (carta_menu_aberto != noone && instance_exists(carta_menu_aberto) && menu_escala > 0.01) {
	
    var _carta = carta_menu_aberto;
    var _opcoes = obter_opcoes_menu(_carta);
    var _n = array_length(_opcoes);
    
    var _largura_opcao = 80;
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
if keyboard_check_pressed(vk_escape){
	game_end()
	}



var _total = array_length(mao);
var _melhor_carta = noone;
var _menor_distancia = 999999;

for (var i = 0; i < _total; i++) {
    var _carta = mao[i];
    if (!instance_exists(_carta)) continue;
    if (_carta.arrastando) continue;
    if (!_carta.esta_na_mao) continue;
    if (_carta.travada) continue;
    
    var _dentro_y = (mouse_y >= _carta.y - _carta.sprite_height/2 - 40) 
                  && (mouse_y <= _carta.y + _carta.sprite_height/2);
    
    if (_dentro_y) {
        var _dist_x = abs(mouse_x - _carta.x);
        
        if (_dist_x < _carta.sprite_width/2 && _dist_x < _menor_distancia) {
            _menor_distancia = _dist_x;
            _melhor_carta = _carta;
        }
    }
}

hover_atual = _melhor_carta;

for (var i = 0; i < _total; i++) {
    var _carta = mao[i];
    if (!instance_exists(_carta)) continue;
    _carta.hover_ativo_externo = (_carta == hover_atual);
}

if (mouse_check_button_pressed(mb_left)) {
    if (hover_atual != noone && instance_exists(hover_atual) && !hover_atual.travada) {
      with (hover_atual) {
	    arrastando = true;
	    esta_na_mao = false;
	    rotacao_atual = 0;
	    escala_atual = 1;
	    y_offset_atual = 0;
    
	    if (slot_atual != noone) {
	        slot_atual.ocupado = false;
	        slot_atual.carta_atual = noone;
	        slot_atual = noone;
    }
}
    }
}
/*
// pega a posição do mouse relativa à JANELA (gui), não à room
var _mouse_gui_y = device_mouse_y_to_gui(0);

var _zona_scroll = 80; // quantos pixels da borda ativam o scroll
var _velocidade_scroll = 15;

if (_mouse_gui_y < _zona_scroll) {
    // mouse perto do topo: sobe a câmera (mostra o lado do inimigo)
    camera_y_alvo -= _velocidade_scroll;
} else if (_mouse_gui_y > (display_get_gui_height() - _zona_scroll)) {
    // mouse perto da base: desce a câmera (volta pro seu lado)
    camera_y_alvo += _velocidade_scroll;
}

// trava os limites (não deixa a câmera sair da room)
camera_y_alvo = clamp(camera_y_alvo, 0, room_height - altura_view);

// suaviza o movimento
camera_y += (camera_y_alvo - camera_y) * 0.1;

camera_set_view_pos(minha_camera, 0, camera_y);
*/
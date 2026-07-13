if keyboard_check_pressed(vk_escape){
	game_end()
	}

var _total = array_length(mao);
var _melhor_carta = noone;
var _menor_distancia = 999999;

// --- controla o preview ampliado (botão direito) ---
if (mouse_check_button_pressed(mb_right)) {
    if (carta_preview == noone && hover_atual != noone) {
        carta_preview = hover_atual;
    } else {
        carta_preview = noone; // clicar de novo com botão direito fecha
    }
}

// enquanto o preview está ativo, ignora todo o resto do Step (hover, clique, arrasto)
if (carta_preview != noone) {
    if (!instance_exists(carta_preview)) {
        carta_preview = noone;
    }
    exit;
}

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
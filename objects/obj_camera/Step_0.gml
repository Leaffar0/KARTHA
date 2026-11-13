var _preview_aberto = instance_exists(obj_livro) && obj_livro.preview_ativo;
_preview_aberto = _preview_aberto || (instance_exists(obj_controlador) && obj_controlador.carta_preview != noone);

_preview_aberto = _preview_aberto || mouse_sobre_historico();

var _meia_altura = view_hview[0] / 2;
var _limite_y = max(0, room_height - view_hview[0]);
var _mouse_tela_y = window_mouse_get_y();
if (!_preview_aberto) {
    var _scroll = mouse_wheel_down() - mouse_wheel_up();
    if (_scroll != 0) {
        if (!scroll_ativo) {
            // Parte da posição visível, inclusive quando o centro original
            // está além da borda da sala.
            y = clamp(y, _meia_altura, _meia_altura + _limite_y);
            scroll_alvo_y = y;
        }
        scroll_ativo = true;
        scroll_mouse_origem_y = _mouse_tela_y;
        scroll_alvo_y = clamp(scroll_alvo_y + _scroll * velocidade_scroll,
            _meia_altura, _meia_altura + _limite_y);
    } else if (scroll_ativo && abs(_mouse_tela_y - scroll_mouse_origem_y) >= 16) {
        // Ignora pequenos movimentos involuntários ao girar a roda.
        // Retoma o movimento original após deslocar o cursor na vertical.
        scroll_ativo = false;
    }

    if (scroll_ativo) {
        // Mantém o destino enquanto o mouse está parado, sem desfazer o scroll.
        y = lerp(y, scroll_alvo_y, suavidade_scroll);
        if (abs(y - scroll_alvo_y) < 0.1) y = scroll_alvo_y;
    } else {
        y = mouse_y;
        scroll_alvo_y = y;
    }
}

view_xview[0] = clamp(x - view_wview[0] / 2, 0, max(0, room_width - view_wview[0]));
view_yview[0] = clamp(y - _meia_altura, 0, _limite_y);

var _dt = min(delta_time / 1000000, 0.05);
tempo_visual += _dt;
if (fase == 0) {
    tempo = min(duracao_fechar, tempo + _dt);
    var _t = tempo / duracao_fechar;
    opacidade = _t * _t * (3 - 2 * _t);
    if (tempo >= duracao_fechar) fase = 1;
} else if (fase == 1) {
    // A tela já foi desenhada totalmente preta antes da troca.
    fase = 2;
    tempo = -duracao_pausa;
    room_goto(destino);
} else {
    tempo += _dt;
    var _t = clamp(tempo / duracao_abrir, 0, 1);
    opacidade = 1 - _t * _t * (3 - 2 * _t);
    if (_t >= 1) instance_destroy();
}

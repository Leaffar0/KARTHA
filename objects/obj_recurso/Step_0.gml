// O recurso entra voando a partir da carta e aterrissa suavemente no slot.
if (entrando_no_campo) {
    entrada_progresso += 1 / entrada_duracao;
    var _progresso = clamp(entrada_progresso, 0, 1);
    var _progresso_suave = _progresso * _progresso * (3 - (2 * _progresso));
    var _arco = sin(_progresso_suave * pi) * 42;

    x = lerp(entrada_origem_x, destino_x, _progresso_suave);
    y = lerp(entrada_origem_y, destino_y, _progresso_suave) - _arco;
    escala_animacao = lerp(0.62, 1, _progresso_suave) * (1 + sin(_progresso_suave * pi) * 0.08);
    alpha_animacao = lerp(0.35, 1, _progresso_suave);

    if (_progresso >= 1) {
        entrando_no_campo = false;
        x = destino_x;
        y = destino_y;
        escala_animacao = 1;
        alpha_animacao = 1;
        pulso_virada_timer = pulso_virada_duracao;
        tocar_som_variado("recurso", 0.30);
    }
}

// O estado de pagamento é imediato. O atraso pertence só ao desenho.
if (virado != virado_anterior) {
    virado_anterior = virado;
    toque_virada_pendente = virado;
    if (!virado) atraso_virada_visual = 0;
}
if (atraso_virada_visual > 0) {
    atraso_virada_visual--;
} else {
    var _rotacao_alvo = virado ? 90 : 0;
    rotacao_atual = lerp(rotacao_atual, _rotacao_alvo, 0.29);
    if (abs(_rotacao_alvo - rotacao_atual) < 2) {
        rotacao_atual = _rotacao_alvo;
        if (toque_virada_pendente) {
            toque_virada_pendente = false;
            pulso_virada_timer = pulso_virada_duracao;
            tocar_som_variado("recurso", 0.24);
        }
    }
}
if (pulso_virada_timer > 0) pulso_virada_timer--;

var _dt_bloqueio = min(delta_time/1000000,0.05);
if (bloqueado_turnos > 0) {
    if (bloqueio_visual_anterior <= 0 || bloqueado_turnos > bloqueio_visual_anterior)
        bloqueio_visual_entrada = 0;
    bloqueio_visual_turnos = bloqueado_turnos;
}
bloqueio_visual_anterior = bloqueado_turnos;
bloqueio_visual_entrada = min(1,bloqueio_visual_entrada+_dt_bloqueio/0.34);
bloqueio_visual_alpha = clamp(bloqueio_visual_alpha+_dt_bloqueio*(bloqueado_turnos>0?6:-4),0,1);

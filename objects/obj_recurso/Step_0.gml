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
    }
}

// Detecta tanto o pagamento de custo quanto o desvirar do início do turno.
if (virado != virado_anterior) {
    virado_anterior = virado;
    pulso_virada_timer = pulso_virada_duracao;
}

var _rotacao_alvo = virado ? 90 : 0;
rotacao_atual += (_rotacao_alvo - rotacao_atual) * 0.14;

if (pulso_virada_timer > 0) {
    var _pulso = pulso_virada_timer / pulso_virada_duracao;
    escala_animacao = max(escala_animacao, 1 + sin(_pulso * pi) * 0.08);
    pulso_virada_timer--;
}

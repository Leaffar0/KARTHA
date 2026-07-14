if (obj_controlador.vida_jogador <= 0 || obj_controlador.vida_inimigo <= 0) exit;
if (!travada || dono != "jogador") exit;
if (obj_controlador.fase == "ataque") {
    // nada por enquanto
} else if (obj_controlador.fase == "movimento") {
    if (!moveu_este_turno) {
        var _resultado = mover_tropa(id, 1);
        if (_resultado == "movido") {
            moveu_este_turno = true;
        }
    }
}
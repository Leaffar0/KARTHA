// obj_recurso não usa sprite/máscara no editor, então o evento de mouse pode
// ser recebido fora da imagem. Confere manualmente a área realmente desenhada.
if (dono != "jogador") exit;
if (obj_controlador.turno != "jogador") {
    mostrar_aviso_regra("Você poderá retirar o recurso no seu turno", x, y);
    exit;
}
if (obj_controlador.rolagens_pendentes > 0 || entrando_no_campo) exit;
if (bloqueado_turnos > 0) {
    mostrar_aviso_regra("Recurso bloqueado por " + string(bloqueado_turnos) + " turno(s)", x, y);
    exit;
}
if (obj_controlador.confirmacao_recurso_ativa) exit;

var _escala_clique = escala_recurso * max(1, escala_animacao);
var _meia_largura = sprite_get_width(sprite_index) * _escala_clique * 0.5;
var _meia_altura = sprite_get_height(sprite_index) * _escala_clique * 0.5;

// Quando está virado, largura e altura visuais também ficam invertidas.
if (abs(rotacao_atual) > 45) {
    var _troca_dimensao = _meia_largura;
    _meia_largura = _meia_altura;
    _meia_altura = _troca_dimensao;
}

if (!point_in_rectangle(mouse_x, mouse_y,
    x - _meia_largura, y - _meia_altura,
    x + _meia_largura, y + _meia_altura)) exit;

obj_controlador.recurso_pendente_retirada = id;
obj_controlador.confirmacao_recurso_ativa = true;

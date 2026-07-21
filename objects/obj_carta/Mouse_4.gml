if (!travada || dono != "jogador") exit;
if (obj_controlador.turno != "jogador") exit;
if (obj_controlador.rolagens_pendentes > 0) exit;

// clicar na mesma carta fecha o menu; clicar em outra troca pra ela
if (obj_controlador.carta_menu_aberto == id) {
    obj_controlador.carta_menu_aberto = noone;
} else {
    obj_controlador.carta_menu_aberto = id;
}
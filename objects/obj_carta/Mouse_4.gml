if (!travada || dono != "jogador") exit;
if (obj_controlador.turno != "jogador") exit;
if (obj_controlador.rolagens_pendentes > 0) exit;
if (!tropa_pode_agir(id)) exit; // <-- adiciona essa linha

if (obj_controlador.carta_menu_aberto == id) {
    obj_controlador.carta_menu_aberto = noone;
} else {
    obj_controlador.carta_menu_aberto = id;
}
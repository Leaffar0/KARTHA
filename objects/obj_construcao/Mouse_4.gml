if (!lado_controlado_localmente(dono)) exit;
if (obj_controlador.turno != dono) {
    mostrar_aviso_regra("A construção estará disponível no seu turno", x, y);
    exit;
}
if (obj_controlador.rolagens_pendentes > 0) {
    mostrar_aviso_regra("Aguarde a rolagem terminar", x, y);
    exit;
}
if (efeito_construcao == "hemodrenario") {
    if (obj_controlador.modo_partida == "online")
        online_enviar_acao("use_construction", { cardId: online_instance_id });
    else usar_habilidade_hemodrenario(id);
}

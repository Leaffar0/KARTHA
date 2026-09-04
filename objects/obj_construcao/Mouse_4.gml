if (dono != "jogador") exit;
if (obj_controlador.turno != "jogador") {
    mostrar_aviso_regra("A construção estará disponível no seu turno", x, y);
    exit;
}
if (obj_controlador.rolagens_pendentes > 0) {
    mostrar_aviso_regra("Aguarde a rolagem terminar", x, y);
    exit;
}
if (efeito_construcao == "hemodrenario") usar_habilidade_hemodrenario(id);

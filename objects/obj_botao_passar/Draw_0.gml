draw_self();

var _texto = "Concluir fase";
if (obj_controlador.rolagens_pendentes > 0) {
    _texto = "Aguardando dados";
} else {
    switch (obj_controlador.fase) {
        case "gerenciamento": _texto = "Ir para ataque"; break;
        case "ataque": _texto = "Concluir ataque"; break;
        case "movimento": _texto = "Concluir movimento"; break;
        case "compra": _texto = "Comprar carta"; break;
    }
}

draw_text(x - 55, y - 60, _texto);

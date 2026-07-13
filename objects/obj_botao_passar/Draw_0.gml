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

draw_set_font(fnt_botao)
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(x, y - 30, _texto);

draw_set_halign(-1);
draw_set_valign(-1);
draw_set_font(-1)
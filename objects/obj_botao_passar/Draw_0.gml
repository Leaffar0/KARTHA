draw_self();
draw_set_font(Fontenil);

var _texto = "Passar Turno";

if (obj_controlador.rolagens_pendentes > 0) {
    _texto = "Aguardando dados";
}

draw_set_font(fnt_botao);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(x, y - 30, _texto);
draw_set_halign(-1);
draw_set_valign(-1);
draw_set_font(-1);
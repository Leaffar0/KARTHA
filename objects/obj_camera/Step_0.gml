var _preview_aberto = instance_exists(obj_livro) && obj_livro.preview_ativo;

if (!_preview_aberto) {
    y = mouse_y;
}

view_xview[0] = clamp(x - view_wview[0] / 2, 0, room_width - view_wview[0]);
view_yview[0] = clamp(y - view_hview[0] / 2, 0, room_height - view_hview[0]);
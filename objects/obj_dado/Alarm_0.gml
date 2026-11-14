if (devolver_mao && !recolhendo) {
    recolhendo = true;
    recolher_tempo = 0;
    recolher_x = x;
    recolher_y = y;
    var _cam = view_camera[0];
    recolher_destino_x = camera_get_view_x(_cam) + camera_get_view_width(_cam)*0.5;
    recolher_destino_y = devolver_topo
        ? camera_get_view_y(_cam) - 100
        : camera_get_view_y(_cam) + camera_get_view_height(_cam) + 100;
    depth = -12000;
    exit;
}
show_debug_message("Dado id=" + string(id) + " terminou, vai chamar callback.");
if (callback != noone) {
    var _funcao = callback;
    _funcao(valor_final);
}
if (instance_exists(obj_controlador)) {
    obj_controlador.rolagens_pendentes = max(0, obj_controlador.rolagens_pendentes - 1);
    show_debug_message("-1 pendente (dado id=" + string(id) + "). Total: " + string(obj_controlador.rolagens_pendentes));
}
instance_destroy();

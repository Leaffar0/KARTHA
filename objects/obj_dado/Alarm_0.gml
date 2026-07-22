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
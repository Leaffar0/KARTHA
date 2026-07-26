if (callback != noone) {
    var _funcao = callback;
    _funcao(resultado_final);
}
if (instance_exists(obj_controlador)) {
    obj_controlador.rolagens_pendentes = max(0, obj_controlador.rolagens_pendentes - 1);
    debug_combate("-1 pendente (moeda id=" + string(id) + "). Total: " + string(obj_controlador.rolagens_pendentes));
}
instance_destroy();
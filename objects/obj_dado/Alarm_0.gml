if (callback != noone) {
    var _funcao = callback;
    _funcao(valor_final);
}

if (instance_exists(obj_controlador)) {
    obj_controlador.rolagens_pendentes = max(0, obj_controlador.rolagens_pendentes - 1);
}

instance_destroy();

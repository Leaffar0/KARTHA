atualizar_gravura_slot();
var _disponivel = false;
if (instance_exists(obj_tabuleiro)) {
    var _bases = obj_tabuleiro.gravura_bases;
    for (var i = 0; i < array_length(_bases); i++) {
        if (_bases[i].slot == id && _bases[i].motivo == "") {
            _disponivel = true;
            break;
        }
    }
}
gravura_disponivel = lerp(gravura_disponivel, _disponivel ? 1 : 0,
    1 - exp(-20 * min(delta_time / 1000000, 0.1)));

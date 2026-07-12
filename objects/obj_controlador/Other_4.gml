// Room Start: identifica a grade pelos slots vermelhos da room.
organizar_grade_batalha();

var _lista_construcao = [];
with (obj_slot_construcao) {
    array_push(_lista_construcao, id);
}

var _n = array_length(_lista_construcao);
for (var i = 0; i < _n - 1; i++) {
    for (var j = 0; j < _n - i - 1; j++) {
        if (_lista_construcao[j].x > _lista_construcao[j+1].x) {
            var _temp = _lista_construcao[j];
            _lista_construcao[j] = _lista_construcao[j+1];
            _lista_construcao[j+1] = _temp;
        }
    }
}

for (var i = 0; i < _n; i++) {
    _lista_construcao[i].lane = i;
}

// organiza os 6 slots de recurso automaticamente por posição X
var _lista_recursos = [];
with (obj_slot_recurso) {
    array_push(_lista_recursos, id);
}

var _n = array_length(_lista_recursos);
for (var i = 0; i < _n - 1; i++) {
    for (var j = 0; j < _n - i - 1; j++) {
        if (_lista_recursos[j].x > _lista_recursos[j+1].x) {
            var _temp = _lista_recursos[j];
            _lista_recursos[j] = _lista_recursos[j+1];
            _lista_recursos[j+1] = _temp;
        }
    }
}

for (var i = 0; i < _n; i++) {
    _lista_recursos[i].indice = i;
}
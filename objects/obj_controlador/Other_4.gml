// Room Start: identifica a grade pelos slots vermelhos da room.
organizar_grade_batalha();

// descobre a divisão vertical (mesma lógica do campo de batalha: metade de cima = inimigo, de baixo = jogador)
var _todos_y_recurso = [];
with (obj_slot_recurso) {
    if (array_get_index(_todos_y_recurso, y) == -1) array_push(_todos_y_recurso, y);
}
array_sort(_todos_y_recurso, true);

var _meio_recurso = _todos_y_recurso[floor(array_length(_todos_y_recurso) / 2)];

with (obj_slot_recurso) {
    dono = (y >= _meio_recurso) ? "jogador" : "inimigo";
}

var _todos_y_construcao = [];
with (obj_slot_construcao) {
    if (array_get_index(_todos_y_construcao, y) == -1) array_push(_todos_y_construcao, y);
}
array_sort(_todos_y_construcao, true);

var _meio_construcao = _todos_y_construcao[floor(array_length(_todos_y_construcao) / 2)];

with (obj_slot_construcao) {
    dono = (y >= _meio_construcao) ? "jogador" : "inimigo";
}

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
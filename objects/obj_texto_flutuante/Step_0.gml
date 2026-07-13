vida_texto += 1;

y -= velocidade_subida;
x += sin(vida_texto * 0.3) * oscilacao_intensidade * 0.1; // balanço leve pros lados

if (vida_texto >= vida_texto_max) {
    instance_destroy();
}
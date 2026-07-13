// move na direção definida, desacelerando com o tempo
x += lengthdir_x(velocidade_particula, direcao_movimento);
y += lengthdir_y(velocidade_particula, direcao_movimento);
velocidade_particula *= 0.92; // desacelera aos poucos

vida_particula -= 1;

// cresce um pouco enquanto se dissipa
var _progresso = 1 - (vida_particula / vida_particula_max);
image_xscale = lerp(escala_inicial, escala_final, _progresso);
image_yscale = image_xscale;

image_alpha = vida_particula / vida_particula_max; // vai sumindo (fade out)

if (vida_particula <= 0) {
    instance_destroy();
}
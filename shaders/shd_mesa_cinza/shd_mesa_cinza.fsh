varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main() {
    vec4 texel = texture2D(gm_BaseTexture, v_vTexcoord);
    float gray = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
    // Próximo do tom escuro original, com um leve clareamento neutro.
    // Preserva o contraste dos traços e a transparência do tabuleiro.
    float paper = min(1.0, gray * 1.06 + 0.07);
    gl_FragColor = vec4(vec3(paper), texel.a) * v_vColour;
}

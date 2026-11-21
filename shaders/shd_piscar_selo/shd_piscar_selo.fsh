varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform vec4 u_recorte;
uniform vec4 u_pixels;
uniform float u_fechamento;

void main() {
    vec2 tamanhoUV = u_recorte.zw - u_recorte.xy;
    vec2 px = u_pixels.xy + (v_vTexcoord - u_recorte.xy) / tamanhoUV * u_pixels.zw;
    // Aperta apenas a amêndoa. O losango e os espinhos ficam ancorados no couro.
    float lateral = 1.0 - smoothstep(6.0, 56.0, abs(px.x - 191.0));
    float altura = 27.0 * lateral;
    float abertura = altura * (1.0 - u_fechamento);
    float limite = altura + 16.0;
    float dy = px.y - 103.0;
    float d = abs(dy);
    float origem = d;
    if (d < abertura) origem = d * altura / max(abertura, 0.01);
    else if (d < limite) origem = mix(altura, limite, (d - abertura) / (limite - abertura));
    vec2 uv = v_vTexcoord + vec2(0.0, sign(dy) * (origem - d) * tamanhoUV.y / u_pixels.w);
    gl_FragColor = texture2D(gm_BaseTexture, uv) * v_vColour;
}

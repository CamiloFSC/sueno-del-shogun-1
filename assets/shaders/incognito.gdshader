shader_type canvas_item;
// Carta aún no obtenida: blanco y negro, muy borrosa y oscura.
uniform float radius = 0.030;

void fragment() {
	vec3 acc = vec3(0.0);
	float w = 0.0;
	for (int i = -3; i <= 3; i++) {
		for (int j = -3; j <= 3; j++) {
			vec2 o = vec2(float(i), float(j)) * radius / 3.0;
			acc += texture(TEXTURE, UV + o).rgb;
			w += 1.0;
		}
	}
	vec3 c = acc / w;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(vec3(g * 0.55 + 0.06), a);
}

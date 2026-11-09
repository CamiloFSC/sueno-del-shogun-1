shader_type canvas_item;
// Efecto holográfico: arcoíris que barre la carta, destello diagonal y chispas.
uniform float strength : hint_range(0.0, 1.0) = 0.5;
uniform vec2 tilt = vec2(0.5, 0.5);   // 0..1; se mueve con el ratón en el visor

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float t = TIME;
	float diag = UV.x * 0.9 + UV.y * 0.7 + (tilt.x - 0.5) * 0.9 - (tilt.y - 0.5) * 0.5;
	vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (diag * 1.4 + t * 0.10 + vec3(0.0, 0.33, 0.67)));
	float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float sweep = exp(-pow((fract(diag * 0.6 - t * 0.16) - 0.5) * 7.0, 2.0));
	vec2 g = floor(UV * vec2(64.0, 90.0));
	float h = fract(sin(dot(g, vec2(12.9898, 78.233))) * 43758.5453);
	float spark = step(0.988, h) * (0.5 + 0.5 * sin(t * 4.0 + h * 40.0));
	vec3 holo = rainbow * strength * (0.30 + 0.70 * lum) + vec3(sweep * 0.30) + vec3(spark * 0.9);
	COLOR = vec4(base.rgb + holo * base.a, base.a);
}

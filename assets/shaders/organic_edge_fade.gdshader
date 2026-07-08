// Dissolves one edge of a sprite into transparency with noise-distorted softness.
// Apply to individual tiles at biome boundaries:
//   top_fade    > 0 → tile fades transparent toward its top edge
//   bottom_fade > 0 → tile fades transparent toward its bottom edge
// UV.y maps to the sprite texture, so the fade zone is a fixed pixel band
// regardless of camera position.
shader_type canvas_item;

uniform float top_fade    : hint_range(0.0, 0.8) = 0.0;
uniform float bottom_fade : hint_range(0.0, 0.8) = 0.0;
uniform float noise_amount : hint_range(0.0, 0.3) = 0.06;
uniform float noise_scale  : hint_range(1.0, 30.0) = 8.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	float n = value_noise(UV * noise_scale + vec2(TIME * 0.018, 0.0));
	float dy = clamp(UV.y + (n - 0.5) * noise_amount, 0.0, 1.0);

	float alpha = 1.0;
	if (top_fade > 0.001) {
		alpha *= smoothstep(0.0, top_fade, dy);
	}
	if (bottom_fade > 0.001) {
		alpha *= 1.0 - smoothstep(1.0 - bottom_fade, 1.0, dy);
	}

	col.a *= alpha;
	COLOR = col;
}

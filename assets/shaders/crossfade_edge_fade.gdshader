// Crossfade edge fade: blends up to 3 stacked images by weight (w_a+w_b+w_c=1)
// into ONE opaque frame, THEN dissolves the bottom/top edge like
// organic_edge_fade. Used for Chrono Sea's crossfade positions.
//
// Why not just stack N alpha-animated sprites? Two alpha-blended layers do NOT
// compose to full opacity: at 0.5/0.5 the combined cover is 1-(1-.5)(1-.5)=0.75,
// so mid-dissolve the position goes ~25% transparent and the tile below bleeds
// through (a visible seam/ghost). A weighted MIX (weights sum to 1) stays fully
// opaque at every phase, so the crossfade is a clean dissolve.
shader_type canvas_item;

uniform float top_fade    : hint_range(0.0, 0.8) = 0.0;
uniform float bottom_fade : hint_range(0.0, 0.8) = 0.0;
uniform float noise_amount : hint_range(0.0, 0.3) = 0.10;
uniform float noise_scale  : hint_range(1.0, 30.0) = 5.0;

uniform sampler2D tex_b;
uniform sampler2D tex_c;
uniform float w_a = 1.0;   // weights of the three images, summing to 1.0
uniform float w_b = 0.0;
uniform float w_c = 0.0;

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
	// Weighted blend of the (color-matched) images -> one opaque frame.
	vec4 col = texture(TEXTURE, UV) * w_a
			 + texture(tex_b, UV)  * w_b
			 + texture(tex_c, UV)  * w_c;

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
	COLOR *= col;   // preserve sprite modulate (as organic_edge_fade does)
}

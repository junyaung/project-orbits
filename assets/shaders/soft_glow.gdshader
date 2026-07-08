shader_type canvas_item;
render_mode blend_add;

/// Poor-man's bloom: multi-tap blur of the sprite's own alpha, tinted warm-gold
/// and added under the crisp original (drawn by a second, un-shaded sprite on
/// top). Used for the Upper Sky "perfect sling" star-trail cue so it reads as
/// a soft magical glow rather than a flat cutout line.

uniform float glow_radius : hint_range(0.0, 0.05) = 0.018;
uniform float glow_strength : hint_range(0.0, 4.0) = 2.2;
uniform vec4 glow_tint : source_color = vec4(1.0, 0.86, 0.45, 1.0);

void fragment() {
	vec2 uv = UV;
	vec4 sum = vec4(0.0);
	const int TAPS = 8;
	for (int i = 0; i < TAPS; i++) {
		float a = float(i) / float(TAPS) * 6.28318530718;
		vec2 offset = vec2(cos(a), sin(a)) * glow_radius;
		sum += texture(TEXTURE, uv + offset);
	}
	sum /= float(TAPS);
	// also sample dead center so a thin line still contributes
	sum += texture(TEXTURE, uv) * 0.6;

	vec4 base_col = texture(TEXTURE, uv);
	float glow_a = clamp(sum.a * glow_strength, 0.0, 1.0);
	COLOR = vec4(glow_tint.rgb, glow_a * COLOR.a * glow_tint.a);
}

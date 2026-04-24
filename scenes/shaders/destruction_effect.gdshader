shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float seed : hint_range(0.01, 1.0) = 0.5;
uniform vec2 direction = vec2(-0.5, 0.0);
uniform float mask_vignette_strength : hint_range(0.0, 1.0) = 0.5;
uniform vec2 mask_vignette_center = vec2(0.5, 0.3);
uniform float time : hint_range(0.0, 5.0) = 0.0;

// From https://godotshaders.com/snippet/random-value/
float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
	// Add some vertex displacement based on strength
	VERTEX += vec2(
		random(UV * seed + time) * strength * 10.0,
		random(UV * seed * 2.0 + time) * strength * -5.0
	);
}

void fragment() {
	vec2 center = vec2(0.5);
	float circle_grad = 1.0 - distance(UV, center) * 3.0;
	vec2 offset = vec2(random(UV * seed), random(UV * seed));
	offset.x = clamp(offset.x, 0.0, 0.5);
	offset.y = clamp(offset.y, 0.0, 1.5);
	
	vec2 offset_uv = offset;
	offset_uv = offset_uv * strength + UV + direction * strength;
	
	float circle_clip = distance(UV, mask_vignette_center);
	COLOR = texture(TEXTURE, offset_uv);
	
	// Dissolve effect with vignette
	COLOR.a = (COLOR.a - clamp(offset.x * strength, 0.0, 3.0) - strength) - circle_clip * strength * mask_vignette_strength * 3.0;
	
	// Add some color shift during destruction
	if (strength > 0.5) {
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.6, 0.3), (strength - 0.5) * 0.6);
	}
}
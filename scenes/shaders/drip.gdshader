shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;
uniform sampler2D noise_texture: repeat_enable;
uniform vec4 water_color: source_color;
uniform float advance;
uniform float shrink: hint_range(0.0, 1.0, 0.01);
uniform vec2 texture_size;
uniform float brush_size;
uniform vec2 brush_position;

void fragment() {
	vec2 ratio = vec2(1.0, texture_size.y / texture_size.x);
	vec2 pixel_size = 1.0 / texture_size;
	vec2 shifted_uv = UV - vec2(0.0, (1.0 / texture_size.g) * advance);
	vec4 prev_frame;
	if (shifted_uv.y < 0.0) {
	    prev_frame = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
	    prev_frame = texture(screen_texture, shifted_uv);
		float center = texture(screen_texture, shifted_uv).b;
		float left   = texture(screen_texture, shifted_uv + vec2(-pixel_size.x, 0.0)).b;
		float right  = texture(screen_texture, shifted_uv + vec2(pixel_size.x, 0.0)).b;
		float shrink_alpha = step(0.1, center);
		if (left * right < 0.1) {
			if (texture(noise_texture, UV + TIME * shifted_uv.g).r < shrink * advance) {
				shrink_alpha = 0.0;
			}
		}
	
		prev_frame.rgb *= shrink_alpha;
	}
	
	vec2 uv_adjust = UV * ratio;
	float brush_dist = distance(uv_adjust, brush_position * ratio);
	float brush = step(brush_dist, brush_size / texture_size.r);
	COLOR = max(vec4(prev_frame.rgb, water_color.a * step(0.01, prev_frame.b)), vec4(water_color.rgb * brush, water_color.a * brush));
}

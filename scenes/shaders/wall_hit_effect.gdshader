shader_type canvas_item;

uniform float hit_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float hit_radius : hint_range(10.0, 100.0) = 30.0;
uniform vec2 hit_position = vec2(0.5, 0.5);
uniform float time_since_hit : hint_range(0.0, 2.0) = 0.0;
uniform vec4 hit_color : source_color = vec4(1.0, 0.3, 0.0, 1.0);
uniform float shake_intensity : hint_range(0.0, 10.0) = 2.0;
uniform float crack_intensity : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture : hint_default_black;

vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(dot(hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
                   dot(hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
               mix(dot(hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
                   dot(hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
    vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);
    
    // Screen shake effect
    if (hit_intensity > 0.0) {
        float shake = sin(TIME * 50.0 + uv.x * 10.0) * shake_intensity * hit_intensity * 0.002;
        uv.x += shake;
        uv.y += sin(TIME * 60.0 + uv.y * 12.0) * shake_intensity * hit_intensity * 0.002;
        tex_color = texture(TEXTURE, uv);
    }
    
    // Distance from hit position
    float dist = distance(UV, hit_position);
    
    // Hit flash effect
    float hit_effect = 0.0;
    if (hit_intensity > 0.0) {
        // Pulsing effect that fades over time
        float pulse = sin(TIME * 20.0) * 0.5 + 0.5;
        float fade = 1.0 - (time_since_hit / 2.0);
        
        // Create expanding circle effect
        float circle_effect = smoothstep(hit_radius * 0.01, 0.0, dist - time_since_hit * 50.0);
        hit_effect = circle_effect * hit_intensity * fade * pulse;
    }
    
    // Crack effect
    if (crack_intensity > 0.0 && dist < hit_radius * 0.01) {
        vec2 crack_uv = (UV - hit_position) * 10.0;
        float crack_noise = noise(crack_uv + TIME * 0.5);
        float cracks = step(0.8, abs(crack_noise));
        
        // Darken areas where cracks appear
        tex_color.rgb = mix(tex_color.rgb, vec3(0.3, 0.2, 0.1), cracks * crack_intensity);
    }
    
    // Combine effects
    vec3 final_color = mix(tex_color.rgb, hit_color.rgb, hit_effect);
    
    // Add particle dust effect around hit area
    if (hit_intensity > 0.0 && dist < hit_radius * 0.02) {
        float dust = noise(UV * 100.0 + TIME * 2.0);
        dust = smoothstep(0.7, 1.0, dust);
        final_color = mix(final_color, vec3(0.8, 0.7, 0.5), dust * hit_intensity * 0.3);
    }
    
    COLOR = vec4(final_color, tex_color.a);
}
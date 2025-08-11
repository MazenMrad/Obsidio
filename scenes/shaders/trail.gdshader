shader_type canvas_item;
render_mode blend_add;

uniform float time;          // No hint needed
uniform float flow_speed = 2.5;
uniform vec4 color_center : source_color = vec4(1.0, 0.6, 0.0, 1.0);
uniform vec4 color_tail : source_color = vec4(0.0, 0.7, 1.0, 0.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float alpha = tex.a;

    float pulse = 0.8 + 0.2 * sin(time * 5.0);

    float energy = abs(UV.x - 0.5);
    energy = smoothstep(0.0, 0.6, energy + 0.1 * sin((energy * 10.0) - time * 10.0));

    float glow = alpha * pulse * energy;

    float grad = 1.0 - abs(UV.x - 0.5) * 2.0;
    vec3 final_color = mix(color_tail.rgb, color_center.rgb, grad);

    COLOR = vec4(final_color * glow, glow);
}
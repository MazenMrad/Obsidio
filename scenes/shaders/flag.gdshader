shader_type canvas_item;

uniform float amplitude       : hint_range(0.0, 20.0) = 5.0;   // Controls the height of the wave.
uniform float frequency       : hint_range(-10.0, 10.0) = 3.0;  // Sets the number of waves (negative values flip the wave).
uniform float speed           : hint_range(0.0, 5.0) = 1.0;    // Adjusts how fast the wave moves.
// 'pole_side' indicates where the flag is attached (the wave is reduced there):
// 0 = Left, 1 = Right, 2 = Top, 3 = Bottom.
uniform int pole_side         = 0;
uniform float fixed_edge_range: hint_range(0.0, 1.0) = 0.2;    // Determines the area where the wave is damped.

void fragment() {
    vec2 distorted_uv = UV; // Start with the original UV coordinates.
    float wave;             // Will hold the calculated wave offset.
    float influence;        // Factor that reduces the wave effect near the pole.

    // For top or bottom pole attachments, the wave moves vertically.
    if (pole_side == 2 || pole_side == 3) {
        // Use UV.x to drive the wave calculation and apply the offset along y.
        wave = sin(UV.x * frequency + TIME * speed) * amplitude * 0.01;
        if (pole_side == 2) {
            // If the flag is attached at the top:
            // Reduce the wave effect near the top edge (UV.y near 1).
            influence = 1.0 - smoothstep(1.0 - fixed_edge_range, 1.0, UV.x);
        } else {
            // If the flag is attached at the bottom:
            // Reduce the wave effect near the bottom edge (UV.y near 0).
            influence = smoothstep(0.0, fixed_edge_range, UV.x);
        }
        // Apply the calculated vertical displacement.
        distorted_uv.y += wave * influence;
    } else {
        // For left or right pole attachments, the wave moves horizontally.
        // Use UV.y to drive the wave calculation and apply the offset along x.
        wave = sin(UV.y * frequency + TIME * speed) * amplitude * 0.01;
        if (pole_side == 0) {
            // If the flag is attached on the left:
            // Reduce the wave effect near the left edge (UV.x near 0).
            influence = smoothstep(0.0, fixed_edge_range, UV.y);
        } else {
            // If the flag is attached on the right:
            // Reduce the wave effect near the right edge (UV.x near 1).
            influence = 1.0 - smoothstep(1.0 - fixed_edge_range, 1.0, UV.y);
        }
        // Apply the calculated horizontal displacement.
        distorted_uv.x += wave * influence;
    }

    // Retrieve the texture color from the modified UV coordinates.
    vec4 tex_color = texture(TEXTURE, distorted_uv);

    // Discard pixels that are nearly transparent.
    if (tex_color.a < 0.1) {
        discard;
    }

    // Output the final color.
    COLOR = tex_color;
}

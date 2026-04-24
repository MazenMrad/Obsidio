shader_type canvas_item;

// Uniform parameters from both scripts
uniform float sensitivity : hint_range(0.0, 1.0) = 0.5;
const float edge_width = 0.13;
uniform sampler2D noise_texture : repeat_enable;
uniform int material_type : hint_range(0, 6) = 0;
uniform vec3 import_new_color;
uniform vec4 hit_tint : source_color = vec4(1.0, 0.2, 0.2, 1.0);
uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;

// Small tolerance value for color comparison
const float epsilon = 0.01;

// Function to compare colors with a small tolerance
bool compare_colors(vec4 c1, vec4 c2) {
    return abs(c1.r - c2.r) < epsilon && abs(c1.g - c2.g) < epsilon && abs(c1.b - c2.b) < epsilon && abs(c1.a - c2.a) < epsilon;
}

void fragment() {
    // Sample the original texture
    vec4 color = texture(TEXTURE, UV);

    // Check if the pixel is transparent
    if (color.a < 0.01) {
        // Output the pixel as is
        COLOR = color;
    }

    // Definitions from Paint Selector for original colors
    vec4 light_origin         = vec4(0.0, 1.0, 0.0, 1.0);
    vec4 normal_origin        = vec4(1.0, 1.0, 0.0, 1.0);
    vec4 normal_dark_origin   = vec4(1.0, 0.0, 0.0, 1.0);
    vec4 dark_origin          = vec4(1.0, 0.0, 1.0, 1.0);
    vec4 darker_dark_origin   = vec4(0.0, 1.0, 1.0, 1.0);
    vec4 darkest_origin       = vec4(0.0, 0.0, 1.0, 1.0);

    // Corresponding new colors based on import_new_color
    vec4 light_color          = vec4(import_new_color.rgb * 1.15, 1.0);
    vec4 normal_color         = vec4(import_new_color.rgb * 1.0, 1.0);
    vec4 normal_dark_color    = vec4(import_new_color.rgb * 0.92, 1.0);
    vec4 dark_color           = vec4(import_new_color.rgb * 0.7, 1.0);
    vec4 darker_dark_color    = vec4(import_new_color.rgb * 0.4, 1.0);
    vec4 darkest_color        = vec4(import_new_color.rgb * 0.2, 1.0);

    // Apply the color replacement
    if (compare_colors(color, light_origin)) {
        color = light_color;
    } else if (compare_colors(color, normal_origin)) {
        color = normal_color;
    } else if (compare_colors(color, normal_dark_origin)) {
        color = normal_dark_color;
    } else if (compare_colors(color, dark_origin)) {
        color = dark_color;
    } else if (compare_colors(color, darker_dark_origin)) {
        color = darker_dark_color;
    } else if (compare_colors(color, darkest_origin)) {
        color = darkest_color;
    }

    // Define the replace_color and edge_color based on material_type
    vec4 replace_color;
    vec4 edge_color;

    if (material_type == 0) {
        // Steel
        replace_color = vec4(0.68, 0.35, 0.24, 1.0); // Rust color
        edge_color    = vec4(0.4, 0.4, 0.4, 1.0);    // Edge color
    } else if (material_type == 1) { 
        // Aluminium
        replace_color = vec4(0.58, 0.58, 0.58, 1.0); // Aluminium color
        edge_color    = vec4(0.8, 0.8, 0.8, 1.0);    // Edge color
    } else if (material_type == 2) { 
        // Magnesium
        replace_color = vec4(0.61, 0.62, 0.63, 1.0); // Magnesium color
        edge_color    = vec4(0.5, 0.5, 0.5, 1.0);    // Edge color
    } else if (material_type == 3) { 
        // Titanium
        replace_color = vec4(0.51, 0.502, 0.478, 1.0); // Titanium color
        edge_color    = vec4(0.49, 0.48, 0.48, 1.0);   // Edge color
    } else if (material_type == 4) {
        // Plastic
        replace_color = vec4(0.21, 0.21, 0.21, 1.0); // Plastic color
        edge_color    = vec4(0.4, 0.4, 0.4, 1.0);    // Edge color
    } else if (material_type == 5) {
        // Carbon Fiber
        replace_color = vec4(0.24, 0.24, 0.24, 1.0); // Carbon Fiber color
        edge_color    = vec4(0.45, 0.45, 0.45, 1.0); // Edge color
    } else if (material_type == 6) {
        // Rubber
        replace_color = vec4(0.25, 0.25, 0.25, 1.0); // Rubber color
        edge_color    = vec4(0.22, 0.22, 0.22, 1.0); // Edge color
    }

    // Get the size of the texture in pixels
    float size_x = float(textureSize(TEXTURE, 0).x);
    float size_y = float(textureSize(TEXTURE, 0).y);

    // Create a new UV coordinate that snaps to pixel grid for pixel-perfect effect
    vec2 UVr = vec2(floor(UV.x * size_x) / size_x, floor(UV.y * size_y) / size_y);

    // Sample the noise texture at the UVr coordinates
    float noise_value = texture(noise_texture, UVr).r; // Assuming a grayscale noise texture

    // Define thresholds for smoothstep
    float edge_lower = sensitivity - edge_width;
    float edge_upper = sensitivity + edge_width;

    // Calculate the interpolation factor using smoothstep
    float factor = smoothstep(edge_lower, edge_upper, noise_value);

    // Interpolate between colors based on the factor
    // First, interpolate between replace_color and edge_color
    vec4 color1 = mix(replace_color, edge_color, factor);
    // Then, interpolate between color1 and the current color
    vec4 finalColor = mix(color1, color, factor);

    // Optional hit flash tint applied after dissolve shading.
    float hit_mix = clamp(hit_strength, 0.0, 1.0);
    vec3 hit_color = mix(finalColor.rgb, hit_tint.rgb, hit_mix);

    // Preserve the original alpha
    COLOR = vec4(hit_color, color.a);
}

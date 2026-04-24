shader_type canvas_item;

uniform float noise_scale : hint_range(1.0, 10.0) = 4.0;
uniform float vignette_strength : hint_range(0.1, 2.0) = 0.7;
uniform float sepia_strength : hint_range(0.0, 1.0) = 0.85;
uniform float contrast : hint_range(0.5, 2.0) = 1.2;

uniform float glow_range : hint_range(1.0, 30.0) = 12.0;    // 内发光范围(像素)
uniform float glow_strength : hint_range(0.0, 1.0) = 0.75;  // 内发光强度
uniform float glow_falloff : hint_range(0.5, 4.0) = 2.0;    // 衰减曲线，越大越集中在线条边
uniform float dirt_strength : hint_range(0.0, 1.0) = 0.4;   // 脏污强度
uniform float dirt_scale : hint_range(1.0, 100.0) = 8.0;     // 脏污大小

float rand(vec2 co) { return fract(sin(dot(co,vec2(12.9898,78.233)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(rand(i),rand(i+vec2(1,0)),f.x),mix(rand(i+vec2(0,1)),rand(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) {
    return noise(p)*0.5+noise(p*2.1)*0.25+noise(p*4.3)*0.125+noise(p*8.7)*0.063;
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (tex.a < 0.1) {
        COLOR = vec4(0.0);
    } else {
        vec2 px = TEXTURE_PIXEL_SIZE;

        // 找周围最近线条像素，计算内发光强度
        float closest = 1.0;
        vec3 nearestLineColor = vec3(0.0);
        float ga = 2.399963;
        for (int i = 0; i < 32; i++) {
            float r = sqrt(float(i + 1) / 32.0);
            float angle = float(i) * ga;
            // 噪声扰动采样角度，让发光边缘不规则
            float nOffset = fbm(UV * 10.0 + vec2(float(i) * 0.3)) * 1.5;
            vec2 offset = vec2(cos(angle + nOffset), sin(angle + nOffset)) * r * px * glow_range;
            vec4 s = texture(TEXTURE, UV + offset);
            if (s.a > 0.1) {
                float b = dot(s.rgb, vec3(0.333));
                if (b < 0.45) { // 线条像素
                    if (r < closest) {
                        closest = r;
                        nearestLineColor = s.rgb;
                    }
                }
            }
        }

        // 距离转发光强度，falloff控制衰减曲线
        float glowAmount = pow(1.0 - closest, glow_falloff) * glow_strength;
        // 噪声让发光强度不均匀，模拟墨水洇纸
        float glowNoise = fbm(UV * 15.0 + vec2(2.3, 5.1));
        glowAmount *= (0.6 + glowNoise * 0.8);
        glowAmount = clamp(glowAmount, 0.0, 1.0);

        vec3 col = tex.rgb;

        // 叠内发光：当前颜色向线条色混合
        col = mix(col, nearestLineColor, glowAmount);

        // 脏污效果：多层噪声叠加暗斑
        float dirt1 = fbm(UV * dirt_scale);
        float dirt2 = fbm(UV * dirt_scale * 2.3 + vec2(4.1, 2.7));
        float dirt3 = fbm(UV * dirt_scale * 0.5 + vec2(1.2, 8.3));
        float dirt = dirt1 * dirt2 * dirt3; // 三层相乘，只有都暗的地方才出现斑点
        col -= pow(dirt, 1.5) * dirt_strength;

        // 对比度
        col = (col - 0.5) * contrast + 0.5;

        // sepia
        float gray = dot(col, vec3(0.299, 0.587, 0.114));
        vec3 sepia = vec3(gray) * vec3(1.12, 0.95, 0.70);
        col = mix(col, sepia, sepia_strength);

        // 羊皮纸噪声
        float n  = fbm(UV * noise_scale);
        float n2 = fbm(UV * noise_scale * 2.5 + vec2(3.7, 1.9));
        col += (n  - 0.5) * 0.05;
        col += (n2 - 0.5) * 0.025;

        // 纸纹
        float lines = sin(UV.y * 500.0) * 0.015 + sin(UV.y * 180.0) * 0.007;
        col += lines;

        // 边缘压暗
        vec2 e = UV * (1.0 - UV);
        float vignette = pow(clamp(e.x * e.y * 16.0, 0.0, 1.0), vignette_strength);
        col *= vignette;

        COLOR = vec4(col, tex.a);
    }
}
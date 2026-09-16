#version 460 core
#include <flutter/runtime_effect.glsl>

// Ported from KeeTa's `blurry_fragment_horizontal/vertical.fsh` (9-tap gaussian),
// collapsed into a single cross-pass and driven by progress so an image can
// "focus in" from blurred (progress 0) to sharp (progress 1). Normalised so the
// total tap weight is 1.
precision highp float;

uniform vec2 uSize;
uniform float uProgress;      // 1 = sharp, 0 = max blur
uniform sampler2D uTex;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    float blur = 1.0 - clamp(uProgress, 0.0, 1.0);
    vec2 unit = (1.5 / uSize) * blur * 6.0;

    float w[5];
    w[0] = 0.2270270270;
    w[1] = 0.1945945946;
    w[2] = 0.1216216216;
    w[3] = 0.0540540541;
    w[4] = 0.0162162162;

    vec4 sum = texture(uTex, uv) * w[0];
    float total = w[0];
    for (int i = 1; i <= 4; i++) {
        vec2 hx = vec2(float(i), 0.0) * unit;
        vec2 vy = vec2(0.0, float(i)) * unit;
        sum += texture(uTex, uv + hx) * w[i];
        sum += texture(uTex, uv - hx) * w[i];
        sum += texture(uTex, uv + vy) * w[i];
        sum += texture(uTex, uv - vy) * w[i];
        total += 4.0 * w[i];
    }
    fragColor = sum / total;
}

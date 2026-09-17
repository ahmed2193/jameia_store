#version 460 core
#include <flutter/runtime_effect.glsl>

// Ported (simplified) from Jameia's `transform_fragment.fsh`: a progress-driven
// affine settle — the image scales from a slight zoom (1.08) down to 1.0 about
// its centre while its alpha ramps 0 -> 1. The Jameia Ken-Burns / image reveal.
precision highp float;

uniform vec2 uSize;
uniform float uProgress;      // 0 = hidden, 1 = fully settled
uniform sampler2D uTex;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    float p = clamp(uProgress, 0.0, 1.0);

    float scale = mix(1.08, 1.0, p);
    vec2 c = vec2(0.5);
    vec2 suv = (uv - c) / scale + c;

    if (suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0) {
        fragColor = vec4(0.0);
        return;
    }
    vec4 col = texture(uTex, suv);
    fragColor = vec4(col.rgb, col.a * p);
}

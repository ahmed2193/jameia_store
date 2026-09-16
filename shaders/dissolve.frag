#version 460 core
#include <flutter/runtime_effect.glsl>

// Ported from KeeTa's `alpha_fragment.fsh` (Meituan video-effects SDK):
// a straight cross-fade / dissolve between two textures driven by progress.
precision mediump float;

uniform vec2 uSize;
uniform float uProgress;      // 0 = from, 1 = to
uniform sampler2D uFrom;
uniform sampler2D uTo;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    float t = clamp(uProgress, 0.0, 1.0);
    vec4 a = texture(uFrom, uv);
    vec4 b = texture(uTo, uv);
    fragColor = mix(a, b, t);
}

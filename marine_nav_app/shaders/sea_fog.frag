#version 460 core

#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 uResolution;
uniform float uTime;
uniform float uFogDensity;
uniform vec3 uFogColor;
uniform float uNoiseAmplitude;
uniform float uNoiseSpeed;

out vec4 fragColor;

// Simplex noise
vec3 mod289(vec3 x) { return x - floor(x / 289.0) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x / 289.0) * 289.0; }
vec3 permute(vec3 x) { return mod289((x * 34.0 + 1.0) * x); }

float snoise(vec2 v) {
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                      -0.577350269189626, 0.024390243902439);
  vec2 i = floor(v + dot(v, C.yy));
  vec2 x0 = v - i + dot(i, C.xx);
  vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod289(i);
  vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
  vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
  m = m * m;
  m = m * m;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 a0 = x - floor(x + 0.5);
  m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
  vec3 g;
  g.x = a0.x * x0.x + h.x * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  float t = uTime * uNoiseSpeed;

  // Distance from center (boat position) — fog thicker at edges
  float distFromCenter = length(uv - vec2(0.5));

  // Layered noise for patchy fog
  float noise1 = snoise(uv * 3.0 + vec2(t, t * 0.7)) * uNoiseAmplitude;
  float noise2 = snoise(uv * 6.0 + vec2(-t * 0.5, t * 1.2)) * uNoiseAmplitude * 0.5;
  float patchiness = noise1 + noise2;

  // Exponential fog — denser at edges, patchy with noise
  float fogFactor = 1.0 - exp(-uFogDensity * (1.0 + patchiness) * (distFromCenter * 2.5 + 0.3));
  fogFactor = clamp(fogFactor, 0.0, 0.9);

  fragColor = vec4(uFogColor, fogFactor);
}

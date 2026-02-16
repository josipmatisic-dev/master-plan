#version 460 core

#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 uResolution;
uniform float uTime;
uniform float uIntensity;
uniform float uWindAngle;
uniform float uWindSpeed;
uniform vec3 uDropColor;
uniform float uPrecipType;  // 0.0=rain, 0.5=snow, 1.0=hail

out vec4 fragColor;

// Hash for pseudo-random
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D rotation
vec2 rotate2d(vec2 v, float a) {
  float s = sin(a);
  float c = cos(a);
  return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  float t = uTime;

  // Early out if no precipitation
  if (uIntensity < 0.01) {
    fragColor = vec4(0.0);
    return;
  }

  // Rotate UV by wind angle so drops fall in wind direction
  vec2 centeredUV = uv - 0.5;
  vec2 rotatedUV = rotate2d(centeredUV, uWindAngle) + 0.5;

  float totalAlpha = 0.0;

  // Layer count based on intensity (more layers = denser rain)
  int layers = int(mix(2.0, 6.0, uIntensity));

  for (int layer = 0; layer < 6; layer++) {
    if (layer >= layers) break;

    float layerSeed = float(layer) * 1.73;
    float layerDepth = 0.5 + float(layer) * 0.1;

    // Grid scale — closer layers have larger grid
    float gridScale = mix(15.0, 40.0, uIntensity) * layerDepth;
    vec2 gridUV = rotatedUV * gridScale;
    vec2 cell = floor(gridUV);
    vec2 localUV = fract(gridUV);

    // Per-cell random values
    float cellHash = hash(cell + layerSeed);
    float cellHash2 = hash(cell + layerSeed + 100.0);

    // Drop presence — not every cell has a drop
    float dropPresence = step(1.0 - uIntensity * 0.8, cellHash);

    if (dropPresence > 0.0) {
      // Drop horizontal position within cell
      float dropX = 0.3 + cellHash2 * 0.4;

      if (uPrecipType < 0.25) {
        // --- RAIN ---
        float dropSpeed = 1.0 + cellHash * 2.0 + uWindSpeed * 0.05;
        float dropY = fract(t * dropSpeed + cellHash * 6.28);

        // Streak shape
        float streakLen = mix(0.08, 0.25, uWindSpeed * 0.03 + cellHash * 0.5);
        float dx = abs(localUV.x - dropX);
        float dy = localUV.y - dropY;

        float xFalloff = smoothstep(0.015, 0.0, dx);
        float yFalloff = smoothstep(0.0, streakLen * 0.3, dy)
                       * smoothstep(streakLen, streakLen * 0.7, dy);

        float drop = xFalloff * yFalloff * uIntensity;
        totalAlpha += drop * layerDepth;

      } else if (uPrecipType < 0.75) {
        // --- SNOW ---
        float driftX = sin(t * 0.5 + cellHash * 6.28) * 0.1;
        float dropSpeed = 0.15 + cellHash * 0.15;
        float dropY = fract(t * dropSpeed + cellHash * 6.28);

        float dist = length(localUV - vec2(dropX + driftX, dropY));
        float flakeSize = 0.02 + cellHash2 * 0.02;
        float flake = smoothstep(flakeSize, flakeSize * 0.3, dist);

        totalAlpha += flake * uIntensity * 0.6 * layerDepth;

      } else {
        // --- HAIL ---
        float dropSpeed = 2.5 + cellHash * 1.5;
        float dropY = fract(t * dropSpeed + cellHash * 6.28);

        float dist = length(localUV - vec2(dropX, dropY));
        float hailSize = 0.015 + cellHash2 * 0.01;
        float hail = smoothstep(hailSize, hailSize * 0.2, dist);

        totalAlpha += hail * uIntensity * 1.2 * layerDepth;
      }
    }
  }

  totalAlpha = clamp(totalAlpha, 0.0, 0.7);

  // Background dimming for heavy rain
  float dimming = uIntensity * 0.15 * step(0.6, uIntensity);

  fragColor = vec4(uDropColor * totalAlpha + vec3(0.0) * dimming, totalAlpha + dimming);
}

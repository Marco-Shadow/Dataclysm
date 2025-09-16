shader_type canvas_item;
uniform vec4 color_deep : source_color = vec4(0.1, 0.0, 0.2, 1.0);  // Deep purple
uniform vec4 color_mid : source_color = vec4(0.3, 0.1, 0.4, 1.0);   // Mid purple
uniform vec4 color_accent : source_color = vec4(0.5, 0.2, 0.7, 1.0); // Accent purple
uniform float speed : hint_range(0.1, 1.0) = 0.2;
uniform float blur_amount : hint_range(1.0, 10.0) = 4.0;  // Controls how soft/blurry the gradients are
uniform float gradient_scale : hint_range(1.0, 5.0) = 2.5;  // Controls the scale of gradient areas
uniform float movement : hint_range(0.0, 1.0) = 0.4;     // Amount of subtle movement

// Simplex-inspired 2D noise function for smooth gradients
vec2 random2(vec2 p) {
    return fract(sin(vec2(
        dot(p, vec2(127.1, 311.7)),
        dot(p, vec2(269.5, 183.3))
    )) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Cubic Hermite curve for smoother interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    // Mix 4 corner values
    float a = dot(random2(i), f);
    float b = dot(random2(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(random2(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(random2(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
    
    return mix(
        mix(a, b, u.x),
        mix(c, d, u.x),
        u.y
    ) * 0.5 + 0.5; // Normalize to 0-1 range
}

// Fractional Brownian Motion for layered noise
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    // Add several noise layers with decreasing amplitude
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

void fragment() {
    // Get normalized UV and time
    vec2 uv = UV * 2.0 - 1.0;  // Center at (0,0) with range -1 to 1
    float time = TIME * speed;
    
    // Create movement vector based on time
    vec2 move = vec2(
        sin(time * 0.5) * movement,
        cos(time * 0.4) * movement
    );
    
    // Apply noise at different scales and movement speeds for a layered effect
    float layer1 = fbm((uv + move) * gradient_scale / blur_amount);
    float layer2 = fbm((uv - move * 0.7) * gradient_scale * 1.3 / blur_amount);
    float layer3 = fbm((uv + move * 1.3) * gradient_scale * 0.7 / blur_amount);
    
    // Combine layers with different weights for more interesting patterns
    float gradient = layer1 * 0.5 + layer2 * 0.3 + layer3 * 0.2;
    
    // Apply additional softening based on blur amount
    gradient = pow(gradient, 0.8 / (blur_amount * 0.1));
    
    // Create distance-based vignette effect
    float d = length(uv);
    float vignette = 1.0 - smoothstep(0.5, 1.2, d);
    
    // Combine effects for final color
    vec4 final_color = mix(color_deep, color_mid, gradient);
    
    // Add subtle accents to brighter areas
    final_color = mix(final_color, color_accent, pow(gradient, 2.0) * 0.4);
    
    // Add vignette darkening at edges
    final_color = mix(final_color, color_deep, 1.0 - vignette);
    
    // Add subtle overall pulsing
    final_color.rgb += vec3(0.05, 0.02, 0.08) * sin(time * 0.8) * (1.0 - d) * 0.3;
    
    COLOR = final_color;
}
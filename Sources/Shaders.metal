#include <metal_stdlib>
using namespace metal;

[[stitchable]] float2 ripple(
    float2 position,
    float  time,
    device const void *rippleDataRaw,
    int    rippleDataSize
) {
    device const float *data = (device const float *)rippleDataRaw;
    int count = rippleDataSize / 12; // 3 floats × 4 bytes each

    float2 disp = float2(0.0, 0.0);

    for (int i = 0; i < count; i++) {
        float2 center    = float2(data[i * 3], data[i * 3 + 1]);
        float  startTime = data[i * 3 + 2];
        float  age       = time - startTime;

        if (age <= 0.0 || age > 2.6) continue;

        float dist = distance(position, center);
        if (dist < 1.0) continue;

        // Wave physics
        float speed      = 380.0;   // px/s — wave propagation speed
        float wavelength = 26.0;    // px  — spatial frequency
        float amplitude  = 22.0;    // px  — max displacement

        float waveFront     = speed * age;
        float distFromFront = dist - waveFront;
        float reach         = wavelength * 3.5;

        if (abs(distFromFront) > reach) continue;

        float timeFade = exp(-age * 2.0);          // damps over time
        float distFade = exp(-dist * 0.0025);       // damps with distance
        float window   = 1.0 - smoothstep(0.0, reach, abs(distFromFront));
        float wave     = sin((distFromFront / wavelength) * M_PI_F * 2.0)
                       * amplitude * timeFade * distFade * window;

        disp += normalize(position - center) * wave;
    }

    return position + disp;
}

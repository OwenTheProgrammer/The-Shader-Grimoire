#pragma once
// Easing functions from https://easings.net/ optimized for graphics hardware by OwenTheProgrammer.
// Use this code as you wish, view https://github.com/OwenTheProgrammer/The-Shader-Grimoire license for legal
// All functions are assumed to have a working domain and range of 0 to 1 unless specified.

// MUL + SINCOS + ADD, r0.x
float easeInSine(float x)
{
	const float hpi = 1.57079632679;
	return 1 - cos(hpi * x);
}

// MUL + SINCOS, r0.x
float easeOutSine(float x)
{
	const float hpi = 1.57079632679;
	return sin(hpi * x);
}

// SINCOS + 2 MUL, r0.x
float easeInOutSine(float x)
{
	const float hpi = 1.57079632679;
	return pow(sin(hpi * x), 2);
}

// MUL, r0.x
float easeInQuad(float x)
{
	return x*x;
}

// ADD + MUL, r0.x
float easeOutQuad(float x)
{
	return (2 - x) * x;
}

// ADD + 2 MAD, r0.x
float easeInOutQuad(float x)
{
	x -= 0.5;
	return (x - x * abs(x)) * 2 + 0.5;
}

// 2 MUL, r0.x
float easeInCubic(float x)
{
	return x*x*x;
}

// ADD + MAD + MUL, r0.x
float easeOutCubic(float x)
{
	return x * ((x - 3) * x + 3);
}

// ADD + 3 MAD, r0.xy
float easeInOutCubic(float x)
{
	float f;
	x -= 0.5;
	f = 4 * abs(x) - 6;
	f = f * abs(x) + 3;
	return f * x + 0.5;
}

// 2 MUL, r0.x
float easeInQuart(float x)
{
	return x*x*x*x;
}

// ADD + MUL + MAD, r0.x
float easeOutQuart(float x)
{
	return 1 - pow(1-x, 4);
}

// ADD + 4 MAD, r0.xy
float easeInOutQuart(float x)
{
	float f;
	x -= 0.5;
	f = -8 * abs(x) + 16;
	f =  f * abs(x) - 12;
	f =  f * abs(x) + 4;
	return f * x + 0.5;
}

// 3 MUL, r0.x
float easeInQuint(float x)
{
	return x*x*x*x*x;
}

// ADD + MAD + 2 MUL, r0.xy
float easeOutQuint(float x)
{
	return 1 - pow(1-x, 5);
}

// ADD + 5 MAD, r0.xy
float easeInOutQuint(float x)
{
	float f;
	x -= 0.5;
	f = 16 * abs(x) - 40;
	f = f  * abs(x) + 40;
	f = f  * abs(x) - 20;
	f = f  * abs(x) + 5;
	return f * x + 0.5;
}

// MUL + EXP + MAD, r0.x
float easeInExpo(float x)
{
	const float S = 1.0 / 1023.0;
	return exp2(10 * x) * S - S;
}

// MUL + EXP + MAD, r0.x
float easeOutExpo(float x)
{
	const float S = 1024.0 / 1023.0;
	return -S * exp2(-10 * x) + S;
}

// I am calling this good enough after seven hours of work.
// LT + EXP + AND + 4 MAD, r0.xy
float easeInOutExpo(float x)
{
    x = x * 20 - 10;
    const float S = 512.0 / 1023.0;
    float m = 1 - 2 * float(x < abs(x));
    return (S - S * exp2(-abs(x))) * m + 0.5;
}

// MAD + SQRT + ADD, r0.x
float easeInCirc(float x)
{
	return 1 - sqrt(1 - x*x);
}

// ADD + MUL + SQRT, r0.x
float easeOutCirc(float x)
{
    return sqrt((2-x) * x);
}

// ADD + LT + SQRT + AND + 3 MAD, r0.xy
float easeInOutCirc(float x)
{
    x -= 0.5;
    float m = 1 - 2 * float(x < abs(x)); //sign(x)
    return sqrt(abs(x) - abs(x) * abs(x)) * m + 0.5;
}

// MAD + 2 MUL, r0.xy
float easeInBack(float x)
{
	x = 1 - x;
	return 1 - x * ((2.70158 * x - 6.40316) * x + 4.70158);
    //return x*x * (2.70158 * x - 1.70158);
}

// MUL + 2 MAD, r0.x
float easeOutBack(float x)
{
    return x * ((2.70158 * x - 6.40316) * x + 4.70158);
}

// Could probably do a little better
// MUL + 5 MAD, r0.xy
float easeInOutBack(float x)
{
    float v = 1 - 2 * x;
    const float4 K = float4(4.0949095, 16.379638, 14.379638, 21.569457);
    return K.x * (v * abs(v) - 1) + x * (K.y + x * (K.z * x - K.w));
}

// EXP + SINCOS + MUL + 2 MAD, r0.xy
float easeInElastic(float x)
{
    const float pi = 3.14159265359;
    const float hpi = pi * 0.5;
    const float S = (20.0 * pi)/3.0;
    const float M = 1024.0 / 513.0;
    const float B = 1.0 / 513.0;
    float f = exp2(10 * x - 10) * sin(S * x - hpi);
    return f * M - B;
}

// SINCOS + EXP + 2 MUL + 2 MAD, r0.xy
float easeOutElastic(float x)
{
    const float pi = 3.14159265359;
    const float hpi = pi * 0.5;
    const float S = (20.0 * pi)/3.0;
    const float B = 2048.0 / 2049.0;
    float f = exp2(-10 * x) * sin(S * x - hpi);
    return f * B + B;
}

// Hate this one. May revisit.
// SINCOS + EXP + LT + AND + 2 MUL + 4 MAD, r0.xyz
float easeInOutElastic(float x)
{
    const float pi = 3.14159265359;
    const float cosw = (4.0 * pi) / 9.0;
    const float M = -512.0/(sin(pi/18.0)-1024.0);
    const float B = 0.5;

    float v = 20 * x - 10;
    float m = 1 - 2 * float(v < abs(v)); //sign(v)
    float f = m * (1 - exp2(-abs(v)) * cos(cosw * v));
    return f * M + B;
}

// Because of the full 4 component count, I may revisit
// ADD + MAD + MUL + 2 MIN, r0.xyzw
float easeOutBounce(float x)
{
    const float4 BIAS = float4(0,6,9,10.5)/11.0;
    const float4 OFFSET = float4(0,12,15,15.75)/121.0;
    float4 p = (x - BIAS) * (x - BIAS) + OFFSET;
    return 7.5625 * min(min(p.x, p.y), min(p.z, p.w));
}

// Because of the full 4 component count, I may revisit
// ADD + 2 MAD + 2 MIN, r0.xyzw
float easeInBounce(float x)
{
    return 1 - easeOutBounce(1 - x);
}

// IADD + ITOF + MUL + 2 LT + 2 MIN + 3 MAD, r0.xyzw
float easeInOutBounce(float x)
{
    float v = 2 * x - 1;
    float f = sign(v) * easeOutBounce(abs(v));
    return f * 0.5 + 0.5;
}

// MIN + MAX + 2 ADD + 2 LOG + 2 EXP + 2 MAD + 2 MUL, r0.xy
float easeInOutNth(float x, float n)
{
    //x = saturate(x);
    float b = 2 * min(x, 0.5);
    float a = 2 - 2 * max(x, 0.5);
    return (pow(b, n) - pow(a, n)) * 0.5 + 0.5;
}
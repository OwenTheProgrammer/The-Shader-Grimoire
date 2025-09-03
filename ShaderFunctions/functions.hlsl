// Shader functions by OwenTheProgrammer
#ifndef OTP_SHADER_FUNCTIONS_INCLUDED
#define OTP_SHADER_FUNCTIONS_INCLUDED

// Extends a function _FN to work with float[2|3|4]
#define PROTO_F234(_FN) \
    float2 _FN(float2 v) { return float2(_FN(v.x), _FN(v.y)); } \
    float3 _FN(float3 v) { return float3(_FN(v.x), _FN(v.y), _FN(v.z)); } \
    float4 _FN(float4 v) { return float4(_FN(v.x), _FN(v.y), _FN(v.z), _FN(v.w)); }

// Modern sign function
float sgn(float x)
{
    #if SHADER_TARGET >= 35
    // bitwise ORs the sign bit of x, with the floating point memory of 1.0
    // requires integer support
    const uint F32_ONE = asuint((float)1);
    const uint F32_SGN = asuint((float)(-1)) & (~F32_ONE);
    return asfloat( (asuint(x) & F32_SGN) + F32_ONE );
#else
    return 1 - 2 * float(x < 0);
#endif //SHADER_TARGET 3.5+
}
PROTO_F234(sgn)

/* == TRIG FUNCTIONS == */

// Cotangent of x
float cot(float x)
{
    return cos(x) / sin(x);
}
PROTO_F234(cot)

// Secant of x
float sec(float x)
{
    return 1.0 / cos(x);
}
PROTO_F234(sec)

// Cosecant of x
float csc(float x)
{
    return 1.0 / sin(x);
}
PROTO_F234(csc)

/* == HYPERBOLIC TRIG FUNCTIONS == */

// Better implementation of hyperbolic tangent of x than tanh
float htan(float x)
{
    x = exp(x) * exp(x) + 1;
    return -2 / x + 1;
}
PROTO_F234(htan)

// Hyperbolic cotangent of x
float hcot(float x)
{
    x = exp(x) * exp(x) - 1;
    return 1 + 2 / x;
}
PROTO_F234(hcot)

// Hyperbolic secant of x
float hsec(float x)
{
    return 2.0 / (exp(x) + exp(-x));
}
PROTO_F234(hsec)

// Hyperbolic cosecant of x
float hcsc(float x)
{
    return 2.0 / (exp(x) - exp(-x));
}
PROTO_F234(hcsc)

/* == INVERSE HYPERBOLIC TRIG FUNCTIONS == */

// Inverse hyperbolic sine of x
float hasin(float x)
{
    return log(x + sqrt(x * x + 1));
}
PROTO_F234(hasin)

// Inverse hyperbolic cosine of x
// defined at x >= 1
float hacos(float x)
{
    return log(x + sqrt(x * x - 1));
}
PROTO_F234(hacos)

// Inverse hyperbolic tangent of x
// defined at abs(x) < 1
float hatan(float x)
{
    return 0.5 * (log(x + 1) - log(1 - x));
}
PROTO_F234(hatan)

// Inverse hyperbolic cotangent of x
// defined at abs(x) > 1
float hacot(float x)
{
    float s = sgn(x);
    return 0.5 * (log(x * s + s) - log(x * s - s));
}
PROTO_F234(hacot)

// Inverse hyperbolic secant of x
// defined at 0 < x <= 1
float hasec(float x)
{
    return log(1 + sqrt(1 - x * x)) - log(x);
}
PROTO_F234(hasec)

// Inverse hyperbolic cosecant of x
// defined at x != 0
float hacsc(float x)
{
    return log((sqrt(x * x + 1) * sgn(x) + 1) / x);
}
PROTO_F234(hacsc)

/* == EXOTIC FUNCTIONS == */

// Approximation of the error function erf(x) https://en.wikipedia.org/wiki/Error_function
// Error: min (-3.216649658274200e-4) max (3.216649658274200e-4) median: 4.42299e-19
float erf(float x)
{
    float w = x*(0.2006033923313427*x*x + 2.258650166982141);
    return 1 - 2 / (exp(w) + 1);
}
PROTO_F234(erf)

#undef PROTO_F234

#endif //OTP_SHADER_FUNCTIONS_INCLUDED

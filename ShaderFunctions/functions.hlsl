// Shader functions by OwenTheProgrammer

/* Approximation of the error function erf(x) https://en.wikipedia.org/wiki/Error_function */
/* Error: min (-3.216649658274200e-4) max (3.216649658274200e-4) median: 4.42299e-19  */
float erf(float x)
{
    float w = x*(0.2006033923313427*x*x + 2.258650166982141);
    return (exp(w) - 1.0) / (exp(w) + 1.0);
}
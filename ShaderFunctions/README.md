# Shader Functions

I work on/with shaders deeply and frequently. Often times I find myself either missing an implementation entirely, recreate the same function over and over again, or waste time making sure things are efficient.

[functions.hlsl](./functions.hlsl) will contain an open source list of random implementations I come up with, that you may or may not need for your shaders.

## Error Function Approximation

An approximation of the [Error function](https://en.wikipedia.org/wiki/Error_function) which is useful when integrating exponents.

```math
\large\mathrm{erf}(z) = \frac{2}{\sqrt{\pi}}\int_0^z{e^{-t^2}\:dt}
```

Here's [the details](./details/ErrorFunction.md) and here's [the implementation](./functions.hlsl#L5).
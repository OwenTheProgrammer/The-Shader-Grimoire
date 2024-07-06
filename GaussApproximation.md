# Gaussian approximation
While working on my lighting system ObjectGI, It came time in my life to finally squint your eyes for you; By that I mean blur.
Of course, the Gaussian blur equation is one of the most widely used out there as it models the contribution of each pixel as a uniform distribution 
across an area.. bla bla bla it do blur good. One problem, its quite heavy to compute and my math nerves were tingling, so I figured I should go through and try 
to optimize it!

Looking at the [Gaussian blur equation](https://en.wikipedia.org/wiki/Gaussian_blur#Mathematics)

```math
\large
    G(x) = \frac{1}{\sqrt{2\pi \sigma^2}} e^{-\frac{x^2}{2\sigma^2}}
```

We can see there are two main terms here. The first term is the inverse root and the second being the 
exponential part.

## The Inverse Square root (no, not quake.)
Lets first look at this part. The variable $\sigma$ labeled in orange, is the only non-constant. You can think of it as the "blur" amount or the sharpness of your blur function as it varies the distribution of the curve-blob.

$$
\large
\frac{1}{\sqrt{2\pi \textcolor{orange}{\sigma}^2}}
$$

Because we have the form $\frac{1}{\sqrt{A \times B^n}}$ we can seperate the square root into two square roots as follows.

$$
\large
\begin{split}
    \sqrt{xy} &= \sqrt{x}\sqrt{y} \\
    \frac{1}{\sqrt{2\pi \sigma^2}} &= \frac{1}{\sqrt{2\pi}\sqrt{\sigma^2}}
\end{split}
$$

Another property of square root $\sqrt{x^2} = |x|$ where the pipe symbols represent **the absolute of x or "abs(x)"** gives us

$$
\large
\frac{1}{\sqrt{2\pi} \times |\sigma|}
$$
>[!NOTE]
> This absolute can be ignored as you wouldnt ever really want a "negative blur" but its better to keep it around for later shader code reasons.


Now that we have removed the $\sigma$ term from the square root, we can apply a fraction rule to simplify.

$$
\large
\frac{\left(\frac{a}{b}\right)}{c} = \frac{a}{bc}, \quad\quad
\frac{1}{\sqrt{2\pi} \times |\sigma|} = 
\textcolor{orange}{
    \frac{\left(\frac{1}{\sqrt{2\pi}}\right)}{|\sigma|}
} = 
\frac{\left(\frac{1}{|\sigma|}\right)}{\sqrt{2\pi}}
$$

which gives us the final term

$$
\large
\frac{1}{\sqrt{2\pi \sigma^2}} = \frac{k}{|\sigma|}, \quad \text{where }
k = \frac{1}{\sqrt{2\pi}} \approx 0.39894...
$$


## The Exponential <strike>pain</strike>

Id like to preface this part with the fact that *I got lucky figuring this part out. Only now do I actually know why this works the way it does.*

With that out of the way, math!

$$
\LARGE
e^{-\frac{x^2}{2\textcolor{orange}{\sigma}^2}}
$$

THIS WAS SO MUCH HARDER THAN I THOUGHT IT WOULD BE. But lets start.

The first thing I did was evaluate on $\sigma = 1$ making our problem a little simpler

$$
\LARGE
e^{-\frac{x^2}{2}}
$$

Then I created a simpler polynomial function given the (x, y) turning points $\left[(-1, 0), (0, 1), (1, 0)\right]$

$$
\begin{split}
    f(x) &= \left(x + 1\right)\left(x + 1\right)\left(x - 1\right)\left(x - 1\right) \\
    &= \left(x + 1 \right)^2\left(x - 1\right)^2 \\
    &= \left(x^2 + 2x + 1\right)\left(x^2 - 2x + 1\right) \\
    &= x^4-2x^2+1 \\ 
    &= x^4-x^2-x^2+1 \\
    &= x^2\left(x^2-1\right)-\left(x^2-1\right) \\
    &= \left(x^2-1\right)\left(x^2-1\right)\\
    &= \left(x^2-1\right)^2
\end{split}
$$

The turning point of (0, 1) is an awesome property of the other turning points.
Perfect, but this goes outside of the range id like to use. I want it to be flat past $-1$ and $+1$ Thankfully, we can clamp the range and mirror it!

$$
    g(x) = f(\text{saturate}\left(|x|\right)) = f(\min\left(|x|, 1\right))
$$
>[!NOTE]
> saturate(x) is a cool graphics intrinsic that effectively clamps a value between 0 and 1.

The only problem with this is the fact that the turning points are at -1 and +1, while the exponential is 
not. Luckily, we can multiply $x$ by some constant $w$ to shift the turning points to best fit the function.

<p align="center" width="100%">
    <i>Now all we have to do is figure out what that constant term is.</i>
</p>
    <br>

Because the application of this function is the sum of a distribution, we care more about the function areas matching 
rather than the functions lining up with each other when graphed (although those are typically bijective.) 

meaning.. calculus. Okay here we go! put your smiles on people! :blush:

First of all, we have to get the integral of both functions. Lets start with the turning point curve.

$$
\begin{split}
    F(x, w) &= \int{\left(\left(wx\right)^2-1\right)^2}dx \\
    &= \int{w^4x^4-2w^2x^2+1} dx \\
    &= \int{w^4x^4}dx - \int{2w^2x^2}dx + \int{1}dx \\
    &= w^4\int{x^4}dx -2w^2\int{x^2}dx + 1\int{}dx \\
\end{split}
$$

<p align="center" width="100%">
<table><tr><td>

```math
\begin{split}
    1\int{dx} &= 1\int{x^0}\;dx \\
    1\left[ \frac{x^{0+1}}{0+1} \right] &= 1\left[ \frac{x^1}{1}\right] \\
    &= x
\end{split}
```

</td><td>

```math
\begin{split}
    &= -2w^2\int{x^2}dx \\
    &= -2w^2 \left[\frac{x^{2+1}}{2+1}\right] \\
    &= \frac{-2w^2x^3}{3} \\
\end{split}
```

</td><td>

```math
\begin{split}
    &= w^4\int{x^4}dx \\
    &= w^4 \left[\frac{x^{4+1}}{4+1}\right] \\
    &= \frac{w^4x^5}{5} \\
\end{split}
```

</td></tr></table>
</p>

$$
\begin{split}
    F(x, w) &= \frac{w^4x^5}{5}+\frac{-2w^2x^3}{3} + x + C \\
    &= \frac{15x + 3w^4x^5 - 10w^2x^3}{15} + C \\
\end{split}
$$

Since we are scaling $x$ by $w$, $x$ should be proportional to $w$. We'd want to remap $x$ onto $w$, so 
letting $x = \frac{1}{w}$ remaps the $x$ position $w$ to be $\frac{w}{w}$ or always 1. 

$$
\begin{split}
    F(\frac{1}{w}, w) &= \frac{15x + 3w^4x^5 - 10w^2x^3}{15} \\
    &= \frac{15\left(\frac{1}{w}\right) + 3\left(\frac{1}{w}\right)^4w^5 - \left(\frac{1}{w}\right)^2w^3}{15} \\
    &= \frac{8}{15w} \quad\text{lol}\\
\end{split}
$$

Alright! we know the area of a given range over our polynomial domain. Now all we have to do is the integral of the exponent.

$$
\LARGE
    \int{e^{-\frac{x^2}{2}}}dx
$$

And we can simply evaluate this with the [Gaussian integral](https://en.wikipedia.org/wiki/Gaussian_integral) with some wo-...

<p align="center" width="100%">
<img src="./GaussApproximation/me_rn.gif" width="256"/>
</p>

<p align="center" width="100%">
    Oh no... oh god no... I need the definite integral... <br>
    ...
</p>

OKAY so fun fact about Owen, he didnt go to school for this shit and he *definitely* doesnt know how to do THIS shit. Time to call up my side-chick Wolfram-alpha.

Here is the equation

$$
\large
    E(w) = \frac{\sqrt{\pi}\text{ erf}\left(\frac{1}{\sqrt{2}w}\right)}{\sqrt{2}}
$$

Now we can find the best value for our variable $w$ by taking the absolute difference of these integrals, meaning we are trying to 
find when $w$ approaches 0

$$
\large
    k = \underset{w \rightarrow 0^+}{\min} \bigl| E(w) - F(w) \bigr| = \underset{w \rightarrow 0^+}{\min} \biggl|
        \frac{\sqrt{\pi}\text{ erf}\left(\frac{1}{\sqrt{2}w}\right)}{\sqrt{2}} - \frac{8}{15w} \biggr|
$$

At this point, we have a convergence function that a computer can solve. I then used the following python code (still dont enjoy python)

```python
import math

# Constants
ROOT_TWO = math.sqrt(2.0)
ROOT_PI = math.sqrt(math.pi)

# Functions
E =     lambda w : ( ROOT_PI * math.erf(1.0 / (ROOT_TWO * w)) ) / ROOT_TWO
F =     lambda w : 8.0 / (15.0 * w)
eval =  lambda x : E(x) - F(x)

# Initial values (w=1 is arbitrarily within the domain range)
w_value = 1.0
w_step = 1e-8

# Regressive optimization search
for i in range(100000000):
    error = eval(w_value)
    w_value += w_step if error < 0 else -w_step

print(w_value)
```
Running this gives me this value which I will round
```cmd
/app # python run.py
0.4348782775218976
```

With this number, we are finally. finally. done. We can now use the value we just computed as a constant numerator to $\sigma$

$$
\large
\begin{split}
    g(x) &= \left(x^2-1\right)^2 \\
    f(x) &= g\left( \min\left( \frac{0.43488}{\sigma} |x|, 1 \right)\right) \\
\end{split}
$$

Finally, combining it all together, we get a fairly efficient-to-compute gaussian approximation with zero runtime square roots, average 2-4% error over the entire curve, and of course, faster kernel blurs.

<p align="center" width="100%">
<table>
    <tr><td>

```math
\LARGE
    \frac{1}{\sqrt{2\pi\sigma^2}} = \frac{\left(\frac{1}{\sqrt{2\pi}}\right)}{|\sigma|}
```

</td><td></td><td>

```math
\LARGE
    e^{-\frac{x^2}{2\sigma^2}} \;\approx\; 
\large
    \left(\min\left( \frac{0.43488 |x|}{\sigma}, 1\right)^2-1\right)^2
```

</td>
</tr>

</table>
</p>

```math
\LARGE
    \frac{1}{\sqrt{2\pi\sigma^2}}e^{-\frac{x^2}{2\sigma^2}} \quad\approx\quad 
    \Biggl|
    \large\frac{\left(\frac{1}{\sqrt{2\pi}}\right)}{\sigma}
    \Biggr|
    \cdot g\left(\min \left(\Biggl| \frac{0.43488x}{\sigma} \Biggr|, 1\right)\right)
```

<table><tr> <td>HLSL code:</td> <td>GLSL code:</td>
</tr>
<tr>
<td>

```hlsl
float gauss_approx(float x, float k) {
    float scale = (1/sqrt(2*UNITY_PI)) / k;
    float xpos = min(abs(0.43488 * x / k), 1);
    return abs(scale) * pow(xpos*xpos-1, 2);
}
```

</td><td>

```glsl
float gauss_approx(float x, float k) {
    const float M_PI = 3.14159265358979323846264338327950288;
    const float INV_SQRT_TWOPI = 1.0 / sqrt(2.0 * M_PI);
    const float W_TERM = 0.4348782775218976;
    
    float scale = INV_SQRT_TWOPI / k;
    float xpos = min(abs((W_TERM * x) / k), 1.0);
    return abs(scale) * pow(xpos*xpos-1.0, 2.0);
}
```

</td>
</tr>

<tr> <td>gauss_approx asm:</td><td> gauss asm: </td> </tr>

<tr>
<td>

```x86asm
   0: mul r0.x, v1.x, l(0.434880)
   1: div r0.x, r0.x, v1.y
   2: min r0.x, |r0.x|, l(1.000000)
   3: mad r0.x, r0.x, r0.x, l(-1.000000)
   4: mul r0.x, r0.x, r0.x
   5: div r0.y, l(0.398942), v1.y
   6: mul o0.xyzw, r0.xxxx, |r0.yyyy|
   7: ret 
```

</td><td>

```x86asm
   0: mul r0.x, v1.x, v1.x
   1: dp2 r0.y, v1.yyyy, v1.yyyy
   2: div r0.x, -r0.x, r0.y
   3: mul r0.x, r0.x, l(1.442695)
   4: exp o0.xyzw, r0.xxxx
   5: ret 
```

</td>
</tr>
</table>
</p>

And after all are hard work its-.. SLOWER?? WTF? welp. This comes as a massive plot point to the effort/outcome curve; I may have wasted my time this time in terms of what I was trying to accomplish, but I went down avenues I just wouldnt find myself in if I didnt *try* to do this. At the same time, theres a chance the code would have been better! If that was the case I dont think anyone would be complaining much.

Spending time on the basics can be a drag, but I feel like a lot of the time, stepping back and trying to think outside the box is worth the time it requires. (You reading this is proof of that, thanks for reading!)

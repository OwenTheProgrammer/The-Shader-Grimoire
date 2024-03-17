# The-Shader-Grimoire
A couple cursed, hyper-optimized or demonstrative shader things that will add me to your personal hit-list

# Table of Contents
* [Gaussian Blur Approximation](https://github.com/OwenTheProgrammer/The-Shader-Grimoire#gaussian-blur-approximation)
* [Inverse Functions](https://github.com/OwenTheProgrammer/The-Shader-Grimoire#inverse-functions)
  * [Full-Form Inverse (float2x2)](https://github.com/OwenTheProgrammer/The-Shader-Grimoire#full-form-inverse-float2x2)
* [Fast Noise Algorithms](https://github.com/OwenTheProgrammer/The-Shader-Grimoire#fast-noise-algorithms)
  * [QBit Noise](https://github.com/OwenTheProgrammer/The-Shader-Grimoire#qbit-noise)
  * [QBit Sparkles](https://github.com/OwenTheProgrammer/The-Shader-Grimoire#qbit-sparkles)

# Gaussian Blur Approximation
While working on my real time lighting system (Object GI), I was trying to approximate the gaussian equation for blur. This is that approximation and its surprisingly good.
<table>
 <tr> <td> Shader Code: </td> <td> Assembly Generated: </td> </tr>
<td>
 
```hlsl
float gaussianSample(float x, float k) {
    k = rcp(sqrt(UNITY_TWO_PI)) / k;
    x = saturate(k * abs(x));
    return abs(k) * pow(x*x-1, 2);
}
```
 
</td>
<td>

```hlsl
   0: div r0.x, l(0.398942), v1.y
   1: mul_sat r0.y, r0.x, |v1.x|
   2: mad r0.y, r0.y, r0.y, l(-1.000000)
   3: mul r0.y, r0.y, r0.y
   4: mul o0.xyzw, r0.yyyy, |r0.xxxx|
   5: ret 
```
 
</td>

<tr> <td> Original Gaussian: </td> <td> Approximation: </td> </tr>
<td>
 
![image](https://github.com/OwenTheProgrammer/The-Shader-Grimoire/assets/66239220/d9467017-93f2-444a-9116-6a8f90ea197a)

</td>
<td>

![image](https://github.com/OwenTheProgrammer/The-Shader-Grimoire/assets/66239220/02bcae44-f1c9-4961-b633-7c6c1db2a054)

 
</td>

</table>

## Inverse Functions
You need to undo the actions of a matrix? You're most likely after its inverse.

Imagine you're finding a point on a surface rotated and scaled in space. You could do the math with rotation and scale accounted for,
but often times it's simpler to realign the point back on the grid as if both weren't rotated in the first place. 

### Full-form Inverse (float2x2):
<table>
<tr> <td> Shader Code: </td> <td> Assembly Generated: </td> </tr>
<td>
  
```hlsl
float2x2 inverse(float2x2 A) {
    float2x2 adj = {
        +A._m11, -A._m01,
        -A._m10, +A._m00
    };
    return adj / determinant(A);
}
```

</td>
<td>
  
```hlsl
//A._m00_m01 -> cb0[2].xy
//A._m10_m11 -> cb0[3].xy
0: mul r0.x, cb0[2].y, cb0[3].x
1: mad r0.x, cb0[2].x, cb0[3].y, -r0.x
2: mul r1.xz, cb0[3].yyxy, l(1.0, 0.0, -1.0, 0.0)
3: mul r1.yw, cb0[2].yyyx, l(0.0, -1.0, 0.0, 1.0)
4: div r0.xyzw, r1.xyzw, r0.xxxx
5: dp2 o0.x, r0.xyxx, v1.xyxx
6: dp2 o0.y, r0.zwzz, v1.xyxx
```

</td>
</table>

## Fast Noise Algorithms

Noise without hearing coil wine from your graphics card suffering trig instructions, dot products of massive numbers, and enough bit shifts to shift your mom.

### QBit-Noise
Quick-Bitwise Noise, a simple conversion of your floats memory truncated to perfection and reinterpreted as a new float $\in \left[0, 1\right]$

<table>
<tr> <td> Shader Code: </td> <td> Assembly Generated: </td> </tr>
<td>

```hlsl
float bitNoise(float uvx) {
    static const uint2 kernel = uint2(163, 211);
    uint2 bytes = asuint(float2(uvx, _SinTime.y));
    uint reg = dot(kernel, bytes) & 255;
    return float(reg) / 255.0;
}
```
  
</td>
<td>

```hlsl
0: imul null, r0.x, cb0[1].y, l(211)
1: imad r0.x, l(103), v1.x, r0.x
2: and r0.x, r0.x, l(255)
3: utof r0.x, r0.x
4: mul o0.xyzw, r0.xxxx, l(0.003922, ...)
```

</td>
</table>

### QBit-Sparkles
A simple modification that only keeps the most activated pixel values, making it look like sparkle noise.

<table>
<tr>
  <td> Shader Code: </td> <td> Assembly Generated: </td>
</tr>
<td>
  
```hlsl
float bitSparkles(float uvx) {
    static const uint2 kernel = uint2(163, 211);
    uint2 bytes = asuint(float2(uvx, _SinTime.y));
    uint reg = dot(kernel, bytes) & 255;
    return float(reg / 255);
}
```

</td>
<td>

```hlsl
0: imul null, r0.x, cb0[1].y, l(211)
1: imad r0.x, l(163), v1.x, r0.x
2: and r0.x, r0.x, l(255)
3: udiv r0.x, null, r0.x, l(255)
4: utof o0.xyzw, r0.xxxx
```

</td>
</table>

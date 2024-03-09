# The-Shader-Grimoire
A couple cursed, hyper-optimized or demonstrative shader things that will add me to your personal hit-list

## Inverse Functions
You need to undo the actions of a matrix? You're most likely after its inverse.

Imagine you're finding a point on a surface rotated and scaled in space. You could do the math with rotation and scale accounted for,
but often times it's simpler to realign the point back on the grid as if both weren't rotated in the first place. 

### Full-form Inverse (float2x2):
<table>
<tr>
<td> Shader Code: </td> <td> Assembly Generated: </td>
</tr>

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

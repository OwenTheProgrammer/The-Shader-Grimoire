# The Dumping Grounds

It may seem like I've got all my quads in one basket, but truth be told, I'm as lazy as I am productive, $\sqrt{2}$% of the time.

When I come up with either a shader function, or a wacky way to do things, I ~~document them correctly and store them in a good place~~ DM the people I think will look at it, post it into servers I think will actually open discord for it, and move on with my day. If may have a horrible memory for the rest of my daily tasks, but when it comes to *that one time I made that one function, I know the exact time period and person to search through DMs for.*

I'm a little tired of rederiving these things, and a little tired of having to document them cleanly, so if you have any further questions, come find me.

I will try to keep things somewhat orderly, for all of tonight, and none of the future commits

# Table of Contents
<!-- mtoc-start -->

- [The Dumping Grounds](#the-dumping-grounds)
- [Table of Contents](#table-of-contents)
    - [Shader Shtuff](#shader-shtuff)
        - [Reconstruct Normals from Depth Texture](#reconstruct-normals-from-depth-texture)
        - [Basis View-plane Vectors from ScreenPos](#basis-view-plane-vectors-from-screenpos)
        - [Orthonormal Basis from 3D vectors](#orthonormal-basis-from-3d-vectors)
        - [Orthonormal Basis from 2D Axes](#orthonormal-basis-from-2d-axes)
        - [Vertical and Horizontal FOV from Inverse Projection](#vertical-and-horizontal-fov-from-inverse-projection)
        - [RGBA Channel Interpolation](#rgba-channel-interpolation)
        - [Inverse RGBA Channel Interpolation](#inverse-rgba-channel-interpolation)
        - [RGB888 to RGB565](#rgb888-to-rgb565)
        - [Worldspace scale from the Model Matrix](#worldspace-scale-from-the-model-matrix)
        - [Model Origin in View Space](#model-origin-in-view-space)
        - [Distance from Camera to Model Origin](#distance-from-camera-to-model-origin)
        - [Parameterized Curvy Line](#parameterized-curvy-line)
        - [Billboard Matrix Construction](#billboard-matrix-construction)
        - [Look-At Matrix (Y)](#look-at-matrix-y)
        - [2x2 Matrix Inverse](#2x2-matrix-inverse)
        - [Hue Shift via Chrominance Rotation](#hue-shift-via-chrominance-rotation)
        - [Old Bit Noise](#old-bit-noise)
        - [Calculate Shortest Angle Delta](#calculate-shortest-angle-delta)
    - [Approximations](#approximations)
        - [`1/3` Order Chebyshev Function `cos(acos(x)/3)`](#13-order-chebyshev-function-cosacosx3)
        - [Arc-cosine `acos(x)`](#arc-cosine-acosx)
        - [Arc-cosine `acos` again](#arc-cosine-acos-again)
        - [Atan2 Approximation](#atan2-approximation)
        - [Error function approximation](#error-function-approximation)
        - [Blackbody Kelvin to 2deg sRGB](#blackbody-kelvin-to-2deg-srgb)
    - [Anti-Aliasing](#anti-aliasing)
        - [A Single Quad](#a-single-quad)
        - [Terraced Steps](#terraced-steps)
    - [Quest Screen-Space Stuff](#quest-screen-space-stuff)
    - [Hilarious / Cursed things](#hilarious--cursed-things)
        - [Screen aspect ratio, from the Perspective matrix](#screen-aspect-ratio-from-the-perspective-matrix)
        - [I need the letter A!](#i-need-the-letter-a)

<!-- mtoc-end -->

## Shader Shtuff

### Reconstruct Normals from Depth Texture

Technically, I really should make a whole blog thing about how this one works, and I do plan to improve it further in the near future, but this is how I reconstruct normals from a depth texture. You get anti-aliasing of a hilarious MSAAx1 sample structure, since I sample a 3x3 grid pattern, but this is actually quite efficient to compute.
You can quite easily derive the basis vectors (tangent, bitangent) as well, since my method *solves the plane of best fit on 9 points* which is defined in terms of a basis xyz system.

> [!NOTE]
> The normals are reconstructed slightly skewed because the plane reconstruction uses Ordinary Least Squares (OLS) which minimizes vertical distances. At some point I will update this to use either Total Least Squares (TLS) or some closed form singular value decomposition which minimizes the projective distances, and is the more correct way of solving this problem.

```hlsl
float sampleRawDepth(float2 uv) { return SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(uv, 0, 0)); }

float3 reconstructViewNormal(float2 uv, out float raw_depth)
{
    float2 ts = _CameraDepthTexture_TexelSize.xy;
    #define T(x,y) sampleRawDepth(uv + ts * float2(x,y)).r
    float3x3 k = float3x3(
        T(-1, +1), T( 0, +1), T(+1, +1),
        T(-1,  0), T( 0,  0), T(+1,  0),
        T(-1, -1), T( 0, -1), T(+1, -1)
    );
    #undef T

    raw_depth = k._m11;

    float3 nx = float3(
        k._m00 - k._m02,
        k._m10 - k._m12,
        k._m20 - k._m22
    );
    float3 nz = float3(
        k._m00 + k._m01 + k._m02,
        k._m10 + k._m11 + k._m12,
        k._m20 + k._m21 + k._m22
    );

    float3 normal = float3(
        nx.x + nx.y + nx.z,
       -nz.x        + nz.z,
        nz.x + nz.y + nz.z
    );
    normal.xy *= _CameraDepthTexture_TexelSize.zw;
    return mul((float3x3)UNITY_MATRIX_I_V, normalize(normal));
}
```

Personally I use this macro instead lol
```hlsl
#define VIEWSPACE_NORMALS_FROM_DEPTH(_DEPTH_TEX, _UV, _NORMAL) \
    { \
        float2 ts = _DEPTH_TEX##_TexelSize.xy; \
        float3x3 k = float3x3( \
            SAMPLE_DEPTH_TEXTURE_LOD(_DEPTH_TEX, float4((_UV) + ts * float2(-1, +1), 0, 0)), \
            SAMPLE_DEPTH_TEXTURE_LOD(_DEPTH_TEX, float4((_UV) + ts * float2( 0, +1), 0, 0)), \
            SAMPLE_DEPTH_TEXTURE_LOD(_DEPTH_TEX, float4((_UV) + ts * float2(+1, +1), 0, 0)), \
            SAMPLE_DEPTH_TEXTURE_LOD(_DEPTH_TEX, float4((_UV) + ts * float2(-1,  0), 0, 0)), \
            SAMPLE_DEPTH_TEXTURE_LOD(_DEPTH_TEX, float4((_UV) + ts * float2( 0,  0), 0, 0)), \
            SAMPLE_DEPTH_TEXTURE_LOD(_DEPTH_TEX, float4((_UV) + ts * float2(+1,  0), 0, 0)), \
            SAMPLE_DEPTH_TEXTURE_LOD(_DEPTH_TEX, float4((_UV) + ts * float2(-1, -1), 0, 0)), \
            SAMPLE_DEPTH_TEXTURE_LOD(_DEPTH_TEX, float4((_UV) + ts * float2( 0, -1), 0, 0)), \
            SAMPLE_DEPTH_TEXTURE_LOD(_DEPTH_TEX, float4((_UV) + ts * float2(+1, -1), 0, 0)) \
        ); \
        float3 nx = float3( k._m00 - k._m02, k._m10 - k._m12, k._m20 - k._m22 ); \
        float3 nz = float3( k._m00 + k._m01 + k._m02, k._m10 + k._m11 + k._m12, k._m20 + k._m21 + k._m22 ); \
        float3 _normal = float3( nx.x + nx.y + nx.z, -nz.x + nz.z, nz.x + nz.y + nz.z ); \
        _normal.xy *= _DEPTH_TEX##_TexelSize.zw;  \
        _NORMAL = normalize(_normal);  \
    }
```

### Basis View-plane Vectors from ScreenPos

This constructs a basis coordinate system (x,y,z) from a screenspace position.
- The X vector (`i` in column 1) represents the "right" direction of the viewing plane
- The Y vector (`j` in column 2) represents the "forward" direction of the viewing plane
- The Z vector (`k` in column 3) points towards the camera, representing the view plane "up" vector

```hlsl
float3x3 screenToViewBasis(float2 screenPos)
{
    float2 vs = screenPos * 2 - 1;
    float2 p = vs * unity_CameraInvProjection._m00_m11;
    float3 k = -normalize(float3(p.xy, 1));
    float3 i = normalize(float3(-k.z, 0, k.x));
    float3 j = float3(-i.z * k.y, i.z * k.x - i.x * k.z, i.x * k.y);
    return transpose(float3x3(i, j, k));
}
```

As shown in this image, just with the vectors at the origin instead.
<p align="center">
    <img src="../_InternalAssets/dumping_grounds/media/basis_from_screenpos.png" width="50%"/>
</p>

> [!NOTE]
> This matrix is orthonormal as well, meaning its inverse is its transpose. The inverse would represent a transformation from the view-plane back to view coordinates.

### Orthonormal Basis from 3D vectors

If you have two 3D vectors, you can construct a 3D xyz basis system from them. Technically this is an extended version of the [Gram-Schmidt process](https://en.wikipedia.org/wiki/Gram%E2%80%93Schmidt_process).

Let's say you have a 3D vector $\vec{U}$ and another vector $\vec{V}$ which is non-collinear with the other one (they aren't directly in-line with each other)
we can normalize them to remove scale, let $\vec{u} = \vec{U} / \|\vec{U}\|$ and $\vec{v} = \vec{V} / \|\vec{V}\|$ where $\|\vec{x}\|$ represents the magnitude or "length" of $\vec{x}$.

If we treat $\vec{u}$ as the local $\hat{x}$ axis, and $\vec{v}$ as a rotated version of the $\hat{y}$ axis, we can construct a vector thats *orthogonal* (perpendicular) to both vectors, using the cross product.

$$
\vec{a} \times \vec{b} = \|\vec{a}\| \|\vec{b} \| \sin\left(\theta\right) \vec{n}
$$

where $\vec{n}$ is a vector perpendicular to both $\vec{u}$ and $\vec{v}$, and $\theta$ is the angle between the two vectors.

$$
\vec{u} \times \vec{v} = \sin\left(\theta\right)\vec{n}
$$

since we don't want $\sin\left(\theta\right)$ to scale our vector $\vec{n}$, we normalize the cross product.

$$
\vec{w} = \frac{\vec{u} \times \vec{v}}{\| \vec{u} \times \vec{v} \|}
$$

which gives us our basis $\hat{z}$ axis. Now that we have our basis $\hat{x}$ and $\hat{z}$ axis, we have to reconstruct the $\hat{y}$ axis, which is simply

$$
\vec{v}' = \vec{w} \times \vec{u} = \frac{\left(\vec{u} \times \vec{v}\right) \times \vec{u}}{\| \vec{u} \times \vec{v} \|}
$$

We can use a property of the cross product to simply this expression a bit:

$$
\begin{aligned}
\left(\vec{A} \times \vec{B} \right) \times \vec{C} &= \vec{B} \left( \vec{A} \bullet \vec{C} \right) - \vec{A} \left( \vec{B} \bullet \vec{C} \right) \\
&= \vec{B} \langle \vec{A}, \vec{C} \rangle - \vec{A} \langle \vec{B}, \vec{C} \rangle
\end{aligned}
$$

the second notation is for inner-product bracket notation enjoyers like me.

$$
\frac{ \left( \vec{u} \times \vec{v} \right) \times \vec{u} }{\| \vec{u} \times \vec{v} \|} = \frac{ \vec{v} \langle \vec{u}, \vec{u} \rangle - \vec{u} \langle \vec{v}, \vec{u}\rangle }{\| \vec{u} \times \vec{v} \|}
$$

so now we have:

$$
\begin{aligned}
\hat{x} &= \vec{u} &
\hat{y} &= \frac{ \vec{v} \langle \vec{u}, \vec{u} \rangle - \vec{u} \langle \vec{v}, \vec{u}\rangle }{\| \vec{u} \times \vec{v} \|} &
\hat{z} &= \frac{ \vec{u} \times \vec{v} }{\| \vec{u} \times \vec{v} \|}
\end{aligned}
$$

Let's do some analysis on the lengths to see if we can simplify a bit further.

We define $\vec{u}$ as the normaliezed vector of $\vec{U}$, so we know its length will always be 1, and same goes for $\vec{v}$.

$\vec{u} \times \vec{v}$ is the cross product between two normalized vectors, but those vectors aren't expected to be perpendicular to each other yet, so the $\sin\left(\theta\right)$ term will still affect scale here.

$\left(\vec{u} \times \vec{v}\right) \times \vec{u}$ will carry the scale of $\vec{u} \times \vec{v}$ along with it. This vector is, by definition, guaranteed to be perpendicular to $\vec{u}$, meaning the $\sin\left(\theta\right)$ term between
$\left(\vec{u} \times \vec{v}\right)$ and $\vec{u}$ will be equal to 1, since $\sin\left(90\degree\right) = 1$.

This implies the magnitude of $\left(\vec{u} \times \vec{v}\right) \times \vec{u}$ will have the same magnitude as $\vec{u} \times \vec{v}$, meaning

$$
\| \vec{u} \times \vec{v} \| = \|(\vec{u} \times \vec{v}) \times \vec{u} \| = \| \vec{v} \langle \vec{u}, \vec{u} \rangle - \vec{u} \langle \vec{v}, \vec{u} \rangle \|
$$

We can use this property to simplify what needs to be calculated

$$
\begin{aligned}
\hat{x} &= \frac{\vec{U}}{\|\vec{U}\|} &
\hat{y} &= \frac{\vec{v} \langle \hat{x}, \hat{x} \rangle - \hat{x} \langle \vec{v}, \hat{x}\rangle}{\| \vec{v} \langle \hat{x}, \hat{x} \rangle - \hat{x} \langle \vec{v}, \hat{x} \rangle \|} &
\hat{z} &= \hat{x} \times \hat{y}
\end{aligned}
$$

Furthermore, the dot product of $\langle \hat{x}, \hat{x} \rangle$ is the square magnitude of the normalized vector $\hat{x}$, meaning this will equal 1 every time, therefore we may omit it.
In the case of $\langle \vec{v}, \hat{x}\rangle$ however, we expect $\vec{v}$ to never be aligned with $\hat{x}$ since that would be a degenerate case, so we must keep it as is.
This doesn't change the fact that we *normalize* the $\hat{y}$ vector when calculating it though, so scalar terms will cancel out after normalization. $\hat{y}$ is the only time $\vec{v}$ is
used in computation, so normalizing $\vec{V}$ is insignificant here. We can separate the magnitude of $\vec{v}$ from the dot product $\langle \vec{v}, \hat{x} \rangle$ using the "scalar associative" property.

$$
\langle \vec{v}, \hat{x} \rangle = \langle \frac{\vec{V}}{\|\vec{V}\|}, \hat{x}\rangle = \frac{1}{\|\vec{V}\|} \langle \vec{V}, \hat{x} \rangle
$$

The fact that $\hat{y}$ is normalized after computation implies we can simply ignore the scalar term of $\vec{V}$, and use it as is.

$$
\begin{aligned}
\hat{x} &= \frac{\vec{U}}{\| \vec{U} \|} &
\hat{y} &= \frac{\vec{V} - \hat{x} \langle \vec{V}, \hat{x} \rangle}{\| \vec{V} - \hat{x} \langle \vec{V}, \hat{x} \rangle \|} &
\hat{z} &= \hat{x} \times \hat{y}
\end{aligned}
$$

Now we're at a pretty good point to implement this.

```hlsl
// Correct 3D cross product implementation, computing a x b
// since Unity redefines the cross() function to fit their left-handed coordinate system.
float3 cross3(float3 a, float3 b) {
    return a.yzx * b.zxy - a.zxy * b.yzx;
}

float3x3 vectorsToBasis(float3 u, float3 v)
{
    float3 xh = normalize(u);
    float3 yh = normalize(v - xh * dot(xh, v));
    float3 zh = cross3(xh, yh);
    return transpose(float3x3(xh, yh, zh));
}
```

Expanding our analysis a bit, we're constructing a 3x3 matrix with all columns perpendicular to each other, making this matrix an *orthogonal* matrix, making it a member of $O(3)$.
Since each column vector is of unit length as well, we graduate from *orthogonal* to *orthonormal*. With the determinant of this matrix always being 1 (not going to formally prove this here),
this matrix is a member of the [*special orthogonal group*](https://en.wikipedia.org/wiki/Orthogonal_group) or $SO(3)$

This means the inverse of the matrix is its transpose.

```hlsl
float3x3 vectorsToBasisInverse(float3 u, float3 v) {
    return transpose(vectorsToBasis(u, v));
}
```


### Orthonormal Basis from 2D Axes

Say you have vectors $\mathbf{a} = \left[\mathbf{a}_x, \mathbf{a}_y \right]^T$ and $\mathbf{b} = \left[\mathbf{b}_x, \mathbf{b}_y\right]^T$
and you want to rotate them such that $\mathbf{a}$ is aligned with the global X axis.
This is equivalent to finding the transformation to an "orthonormal basis" of $\mathbf{a}$ and $\mathbf{b}$.
Basically we want to tilt our head such that $\mathbf{a}$ is our new x-axis locally.
Mathematically speaking, we want

$$
\mathbf{R}\left(\theta\right)
\begin{bmatrix}
    \mathbf{a} & \mathbf{b}
\end{bmatrix} =
\begin{bmatrix}
    \cos(\theta) & -\sin(\theta) \\
    \sin(\theta) & \cos(\theta)
\end{bmatrix}
\begin{bmatrix}
    \mathbf{a}_x & \mathbf{b}_x \\
    \mathbf{a}_y & \mathbf{b}_y
\end{bmatrix} =
\begin{bmatrix}
    \| \mathbf{a} \| & \mathbf{b}'_x \\
    0 & \mathbf{b}'_y
\end{bmatrix}
$$

We can solve $\mathbf{a}'$ directly since rotations are scale-invariant operations, meaning the scale of vectors dont change when rotated.

$$
    \mathbf{R}\left(\theta\right)\left(\lambda \mathbf{x}\right) = \lambda \left(\mathbf{R}\left(\theta\right)\mathbf{x}\right)
$$

This implies $\mathbf{a}' = \|\mathbf{a}\| \hat{x}$ where $\hat{x}=\left[1, 0\right]^T$ representing the x-axis, and $\|\mathbf{a}\|$ is the magnitude or length of $\mathbf{a}$


Solving for $\mathbf{b}'$ requires a bit more work though. Rotations are angle-invariant as well, meaning angles between vectors are preserved when rotated.
This lets us define $\mathbf{b}'$ locally with respect to $\mathbf{a}'$ since we know $\mathbf{a}$ is our local x-axis.
Since $\angle\mathbf{ab}$ is the same as $\angle\mathbf{a}'\mathbf{b}'$, and $\mathbf{a}' = \|\mathbf{a}\|\hat{x}$, we can instead solve for

$$
\begin{aligned}
\mathbf{b}' &= \mathbf{R}\left(\angle\mathbf{ab}\right)\left( \|\mathbf{b}\| \hat{x} \right) \\
&=
\begin{bmatrix}
    \cos(\angle\mathbf{ab}) & -\sin(\angle\mathbf{ab}) \\
    \sin(\angle\mathbf{ab}) & \cos(\angle\mathbf{ab})
\end{bmatrix}
\begin{bmatrix}
    \|\mathbf{b}\| \\
    0
\end{bmatrix} \\
&=
\|\mathbf{b}\|
\begin{bmatrix}
    \cos(\angle\mathbf{ab}) \\
    \sin(\angle\mathbf{ab})
\end{bmatrix}
\end{aligned}
$$

Now all we have to do is compute the angle between $\mathbf{a}$ and $\mathbf{b}$

$$
\angle\mathbf{ab}
= \arccos\left(\frac{\mathbf{a} \bullet \mathbf{b}}{\|\mathbf{a}\|\|\mathbf{b}\|}\right)
= \arcsin\left(\frac{\mathbf{a} \times \mathbf{b}}{\|\mathbf{a}\|\|\mathbf{b}\|}\right)
$$

where $\bullet$ represents the vector dot product, and $\times$ represents the 2D vector cross product.

We can use which ever inverse cancels out which ever term in $\mathbf{b}'$ from before, to remove all trig functions.

$$
\begin{aligned}
\mathbf{b}' &= \|\mathbf{b}\|
\begin{bmatrix}
    \cancel{\cos}\left(\cancel{\arccos}\left(\frac{\mathbf{a} \bullet \mathbf{b}}{\|\mathbf{a}\|\|\mathbf{b}\|}\right)\right) \\
    \cancel{\sin}\left(\cancel{\arcsin}\left(\frac{\mathbf{a} \times \mathbf{b}}{\|\mathbf{a}\|\|\mathbf{b}\|}\right)\right)
\end{bmatrix} \\
&=
\cancel{\|\mathbf{b}\|}
\begin{bmatrix}
    \frac{\mathbf{a} \bullet \mathbf{b}}{\|\mathbf{a}\|\cancel{\|\mathbf{b}\|}} &
    \frac{\mathbf{a} \times \mathbf{b}}{\|\mathbf{a}\|\cancel{\|\mathbf{b}\|}}
\end{bmatrix}^T \\
&=
\frac{1}{\|\mathbf{a}\|}
\begin{bmatrix}
    \mathbf{a} \bullet \mathbf{b} &
    \mathbf{a} \times \mathbf{b}
\end{bmatrix}^T
\end{aligned}
$$

which gives us our final values

$$
\begin{aligned}
\mathbf{a}'_x &= \sqrt{\mathbf{a}_x^2 + \mathbf{a}_y^2}
&
\mathbf{a}'_y &= 0 \\
\mathbf{b}'_x &= \frac{\mathbf{a}_x \mathbf{b}_x + \mathbf{a}_y \mathbf{b}_y}{\sqrt{\mathbf{a}_x^2 + \mathbf{a}_y^2}}
&
\mathbf{b}'_y &= \frac{\mathbf{a}_x \mathbf{b}_y - \mathbf{b}_x \mathbf{a}_y}{\sqrt{\mathbf{a}_x^2 + \mathbf{a}_y^2}}
\end{aligned}
$$

More interestingly, because $\frac{x}{\sqrt{x}} = \sqrt{x}$ and $\mathbf{x} \times \mathbf{x} = 0$, we can form a more intuitive definition.

$$
\begin{aligned}
\mathbf{a}'_x &= \frac{\mathbf{a}_x^2 + \mathbf{a}_y^2}{\sqrt{\mathbf{a}_x^2 + \mathbf{a}_y^2}}
&
\mathbf{a}'_y &= \frac{\mathbf{a}_x\mathbf{a}_y - \mathbf{a}_y\mathbf{a}_x}{\sqrt{\mathbf{a}_x^2 + \mathbf{a}_y^2}} \\
\mathbf{b}'_x &= \frac{\mathbf{a}_x\mathbf{b}_x + \mathbf{a}_y\mathbf{b}_y}{\sqrt{\mathbf{a}_x^2 + \mathbf{a}_y^2}}
&
\mathbf{b}'_y &= \frac{\mathbf{a}_x\mathbf{b}_y - \mathbf{b}_x \mathbf{a}_y}{\sqrt{\mathbf{a}_x^2 + \mathbf{a}_y^2}}
\end{aligned}
$$

$$
\begin{aligned}
\mathbf{a}' &= \frac{1}{\|\mathbf{a}\|}
\begin{bmatrix}
    \mathbf{a} \bullet \mathbf{a} \\
    \mathbf{a} \times \mathbf{a}
\end{bmatrix}
&
\mathbf{b}' &= \frac{1}{\|\mathbf{a}\|}
\begin{bmatrix}
    \mathbf{a} \bullet \mathbf{b} \\
    \mathbf{a} \times \mathbf{b}
\end{bmatrix}
\end{aligned}
$$

Given

$$
\mathbf{a} \bullet \mathbf{b} =
\begin{bmatrix}
    \mathbf{a}_x & \mathbf{a}_y
\end{bmatrix}
\begin{bmatrix}
    \mathbf{b}_x \\
    \mathbf{b}_y
\end{bmatrix}
$$

and

$$
\mathbf{a} \times \mathbf{b} =
\begin{bmatrix}
    -\mathbf{a}_y & \mathbf{a}_x
\end{bmatrix}
\begin{bmatrix}
    \mathbf{b}_x \\
    \mathbf{b}_y
\end{bmatrix}
$$

we can represent this as a 2x2 matrix multiplication.

$$
\left(
\frac{1}{\|\mathbf{a}\|}
\begin{bmatrix}
    \mathbf{a}_x & \mathbf{a}_y \\
    -\mathbf{a}_y & \mathbf{a}_x
\end{bmatrix}
\right)
\begin{bmatrix}
    \mathbf{a}_x & \mathbf{b}_x \\
    \mathbf{a}_y & \mathbf{b}_y
\end{bmatrix}
$$

... Ah. yes. of course...
So fun fact, if you normalize a vector, it can be represented as $\left[\cos(\theta), \sin(\theta)\right]$..
Which the rotation matrix $\mathbf{R}\left(\theta\right)$ is completely constructed from $\mathbf{a}$, except with the opposite rotation..

Just goes to show, I am very good at missing things that are obvious, only after I've gone through the lengthy derivation.

heres the hlsl code lol

```hlsl
float2x2 worldToOrthogonal(float2 local_x) {
    float2 a = normalize(local_x);
    return float2x2(a.x, a.y, -a.y, a.x);
}

float2x2 localizeAxes2D(float2 a, float2 b) {
    return mul(worldToOrthogonal(a), transpose(float2x2(a, b)));
}
```



### Vertical and Horizontal FOV from Inverse Projection

```hlsl
float fov_v = 2 * atan(unity_CameraInvProjection._m11); // Vertical FOV (The default camera fov slider one)
float fov_h = 2 * atan(unity_CameraInvProjection._m00); // Horizontal FOV
```

### RGBA Channel Interpolation

If you want to store four independent textures in a single RGBA texture, you can treat a 2D texture as if it was a W x H x 4 3D texture, with each colour channel being a "layer".

```hlsl
float4 getChannelWeightsRGBA(float t)
{
    float4 rgba;
    rgba = float4(2,-4,6,-4) * t + float4(-4,12,-12,4);
    rgba = rgba * t + float4(+6,-12,+6,0);
    rgba = rgba * t + float4(-4,+4,0,0);
    return rgba * t + float4(1,0,0,0);
}
```

Then you can sample the texture colour channels as a 3D texture, like this

```hlsl
float3 samplePacked3D(sampler2D tex, float3 uvw) {
    return dot(tex2D(tex, uvw.xy), getChannelWeightsRGBA(frac(uvw.z)));
}
```

### Inverse RGBA Channel Interpolation

If you want to determine the t value for the [RGBA Channel Interpolation](#rgba-channel-interpolation) you can do so with any of these functions.

> [!NOTE]
> There is a singularity at t=0 and t=1

```hlsl
float inverseRGBAChannelWeights(float4 weights)
{
    return sqrt(weights.a) / (sqrt(weights.a) + sqrt(weights.g));
}
float inverseRGBAChannelWeights(float4 weights)
{
    return (2 * weights.b) / (2 * weights.b + 3 * weights.g);
}
float inverseRGBAChannelWeights(float4 weights)
{
    return (3 * weights.a) / (3 * weights.a + 2 * weights.b);
}
```

### RGB888 to RGB565

I computed the conversion between rgb565 and rgb888 through brute-force searching which didnt take all that long. Every possible state a colour could be in will resolve perfectly to the same result you'd get if you converted to doubles and rounded. Both conversions become two integer instructions `imad, ushr`

```hlsl
uint3 rgb888_to_rgb565(uint3 color)
{
    uint4 K = uint4(0x0F9, 0x1FA, 0x3F6, 0x3F2);
    uint3 rgb565 = (color * K.xyx + K.zwz) >> 11;
    return rgb565;
}
```

```hlsl
uint3 rgb565_to_rgb888(uint3 color)
{
    uint4 K = uint4(0x20F, 0x103, 0x017, 0x021);
    uint3 rgb888 = (color * K.xyx + K.zwz) >> 6;
    return rgb888;
}
```

### Worldspace scale from the Model Matrix

```hlsl
float3 getModelScale()
{
    return float3(
        length(unity_ObjectToWorld._m00_m10_m20),
        length(unity_ObjectToWorld._m01_m11_m21),
        length(unity_ObjectToWorld._m02_m12_m22)
    );
}
```

```hlsl
float3 getInverseModelScale()
{
    return float3(
        length(unity_WorldToObject._m00_m10_m20),
        length(unity_WorldToObject._m01_m11_m21),
        length(unity_WorldToObject._m02_m12_m22)
    );
}
```

### Model Origin in View Space

If you want the pivot position of your model in viewspace (-1 to 1 on the screen) you can use these

```hlsl
// [-1 | +1] view space position of the world space pivot position
half2 getPivotViewPos()
{
    // Get the mesh pivot position in view space
    float3 vs_pivotPos = UNITY_MATRIX_MV._m03_m13_m23;

    // Remove the camera FOV, scaling to [-d | +d]
    vs_pivotPos.xy *= unity_CameraProjection._m00_m11;

    // Scale down by the distance from the camera to the pivot [-1 | +1]
    return vs_pivotPos.xy / vs_pivotPos.z;
}
// [-1 | +1] view space position of a given world space coordinate
half2 getPivotViewPos(float4 pivotPos)
{
    // Transform world space position into view space
    float3 vs_pivotPos = mul(UNITY_MATRIX_V, pivotPos);

    // Remove the camera field-of-view, scaling to [-d | +d]
    vs_pivotPos.xy *= unity_CameraProjection._m00_m11;

    // Scale down by the distance from the camera to the pivot [-1 | +1]
    return vs_pivotPos.xy / vs_pivotPos.z;
}
half2 getPivotViewPos(float3 pivotPos)
{
    return getPivotViewPos(float4(pivotPos, 1));
}
```

### Distance from Camera to Model Origin

You can get the distance from the camera to the pivot position of your model in world space, by simply invoking the wrath of linear algebra.

```hlsl
// Returns the distance from the camera to the world space pivot position
float getPivotDistance()
{
    return abs(UNITY_MATRIX_MV._m23);
}
float getPivotDistance(float4 pivotPos)
{
    return abs(mul(UNITY_MATRIX_V, pivotPos).z);
}
float getPivotDistance(float3 pivotPos)
{
    return getPivotDistance(float4(pivotPos, 1));
}
```

### Parameterized Curvy Line

Random, I know, but if you need the position of a curvy line from point `a` to `b`, given a parameter t, then I've got just the function for you.

```hlsl
float2 p = lerp(a, b, smoothstep(0, 1, t));
p.y += t - smoothstep(0, 1, t);
```

### Billboard Matrix Construction

```hlsl
float3x3 bbMatrix = (float3x3)UNITY_MATRIX_I_V; // Inverse view is your cameras rotation
float3 pivot = unity_ObjectToWorld._m03_m13_m23; // World space model origin
float3 vpos = mul(bbMatrix, i.vertex.xyz) + pivot; // Rotate backwards, move to position
o.vertex = UnityWorldToClipPos(vpos);
```

### Look-At Matrix (Y)

```hlsl
// 2D cross product (the determinant)
float crs(float2 a, float2 b)
{
    return a.x * b.y - a.y * b.x;
}

float3x3 lookAt_Y(float2 cam_pos, float2 obj_fwd)
{
    float dt = dot(cam_pos, obj_fwd); // dot(A,B) = |A| * |B| * cos(theta)
    float ct = crs(cam_pos, obj_fwd); // A x B = |A| * |B| * sin(theta)
    return float3x3(
         dt,  0.0, crs,
        0.0,  1.0, 0.0,
        -crs, 0.0, dt
    )
}
```

Which can be used to make a quad billboard around the Y axis

```hlsl
// Get the model origin relative to the camera position
float3 pivotPos = unity_ObjectToWorld._m03_m13_m23;
float3 camPivotPos = pivotPos - _WorldSpaceCameraPos;

// Only care about the XZ plane for rotation
float3 objFwd = unity_ObjectToWorld._m02_m12_m22;
float2 camDir = normalize(camPivotPos.xz);
float2 fwd = normalzie(objFwd.xz);

// Create a rotation matrix (Y) that looks towards the camera
float3x3 look = lookAt_Y(camDir, fwd);

// Apply the rotation-to-camera on the vertex, essentially doing T(RS(R)) = T(RSR)
float3 vpos = mul(look, i.vertex.xyz);

o.vertex = UnityObjectToClipPos(vpos);
...
```

### 2x2 Matrix Inverse

Want to undo the actions of a `float2x2` matrix? You're after the matrix inverse.

```hlsl
float2x2 inverse(float2x2 M) {
    return float2x2(M._m11, -M._m01, -M._m10, M._m00) / determinant(M);
}
```

### Hue Shift via Chrominance Rotation

```hlsl
// Hue shift by transforming rgb to a chroma rotatable domain (YIQ), rotate chroma, then convert back to rgb
// percent: 0 would be 0% hue shift, 1 would be 360 degree rotation
float3 hueShift( float3 color, float percent) {
    // https://en.wikipedia.org/wiki/YIQ#From_RGB_to_YIQ
    const float3x3 rgb_to_yiq = float3x3(
        0.2990,  0.5870,  0.1140,
        0.5959, -0.2746, -0.3213,
        0.2115, -0.5227,  0.3112
    );
    // https://en.wikipedia.org/wiki/YIQ#From_YIQ_to_RGB
    const float3x3 yiq_to_rgb = float3x3(
        1.0,  0.956,  0.619,
        1.0, -0.272, -0.647,
        1.0, -1.106,  1.703
    );

    // Scale the angle from 0-1 to 0-2pi
    // which is the cycle length of sin and cos
    const float tau = 6.28318530718;
    float theta = percent * tau;

    // Convert the colour to the yiq colour system
    float3 yiq = mul(rgb_to_yiq, color);

    // Rotate around the x axis (IQ plane)
    // This rotates the chrominance plane / hue shifts
    float s = sin(theta), c = cos(theta);
    float3x3 rotor = float3x3(
        1, 0,  0,
        0, c, -s,
        0, s,  c
    );
    float3 yiq_new = mul(rotor, yiq);

    // Convert back to RGB
    return mul(yiq_to_rgb, yiq_new);
}
```

### Old Bit Noise

I believe these were from the very first commit of this project, they're a little dated but I don't see any reason to *get rid* of them.

```hlsl
float bitNoise(float uvx) {
    static const uint2 kernel = uint2(163, 211);
    uint2 bytes = asuint(float2(uvx, _SinTime.y));
    uint reg = dot(kernel, bytes) & 255;
    return float(reg) / 255.0;
}
```

```hlsl
float bitSparkles(float uvx) {
    static const uint2 kernel = uint2(163, 211);
    uint2 bytes = asuint(float2(uvx, _SinTime.y));
    uint reg = dot(kernel, bytes) & 255;
    return float(reg / 255);
}
```

### Calculate Shortest Angle Delta

Ever found yourself currently at 30 degrees and you want to be at 300?

$$
\begin{aligned}
    \Delta &= \theta_{\text{new}} - \theta_{\text{old}} \\
    \theta &= \bmod\left(\theta_{\text{old}} + t \cdot \Delta, 2\pi\right) && \text{or lerp}\left(\theta_{\text{old}}, \Delta, t\right)
\end{aligned}
$$

Of course you rotate 270 degrees around the- no.
you rotate -90 degrees! but.. how?

well the real answer in radians is

$$
\begin{aligned}
    \Delta &=
    \bmod\left(\theta_{\text{new}} - \theta_{\text{old}} \textcolor{blue}{ + \pi}, 2\pi\right) \textcolor{blue}{ - \pi} \\
    &= \mathrm{frac}\left(\frac{1}{2\pi} x - \frac{1}{2}\right) \cdot 2\pi - \pi
\end{aligned}
$$

```hlsl
// Calculates the shortest angle delta
float calculate_angle_delta(float from_rad, float to_rad) {
    return frac(INV_TWO_PI * x - 0.5) * TWO_PI - PI;
}
...
float dt = calculate_angle_delta(old_angle, target_angle);
float angle = lerp(old_angle, dt, some_time_step);
...
```


## Approximations

### `1/3` Order Chebyshev Function `cos(acos(x)/3)`

Computing the cosine of one-third arccosine of x is a weird one, and you'll probably never need it.. but I needed it so here it is.

I used good ol mathematica to find the best suited `w` exponent
```mathematica
f[x_] := Cos[ArcCos[x]/3];
g[x_, w_] := Power[(x + 1) / 2, w] * 1/2 + 1/2;

NMinimize[
  NIntegrate[ (f[x] - g[x, w])^2, {x, -1, 1}],
  0 <= w <= 1, w
]

> {4.7357216555478056`*^-6,{w->0.45596877882443965`}}
```

$$
\cos\left(\frac{\arccos(\theta)}{3}\right) \approx \frac{\left(\theta + 1\right)^w}{2^{w+1}} + \frac{1}{2} \quad w = 0.45596877
$$

and in shader code

```hlsl
// Approximation of cos(acos(x)/3)
float ccinv1_3(float x) {
    return pow(x + 1, 0.45596877) * 0.36451024 + 0.5;
}
```

### Arc-cosine `acos(x)`

I've made a decent approximation of the `acos` function. The built-in implementation of `acos` is an approximation as well, just FYI.

```hlsl
// Approximation of inverse cosine
// Range x [-1, 1] y [0, pi]
// Max error: ±0.0060123 at ±0.29297
float acos_approx(float x) {
  float t = sqrt(1 - abs(x)) * (abs(x) * -0.1677666 + 1.5707964);
  return (x < 0 ? -1 : 1) * (t - 1.5707964) + 1.5707964;
}
```

I think this took roughly a week and a half by the way.
Here is the comparison to the normal `acos` implementation

The normal acos implementation:
```hlsl
 acos: r0.xyzw
   0: mad r0.x, |v1.x|, l(-0.018729), l(0.074261)
   1: mad r0.x, r0.x, |v1.x|, l(-0.212114)
   2: mad r0.x, r0.x, |v1.x|, l(1.570729)
   3: add r0.y, -|v1.x|, l(1.000000)
   4: sqrt r0.y, r0.y
   5: mul r0.z, r0.y, r0.x
   6: mad r0.z, r0.z, l(-2.000000), l(3.141593)
   7: lt r0.w, v1.x, -v1.x
   8: and r0.z, r0.w, r0.z
   9: mad o0.x, r0.x, r0.y, r0.z
  10: ret

VGPRs: 4
gfx900 cycles: 72 (14*4 + 1*16)
```

My acos implementation:

```hlsl
acos_approx: r0.xy
   0: add r0.x, -|v1.x|, l(1.000000)
   1: sqrt r0.x, r0.x
   2: mad r0.y, |v1.x|, l(-0.167767), l(1.570796)
   3: mad r0.x, r0.x, r0.y, l(-1.570796)
   4: lt r0.y, v1.x, l(0.000000)
   5: movc r0.y, r0.y, l(-1.000000), l(1.000000)
   6: mad o0.x, r0.y, r0.x, l(1.570796)
   7: ret

VGPRs: 3
gfx900 cycles: 52 (9*4 + 1*16)
```

To my knowledge, the `movc` will run smoothly, since the arguments to be conditionally moved are both literals, which don't depend on previous evaluations to be predicted, but if I am wrong, please tell me. I'd love to learn so much more about those edge cases.

### Arc-cosine `acos` again

If you were going to immediately convert the range of `acos` from `0-pi` into `0-0.5`, I've got you covered for that one too lol

```hlsl
// Normalized approximation of inverse cosine (acos(x)/2pi)
// Range x [-1, 1] y [0, 0.5]
// Max error: ±0.00095689 at ±0.29297
float acos0h_approx(float x) {
    float t = sqrt(1 - abs(x)) * (abs(x) * -0.026700884 + 0.25);
    return (x < 0 ? -1 : 1) * (t - 0.25) + 0.25;
}
```

And here is the assembly of this one

```hlsl
acos0h_approx: r0.xy
   0: add r0.x, -|v1.x|, l(1.000000)
   1: sqrt r0.x, r0.x
   2: mad r0.y, |v1.x|, l(-0.026701), l(0.250000)
   3: mad r0.x, r0.x, r0.y, l(-0.250000)
   4: lt r0.y, v1.x, l(0.000000)
   5: movc r0.y, r0.y, l(-1.000000), l(1.000000)
   6: mad o0.x, r0.y, r0.x, l(0.250000)
   7: ret
```

### Atan2 Approximation

```hlsl
// Returns the rotation angle of a 2D vector, where 0 = 0 degrees, 1 = 360 degrees
float getAngle(float2 v) {
    v = normalize(v);
    float t = sqrt(1 - abs(v.x)) * (abs(v.x) * -0.026700884 + 0.25);
    return (v.y<0?-1:1) * ((v.x<0?-1:1) * (t - 0.25) - 0.25) + 0.5;
}
float getAngle(float y, float x) {
    return getAngle(float2(x, y));
}
```

---

Say you're trying to do the good ol "get angle from uv" stuff, like this

```hlsl
// inverse tangent to get the angle
float angle = atan2(i.uv.y * -2 + 1, i.uv.x * -2 + 1);
// remap -pi to +pi range to 0.0 to 1.0
return angle / TWO_PI + 0.5;
```

Which will cost ya this chunk of clunk
```hlsl
   0: mad r0.xy, v1.yxyy, l(-2.000000, -2.000000, 0.000000, 0.000000), l(1.000000, 1.000000, 0.000000, 0.000000)
   1: max r0.z, |r0.y|, |r0.x|
   2: div r0.z, l(1.000000, 1.000000, 1.000000, 1.000000), r0.z
   3: min r0.w, |r0.y|, |r0.x|
   4: mul r0.z, r0.z, r0.w
   5: mul r0.w, r0.z, r0.z
   6: mad r1.x, r0.w, l(0.020835), l(-0.085133)
   7: mad r1.x, r0.w, r1.x, l(0.180141)
   8: mad r1.x, r0.w, r1.x, l(-0.330299)
   9: mad r0.w, r0.w, r1.x, l(0.999866)
  10: mul r1.x, r0.w, r0.z
  11: mad r1.x, r1.x, l(-2.000000), l(1.570796)
  12: lt r1.y, |r0.y|, |r0.x|
  13: and r1.x, r1.y, r1.x
  14: mad r0.z, r0.z, r0.w, r1.x
  15: lt r0.w, r0.y, -r0.y
  16: and r0.w, r0.w, l(0xc0490fdb)
  17: add r0.z, r0.w, r0.z
  18: min r0.w, r0.y, r0.x
  19: max r0.x, r0.y, r0.x
  20: ge r0.x, r0.x, -r0.x
  21: lt r0.y, r0.w, -r0.w
  22: and r0.x, r0.x, r0.y
  23: movc r0.x, r0.x, -r0.z, r0.z
  24: mad o0.xyzw, r0.xxxx, l(0.159155, 0.159155, 0.159155, 0.159155), l(0.500000, 0.500000, 0.500000, 0.500000)
  25: ret
```

What the hell maaan I just want my damn UV angle please, none of this crap thank you. Maybe you know a bit more about trig, and find out `acos` is correct when $y \ge 0$ so you write this one instead.

```hlsl
float theta = normalize(i.uv * 2 - 1).x;
theta = (uv.y >= 0) ? theta : (TWO_PI - theta);
return theta * INV_TWO_PI;
```
Which will be better, but it'll still look like.. this..

```hlsl
   0: mad r0.xy, v1.xyxx, l(2.000000, 2.000000, 0.000000, 0.000000), l(-1.000000, -1.000000, 0.000000, 0.000000)
   1: dp2 r0.z, r0.xyxx, r0.xyxx
   2: rsq r0.z, r0.z
   3: mul r0.x, r0.z, r0.x
   4: ge r0.y, r0.y, l(0.000000)
   5: mad r0.z, |r0.x|, l(-0.018729), l(0.074261)
   6: mad r0.z, r0.z, |r0.x|, l(-0.212114)
   7: mad r0.z, r0.z, |r0.x|, l(1.570729)
   8: add r0.w, -|r0.x|, l(1.000000)
   9: lt r0.x, r0.x, -r0.x
  10: sqrt r0.w, r0.w
  11: mul r1.x, r0.w, r0.z
  12: mad r1.x, r1.x, l(-2.000000), l(3.141593)
  13: and r0.x, r0.x, r1.x
  14: mad r0.x, r0.z, r0.w, r0.x
  15: add r0.z, -r0.x, l(6.283185)
  16: movc r0.x, r0.y, r0.x, r0.z
  17: mul o0.xyzw, r0.xxxx, l(0.159155, 0.159155, 0.159155, 0.159155)
  18: ret
```

Well, I did in fact work on [this segment](#arc-cosine-acos-again) for a reason, and using `(x < 0 ? -1 : 1)` instead of the built-in sign function (which should be faster?) you'll get this

```hlsl
float2 v = normalize(i.uv * 2 - 1);
float t = sqrt(1 - abs(v.x)) * (abs(v.x) * -0.026700884 + 0.25);
return (v.y<0?-1:1) * ((v.x<0?-1:1) * (t - 0.25) - 0.25) + 0.5;
```

Resulting in this
```hlsl
   0: mad r0.xy, v1.yxyy, l(2.000000, 2.000000, 0.000000, 0.000000), l(-1.000000, -1.000000, 0.000000, 0.000000)
   1: dp2 r0.z, r0.xyxx, r0.xyxx
   2: rsq r0.z, r0.z
   3: mul r0.xy, r0.zzzz, r0.xyxx
   4: add r0.z, -|r0.y|, l(1.000000)
   5: sqrt r0.z, r0.z
   6: mad r0.w, |r0.y|, l(-0.026701), l(0.250000)
   7: lt r0.xy, r0.xyxx, l(0.000000, 0.000000, 0.000000, 0.000000)
   8: movc r0.xy, r0.xyxx, l(-1.000000,-1.000000,0,0), l(1.000000,1.000000,0,0)
   9: mad r0.z, r0.z, r0.w, l(-0.250000)
  10: mad r0.y, r0.y, r0.z, l(-0.250000)
  11: mad o0.xyzw, r0.xxxx, r0.yyyy, l(0.500000, 0.500000, 0.500000, 0.500000)
  12: ret
```

This implementation does give you range of 0-1 for a whole turn, but you can of course multiply it by 2pi if you want normal stuff.

```hlsl
// Returns the rotation angle of a 2D vector, where 0 = 0 degrees, 1 = 360 degrees
float getAngle(float2 v) {
    v = normalize(v);
    float t = sqrt(1 - abs(v.x)) * (abs(v.x) * -0.026700884 + 0.25);
    return (v.y<0?-1:1) * ((v.x<0?-1:1) * (t - 0.25) - 0.25) + 0.5;
}
float getAngle(float y, float x) {
    return getAngle(float2(x, y));
}
```

### Error function approximation

```hlsl
// Approximation of the error function erf(x) https://en.wikipedia.org/wiki/Error_function
// Error: min (-3.216649658274200e-4) max (3.216649658274200e-4) median: 4.42299e-19
float erf(float x)
{
    float w = x*(0.2006033923313427*x*x + 2.258650166982141);
    return 1 - 2 / (exp(w) + 1);
}
```

You can find the details of how I came up with this guy [here.](../Sections/ErrorFunctionApproximation.md)

### Blackbody Kelvin to 2deg sRGB

This one's old, but I haven't cared to do better yet lol

```hlsl
float3 BlackBodyApprox(float k) {
    float x = k / 1000.0;
    const float3 gTerms[2] = {
        float3(0.527, 1.67, 0.4233),
        float3(-0.163, 0.46, 1.606)
    };
    float3 gT = gTerms[x < 6.695];

    float4 fmd = {
        0.508 * max(6.749, x) - 2.0,
        gT.x * x - gT.y,
        0.0207 * x + 0.043,
        saturate(-0.78 * x + 1)
    };
    fmd.rg = 1.0 / fmd.rg;

    float3 col = {
        fmd.r + 0.2999611,
        fmd.g + gT.z,
        saturate(fmd.b * x - 0.158)
    };
    float atten = pow(fmd.a*fmd.a-1,2);
    return col * atten;
}
```


## Anti-Aliasing

### A Single Quad

"Oh boy do I ever wish I could have MSAA on this one quad, but I don't want to turn that crap on! and im okay with this quad being in the transparent pass, or my framebuffer is actually cleared each frame" Said only I at some point, well luckily for you, I've done just that!

```hlsl
float quadAA(float2 uv)
{
    float2 w = abs(float2( ddx(uv.x), ddy(uv.y) ));
    float2 tent = max(abs(uv - 0.5), abs(w - 0.5));
    float2 ftc = saturate(0.5 - tent) / w;
    return ftc.x * ftc.y;
}
```

### Terraced Steps

```hlsl

float terracedStepF(float x)
{
    float fx = floor(x);
    float hstep = -0.5 * fx - 0.5;
    return dot(abs(fx), float2(hstep, x));
}

float terracedStepAA(float step_count, float x)
{
    float w = fwidth(x) * 0.5;

    float A = step_count * (x - w);
    float B = step_count * (x + w);

    return (terracedStepF(B) - terracedStepF(A)) / (w * F(step_count));
}

```

## Quest Screen-Space Stuff

`framebufferfetch` is a cool extension all quests seem to support, but 99% of people will never figure this out because it will appear shader-pink on desktop, including inside unity.
I have made a few example shaders that support both platforms here.

- [AlphaBlend (Unlit)](../_InternalAssets/dumping_grounds/screen_space_quest/AlphaBlendUnlit.shader)
- [DepthWrite](../_InternalAssets/dumping_grounds/screen_space_quest/DepthWrite.shader)
- [DepthRead](../_InternalAssets/dumping_grounds/screen_space_quest/DepthRead.shader)


## Hilarious / Cursed things

### Screen aspect ratio, from the Perspective matrix

```hlsl
width / height = unity_CameraInvProjection._m00 * unity_CameraProjection._m11;
height / width = unity_CameraInvProjection._m11 * unity_CameraProjection._m00;
```

### I need the letter A!

```hlsl
float amid = step(abs(i.uv.y-0.33),0.06)*step(abs(i.uv.x-0.5),0.2);
float legs = abs(1.06-3.53*abs(i.uv.x-0.5)-i.uv.y);
legs = step(legs,0.22)*step(abs(i.uv.y-0.5),0.46);
float letterA = saturate(amid + legs);
```


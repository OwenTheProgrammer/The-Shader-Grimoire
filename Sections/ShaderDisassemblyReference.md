# Shader Disassembly Reference

Sometimes I have to decompile a shader or read through the compiled version of my hlsl bullshit. I hate having to remind myself every time wtf `round_z` means, so I figured its time to make a massive table of shader assembly contents... and well I guess write out a thesis of knowledge on how to read disassembled shader shit.

# Table of Contents
<!-- mtoc-start -->

- [Shader Disassembly Reference](#shader-disassembly-reference)
- [Table of Contents](#table-of-contents)
	- [Prerequisite](#prerequisite)
		- [CPU vs GPU](#cpu-vs-gpu)
		- [Architecture](#architecture)
	- [Instruction Layout](#instruction-layout)
		- [Instruction Masking](#instruction-masking)
		- [Component Swizzling](#component-swizzling)
		- [Read/Write Ordering](#readwrite-ordering)
		- [Wtf is `l()`?](#wtf-is-l)
		- [Decoding DirectX-ByteCode (DXBC)](#decoding-directx-bytecode-dxbc)
	- [Instruction Modifiers](#instruction-modifiers)
		- [Absolute](#absolute)
		- [Negate](#negate)
		- [Saturate](#saturate)
- [Pattern Recognition](#pattern-recognition)
	- [`mul l(highly suspicious constant)` -\> `constant division`](#mul-lhighly-suspicious-constant---constant-division)
	- [Many texture samples in the same general area](#many-texture-samples-in-the-same-general-area)
	- [`mul, mad, mad, add` -\> `mul(float4x4, float4(xyz, 1))`](#mul-mad-mad-add---mulfloat4x4-float4xyz-1)
	- [`mul, mad, mad, mad` -\> `mul(float4x4, float4(xyzw))`](#mul-mad-mad-mad---mulfloat4x4-float4xyzw)
	- [`log, mul, exp` -\> `pow()`](#log-mul-exp---pow)
	- [`mul, 1.442695, exp` -\> `exp()`](#mul-1442695-exp---exp)
		- [Finding the base of an exponent](#finding-the-base-of-an-exponent)
	- [`log, mul, 0.693147` -\> `log()`](#log-mul-0693147---log)
	- [`rsq, div 1/x` -\> `sqrt(x)`](#rsq-div-1x---sqrtx)
	- [`log, mul 0.333333, exp` -\> `cbrt(x)`](#log-mul-0333333-exp---cbrtx)
	- [`dp#, .xyzw, sqrt` -\> `length()`](#dp-xyzw-sqrt---length)
	- [`dp#, rsq, mul` -\> `normalize()`](#dp-rsq-mul---normalize)
	- [`max(..., 0.0)` or `min(..., 1.0)` -\> `saturate()`](#max-00-or-min-10---saturate)
	- [`lt, lt, iadd, itof` -\> `sign()`](#lt-lt-iadd-itof---sign)
	- [`dp3 0.299, 0.587, 0.114` -\> RGB to Brightness](#dp3-0299-0587-0114---rgb-to-brightness)
	- [`mad 0.305306 0.682171, mad 0.012523, mul` -\> `GammaToLinearSpace()`](#mad-0305306-0682171-mad-0012523-mul---gammatolinearspace)
	- [`mad 2.51 .03, mul, mad 2.43 .59, mad .14, div_sat` -\> `ACESFilm`](#mad-251-03-mul-mad-243-59-mad-14-div_sat---acesfilm)
- [Assembly Table](#assembly-table)
	- [ADD](#add)
		- [Signature](#signature)
		- [Remarks](#remarks)
	- [AND](#and)
		- [Signature](#signature-1)
		- [Remarks](#remarks-1)
	- [BREAK](#break)
		- [Signature](#signature-2)
		- [Remarks](#remarks-2)
	- [BREAKC](#breakc)
		- [Signature](#signature-3)
		- [Remarks](#remarks-3)

<!-- mtoc-end -->

## Prerequisite

### CPU vs GPU

First of all, shader development is *very* different compared to normal programming, unless you live and breath SIMD instructions..

```c
	__m256i m_vexp = _mm256_set1_epi32(exponent);
	__m256i m_input = _mm256_set1_ps(value);
	__m256i m_split = _mm256_srlv_epi32(m_input);
	...
```

but even if that's genuinely the case, you'll probably find yourself out of your element somewhere in the syntax.

Graphics hardware is specially designed for executing simpler "shader programs" with insane levels of parallelization. While CPUs are great at doing a gazillion different complex instructions, rendering millions of pixels in a fraction of a second isn't feasible across (typically) 16 cores/threads. GPUs are just big blocks of compute working in ["SIMD"](https://en.wikipedia.org/wiki/Single_instruction,_multiple_data) or ["SIMT"](https://en.wikipedia.org/wiki/Single_instruction,_multiple_threads), often bottle-necked by memory speeds and occupancy.

Don't get me wrong, memory is often slowest in the graphics pipeline, but the memory shared across each core of a GPU can work well into the terabytes per second read/write speeds.

### Architecture

The architecture of a graphics card is vendor/model specific, but most share the same general "eh, processor here, block of memory beside it, copy, paste paste paste paste .." template.

GPUs have processors just like a CPU would, but their Instruction-Set-Architecture (ISA) isn't thousands of pages long. CPUs divide their silicon space to accommodate processors you can count using two or three hands, but counting GPU cores requires *a lot of hands.* Silicon is cheap as dirt of course :3 so we display our creative efforts to fit as many cores into a graphics card as possible, without choosing between a GPU that hallucinates 3/4 of your frames, and a literal Toyota Corolla..

Monopolistic tendencies asside, we need many computes' rendered and we need them right now, so GPUs fill their silicon space with tons of shrimple processors. Each core or "thread" is like a microprocessor in the sense that it has its own RAM and program memory. A group of threads work on the same shader program alongside each other. Each group is coordinated within a multi-processor, and so on and so on.

Zooming back into a single thread, each "register" a thread works on has four components, usually 32-64 bits wide. (This is why we have `.xyzw` and `float4`, but not `float5`) We can run the same instruction across all components at once, but each register is often holding a mixed bag of unlabeled floats and integers. The computation order and register allocation is abstracted away from you as a shader developer, but disassembling shaders means you get to interpret them yourself :)


## Instruction Layout

When working with shader assembly (at least with D3D style shader disassembly) you will commonly see scawy stuff like this:
```hlsl
      vs_4_0
      dcl_constantbuffer CB0[4], immediateIndexed
      dcl_constantbuffer CB1[21], immediateIndexed
      dcl_input v0.xyz
      dcl_input v1.xy
      dcl_output o0.xy
      dcl_output_siv o1.xyzw, position
      dcl_temps 2
   0: mov o0.xy, v1.xyxx
   1: mul r0.xyzw, v0.yyyy, cb0[1].xyzw
   2: mad r0.xyzw, cb0[0].xyzw, v0.xxxx, r0.xyzw
   3: mad r0.xyzw, cb0[2].xyzw, v0.zzzz, r0.xyzw
   4: add r0.xyzw, r0.xyzw, cb0[3].xyzw
   5: mul r1.xyzw, r0.yyyy, cb1[18].xyzw
   6: mad r1.xyzw, cb1[17].xyzw, r0.xxxx, r1.xyzw
   7: mad r1.xyzw, cb1[19].xyzw, r0.zzzz, r1.xyzw
   8: mad o1.xyzw, cb1[20].xyzw, r0.wwww, r1.xyzw
   9: ret
// Approximately 0 instruction slots used
```

Let's go over what each thing here means.

- `vs_4_0`: "vs" stands for **V**ertex **S**hader, targeting version `4.0` represented as `4_0`
- `dcl_constantbuffer CB0[4], immediateIndexed`
  - `dcl_constantbuffer`: **d**e**cl**ares a global buffer/array/table of **constant** values for your shader to use
  - `CB0[4]`: `CB` stands for **C**onstant **B**uffer, `0` is the buffer index since you can have multiple bound at once, and `[4]` means there are `4` elements stored in it. **NOTE** elements are often stored as *columns* of *four* values.
  - `immediateIndexed`: This means you can access an element within the buffer **immediately** given an integer **index**. Alternatively `dynamic_indexed` requires an expression be computed to determine the actual location of your element before you can receive it.
- `dcl_input v0.xyz`:
  - `dcl_input`: **d**e**cl**ares an **input** to the current shader stage.
  - `v0.xyz`: All input registers will be `v#` with `#` being the register index. `.xyz` represents the "swizzle" or mask for what components of the full register will be used. (Remember, every register is four elements wide.)
- `dcl_input v1.xy`: Another input with the first two elements used
- `dcl_output o0.xy`:
  - `dcl_output`: **d**e**cl**ares an **output** to the current shader stage.
  - `o0.xy`: All output registers will be `o#` with `#` being the register index. `.xy` means we only expect to actually use the first two elements of the register.
- `dcl_output_siv o1.xyzw, position`:
  - `dcl_output_siv`: This is a special register, typically generated from things like `SV_POSITION`. "SV" means "System Value" in this case. Anything prefixed with `SV_` will be interpreted by the rasterizer stage; the stage that determines how to invoke pixel shader stage, based on the result of the vertex shader stage.
  - `o1.xyzw`: Means our output will be a full vector4 type
  - `position`: This marks the `o1` output register as the vertex position output, which the rasterizer will work from. This implies `o1` will be our vertex position.
- `dcl_temps 2`: pre-**d**e**cl**ares the amount of **temp**orary registers will be needed to execute this shader program. Since we have `2`, we can expect to use registers `r0` and `r1`

> [!NOTE]
> Each `dcl_input` and `dcl_output` don't specify the expected *type* for each argument. That can instead be found in the Input Signature / `ISGN` and Output Signature / `OSGN` parts of the shader disassembly.

Here's a table of very common types:
- `v#`: Input register
- `r#`: Temporary register
- `o#`: Output register
- `t#`: Texture object
- `s#`: Texture sampler
- `cb#`: Constant buffer
- `icb#`: Integer constant buffer


Everything from here is the actual vertex shader program, which comes in the following format.

```hlsl
   [Instruction Number]: [Instruction OpCode] [Destination register].[Swizzle Mask], [Source register/operand].[Swizzle] ...
```



Theres a very important detail to the way the operands are treated here, so ill make sure to outline it as best I can here:

Looking at `0: mov o0.xy, v1.xyxx`, you will see `o0.xy` which tells us we're setting the `xy` component of `o0`, but we also see `v1.xyxx` which would be.. four components? what gives?

### Instruction Masking

If we were to execute `mov r0.xy, v1.xyxx`, we would **mov**e parts of `v1` into `r0`. For the majority of instructions, you can separate the instruction per each component of the destination, like so.

```hlsl
mov r0.xy, v1.xyxx

// becomes
mov r0.x, v1.x	// mov r0.x_, v1.x___
mov r0.y, v1.y	// mov r0._y, v1._y__
```

Some instructions like the dot product can't be split like this, since they interface with multiple parts of the source operands at once to compute the result.

```hlsl
dp3 r0.x, v1.xyzx, v2.xyzx

r0.x = dot(v1.xyz, v2.xyz);
r0.x = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
```


### Component Swizzling

Some instructions are quite simple to read. If the destination has a single component, you will see shader assembly like so

```hlsl
add r0.x, -r0.x, l(4.000000)

//r0.x = -r0.x + 4.0;
//     = 4.0 - r0.x;
```

but as soon as two, three, or four elements come up in any way, you'll be reading this instead.

```hlsl
add r0.xy, -r0.xyxx, l(4.000000, 4.000000, 0.000000, 0.000000)
```

The components of `-r0.xyxx` arent all used, only the ones that the destination `r0.xy` actually calls for (we will go over this shortly.) The `r0` swizzle `.xyxx` doesn't use the last two x components, this is merely the swizzle generator doing its thing.

The swizzle `.xy` is extended to become four components long when the destination has more than one component, with each unused component taking the first components swizzle. For instance:

- `r0.x` will become `r0.xxxx`
- `r0.xy` will become `r0.xyxx`
- `r0.wz` will become `r0.wzww`

Each `x|y|z|w` you see in a swizzle defines which section of a register goes where, like a switch board. **This is position dependent**. Registers of the GPU are purely memory cells, they don't have an inherit type assigned to them. It's up to the shader compiler to keep track and utilize the correct instructions based on the given values.

Let's go through what happens when we execute: `mul r0.xz, r0.yywy, v1.xxyx`

Looking at the destination swizzle `.xz`, we know the second and forth components aren't evaluated for each operand, so we can focus on the components that are in the same position.

```hlsl
mul r0.xz, r0.yywy, v1.xxyx


// r0.xyzw -> r0.[x][ ][z][ ] -> r0.x_z_
// Gives us the mask:
//               [x][ ][z][ ]
// r0.yywy -> r0.[y][ ][w][ ] -> r0.y_w_
// v1.xxyx -> v1.[x][ ][y][ ] -> v1.x_y_

mul r0.x_z_, r0.y_w_, v1.x_y_
mul r0.xz, r0.yw, v1.xy

// Original:
mul r0.xz, r0.yywy, v1.xxyx
// What we're actually computing:
mul r0.xz, r0.yw, v1.xy
```


```hlsl
// Without destination mask:
mul r0.xyzw, r0.ywwy, v1.xyyx

// Expanded computation per component of r0.xyzw
mul r0.x, r0.y, v1.x
mul r0.y, r0.w, v1.y
mul r0.z, r0.w, v1.y
mul r0.w, r0.y, v1.x

// r0.xz means we only execute the results for r0.x and r0.z

  mul r0.x, r0.y, v1.x
//mul r0.y, r0.w, v1.y
  mul r0.z, r0.w, v1.y
//mul r0.w, r0.y, v1.x

// Resulting in
  mul r0.xz, r0.yw, v1.xy
```

### Read/Write Ordering

Another thing I should bring up is register self read/write, like this

```hlsl
mul r0.xy, r0.xyxx, r0.yxyy
```

`r0.x = r0.x * r0.y` and `r0.y = r0.y * r0.x`, which might seem like a race condition, but the source operands of an instruction are loaded as temps before, in this case, the Arithmetic Logical Unit (ALU) executes the microcode for multiplication.

so what's really happening is:

```hlsl
float4 mul_A = r0.xyxx; // temporary
float4 mul_B = r0.yxyy; // temporary

r0.xy = mul_A.xy * mul_B.xy;

// unravelling mul_A and mul_B:
r0.xy = r0.xy * r0.yx;
```

### Wtf is `l()`?

I couldn't find a good place to talk about *literals*, so I guess it's going here.

Your shader is stored as big blocks of machine code, containing the information needed to run each instruction of your program. The shader compiler converts your shader code into something a GPU thread can understand (*technically* there are driver translation layers in here as well, but I don't know that side too well). Each instruction stores what type of operation to use (the "opcode"), the destination register and its component masks, the source registers and or operands, etc. Storing every temporary value in memory would be a terrible idea, especially when you'd have to store its address and initialize it with data beforehand.. So instructions can come with the source values directly, as *literals*.

Literals come in the form of either `l(...)` or `l(..., ..., ..., ...)` depending on the destination swizzle thing.

- `l(0.000000)` floating point values are always stored like this, with six decimal places.
- `l(40)` signed/unsigned integers are stored as-is*
- `l(0x000186a1)` signed/unsigned integers larger than `10 000` will be stored as hex.

> [!NOTE]
> You can differentiate signed and unsigned literals based on the instruction context. If the instruction is `i*` like `imul`, its for sure going to be an integer literal. `u*` like `umul` will be unsigned.

I have to bring some caution though..

### Decoding DirectX-ByteCode (DXBC)

Bitwise operations can not be applied to float types. I know it may sound obvious, but sometimes the shader disassembler missinterprets a large unsigned integer as a floating point value.

There is a good chance if you've been doing this shit for a while, you've seen some head-scratching shader code.. *Heh.. get a load a' this shit.*

```hlsl
	...
	and r0.y, r0.x, l(0.000000)
	ushr r0.x, r0.x, l(8)
	and r0.x, r0.x, l(0.000000)
	umad r0.x, r0.y, l(256), r0.x
	...
```

Yes, I've seen shader disassembly like this before, and no, you're not tweaking.

```hlsl
	// weird way to clear this register, but alright y is a float now..

	// and r0.y, r0.x, l(0.000000)
	r0.y = r0.x & 0.000000;

	// alright.. divide it? but its ushr, so r0.x should be an unsigned value, makes sense..
	// oh yeah! the floating point memory for 0.0 is also memory 0, alright

	//ushr r0.x, r0.x, l(8)
	//r0.x >>= 8;
	r0.x /= 256;

	// A-.. and then we clear it again????
	r0.x &= 0.000000; //and r0.x, r0.x, l(0.000000)

	// Then do an unsigned fused-multiply-add???????

	//umad r0.x, r0.y, l(256), r0.x
	//r0.x = r0.y * 256 + r0.x;
	r0.x += r0.y * 256;
```

Yes. I've actually seen shit like this before. Yes. The shader disassembler is incorrect here. If you come across a float where it really shouldn't be, there's *only one solution* to that mess, and thats to **decompile the dxbc bytecode yourself.**

renderdoc actually gives you this when you save the shader with the little save icon, make sure to save the shader as bytes though, and youll want to [read the only damn documentation worth reading](http://timjones.io/blog/archive/2015/09/02/parsing-direct3d-shader-bytecode#parsing-shader-bytecode) and decode the SHDR chunk.

```hlsl
// All enum flags are under D3D10_SB_*

// -- OpcodeToken0 --
"117440513": 0 0000111 0000000000000 00000000001
	- OPCODE_TYPE:      00000000001 (OPCODE_AND)
	- OPCODE_CONTROLS:  0000000000000
	- INSTRUCTION_LEN:  0000111 (7 DWORDS)
	- OP_EXTENDED:      0 (normal operation)

// 117440513:
// AND instruction
// over 7 unsigned 32 bit integers.

READ: 117440513, 1048610, 0, 1048586, 0, 16385, 16711935
```
```hlsl
// -- OperandToken0 --
"1048610": 0 000 000 000 01 00000000 0000001000 10
	- NUM_CMPS: 10 (OPERAND_4_COMPONENT)
	- CMP_SEL: 0000001000 -> 0000 0010 00
		- MODE: 00 (OPERAND_4_COMPONENT_MASK_MODE)
		- MASK: 0010 OPERAND_4_COMPONENT_MASK_Y
		- IGNORED: 0000
	- OPERAND_TYPE: 00000000 (OPERAND_TYPE_TEMP)
	- OPERAND_RDIM: 01 (OPERAND_INDEX_1D)
	- OPERAND_IREP_1D: 000 (OPERAND_INDEX_IMMEDIATE32)
	- OPERAND_IREP_2D: 000 (IGNORED)
	- OPERAND_IREP_3D: 000 (IGNORED)
	- OP_EXTENDED: 0 (normal operation)

// 1048610:
// - 4 components
// - masked (Y)
// - temp register
// - 32 bit register index (next DWORD)
// - READ "0": register index 0

// 1048610, 0: r0.y
```
```hlsl
// -- OperandToken0 --
"1048586": 0 000 000 000 01 00000000 0000000010 10
	- NUM_CMPS: 10 (OPERAND_4_COMPONENT)
	- CMP_SEL: 0000000010 -> 000000 00 10
		- MODE: 10 (OPERAND_4_COMPONENT_SELECT_1_MODE)
		- CMP_NAME: 00 (4_COMPONENT_X)
		- IGNORED: 000000
	- OPERAND_TYPE: 00000000 (OPERAND_TYPE_TEMP)
	- OPERAND_RDIM: 01 (OPERAND_INDEX_1D)
	- OPERAND_IREP_1D: 000 (OPERAND_INDEX_IMMEDIATE32)
	- OPERAND_IREP_2D: 000 (IGNORED)
	- OPERAND_IREP_3D: 000 (IGNORED)
	- OP_EXTENDED: 0 (normal operation)

// 1048586:
// - 4 components
// - single component (x)
// - temp register
// - 32 bit register index (next DWORD)
// - READ "0": register index 0

// 1048586, 0: r0.x
```
```hlsl
// -- OperandToken0 --
"16385": 0 000 000 000 00 00000100 0000000000 01
	- NUM_CMPS: 01 (OPERAND_1_COMPONENT)
	- CMP_SEL: 0000000000 (IGNORED)
	- OPERAND_TYPE: 00000100 (OPERAND_TYPE_IMMEDIATE32)
	- OPERAND_RDIM: 00 (OPERAND_INDEX_0D)
	- OPERAND_IREP_1D: 000 (IGNORED)
	- OPERAND_IREP_2D: 000 (IGNORED)
	- OPERAND_IREP_3D: 000 (IGNORED)
	- OP_EXTENDED: 0 (normal operation)

// 16385:
// - 1 component
// - immediate 32 bit type (1 * DWORDS)
// - READ "16711935": 32 bit value = 0xFF00FF

// 16385, 16711935: uint(0xFF00FF)
```

```hlsl
117440513: and
1048610, 0: r0.x
1048586, 0: r0.y
16385, 16711935: uint(0xFF00FF)

// 117440513, 1048610, 0, 1048586, 0, 16385, 16711935:
// and r0.x, r0.y, l(0xFF00FF)
r0.x = r0.y & 0xFF00FF;
```

Remember, RenderDoc gave me this:
```hlsl
and r0.y, r0.x, l(0.000000)
```
While the actual bytecode represents this:
```hlsl
r0.x = r0.y & 0xFF00FF;
```

So... why? I honestly don't know myself.. but decoding dxbc by hand is possible, and decoding it by writing a program has proven much more difficult, but I hope to create some tools down the line.


## Instruction Modifiers

### Absolute

[See the documentation](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/absolute-value)
The absolute modifier takes the absolute value for both single and double precision floats. This modifier ensures the given value is always positive. Microsoft documents this modifier as `_abs`, which is intriguing since I've never seen it like that.

You're more likely to see the `abs` modifier displayed with double bar notation, which is much more common in mathematics. I personally use the following math notation:

$$
\begin{gather*}
| x | \text{ represents the absolute value of } x \\
\| x \| \text{ represents the magnitude or length of vector } x
\end{gather*}
$$

The following shader assembly

```hlsl
   0: mov o0.xyzw, |v0.xxxx|
   1: ret
```

was generated from
```hlsl
return abs(i.uv.x);
```

where `|v0.xxxx|` is the absolute of the `v0.x` value.

If you find a case where `_abs` is used in shader assembly, I'd love to know about it.

- Applying the absolute modifier on infinite values results on positive infinity
- NaN values are preserved as NaN, but the particular bit pattern is undefined.


### Negate

[See the documentation](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/negate)

The negation modifier flips the signature of single/double precision floats, and integers.
For integer operands, the negate modifier takes the two's complement of the integer value; bitwise invert and add one, your typical integer negative.

The following shader assembly
```hlsl
   0: mov o0.xyzw, -v0.xxxx
   1: ret
```

was generated from
```hlsl
return -i.uv.x;
```

- Applying negate on a floating point $\pm \infty$ gives you $\mp \infty$ like normal
- Applying negate on a NaN float will preserve the NaN, but the bit pattern is undefined.

### Saturate

[See the documentation](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/saturate)

The saturate modifier is probably the most powerful modifier of them all. The `saturate` instruction clamps any single/double precision float to the range 0 to 1.

saturate can be implemented in different ways, for instance GLSL does not include `saturate`, so instead you may see

```glsl
value = clamp(value, 0.0, 1.0);
```

in place of saturate. Conceptually, saturate can also be implemented with `min` and `max` functions as

$$
\mathrm{saturate}(x) = \min(1, \max(x, 0))
$$

`sat` follows the same rules as min and max for things like NaN returning 0


`mov_sat` here:
```hlsl
   0: mov_sat o0.xyzw, v0.xxxx
   1: ret
```

is generated from
```hlsl
return saturate(i.uv.x);
```

and
```hlsl
   0: div_sat r0.x, v0.x, v0.y
   1: add o0.xyzw, r0.xxxx, l(4.000000, 4.000000, 4.000000, 4.000000)
   2: ret
```

can be generated from
```hlsl
return saturate(i.uv.x / i.uv.y) + 4.0;
```

# Pattern Recognition

There are some assembly patterns you start to pick up on when you stare at your screen for long enough. Some are simple to find, some are stupid hard to piece together because its been optimized into another operation somewhere else.

## `mul l(highly suspicious constant)` -> `constant division`

You ever just feel like a number is something more? no? just me? aww..

well, if you have a literal thats less than 1, and it feels kinda funny, try
- computing 1 / that value
- searching "{that value} as a fraction"

there's a good chance it has some stupid value like `13137/50000` in which I would just ignore it, but if its like 1/125, it might just mean something.

```hlsl
//mul r0.xyzw, r0.xyzw, l(0.062500, 0.062500, 0.062500, 0.062500)
```

$$
\frac{1}{0.0625} = 16
$$

```hlsl
//mul r0.xyzw, r0.xyzw, l(0.062500, 0.062500, 0.062500, 0.062500)

r0.xyzw /= 16.0;
```

## Many texture samples in the same general area

If you see more texture samples on your screen than like 4-ish, theres a good chance somethings up.

There was most likely an unrolled loop somewhere, but in general either some convolution is right in front of you, [like gaussian blurs 'n such.](https://en.wikipedia.org/wiki/Kernel_(image_processing)#Details)


## `mul, mad, mad, add` -> `mul(float4x4, float4(xyz, 1))`

```hlsl
//mul r0.xyzw, v0.yyyy, cb0[1].xyzw
//mad r0.xyzw, cb0[0].xyzw, v0.xxxx, r0.xyzw
//mad r0.xyzw, cb0[2].xyzw, v0.zzzz, r0.xyzw
//add r0.xyzw, r0.xyzw, cb0[3].xyzw
```

## `mul, mad, mad, mad` -> `mul(float4x4, float4(xyzw))`

```hlsl
// mul r1.xyzw, r0.yyyy, cb1[18].xyzw
// mad r1.xyzw, cb1[17].xyzw, r0.xxxx, r1.xyzw
// mad r1.xyzw, cb1[19].xyzw, r0.zzzz, r1.xyzw
// mad o1.xyzw, cb1[20].xyzw, r0.wwww, r1.xyzw
```

## `log, mul, exp` -> `pow()`

First of all, the shader compiler will use multiplication composition to get small powers of a variable, like so.

```hlsl
// mul o0.x, v1.x, v1.x
return pow(x, 2);

// mul r0.x, v1.x, v1.x
// mul o0.x, r0.x, v1.x
return pow(x, 3);

// mul r0.x, v1.x, v1.x
// mul o0.x, r0.x, r0.x
return pow(x, 4);

// mul r0.x, v1.x, v1.x
// mul r0.x, r0.x, r0.x
// mul o0.x, r0.x, v1.x
return pow(x, 5);
...
```

But as im sure you guessed, it's not going to unroll `pow(x, 400)` as
```hlsl
// 400: 256 + 128 + 16
float v = x;    // x
v = v * v;      // x^2
v = v * v;      // x^4
v = v * v;      // x^8
v = v * v;      // x^16
float v16 = v;
v = v * v;      // x^32
v = v * v;      // x^64
v = v * v;      // x^128
float v128 = v;
v = v * v;      // x^256
v = v * v128;   // x^384
v = v * v16;    // x^400
```
which would be funny as hell, what about fractional powers? what about dynamic powers?

The shader compiler does this wacko shtuff:

$$
\Large
\begin{aligned}
	x &= 2^{\log_2\left(x\right)} \\
	\left(x\right)^n &= \left(2^{\log_2\left(x\right)}\right)^n \\
	x^n &= 2^{n\log_2\left(x\right)}
\end{aligned}
$$

Resulting in this expansion:

```hlsl
//log r0.x, [input]
//mul r0.x, r0.x, [power]
//exp r0.x, r0.x

pow(input, power);
```

> [!NOTE]
> `log()` and `exp()` functions are base-e in HLSL, but the shader assembly has `log` and `exp` as base-2 functions.. just to mess with ya.
> the `log` instruction maps to the `log2()` intrinsic
> the `exp` instruction maps to the `exp2()` intrinsic

## `mul, 1.442695, exp` -> `exp()`

Speaking of actually, `exp()` is done using more logarithm rules:

$$
\Large
\begin{aligned}
	\left(a^b\right)^c &= a^{bc} \\
	b^{\log_b\left(x\right)} &= x \\
	e^x &= \left(2^{\log_2\left(e\right)}\right)^x
		 = 2^{x\log_2\left(e\right)} \\
	\log_2\left(e\right) &\approx 1.442695
\end{aligned}
$$

```hlsl
//mul r0.x, [input], l(1.442695)
//exp r0.x, r0.x

exp(input);
```

This is where things are rough to work out 99% of the time though.. since even the smallest of modifications result in a different result

```hlsl
//mul r0.x, [input], l(7.213475)
//exp r0.x, r0.x

exp(input * 5.0);
```

But of course, you can divide the literal by $\log_2\left(e\right)$ to see what the multiplier would be to get `exp()` to work.

$$
	\frac{7.213475}{\log_2\left(e\right)} \approx 4.99999985829
$$

Same goes for other exponents by the way!

### Finding the base of an exponent

Alright let's say you have

```hlsl
mul r0.x, v1.x, l(1.584962)
exp r0.x, r0.x
```

and we want to calculate the base of the exponentiation `pow(base, v1.x)`, we can simply raise the literal to the power of two.

$$
	2^{1.584962} \approx 2.99999895878
$$

If you like the number enough to marry it, you can just use that

```hlsl
//return pow(2.99999, v1.x); just kidding lol
return pow(3.0, v1.x);
```

Do keep in mind as well, the base may be a power of two as well. Take for instance

```hlsl
	add r0.x, v1.x, v1.x
	exp r0.x, r0.x
```

Which we can interpret as

```hlsl
	mul r0.x, v1.x, l(2.000000)
	exp r0.x, r0.x
```

raising two to the `2.000000`'th power results in.. well.. $2^2$.. which is 4.
```hlsl
return pow(4, v1.x);
```

## `log, mul, 0.693147` -> `log()`

Yet another optimization trick

$$
\begin{aligned}
	\ln\left(x\right) &= \ln\left(2\right) \log_2\left(x\right) \\
	\ln\left(2\right) &\approx 0.693147
\end{aligned}
$$

```hlsl
//log r0.x, v1.x
//mul r0.x, r0.x, l(0.693147)

return log(v1.x);
```

Which is yet another point where the multiplier may not be perfect to read off..

```hlsl
//log r0.x, v1.x
//mul r0.x, r0.x, l(2.772589)

// 2.772589 / 0.693147 = 4.0000014427

return log(v1.x) * 4;
```

## `rsq, div 1/x` -> `sqrt(x)`

```hlsl
//rsq r0.x, v1.x
//div r0.x, l(1.000000), r0.x

return sqrt(v1.x);
```

## `log, mul 0.333333, exp` -> `cbrt(x)`

I outline this one because the `cbrt(x)` function doesnt exist..

```hlsl
#define cbrt(x) pow(x, 1.0/3.0)

//log r0.x, v1.x
//mul r0.x, r0.x, l(0.333333)
//exp r0.x, r0.x

return cbrt(v1.x)
```

## `dp#, .xyzw, sqrt` -> `length()`

Computing the length of vectors happen a lot, thankfully the instructions needed to compute the euclidean length aren't really seperable, so they're quite easy to spot.

Anytime you see the dot product for one variable, with swizzles that look like this:
- `dp2` = `.xyxx`
- `dp3` = `.xyzx`
- `dp4` = `.xyzw`

Followed by a square root, then that computes the length.

```hlsl
// dp2 r0.x, v1.xyxx, v1.xyxx
// sqrt r0.x, r0.x

return length(some float2);

// dp3 r0.x, v1.xyzx, v1.xyzx
// sqrt r0.x, r0.x

return length(some float3);

// dp4 r0.x, v1.xyzw, v1.xyzw
// sqrt r0.x, r0.x

return length(some float4);

// dp3 r0.x, v1.xyzx, v2.xyzx
// sqrt r0.x, r0.x

// NOT the length, since its v1 and v2:
return sqrt(dot(v1.xyz, v2.xyz));

// dp4 r0.x, v1.xyxy, v1.xyxy
// sqrt r0.x, r0.x

// NOT the length since the 4 component dot product didnt include z or w
return sqrt(dot(v1.xyxy, v1.xyxy));
```

## `dp#, rsq, mul` -> `normalize()`

```hlsl
// dp3 r0.x, v1.xyzx, v1.xyzx
// rsq r0.x, r0.x
// mul o0.xyz, v1.xyzx, r0.x

return normalize(v1.xyz);
```

> [!NOTE]
> normalize(x) is definitionally equal to x / length(x), so identifying normalize can also be found through:
> dp#, sqrt, div

## `max(..., 0.0)` or `min(..., 1.0)` -> `saturate()`

Sometimes the shader compiler understands a given expression stays within the lower or upper bound of saturate. This results in min / max being used in place of saturate.

```hlsl
// x*x can't be less than zero, so we only need to clamp x*x to 1.

// mul r0.x, v1.x, v1.x
// min r0.x, r0.x, l(1.000000)

return saturate(x * x);
```

## `lt, lt, iadd, itof` -> `sign()`

```hlsl
// lt r0.x, l(0.0), [input]
// lt r0.y, [input], l(0.0)
// iadd r0.x, -r0.x, r0.y
// itof r0.x, r0.x

return sign(input)
```

## `dp3 0.299, 0.587, 0.114` -> RGB to Brightness

Sometimes you'll see it like this:
```hlsl
// dp3 r0.x, [color].xyzx l(0.299000, 0.587000, 0.114000, 0.000000)
```

and sometimes you'll get a truncated version:
```hlsl
// dp3 r0.x, [color].xyzx l(0.300000, 0.590000, 0.110000, 0.000000)
```

but they both represent the Y' component of Y'UV, which is often used for converting an RGB colour into its brightness component.


## `mad 0.305306 0.682171, mad 0.012523, mul` -> `GammaToLinearSpace()`

This one's fairly Unity specific, but you may see it come up from time to time.

```hlsl
// mad r0.xyz, [color].xyzx, l(0.305306, 0.305306, 0.305306, 0.000000), l(0.682171, 0.682171, 0.682171, 0.000000)
// mad r0.xyz, [color].xyzx, r0.xyzx, l(0.012523, 0.012523, 0.012523, 0.000000)
// mul r0.xyz, r0.xyzx, [color].xyzx

return GammaToLinearSpace(color);
```

## `mad 2.51 .03, mul, mad 2.43 .59, mad .14, div_sat` -> `ACESFilm`

TODO: this section lol there are so many colour transforms
to the reader though, you should snoop around colour space matrices to see if your assembly is genuinely just a R709 transform or whatever.


# Assembly Table

## ADD

Sums the components of two floating point vectors together.

- [Documentation](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/add--sm4---asm-)
- Disassembly id: `add`
- Opcode type: `D3D10_SB_OPCODE_TYPE::D3D10_SB_OPCODE_ADD`
- Opcode value: `0`
- Works with float and double types

### Signature

Disassembly (brief): `add dst.xyzw, src0.xyzw, src1.xyzw`
Disassembly (full): `add[_sat] dst[.mask], [-]src0[_abs][.swizzle], [-]src1[_abs][.swizzle]`
Shader: `dst = src0 + src1;`


### Remarks

- `x = 0`
	- `add x, -x,  x` : `x = -x + x = x - x`
	- `add x,  x, -x` : `x = x + -x = x - x`
- `x`
	- `add x, x, l(0.0)` : `x = x + 0.0`
	- `add x, l(0.0), x` : `x = 0.0 + x`
- `|x|`
	- `add x, |x|, l(0.0)` : `x = |x| + 0.0 = abs(x)`
	- `add x, l(0.0), |x|` : `x = 0.0 + |x| = abs(x)`
- `-x` or `x *= -1`
	- `add x, -x, l(0.0)` : `x = -x + 0.0 = -x`
	- `add x, l(0.0), -x` : `x = 0.0 + -x = -x`
- `-|x|`
	- `add x, -|x|, l(0.0)` : `x = -|x| + 0.0 = -abs(x)`
	- `add x, l(0.0), -|x|` : `x = 0.0 + -|x| = -abs(x)`
- `x++`
	- `add x, x, l(1.0)` : `x = x + 1.0`
	- `add x, l(1.0), x` : `x = 1.0 + x`
- `x--`
	- `add x, x, l(-1.0)` : `x = x + -1.0 = x - 1`
	- `add x, l(-1.0), x` : `x = -1.0 + x = x - 1`
- `x += y`
	- `add x, x, y` : `x = x + y`
	- `add x, y, x` : `x = y + x`
- `x -= y`
	- `add x, x, -y` : `x = x + -y`
- `x *= 2`
	- `add x,  x,  x` : `x = x + x`
- `x = 2 * y`
	- `add x, y, y` : `x = y + y`
- `x *= -2`
	- `add x, -x, -x` : `x = -x + -x`
- `x = -2 * y`
	- `add x, -y, -y` : `x = -y + -y`
- `x = y - x`
	- `add x, -x, y` : `x = -x + y = y - x`
- `max(2x, 0)`
	- `add x, |x|, x` : `x = |x| + x = abs(x) + x`
- `max(-2x, 0)`
	- `add x, |x|, -x` : `x = |x| + -x = abs(x) - x`
- `min(2x, 0)`
	- `add x, x, -|x|` : `x = x + -|x| = x - abs(x)`
- `min(-2x, 0)`
	- `add x, -x, -|x|` : `x = -x + -|x| = -x - abs(x)`
	- `add x, -|x|, -x` : `x = -|x| + -x = -abs(x) - x`


## AND

Computes the bitwise AND between the components of two integer vectors.

- [Documentation](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/and--sm4---asm-)
- Disassembly id: `and`
- Opcode type: `D3D10_SB_OPCODE_TYPE::D3D10_SB_OPCODE_AND`
- Opcode value: `1`
- Works with signed/unsigned integer types

### Signature

Disassembly (brief): `and dst.xyzw, src0.xyzw, src1.xyzw`
Disassembly (full): `and dst[.mask], src0[.swizzle], src1[.swizzle]`
Shader: `dst = src0 & src1;`

### Remarks

- `x = 0`
	- `and x, x, l(0)` : `x = x & 0`
	- `and x, l(0), x` : `x = 0 & x`
- `x`
	- `and x, x, x` : `x = x & x = x`
	- `and x, x, l(~0)` : `x = x & (~0) = x`
- `x & 1` "x is odd"
	- `and x, x, l(1)` : `x = x & 1`
	- `and x, l(1), x` : `x = 1 & x`
- `x % (2^n)` "Wrap around after n-th power of two"
	- `and x, x, l( (2^n)-1 )` : `x = x & [1|3|7|15|31|...]`
	- `and x, l( (2^n)-1 ), x` : `x = [1|3|7|15|31|...] & x`
- `(x / (2^n)) * 2^n` "Round down to n-th power of two"
	- `and x, x, l(~((2^n)-1))` : `x = x & ~[1|3|7|15|31|...]`
	- `and x, l(~((2^n)-1)), x` : `x = ~[1|3|7|15|31|...] & x`
- `x = y`
	- `and x, l(~0), y` : `x = (~0) & y = y`
	- `and x, y, l(~0)` : `x = y & (~0) = y`

## BREAK

Leaves a switch case / breaks out of a loop, moving to the instruction after the next `endloop` or `endswitch`.

- [Documentation](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/break--sm4---asm-)
- Disassembly id: `break`
- Opcode type: `D3D10_SB_OPCODE_TYPE::D3D10_SB_OPCODE_BREAK`
- Opcode value: `2`
- No arguments taken.

### Signature

Disassembly: `break`
Shader: `break;`

### Remarks
Must appear within a `loop`/`endloop` or `switch`/`endswitch`

## BREAKC

Conditionally leaves a switch case / breaks out of a loop, moving to the instruction after the next `endloop` or `endswitch`.

- [Documentation](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/breakc--sm4---asm-)
- Disassembly id: `breakc`
- Opcode type: `D3D10_SB_OPCODE_TYPE::D3D10_SB_OPCODE_BREAKC`
- Opcode value: `3`
- Works with technically any register type, but favoured towards signed/unsigned integers.

### Signature

Disassembly (brief): `breakc[_z|_nz] src0.[cmp]`
Disassembly (full): break if all zeros: `breakc_z` break if non-zero: `breakc_nz`
Shader:

```hlsl
// breakc_z
if(!src0.cmp)
	break;

// breakc_nz
if(src0.cmp)
	break;
```

### Remarks

Must appear within a `loop`/`endloop` or `switch`/`endswitch`

If any bit within the memory of `src0.cmp` is set, `breakc_nz` will perform a break.

If all bits within the memory of `src0.cmp` are zeros, `breakc_z` will perform a break.

Only one component may be used from `src0`


# Did you know?

Here's a random compilation of niche shader things for ya

# Table of Contents
- [Did you know?](#did-you-know)
- [Table of Contents](#table-of-contents)
- [General Shader Things](#general-shader-things)
	- [Read The ~~Fucking~~ Secret Manual](#read-the-fucking-secret-manual)
		- [I use VRChat Creator Companion :3](#i-use-vrchat-creator-companion-3)
		- [I installed through Unity Hub](#i-installed-through-unity-hub)
		- [I installed with the standalone installers](#i-installed-with-the-standalone-installers)
		- [I'm cooked..](#im-cooked)
		- [I'm fucking ROASTED MY GUY](#im-fucking-roasted-my-guy)
	- [Copy the Manual](#copy-the-manual)
- [HLSL Shader Things](#hlsl-shader-things)
	- [Workflow and Creature Comforts](#workflow-and-creature-comforts)
		- [Customized Shader Templates](#customized-shader-templates)
		- [Named Passes](#named-passes)
		- [Properties](#properties)
			- [(The documentation for these)](#the-documentation-for-these)
			- [`[HideInInspector]`](#hideininspector)
			- [`[Header()]`](#header)
			- [`[Space()]`](#space)
			- [`[HDR]`](#hdr)
	- [Actual Shader Code](#actual-shader-code)
		- [Debug Symbols](#debug-symbols)
		- [Useful Definitions](#useful-definitions)
			- [`USING_DIRECTIONAL_LIGHT`](#using_directional_light)
			- [`USING_STEREO_MATRICES` And Shader API stuff](#using_stereo_matrices-and-shader-api-stuff)
			- [`SHADER_STAGE_VERTEX` / `SHADER_STAGE_FRAGMENT`](#shader_stage_vertex--shader_stage_fragment)
			- [`UNITY_UV_STARTS_AT_TOP`](#unity_uv_starts_at_top)
			- [`UNITY_REVERSED_Z`](#unity_reversed_z)
	- [Function Definitions](#function-definitions)
		- [Prototypes](#prototypes)
		- [Poly-definitions](#poly-definitions)
	- [Parameter Modifiers / Keywords](#parameter-modifiers--keywords)
		- [void keyword](#void-keyword)
		- [in keyword](#in-keyword)
		- [out keyword](#out-keyword)
		- [inout keyword](#inout-keyword)
		- [Interpolation Modifiers](#interpolation-modifiers)
	- [Structs Are a Thing](#structs-are-a-thing)
	- [CGINCLUDE for global definitions](#cginclude-for-global-definitions)
	- [`#include_with_pragmas`](#include_with_pragmas)
	- [Shader Semantics](#shader-semantics)
		- [`SV_IsFrontFace`](#sv_isfrontface)
		- [`SV_VertexID`](#sv_vertexid)
	- [Cursed Knowledge](#cursed-knowledge)
		- [Disabling Specific Warnings](#disabling-specific-warnings)
		- [Inlining Function Arguments](#inlining-function-arguments)
		- [Intrinsic Overloading](#intrinsic-overloading)


# General Shader Things

## Read The ~~Fucking~~ Secret Manual

You might be wondering "What in the world does UnityObjectToClipPos actually do??" or "How the fuck did you find `unity_SpecCube1_BoxMin`? its no where in the documentation!"

There's a simple answer, and I highly recommend you follow along for this section.

Where ever you decided to install your current version of Unity, theres a directory named CGIncludes that contains all of Unitys cginc files.

> [!NOTE]
> You may have been referencing the TwoTailsGames github project with cginc files, but these are most likely outdated and a half by now. Some things will be the same, but Unity has changed major amounts since it was "Copyright (c) 2016 Unity Technologies" land.

For me, this directory is located under `C:\\Program Files\\Unity\\Hub\\Editor\\2022.3.22f1\\Editor\\Data\\CGIncludes`
but that location may differ for you.

Need help finding it? I gotchu

### I use VRChat Creator Companion :3

Alright simple enough

1. Launch VRChat Creator Companion
2. Goto "Settings" which will most likely be at the bottom left of the window
3. Goto "General" if you aren't already there
4. Under the "Unity Editors" section, you should see "Selected Editor"

You can either Navigate your way to the file path given, except for Unity.exe since that would launch Unity, Or

1. Click "View all installed Versions"
2. Find the version of Unity you use that has a checkmark to the left of it
3. Drag select the text in the box with the path to the Unity version
4. Copy the text, without Unity.exe
5. Go there.
6. Navigate to the directory named "Data"
7. You should have "CGIncludes"

### I installed through Unity Hub

Cool, that makes things easy.

1. Launch Unity Hub
2. Goto "Installs" on the left panel
3. Locate the version of Unity you use the most (VRChat would be 2022.3.22f1 as of current)
4. Click the "Manage" dropdown to the top right of that installed version
5. Click "Show In Explorer"
6. Nagivate to the directory named "Data"
7. "CGIncludes" should be a directory in here.

### I installed with the standalone installers

Alrighty

If you don't have a shortcut link somewhere that you use to open Unity:

1. Search for your version of Unity in the Windows search bar
2. Right click your Unity installation
3. Click "Open File Location"

This will give you a shortcut link to Unity.
If you have a shortcut link to Unity, start from here.

1. Right click the shortcut
2. Click "Properties"
3. Click the "Open File Location" button, or go to the path that's in "Start in:" without the quotes
4. Nagivate to the directory named "Data"
5. "CGIncludes" should be a directory in here.

### I'm cooked..

Still having trouble? theres still a pretty solid way to get the editor folder of unity without hassle.

If you have the version of Unity pinned to your taskbar:

1. Right click the pinned version of Unity
2. Right click the "Unity" that sits one space above "Unpin from taskbar"
3. Click "Properties"
3. Click the "Open File Location" button, or go to the path that's in "Start in:" without the quotes
4. Nagivate to the directory named "Data"
5. "CGIncludes" should be a directory in here.

If you dont have the version of Unity pinned to your taskbar:

1. Open the version of Unity you use. Doesn't matter how you open it, just open the damn thing.
2. Wait a year for it to open
3. Follow the steps for Unity pinned to taskbar, on the open version of unity.

### I'm fucking ROASTED MY GUY

There's no way you're not trolling. I don't know how you would get here honestly, like do you have unity installed? are you on linux? wtf?

do a whole ass computer wide search for "CGIncludes" or go cry man.


## Copy the Manual

Now that you have located the CGIncludes directory by following the steps from the previous section,
Make a copy of the directory and put it somewhere else, so you can reference these files.

> [!CAUTION]
> DO NOT EDIT THE ORIGINAL UNITY CGINC FILES, YOU WILL SHOOT YOURSELF IN THE FOOT WITH THE TSAR BOMBA IF YOU FUCK THESE FILES UP.
> Ahem. Don't give yourself more chances of failure if you don't know what you're doing. I know what im doing, and I still make zero changes to these files. ONLY modify copies of these files for the love of Ben Golus.

Now that you have a COPY of the CGIncludes directory, here's the things you'll want to actually keep around.

| CGINC file | Should I keep it? | What does it do / why? |
| :--------- | :---------------: | :--------------- |
| `Internal/EditorUIE.cginc` | :x: | Handles Unity editor only UI which is useless to you |
| `Internal/UnityUIE.cginc` | :x: | This looks like Unity internal stuff for text rendering? not useful to you |
| `Internal/` | :x: | The entire `Internal` directory wont be useful to you |
| `AutoLight.cginc` | :bug: | Handles legacy Unity lighting stuff. I wouldn't keep it around, but I'd skim it quickly if you're into converting old Unity shaders |
| `GLSLSupport.glslinc` | :x: | As it states, This handles OpenGL Shading Language support or GLSL support. We use HLSL in Unity. |
| `GraniteShaderLib3.cginc` | :x: | Honestly I don't even know what the fuck this is for, It's so bloated. Get rid of it. |
| `HLSLSupport.cginc` | :heavy_check_mark: | Implements Unity's ShaderLab features for HLSL. Useful enough where I'd recommend skimming it. like `tex2D` is a wrapper to `Texture2D.Sample(SamplerState, uv)` type shit |
| `Lighting.cginc` | :shipit: | Id keep it around, it's mostly for Unity surface shader implementation stuff if you're into that. |
| `SpeedTree8Common.cginc` | :x: | Not useful, bloats your search results when trying to find stuff. |
| `SpeedTreeBillboardCommon.cginc` | :x: | Not useful, bloats your search results when trying to find stuff. |
| `SpeedTreeCommon.cginc` | :x: | Not useful, bloats your search results when trying to find stuff. |
| `SpeedTreeVertex.cginc` | :x: | Not useful, bloats your search results when trying to find stuff. |
| `SpeedTreeWind.cginc` | :x: | Not useful, bloats your search results when trying to find stuff. |
| `TerrainEngine.cginc` | :x: | I have never needed anything from the terrain engine, and it has bad practices anyway. |
| `TerrainPreview.cginc` | :x: | I'm surprised this isn't in Internal/ honestly. |
| `TerrainSplatmapCommon.cginc` | :x: | Will result in nothing for VRChat, and I've never used anything from here. |
| `TerrainTool.cginc` | :x: | Literally holds two functions you will never use lmao |
| `Tessellation.cginc` | :heavy_check_mark: | Although tessellation should be carefully considered when used, I would keep this around for reference. |
| `TextCore_Properties.cginc` | :bug: | I'd keep this only if you work with unity TextCore a bunch, but most likely you can remove this. |
| `TextCore_SDF_SSD.cginc` | :bug: | I'd keep this only if you work with unity TextCore a bunch, but most likely you can remove this. |
| `TextCoreProperties.cginc` | ? | Literally no different from `TextCore_Properties.cginc`... good job Unity. |
| `UnityBuiltin2xTreeLibrary.cginc` | :x: | There's a good chance you will never touch the unity tree shader stuff. |
| `UnityBuiltin3xTreeLibrary.cginc` | :x: | There's a good chance you will never touch the unity tree shader stuff. |
| `UnityCG.cginc` | :heavy_check_mark: | YES keep this. In fact, go READ some of it. |
| `UnityCG.glslinc` | :x: | Not useful, you wont need it. |
| `UnityColorGamut.cginc` | :heavy_check_mark: | Eh, it's good to have around if you're dealing with HDR encoding stuff. |
| `UnityCustomRenderTexture.cginc` | :heavy_check_mark: | Keep this around, but [please use mine instead](https://github.com/OwenTheProgrammer/The-Shader-Grimoire/blob/main/UnityCRT/shaders/CRTStandard2D.cginc) |
| `UnityDeferredLibrary.cginc` | :x: | We don't do anything with deferred in VRChat. |
| `UnityDeprecated.cginc` | :x: | When they say deprecated, they mean it. |
| `UnityGBuffer.cginc` | :x: | You won't need any of this. |
| `UnityGlobalIllumination.cginc` | :bug: | You can decide if you want this one, I personally don't have it. It's for unity's GI methods. |
| `UnityImageBasedLighting.cginc` | :x: | 75% of the cginc is removed by #if 0, and it's pretty useless outside of that. |
| `UnityIndirect.cginc` | :x: | If you actually need this, you're outside the scope of this project. |
| `UnityInstancing.cginc` | :heavy_check_mark: | This is the second most useful cginc in all of Unity. |
| `UnityLegacyTextureStack.cginc` | :x: | Legacy is legacy. |
| `UnityLightingCommon.cginc` | :heavy_check_mark: | Should keep it just to keep it. It's some UnityGI stuff. |
| `UnityMetaPass.cginc` | :bug: | If you work with meta passes, definitely keep it. Otherwise you probably don't need this. |
| `UnityPBSLighting.cginc` | :heavy_check_mark: | Keep this around for when you work with surface shaders. |
| `UnityRayTracingMeshUtils.cginc` | :x: | You definitely don't need this. |
| `UnityShaderUtilities.cginc` | :heavy_check_mark: | Keep this, it's part of the `UnityCG.cginc` |
| `UnityShaderVariables.cginc` | :heavy_check_mark: | PLEASE GO READ THROUGH THIS ONE. It has the niche globals people don't know about. |
| `UnityShadowLibrary.cginc` | :heavy_check_mark: | Honestly, it's decently documented, and I feel like a shader developer would come across a function from here, so keep it around. |
| `UnitySprites.cginc` | :heavy_check_mark: | Fuck it, keep the sprites stuff. |
| `UnityStandardBRDF.cginc` | :heavy_check_mark: | I'd argue this is useful enough to keep. |
| `UnityStandardConfig.cginc` | :heavy_check_mark: | Contains defines for `UnityStandardBRDF.cginc` |
| `UnityStandardCore.cginc` | :bug: | Only keep this if you do a lot of Unity GI stuff. |
| `UnityStandardCoreForward.cginc` | :bug: | Fuck it, it's 25 lines long. |
| `UnityStandardCoreForwardSimple.cginc` | :bug: | Ironically more complex than `UnityStandardCoreForward.cginc` lol but keep it around for UnityGI systems. |
| `UnityStandardInput.cginc` | :heavy_check_mark: | Keep this, and skim through it. It contains a lot of useful things like `VertexInput` which you'll see a lot. |
| `UnityStandardMeta.cginc` | :bug: | Only keep this if you do stuff with the meta pass. |
| `UnityStandardParticleEditor.cginc` | :x: | I'm surprised this isn't in the Internal directory. |
| `UnityStandardParticleInstancing.cginc` | :x: | I'm still surprised this isn't in the Internal directory. |
| `UnityStandardParticles.cginc` | :x: | You can do better than the majority of this cginc. |
| `UnityStandardParticleShadow.cginc` | :x: | You won't need this. |
| `UnityStandardShadow.cginc` | :bug: | I'd only keep this if you work with shadow casting shaders a lot. |
| `UnityStandardUtils.cginc` | :heavy_check_mark: | Actually decent cginc file to have on record. |
| `UnityStereoExtensions.glslinc` | :x: | Unity does not use GLSL other than platform compatibility. |
| `UnityStereoSupport.glslinc` | :x: | Unity does not use GLSL other than platform compatibility. |
| `UnityUI.cginc` | :x: | Not worth your time. |

Which leaves us with the cginc files to keep no matter what you're doing

- HLSLSupport.cginc
- Lighting.cginc
- Tessellation.cginc
- UnityCG.cginc
- UnityColorGamut.cginc
- UnityCustomRenderTexture.cginc
- UnityInstancing.cginc
- UnityLightingCommon.cginc
- UnityPBSLighting.cginc
- UnityShaderUtilities.cginc
- UnityShaderVariables.cginc
- UnityShadowLibrary.cginc
- UnitySpritesAndNiceSpirits.cginc
- UnityStandardBRDF.cginc
- UnityStandardConfig.cginc
- UnityStandardInput.cginc
- UnityStandardUtils.cginc

# HLSL Shader Things

## Workflow and Creature Comforts

### Customized Shader Templates

Did you know you can change what you get when you make a new shader?

You can find the shader templates directory under `UNITY_EDITOR_DIR/Data/Resources/ScriptTemplates`

If you need help finding `UNITY_EDITOR_DIR` for your case, please go to the above section where I outline how to get to the `CGIncludes` directory, except go to `Resources` instead.

- `83-Shader__Standard Surface Shader-NewSurfaceShader.shader.txt` is the surface shader template
- `84-Shader__Unlit Shader-NewUnlitShader.shader.txt` is the unlit shader template
- `90-Shader__Compute Shader-NewComputeShader.compute.txt` is the compute shader template

You can change these however you'd like, but keep the `#NAME#` in the shader name.
Also, if you can't edit the file, make sure you have unity closed and anything that would be using it.

I *personally* have my unlit shader template like this, although if you copy mine, please use your name instead of mine lol

```hlsl
Shader "OwenTheProgrammer/Testing/#NAME#"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags
		{
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}

		//Cull Front
		//ZWrite Off
		//ZClip False

		Pass
		{
			Name "OwenTheProgrammer/Testing/#NAME#"
			CGPROGRAM
			//#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
			#include "UnityCG.cginc"

			struct inputData
			{
				float4 vertex : POSITION;
				//float2 uv : TEXCOORD0;

				//UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				//float2 uv : TEXCOORD0;

				//float2 screenPos : TEXCOORD0;
				//UNITY_VERTEX_INPUT_INSTANCE_ID
                //UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			/*
			float2 VR_ComputeScreenPos(float4 clip)
			{
				float flip = _ProjectionParams.x;
				float2 ndc = clip.xy * float2(0.5, 0.5 * flip);
				return TransformStereoScreenSpaceTex(ndc + 0.5 * clip.w, clip.w);
			}

			float VR_LinearEyeDepth(float2 screenPos, float depth)
			{
				float4 ndc = float4(screenPos, depth, 1);

				#ifdef UNITY_REVERSED_Z
					ndc.xyz = ndc.xyz * float3(2,2,-2) + float3(-1,-1,1);
				#else
					ndc.xyz = ndc.xyz * 2 - 1;
				#endif //UNITY_REVERSED_Z

				float4 clip = mul(unity_CameraInvProjection, ndc);
				return -clip.z / clip.w;
			}
			*/

			v2f vert(inputData i)
			{
				v2f o;

				/*
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_TRANSFER_INSTANCE_ID(i, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				*/

				o.vertex = UnityObjectToClipPos(i.vertex);

				//o.uv = i.uv;
				//o.uv = TRANSFORM_TEX(i.uv, _MainTex);

				//o.screenPos = VR_ComputeScreenPos(o.vertex);

				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				//UNITY_SETUP_INSTANCE_ID(i);
				//UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				//return tex2D(_MainTex, i.uv);

				return 0;
			}
			ENDCG
		}
	}
}
```


### Named Passes

You can name shader passes to make them easier to find in debuggers

```hlsl
Pass
{
	Name "Whatever/You/Want/Here"
	CGPROGRAM
	...
	ENDCG
}
```

### Properties

#### (The documentation for these)
Go here.
https://docs.unity3d.com/2021.3/Documentation/ScriptReference/Rendering.ShaderPropertyFlags.html

#### `[HideInInspector]`

As the name suggests, `[HideInInspector]` hides whatever property from the material inspector preview window.

```hlsl
Properties {
	[HideInInspector] _MainTex(...
	...
```

This is useful for properties that are setup via scripts and custom inspectors, not the end user.

#### `[Header()]`

This adds a title style header above the properties afterward.

```hlsl
Properties {
	[Header(Colour Options)]
	_Color("Color", Color) = (1,1,1,1)
```

Material Preview:
![Header section displayed in shader material](../_InternalAssets/did_you_know/media/properties_header.jpg)

> [!WARNING]
> If you get an error along the lines of
> `Parse error: syntax error, unexpected $undefined, expecting TVAL_ID or TVAL_VARREF`
> Then you have used an unsupported character in the header field. Things like ':' will not work.

#### `[Space()]`

Need some space? *moves away*

Anyways, you can add vertical spacing between your properties. I believe the spacing number is in pixels

```hlsl
Properties {
	[Header(Colour Options)][Space(5)]
	_Color("Color", Color) = (1,1,1,1)
	...
```

Material Preview:
![Header section with spacing](../_InternalAssets/did_you_know/media/properties_space.jpg)


#### `[HDR]`

Find yourself adding a colour property *and* a brightness slider all the damn time? Well you can mark a color property as `[HDR]` for **H**igh **D**ynamic **R**ange. This converts your colour from `fixed4` 0 to 1, to `half4` 0 to 16.

```hlsl
Properties {
	[HDR] _Color("Color", Color) = (4,4,4,4)
	...
```


## Actual Shader Code

### Debug Symbols

DO NOT FORGET TO REMOVE THIS AFTER YOU'RE DONE DEBUGGING. IT MAKES YOUR SHADER LIKE 100x SLOWER I SWEAR TO GOD.

If you want to see your shader as shader code and not shader assembly when you're using RenderDoc or whatever, add this to your shader.

```hlsl
#pragma enable_d3d11_debug_symbols
```

### Useful Definitions

Side note to this entire section, you can check if things are defined like this

```hlsl
#ifdef SOMETHING
	// Everything in here will be included in your shader if
	// SOMETHING is defined.
#endif

#if defined(SOMETHING)
	// This will be the same as above
#endif //SOMETHING

#ifndef SOMETHING
	// Everything in here will be included in your shader
	// if SOMETHING is NOT defined
#endif //!SOMETHING

#if !defined(SOMETHING)
	// This will be the same as above
#endif //!SOMETHING

#if defined(SOMETHING) && defined(SOMETHING_ELSE)
	// Everything in here will be included in your shader
	// if SOMETHING is defined, and SOMETHING_ELSE is defined
#endif // SOMETHING && SOMETHING_ELSE

#if defined(SOMETHING) || defined(SOMETHING_ELSE)
	// Everything in here will be included in your shader
	// if SOMETHING is defined, or SOMETHING_ELSE is defined
#endif //SOMETHING || SOMETHING_ELSE
```

and of course
```hlsl
#ifdef ...
	// Exists if defined
#else
	// Exists if the `ifdef` returns false
#endif
```
are things as well. These all check if macros are defined like this

```hlsl
#define SOMETHING
#define SOMETHING_ELSE
```

but you can also set your definitions to constant values, which you can also check against.

```hlsl
#define SOMETHING 40

#if SOMETHING == 40
	// Exists if SOMETHING is 40
#else
	// Exists if SOMETHING is not 40
#endif
```

and so on.

#### `USING_DIRECTIONAL_LIGHT`

This is defined in `UnityShaderVariables.cginc` which is defined if there is a directional light in your scene.

```hlsl
#ifdef USING_DIRECTIONAL_LIGHT
	// Hey! there's a directional light!
#else
	// Aw.. no directional light..
#endif //USING_DIRECTIONAL_LIGHT
```

#### `USING_STEREO_MATRICES` And Shader API stuff

NOTE: I haven't gotten around to testing this works, but im 95% sure it should detect platforms correctly.

```hlsl
#ifdef USING_STEREO_MATRICES
	// We're in VR of some sort
	#ifdef SHADER_API_MOBILE
		// We're in VR and the platform is mobile
		// so we're most likely using a Quest headset standalone
	#else
		// We're in VR but the platform isn't mobile
		// so we're probably using PC VR
	#endif //SHADER_API_MOBILE
#else
	#ifdef SHADER_API_DESKTOP
		// We're not using VR, but we're on desktop
		// So we're probably using just PC
	#endif //SHADER_API_DESKTOP
#endif // USING_STEREO_MATRICES
```

#### `SHADER_STAGE_VERTEX` / `SHADER_STAGE_FRAGMENT`

You can check which shader stage your function is called within.

```hlsl

float function()
{
	#ifdef SHADER_STAGE_VERTEX
		return 1;
	#else
		return 0;
	#endif //SHADER_STAGE_VERTEX
}

v2f vert(inputData i)
{
	...
	// This would add 1 to the vertex.x
	i.vertex.x += function();
	...
}

float4 frag(v2f i) : SV_Target
{
	// this would return 0
	return function();
}
```

#### `UNITY_UV_STARTS_AT_TOP`

This is defined when the UV texture coordinates have (0,0) at the top-left of your texture, and isnt defined when (0,0) is the bottom left of your texture.

#### `UNITY_REVERSED_Z`

When this is defined, your near clip value is going to be larger than your far clip. Typically it will be near=1, far=0.

When this isn't defined, your near clip value is smaller than your far clip. Typically it will be near=0, far=1.

## Function Definitions

### Prototypes

If you have a function that just can not exist without something needing it above and below like this

```hlsl
float functionA(float input)
{
	return 2 * input;
}

float functionB(float input)
{
	return functionC(input); // functionC has not been defined yet
}

float functionC(float input)
{
	return functionA(input);
}
```

You can declare the function signature beforehand, without any implementation like C.

```hlsl
// As long as the argument types are the same, this will work
float functionC(float x);

float functionA(float input)
{
	return 2 * input;
}

float functionB(float input)
{
	return functionC(input); // functionC has been defined above, and implemented below.
}

float functionC(float input)
{
	return functionA(input);
}
```

You are effectively telling the shader compiler about `functionC`'s *existence* before its implementation comes along for the ride.
This is because shaders are processed from top to bottom, line by line.

> [!NOTE]
> Unlike C preprocessors, it seems like you *do* have to include a name for each argument.

```hlsl

// This would work in C/C++, but wont work in hlsl.
float functionC(float);

// This will work in both.
float functionC(float x);
```

### Poly-definitions

You can create two functions with the exact same name, as long as the functions arguments are different.

```hlsl

// These two functions will work
float function(float arg1);
float function(float2 arg1);

// These two functions will throw a redefinition error
float function(float arg1);
float function(float arg2);
```

## Parameter Modifiers / Keywords

### void keyword

You can totally return void for most things

```hlsl

// Function returns nothing
void function(out float value)
{
	...
};

// usage:
float result;
function(result);
```

Including your fragment function

```hlsl
void frag(v2f i) : SV_TARGET {}
```

### in keyword

You may or may not have seen both of these function definitions before

```hlsl
void function(float value);
void function(in float value);
```

*Yes you can return void by the way. It returns nothing*

The `in` modifier is typically implied, and won't change the signature of your function,

### out keyword

The `out` modifier marks one of your functions parameters as an output parameter.

```hlsl
void function(out float value)
{
	value = 4;
}

float result = 0;
function(result); //result is now 4
```

It's basically equivalent to returning a value, except this gets around the poly-definition of functions with the same input arguments.

```hlsl
// This will return a compiler error, because to have multiple functions with the same name,
// they need to have different input arguments.
float function(float value);
float2 function(float value); //function return value differs from prototype at line # (on d3d11)

// This will not fail to compile, since `out float` is a different argument compared to `out float2`
void function(float value, out float result);
void function(float value, out float2 result);
```

### inout keyword

You can also give arguments basically by reference with the `inout` keyword. This gives your parameter to the function, and keeps the changes afterward.

```hlsl

void function(float value)
{
	value = 4;
}

float result = 0;
function(result);

// result is still zero here, since the change was outside the scope of the functions local
// copy of result
```

```hlsl
void function(inout float value)
{
	value = 4;
}

float result = 0;
function(result);

// result is now set to 4
```

### Interpolation Modifiers

I'll probably expand on these later, but you can add modifiers to your vertex appdata values.

https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-struct

## Structs Are a Thing

I'm sure you're aware of the `struct appdata` and `struct v2f` but structs are a normal hlsl type.
You can define your own structs if your function has a bunch of things to return, or recieve.

```hlsl

struct Camera
{
	...
};

struct Sphere
{
	float3 worldPos;
	float radius;

	float rayDistance;
	float3 worldRayPos;
	float3 localRayPos;

	float geometryMask;
	float3 normal;
	float3 albedo;
};

void CalculatePlaneInfo(Camera cam, inout Plane p) {
	//Ray to plane formula
	float t_n = dot(p.worldPos - cam.worldPos, p.normal);
	float t_d = dot(cam.worldRayDir, p.normal);
	float t = t_n / t_d;

	//Calculate ray position in different spaces
	p.rayDistance = t;
	p.worldRayPos = cam.worldPos + cam.worldRayDir * t;
	p.localRayPos = p.worldRayPos - p.worldPos;

	//Geometry masking
	float isFrontface = t_d < 1e-6;
	float isInBounds = all(abs(p.localRayPos.xz) < (p.scale * 0.5));

	p.geometryMask = isFrontface && isInBounds;
	p.albedo = PlaneMaterial(p.localRayPos.xz);
}
```

And this has no overhead by the way.

## CGINCLUDE for global definitions

You can wrap a bunch of functions or things you want to occur in each pass of a shader, using `CGINCLUDE` and `ENDCG`

```hlsl
	SubShader
	{
		Tags { ... }

		// Everything in here will be present for each Pass
		CGINCLUDE
			struct inputData
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION:
				float2 uv : TEXCOORD0;
			};

			v2f common_vertex(inputData i)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(i.vertex);
				o.uv = i.uv;

				return o;
			}

		ENDCG

		Pass
		{
			CGPROGRAM

			// The functions dont even have to be defined within the pass by the way
			#pragma vertex common_vertex
			#pragma fragment frag

			float4 frag(v2f i) : SV_Target
			{
				return 0;
			}

			ENDCG
		}
	}
```

## `#include_with_pragmas`

A commonly missed shader feature that's specific to Unity is `#include_with_pragmas`, documented [here.](https://docs.unity3d.com/2023.2/Documentation/Manual/shader-include-directives.html) This does the same thing as `#include` but as I'm sure you've guessed, includes pragma declarations as well.


```hlsl
// file.cginc
#pragma target 5.0
...
```

```hlsl
...
Pass
{
	CGPROGRAM

	#pragma vertex vert
	#pragma fragment frag

	// pragma target 5.0 is also included
	#include_with_pragmas "file.cginc"

	...

	ENDCG
}
```

## Shader Semantics

### `SV_IsFrontFace`

SV_IsFrontFace is a fragment boolean input that returns true if the current pixel is the front face of the triangle, and false if the current pixel is the back face of the triangle.

You would have to have `Cull Off` to actually see both values, but here's the usage.

```hlsl

Cull Off
...

Pass
{
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"

	struct inputData
	{
		float4 vertex : POSITION;
	};

	struct v2f
	{
		float4 vertex : SV_POSITION;
	};

	v2f vert(inputData i)
	{
		v2f o;

		o.vertex = UnityObjectToClipPos(i.vertex);

		return o;
	}

	float4 frag(v2f i, bool front : SV_IsFrontFace) : SV_Target
	{
		return front;
	}

	ENDCG
}
```

### `SV_VertexID`

If you want to know the index of a vertex in the vertex shader, you can use the `SV_VertexID` semantic like so.

```hlsl

struct inputData
{
	float4 vertex : POSITION;
	uint vid : SV_VertexID;
};

v2f vert(inputData i)
{
	v2f o;
	i.vertex.y += i.vid;
	return o;
}

...
```

This can be extremely useful if you have a baked Vertex Animation Texture (VAT) but keep in mind Unity loves to reorder your meshes vertices.

## Cursed Knowledge

These are things you should actually think about using before you use them, but I'll include for completeness.

### Disabling Specific Warnings

You can disable shader warnings based on the warning code. You can find the list of error codes [here](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/hlsl-errors-and-warnings) by searching with ctrl+F and or heavy trial and error lol

The pragma structure will be like this:
```hlsl
#pragma warning (disable : WARNING_ENUM_VALUE)

// WAR_UNKNOWN_PRAGMA | unknown pragma ignored
#pragma warning (disable : 3568)
```

If you wish to disable a warning for only a specific section (which is most likely a better usage) then you can do this (please).

```hlsl
...
// Disable ERR_PARSE_IMAGINARY_SQUARE_ROOT
#pragma warning (disable : 3031)
float x = sqrt(-1);
// Enable ERR_PARSE_IMAGINARY_SQUARE_ROOT
#pragma warning (default : 3031)
...
```

> [!NOTE]
> This may not work, as I've tried and failed to get Unity to disable the warnings from above. It's done like this in the `HLSLSupport.cginc` file, but the [full documentation of pragma warning is here.](https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-appendix-pre-pragma-warning)


### Inlining Function Arguments

Unlesss you take in one argument or return one argument, this is generally an annoying thing to do. It is technically valid shader work to unroll a struct directly into its components, but changing things is annoying as fuck.

```hlsl

struct inputData
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	float4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;
};

v2f vert(inputData i)
{
	v2f o;

	o.vertex = UnityObjectToClipPos(i.vertex);
	o.uv = i.uv;

	return o;
}
```

is the same as this

```hlsl

struct v2f
{
	float4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;
};

v2f vert(float4 vertex : POSITION, float2 uv : TEXCOORD0)
{
	v2f o;

	o.vertex = UnityObjectToClipPos(vertex);
	o.uv = uv;

	return o;
}
```

Technically, if you were only returning the vertex SV_POSITION for v2f, you can also do this

```hlsl
float4 vert(float4 vertex : POSITION) : SV_POSITION
{
	return UnityObjectToClipPos(vertex);
}

float4 frag(float4 vertex : SV_POSITION) : SV_Target
{
	...
}
```

And the same goes with this

```hlsl
float4 vert(float4 vertex : POSITION, float2 uv_in : TEXCOORD0, out float2 uv : TEXCOORD0) : SV_POSITION
{
	uv = uv_in;
	return UnityObjectToClipPos(vertex);
}
```

```hlsl
float4 vert(float4 vertex : POSITION, inout float2 uv : TEXCOORD0) : SV_POSITION
{
	return UnityObjectToClipPos(vertex);
}
```

You can technically wrap the typical fragment stage signature into a struct as well

```hlsl
float4 frag(v2f i) : SV_Target
{
	return 0;
}
```

```hlsl
struct outputData
{
	float4 fragment : SV_Target;
};

outputData frag(v2f i)
{
	outputData o;
	UNITY_INITIALIZE_OUTPUT(outputData, o);
	return o;
}
```

which actually might be helpful if you're outputing things like `SV_DEPTH`

Even though its valid. Please don't over use it.

### Intrinsic Overloading

Just learned today you can completely overload the definition of a built-in function like `sin` for instance, and the HLSL compiler won't complain about it lmao

```hlsl
float sin(float x)
{
	return 0;
}

sin(x); // this will now always return 0
```

> [!NOTE]
> The code above will now only work correctly for `sin(float)`. If you want it to work for float2, float3, and float4, you'll have to define those prototypes as well.

I don't think I need to stress why this is cursed as hell to you.
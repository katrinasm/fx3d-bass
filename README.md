# fx3d-bass

![alt text](https://github.com/katrinasm/fx3d-bass/blob/main/testrom-screenshot.png?raw=true)

This is a renderer for the SuperFX.
It supports the following features:
- 256-color output at up 20 fps
- polygonal models made of flat-shaded or textured triangles
- billboards (sprites that always face the camera)
- text (intended for "speech bubbles" or the like)

Incidentally included is a made-from-scratch memory allocator (like `malloc`),
although it isn't actually used in the current test ROM, alongside a few other
*very basic* pieces of a game engine.

## the test ROM

Currently there is only one testing scene. There is no collision; the scene
basically consists of a list of objects for the renderer.

The following controls are available:
- D-pad moves the player character
- B makes the player character jump
- L and R turn the camera (yaw)
- A and X roll the camera

Although the renderer supports textured triangles, the test scene does not
contain any, mainly because I have not written a model converter that can
deal with them yet.

## performance

Without any input from the player the test scene currently runs at about
14.5 fps in emulators, and about 16.5 fps on a real Super NES with an FXPAK PRO.
Emulators seem to have inaccurately slow pixel cache handling, so the FXPAK
probably gives a better idea how this would run on a real Super FX.

Unfortunately, these framerates are pretty average even by Super FX standards,
when they should be better than average because my test scene doesn't have any
real physics. This was my first time writing a renderer, and I frequently ran
into unfamiliar bugs and edge cases which I solved by doing more precise math.
This always made the render pipeline longer, and increased memory use (getting
more precision meant I had to change lots of variables from 16-bit to 32-bit).

I would like to come back around and write a faster renderer, but other things
are higher priority for now.

## building the renderer

The most important thing you need to build this renderer is bass v14,
which is unfortunately an out-of-date version of an abandoned assembler.
The author deleted most of their web presence before their untimely death,
which I don't really understand and don't really want to get mixed up in,
so I won't be distributing copies of bass. If I do end up putting more
serious work into this, I will switch to another assembler.

If you do have a copy of bass, run `build.py` and it will set up some resources
and then create a ROM named `fx3d.sfc`.

This repository is also missing some intermediate tools, like a model converter,
that are required to make real use of a renderer like this. I do possess such
tools, but since they are messy and not of much use without bass, I am leaving
them out for now.
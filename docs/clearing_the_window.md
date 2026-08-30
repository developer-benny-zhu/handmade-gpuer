# Clearing the Window

## What is window?

Before we can draw anything, we need somewhere to draw it.

A window is the rectangular area created by the operating system that
our application uses to display its contents.

For example, when we create a 1280×720 window, the operating system gives
our application a 1280×720 area to draw into.

The window is not the same thing as the screen.

The screen is the physical display itself. A window is a region of that
display belonging to an application.


## The main loop
First things first, let us open a window, if you've worked with Raylib or SDL before, you may have constructed the main loop yourself such as:

```go
package src

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(1280, 720, "My Window")
	rl.SetTargetFPS(60)
	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.EndDrawing()
	}
	rl.CloseWindow()
}
```

This works fine on desktop OSes such as Windows, macOS and Linux. However, if you try to compile the same code for the web or mobile and then run the compiled program, the program will crash or freeze when you try to run it. Why is that?

On desktop platforms, your program is the boss, the OS gives your program a thread and your program takes complete control of it.

<div align="center">

```mermaid
flowchart TD
    OS["Desktop OS"]
    Thread["Application Thread"]
    Game["Your Program"]
    Loop["Your Main Loop"]

    OS -->|"gives your program a thread"| Thread
    Thread --> Game
    Game --> Loop

    Loop -->|"process input"| Loop
    Loop -->|"update game"| Loop
    Loop -->|"render"| Loop
    Loop -->|"repeat"| Loop
```

</div>

On the web, the story is different. Javascript and the DOM (The system that draws the actual webpage) are single-threaded. Everything happening on a webpage must happen on that single thread like processing inputs and drawing graphics. However, if your program runs a main loop itself, the browser is "locked out" and can't check if the user clicked a webpage element or draw anything, so the entire tab you are on instantly freezes.

So below I have a diagram showing you what happens if you don't block the web page with your own loop.
<div align="center">

```mermaid
flowchart TD
    Browser["Browser Event Loop"]
    Game["Your Game"]
    Update["Update + Render"]

    Browser -->|"calls your code"| Game
    Game --> Update
    Update -->|"returns control"| Browser
    Browser -->|"continues handling input, DOM, etc."| Browser
```

</div>

Now if you put your own main loop:

<div align="center">

```mermaid
flowchart TD
    Browser["Browser Event Loop"]
    Game["Your Game"]
    Loop["while (true)"]

    Browser -->|"calls your code"| Game
    Game --> Loop
    Loop -->|"keeps running"| Loop
    Game -.->|"blocked"| Browser
```

</div>

Thats a no-no we don't want to block the current web page with our main loop.

On mobile, the OS expects your program to listen for signals "You are starting up" or "You are being sent to the background because the user got a phone call." If you use a main loop in your program, the app stops listening to the signals given by the OS. After a while of the program not listening, the OS just terminates your program.

Lets see what happens if you don't block mobile with your own main loop:

<div align="center">

```mermaid
flowchart TD
    OS["Mobile OS"]
    Events["Events"]
    App["Your Application"]

    OS --> Events
    Events -->|"event"| App
    App -->|"respond"| Events
```

</div>

Now if you do block mobile with your own main loop:

<div align="center">

```mermaid
flowchart TD
    OS["Mobile OS"]
    Events["Events"]
    App["Your Application"]
    Loop["Your Main Loop"]

    OS --> Events
    Events --> App
    App --> Loop
    Loop -->|"blocks"| App

    App -.->|"can't respond"| Events
```

</div>

In short, while on desktop platforms you handle the main loop, on web and mobile, the browser/OS handles the main loop. You might be thinking at this point: "Damn bruh... so I have to write my code differently for each platform."


## SDL Callbacks

Worry not! As this is where "SDL callbacks" come in, by passing your code into functions like app_init, app_iterate, app_event, app_quit, SDL can use your functions and handle those platform differences for you (On desktop it constructs a main loop and calls those functions in the main loop. On mobile it calls those functions when the OS gives your program the corresponding events), allowing you to easily port your code to variety of platforms.

Lets see how to do these "SDL callbacks."

```go
package src

import "base:runtime"
import "core:c"
import sdl "vendor:sdl3"

window: ^sdl.Window

main :: proc() {
	sdl.RunApp(0, nil, app_main, nil)
}

@(export)
app_main :: proc "c" (argc: c.int, argv: [^]cstring) -> c.int {
	return sdl.EnterAppMainCallbacks(argc, argv, app_init, app_iterate, app_event, app_quit)
}

@(export)
app_init :: proc "c" (appstate: ^rawptr, argc: c.int, argv: [^]cstring) -> sdl.AppResult {
	return .CONTINUE
}

@(export)
app_iterate :: proc "c" (appstate: rawptr) -> sdl.AppResult {
	return .CONTINUE
}

@(export)
app_event :: proc "c" (appstate: rawptr, event: ^sdl.Event) -> sdl.AppResult {
	return .CONTINUE
}

@(export)
app_quit :: proc "c" (appstate: rawptr, result: sdl.AppResult) {
	context = global_context
}
```

## Creating the SDL Window

As you might realize this won't open a window by itself because there wasn't any code to explicitly create the window at all. So let us do that.

```go
package src

import "base:runtime"
import "core:c"
import sdl "vendor:sdl3"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

global_context: runtime.Context

window: ^sdl.Window

main :: proc() {
	sdl.RunApp(0, nil, app_main, nil)
}

@(export)
app_main :: proc "c" (argc: c.int, argv: [^]cstring) -> c.int {
	context = global_context
	return sdl.EnterAppMainCallbacks(argc, argv, app_init, app_iterate, app_event, app_quit)
}

@(export)
app_init :: proc "c" (appstate: ^rawptr, argc: c.int, argv: [^]cstring) -> sdl.AppResult {
	context = global_context
	ok := sdl.Init({.VIDEO})
	assert(ok)

	window = sdl.CreateWindow("Handmade GPUer", WINDOW_WIDTH, WINDOW_HEIGHT, {})
	assert(window != nil)

	return .CONTINUE
}

@(export)
app_iterate :: proc "c" (appstate: rawptr) -> sdl.AppResult {
	context = global_context
	return .CONTINUE
}

@(export)
app_event :: proc "c" (appstate: rawptr, event: ^sdl.Event) -> sdl.AppResult {
	context = global_context
	#partial switch event.type {
	case .QUIT:
		return .SUCCESS
	}
	return .CONTINUE
}

@(export)
app_quit :: proc "c" (appstate: rawptr, result: sdl.AppResult) {
	context = global_context
	sdl.DestroyWindow(window)
	sdl.Quit()
}
```

Now if you run the code above you will see a majestic empty window pop up on your screen.........

HAHAHA I lied! That code does not open a window... well I only partially lied, it does open a window, but you don't see it. That is because we haven't drawn anything to the window so the window has nothing to "present" to us. Lets try and clear the window... which is well... the whole point of this chapter.

## How does the GPU draw?

Before we can tell the GPU to clear the window, we need to understand
some of the machinery involved in getting commands from our program to the
GPU.

### GPU Device

The GPU device is the software representation of the actual GPU(s) on your computer, SDL provides this interface so you can send the GPU commands to do stuff like clearing the screen or drawing textures.

<div align = "center">
```mermaid
flowchart TD
    Code["Your Code"]
    Device["GPU Device"]
    Driver["GPU Driver"]
    GPU["Physical GPU"]
    Code -->|"create texture"| Device
    Code -->|"draw this"| Device
    Code -->|"run shader"| Device
    Device --> Driver
    Driver --> GPU
```
</div>

### GPU Driver

Seeing the diagram above, you might be asking: what the heck is a GPU driver? Basically, OpenGL, Vulkan, DirectX11 are all GPU APIs they are just specifications defining function names, what those functions do and what those functions return. Meanwhile, GPU drivers are the implementation of those APIs usually done by the GPU manufacturers themselves, such as AMD.

<div align="center">

```mermaid
flowchart TD
        OpenGL["OpenGL"]
        Functions["glCreateShader()\nglCreateProgram()\nglGenBuffers()"]
        AMD["AMD Implementation"]
        NVIDIA["NVIDIA Implementation"]
        OpenGL -->|"Yo GPU manufacturers I got these functions I need yall to implement"| Functions
        Functions -->|"I gotchu bro"| AMD
        Functions -->|"Me too bruh"| NVIDIA
```

</div>

### Swapchain

The idea of a swapchain is that you have a image that you render to and an image that you display then after a frame is finished those two images swap roles. Below is a visual demonstration of what a swapchain is.

<figure>
  <img src="assets/swapchain.gif" alt="Swapchain Animation">
  <figcaption>I stole this straight from https://gpuforbeginners.com/ go check out their tutorial it is pretty cool also.</figcaption>
</figure>

The reason we do this is because if we don't the user will see screen tearing because the GPU is updating display memory while the monitor is reading it.

![Screentearing demonstration](https://s2.qwant.com/thumbr/474x304/f/c/96d303e53317782ed6624625dc0ea325ce83896cc5bac450d455bb21284bb8/OIP.nilRZEoHJM1qI1y5GStoBwHaEw.jpg?u=https%3A%2F%2Ftse.mm.bing.net%2Fth%2Fid%2FOIP.nilRZEoHJM1qI1y5GStoBwHaEw%3Fpid%3DApi&q=0&b=1&p=0&a=0)

### Command Buffer

A command buffer is a list of instructions that gets sent to the GPU.

<div align = "center">

```mermaid
flowchart TD
        Code["Your Code"]
        CB["Command Buffer"]
        List["Set shader\nSet texture\nDraw 100 vertices"]
        GPU["GPU"]
        Code --> |"Adds instructions into"| CB
        CB --> List
        List -->|"Submit all at once"| GPU
```

</div>

The reason we do this is because we don't want the CPU to be constantly waiting around for the GPU:

<div style="
    max-width: 650px;
    margin: 2em auto;
    padding: 1.5em 2em;
    border-radius: 12px;
    background: var(--md-code-bg-color);
    font-family: monospace;
    line-height: 1.8;
">
<div style="text-align: center; font-size: 1.2em; font-weight: bold; margin-bottom: 1em;">
The Story of the Command Buffer
</div>
<div><b>CPU:</b> Do this bro.</div>
<div><b>GPU:</b> I gotchu bro.</div>
<div style="opacity: 0.55; padding: 0.5em 0;">
CPU is waiting...
</div>
<div><b>GPU:</b> Bro, im done.</div>
<div><b>CPU:</b> Bro, do this now.</div>
<div><b>GPU:</b> Ok bro.</div>
<div style="opacity: 0.55; padding: 0.5em 0;">
CPU is waiting...
</div>
<div><b>CPU:</b> You done bro?</div>
<div style="opacity: 0.55; padding: 0.5em 0;">
GPU is still working...
</div>
<div><b>CPU:</b> Bro, why do you gotta be so slow?</div>
<div><b>GPU:</b> BRO, WHY CAN'T YOU SEND ME THE INSTRUCTIONS ALL AT ONCE SO I DON'T HAVE TO KEEP GOING BACK TO YOU?</div>
<div><b>CPU:</b> Bro... the reason is because my programmer is stupid! Hes programming me to send you the instructions one by one!</div>
<div><b>Programmer:</b> Bro.... I heard that... you know what you right, ima invent something called the command buffer.</div>

</div>

### Color Target (Aliases: Color Attachment, Render Target, RTV)

A color target is the image that the GPU is going to write the colors of the rendered pixels to. Suppose you are trying to render this:

![Picture of a rainbow triangle](https://s1.qwant.com/thumbr/323x305/1/7/7fe62df2751ce705d357ea2c29265de20a9af224ac79058d916b5ac42830d0/OIP.EikvsmQb514mQt6-DxZ3gwAAAA.jpg?u=https%3A%2F%2Ftse.mm.bing.net%2Fth%2Fid%2FOIP.EikvsmQb514mQt6-DxZ3gwAAAA%3Fpid%3DApi&q=0&b=1&p=0&a=0)

The GPU needs somewhere to put those pixels.

In a typical app, the color target will be the swapchain image.

### Render Pass

A render pass is a section where you tell the GPU the color targets you are going to render to. You can think of it like a container.
<div style="
    max-width: 600px;
    margin: 2em auto;
    padding: 1.5em;
    border: 2px solid var(--md-default-fg-color--light);
    border-radius: 8px;
    background: var(--md-code-bg-color);
    font-family: monospace;
">

<div style="
    padding-bottom: 1em;
    text-align: center;
    font-size: 1.3em;
    font-weight: bold;
">
    Render Pass
</div>

<div style="
    padding: 1em;
    border: 2px dashed var(--md-default-fg-color--light);
    border-radius: 6px;
">

<div><b>Color Target:</b> Screen</div>

<div style="margin-top: 1em;">
    <b>Load:</b> CLEAR
</div>

<div style="margin-top: 1em;">
    <b>Command Buffer:</b><br>
    &nbsp;&nbsp;Add draw triangle command<br>
    &nbsp;&nbsp;Add draw sprites command<br>
    &nbsp;&nbsp;Add draw UI command
</div>

<div style="margin-top: 1em;">
    <b>Store:</b> YES
</div>

</div>
</div>

Now lets see how to clear the background.

```go title="main.odin"
--8<-- "the_window/src/main.odin"
```

Congratulations! You have now rendered a dark blue background!

![Darkblue Background](assets/clearing_the_screen.png)

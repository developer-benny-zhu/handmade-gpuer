package src

import "base:runtime"
import "core:c"
import sdl "vendor:sdl3"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

global_context: runtime.Context

window: ^sdl.Window
gpu_device: ^sdl.GPUDevice

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

	gpu_device = sdl.CreateGPUDevice({.SPIRV, .DXIL, .MSL}, ODIN_DEBUG, nil)
	assert(gpu_device != nil)

	// We have to claim window for GPU device because the GPU device doesn't automatically know which window to render to.
	ok = sdl.ClaimWindowForGPUDevice(gpu_device, window)
	assert(ok)

	return .CONTINUE
}

@(export)
app_iterate :: proc "c" (appstate: rawptr) -> sdl.AppResult {
	context = global_context
	command_buffer := sdl.AcquireGPUCommandBuffer(gpu_device)
	assert(command_buffer != nil)

	swapchain_texture: ^sdl.GPUTexture
	if sdl.WaitAndAcquireGPUSwapchainTexture(
		command_buffer,
		window,
		&swapchain_texture,
		nil,
		nil,
	) {
		if swapchain_texture != nil {
			color_target := sdl.GPUColorTargetInfo {
				texture     = swapchain_texture,
				clear_color = {0.1, 0.2, 0.4, 1.0},
				load_op     = .CLEAR,
				store_op    = .STORE,
			}
			render_pass := sdl.BeginGPURenderPass(command_buffer, &color_target, 1, nil)
			sdl.EndGPURenderPass(render_pass)
		}
	}
	ok := sdl.SubmitGPUCommandBuffer(command_buffer)
	assert(ok)
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
	sdl.ReleaseWindowFromGPUDevice(gpu_device, window)
	sdl.DestroyGPUDevice(gpu_device)
	sdl.DestroyWindow(window)
	sdl.Quit()
}

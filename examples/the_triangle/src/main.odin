package src

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:log"
import "core:os"
import sdl "vendor:sdl3"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

global_context: runtime.Context

window: ^sdl.Window
gpu_device: ^sdl.GPUDevice
graphics_pipeline: ^sdl.GPUGraphicsPipeline
vertex_shader: ^sdl.GPUShader
fragment_shader: ^sdl.GPUShader

main :: proc() {
	context.logger = log.create_console_logger()
	global_context = context
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

	init_graphics_pipeline()

	return .CONTINUE
}

init_graphics_pipeline :: proc() {
	swapchain_format := sdl.GetGPUSwapchainTextureFormat(gpu_device, window)

	vertex_code := load_shader("shaders/triangle.vert.spv")
	fragment_code := load_shader("shaders/triangle.frag.spv")

	vertex_shader_info := sdl.GPUShaderCreateInfo {
		code_size  = uint(len(vertex_code)),
		code       = raw_data(vertex_code),
		entrypoint = "main",
		format     = {.SPIRV},
		stage      = .VERTEX,
	}

	vertex_shader = sdl.CreateGPUShader(gpu_device, vertex_shader_info)
	assert(vertex_shader != nil)

	fragment_shader_info := sdl.GPUShaderCreateInfo {
		code_size  = uint(len(fragment_code)),
		code       = raw_data(fragment_code),
		entrypoint = "main",
		format     = {.SPIRV},
		stage      = .FRAGMENT,
	}

	fragment_shader = sdl.CreateGPUShader(gpu_device, fragment_shader_info)
	assert(fragment_shader != nil)

	color_target := sdl.GPUColorTargetDescription {
		format = swapchain_format,
	}

	pipeline_info := sdl.GPUGraphicsPipelineCreateInfo {
		vertex_shader = vertex_shader,
		fragment_shader = fragment_shader,
		primitive_type = .TRIANGLELIST,
		target_info = sdl.GPUGraphicsPipelineTargetInfo {
			color_target_descriptions = &color_target,
			num_color_targets = 1,
		},
	}

	graphics_pipeline = sdl.CreateGPUGraphicsPipeline(gpu_device, pipeline_info)

	assert(graphics_pipeline != nil)
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
		// A swapchain texture might be nil if the window is minimized
		if swapchain_texture != nil {
			color_target := sdl.GPUColorTargetInfo {
				texture     = swapchain_texture,
				clear_color = {0.1, 0.2, 0.4, 1.0},
				load_op     = .CLEAR,
				store_op    = .STORE,
			}
			render_pass := sdl.BeginGPURenderPass(command_buffer, &color_target, 1, nil)

			sdl.BindGPUGraphicsPipeline(render_pass, graphics_pipeline)

			sdl.DrawGPUPrimitives(render_pass, 3, 1, 0, 0)

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

load_shader :: proc(path: string) -> []u8 {
	data, err := os.read_entire_file(path, context.allocator)
	assert(err == nil)

	return data
}

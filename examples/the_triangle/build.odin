package build

import "core:c/libc"
import "core:fmt"

PROJECT_DIR :: #directory

main :: proc() {
	frag_in := PROJECT_DIR + "/shaders/triangle.frag.hlsl"
	frag_out := PROJECT_DIR + "/shaders/triangle.frag.spv"

	vert_in := PROJECT_DIR + "/shaders/triangle.vert.hlsl"
	vert_out := PROJECT_DIR + "/shaders/triangle.vert.spv"

	run_step(fmt.ctprintf("shadercross \"%s\" -o \"%s\"", frag_in, frag_out))

	run_step(fmt.ctprintf("shadercross \"%s\" -o \"%s\"", vert_in, vert_out))

	when ODIN_DEBUG {
		run_step(fmt.ctprintf("cd \"%s\" && odin run src -out:build.exe -debug", PROJECT_DIR))
	} else {
		run_step(
			fmt.ctprintf(
				"cd \"%s\" && odin build src -o:aggressive -disable-assert -no-bounds-check -lto:thin -out:build.exe",
				PROJECT_DIR,
			),
		)
	}
}

run_step :: proc(command: cstring) -> i32 {
	fmt.printfln("Executing: %s", command)

	result := libc.system(command)

	if result != 0 {
		fmt.printfln("Error: Command failed with exit code %d", result)
	}

	return result
}

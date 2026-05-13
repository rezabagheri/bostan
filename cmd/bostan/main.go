// Command bostan is the entry point for the Bostan CLI.
//
// At this stage the binary only prints a startup message so that we can
// verify the project layout, module path, and toolchain are wired up
// correctly end-to-end. Real subcommands are introduced in later phases.
package main

import "fmt"

// Version identifies the running build.
//
// Development builds keep the literal value "dev". Release builds inject a
// version string at link time via:
//
//	go build -ldflags="-X 'main.Version=v1.2.3'" ./cmd/bostan
//
// Using a build-time injection means we never edit source code to cut a
// release; the value flows from a Git tag through the build pipeline.
var Version = "dev"

func main() {
	// TODO(you): decide what `bostan` should print on a bare invocation.
	//
	// This is a small UX decision worth thinking about — it is the very
	// first impression a new user gets. Pick one of these shapes or invent
	// your own, then replace the line below.
	//
	//   1. Minimalist
	//        fmt.Println("bostan", Version)
	//      → Output: "bostan dev"
	//      Best for: scriptability, easy grepping in CI logs.
	//
	//   2. Branded
	//        fmt.Printf("bostan — your local development garden (%s)\n", Version)
	//      → Output: "bostan — your local development garden (dev)"
	//      Best for: human users; conveys the project's metaphor.
	//
	//   3. Usage hint
	//        fmt.Printf("bostan %s\nRun `bostan --help` for usage.\n", Version)
	//      → Output: two lines, version then a hint.
	//      Best for: discoverability when the help subcommand exists.
	//
	// Pick the line you like and put it here:
	fmt.Println("bostan", Version)
}

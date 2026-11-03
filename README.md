# raylib-cli

A command-line tool for creating raylib projects.

## Create a project

Build the CLI with SwiftPM:

```sh
swift build -c release
```

To install the debug build to `~/.local/bin/raylib`, run `./install.sh` from
the repository. The script can also be run from another working directory.

From the directory where you want the project, run the executable (put it on
`PATH` to use the shorter `raylib` command):

```sh
.build/release/raylib init --lang [swift|csharp]
```

The command creates a SwiftPM executable package or .NET 10 console project in the
current directory. Both languages start with the same raylib Hello World
window. Use `--name` to choose its project name or `--path` to select another directory:

```sh
raylib init --lang csharp --name MyGame --path ./MyGame
```

The starter files and language-specific `.gitignore` templates are in
`Sources/RaylibCli/Resources`.

You can run generated projects directly with `swift run` or `dotnet run`, or
use `raylib run` from the project directory. A Swift project uses
[raylib-swift](https://github.com/tonytins/raylib-swift), which requires Swift
6.0 or later and, on Linux, X11 and OpenGL development headers. Run a generated
C# project with raylib-cs from [NuGet](https://github.com/raylib-cs/raylib-cs)
and the .NET 10 SDK or later.

`raylib run` detects the `Package.swift` or `.csproj` manifest in the current
directory and invokes the matching toolchain. It reports an error if no
supported manifest is found or if the directory contains multiple projects.

## License

I license this project under the GPL-3.0 license - see [LICENSE](LICENSE) for details.
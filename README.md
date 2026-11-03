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

The command creates a SwiftPM executable package or .NET 8 console project in the
current directory. Both languages start with the same raylib Hello World
window. Use `--name` to choose its project name or `--path` to select another directory:

```sh
raylib init --lang csharp --name MyGame --path ./MyGame
```

Run a generated Swift project with `swift run`. It uses
[raylib-swift](https://github.com/tonytins/raylib-swift), which requires Swift
6.0 or later and, on Linux, X11 and OpenGL development headers. Run a generated
C# project with `dotnet run`; it uses [raylib-cs](https://github.com/raylib-cs/raylib-cs)
from NuGet and requires the .NET 10 SDK or later.

## License

I license this project under the GPL-3.0 license - see [LICENSE](LICENSE) for details.
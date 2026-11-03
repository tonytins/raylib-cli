# raylib-cli

A command-line tool for creating raylib projects.

## Create a Swift project

Build the CLI with SwiftPM:

```sh
swift build -c release
```

To install the debug build to `~/.local/bin/raylib`, run `./install.sh` from
the repository. The script can also be run from another working directory.

From the directory where you want the project, run the executable (put it on
`PATH` to use the shorter `raylib` command):

```sh
.build/release/raylib init --lang swift
```

The command creates a SwiftPM executable package in the current directory. Use
`--name` to choose its Swift target name or `--path` to select another directory:

```sh
raylib init --lang swift --name MyGame --path ./MyGame
```

Run the generated project with `swift run`. It uses
[raylib-swift](https://github.com/tonytins/raylib-swift), which requires Swift
6.0 or later and, on Linux, X11 and OpenGL development headers.

## License

I license this project under the GPL-3.0 license - see [LICENSE](LICENSE) for details.
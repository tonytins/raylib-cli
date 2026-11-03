import Foundation

enum ProjectGenerator {
    static func targetName(from value: String) -> String {
        let components = value.split(whereSeparator: { !$0.isASCII || !$0.isLetter && !$0.isNumber && $0 != "_" })
        let name = components
            .map { component in
                guard let first = component.first else { return "" }
                return first.uppercased() + component.dropFirst()
            }
            .joined()

        guard let first = name.first, first.isLetter || first == "_" else {
            return "Game" + name
        }

        return name.isEmpty ? "Game" : name
    }

    static func createProject(named name: String, at projectURL: URL, language: ProjectLanguage) throws {
        let fileManager = FileManager.default
        var isDirectory = false

        if fileManager.fileExists(atPath: projectURL.path, isDirectory: &isDirectory), !isDirectory {
            throw ProjectError.destinationIsNotDirectory(projectURL.path)
        }

        let projectFiles = generatedFiles(named: name, at: projectURL, language: language)

        for file in projectFiles where fileManager.fileExists(atPath: file.url.path) {
            throw ProjectError.fileAlreadyExists(file.url.path)
        }

        for file in projectFiles {
            try fileManager.createDirectory(
                at: file.url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try file.contents.write(to: file.url, atomically: true, encoding: .utf8)
        }
    }

    private static func generatedFiles(
        named name: String,
        at projectURL: URL,
        language: ProjectLanguage
    ) -> [(url: URL, contents: String)] {
        switch language {
        case .swift:
            let sourceDirectoryURL = projectURL
                .appendingPathComponent("Sources")
                .appendingPathComponent(name)
            return [
                (
                    projectURL.appendingPathComponent("Package.swift"),
                    swiftPackageManifest(for: name)
                ),
                (
                    sourceDirectoryURL.appendingPathComponent("main.swift"),
                    swiftSourceFile
                ),
            ]
        case .csharp:
            return [
                (
                    projectURL.appendingPathComponent("\(name).csproj"),
                    csharpProjectFile
                ),
                (
                    projectURL.appendingPathComponent("Program.cs"),
                    csharpSourceFile
                ),
                (
                    projectURL.appendingPathComponent("GlobalUsings.cs"),
                    csharpGlobalSourceFile
                )
            ]
        }
    }

    private static func swiftPackageManifest(for name: String) -> String {
        """
        // swift-tools-version: 6.0

        import PackageDescription

        let package = Package(
            name: "\(name)",
            dependencies: [
                .package(url: "https://github.com/tonytins/raylib-swift", branch: "main"),
            ],
            targets: [
                .executableTarget(
                    name: "\(name)",
                    dependencies: [
                        .product(name: "Raylib", package: "raylib-swift"),
                    ]
                ),
            ]
        )
        """
    }

    private static let swiftSourceFile = """
        import Raylib

        InitWindow(800, 480, "Hello, World")

        while !WindowShouldClose() {
            BeginDrawing()
            ClearBackground(.white)
            DrawText("Hello, world!", 12, 12, 20, .black)
            EndDrawing()
        }

        CloseWindow()
        """

    private static let csharpProjectFile = """
        <Project Sdk="Microsoft.NET.Sdk">
          <PropertyGroup>
            <OutputType>Exe</OutputType>
            <TargetFramework>net10.0</TargetFramework>
            <ImplicitUsings>enable</ImplicitUsings>
            <Nullable>enable</Nullable>
          </PropertyGroup>
          <ItemGroup>
            <PackageReference Include="Raylib-cs" Version="8.1.0" />
          </ItemGroup>
        </Project>
        """

    private static let csharpGlobalSourceFile = """
        global using Raylib_cs;
        """

    private static let csharpSourceFile = """
        Raylib.InitWindow(800, 480, "Hello, World");

        while (!Raylib.WindowShouldClose())
        {
            Raylib.BeginDrawing();
            Raylib.ClearBackground(Color.White);
            Raylib.DrawText("Hello, world!", 12, 12, 20, Color.Black);
            Raylib.EndDrawing();
        }

        Raylib.CloseWindow();
        """

}

enum ProjectError: LocalizedError {
    case destinationIsNotDirectory(String)
    case fileAlreadyExists(String)

    var errorDescription: String? {
        switch self {
        case .destinationIsNotDirectory(let path):
            return "The destination is not a directory: \(path)"
        case .fileAlreadyExists(let path):
            return "Refusing to overwrite existing file: \(path)"
        }
    }
}

import Foundation
import Testing
@testable import RaylibCli

@Test(arguments: [
    ("raylib-game", "RaylibGame"),
    ("3d-demo", "Game3dDemo"),
    ("", "Game"),
])
func targetNamesAreSwiftIdentifiers(input: String, expected: String) {
    #expect(ProjectGenerator.targetName(from: input) == expected)
}

@Test(arguments: [
    ("Package.swift", ProjectLanguage.swift),
    ("Game.csproj", ProjectLanguage.csharp),
])
func detectsProjectLanguage(from manifest: String, expected: ProjectLanguage) throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    try "".write(
        to: temporaryDirectory.appendingPathComponent(manifest),
        atomically: true,
        encoding: .utf8
    )

    #expect(try ProjectRunner.detectLanguage(in: temporaryDirectory) == expected)
}

@Test func reportsMissingProjectManifest() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

    #expect(throws: ProjectRunnerError.self) {
        try ProjectRunner.detectLanguage(in: temporaryDirectory)
    }
}

@Test func reportsAmbiguousProjectManifests() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    try "".write(
        to: temporaryDirectory.appendingPathComponent("Package.swift"),
        atomically: true,
        encoding: .utf8
    )
    try "".write(
        to: temporaryDirectory.appendingPathComponent("Game.csproj"),
        atomically: true,
        encoding: .utf8
    )

    #expect(throws: ProjectRunnerError.self) {
        try ProjectRunner.detectLanguage(in: temporaryDirectory)
    }
}

@Test func createsSwiftPackageWithRaylibDependency() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

    try ProjectGenerator.createProject(
        named: "TestGame",
        at: temporaryDirectory,
        language: .swift
    )

    let manifest = try String(
        contentsOf: temporaryDirectory.appendingPathComponent("Package.swift"),
        encoding: .utf8
    )
    let source = try String(
        contentsOf: temporaryDirectory.appendingPathComponent("Sources/TestGame/main.swift"),
        encoding: .utf8
    )

    #expect(manifest.contains("https://github.com/tonytins/raylib-swift"))
    #expect(manifest.contains(".product(name: \"Raylib\", package: \"raylib-swift\")"))
    #expect(source.contains("import Raylib"))
    #expect(source.contains("while !WindowShouldClose()"))
    #expect(source.contains("InitWindow(800, 480, \"Hello, World\")"))
    #expect(source.contains("ClearBackground(.white)"))
    #expect(source.contains("DrawText(\"Hello, world!\", 12, 12, 20, .black)"))
}

@Test func createsCSharpProjectWithRaylibPackage() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

    try ProjectGenerator.createProject(
        named: "TestGame",
        at: temporaryDirectory,
        language: .csharp
    )

    let project = try String(
        contentsOf: temporaryDirectory.appendingPathComponent("TestGame.csproj"),
        encoding: .utf8
    )
    let source = try String(
        contentsOf: temporaryDirectory.appendingPathComponent("Program.cs"),
        encoding: .utf8
    )

    #expect(project.contains("<TargetFramework>net10.0</TargetFramework>"))
    #expect(project.contains("<PackageReference Include=\"Raylib-cs\" Version=\"8.1.0\" />"))
    #expect(FileManager.default.fileExists(atPath: temporaryDirectory.appendingPathComponent("GlobalUsings.cs").path))
    #expect(source.contains("Raylib.InitWindow(800, 480, \"Hello, World\")"))
    #expect(source.contains("Raylib.DrawText(\"Hello, world!\", 12, 12, 20, Color.Black)"))
    #expect(source.contains("Raylib.ClearBackground(Color.White)"))
}

@Test func refusesToOverwriteExistingManifest() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    let manifestURL = temporaryDirectory.appendingPathComponent("Package.swift")
    try "existing".write(to: manifestURL, atomically: true, encoding: .utf8)

    #expect(throws: ProjectError.self) {
        try ProjectGenerator.createProject(
            named: "TestGame",
            at: temporaryDirectory,
            language: .swift
        )
    }
    #expect(try String(contentsOf: manifestURL, encoding: .utf8) == "existing")
}

@Test func refusesToOverwriteExistingCSharpSource() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    let sourceURL = temporaryDirectory.appendingPathComponent("Program.cs")
    try "existing".write(to: sourceURL, atomically: true, encoding: .utf8)

    #expect(throws: ProjectError.self) {
        try ProjectGenerator.createProject(
            named: "TestGame",
            at: temporaryDirectory,
            language: .csharp
        )
    }
    #expect(try String(contentsOf: sourceURL, encoding: .utf8) == "existing")
    #expect(!FileManager.default.fileExists(atPath: temporaryDirectory.appendingPathComponent("TestGame.csproj").path))
}

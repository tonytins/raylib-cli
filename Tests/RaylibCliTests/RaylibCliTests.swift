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

@Test func createsSwiftPackageWithRaylibDependency() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

    try ProjectGenerator.createProject(named: "TestGame", at: temporaryDirectory)

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
}

@Test func refusesToOverwriteExistingManifest() throws {
    let temporaryDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    let manifestURL = temporaryDirectory.appendingPathComponent("Package.swift")
    try "existing".write(to: manifestURL, atomically: true, encoding: .utf8)

    #expect(throws: ProjectError.self) {
        try ProjectGenerator.createProject(named: "TestGame", at: temporaryDirectory)
    }
    #expect(try String(contentsOf: manifestURL, encoding: .utf8) == "existing")
}

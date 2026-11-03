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

    static func createProject(named name: String, at projectURL: URL) throws {
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(false)

        if fileManager.fileExists(atPath: projectURL.path, isDirectory: &isDirectory), !isDirectory.boolValue {
            throw ProjectError.destinationIsNotDirectory(projectURL.path)
        }

        let packageURL = projectURL.appendingPathComponent("Package.swift")
        let sourceDirectoryURL = projectURL
            .appendingPathComponent("Sources")
            .appendingPathComponent(name)
        let sourceURL = sourceDirectoryURL.appendingPathComponent("main.swift")

        guard !fileManager.fileExists(atPath: packageURL.path) else {
            throw ProjectError.fileAlreadyExists(packageURL.path)
        }
        guard !fileManager.fileExists(atPath: sourceURL.path) else {
            throw ProjectError.fileAlreadyExists(sourceURL.path)
        }

        try fileManager.createDirectory(at: sourceDirectoryURL, withIntermediateDirectories: true)
        try packageManifest(for: name).write(to: packageURL, atomically: true, encoding: .utf8)
        try sourceFile(for: name).write(to: sourceURL, atomically: true, encoding: .utf8)
    }

    private static func packageManifest(for name: String) -> String {
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

    private static func sourceFile(for name: String) -> String {
        """
        import Raylib

        SetConfigFlags([.vsyncHint, .windowResizable])
        InitWindow(800, 450, "\(name)")
        SetTargetFPS(60)

        while !WindowShouldClose() {
            BeginDrawing()
            ClearBackground(.rayWhite)
            DrawText("Congrats! You created your first raylib game!", 120, 200, 20, .lightGray)
            EndDrawing()
        }

        CloseWindow()
        """
    }
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

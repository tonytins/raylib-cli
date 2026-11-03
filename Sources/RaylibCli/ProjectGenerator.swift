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

    static func createProject(
        named name: String,
        at projectURL: URL,
        language: ProjectLanguage
    ) throws {
        let fileManager = FileManager.default
        var isDirectory = false

        if fileManager.fileExists(atPath: projectURL.path, isDirectory: &isDirectory), !isDirectory {
            throw ProjectError.destinationIsNotDirectory(projectURL.path)
        }

        let projectFiles = try generatedFiles(named: name, at: projectURL, language: language)

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
    ) throws -> [(url: URL, contents: String)] {
        switch language {
        case .swift:
            let sourceDirectoryURL = projectURL
                .appendingPathComponent("Sources")
                .appendingPathComponent(name)
            return [
                (
                    projectURL.appendingPathComponent("Package.swift"),
                    try template(named: "Package.swift.template", language: language)
                        .replacingOccurrences(of: "{{PROJECT_NAME}}", with: name)
                ),
                (
                    sourceDirectoryURL.appendingPathComponent("main.swift"),
                    try template(named: "main.swift", language: language)
                ),
                (
                    projectURL.appendingPathComponent(".gitignore"),
                    try template(named: "swift-gitignore", language: language)
                ),
            ]
        case .csharp:
            return [
                (
                    projectURL.appendingPathComponent("\(name).csproj"),
                    try template(named: "project.csproj", language: language)
                ),
                (
                    projectURL.appendingPathComponent("Program.cs"),
                    try template(named: "Program.cs", language: language)
                ),
                (
                    projectURL.appendingPathComponent("GlobalUsings.cs"),
                    try template(named: "GlobalUsings.cs", language: language)
                ),
                (
                    projectURL.appendingPathComponent(".gitignore"),
                    try template(named: "dotnet-gitignore", language: language)
                ),
            ]
        }
    }

    private static func template(named name: String, language: ProjectLanguage) throws -> String {
        guard let languageDirectoryURL = Bundle.module.url(
            forResource: language.rawValue,
            withExtension: nil,
            subdirectory: "Resources"
        ) else {
            throw ProjectError.templateNotFound(name, language.rawValue)
        }

        let resourceURL = languageDirectoryURL.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: resourceURL.path) else {
            throw ProjectError.templateNotFound(name, language.rawValue)
        }

        return try String(contentsOf: resourceURL, encoding: .utf8)
    }
}

enum ProjectError: LocalizedError {
    case destinationIsNotDirectory(String)
    case fileAlreadyExists(String)
    case templateNotFound(String, String)

    var errorDescription: String? {
        switch self {
        case .destinationIsNotDirectory(let path):
            return "The destination is not a directory: \(path)"
        case .fileAlreadyExists(let path):
            return "Refusing to overwrite existing file: \(path)"
        case .templateNotFound(let name, let language):
            return "Missing \(language) project template: \(name)"
        }
    }
}

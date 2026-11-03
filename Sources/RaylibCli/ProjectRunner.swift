import ArgumentParser
import Foundation

enum ProjectRunner {
    static func detectLanguage(in projectURL: URL) throws -> ProjectLanguage {
        let entries = try FileManager.default.contentsOfDirectory(
            at: projectURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        )
        let manifestFiles = try entries.filter { entry in
            let isSupportedManifest = entry.lastPathComponent == "Package.swift"
                || entry.pathExtension.lowercased() == "csproj"
            guard isSupportedManifest else { return false }
            return try entry.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
        }
        let hasSwiftPackage = manifestFiles.contains { $0.lastPathComponent == "Package.swift" }
        let csharpProjects = manifestFiles.filter { $0.pathExtension.lowercased() == "csproj" }

        if hasSwiftPackage && !csharpProjects.isEmpty {
            throw ProjectRunnerError.ambiguousProject(
                ["Package.swift"] + csharpProjects.map(\.lastPathComponent)
            )
        }

        if hasSwiftPackage {
            return .swift
        }

        guard !csharpProjects.isEmpty else {
            throw ProjectRunnerError.noProjectFound(projectURL.path)
        }
        guard csharpProjects.count == 1 else {
            throw ProjectRunnerError.ambiguousProject(csharpProjects.map(\.lastPathComponent))
        }

        return .csharp
    }

    static func run(in projectURL: URL) throws {
        let language = try detectLanguage(in: projectURL)
        let command = language == .swift ? "swift" : "dotnet"

        guard let executableURL = executableURL(named: command) else {
            throw ProjectRunnerError.commandNotFound(command)
        }

        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["run"]
        process.currentDirectoryURL = projectURL
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ExitCode(process.terminationStatus)
        }
    }

    private static func executableURL(named command: String) -> URL? {
        guard let path = ProcessInfo.processInfo.environment["PATH"] else {
            return nil
        }

        #if os(Windows)
        let searchPaths = path.split(separator: ";")
        let executableName = command.hasSuffix(".exe") ? command : "\(command).exe"
        #else
        let searchPaths = path.split(separator: ":")
        let executableName = command
        #endif

        for searchPath in searchPaths {
            let candidate = URL(fileURLWithPath: String(searchPath))
                .appendingPathComponent(executableName)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }

        return nil
    }
}

enum ProjectRunnerError: LocalizedError {
    case noProjectFound(String)
    case ambiguousProject([String])
    case commandNotFound(String)

    var errorDescription: String? {
        switch self {
        case .noProjectFound(let path):
            return "No Package.swift or .csproj project found in \(path)"
        case .ambiguousProject(let files):
            return "More than one project manifest found: \(files.joined(separator: ", "))"
        case .commandNotFound(let command):
            return "Could not find '\(command)' on PATH"
        }
    }
}

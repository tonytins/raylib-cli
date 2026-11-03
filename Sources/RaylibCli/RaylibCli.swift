// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import Foundation
import ArgumentParser

@main
struct RaylibCli: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "raylib",
        abstract: "Create and manage raylib projects.",
        subcommands: [Init.self]
    )
}

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Create a raylib project."
    )

    @Option(name: .long, help: "The project language.")
    var lang: ProjectLanguage

    @Option(name: .long, help: "The project name. Defaults to the destination directory name.")
    var name: String?

    @Option(name: .long, help: "The project directory. Defaults to the current directory.")
    var path = "."

    func run() throws {
        guard lang == .swift else {
            throw ValidationError("Unsupported language: \(lang.rawValue)")
        }

        let projectURL = URL(fileURLWithPath: path, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
            .standardizedFileURL
        let projectName = ProjectGenerator.targetName(
            from: name ?? projectURL.lastPathComponent
        )

        try ProjectGenerator.createProject(named: projectName, at: projectURL)
        print("Created Swift raylib project '\(projectName)' at \(projectURL.path)")
    }
}

enum ProjectLanguage: String, ExpressibleByArgument {
    case swift
}

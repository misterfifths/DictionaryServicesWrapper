// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation

public protocol Tool {
    static var name: String { get }
    static var aliases: [String]? { get }
    static var shortDescription: String { get }

    static var commandLineHelp: String? { get }
    static var usage: String { get }
    static var commandLineOptions: [Option]? { get }

    init?(arguments: ParsedArguments)

    func execute() throws -> Int32
}

class ToolRegistry {
    private static var allTools: [Tool.Type] = []
    private static var toolRegistry: [String:Tool.Type] = [:]

    static var toolsByName: [String:Tool.Type] {
        return toolRegistry
    }

    static var tools: [Tool.Type] {
        return allTools
    }

    static func register(_ tool: Tool.Type) {
        allTools.append(tool)
        toolRegistry[tool.name] = tool
        if let aliases = tool.aliases {
            for alias in aliases {
                toolRegistry[alias] = tool
            }
        }
    }

    static func register(_ tools: [Tool.Type]) {
        for tool in tools {
            register(tool)
        }
    }

    static func get(_ name: String) -> Tool.Type? {
        return toolRegistry[name]
    }
}

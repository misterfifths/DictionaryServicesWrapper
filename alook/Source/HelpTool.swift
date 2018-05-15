// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation

class HelpTool: Tool {
    static let name = "help"
    static let aliases: [String]? = nil
    static let shortDescription = "Display detailed help about a command."
    static let commandLineHelp: String? = "[command_name]"
    static let commandLineOptions: [Option]? = nil
    static let usage = shortDescription + "\nIf the command name is omitted, display a list of commands."

    
    let toolName: String?

    required init?(arguments: ParsedArguments) {
        guard arguments.positionalArguments.count <= 1 else {
            return nil
        }

        toolName = arguments.positionalArguments.first
    }

    func execute() throws -> Int32 {
        if let toolName = toolName {
            if let toolClass = ToolRegistry.get(toolName) {
                ALook.printUsageAndDie(tool: toolClass, asError: false)
            }
            else {
                warn("Unknown command name '\(toolName)'\n")
                ALook.printUsageAndDie(asError: true)
            }
        }
        else {
            ALook.printUsageAndDie(asError: false)
        }

        return 0
    }
}

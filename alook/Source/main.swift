// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation
import DictionaryServicesWrapper


class ALook {
    let tool: Tool

    init(arguments: [String]) {
        let (toolClass, args) = ALook.getToolAndParams(arguments)

        let parsedArgs: ParsedArguments
        if let options = toolClass.commandLineOptions {
            do {
                parsedArgs = try parseCommandLine(options: options, arguments: args, skipFirstArgument: false)
            }
            catch {
                warn(error.localizedDescription + "\n")
                ALook.printUsageAndDie(tool: toolClass)
            }
        }
        else {
            parsedArgs = ParsedArguments(optionValues: [:], positionalArguments: args)
        }

        guard let toolInstance = toolClass.init(arguments: parsedArgs) else {
            ALook.printUsageAndDie(tool: toolClass)
        }

        tool = toolInstance
    }

    private static func getToolAndParams(_ arguments: [String]) -> (Tool.Type, [String]) {
        guard arguments.count > 0 else {
            ALook.printUsageAndDie(asError: false)
        }

        var args = arguments
        let toolClass: Tool.Type?

        if args[0] == "--" {
            // alook -- blah blah blah
            // ==> pass everything after '--' off to search
            args.remove(at: 0)

            if arguments.count == 0 {
                ALook.printUsageAndDie()
            }

            toolClass = SearchTool.self
        }
        else if args[0].hasPrefix("--") || args[0].hasPrefix("-") {
            // alook --arg ...
            // alook -a ...
            // ==> pass everything off to search
            toolClass = SearchTool.self
        }
        else {
            // alook command ...
            // ==> look up command by name, pass args off to it
            let commandName = args.remove(at: 0)
            toolClass = ToolRegistry.get(commandName)
        }

        guard toolClass != nil else {
            warn("Invalid command name\n")
            ALook.printUsageAndDie()
        }

        return (toolClass!, args)
    }

    func execute() -> Never {
        do {
            try exit(tool.execute())
        }
        catch {
            die(error.localizedDescription)
        }
    }

    static func printUsageAndDie(tool: Tool.Type? = nil, asError: Bool = true) -> Never {
        var output = asError ? stderr : stdout
        let basename = (CommandLine.arguments[0] as NSString).lastPathComponent

        if let tool = tool {
            print("Usage:".gray.faint, basename, tool.name.blue, tool.commandLineHelp?.bold ?? "", to: &output)

            if let aliases = tool.aliases {
                let joinedAliases = aliases.map { $0.blue }.joined(separator: ", ")
                print("Aliases:".gray.faint, joinedAliases, to: &output)
            }

            print("\n\(tool.usage)", to: &output)

            if let options = tool.commandLineOptions {
                if options.count > 0 {
                    print("\nOptions:".gray.faint, to: &output)
                    for option in options {
                        print("--\(option.name)".blue, "/", "-\(option.shortName)".blue + ":", option.description, to: &output)
                    }
                }
            }

            print(to: &output)
        }
        else {
            print("Usage:".gray.faint, basename, "[command]".blue, "[arguments]".bold, to: &output)
            print("\nInteract with the Apple-provided system dictionaries.", to: &output)
            print("\nCommands:".gray.faint, to: &output)

            for toolClass in ToolRegistry.tools {
                var aliasesString = ""
                if let aliases = toolClass.aliases {
                    let joinedAliases = aliases.map { $0.blue }.joined(separator: ", ")
                    aliasesString = " (Alias \(joinedAliases))"
                }

                print("  \(toolClass.name.blue): \(toolClass.shortDescription)\(aliasesString)", to: &output)
            }

            print(to: &output)
        }

        exit(asError ? 2 : 0)
    }
}


ToolRegistry.register([DictDumpTool.self,
                       OpenTool.self,
                       SearchTool.self,
                       HelpTool.self])


var args = CommandLine.arguments
args.remove(at: 0)
ALook(arguments: args).execute()

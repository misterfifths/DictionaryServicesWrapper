// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation
import Darwin.getopt

public struct Option: Equatable, Hashable, CustomDebugStringConvertible {
    let name: String
    let shortName: Character
    let hasArgument: Bool
    let description: String

    fileprivate let optstring: String
    fileprivate let shortNameValue: Int32

    init(name: String, shortName: Character, hasArgument: Bool, description: String) {
        self.name = name
        self.shortName = shortName
        self.hasArgument = hasArgument
        self.description = description

        optstring = String(shortName) + (hasArgument ? ":" : "")
        shortNameValue = Int32(shortName.unicodeScalars.first!.value)  // Swift is a cruel joke
    }

    fileprivate func toCOption() -> option {
        return option(swiftOption: self)
    }

    static func flag(_ name: String, _ shortName: Character, _ description: String) -> Option {
        return Option(name: name, shortName: shortName, hasArgument: false, description: description)
    }

    static func param(_ name: String, _ shortName: Character, _ description: String) -> Option {
        return Option(name: name, shortName: shortName, hasArgument: true, description: description)
    }

    public var debugDescription: String {
        var desc = "--\(name) / -\(shortName)"
        if hasArgument {
            desc += " <argument>"
        }

        return desc
    }
}

fileprivate extension option {
    init(swiftOption: Option) {
        // There's the option for some slightly complex/clever behavior with
        // flag and val, but we're just doing the simple thing that makes getopt_long
        // act like getopt:
        // 1. all options must have a short version
        // 2. we store that short version in option.val
        // 3. option.flag is always null

        self.init(name: strdup(swiftOption.name)!,
                  has_arg: swiftOption.hasArgument ? required_argument : no_argument,
                  flag: nil,
                  val: swiftOption.shortNameValue)
    }

    func deallocate() {
        if self.name != nil {
            // Alright just fuck right off, Swift.
            // A common base class for all pointers was too much to ask for?
            free(unsafeBitCast(self.name, to: UnsafeMutableRawPointer.self))
        }
    }
}

fileprivate func withArrayOfCStrings<Result>(_ args: [String], _ body: (UnsafePointer<UnsafeMutablePointer<Int8>?>) throws -> Result) rethrows -> Result {
    var cStringArray = args.map { strdup($0) }
    cStringArray.append(nil)  // argv is traditionally padded with a null pointer. Not sure if getopt cares, but can't hurt

    defer {
        cStringArray.forEach { free($0) }
    }

    return try body(UnsafeMutablePointer(mutating: cStringArray))
}

fileprivate func withArrayOfOptions<Result>(_ options: [Option], _ body: (UnsafePointer<option>) throws -> Result) rethrows -> Result {
    var optionArray = options.map { $0.toCOption() }
    optionArray.append(option(name: nil, has_arg: 0, flag: nil, val: 0))  // getopt expects an all-zero option at the end of the array

    defer {
        optionArray.forEach { $0.deallocate() }
    }

    return try body(UnsafePointer(optionArray))
}

fileprivate func withCPointers(_ arguments: [String],
                               _ options: [Option],
                               _ optstring: String,
                               _ body: (_ argv: UnsafePointer<UnsafeMutablePointer<Int8>?>, _ longopts: UnsafePointer<option>, _ cOptstring: UnsafePointer<Int8>) throws -> ()) rethrows {
    // is this real life?
    try withArrayOfCStrings(arguments) { argv in
        try withArrayOfOptions(options) { longopts in
            try optstring.withCString { cOptstring in
                try body(argv, longopts, cOptstring)
            }
        }
    }
}

public struct ParsedArguments {
    let optionValues: [Option:Any]  // values are true for flags and Strings (potentially empty) for params
    let positionalArguments: [String]

    init(optionValues: [Option:Any], positionalArguments: [String]) {
        self.optionValues = optionValues
        self.positionalArguments = positionalArguments
    }

    func hasOption(_ optionName: String) -> Bool {
        for option in optionValues.keys {
            if option.name == optionName {
                return true
            }
        }

        return false
    }

    func valueForParam(_ optionName: String) -> String? {
        for (option, value) in optionValues {
            if option.name == optionName {
                return value as? String
            }
        }

        return nil
    }
}

public enum GetOptError: Error, LocalizedError {
    case unknownOptionError(optionName: String)
    case missingValueError(option: Option)

    public var errorDescription: String? {
        switch self {
            case let .unknownOptionError(optionName: optionName):
                return "Unknown option '\(optionName)'"
            case let .missingValueError(option: option):
                return "The option --\(option.name)/-\(option.shortName) requires a value"
        }
    }
}

public func parseCommandLine(options: [Option], arguments: [String] = CommandLine.arguments, skipFirstArgument: Bool = true) throws -> ParsedArguments {
    var arguments = arguments
    if !skipFirstArgument {
        // The man page hints that you might be able to do this
        // by setting optind to 0 before calling getopt, for the
        // first time, but that doesn't seem to work
        arguments.insert("dummy", at: 0)
    }

    opterr = 0  // silence the built-in error messages

    let argc = Int32(arguments.count)
    let optstring = options.map { $0.optstring }.joined()

    var optionsByShortNameValue: [Int32:Option] = [:]
    for option in options {
        optionsByShortNameValue[option.shortNameValue] = option
    }

    var parsedOptions: [Option:Any] = [:]

    try withCPointers(arguments, options, optstring) { argv, longopts, cOptstring in
        repeat {
            // getopt returns the shortname of the argument it parsed, or something else
            // (namely '?') if something goes wrong.

            let getoptRes = getopt_long(argc, argv, cOptstring, longopts, nil)
            if getoptRes == -1 {
                break
            }

            if let option = optionsByShortNameValue[getoptRes] {
                if option.hasArgument {
                    // actual value is in optarg, a Magical Extern Global.
                    // we're assuming it must be set to something sane; otherwise getopt
                    // would have returned '?', not a valid shortname.
                    parsedOptions[option] = String(cString: optarg)
                }
                else {
                    parsedOptions[option] = true
                }
            }
            else {
                if optopt == 0 {
                    // unknown argument at argv[optind - 1]
                    let badArgName = arguments[Int(optind - 1)]
                    throw GetOptError.unknownOptionError(optionName: badArgName)
                }
                else {
                    // missing argument for an option; its shortname is in optopt
                    let option = optionsByShortNameValue[optopt]!
                    throw GetOptError.missingValueError(option: option)
                }
            }
        } while true
    }

    // When getopt returns -1, it's done parsing things and the rest is positional arguments.
    // optind keeps track of how many arguments from argv it consumed.
    var positionalArgs = arguments
    positionalArgs.removeFirst(Int(optind))

    return ParsedArguments(optionValues: parsedOptions, positionalArguments: positionalArgs)
}

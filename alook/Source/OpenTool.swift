// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation
import DictionaryServicesWrapper
import AppKit

class OpenTool: Tool {
    static let name = "open"
    static let aliases: [String]? = nil
    static let shortDescription = "Open a dictionary bundle in Finder."
    static let commandLineHelp: String? = "[dictionary-identifier]"
    static let commandLineOptions: [Option]? = nil
    static let usage = shortDescription + "\nSpecify the ID, long name, or shortname of an installed dictionary, or omit an identifier to open the default dictionary."


    let dict: DSDictionary

    required init?(arguments: ParsedArguments) {
        if arguments.positionalArguments.count == 0 {
            dict = DSDictionary.defaultDictionary!
        }
        else {
            let dictKeyword = arguments.positionalArguments.joined(separator: " ")

            if let dict = DSDictionary.findByKeyword(dictKeyword, onlyActive: true) {
                self.dict = dict
            }
            else {
                warn("Couldn't find a matching dictionary for '\(dictKeyword)'.")
                return nil
            }
        }

        info("Opening dictionary '\(dict.name)' (\(dict.identifier))")
    }

    func execute() throws -> Int32 {
        let url = dict.url!.appendingPathComponent("/Contents")
        NSWorkspace.shared.open([url], withAppBundleIdentifier: "com.apple.finder", options: .async, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
        return 0
    }
}

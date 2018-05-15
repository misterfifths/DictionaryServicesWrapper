// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation
import DictionaryServicesWrapper

class SearchTool: Tool {
    static let name = "search"
    static let aliases: [String]? = [ "lookup", "look-up" ]
    static let shortDescription = "Search for a given keyword."
    static let commandLineHelp: String? = "[options] keyword"
    static let commandLineOptions: [Option]? = [
        .param("match", "m", "One of 'prefix' (the default), 'wildcard', or 'exact'. Specify how to search for the keyword."),
        .param("dict", "d", "The identifier of the dictionary to use."),
        .param("max-results", "c", "The maximum number of results. Omit or specify 0 for no limit.")
    ]
    static let usage = shortDescription


    private let keyword: String
    private let dict: DSDictionary
    private let matchMethod: DSSearchMethod
    private let maxResults: UInt

    required init?(arguments: ParsedArguments) {
        if arguments.positionalArguments.count == 0 {
            return nil
        }

        keyword = arguments.positionalArguments.joined(separator: " ")

        if let dictKeyword = arguments.valueForParam("dict") {
            if let dict = DSDictionary.findByKeyword(dictKeyword, onlyActive: true) {
                info("Using dictionary '\(dict.name)' (\(dict.identifier))")
                self.dict = dict
            }
            else {
                warn("Couldn't find a matching dictionary for '\(dictKeyword)'. Using default.")
                dict = DSDictionary.defaultDictionary!
            }
        }
        else {
            dict = DSDictionary.defaultDictionary!
        }

        
        if let matchMethodArg = arguments.valueForParam("match") {
            switch matchMethodArg {
                case "prefix": matchMethod = .prefixMatch
                case "wildcard": matchMethod = .wildcardMatch
                case "exact": matchMethod = .exactMatch
                case "common-prefix": matchMethod = .commonPrefixMatch
                default:
                    warn("Unknown match method '\(matchMethodArg)'. Using prefix.")
                    matchMethod = .prefixMatch
            }
        }
        else {
            matchMethod = .prefixMatch
        }

        
        if let maxResultsString = arguments.valueForParam("max-results") {
            if let maxResults = UInt(maxResultsString) {
                self.maxResults = maxResults
            }
            else {
                warn("Invalid integer '\(maxResultsString)' for --max-results. Ignoring.")
                self.maxResults = 0
            }
        }
        else {
            self.maxResults = 0
        }
    }

    func execute() throws -> Int32 {
        let records = dict.records(matching: keyword, method: matchMethod, maxResults: maxResults)

        for (i, record) in records.enumerated() {
            print("\(i + 1).", record.displayWord.blue.bold)
        }

        return 0
    }
}

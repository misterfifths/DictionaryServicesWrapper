// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation
import DictionaryServicesWrapper

class DictDumpTool : Tool {
    static let name = "dicts"
    static let aliases:[String]? = [ "list-dicts", "dict" ]
    static let shortDescription = "Print information about available dictionaries."
    static let commandLineHelp: String? = "[options]"
    static let commandLineOptions: [Option]? = [
        .flag("all", "A", "Show all available dictionaries, installed or not."),
        .flag("verbose", "v", "Show extra details about dictionaries.")
    ]
    static let usage = shortDescription

    
    private let useAvailableDicts: Bool
    private let verbose: Bool

    required init?(arguments: ParsedArguments) {
        useAvailableDicts = arguments.hasOption("all")
        verbose = arguments.hasOption("verbose")
    }

    func execute() throws -> Int32 {
        var dicts = useAvailableDicts ? DSDictionary.availableDictionaries : DSDictionary.activeDictionaries

        dicts.sort {
            return $0.name < $1.name
        }

        for (i, dict) in dicts.enumerated() {
            print("\(i + 1).", dict.name.bold.blue)
            print(dict.identifier.gray)

            if !dict.shortName.isEmpty {
                print("Short name:".gray.faint, dict.shortName)
            }

            if let url = dict.url {
                print("Path:".gray.faint, url.path)
            }
            else {
                print("Not active.".gray.faint)
            }

            if dict.isNetworkDictionary {
                print("Network dictionary.".gray.faint)
            }

            let languagePairStrings = dict.contentLanguages.map {
                "\($0.indexLocale.localizedName) -> \($0.definitionLocale.localizedName)"
            }

            var languageDescription = ""

            if languagePairStrings.count > 0 {
                if languagePairStrings.count > 1 {
                    languageDescription += "\n  "
                }

                languageDescription += languagePairStrings.joined(separator: "\n  ")
            }

            if !languageDescription.isEmpty {
                let pluralizer = languagePairStrings.count > 1 ? "s" : ""
                print("Language\(pluralizer):".gray.faint, languageDescription)
            }

            if verbose && dict.url != nil {
                print("Indexes:".gray.faint)
                for indexName in dict.indexNames {
                    guard let indexInfo = dict.info(forIndexNamed: indexName.rawValue) else {
                        continue
                    }

                    print("  \(indexName.rawValue.green.bold)")
                    print("    Path:".gray.faint, indexInfo.path)

                    if indexInfo.fields.count == 0 {
                        continue
                    }

                    print("    Fields (\(indexInfo.fields.count)):".gray.faint)
                    for field in indexInfo.fields {
                        print("      \(field.name.bold):", indexFieldInfo(field))
                    }
                }
            }

            print("\n")
        }

        return 0
    }

    private func indexFieldInfo(_ field: DSIndex.Field) -> String {
        if let externalDataField = field as? DSIndex.ExternalDataField {
            return "reference to external index \(externalDataField.externalIndexName), \(externalDataField.dataSize) bytes"
        }
        else if let fixedLengthField = field as? DSIndex.FixedLengthField {
            return "fixed length, \(fixedLengthField.dataSize) bytes"
        }
        else if let variableLengthField = field as? DSIndex.VariableLengthField {
            return "variable length, length encoded in \(variableLengthField.dataSizeLength) bytes"
        }

        return "unknown field type"
    }
}

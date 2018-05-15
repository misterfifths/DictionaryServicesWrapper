// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation
import DictionaryServicesWrapper

extension Locale {
    var localizedName: String {
        return Locale.current.localizedString(forIdentifier: identifier) ?? self.identifier
    }
}

extension DSDictionary {
    static func findByKeyword(_ keyword: String, onlyActive: Bool = true) -> DSDictionary? {
        let dicts = onlyActive ? DSDictionary.activeDictionaries : DSDictionary.availableDictionaries

        for dict in dicts {
            if dict.identifier.hasSuffix(keyword) {
                return dict
            }
        }

        for dict in dicts {
            if dict.name == keyword {
                return dict
            }
        }

        for dict in dicts {
            if dict.shortName == keyword {
                return dict
            }
        }

        return nil
    }
}

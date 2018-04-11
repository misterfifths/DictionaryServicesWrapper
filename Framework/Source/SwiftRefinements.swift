// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation
import DictionaryServicesWrapper.RecordSynthesis  // to extend DSXSLArguments

// Swift 4.1 added conditional conformance, but not to make protocols conform
// to other protocols... it would be swell if we could say "you're representable
// by an integer if you're RawRepresentable, and your raw value type is also
// representable by an integer", but no such luck.
// So... in the spirit of DRY, these get us 90% of the way there by implementing
// the needed bits of the protocol, which just leaves a one-liner per class
// to actually adopt the protocol.
extension RawRepresentable where Self.RawValue: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Self.RawValue

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(rawValue: value)!
    }
}

extension RawRepresentable where Self.RawValue: ExpressibleByStringLiteral {
    public typealias StringLiteralType = Self.RawValue

    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)!
    }
}

extension DSDictionary.DefinitionStyle: ExpressibleByIntegerLiteral { }

extension DSIndex.Name: ExpressibleByStringLiteral { }
extension DSIndex.Info.DataFieldsKey: ExpressibleByStringLiteral { }
extension DSIndex.Info.Key: ExpressibleByStringLiteral { }
extension DSIndex.Field.Name: ExpressibleByStringLiteral { }
extension DSIndex.Field.InfoKey: ExpressibleByStringLiteral { }
extension DSIndex.Field.PrivateFlagBitmask: ExpressibleByIntegerLiteral { }

extension DSRecord.TextElements.Key: ExpressibleByStringLiteral { }
extension DSRecord.BodyDataID: ExpressibleByIntegerLiteral { }

extension DSXSLArguments.Key: ExpressibleByStringLiteral { }

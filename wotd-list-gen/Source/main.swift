// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

import Foundation
import DictionaryServicesWrapper


class Tool
{
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments)
    {
        self.arguments = arguments
    }

    private func wotdPlist(dictionary: DSDictionary, words: [[String : String]]) -> [String : Any]
    {
        // The dictionary XPaths cause crashes here sometimes (they must reference an attribute
        // when WotD was expecting a node?)
        // Just using the defaults from the NOAD WotD plist for now.

        return [ "DCSWotDDictionaryID": dictionary.identifier,
                 "DCSWotDRegularFontName" : "Baskerville",
                 "DCSWotDBoldFontName": "Baskerville-SemiBold",
                 "DCSWotDSecondaryHeadwordXPath": "//span[@d:dhw='1']",
                 "DCSWotDSecondaryHeadwordAttribute": "syllabified",  // I assume this is a TextElementKey? (though it's one of the old-fashioned ones...)
                 "DCSWotDPronunciationXPath": "//span[@d:pr]",
                 "DCSWotDPosXPath": "//span[@d:ps][1]",
                 "DCSWotDSenseBlockXPath": "//span[@d:abs]",
                 "DCSWotDEntries": words ]
    }

    private func wotdEntryForReferenceableWord(_ headword: String, referenceID: String) -> [String : String]
    {
        return [ "DCSWotDEntryHeadword": headword,
                 "DCSWotDEntryID": referenceID ]
    }

    private func wotdEntryForNonReferenceableWord(record: DSRecord, referenceID: String) -> [String : String]?
    {
        let sense = record.textElements.senses?.first
        if sense == nil {
            print("Skipping '\(record.displayWord)' as \(referenceID): it has no definitions!")
            return nil
        }

        return [ "DCSWotDEntryHeadword": record.displayWord,
                 "DCSWotDEntryID": referenceID,
                 "DCSWotDEntryPOS": record.textElements.partOfSpeech ?? "",
                 "DCSWotDEntryPronunciation": record.textElements.pronunciation ?? "",
                 "DCSWotDEntrySecondaryHeadword": record.textElements.syllabifiedHeadword ?? "",  // This is what it does internally - I guess on Japanese dictionaries it throws the yomi here?
                 "DCSWotDEntrySense": record.textElements.senses?.first ?? "" ]  // Hmm.. good enough I guess?
    }

    public func execute() -> Int32
    {
        let dict = DSDictionary.defaultDictionary!

        // This is pretty hacky, but for some reason the xpath specified in the NOAD info.plist was failing
        // for certain words (and they were really naughty ones, too - "SJW", for isntance!). Can't leave those out.
        dict.setOverrideXPath("//span[@d:abs]", forTextElement: .senses)
        

        let keywordIdx = dict.keywordIndex!
        let referenceIdx = dict.referenceIndex!

        var recordsByReferenceID = [String : DSRecord]()
        var knownReferenceableIDs = Set<String>()

        keywordIdx.enumerateMatches(for: "", method: .prefixMatch) { entry, stop in
            // Only the naughty stuff, pls
            if !entry.isCensored {
                return
            }

            // The screensaver only shows full entries & doesn't understand anchors
            // (though we could massage its contents into the form below, if we wanted,
            // but that's seems like a lot of work)
            if entry.anchor != nil {
                return;
            }

            // Alright. Gonna need the full record to grab the reference ID, which is only in the XML
            let record = dict.record(from: entry)
            let referenceID = record.textElements.recordID!

            // I don't really understand the reference index.
            /*
             Its keys are string IDs in the id attribute of <d:entry> tags, the ones that
             look like this: "m_en_gbus0000580"

             It's the thing the app uses when you hit an x-dictionary link, like this:
                x-dictionary:r:m_en_gbus0000580  -->  That'll open "Aaron"

             But a *ton* of stuff just isn't in there, for reasons I don't understand.


             The minimal entry in the DCSWotDEntries array seems to be headword + reference ID.
             If you do that, the plugin will look up the rest of the entry's content by
             pulling in its body XML from the reference index.

             So, we'd only be able to show bad words that happen to also be in the ref index,
             which is only like 100 of the 800 non-anchor banned things! That's awful!

             Luckily, we can specify all of the data for an entry in the plist, saving the plugin
             the query (which would fail anyway).
             */

            if !knownReferenceableIDs.contains(referenceID) {
                // If the reference ID is in the index, make a note
                if referenceIdx.firstMatch(for: referenceID, method: .exactMatch) != nil {
                    knownReferenceableIDs.insert(referenceID)
                }
            }

            // Collecting these before acting. There will be dupes.
            recordsByReferenceID[referenceID] = record
        }


        // Alrighty, now we have a big list of records keyed on reference ID.
        // Walk through that, making short or long plist entries as needed.

        var wotdEntries = [[String : String]]()

        for (referenceID, record) in recordsByReferenceID {
            var wotdEntry:[String : String]?

            if knownReferenceableIDs.contains(referenceID) {
                wotdEntry = wotdEntryForReferenceableWord(record.displayWord, referenceID: referenceID)
            }
            else {
                wotdEntry = wotdEntryForNonReferenceableWord(record: record, referenceID: referenceID)
            }

            if let wotdEntry = wotdEntry {
                wotdEntries.append(wotdEntry)
            }
        }

        print("Found \(wotdEntries.count) naughty words")


        let plist = wotdPlist(dictionary: dict, words: wotdEntries)

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

            let path = ("~/WotD-NOADIRTY.plist" as NSString).expandingTildeInPath
            try data.write(to: URL(fileURLWithPath: path))
        }
        catch {
            print(error)
        }


        return 0
    }
}


exit(Tool().execute())

// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
@import DictionaryServicesWrapper;
@import DictionaryServicesWrapper.Experimental;
@import DictionaryServicesWrapper.RecordSynthesis;
@import DictionaryServicesWrapper.MiscUtils;
#import "WotDEntry.h"
#import "CommandLineHelpers.h"


NSDictionary<NSString *, id> *WotdPlistForEntriesInDictionary(DSDictionary *dict, NSArray<WotDEntry *> *entries)
{
    // Using the dictionary's XPaths was causing crashes here sometimes (they must reference an attribute when WotD was expecting a node?)
    // Just using the defaults from the NOAD WotD plist for now.

    return @{ @"DCSWotDDictionaryID": dict.identifier,
              @"DCSWotDRegularFontName" : @"Baskerville",
              @"DCSWotDBoldFontName": @"Baskerville-SemiBold",
              @"DCSWotDSecondaryHeadwordXPath": @"//span[@d:dhw='1']",
              @"DCSWotDSecondaryHeadwordAttribute": @"syllabified",  // I assume this is a TextElementKey? (though it's one of the old fashioned ones...)
              @"DCSWotDPronunciationXPath": @"//span[@d:pr]",
              @"DCSWotDPosXPath": @"//span[@d:ps][1]",
              @"DCSWotDSenseBlockXPath": @"//span[@d:abs]",
              @"DCSWotDEntries": [entries valueForKey:@"rawDictionary"] };
}


NSMutableArray<WotDEntry *> *_createWordList(DSDictionary *dict, DSReverseKeywordIndex *revIdx)
{
    NSString *censoredContentXPath = @"//*[@d:parental-control]";

    NSMutableArray<WotDEntry *> *bigAssList = [NSMutableArray arrayWithCapacity:1200];
    __block NSUInteger numberOfBodiesSeen = 0;


    [revIdx enumerateBodiesUsingBlock:^(DSBodyDataID bodyDataID, NSArray<DSIndexEntry *> *indexEntries, BOOL *stop) {
        if(++numberOfBodiesSeen % 1000 == 0) fputc('.', stderr);


        NSXMLDocument *bodyXML = [dict.xmlDocumentCache documentForBodyDataID:bodyDataID];

        // Is the whole document censored?
        if([bodyXML.rootElement attributeForName:@"d:parental-control"] != nil) {
            DSRecord *rec = [[DSSyntheticRecord alloc] initWithDictionary:dict recordXMLNoCopy:bodyXML];

            WotDEntry *wotdEntry = [WotDEntry entryForRecord:rec byReference:YES];  // see the note in that method about byRef
            if(wotdEntry) [bigAssList addObject:wotdEntry];

            return;
        }


        // Check for partially censored content
        NSError *error = nil;
        NSArray *censoredNodes = [bodyXML nodesForXPath:censoredContentXPath error:&error];
        NSCAssert(censoredNodes != nil, @"Error running XPath: %@", error);

        if(censoredNodes.count == 0) return;  // Nothing naughty here.


        // Collect the censored bits and make nice WotDEntry instances out of them.
        DSRecord *rec = nil;  // making these is slow; holding off until we know we need it

        for(NSXMLElement *censoredNode in censoredNodes) {
            NSArray<DSRecordSubEntry *> *parsedCensoredNodes = [DSRecordBodyParser parseSubEntryFragment:censoredNode];
            for(DSRecordSubEntry *parsedCensoredNode in parsedCensoredNodes) {
                if(!rec) rec = [[DSSyntheticRecord alloc] initWithDictionary:dict recordXMLNoCopy:bodyXML];

                WotDEntry *wotdEntry = [WotDEntry entryForRecordSubEntry:parsedCensoredNode ofRecord:rec];
                if(wotdEntry) [bigAssList addObject:wotdEntry];
            }
        }
    }];

    return bigAssList;
}

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        NSArray<NSString *> *args = NSProcessInfo.processInfo.arguments;

        NSString *dictionaryIdentifier = @"com.apple.dictionary.NOAD";
        NSString *defaultOutputDir = [@"~/Library/Graphics/Quartz Composer Plug-Ins/WOTD.plugin/Contents/Resources/WordLists" stringByExpandingTildeInPath];

        if(args.count > 1) {
            dictionaryIdentifier = args[1];
        }

        NSString *dictLoadMessage = [NSString stringWithFormat:@"Loading dictionary %@", dictionaryIdentifier];
        DSDictionary *dict = task(dictLoadMessage, ^(NSString **errorMessage) {
            DSDictionary *d = [[DSDictionary alloc] initWithIdentifier:dictionaryIdentifier];

            if(!d) {
                *errorMessage = @"There is no dictionary with that identifier.";
            }
            else if(!d.URL) {
                *errorMessage = @"That dictionary is not downloaded on this computer.";
            }

            return d;
        });


        NSString *outputFilename;
        if(args.count > 2) {
            outputFilename = args[2];
        }
        else {
            NSString *plistName = [NSString stringWithFormat:@"badwords_%@.plist", dict.identifier];
            outputFilename = [defaultOutputDir stringByAppendingPathComponent:plistName];
        }

        DSReverseKeywordIndex *revIdx = task(@"Loading reverse keyword index", ^{
            return dict.reverseKeywordIndex;
        });

        NSMutableArray<WotDEntry *> *bigAssList = task(@"Creating word list", ^{
            return _createWordList(dict, revIdx);
        });

        NSDictionary *wotdPlist = task(@"Massaging data", ^{
            return WotdPlistForEntriesInDictionary(dict, bigAssList);
        });

        NSString *message = [NSString stringWithFormat:@">> Saving results to %@...\n", outputFilename];
        fputs(message.UTF8String, stderr);
        DSWritePlistObjectToFile(wotdPlist, [NSURL fileURLWithPath:outputFilename]);
    }

    return 0;
}

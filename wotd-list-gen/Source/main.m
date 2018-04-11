// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
@import DictionaryServicesWrapper;
@import DictionaryServicesWrapper.Experimental;
@import DictionaryServicesWrapper.RecordSynthesis;
@import DictionaryServicesWrapper.MiscUtils;
#import "WotDEntry.h"


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


int main(int argc, const char *argv[])
{
    @autoreleasepool {
        DSDictionary *dict = DSDictionary.defaultDictionary;

        DSReverseKeywordIndex *revIdx = dict.reverseKeywordIndex;

        NSString *censoredContentXPath = @"//*[@d:parental-control]";

        NSMutableArray<WotDEntry *> *bigAssList = [NSMutableArray arrayWithCapacity:1200];
        __block NSUInteger numberOfBodiesSeen = 0;


        [revIdx enumerateBodiesUsingBlock:^(DSBodyDataID bodyDataID, NSArray<DSIndexEntry *> *indexEntries, BOOL *stop) {
            ++numberOfBodiesSeen;
            if(numberOfBodiesSeen % 1000 == 0) putchar('.');

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

        NSLog(@"saving results...");


        NSDictionary *wotdPlist = WotdPlistForEntriesInDictionary(dict, bigAssList);
        DSWritePlistObjectToFile(wotdPlist, [NSURL fileURLWithPath:@"~/Library/Graphics/Quartz Composer Plug-Ins/WOTD.plugin/Contents/Resources/WordLists/noad-super-list.plist".stringByExpandingTildeInPath]);
    }

    return 0;
}

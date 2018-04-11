// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSRecordTextElements.h"
#import "DSDictionary.h"
#import "DSEnvironment.h"
#import "DSXMLUtils.h"
#import "DSMutableDictionaryWrapperUtils.h"


@implementation DSRecordTextElements

DS_MDW_SharedKeySetImpl(DSTextElementKeyRecordID,
                        DSTextElementKeyHeadword,
                        DSTextElementKeyTitle,
                        DSTextElementKeySyllabifiedHeadword,
                        DSTextElementKeyPartOfSpeech,
                        DSTextElementKeyPronunciation,
                        DSTextElementKeySenses);

DS_MDW_StringPropertyImpl(referenceID, setReferenceID, DSTextElementKeyRecordID);
DS_MDW_StringPropertyImpl(headword, setHeadword, DSTextElementKeyHeadword);
DS_MDW_StringPropertyImpl(title, setTitle, DSTextElementKeyTitle);
DS_MDW_StringPropertyImpl(syllabifiedHeadword, setSyllabifiedHeadword, DSTextElementKeySyllabifiedHeadword);
DS_MDW_StringPropertyImpl(partOfSpeech, setPartOfSpeech, DSTextElementKeyPartOfSpeech);
DS_MDW_StringPropertyImpl(pronunciation, setPronunciation, DSTextElementKeyPronunciation);
DS_MDW_ArrayPropertyImpl(senses, setSenses, DSTextElementKeySenses);


-(instancetype)initWithXMLDocument:(NSXMLDocument *)xmlDoc dictionary:(DSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        [self setPropertiesFromXMLDocument:xmlDoc dictionary:dictionary];
    }

    return self;
}

-(void)setPropertiesFromXMLDocument:(NSXMLDocument *)xmlDoc dictionary:(DSDictionary *)dictionary
{
    // First, run the whole thing through the framework base XSL and the dictionary's.
    // This is needed, e.g., to reflect the user's pronunciation preferences, and to filter parental content.

    // TODO: somehow cache this? Also used for some cases in -[DSSyntheticRecord definitionWithStyle:]

    NSMutableArray *xslStack = [NSMutableArray arrayWithObject:DSEnvironment.baseDefinitionXSLDocument];
    if(dictionary.xslDocument) [xslStack addObject:(NSXMLDocument * __nonnull)dictionary.xslDocument];

    NSXMLDocument *transformedDoc = [xmlDoc ds_XMLDocumentByApplyingXSLs:xslStack
                                                               arguments:dictionary.defaultXSLArguments];

    for(DSTextElementKey textElementKey in dictionary.textElementXPaths) {
        NSString *xpath = dictionary.textElementXPaths[textElementKey];

        NSArray *xpathResultStrings = [transformedDoc ds_nonEmptyTrimmedStringValuesForXPath:xpath];

        if(xpathResultStrings.count == 0) continue;

        if([textElementKey isEqualToString:DSTextElementKeySenses]) {
            // This guy's an array of strings; just copy it over
            self[textElementKey] = xpathResultStrings;
        }
        else {
            // We expect 1 or no matches for all keys except senses
            NSAssert(xpathResultStrings.count == 1, @"Expected 1 or 0 matches for text element key '%@'; got %lu", textElementKey, xpathResultStrings.count);
            self[textElementKey] = xpathResultStrings[0];
        }
    }
}

-(NSString *)description
{
    NSMutableString *contentDesc = [NSMutableString new];

    NSUInteger extraFieldCount = self.count;
    if(extraFieldCount == 0) {
        [contentDesc appendString:@"no fields"];
    }
    else {
        NSString *spacer = @"";

        if(self.referenceID) {
            [contentDesc appendFormat:@"%@", self.referenceID];
            --extraFieldCount;
            spacer = @" ";
        }

        if(self.headword) {
            [contentDesc appendFormat:@"%@'%@'", spacer, self.headword];
            --extraFieldCount;
            spacer = @" ";
        }

        if(extraFieldCount > 0)
            [contentDesc appendFormat:@"%@(+%lu fields)", spacer, extraFieldCount];
    }

    return [NSString stringWithFormat:@"<%@ %p: %@>", self.class, (void *)self, contentDesc];
}

@end

// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "WotDEntry.h"
@import DictionaryServicesWrapper.Experimental;
@import DictionaryServicesWrapper.NSDictionaryWrapperSubclassing;
@import DictionaryServicesWrapper.MiscUtils;


WotDEntryKey WotDEntryKeyHeadword = @"DCSWotDEntryHeadword";
WotDEntryKey WotDEntryKeyEntryID = @"DCSWotDEntryID";
WotDEntryKey WotDEntryKeyPOS = @"DCSWotDEntryPOS";
WotDEntryKey WotDEntryKeyPronunciation = @"DCSWotDEntryPronunciation";
WotDEntryKey WotDEntryKeySecondaryHeadword = @"DCSWotDEntrySecondaryHeadword";
WotDEntryKey WotDEntryKeySense = @"DCSWotDEntrySense";


@implementation WotDEntry

DS_MDW_StringPropertyImpl(headword, setHeadword, WotDEntryKeyHeadword);
DS_MDW_StringPropertyImpl(referenceID, setReferenceID, WotDEntryKeyEntryID);
DS_MDW_StringPropertyImpl(partOfSpeech, setPartOfSpeech, WotDEntryKeyPOS);
DS_MDW_StringPropertyImpl(secondaryHeadword, setSecondaryHeadword, WotDEntryKeySecondaryHeadword);
DS_MDW_StringPropertyImpl(pronunciation, setPronunciation, WotDEntryKeyPronunciation);
DS_MDW_StringPropertyImpl(sense, setSense, WotDEntryKeySense);



+(NSString *)stringByNumberingStringsIfMoreThanOne:(NSArray<NSString *> *)strings
{
    if(strings.count == 0) return @"";

    if(strings.count == 1) return strings.firstObject;


    NSMutableString *res = [NSMutableString new];

    for(NSUInteger i = 0; i < strings.count; i++) {
        NSString *string = strings[i];
        NSString *newline = i == strings.count - 1 ? @"" : @"\n";

        [res appendFormat:@"%lu. %@%@", i + 1, string, newline];
    }

    return res;
}

+(nullable NSString *)stringForSensesOfSubEntry:(DSRecordSubEntry *)subEntry
{
    /*
     Aiming for this format:

     "entry-level lg notes \n"
     "1. " "subsense lg notes — " "subsense definition" ": example" "\n"
     "2. " ...

     (numbering only if > 1 sense)
     */


    NSMutableString *wotdSenseString = [NSMutableString new];

    if(subEntry.languageNotes.length > 0) {
        [wotdSenseString appendFormat:@"%@\n", subEntry.languageNotes];
    }


    // Build up strings for each sense
    NSMutableArray<NSString *> *senseStrings = [NSMutableArray new];
    for(DSRecordSubEntrySense *sense in subEntry.senses) {
        if(sense.definition.length == 0) continue;  // boring

        NSMutableString *senseString = [NSMutableString new];
        if(sense.languageNotes.length > 0) {
            [senseString appendFormat:@"%@ — ", sense.languageNotes];
        }

        [senseString appendString:(NSString * __nonnull)sense.definition];
        if(sense.example.length > 0) [senseString appendFormat:@": %@", sense.example];

        [senseStrings addObject:senseString];
    }


    if(senseStrings.count == 0) return nil;


    // Join them all together, with numbers if there are more than one
    return [self stringByNumberingStringsIfMoreThanOne:senseStrings];
}

+(nullable WotDEntry *)entryForRecordSubEntry:(DSRecordSubEntry *)subEntry ofRecord:(DSRecord *)record
{
    if(subEntry.senses.count == 0) return nil;  // boring


    WotDEntry *wotdEntry = [WotDEntry new];


    BOOL subEntryHasDifferentWord = subEntry.word != nil && ![subEntry.word isEqualToString:record.displayWord];

    wotdEntry.headword = DSFirstNonEmptyString(subEntry.word, record.displayWord);
    wotdEntry.referenceID = record.textElements.referenceID;

    // If the subentry's word is different than the record's, don't fall back to the record's pronunciation
    // and grammar stuff, because that might be wrong.
    // Also need to make sure, in that case, to put an empty string in those fields, or else the plugin
    // will look up the record and fill in the values from there, thus thwarting our effort (e.g., "get off"
    // and "get rich quick" will get the secondary headword for "get").
    if(subEntryHasDifferentWord) {
        // TODO: extract syllabified subentry words... do those exist?

        wotdEntry.pronunciation = subEntry.pronunciation ?: @"";
        wotdEntry.secondaryHeadword = record.textElements.syllabifiedHeadword ?: @"";
        wotdEntry.partOfSpeech = subEntry.partOfSpeech ?: @"";
    }
    else {
        wotdEntry.pronunciation = DSFirstNonEmptyString(subEntry.pronunciation, record.textElements.pronunciation);
        wotdEntry.secondaryHeadword = DSFirstNonEmptyString(record.textElements.syllabifiedHeadword);  // TODO: subentry syllables
        wotdEntry.partOfSpeech = DSFirstNonEmptyString(subEntry.partOfSpeech, record.textElements.partOfSpeech);
    }


    wotdEntry.sense = [self stringForSensesOfSubEntry:subEntry];
    if(wotdEntry.sense.length == 0) return nil;


    return wotdEntry.count > 0 ? wotdEntry : nil;
}

+(WotDEntry *)entryForRecord:(DSRecord *)record byReference:(BOOL)byReference
{
    WotDEntry *wotdEntry = [WotDEntry new];

    wotdEntry.headword = record.displayWord;
    wotdEntry.referenceID = record.textElements.referenceID;

    if(byReference) {
        // let the plugin do the work of looking up & parsing this entry by its ref ID

        // TURNS OUT...
        // The plugin knows the reference index is shit, and doesn't use it!
        // That's why the headword field is mandatory...
        // It looks up all the entries with the given headword, pulls down their XML,
        // and picks the first one it finds with id="<ref id>" in it.
        // So, we should be safe just doing this all the time, really.
        return wotdEntry;
    }


    wotdEntry.pronunciation = record.textElements.pronunciation;
    wotdEntry.secondaryHeadword = record.textElements.syllabifiedHeadword;
    wotdEntry.partOfSpeech = record.textElements.partOfSpeech;


    wotdEntry.sense = [self stringByNumberingStringsIfMoreThanOne:record.textElements.senses];
    if(wotdEntry.sense.length == 0) return nil;

    return wotdEntry.count > 0 ? wotdEntry : nil;
}

-(NSString *)description
{
    NSMutableString *s = [NSMutableString new];

    [s appendFormat:@"headword:[%@] (%@)", self.headword, self.referenceID];
    if(self.secondaryHeadword) [s appendFormat:@"\nsecondary:[%@]", self.secondaryHeadword];
    if(self.pronunciation) [s appendFormat:@"\npronunciation:[%@]", self.pronunciation];
    if(self.partOfSpeech) [s appendFormat:@"\npos:[%@]", self.partOfSpeech];
    if(self.sense) [s appendFormat:@"\nsense:[%@]", self.sense];

    return s;
}

@end

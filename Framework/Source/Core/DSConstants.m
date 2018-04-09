// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSConstants.h"
#import "FrameworkInternals.h"


DSIndexName const DSIndexNameKeyword = @"DCSKeywordIndex";
DSIndexName const DSIndexNameBodyData = @"DCSBodyDataIndex";
DSIndexName const DSIndexNameReference = @"DCSReferenceIndex";


DSIndexFieldName const DSIndexFieldNameExternalBodyID = @"DCSExternalBodyID";
DSIndexFieldName const DSIndexFieldNamePrivateFlag = @"DCSPrivateFlag";
DSIndexFieldName const DSIndexFieldNameKeyword = @"DCSKeyword";
DSIndexFieldName const DSIndexFieldNameHeadword = @"DCSHeadword";
DSIndexFieldName const DSIndexFieldNameEntryTitle = @"DCSEntryTitle";
DSIndexFieldName const DSIndexFieldNameAnchor = @"DCSAnchor";
DSIndexFieldName const DSIndexFieldNameYomiWord = @"DCSYomiWord";
DSIndexFieldName const DSIndexFieldNameSortKey = @"DCSSortKey";


const DSIndexFieldPrivateFlagBitmask DSIndexFieldPrivateFlagBitmaskCensored = 0x01;
const DSIndexFieldPrivateFlagBitmask DSIndexFieldPrivateFlagBitmaskPriority = 0x1e;


DSTextElementKey const DSTextElementKeyTitle = @"DSTextElementKeyTitle";  // This one isn't real from the framework's perspective


DSXSLArgumentKey const DSXSLArgumentKeyParentalControl = @"parental-control";
DSXSLArgumentKey const DSXSLArgumentKeyAriaLabel = @"aria-label";
DSXSLArgumentKey const DSXSLArgumentKeyBaseURL = @"base-url";
DSXSLArgumentKey const DSXSLArgumentKeyRTLDirection = @"rtl-direction";
DSXSLArgumentKey const DSXSLArgumentKeyStylesheetContent = @"stylesheet-content";


NSUInteger DSUIntegerForSearchMethod(DSSearchMethod searchMethod)
{
    // The dictionary search methods want integer versions of these flags;
    // the IDX* methods want strings.

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"

    if([searchMethod isEqualToString:DSSearchMethodAllMatch]) return DCSDictionarySearchMethodPrefixMatch;

    #pragma clang diagnostic pop

    if([searchMethod isEqualToString:DSSearchMethodPrefixMatch]) return DCSDictionarySearchMethodPrefixMatch;
    if([searchMethod isEqualToString:DSSearchMethodCommonPrefixMatch]) return DCSDictionarySearchMethodPrefixMatch;
    if([searchMethod isEqualToString:DSSearchMethodWildcardMatch]) return DCSDictionarySearchMethodWildcardMatch;

    return DCSDictionarySearchMethodExactMatch;
}

NSDictionary<NSString *, DSTextElementKey> *DSOldNameToTextElementKeyMap()
{
    // There's a private method CopyConvertedTextElementKey that knows these translations

    static NSDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = @{ @"definitions": DSTextElementKeySenses,
                  @"pos": DSTextElementKeyPartOfSpeech,
                  @"pronunciation": DSTextElementKeyPronunciation,
                  @"syllabified": DSTextElementKeySyllabifiedHeadword };
    });

    return dict;
}

DSTextElementKey DSTextElementKeyForOldName(NSString *oldName)
{
    return DSOldNameToTextElementKeyMap()[oldName] ?: oldName;
}

NSString *DSOldNameForTextElementKey(DSTextElementKey textElementKey)
{
    NSDictionary *oldNamesToNew = DSOldNameToTextElementKeyMap();
    for(NSString *oldName in oldNamesToNew) {
        if([oldNamesToNew[oldName] isEqualToString:textElementKey]) {
            return oldName;
        }
    }

    return nil;
}

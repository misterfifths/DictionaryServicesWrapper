// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <CoreServices/CoreServices.h>


#pragma mark - Types

typedef CFTypeRef DCSRecordRef;
typedef CFTypeRef IDXIndexRef;


NS_ASSUME_NONNULL_BEGIN


#pragma mark - Constants

extern NSString * const kDCSDictionaryDescriptionLanguage;
extern NSString * const kDCSDictionaryIndexLanguage;

extern NSString * const kIDXSearchExactMatch;
extern NSString * const kIDXSearchPrefixMatch;
extern NSString * const kIDXSearchCommonPrefixMatch;
extern NSString * const kIDXSearchWildcardMatch;
extern NSString * const kIDXSearchAllMatch;

extern NSString * const kIDXPropertyIndexList;

extern NSString * const kIDXPropertyIndexName;
extern NSString * const kIDXPropertyIndexPath;
extern NSString * const kIDXPropertyIndexAccessMethod;
extern NSString * const kIDXPropertyIndexKeyMatchingMethods;
extern NSString * const kIDXPropertyIndexDataSizeLength;
extern NSString * const kIDXPropertyIndexWritable;
extern NSString * const kIDXPropertyIndexSupportDataID;
extern NSString * const kIDXPropertyIndexBigEndian;

extern NSString * const kIDXPropertyDataFields;
extern NSString * const kIDXPropertyExternalFields;
extern NSString * const kIDXPropertyFixedFields;
extern NSString * const kIDXPropertyVariableFields;
extern NSString * const kIDXPropertyDataFieldName;
extern NSString * const kIDXPropertyDataSize;
extern NSString * const kIDXPropertyDataSizeLength;

extern NSString * const kDCSTextElementKeyRecordID;
extern NSString * const kDCSTextElementKeyHeadword;
extern NSString * const kDCSTextElementKeySyllabifiedHeadword;
extern NSString * const kDCSTextElementKeyPartOfSpeech;
extern NSString * const kDCSTextElementKeyPronunciation;
extern NSString * const kDCSTextElementKeySenses;



#pragma mark - Enums

typedef NS_ENUM(NSUInteger, DCSSearchMethod) {
    DCSSearchMethodExactMatch,
    DCSSearchMethodPrefixMatch,
    DCSSearchMethodCommonPrefixMatch,
    DCSSearchMethodWildcardMatch
};

typedef NS_ENUM(NSUInteger, DCSDefinitionStyle) {
    DCSDefinitionStyleBareXHTML,
    DCSDefinitionStyleXHTMLForApp,
    DCSDefinitionStyleXHTMLForPanel,
    DCSDefinitionStylePlainText,
    DCSDefinitionStyleRaw
};

typedef NS_OPTIONS(NSUInteger, DCSearchStringNormalizationOptions) {
    DCSearchStringNormalizationOptionNone = 0,
    DCSearchStringNormalizationOptionMaintainCase = 1
};



#pragma mark - Dictionary functions

#pragma mark Discovery & creation

extern NSArray *DCSCopyAvailableDictionaries(void) NS_RETURNS_RETAINED;
extern NSArray *DCSGetActiveDictionaries(void);
extern DCSDictionaryRef DCSGetDefaultDictionary(void);
extern DCSDictionaryRef DCSGetDefaultThesaurus(void);

extern DCSDictionaryRef __nullable DCSDictionaryCreate(NSURL *url);
extern DCSDictionaryRef __nullable DCSDictionaryCreateWithIdentifier(NSString *identifier);



#pragma mark Properties

// Assuming nonnull on these. If they're null, the dictionary is really weird/broken.
extern NSURL *DCSDictionaryGetURL(DCSDictionaryRef dictionary);
extern NSString *DCSDictionaryGetName(DCSDictionaryRef dictionary);
extern NSString *DCSDictionaryGetShortName(DCSDictionaryRef dictionary);
extern NSString *DCSDictionaryGetIdentifier(DCSDictionaryRef dictionary);

extern Boolean DCSDictionaryIsNetworkService(DCSDictionaryRef dictionary);
extern Boolean DCSDictionaryIsSupportedDefinitionStyle(DCSDictionaryRef dictionary, DCSDefinitionStyle format);

extern NSDictionary<NSString *, id> * __nullable DCSDictionaryGetPreferences(DCSDictionaryRef dictionary);
extern NSArray * __nullable DCSDictionaryGetSubDictionaries(DCSDictionaryRef dictionary);

extern NSArray<NSDictionary<NSString *, NSString *> *> * __nullable DCSDictionaryGetLanguages(DCSDictionaryRef dictionary);
extern NSString * __nullable DCSDictionaryGetPrimaryLanguage(DCSDictionaryRef dictionary);


#pragma mark Queries

extern NSArray * __nullable DCSCopyRecordsForSearchString(DCSDictionaryRef dictionary, NSString *string, DCSSearchMethod searchMethod, NSUInteger maxResults) NS_RETURNS_RETAINED;
extern DCSRecordRef __nullable DCSCopyRecordForReference(DCSDictionaryRef dict, NSString *reference);



#pragma mark - Record functions

extern DCSDictionaryRef DCSRecordGetDictionary(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetString(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetHeadword(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetRawHeadword(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetSupplementalHeadword(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetTitle(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetAnchor(DCSRecordRef record);

extern NSString * __nullable DCSRecordCopyDefinition(DCSRecordRef record, DCSDefinitionStyle format) NS_RETURNS_RETAINED;  // It seems that style 4 (raw) will make this return an NSData. But, I have yet to see any dictionaries that support that style.
extern NSDictionary<NSString *, id> * __nullable DCSRecordCopyTextElements(DCSRecordRef record, NSArray<NSString *> * __nullable requestedElementNames) NS_RETURNS_RETAINED;  // nil requestedElementNames means return everything. If none of the keys in requestedElementNames are in the record, returns nil

//extern NSString *DCSRecordCopyData(DCSRecordRef record, DCSDefinitionFormat format) NS_RETURNS_RETAINED;  // synonym for CopyDefinition, except it explicitly returns nil for DCSDefinitionStyleRaw. That seems useless, and like they're named backward...

extern NSURL * __nullable DCSRecordCopyDataURL(DCSRecordRef record) NS_RETURNS_RETAINED;  // Seemingly only meaningful on records from network dictionaries



#pragma mark - Index functions

#pragma mark Discovery & creation

extern NSArray *IDXCopyIndexNames(NSURL *dictionaryURL, Boolean copyURLs) NS_RETURNS_RETAINED;  // returns string ids (like "DCSKeywordIndex") or NSURLs of the index files if copyURLs

extern IDXIndexRef __nullable IDXCreateIndexObject(CFAllocatorRef __nullable allocator, NSURL *dictionaryURL, NSString *indexName);


#pragma mark Queries

extern void IDXSetRequestFields(IDXIndexRef idx, NSArray<NSString *> *fieldNames);
extern Boolean IDXSetSearchString(IDXIndexRef idx, NSString *searchString, NSString *matchMethod);
extern Boolean IDXContainsMatchData(IDXIndexRef idx);  // Unclear how/if this works... returns false a lot

extern Boolean IDXSupportsDataPtr(IDXIndexRef idx);

uint32_t IDXGetMatchData(IDXIndexRef idxRef, uint32_t maxResults, uint32_t bufferLength, void *buffer, CFRange * _Nonnull * _Nonnull outRanges, uint32_t * __nullable outInt);
extern int64_t IDXGetFieldDataPtrs(IDXIndexRef idx, void *fieldData, size_t fieldDataLength, void * _Nonnull * _Nonnull fieldPtrs, size_t *fieldLengths);

typedef void (*IDXPerformSearchCallback)(IDXIndexRef idx, void *fieldData, size_t fieldDataLength, uint32_t alwaysOne, void * __nullable context);
extern void IDXPerformSearch(IDXIndexRef idx, IDXPerformSearchCallback callback, void * __nullable context);  // callback signature seems to vary depending on SupportDataPtr, and maybe more?

extern size_t IDXGetDataByID(IDXIndexRef idx, uint64_t recordID, size_t bufferSize, void * __nullable buffer);  // If you pass 0 for bufferSize and NULL for the buffer, this returns the number of bytes needed to contain the data
extern size_t IDXGetDataPtrByID(IDXIndexRef idx, uint64_t recordID, void * __nullable * __nonnull outBuffer);

#pragma mark Miscellaneous

extern NSData *IDXCreateFlattenData(IDXIndexRef idx, NSDictionary<NSString *, id> *fields) NS_RETURNS_RETAINED;
// extern void *IDXGetMatchDataPtr(IDXIndexRef idx, void *arg2, void *arg3, void *arg4, void *arg5, void *arg6);



#pragma mark - Miscellaneous functions

//extern NSArray *DCSCreateHeadwordList(size_t, NSArray **, NSString *, NSString **);

//extern NSArray *DCSCopyLemmas(DCSDictionaryRef dict, NSString *term) NS_RETURNS_RETAINED;

//NSDictionary *CopyTransformedTextFromXML(NSString *xmlString /*?, literal 3, headword?, allow vertical orientation?? 1*/) NS_RETURNS_RETAINED;
//NSDictionary *CopyXPathElementsArray(NSString *xmlString, NSDictionary *xpathSpecs, NSDictionary *dtdsByXmlNamespace) NS_RETURNS_RETAINED;

// Seems like it breaks the string into words elements, based on entries in some private Apple wordbreak dictionary?
// For instance, turns "a dog" into [ [a], [dog] ], and "three-fold" into [ [three], [fold] ]
// Shrug.
extern NSArray<NSArray<NSString *> *> *DCSCreateAppleWordEquivalenceList(NSString *string) NS_RETURNS_RETAINED;

// Search methods on dictionaries call this for you, but not on indexes!
extern void DCSNormalizeSearchStringWithOptionsAndLocale(NSMutableString *string,
                                                         DCSearchStringNormalizationOptions options,
                                                         NSLocale * __nullable locale);



#pragma mark - Cleanup

#pragma redefine_extname DCSDictionaryGetPreferences _DCSDictionaryGetPreference
#pragma redefine_extname IDXSupportsDataPtr _IDXSupportDataPtr


NS_ASSUME_NONNULL_END


// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <CoreServices/CoreServices.h>


// Exported methods from the DictonaryServices framework, lovingly reverse-engineered.

// These methods actually return CF types (strings, arrays, etc.), but I've just translated all of those
// to NS types, since that just works, and avoids a ton of bridge casts.

// Also these have been audited for NS_RETURNS_RETAINED, though I'm not strictly sure if that was
// necessary... clang docs were unclear on whether that's determined from that method name
// (create/get/copy rule), so I just did it. (CF_RETURNS_RETAINED, on the other hand, is documented to
// do the right thing based on function names, so I've left that off when a function returns
// a CF type.)

// Nullability annotations are a bit of a guess in most cases, but seem sound enough.

// There are a lot of useful strings & constants that aren't exported by the framework. Those are
// collected manually in DSConstants.h/m.


#pragma mark - Types

typedef CFTypeRef DCSRecordRef;
typedef CFTypeRef IDXIndexRef;


NS_ASSUME_NONNULL_BEGIN


#pragma mark - Constants

typedef NSString * const DCSDictionaryLanguageKey NS_TYPED_EXTENSIBLE_ENUM;
extern DCSDictionaryLanguageKey kDCSDictionaryDescriptionLanguage;
extern DCSDictionaryLanguageKey kDCSDictionaryIndexLanguage;

typedef NSString * const IDXSearchMethod NS_TYPED_EXTENSIBLE_ENUM;
extern IDXSearchMethod kIDXSearchExactMatch;
extern IDXSearchMethod kIDXSearchPrefixMatch;
extern IDXSearchMethod kIDXSearchCommonPrefixMatch;
extern IDXSearchMethod kIDXSearchWildcardMatch;
extern IDXSearchMethod kIDXSearchAllMatch;

typedef NSString * const DCSTextElementKey NS_TYPED_EXTENSIBLE_ENUM;
extern DCSTextElementKey kDCSTextElementKeyRecordID;
extern DCSTextElementKey kDCSTextElementKeyHeadword;
extern DCSTextElementKey kDCSTextElementKeySyllabifiedHeadword;
extern DCSTextElementKey kDCSTextElementKeyPartOfSpeech;
extern DCSTextElementKey kDCSTextElementKeyPronunciation;
extern DCSTextElementKey kDCSTextElementKeySenses;

// Key for the list of index info dictionaries in the DCSDictionary's info.plist
extern NSString * const kIDXPropertyIndexList;

// These are keys in an index info dictionary
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

// And these are keys inside the individual field dictionaries
extern NSString * const kIDXPropertyDataFieldName;
extern NSString * const kIDXPropertyDataSize;
extern NSString * const kIDXPropertyDataSizeLength;



#pragma mark - Enums

typedef NS_ENUM(NSUInteger, DCSDictionarySearchMethod) {
    DCSDictionarySearchMethodExactMatch,
    DCSDictionarySearchMethodPrefixMatch,
    DCSDictionarySearchMethodCommonPrefixMatch,
    DCSDictionarySearchMethodWildcardMatch
};

typedef NS_ENUM(NSUInteger, DCSDefinitionStyle) {
    DCSDefinitionStyleBareXHTML,
    DCSDefinitionStyleXHTMLForApp,
    DCSDefinitionStyleXHTMLForPanel,
    DCSDefinitionStylePlainText,
    DCSDefinitionStyleRaw
};

typedef NS_OPTIONS(NSUInteger, DCSearchStringNormalizationOptions) {
    DCSearchStringNormalizationOptionNone,
    DCSearchStringNormalizationOptionMaintainCase
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
extern NSString *DCSDictionaryGetName(DCSDictionaryRef dictionary);
extern NSString *DCSDictionaryGetShortName(DCSDictionaryRef dictionary);
extern NSString *DCSDictionaryGetIdentifier(DCSDictionaryRef dictionary);

// This is null if the dictionary's not actually downloaded (e.g., instances gotten through CopyAvailableDictionaries)
extern NSURL * __nullable DCSDictionaryGetURL(DCSDictionaryRef dictionary);

extern Boolean DCSDictionaryIsNetworkService(DCSDictionaryRef dictionary);
extern Boolean DCSDictionaryIsSupportedDefinitionStyle(DCSDictionaryRef dictionary, DCSDefinitionStyle format);

extern NSDictionary<NSString *, id> * __nullable DCSDictionaryGetPreferences(DCSDictionaryRef dictionary);
extern NSArray * __nullable DCSDictionaryGetSubDictionaries(DCSDictionaryRef dictionary);

extern NSArray<NSDictionary<DCSDictionaryLanguageKey, NSString *> *> * __nullable DCSDictionaryGetLanguages(DCSDictionaryRef dictionary);
extern NSString * __nullable DCSDictionaryGetPrimaryLanguage(DCSDictionaryRef dictionary);


#pragma mark Queries

extern NSArray * __nullable DCSCopyRecordsForSearchString(DCSDictionaryRef dictionary, NSString *string, DCSDictionarySearchMethod searchMethod, NSUInteger maxResults) NS_RETURNS_RETAINED;
extern DCSRecordRef __nullable DCSCopyRecordForReference(DCSDictionaryRef dict, NSString *referenceID);



#pragma mark - Record functions

extern DCSDictionaryRef DCSRecordGetDictionary(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetString(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetHeadword(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetRawHeadword(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetSupplementalHeadword(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetTitle(DCSRecordRef record);
extern NSString * __nullable DCSRecordGetAnchor(DCSRecordRef record);

extern NSString * __nullable DCSRecordCopyDefinition(DCSRecordRef record, DCSDefinitionStyle format) NS_RETURNS_RETAINED;  // It seems that style 4 (raw) will make this return an NSData. But, I have yet to see any dictionaries that support that style.
extern NSDictionary<DCSTextElementKey, id> * __nullable DCSRecordCopyTextElements(DCSRecordRef record, NSArray<DCSTextElementKey> * __nullable requestedElementNames) NS_RETURNS_RETAINED;  // nil requestedElementNames means return everything. If none of the keys in requestedElementNames are in the record, returns nil

//extern NSString *DCSRecordCopyData(DCSRecordRef record, DCSDefinitionFormat format) NS_RETURNS_RETAINED;  // synonym for CopyDefinition, except it explicitly returns nil for DCSDefinitionStyleRaw. That seems useless, and like they're named backward...

extern NSURL * __nullable DCSRecordCopyDataURL(DCSRecordRef record) NS_RETURNS_RETAINED;  // Seemingly only meaningful on records from network dictionaries



#pragma mark - Index functions

#pragma mark Discovery & creation

extern NSArray *IDXCopyIndexNames(NSURL *dictionaryURL, Boolean copyURLs) NS_RETURNS_RETAINED;  // returns string ids (like "DCSKeywordIndex") or NSURLs of the index files if copyURLs

extern IDXIndexRef __nullable IDXCreateIndexObject(CFAllocatorRef __nullable allocator, NSURL *dictionaryURL, NSString *indexName);


#pragma mark Queries

extern void IDXSetRequestFields(IDXIndexRef idx, NSArray<NSString *> *fieldNames);
extern Boolean IDXSetSearchString(IDXIndexRef idx, NSString *searchString, IDXSearchMethod matchMethod);
extern Boolean IDXContainsMatchData(IDXIndexRef idx);  // Unclear how/if this works... returns false a lot

extern Boolean IDXSupportsDataPtr(IDXIndexRef idx);

uint32_t IDXGetMatchData(IDXIndexRef idxRef, uint32_t maxResults, uint32_t bufferLength, void *buffer, CFRange * __nonnull * __nonnull outRanges, uint32_t * __nullable outInt);
extern int64_t IDXGetFieldDataPtrs(IDXIndexRef idx, void *fieldData, size_t fieldDataLength, void * __nonnull * __nonnull fieldPtrs, size_t *fieldLengths);

typedef void (*IDXPerformSearchCallback)(IDXIndexRef idx, void *fieldData, size_t fieldDataLength, uint32_t alwaysOne, void * __nullable context);
extern void IDXPerformSearch(IDXIndexRef idx, IDXPerformSearchCallback callback, void * __nullable context);  // callback signature seems like it might vary depending on SupportDataPtr? Haven't tested.

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

// I'm crazy. Renamining some methods that had weird names.
#pragma redefine_extname DCSDictionaryGetPreferences _DCSDictionaryGetPreference
#pragma redefine_extname IDXSupportsDataPtr _IDXSupportDataPtr


NS_ASSUME_NONNULL_END


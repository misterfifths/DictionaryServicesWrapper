// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"
#import "DSConstants.h"
#import "DSIndex.h"
#import "DSRecord.h"
#import "DSContentLanguagePair.h"

@class DSXSLArguments;


NS_ASSUME_NONNULL_BEGIN


// Presently unsupported things: subdictionaries, front matter, almost certainly the Wikipedia dictionary,
// probably bits and pieces of non-NOAD dictionaries.
// Big-endian indexes are probably busted. Haven't tested at all.
// Seems like certain dictionaries have RTF content, not XML? That'll definitely break.


@interface DSDictionary : NSObject

@property (nonatomic, readonly, class) NSArray<DSDictionary *> *availableDictionaries;
@property (nonatomic, readonly, class) NSArray<DSDictionary *> *activeDictionaries;

@property (nonatomic, readonly, class, nullable) DSDictionary *defaultDictionary NS_SWIFT_NAME(defaultDictionary);
@property (nonatomic, readonly, class, nullable) DSDictionary *defaultThesaurus;


@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *shortName;  // never nil, but intermittently empty
@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readonly, strong, nullable) NSURL *URL;  // nil if this dictionary isn't downloaded (i.e., an instance gotten through +availableDictionaries)
@property (nonatomic, readonly) BOOL isNetworkDictionary;

@property (nonatomic, readonly, copy) NSArray<DSContentLanguagePair *> *contentLanguages;

@property (nonatomic, readonly, copy, nullable) NSString *primaryLanguage;
@property (nonatomic, readonly, copy, nullable) NSLocale *primaryLocale;


+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

-(nullable instancetype)initWithIdentifier:(NSString *)identifier;
-(nullable instancetype)initWithURL:(NSURL *)URL;

-(BOOL)supportsDefinitionStyle:(DSDefinitionStyle)style DS_WARN_UNUSED_RESULT;

-(nullable DSRecord *)firstRecordMatchingString:(NSString *)string method:(DSSearchMethod)searchMethod DS_WARN_UNUSED_RESULT;
-(NSArray<DSRecord *> *)recordsMatchingString:(NSString *)string method:(DSSearchMethod)searchMethod DS_WARN_UNUSED_RESULT;
-(NSArray<DSRecord *> *)recordsMatchingString:(NSString *)string method:(DSSearchMethod)searchMethod maxResults:(NSUInteger)maxResults DS_WARN_UNUSED_RESULT;


#pragma mark - Indexes

@property (nonatomic, readonly, copy) NSArray<DSIndexName> *indexNames;
-(nullable DSIndexInfo *)infoForIndexNamed:(NSString *)indexName DS_WARN_UNUSED_RESULT;
-(nullable DSIndex *)indexWithName:(DSIndexName)indexName DS_WARN_UNUSED_RESULT;

@property (nonatomic, readonly, strong, nullable) DSIndex *keywordIndex;
@property (nonatomic, readonly, strong, nullable) DSIndex *bodyDataIndex;
@property (nonatomic, readonly, strong, nullable) DSIndex *referenceIndex;

// The recordsMatchingString methods do this automatically; only needed if manually searching against
// an index. Normalizes the string using -primaryLocale.
-(NSString *)stringByNormalizingSearchTerm:(NSString *)searchTerm DS_WARN_UNUSED_RESULT;


#pragma mark - Record synthesis

@property (nonatomic, readonly, copy) NSDictionary<DSTextElementKey, NSString *> *textElementXPaths;
-(void)setOverrideXPath:(NSString *)xpath forTextElement:(DSTextElementKey)key;

@property (nonatomic, readonly, copy) NSArray<NSURL *> *styleSheetURLs;
@property (nonatomic, readonly, copy) NSString *styleSheetContent;

@property (nonatomic, readonly, strong, nullable) NSURL *xslURL;
@property (nonatomic, readonly, strong, nullable) NSXMLDocument *xslDocument;

@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *defaultPreferences;
@property (nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *preferences;

@property (nonatomic, readonly, copy) DSXSLArguments *defaultXSLArguments;

// Looks up the given string in the referenceIndex (to translate it to a body data ID),
// then looks up its body in the bodyDataIndex, and recovers a record out of that.
-(nullable DSRecord *)recordForReference:(NSString *)referenceString DS_WARN_UNUSED_RESULT;

// These assumes they're being given an entry from the keyword index (or at least one that has an external body ID).
-(DSRecord *)recordFromEntry:(DSIndexEntry *)entry DS_WARN_UNUSED_RESULT;  // Looks up body data in bodyDataIndex
-(DSRecord *)recordFromEntry:(DSIndexEntry *)entry bodyData:(NSString *)bodyData DS_WARN_UNUSED_RESULT;

@end


NS_ASSUME_NONNULL_END

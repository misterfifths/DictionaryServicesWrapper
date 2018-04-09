// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"
#import "DSConstants.h"
#import "DSIndexInfo.h"
#import "DSIndexField.h"
#import "DSIndexEntry.h"

@class DSDictionary;
@class DSRecord;


NS_ASSUME_NONNULL_BEGIN


@interface DSIndex : NSObject

@property (nonatomic, readonly, strong) DSIndexInfo *info;
@property (nonatomic, readonly, copy) DSIndexName name;
@property (nonatomic, readonly, weak) DSDictionary *dictionary;
@property (nonatomic, readonly, copy) NSArray<DSIndexField *> *fields;
@property (nonatomic, readonly) BOOL supportsFindByID;

@property (nonatomic, readonly, copy) NSArray<DSSearchMethod> *supportedSearchMethods;
-(BOOL)supportsSearchMethod:(DSSearchMethod)searchMethod DS_WARN_UNUSED_RESULT;


+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

// You probably want -[DSDictionary indexWithName:], not this initialiazer
-(instancetype)initWithName:(DSIndexName)indexName
                 dictionary:(DSDictionary *)dictionary;


// TODO: these are wildly thread unsafe.

// These three run the search string through the dictionary's normalization
-(nullable DSIndexEntry *)firstMatchForString:(NSString *)string
                                       method:(DSSearchMethod)searchMethod DS_WARN_UNUSED_RESULT;

-(NSArray<DSIndexEntry *> *)matchesForString:(NSString *)string
                                      method:(DSSearchMethod)searchMethod
                                  maxResults:(NSUInteger)maxResults DS_WARN_UNUSED_RESULT;

-(void)enumerateMatchesForString:(NSString *)string
                          method:(DSSearchMethod)searchMethod
                      usingBlock:(void (^ NS_NOESCAPE)(DSIndexEntry *entry, BOOL *stop))block;

// This one does no normalization
-(void)enumerateMatchesForNormalizedString:(NSString *)string
                                    method:(DSSearchMethod)searchMethod
                                usingBlock:(void (^ NS_NOESCAPE)(DSIndexEntry *entry, BOOL *stop))block;


// Making the somewhat reasonable assumption this is a string.
// Only usable if supportsFindByID is YES.
-(nullable NSString *)dataForRecordID:(DSBodyDataID)recordID DS_WARN_UNUSED_RESULT;


// TODO: definitely an argument to be made for subclasses of this:
// - one that only supports queries (e.g. keyword, reference)
// - one that only supports find-by-ID (e.g. body data)
// or even further - specialized subclasses that return specialized DSIndexEntry subclasses?

@end


NS_ASSUME_NONNULL_END

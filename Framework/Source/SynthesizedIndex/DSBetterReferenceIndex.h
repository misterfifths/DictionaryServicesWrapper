// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDictionary.h"
#import "DSSynthesizedIndex.h"
#import "DSDefines.h"

@class DSBetterReferenceIndexEntry;

typedef NSDictionary<NSString *, DSBetterReferenceIndexEntry *> DSBetterReferenceIndexMap;
typedef NSDictionary<NSString *, NSDictionary *> DSBetterReferenceIndexPlist;


NS_ASSUME_NONNULL_BEGIN


// Map of all reference IDs ("m_en_gbus*" strings) *and* body data IDs
// to each other, as well as the body XML's title, so you don't have to fetch
// and parse it just to know what you're looking at.
// In true slapdash fashion, all of this stuff asserts if something's missing.
@interface DSBetterReferenceIndex : DSSynthesizedIndex<DSBetterReferenceIndexMap *, DSBetterReferenceIndexPlist *>

-(DSBetterReferenceIndexEntry *)entryForReferenceID:(NSString *)referenceID DS_WARN_UNUSED_RESULT;
-(DSBodyDataID)bodyDataIDForReferenceID:(NSString *)referenceID DS_WARN_UNUSED_RESULT;
-(NSString *)titleForReferenceID:(NSString *)referenceID DS_WARN_UNUSED_RESULT;

-(DSBetterReferenceIndexEntry *)entryForBodyDataID:(DSBodyDataID)bodyDataID DS_WARN_UNUSED_RESULT;
-(NSString *)referenceIDForBodyDataID:(DSBodyDataID)bodyDataID DS_WARN_UNUSED_RESULT;
-(NSString *)titleForBodyDataID:(DSBodyDataID)bodyDataID DS_WARN_UNUSED_RESULT;

-(DSBetterReferenceIndexEntry *)objectForKeyedSubscript:(id)referenceIDOrBodyIDStringOrBodyIDNumber;

@end


NS_SWIFT_NAME(DSBetterReferenceIndex.Entry)
@interface DSBetterReferenceIndexEntry : DSMutableDictionaryWrapper<NSString *, id>

@property (nonatomic) DSBodyDataID bodyDataID;
@property (nonatomic, copy) NSString *referenceID;
@property (nonatomic, copy) NSString *title;

@end


@interface DSDictionary (DSBetterReferenceIndex)

@property (nonatomic, readonly) BOOL betterReferenceIndexIsLoaded;
@property (nonatomic, readonly) DSBetterReferenceIndex *betterReferenceIndex;
-(void)evictBetterReferenceIndex;

@end

NS_ASSUME_NONNULL_END

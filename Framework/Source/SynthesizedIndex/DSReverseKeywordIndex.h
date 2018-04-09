// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSSynthesizedIndex.h"
#import "DSDictionary.h"
#import "DSDefines.h"

@class DSIndexEntry;

typedef NSDictionary<NSString *, NSArray<DSIndexEntry *> *> DSReverseKeywordIndexMap;
typedef NSDictionary<NSString *, NSArray<NSDictionary *> *> DSReverseKeywordIndexPlist;


NS_ASSUME_NONNULL_BEGIN


// Map of body IDs to all the keyword index entries that point to that body.
// In true slapdash fashion, all of this stuff asserts if something's missing.
@interface DSReverseKeywordIndex : DSSynthesizedIndex<DSReverseKeywordIndexMap *, DSReverseKeywordIndexPlist *>

-(NSArray<DSIndexEntry *> *)keywordIndexEntriesForBodyDataID:(DSBodyDataID)bodyDataID DS_WARN_UNUSED_RESULT;
-(NSArray<DSIndexEntry *> *)objectForKeyedSubscript:(NSNumber *)bodyDataIDNumber DS_WARN_UNUSED_RESULT;

-(void)enumerateBodiesUsingBlock:(void (^ NS_NOESCAPE)(DSBodyDataID bodyDataID, NSArray<DSIndexEntry *> *keywordIndexEntries, BOOL *stop))block;

@end


@interface DSDictionary (DSReverseKeywordIndex)

@property (nonatomic, readonly) BOOL reverseKeywordIndexIsLoaded;
@property (nonatomic, readonly) DSReverseKeywordIndex *reverseKeywordIndex;
-(void)evictReverseKeywordIndex;

@end


NS_ASSUME_NONNULL_END

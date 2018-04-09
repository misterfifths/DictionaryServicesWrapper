// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"

@class DSDictionary;
@class DSRecordSubEntry;


NS_ASSUME_NONNULL_BEGIN


// Attempts to parse & follow the XPointers in DSRecord anchors.
// Pretty naive. Only understands "xpointer(//*[@id='reference_id.subentry_id'])".
// Hashable & isEqual friendly.
@interface DSXPointer : NSObject

@property (nonatomic, readonly, copy) NSString *targetReferenceID;
@property (nonatomic, readonly, copy) NSString *targetSubEntryID;

@property (nonatomic, readonly, copy) NSString *targetDescription;


-(instancetype)initWithXPointerString:(NSString *)xpointer;


-(NSXMLNode *)followInDictionary:(DSDictionary *)dictionary DS_WARN_UNUSED_RESULT;

// This will load dictionary.betterReferenceIndex, which can take a really long time
// and a ton of memory, especially if it has to make it from scratch.
// Beware. Check DSDictionary.betterReferenceIndexIsLoaded beforehand if you care.
-(NSArray<DSRecordSubEntry *> *)followToSubEntriesInDictionary:(DSDictionary *)dictionary DS_WARN_UNUSED_RESULT;


-(instancetype)init NS_UNAVAILABLE;
+(instancetype)new NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END

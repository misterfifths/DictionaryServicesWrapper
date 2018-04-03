// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "FrameworkInternals.h"
#import "DSDictionary.h"
#import "DSIndex.h"
#import "DSRecord.h"


NS_ASSUME_NONNULL_BEGIN


@interface DSDictionary (FrameworkBridging)

@property (nonatomic, readonly) DCSDictionaryRef dictRef;

-(instancetype)initWithDictRef:(DCSDictionaryRef)dictRef;

@end


@interface DSRecord (FrameworkBridging)

// Returns null on synthetic records
@property (nonatomic, readonly, nullable) DCSRecordRef recordRef;

-(instancetype)initWithRecordRef:(DCSRecordRef)recordRef
                      dictionary:(DSDictionary *)dictionary;

@end


@interface DSIndex (FrameworkBridging)

@property (nonatomic, readonly) IDXIndexRef indexRef;

-(instancetype)initWithIndexRef:(IDXIndexRef)indexRef
                           name:(DSIndexName)indexName
                     dictionary:(DSDictionary *)dictionary;

@end


NS_ASSUME_NONNULL_END

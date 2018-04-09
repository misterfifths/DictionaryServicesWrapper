// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSRecord.h"
#import "FrameworkInternals.h"

#import "DSSyntheticRecord.h"

@class DSIndex;
@class DSIndexEntry;


NS_ASSUME_NONNULL_BEGIN


@interface DSRecord (InternalInitializers)

-(instancetype)initWithDictionary:(DSDictionary *)dictionary;

// This is a little janky, but this lives on the base class so we can expose it in
// FrameworkBridging.h without exposing DSConcreteRecord.
-(instancetype)initWithRecordRef:(DCSRecordRef)recordRef
                      dictionary:(DSDictionary *)dictionary;

@end


@interface DSConcreteRecord : DSRecord

-(instancetype)initWithDictionary:(DSDictionary *)dictionary NS_UNAVAILABLE;

@end


@interface DSSyntheticRecord (InternalInitializers)

-(instancetype)initWithDictionary:(DSDictionary *)dictionary NS_UNAVAILABLE;
-(instancetype)initWithRecordRef:(DCSRecordRef)recordRef dictionary:(DSDictionary *)dictionary NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END

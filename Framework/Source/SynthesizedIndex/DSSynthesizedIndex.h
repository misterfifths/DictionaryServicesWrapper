// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>

@class DSDictionary;


NS_ASSUME_NONNULL_BEGIN


@interface DSSynthesizedIndex<MapType : NSDictionary *, PlistType : NSDictionary *> : NSObject

+(void)deleteDefaultCacheFileForDictionary:(DSDictionary *)dictionary;


+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END

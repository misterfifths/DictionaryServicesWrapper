// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSSynthesizedIndex.h"
#import "DSDefines.h"


NS_ASSUME_NONNULL_BEGIN


@interface DSSynthesizedIndex<MapType, PlistType> (Internal)

// Subclass responsibilities

+(MapType)createMapForDictionary:(DSDictionary *)dictionary DS_WARN_UNUSED_RESULT;

+(MapType)mapFromPlist:(PlistType)plist DS_WARN_UNUSED_RESULT;
+(PlistType)plistFromMap:(MapType)map DS_WARN_UNUSED_RESULT;


// These could potentially be public, but funnelling people through the
// DSDictionary accessors seems like a better choice.

+(instancetype)indexForDictionary:(DSDictionary *)dictionary
                  useDefaultCache:(BOOL)defaultCache DS_WARN_UNUSED_RESULT;

+(instancetype)indexForDictionary:(DSDictionary *)dictionary
                         cacheURL:(nullable NSURL *)cacheURL DS_WARN_UNUSED_RESULT;


// Internal stuff

// ~/Library/Caches/<app bundle id if any>/<dictionary id>.<index class name>.plist
+(NSURL *)defaultCacheURLForDictionary:(DSDictionary *)dictionary DS_WARN_UNUSED_RESULT;

// Makes the parent directories for the default cache file, and asserts if that fails
+(void)ensureDirectoryForDefaultCacheForDictionary:(DSDictionary *)dictionary;

+(nullable MapType)loadMapFromCache:(NSURL *)cacheURL DS_WARN_UNUSED_RESULT;
+(void)writeMap:(MapType)map toURL:(NSURL *)fileURL;


@property (nonatomic, strong) MapType rawMap;

-(instancetype)initWithMap:(MapType)map;

@end


NS_ASSUME_NONNULL_END

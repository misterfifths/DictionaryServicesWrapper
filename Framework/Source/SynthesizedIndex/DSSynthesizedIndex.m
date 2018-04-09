// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSSynthesizedIndexPrivate.h"
#import "DSMiscUtils.h"
#import "DSDictionary.h"


@interface DSSynthesizedIndex ()

// This is in DSSynthesizedIndexPrivate.h; just repeating it here to get autosynthesis
@property (nonatomic, strong) NSDictionary *rawMap;

@end


@implementation DSSynthesizedIndex

+(NSDictionary *)createMapForDictionary:(DSDictionary *)dictionary
{
    [NSException raise:NSInternalInconsistencyException format:@"Must be implemented by subclasses"];
    return nil;
}

+(NSDictionary *)mapFromPlist:(NSDictionary *)plist
{
    [NSException raise:NSInternalInconsistencyException format:@"Must be implemented by subclasses"];
    return nil;
}

+(NSDictionary *)plistFromMap:(NSDictionary *)map
{
    [NSException raise:NSInternalInconsistencyException format:@"Must be implemented by subclasses"];
    return nil;
}

+(NSURL *)defaultCacheURLForDictionary:(DSDictionary *)dictionary
{
    NSURL *cacheDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;

    NSString *appBundleID = NSBundle.mainBundle.bundleIdentifier;
    if(appBundleID) {
        // command-line apps don't have bundles :-(
        cacheDirectory = [cacheDirectory URLByAppendingPathComponent:appBundleID isDirectory:YES];
    }

    NSString *filename = [NSString stringWithFormat:@"%@.%@.plist", dictionary.identifier, self.class];
    return (NSURL * __nonnull)[cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}

+(void)ensureDirectoryForDefaultCacheForDictionary:(DSDictionary *)dictionary
{
    NSURL *cacheURL = [self defaultCacheURLForDictionary:dictionary];
    NSURL *cacheDir = [cacheURL URLByDeletingLastPathComponent];

    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtURL:cacheDir
                                            withIntermediateDirectories:YES
                                                             attributes:nil
                                                                  error:&error];

    // Docs say YES means "we made it, or, if withIntermediateDirectories == YES, it already existed"
    NSAssert(success, @"Error making a cache directory at %@: %@", cacheDir.path, error);
}

+(void)deleteDefaultCacheFileForDictionary:(DSDictionary *)dictionary
{
    NSURL *cacheURL = [self defaultCacheURLForDictionary:dictionary];
    [[NSFileManager defaultManager] removeItemAtURL:cacheURL error:NULL];
}

+(NSDictionary *)loadMapFromCache:(NSURL *)cacheURL
{
    // TODO: there is absolutely no versioning here, or checking whether the dictionary changed
    // since we generated this cache, or validation that this cache isn't garbage.

    id plist = DSReadPlistObjectFromFile(cacheURL, NO);
    if(!plist) return nil;
    return [self mapFromPlist:plist];
}

+(void)writeMap:(NSDictionary *)map toURL:(NSURL *)fileURL
{
    id plist = [self plistFromMap:map];
    DSWritePlistObjectToFile(plist, fileURL);
}

+(instancetype)indexForDictionary:(DSDictionary *)dictionary useDefaultCache:(BOOL)defaultCache
{
    NSURL *cacheURL = nil;
    if(defaultCache) {
        cacheURL = [self defaultCacheURLForDictionary:dictionary];
        [self ensureDirectoryForDefaultCacheForDictionary:dictionary];
    }

    return [self indexForDictionary:dictionary cacheURL:cacheURL];
}

+(instancetype)indexForDictionary:(DSDictionary *)dictionary cacheURL:(NSURL *)cacheURL
{
    NSDictionary *map = nil;

    if(cacheURL) {
        map = [self loadMapFromCache:cacheURL];
    }

    if(map) {
        NSLog(@"Loaded %@ map for %@ from cache at %@: %lu entries", self.class, dictionary.identifier, cacheURL.path, map.count);
    }
    else {
        NSLog(@"Couldn't load cached %@ map for %@. Making a new one.", self.class, dictionary.identifier);

        map = [self createMapForDictionary:dictionary];
        NSLog(@"Created %@ map for %@: %lu entries", self.class, dictionary.identifier, map.count);
        if(cacheURL) {
            NSLog(@"Writing %@ map for %@ to cache at %@", self.class, dictionary.identifier, cacheURL.path);
            [self writeMap:map toURL:cacheURL];
        }
    }

    return [[self alloc] initWithMap:map];
}

-(instancetype)initWithMap:(id)map
{
    NSAssert(self.class != [DSSynthesizedIndex class], @"Make instances of subclasses, not DSSynthesizedIndex");

    self = [super init];
    if(self) {
        _rawMap = map;
    }

    return self;
}

@end

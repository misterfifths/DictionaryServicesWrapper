// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSMutableDictionaryWrapper.h"

@implementation DSMutableDictionaryWrapper

+(id)sharedKeySet
{
    return nil;
}

+(NSMutableDictionary *)newMutableDictionary
{
    id sharedKeySet = self.sharedKeySet;

    if(sharedKeySet)
        return [NSMutableDictionary dictionaryWithSharedKeySet:sharedKeySet];

    return [NSMutableDictionary new];
}

-(instancetype)init
{
    self = [self initWithDictionaryNoCopy:[[self class] newMutableDictionary]];
    return self;
}

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *d;

    // Going out of our way to do this so we definitely get a shared key set dictionary, if we have a key set.
    if([[self class] sharedKeySet]) {
        d = [[self class] newMutableDictionary];
        [d addEntriesFromDictionary:dictionary];
    }
    else {
        d = [dictionary mutableCopy];
    }

    self = [self initWithDictionaryNoCopy:d];
    return self;
}

-(instancetype)initWithDictionaryNoCopy:(NSDictionary *)dictionary
{
    NSAssert([dictionary isKindOfClass:[NSMutableDictionary class]], @"DSMutableDictionaryWrapper must wrap a mutable dictionary");

    self = [super initWithDictionaryNoCopy:dictionary];
    return self;
}

-(void)removeObjectForKey:(id<NSCopying>)aKey
{
    [((NSMutableDictionary *)_rawDictionary) removeObjectForKey:aKey];
}

-(void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    [((NSMutableDictionary *)_rawDictionary) setObject:anObject forKey:aKey];
}

-(void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    [((NSMutableDictionary *)_rawDictionary) setObject:obj forKeyedSubscript:key];
}

-(void)setDictionary:(NSDictionary *)otherDictionary
{
    [((NSMutableDictionary *)_rawDictionary) setDictionary:otherDictionary];
}

-(void)addEntriesFromDictionary:(NSDictionary *)otherDictionary
{
    [((NSMutableDictionary *)_rawDictionary) addEntriesFromDictionary:otherDictionary];
}

@end

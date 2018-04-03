// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSDictionaryWrapper.h"

@implementation DSDictionaryWrapper

@synthesize rawDictionary=_rawDictionary;

-(instancetype)init
{
    self = [self initWithDictionaryNoCopy:@{ }];
    return self;
}

-(instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self initWithDictionaryNoCopy:[dictionary copy]];
    return self;
}

-(instancetype)initWithDictionaryNoCopy:(NSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        _rawDictionary = dictionary;
    }

    return self;
}

-(id)objectForKey:(id<NSCopying>)key
{
    return _rawDictionary[key];
}

-(id)objectForKeyedSubscript:(id<NSCopying>)key
{
    return _rawDictionary[key];
}

-(NSUInteger)count
{
    return _rawDictionary.count;
}

-(NSArray *)allKeys
{
    return _rawDictionary.allKeys;
}

-(NSArray *)allValues
{
    return _rawDictionary.allValues;
}

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id _Nullable [])buffer count:(NSUInteger)len
{
    return [_rawDictionary countByEnumeratingWithState:state objects:buffer count:len];
}

@end


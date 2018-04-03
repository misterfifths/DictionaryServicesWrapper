// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSDictionaryWrapper.h"


NS_ASSUME_NONNULL_BEGIN


@interface DSMutableDictionaryWrapper<__covariant KeyType : id<NSCopying>, __covariant ObjectType> : DSDictionaryWrapper<KeyType, ObjectType>

// A key set from +[NSDictionary sharedKeySetForKeys]
// If not nil, all dictionaries made by this class will use it (i.e., calls to -init and -initWithDictionary:).
@property (nonatomic, strong, readonly, nullable, class) id sharedKeySet;


// Passthroughs to rawDictionary
-(void)removeObjectForKey:(KeyType)aKey;
-(void)setObject:(ObjectType)anObject forKey:(KeyType)aKey;
-(void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType)key;
-(void)setDictionary:(NSDictionary<KeyType, ObjectType> *)otherDictionary;
-(void)addEntriesFromDictionary:(NSDictionary<KeyType, ObjectType> *)otherDictionary;

@end


NS_ASSUME_NONNULL_END

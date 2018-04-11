// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"

@interface DSDictionaryWrapper<__covariant KeyType : id<NSCopying>, __covariant ObjectType> : NSObject<NSFastEnumeration>
{
    @protected
    NSDictionary<KeyType, ObjectType> *_rawDictionary;
}

@property (nonatomic, readonly, copy) NSDictionary<KeyType, ObjectType> *rawDictionary;


// Passthroughs to rawDictionary
-(nullable ObjectType)objectForKey:(KeyType)key __attribute__((warn_unused_result));

-(nullable ObjectType)objectForKeyedSubscript:(KeyType)key;

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id _Nullable __unsafe_unretained [_Nonnull])buffer count:(NSUInteger)len;

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly, copy) NSArray<KeyType> *allKeys;
@property (nonatomic, readonly, copy) NSArray<ObjectType> *allValues;


-(instancetype)initWithDictionary:(NSDictionary<KeyType, ObjectType> *)dictionary;
-(instancetype)initWithDictionaryNoCopy:(NSDictionary<KeyType, ObjectType> *)dictionary NS_DESIGNATED_INITIALIZER;

@end


#pragma clang diagnostic pop


NS_ASSUME_NONNULL_END

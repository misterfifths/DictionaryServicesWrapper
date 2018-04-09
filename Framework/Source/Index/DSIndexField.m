// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSIndexField.h"
#import "FrameworkInternals.h"


@interface DSIndexField ()

@property (nonatomic, readwrite, copy) NSString *name;

@end


@implementation DSIndexField

-(instancetype)initWithInfoDictionary:(NSDictionary<DSIndexFieldInfoKey, id> *)dictionary
{
    NSAssert(self.class != [DSIndexField class], @"Make instances of subclasses, not DSIndexField");

    self = [super init];
    if(self) {
        _name = [dictionary[DSIndexFieldInfoKeyName] copy];
        NSAssert(_name != nil, @"Index dictionary is missing %@ field", DSIndexFieldInfoKeyName);
    }

    return self;
}

-(id)decodeValueFromBytes:(void *)bytes length:(size_t)length
{
    [NSException raise:NSInternalInconsistencyException format:@"Must be implemented by subclasses"];
    return nil;
}

@end



@interface DSFixedLengthIndexField ()

@property (nonatomic, readwrite) NSUInteger dataSize;

@end


@implementation DSFixedLengthIndexField

-(instancetype)initWithInfoDictionary:(NSDictionary<DSIndexFieldInfoKey, id> *)dictionary
{
    self = [super initWithInfoDictionary:dictionary];
    if(self) {
        NSNumber *dataSizeNumber = dictionary[DSIndexFieldInfoKeyDataSize];
        NSAssert(dataSizeNumber != nil, @"Index dictionary for %@ is missing %@ field", self.name, DSIndexFieldInfoKeyDataSize);

        _dataSize = dataSizeNumber.unsignedIntegerValue;
    }

    return self;
}

-(id)decodeValueFromBytes:(void *)bytes length:(size_t)length
{
    NSAssert(self.dataSize == length, @"Unexpected data size for field %@: expected %lu, got %zu", self.name, self.dataSize, length);

    if(length <= sizeof(uint64_t)) {
        // Cram it in an NSNumber
        uint64_t t = 0;
        memcpy(&t, bytes, length);
        return @(t);
    }

    return [NSData dataWithBytes:bytes length:length];
}

@end



@interface DSExternalDataIndexField ()

@property (nonatomic, readwrite, copy) NSString *externalIndexName;

@end


@implementation DSExternalDataIndexField

-(instancetype)initWithInfoDictionary:(NSDictionary<DSIndexFieldInfoKey, id> *)dictionary
{
    self = [super initWithInfoDictionary:dictionary];
    if(self) {
        _externalIndexName = [dictionary[DSIndexFieldInfoKeyExternalIndexName] copy];
        NSAssert(_externalIndexName != nil, @"Index dictionary for %@ is missing %@ field", self.name, DSIndexFieldInfoKeyExternalIndexName);
    }

    return self;
}

@end



@interface DSVariableLengthIndexField ()

@property (nonatomic, readwrite) NSUInteger dataSizeLength;

@end


@implementation DSVariableLengthIndexField

-(instancetype)initWithInfoDictionary:(NSDictionary<DSIndexFieldInfoKey, id> *)dictionary
{
    self = [super initWithInfoDictionary:dictionary];
    if(self) {
        NSNumber *dataSizeLengthNumber = dictionary[DSIndexFieldInfoKeyDataSizeLength];
        NSAssert(dataSizeLengthNumber != nil, @"Index dictionary for %@ is missing %@ field", self.name, DSIndexFieldInfoKeyDataSizeLength);

        _dataSizeLength = dataSizeLengthNumber.unsignedIntegerValue;
    }

    return self;
}

-(id)decodeValueFromBytes:(void *)bytes length:(size_t)length
{
    // Just assuming string for this for now.

    if(length == 0) return @"";

    return [NSString stringWithCharacters:bytes length:length / sizeof(unichar)];
}

@end

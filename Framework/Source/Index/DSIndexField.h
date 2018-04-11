// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"
#import "DSConstants.h"


NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(DSIndex.Field)
@interface DSIndexField : NSObject

@property (nonatomic, readonly, copy) NSString *name;


+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

-(nullable instancetype)initWithInfoDictionary:(NSDictionary<DSIndexFieldInfoKey, id> *)indexInfoDictionary;

-(nullable id)decodeValueFromBytes:(void *)bytes length:(size_t)length DS_WARN_UNUSED_RESULT;

@end


NS_SWIFT_NAME(DSIndex.FixedLengthField)
@interface DSFixedLengthIndexField : DSIndexField

@property (nonatomic, readonly) NSUInteger dataSize;

@end


NS_SWIFT_NAME(DSIndex.ExternalDataField)
@interface DSExternalDataIndexField : DSFixedLengthIndexField

@property (nonatomic, readonly, copy) NSString *externalIndexName;

@end


NS_SWIFT_NAME(DSIndex.VariableLengthField)
@interface DSVariableLengthIndexField : DSIndexField

@property (nonatomic, readonly) NSUInteger dataSizeLength;

@end


NS_ASSUME_NONNULL_END


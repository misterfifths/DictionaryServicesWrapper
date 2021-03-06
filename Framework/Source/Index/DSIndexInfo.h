// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSDictionaryWrapper.h"
#import "DSDefines.h"
#import "DSConstants.h"

@class DSIndexField;


NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(DSIndex.Info)
@interface DSIndexInfo : DSDictionaryWrapper<DSIndexInfoKey, id>

@property (nonatomic, readonly, copy) DSIndexName name;

@property (nonatomic, readonly, copy) NSString *path;

@property (nonatomic, readonly, copy) NSArray<DSSearchMethod> *supportedSearchMethods;
-(BOOL)supportsSearchMethod:(DSSearchMethod)searchMethod DS_WARN_UNUSED_RESULT;

@property (nonatomic, readonly) BOOL supportsFindByID;

@property (nonatomic, readonly, getter=isBigEndian) BOOL bigEndian;

@property (nonatomic, readonly) NSArray<DSIndexField *> *fields;

@end


NS_ASSUME_NONNULL_END


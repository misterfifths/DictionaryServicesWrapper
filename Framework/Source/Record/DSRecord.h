// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"
#import "DSConstants.h"
#import "DSRecordTextElements.h"

@class DSDictionary;


NS_ASSUME_NONNULL_BEGIN


@interface DSRecord : NSObject

@property (nonatomic, readonly, strong) DSDictionary *dictionary;

@property (nonatomic, readonly, nullable, copy) NSString *keyword;

@property (nonatomic, readonly, nullable, copy) NSString *headword;
@property (nonatomic, readonly, nullable, copy) NSString *rawHeadword;
@property (nonatomic, readonly, nullable, copy) NSString *supplementalHeadword;

@property (nonatomic, readonly, nullable, copy) NSString *title;

@property (nonatomic, readonly, copy) NSString *displayWord;  // tries desperately to return some non-null representative word for this record

@property (nonatomic, readonly, nullable, copy) NSString *anchor;  // If this is a reference to part of another entry, this is an XPointer to that subentry. You can try to follow these with DSXPointer, if you're feeling adventurous.

@property (nonatomic, readonly, strong) DSRecordTextElements *textElements;

-(BOOL)supportsDefinitionStyle:(DSDefinitionStyle)style DS_WARN_UNUSED_RESULT;
-(NSString *)definitionWithStyle:(DSDefinitionStyle)style DS_WARN_UNUSED_RESULT NS_SWIFT_NAME(definition(style:));
@property (nonatomic, readonly, copy) NSString *plainTextDefinition;


+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END

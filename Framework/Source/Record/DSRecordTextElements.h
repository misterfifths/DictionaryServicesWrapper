// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSMutableDictionaryWrapper.h"
#import "DSDefines.h"
#import "DSConstants.h"

@class DSDictionary;


NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(DSRecord.TextElements)
@interface DSRecordTextElements : DSMutableDictionaryWrapper<DSTextElementKey, id>

@property (nonatomic, copy, nullable) NSString *referenceID;  // the "m_en_gbus..." one, not the body ID, which is a number
@property (nonatomic, copy, nullable) NSString *headword;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *syllabifiedHeadword;
@property (nonatomic, copy, nullable) NSString *partOfSpeech;
@property (nonatomic, copy, nullable) NSString *pronunciation;
@property (nonatomic, copy, nullable) NSArray<NSString *> *senses;

-(instancetype)initWithXMLDocument:(NSXMLDocument *)xmlDoc dictionary:(DSDictionary *)dictionary;

@end


NS_ASSUME_NONNULL_END

// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"


NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(DSDictionary.ContentLanguagePair)
@interface DSContentLanguagePair : NSObject

// Language of search terms in the dictionary
@property (nonatomic, readonly, copy) NSString *indexLanguageID;
-(NSString *)indexLanguageNameInLocale:(nullable NSLocale *)nameLocale DS_WARN_UNUSED_RESULT;
@property (nonatomic, readonly, strong) NSLocale *indexLocale;

// Language of the descriptions/definitions in the dictionary
@property (nonatomic, readonly, copy) NSString *definitionLanguageID;
-(NSString *)definitionLanguageNameInLocale:(nullable NSLocale *)nameLocale DS_WARN_UNUSED_RESULT;
@property (nonatomic, readonly, strong) NSLocale *definitionLocale;


+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

-(instancetype)initWithDictionary:(NSDictionary<NSString *, NSString *> *)dict;

@end


NS_ASSUME_NONNULL_END

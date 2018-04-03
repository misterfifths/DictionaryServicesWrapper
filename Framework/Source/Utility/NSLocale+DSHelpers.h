// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface NSLocale (DSHelpers)

+(NSLocale *)ds_localeFromLanguageID:(NSString *)languageID;
+(NSString *)ds_humanNameForLanguageID:(NSString *)languageID inLocale:(nullable NSLocale *)nameLocale;

@end


NS_ASSUME_NONNULL_END

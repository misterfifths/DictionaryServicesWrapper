// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface NSString (DSHelpers)

-(NSString *)ds_normalizedStringForSearchInLocale:(nullable NSLocale *)locale caseSensitive:(BOOL)caseSensitive NS_SWIFT_NAME(normalizedStringForSearch(locale:caseSensitive:));

@end


@interface NSMutableString (DSHelpers)

-(void)ds_normalizeForSearchInLocale:(nullable NSLocale *)locale caseSensitive:(BOOL)caseSensitive NS_SWIFT_NAME(normalizeForSearch(locale:caseSensitive:));

@end


NS_ASSUME_NONNULL_END

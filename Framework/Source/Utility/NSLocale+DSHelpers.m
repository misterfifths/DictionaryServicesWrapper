// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "NSLocale+DSHelpers.h"

@implementation NSLocale (DSHelpers)

+(NSLocale *)ds_localeFromLanguageID:(NSString *)languageID
{
    // The docs swear +canonicalLanguageIdentifierFromString: and +localeIdentifierFromComponents: won't
    // return nil. I'm suspicious.
    NSString *canonLanguageID = [NSLocale canonicalLanguageIdentifierFromString:(NSString * __nonnull)languageID];
    NSString *localeID = [NSLocale localeIdentifierFromComponents:@{ NSLocaleLanguageCode: canonLanguageID }];

    return [NSLocale localeWithLocaleIdentifier:localeID];
}

+(NSString *)ds_humanNameForLanguageID:(NSString *)languageID inLocale:(NSLocale *)locale
{
    if(!locale) locale = [NSLocale currentLocale];

    NSString *canonLanguageID = [NSLocale canonicalLanguageIdentifierFromString:languageID];

    NSString *name = [locale displayNameForKey:NSLocaleLanguageCode value:canonLanguageID];
    return name ?: languageID;
}

@end

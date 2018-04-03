// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "NSString+DSHelpers.h"
#import "FrameworkInternals.h"


@implementation NSString (DSHelpers)

-(NSString *)ds_normalizedStringForSearchInLocale:(NSLocale *)locale caseSensitive:(BOOL)caseSensitive
{
    NSString *ms = [self mutableCopy];
    DCSNormalizeSearchStringWithOptionsAndLocale((NSMutableString * __nonnull) ms, caseSensitive ? DCSearchStringNormalizationOptionMaintainCase : DCSearchStringNormalizationOptionNone, locale);

    return ms;
}

@end


@implementation NSMutableString (DSHelpers)

-(void)ds_normalizeForSearchInLocale:(NSLocale *)locale caseSensitive:(BOOL)caseSensitive
{
    DCSNormalizeSearchStringWithOptionsAndLocale(self, caseSensitive ? DCSearchStringNormalizationOptionMaintainCase : DCSearchStringNormalizationOptionNone, locale);
}

@end

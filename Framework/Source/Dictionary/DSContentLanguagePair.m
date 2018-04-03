// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSContentLanguagePair.h"
#import "FrameworkInternals.h"
#import "NSLocale+DSHelpers.h"


@interface DSContentLanguagePair ()

@property (nonatomic, readwrite, copy) NSString *indexLanguageID;
@property (nonatomic, readwrite, copy) NSString *definitionLanguageID;

@end


@implementation DSContentLanguagePair

-(instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if(self) {
        _indexLanguageID = [dict[kDCSDictionaryIndexLanguage] copy];
        NSAssert(_indexLanguageID != nil, @"Language pair dictionary missing %@ key", kDCSDictionaryIndexLanguage);

        _definitionLanguageID = [dict[kDCSDictionaryDescriptionLanguage] copy];
        NSAssert(_definitionLanguageID != nil, @"Language pair dictionary missing %@ key", kDCSDictionaryDescriptionLanguage);
    }

    return self;
}

-(NSString *)indexLanguageNameInLocale:(NSLocale *)nameLocale
{
    return [NSLocale ds_humanNameForLanguageID:self.indexLanguageID inLocale:nameLocale];
}

-(NSLocale *)indexLocale
{
    return [NSLocale ds_localeFromLanguageID:self.indexLanguageID];
}

-(NSString *)definitionLanguageNameInLocale:(NSLocale *)nameLocale
{
    return [NSLocale ds_humanNameForLanguageID:self.definitionLanguageID inLocale:nameLocale];
}

-(NSLocale *)definitionLocale
{
    return [NSLocale ds_localeFromLanguageID:self.definitionLanguageID];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p: %@ -> %@>", self.class, (void *)self, [self indexLanguageNameInLocale:nil], [self definitionLanguageNameInLocale:nil]];
}

@end

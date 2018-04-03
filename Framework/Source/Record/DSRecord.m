// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSRecord.h"
#import "DSDictionary.h"
#import "FrameworkInternals.h"
#import "DSRecordPrivate.h"


@interface DSRecord ()

@property (nonatomic, readwrite, strong) DSDictionary *dictionary;

@end


@implementation DSRecord

// Public in FrameworkBridging.h
-(instancetype)initWithRecordRef:(DCSRecordRef)recordRef
                      dictionary:(DSDictionary *)dictionary
{
    self = [[DSConcreteRecord alloc] initWithRecordRef:recordRef dictionary:dictionary];
    return self;
}

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        _dictionary = dictionary;
    }

    return self;
}

-(BOOL)supportsDefinitionStyle:(DSDefinitionStyle)style
{
    return [self.dictionary supportsDefinitionStyle:style];
}

-(NSString *)definitionWithStyle:(DSDefinitionStyle)format
{
    return @"";
}

-(NSString *)displayWord
{
    return self.title ?: self.textElements.title ?: self.headword ?: self.textElements.headword ?: self.rawHeadword ?: self.keyword ?: self.supplementalHeadword ?: self.textElements.recordID ?: @"";
}

-(NSString *)plainTextDefinition
{
    return [self definitionWithStyle:DSDefinitionStylePlainText];
}

-(NSString *)description
{
    NSMutableString *contentDesc = [NSMutableString new];
    NSString *spacer = @"";

    if(self.textElements.recordID) {
        [contentDesc appendString:(NSString * __nonnull)self.textElements.recordID];
        spacer = @" ";
    }
    if(self.title) {
        [contentDesc appendFormat:@"%@title='%@'", spacer, self.title];
        spacer = @", ";
    }
    if(self.headword && (!self.title || ![self.headword isEqualToString:(NSString * __nonnull)self.title])) {
        [contentDesc appendFormat:@"%@hw='%@'", spacer, self.headword];
        // spacer = @", ";
    }

    return [NSString stringWithFormat:@"<%@ %p: %@>", self.class, (void *)self, contentDesc];
}

@end

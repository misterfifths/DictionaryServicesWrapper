// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSRecordPrivate.h"
#import "FrameworkInternals.h"


@interface DSConcreteRecord ()

@property (nonatomic) DCSRecordRef recordRef;

@end


@implementation DSConcreteRecord

@synthesize textElements=_textElements;

-(instancetype)initWithRecordRef:(DCSRecordRef)recordRef dictionary:(DSDictionary *)dictionary
{
    self = [super initWithDictionary:dictionary];
    if(self) {
        _recordRef = CFRetain(recordRef);
        _recordRef = recordRef;
    }

    return self;
}

-(void)dealloc
{
    if(_recordRef) CFRelease(_recordRef);
}

-(NSString *)keyword
{
    return DCSRecordGetString(self.recordRef);
}

-(NSString *)headword
{
    return DCSRecordGetHeadword(self.recordRef);
}

-(NSString *)rawHeadword
{
    return DCSRecordGetRawHeadword(self.recordRef);
}

-(NSString *)supplementalHeadword
{
    return DCSRecordGetSupplementalHeadword(self.recordRef);
}

-(NSString *)title
{
    return DCSRecordGetTitle(self.recordRef);
}

-(NSString *)anchor
{
    return DCSRecordGetAnchor(self.recordRef);
}

-(DSRecordTextElements *)textElements
{
    if(!_textElements) {
        NSDictionary *teDict = DCSRecordCopyTextElements(self.recordRef, nil);
        _textElements = [[DSRecordTextElements alloc] initWithDictionaryNoCopy:teDict];
    }

    return _textElements;
}

-(NSString *)definitionWithStyle:(DSDefinitionStyle)style
{
    // TODO: keyword idx says it doesn't support the raw data style (even though it totally could...)
    // should we hack support in?

    NSAssert([self supportsDefinitionStyle:style], @"Unsupported definition style %lu", style);

    // Assuming that if it's a valid definition style we're going to get a string out of this --
    // it's technically nullable, but ...
    return (NSString * __nonnull)DCSRecordCopyDefinition(self.recordRef, (DCSDefinitionStyle)style);
}

@end

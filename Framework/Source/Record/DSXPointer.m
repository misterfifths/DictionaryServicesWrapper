// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSXPointer.h"
#import "DSXMLDocumentCache.h"
#import "DSXMLUtils.h"
#import "DSBetterReferenceIndex.h"
#import "DSRecordBodyParser.h"


@interface DSXPointer ()

@property (nonatomic, readwrite, copy) NSString *targetReferenceID;
@property (nonatomic, readwrite, copy) NSString *targetSubEntryID;
@property (nonatomic, readwrite, copy) NSString *targetDescription;

@end


@implementation DSXPointer

-(instancetype)initWithXPointerString:(NSString *)xpointer
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *regexError = nil;
        regex = [NSRegularExpression regularExpressionWithPattern:@"^xpointer\\(//\\*\\[@id='(.+)\\.(.+)'\\]\\)$" options:0 error:&regexError];

        NSAssert(regex != nil, @"Regex error: %@", regexError);
    });


    NSTextCheckingResult *match = [regex firstMatchInString:xpointer options:0 range:NSMakeRange(0, xpointer.length)];
    NSAssert(match && match.range.location != NSNotFound, @"Didn't understand this xpointer: %@", xpointer);

    self = [super init];
    if(self) {
        NSRange referenceIDRange = [match rangeAtIndex:1];
        _targetReferenceID = [xpointer substringWithRange:referenceIDRange];

        NSRange subEntryIDRange = [match rangeAtIndex:2];
        _targetSubEntryID = [xpointer substringWithRange:subEntryIDRange];

        _targetDescription = [NSString stringWithFormat:@"%@.%@", _targetReferenceID, _targetSubEntryID];
    }

    return self;
}

-(NSXMLNode *)followInDictionary:(DSDictionary *)dictionary
{
    DSBetterReferenceIndex *betterRefIdx = dictionary.betterReferenceIndex;

    NSString *subEntryXPath = [NSString stringWithFormat:@"//*[@id='%@.%@']", self.targetReferenceID, self.targetSubEntryID];


    DSBetterReferenceIndexEntry *refInfo = betterRefIdx[self.targetReferenceID];
    DSBodyDataID bodyID = refInfo.bodyDataID;
    NSAssert(refInfo != nil && bodyID != 0, @"Couldn't find the other end of xpointer (%@) in the reference index", self.targetReferenceID);

    NSXMLDocument *xmlDoc = [dictionary.xmlDocumentCache documentForBodyDataID:bodyID];

    NSError *error = nil;
    NSArray<NSXMLNode *> *subEntryNodes = [xmlDoc nodesForXPath:subEntryXPath error:&error];
    NSAssert(subEntryNodes != nil, @"Error running xpointer XPath: %@", error);

    NSAssert(subEntryNodes.count == 1, @"XPointer XPath resolved to %lu nodes; expected exactly 1", subEntryNodes.count);

    return (NSXMLNode * __nonnull)subEntryNodes.firstObject;
}

-(NSArray<DSRecordSubEntry *> *)followToSubEntriesInDictionary:(DSDictionary *)dictionary
{
    NSXMLNode *subEntryNode = [self followInDictionary:dictionary];
    NSAssert(subEntryNode.kind == NSXMLElementKind, @"XPointer doesn't point to an element!");
    return [DSRecordBodyParser parseSubEntryFragment:(NSXMLElement *)subEntryNode];
}

-(NSUInteger)hash
{
    return self.targetDescription.hash;
}

-(BOOL)isEqual:(id)object
{
    if(!object) return NO;
    if([object isKindOfClass:[DSXPointer class]]) return NO;
    return [self.targetDescription isEqualToString:((DSXPointer *)object).targetDescription];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p: %@>", self.class, (void *)self, self.targetDescription];
}

@end

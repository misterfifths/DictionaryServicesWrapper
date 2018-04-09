// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSXMLDocumentCache.h"
#import <objc/objc-runtime.h>


@interface DSXMLDocumentCache ()

@property (nonatomic, readwrite, weak) DSDictionary *dictionary;
@property (nonatomic, strong) NSCache<NSNumber *, NSXMLDocument *> *rawCache;

@end


@implementation DSXMLDocumentCache

-(instancetype)initForReadingFromDictionary:(DSDictionary *)dictionary
{
    self = [super init];
    if(self) {
        _dictionary = dictionary;

        _rawCache = [NSCache new];
        _rawCache.name = [NSString stringWithFormat:@"%@ for %@", self.class, dictionary.identifier];
    }

    return self;
}

-(NSXMLDocument *)documentForBodyDataID:(DSBodyDataID)bodyDataID
{
    NSNumber *key = DSNumberForBodyDataID(bodyDataID);

    NSXMLDocument *doc = [self.rawCache objectForKey:key];
    if(doc) return doc;

    NSString *bodyXML = [self.dictionary.bodyDataIndex dataForRecordID:bodyDataID];
    NSCAssert(bodyXML != nil, @"No body data for id %@", DSStringForBodyDataID(bodyDataID));

    NSError *error = nil;
    doc = [[NSXMLDocument alloc] initWithXMLString:bodyXML options:0 error:&error];
    NSCAssert(doc != nil, @"Couldn't parse XML: %@", error);

    [self.rawCache setObject:doc forKey:key];

    return doc;
}

-(void)evictDocumentForBodyDataID:(DSBodyDataID)bodyDataID
{
    [self.rawCache removeObjectForKey:DSNumberForBodyDataID(bodyDataID)];
}

-(void)evictAllDocuments
{
    [self.rawCache removeAllObjects];
}

-(NSUInteger)countLimit
{
    return self.rawCache.countLimit;
}

-(void)setCountLimit:(NSUInteger)countLimit
{
    self.rawCache.countLimit = countLimit;
}

@end


@implementation DSDictionary (DSXMLDocumentCache)

-(DSXMLDocumentCache *)xmlDocumentCache
{
    static const void * const DSXMLDocumentCacheAssociatedObjectKey = &DSXMLDocumentCacheAssociatedObjectKey;

    DSXMLDocumentCache *cache = objc_getAssociatedObject(self, DSXMLDocumentCacheAssociatedObjectKey);
    if(!cache) {
        cache = [[DSXMLDocumentCache alloc] initForReadingFromDictionary:self];
        objc_setAssociatedObject(self, DSXMLDocumentCacheAssociatedObjectKey, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return cache;
}

@end

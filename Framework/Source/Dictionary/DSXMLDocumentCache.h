// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDictionary.h"
#import "DSDefines.h"


NS_ASSUME_NONNULL_BEGIN

// This uses an NSCache under the hood, so it will start evicting things
// automatically if memory pressure sets in.
// TODO: make everything in DSW that fetches from the body data index use this instead?

@interface DSXMLDocumentCache : NSObject

@property (nonatomic, readonly, weak) DSDictionary *dictionary;
@property (nonatomic) NSUInteger countLimit;  // not precise or strict


-(instancetype)initForReadingFromDictionary:(DSDictionary *)dictionary;

-(NSXMLDocument *)documentForBodyDataID:(DSBodyDataID)bodyDataID DS_WARN_UNUSED_RESULT;
-(void)evictDocumentForBodyDataID:(DSBodyDataID)bodyDataID;

-(void)evictAllDocuments;


+(instancetype)new NS_UNAVAILABLE;
-(instancetype)init NS_UNAVAILABLE;

@end


@interface DSDictionary (DSXMLDocumentCache)

@property (nonatomic, readonly) DSXMLDocumentCache *xmlDocumentCache;

@end


NS_ASSUME_NONNULL_END

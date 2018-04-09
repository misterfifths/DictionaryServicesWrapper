// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"

@class DSDictionary;
@class DSIndexEntry;


NS_ASSUME_NONNULL_BEGIN


@interface DSSyntheticRecord : DSRecord

@property (nonatomic, readonly, strong) NSXMLDocument *bodyXML;


-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       indexEntry:(DSIndexEntry *)indexEntry
                  recordXMLNoCopy:(NSXMLDocument *)xmlDoc;

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       indexEntry:(DSIndexEntry *)indexEntry
                        recordXML:(NSXMLDocument *)xmlDoc;

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       indexEntry:(DSIndexEntry *)indexEntry
                  recordXMLString:(NSString *)xmlString;

// Will look up the XML in the dictionary's body index
-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       indexEntry:(DSIndexEntry *)indexEntry;

// These will attempt to reconsitute a record without a keyword index entry (for instance, if coming
// straight from a reference ID)
-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       bodyDataID:(DSBodyDataID)bodyDataID;

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                  recordXMLString:(NSString *)xmlString;

-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                  recordXMLNoCopy:(NSXMLDocument *)xmlDoc;

@end


NS_ASSUME_NONNULL_END

// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSRecord.h"
#import "FrameworkInternals.h"

@class DSIndex;
@class DSIndexEntry;


NS_ASSUME_NONNULL_BEGIN


@interface DSRecord (ProtectedInitializer)

-(instancetype)initWithDictionary:(DSDictionary *)dictionary;

// This is a little janky, but this lives on the base class so we can expose it in
// FrameworkBridging.h without exposing DSConcreteRecords.
-(instancetype)initWithRecordRef:(DCSRecordRef)recordRef
                      dictionary:(DSDictionary *)dictionary;

@end


@interface DSConcreteRecord : DSRecord

-(instancetype)initWithDictionary:(DSDictionary *)dictionary NS_UNAVAILABLE;

@end


@interface DSSyntheticRecord : DSRecord

@property (nonatomic, readonly, strong) NSXMLDocument *bodyXML;


-(instancetype)initWithDictionary:(DSDictionary *)dictionary NS_UNAVAILABLE;
-(instancetype)initWithRecordRef:(DCSRecordRef)recordRef dictionary:(DSDictionary *)dictionary NS_UNAVAILABLE;

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

// Will attempt to reconsitute a record without a keyword index entry (for instance, if coming
// straight from a reference ID)
-(instancetype)initWithDictionary:(DSDictionary *)dictionary
                       bodyDataID:(uint64_t)bodyDataID;

@end


NS_ASSUME_NONNULL_END

// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSBetterReferenceIndex.h"
#import "DSSynthesizedIndexPrivate.h"
#import "DSMiscUtils.h"
#import "DSXMLDocumentCache.h"
#import "DSMutableDictionaryWrapperUtils.h"
#import "DSXMLUtils.h"
#import <objc/objc-runtime.h>


typedef NSMutableDictionary<NSString *, DSBetterReferenceIndexEntry *> DSBetterReferenceMutableIndexMap;
typedef NSMutableDictionary<NSString *, NSDictionary *> DSBetterReferenceIndexMutablePlist;


@implementation DSBetterReferenceIndex

+(DSBetterReferenceIndexMap *)mapFromPlist:(DSBetterReferenceIndexPlist *)plist
{
    DSBetterReferenceMutableIndexMap *res = [NSMutableDictionary dictionaryWithCapacity:plist.count];

    for(NSString *referenceID in plist) {
        NSDictionary *dataForRef = plist[referenceID];
        DSBetterReferenceIndexEntry *entry = [[DSBetterReferenceIndexEntry alloc] initWithDictionaryNoCopy:dataForRef];
        res[referenceID] = entry;
    }

    return res;
}

+(DSBetterReferenceIndexPlist *)plistFromMap:(DSBetterReferenceIndexMap *)map
{
    DSBetterReferenceIndexMutablePlist *res = [NSMutableDictionary dictionaryWithCapacity:map.count];

    for(NSString *referenceIDOrBodyDataIDString in map) {
        DSBetterReferenceIndexEntry *entryForRef = map[referenceIDOrBodyDataIDString];
        res[referenceIDOrBodyDataIDString] = entryForRef.rawDictionary;
    }

    return res;
}

+(DSBetterReferenceIndexMap *)createMapForDictionary:(DSDictionary *)dictionary
{
    DSIndex *keywordIdx = dictionary.keywordIndex;

    NSDictionary *textElementXPaths = dictionary.textElementXPaths;
    NSString *entryReferenceIDXPath = textElementXPaths[DSTextElementKeyRecordID] ?: @"//d:entry/@id";
    NSString *entryTitleXPath = textElementXPaths[DSTextElementKeyTitle] ?: @"//d:entry/@d:title";

    DSBetterReferenceMutableIndexMap *res = [NSMutableDictionary dictionaryWithCapacity:98388];  // NOAD size

    [keywordIdx enumerateMatchesForString:@"" method:DSSearchMethodPrefixMatch usingBlock:^(DSIndexEntry *entry, BOOL *stop) {
        DSBodyDataID bodyDataID = entry.externalBodyID;
        NSString *bodyDataIDString = DSStringForBodyDataID(bodyDataID);

        // Possible we've already seen this body.
        DSBetterReferenceIndexEntry *bodyInfo = res[bodyDataIDString];
        if(bodyInfo) {
            return;
        }


        NSXMLDocument *xmlDoc = [dictionary.xmlDocumentCache documentForBodyDataID:bodyDataID];
        NSString *xmlTitle = [xmlDoc ds_nonEmptyTrimmedStringValuesForXPath:entryTitleXPath].firstObject;
        NSString *referenceID = [xmlDoc ds_nonEmptyTrimmedStringValuesForXPath:entryReferenceIDXPath].firstObject;


        DSBetterReferenceIndexEntry *referenceEntry = [DSBetterReferenceIndexEntry new];
        referenceEntry.bodyDataID = bodyDataID;
        referenceEntry.referenceID = referenceID;
        referenceEntry.title = xmlTitle;

        res[bodyDataIDString] = referenceEntry;
        res[referenceID] = referenceEntry;
    }];

    return res;
}

-(DSBetterReferenceIndexEntry *)entryForReferenceID:(NSString *)referenceID
{
    DSBetterReferenceIndexEntry *entry = self.rawMap[referenceID];
    NSAssert(entry != nil, @"Couldn't find entry for reference id %@", referenceID);
    return entry;
}

-(DSBodyDataID)bodyDataIDForReferenceID:(NSString *)referenceID
{
    return [self entryForReferenceID:referenceID].bodyDataID;
}

-(NSString *)titleForReferenceID:(NSString *)referenceID
{
    return [self entryForReferenceID:referenceID].title;
}

-(DSBetterReferenceIndexEntry *)entryForBodyDataID:(DSBodyDataID)bodyDataID
{
    NSString *idString = DSStringForBodyDataID(bodyDataID);
    DSBetterReferenceIndexEntry *entry = self.rawMap[idString];
    NSAssert(entry != nil, @"Couldn't find entry for body data id %@", idString);
    return entry;
}

-(NSString *)referenceIDForBodyDataID:(DSBodyDataID)bodyDataID
{
    return [self entryForBodyDataID:bodyDataID].referenceID;
}

-(NSString *)titleForBodyDataID:(DSBodyDataID)bodyDataID
{
    return [self entryForBodyDataID:bodyDataID].title;
}

-(DSBetterReferenceIndexEntry *)objectForKeyedSubscript:(id)referenceIDOrBodyIDStringOrBodyIDNumber
{
    if([referenceIDOrBodyIDStringOrBodyIDNumber isKindOfClass:[NSString class]]) {
        DSBetterReferenceIndexEntry *entry = self.rawMap[referenceIDOrBodyIDStringOrBodyIDNumber];
        NSAssert(entry != nil, @"Couldn't find entry for %@", referenceIDOrBodyIDStringOrBodyIDNumber);
        return entry;
    }

    if([referenceIDOrBodyIDStringOrBodyIDNumber isKindOfClass:[NSNumber class]]) {
        DSBodyDataID bodyDataID = DSBodyDataIDFromNumber(referenceIDOrBodyIDStringOrBodyIDNumber);
        return [self entryForBodyDataID:bodyDataID];
    }

    NSAssert(NO, @"Unexpected subscript type %@; expected string or number", [referenceIDOrBodyIDStringOrBodyIDNumber class]);
    return nil;
}

@end



@interface DSBetterReferenceIndexEntry ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *dict;

@end


@implementation DSBetterReferenceIndexEntry

// You're just going to have to trust me on this one, clang.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"


-(DSBodyDataID)bodyDataID
{
    return DSBodyDataIDFromNumber(self[@"bodyDataID"]);
}

-(void)setBodyDataID:(DSBodyDataID)bodyDataID
{
    self[@"bodyDataID"] = DSNumberForBodyDataID(bodyDataID);
}

DS_MDW_StringPropertyImpl(referenceID, setReferenceID, @"referenceID");
DS_MDW_StringPropertyImpl(title, setTitle, @"title");


#pragma clang diagnostic pop

@end


@implementation DSDictionary (DSBetterReferenceIndex)

static const void * const DSDictionary_BetterReferenceIndexAssociatedObjectKey = &DSDictionary_BetterReferenceIndexAssociatedObjectKey;


-(BOOL)betterReferenceIndexIsLoaded
{
    return objc_getAssociatedObject(self, DSDictionary_BetterReferenceIndexAssociatedObjectKey) != nil;
}

-(void)evictBetterReferenceIndex
{
    objc_setAssociatedObject(self, DSDictionary_BetterReferenceIndexAssociatedObjectKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

-(DSBetterReferenceIndex *)betterReferenceIndex
{
    DSBetterReferenceIndex *index = objc_getAssociatedObject(self, DSDictionary_BetterReferenceIndexAssociatedObjectKey);
    if(!index) {
        index = [DSBetterReferenceIndex indexForDictionary:self useDefaultCache:YES];
        objc_setAssociatedObject(self, DSDictionary_BetterReferenceIndexAssociatedObjectKey, index, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return index;
}

@end

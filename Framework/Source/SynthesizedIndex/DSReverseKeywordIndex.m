// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSReverseKeywordIndex.h"
#import "DSMiscUtils.h"
#import "DSSynthesizedIndexPrivate.h"
#import <objc/objc-runtime.h>


typedef NSMutableDictionary<NSString *, NSMutableArray<DSIndexEntry *> *> DSReverseKeywordIndexMutableMap;
typedef NSMutableDictionary<NSString *, NSMutableArray<NSDictionary *> *> DSReverseKeywordIndexMutablePlist;


@implementation DSReverseKeywordIndex

+(DSReverseKeywordIndexMap *)mapFromPlist:(DSReverseKeywordIndexPlist *)plist
{
    DSReverseKeywordIndexMutableMap *res = [NSMutableDictionary dictionaryWithCapacity:plist.count];

    for(NSString *bodyDataIDString in plist) {
        NSArray<NSDictionary *> *indexEntryDicts = plist[bodyDataIDString];
        NSMutableArray<DSIndexEntry *> *indexEntries = [NSMutableArray arrayWithCapacity:indexEntryDicts.count];

        for(NSDictionary *indexEntryDict in indexEntryDicts) {
            [indexEntries addObject:[[DSIndexEntry alloc] initWithDictionaryNoCopy:indexEntryDict]];
        }

        res[bodyDataIDString] = indexEntries;
    }

    return res;
}

+(DSReverseKeywordIndexPlist *)plistFromMap:(DSReverseKeywordIndexMap *)map
{
    DSReverseKeywordIndexMutablePlist *res = [NSMutableDictionary dictionaryWithCapacity:map.count];

    for(NSString *bodyDataIDString in map) {
        NSArray<DSIndexEntry *> *entriesForBody = map[bodyDataIDString];

        NSMutableArray<NSDictionary *> *dictEntriesForBody = [NSMutableArray arrayWithCapacity:entriesForBody.count];
        for(DSIndexEntry *entry in entriesForBody) {
            [dictEntriesForBody addObject:entry.rawDictionary];
        }
        res[bodyDataIDString] = dictEntriesForBody;
    }

    return res;
}

+(DSReverseKeywordIndexMap *)createMapForDictionary:(DSDictionary *)dictionary
{
    DSIndex *keywordIdx = dictionary.keywordIndex;

    DSReverseKeywordIndexMutableMap *entriesByBodyID = [NSMutableDictionary dictionaryWithCapacity:196776];  // the NOAD size

    [keywordIdx enumerateMatchesForString:@"" method:DSSearchMethodPrefixMatch usingBlock:^(DSIndexEntry *entry, BOOL *stop) {
        @autoreleasepool {
            DSBodyDataID bodyDataID = entry.externalBodyID;
            NSString *bodyDataIDString = DSStringForBodyDataID(bodyDataID);

            NSMutableArray<DSIndexEntry *> *entriesForThisBodyID = entriesByBodyID[bodyDataIDString];
            if(entriesForThisBodyID) [entriesForThisBodyID addObject:entry];
            else entriesByBodyID[bodyDataIDString] = [NSMutableArray arrayWithObject:entry];
        }
    }];

    return entriesByBodyID;
}

-(NSArray<DSIndexEntry *> *)keywordIndexEntriesForBodyDataID:(DSBodyDataID)bodyDataID
{
    NSString *bodyDataIDString = DSStringForBodyDataID(bodyDataID);
    NSArray *res = self.rawMap[bodyDataIDString];
    NSAssert(res != nil, @"Couldn't find body data ID %@ in reverse keyword index", bodyDataIDString);
    return res;
}

-(NSArray<DSIndexEntry *> *)objectForKeyedSubscript:(NSNumber *)bodyDataIDNumber
{
    return [self keywordIndexEntriesForBodyDataID:DSBodyDataIDFromNumber(bodyDataIDNumber)];
}

-(void)enumerateBodiesUsingBlock:(void (^)(DSBodyDataID, NSArray<DSIndexEntry *> *, BOOL *))block
{
    BOOL stop = NO;
    for(NSString *bodyDataIDString in self.rawMap) {
        NSArray<DSIndexEntry *> *entries = self.rawMap[bodyDataIDString];
        DSBodyDataID bodyDataID = DSBodyDataIDFromString(bodyDataIDString);

        block(bodyDataID, entries, &stop);
        if(stop) break;
    }
}

@end


@implementation DSDictionary (DSReverseKeywordIndex)

static const void * const DSDictionary_ReverseKeywordIndexAssociatedObjectKey = &DSDictionary_ReverseKeywordIndexAssociatedObjectKey;


-(BOOL)reverseKeywordIndexIsLoaded
{
    return objc_getAssociatedObject(self, DSDictionary_ReverseKeywordIndexAssociatedObjectKey) != nil;
}

-(void)evictReverseKeywordIndex
{
    objc_setAssociatedObject(self, DSDictionary_ReverseKeywordIndexAssociatedObjectKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

-(DSReverseKeywordIndex *)reverseKeywordIndex
{
    DSReverseKeywordIndex *index = objc_getAssociatedObject(self, DSDictionary_ReverseKeywordIndexAssociatedObjectKey);
    if(!index) {
        index = [DSReverseKeywordIndex indexForDictionary:self useDefaultCache:YES];
        objc_setAssociatedObject(self, DSDictionary_ReverseKeywordIndexAssociatedObjectKey, index, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return index;
}

@end

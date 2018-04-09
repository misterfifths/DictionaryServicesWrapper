// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSIndexEntry.h"
#import "DSMutableDictionaryWrapperUtils.h"
#import "DSMiscUtils.h"


@implementation DSIndexEntry

+(id)sharedKeySet
{
    static id keySet;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keySet = [NSMutableDictionary sharedKeySetForKeys:@[ DSIndexFieldNameExternalBodyID,
                                                             DSIndexFieldNamePrivateFlag,
                                                             DSIndexFieldNameKeyword,
                                                             DSIndexFieldNameHeadword,
                                                             DSIndexFieldNameEntryTitle,
                                                             DSIndexFieldNameAnchor,
                                                             DSIndexFieldNameYomiWord,
                                                             DSIndexFieldNameSortKey ]];
    });

    return keySet;
}

-(DSBodyDataID)externalBodyID
{
    return DSBodyDataIDFromNumber(self[DSIndexFieldNameExternalBodyID]);
}

-(void)setExternalBodyID:(DSBodyDataID)externalBodyID
{
    self[DSIndexFieldNameExternalBodyID] = DSNumberForBodyDataID(externalBodyID);
}

-(uint64_t)privateFlag
{
    return [self[DSIndexFieldNamePrivateFlag] unsignedLongLongValue];
}

-(void)setPrivateFlag:(uint64_t)privateFlag
{
    self[DSIndexFieldNamePrivateFlag] = @(privateFlag);
}

-(BOOL)isCensored
{
    return self.privateFlag & DSIndexFieldPrivateFlagBitmaskCensored;
}

-(void)setCensored:(BOOL)isCensored
{
    if(isCensored) self.privateFlag |= DSIndexFieldPrivateFlagBitmaskCensored;
    else self.privateFlag &= ~DSIndexFieldPrivateFlagBitmaskCensored;
}

-(uint8_t)priority
{
    return self.privateFlag & DSIndexFieldPrivateFlagBitmaskPriority;
}

-(void)setPriority:(uint8_t)priority
{
    self.privateFlag |= priority & DSIndexFieldPrivateFlagBitmaskPriority;
}

DS_MDW_StringPropertyImpl(keyword, setKeyword, DSIndexFieldNameKeyword);
DS_MDW_StringPropertyImpl(headword, setHeadword, DSIndexFieldNameHeadword);
DS_MDW_StringPropertyImpl(entryTitle, setEntryTitle, DSIndexFieldNameEntryTitle);
DS_MDW_StringPropertyImpl(anchor, setAnchor, DSIndexFieldNameAnchor);
DS_MDW_StringPropertyImpl(yomiWord, setYomiWord, DSIndexFieldNameYomiWord);
DS_MDW_StringPropertyImpl(supplementalHeadword, setSupplementalHeadword, DSIndexFieldNameYomiWord);  // sic
DS_MDW_StringPropertyImpl(sortKey, setSortKey, DSIndexFieldNameSortKey);


-(NSString *)displayWord
{
    return DSFirstNonEmptyString(self.entryTitle, self.headword, self.supplementalHeadword, self.keyword);
}

-(NSString *)description
{
    NSMutableString *contentDesc = [NSMutableString new];

    NSUInteger extraFieldCount = self.count;
    if(extraFieldCount == 0) {
        [contentDesc appendString:@"no fields"];
    }
    else {
        NSString *spacer = @"";

        if(self.displayWord) {
            [contentDesc appendFormat:@"'%@'", self.displayWord];
            --extraFieldCount;
            spacer = @" ";
        }

        if(contentDesc.length == 0 && self.externalBodyID) {
            [contentDesc appendFormat:@"%@bodyID=%@", spacer, DSStringForBodyDataID(self.externalBodyID)];
            --extraFieldCount;
            spacer = @" ";
        }

        if(extraFieldCount > 0)
            [contentDesc appendFormat:@"%@(+%lu fields)", spacer, extraFieldCount];
    }

    return [NSString stringWithFormat:@"<%@ %p: %@>", self.class, (void *)self, contentDesc];
}

@end

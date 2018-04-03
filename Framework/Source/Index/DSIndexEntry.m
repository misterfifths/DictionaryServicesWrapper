// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSIndexEntry.h"
#import "DSCommon.h"


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

-(uint64_t)externalBodyID
{
    return [self[DSIndexFieldNameExternalBodyID] unsignedLongLongValue];
}

-(void)setExternalBodyID:(uint64_t)externalBodyID
{
    self[DSIndexFieldNameExternalBodyID] = @(externalBodyID);
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

-(NSString *)keyword
{
    return self[DSIndexFieldNameKeyword];
}

-(void)setKeyword:(NSString *)keyword
{
    self[DSIndexFieldNameKeyword] = [keyword copy];
}

-(NSString *)headword
{
    return self[DSIndexFieldNameHeadword];
}

-(void)setHeadword:(NSString *)headword
{
    self[DSIndexFieldNameHeadword] = [headword copy];
}

-(NSString *)entryTitle
{
    return self[DSIndexFieldNameEntryTitle];
}

-(void)setEntryTitle:(NSString *)entryTitle
{
    self[DSIndexFieldNameEntryTitle] = [entryTitle copy];
}

-(NSString *)anchor
{
    return self[DSIndexFieldNameAnchor];
}

-(void)setAnchor:(NSString *)anchor
{
    self[DSIndexFieldNameAnchor] = [anchor copy];
}

-(NSString *)yomiWord
{
    return self[DSIndexFieldNameYomiWord];
}

-(void)setYomiWord:(NSString *)yomiWord
{
    self[DSIndexFieldNameYomiWord] = [yomiWord copy];
}

-(NSString *)supplementalHeadword
{
    return self.yomiWord;
}

-(void)setSupplementalHeadword:(NSString *)supplementalHeadword
{
    self.yomiWord = supplementalHeadword;
}

-(NSString *)sortKey
{
    return self[DSIndexFieldNameSortKey];
}

-(void)setSortKey:(NSString *)sortKey
{
    self[DSIndexFieldNameSortKey] = sortKey;
}

-(NSString *)firstNonemptyValueForKeys:(NSArray *)keys
{
    for(id key in keys) {
        NSString *value = self[key];
        if(!value) continue;
        if(![value isKindOfClass:[NSString class]]) continue;
        if(value.length == 0) continue;

        return value;
    }

    return nil;
}

-(NSString *)displayWord
{
    return [self firstNonemptyValueForKeys:@[ DSIndexFieldNameEntryTitle,
                                              DSIndexFieldNameHeadword,
                                              DSIndexFieldNameYomiWord,
                                              DSIndexFieldNameKeyword ]];
}

-(void)mergeIndexEntry:(DSIndexEntry *)other
{
    for(DSIndexFieldName key in other) {
        id ourValue = self[key];
        id theirValue = other[key];

        // We don't have it; copy it over unless it's an empty string
        if(!ourValue) {
            if([theirValue isKindOfClass:[NSString class]] && [theirValue length] == 0)
                continue;

            self[key] = theirValue;
            continue;
        }

        // The values are equal; move on
        if([ourValue isEqual:theirValue])
            continue;

        // Empty string here; they win
        if([ourValue isKindOfClass:[NSString class]] && [ourValue length] == 0) {
            self[key] = theirValue;
            continue;
        }

        // Their value is empty; it loses
        // if([theirValue isKindOfClass:[NSString class]] && [theirValue length] == 0)
        //    continue;

        // Conflict.
        // Alas.
    }
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
            [contentDesc appendFormat:@"%@bodyID=0x%llx", spacer, self.externalBodyID];
            --extraFieldCount;
            spacer = @" ";
        }

        if(extraFieldCount > 0)
            [contentDesc appendFormat:@"%@(+%lu fields)", spacer, extraFieldCount];
    }

    return [NSString stringWithFormat:@"<%@ %p: %@>", self.class, (void *)self, contentDesc];
}

@end

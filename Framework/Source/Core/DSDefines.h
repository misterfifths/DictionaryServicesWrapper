// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>


#define DS_WARN_UNUSED_RESULT __attribute__((warn_unused_result))


typedef uint64_t DSBodyDataID NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DSRecord.BodyDataID);


NS_ASSUME_NONNULL_BEGIN


static inline NSString *DSStringForBodyDataID(DSBodyDataID bodyDataID) DS_WARN_UNUSED_RESULT NS_SWIFT_NAME(getter:DSBodyDataID.stringValue(self:));

static inline NSNumber *DSNumberForBodyDataID(DSBodyDataID bodyDataID) DS_WARN_UNUSED_RESULT NS_SWIFT_UNAVAILABLE("NSNumbers are pretty much dead in Swift");

static inline DSBodyDataID DSBodyDataIDFromString(NSString *bodyDataIDString) DS_WARN_UNUSED_RESULT NS_SWIFT_NAME(DSBodyDataID.init(stringValue:));

static inline DSBodyDataID DSBodyDataIDFromNumber(NSNumber *bodyDataIDNumber) DS_WARN_UNUSED_RESULT NS_SWIFT_UNAVAILABLE("NSNumbers are pretty much dead in Swift");


static inline NSString *DSStringForBodyDataID(DSBodyDataID bodyDataID)
{
    return [NSString stringWithFormat:@"%llu", bodyDataID];
}

static inline NSNumber *DSNumberForBodyDataID(DSBodyDataID bodyDataID)
{
    return @(bodyDataID);
}

static inline DSBodyDataID DSBodyDataIDFromString(NSString *bodyDataIDString)
{
    NSScanner *scanner = [NSScanner scannerWithString:bodyDataIDString];
    DSBodyDataID bodyDataID = 0;
    NSCAssert([scanner scanUnsignedLongLong:&bodyDataID], @"Unable to scan body data ID from string '%@'", bodyDataIDString);
    return bodyDataID;
}

static inline DSBodyDataID DSBodyDataIDFromNumber(NSNumber *bodyDataIDNumber)
{
    return [bodyDataIDNumber unsignedLongLongValue];
}


NS_ASSUME_NONNULL_END

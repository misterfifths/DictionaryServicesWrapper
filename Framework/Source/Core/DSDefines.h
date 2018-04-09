// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#define DS_WARN_UNUSED_RESULT __attribute__((warn_unused_result))


typedef uint64_t DSBodyDataID;


static inline NSString *DSStringForBodyDataID(DSBodyDataID bodyDataID) DS_WARN_UNUSED_RESULT;
static inline NSNumber *DSNumberForBodyDataID(DSBodyDataID bodyDataID) DS_WARN_UNUSED_RESULT;
static inline DSBodyDataID DSBodyDataIDFromString(NSString *bodyDataIDString) DS_WARN_UNUSED_RESULT;
static inline DSBodyDataID DSBodyDataIDFromNumber(NSNumber *bodyDataIDNumber) DS_WARN_UNUSED_RESULT;


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

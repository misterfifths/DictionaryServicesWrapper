// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSMiscUtils.h"

NSString * __nullable __DSFirstNonEmptyString(size_t numArgs, NSString * __nullable first, ...)
{
    NSString *winner = nil;

    va_list args;
    va_start(args, first);

    size_t i = 0;
    do {
        NSString *candidate = nil;

        if(i == 0) candidate = first;
        else candidate = va_arg(args, NSString *);

        if(candidate.length > 0) {
            winner = candidate;
            break;
        }

        ++i;
    } while(i < numArgs);

    va_end(args);

    return winner;
}

NSArray * __nullable __DSArrayOfNonNilValues(size_t numArgs, id __nullable first, ...)
{
    NSMutableArray *res = [NSMutableArray new];

    va_list args;
    va_start(args, first);

    size_t i = 0;
    do {
        id candidate = nil;

        if(i == 0) candidate = first;
        else candidate = va_arg(args, NSString *);

        if(candidate) [res addObject:candidate];

        ++i;
    } while(i < numArgs);

    va_end(args);

    return res;
}


void DSWritePlistObjectToFile(id plistObj, NSURL *fileURL)
{
    NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:fileURL append:NO];
    [outputStream open];
    NSError *error = nil;
    if(![NSPropertyListSerialization writePropertyList:plistObj toStream:outputStream format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error]) {
        NSCAssert(NO, @"Error writing plist: %@", error);
    }
    [outputStream close];
}


id DSReadPlistObjectFromFile(NSURL *fileURL, BOOL mutableContainers)
{
    NSInputStream *inputStream = [NSInputStream inputStreamWithURL:fileURL];

    [inputStream open];
    if([inputStream.streamError.domain isEqualToString:NSPOSIXErrorDomain] && inputStream.streamError.code == ENOENT) return nil;

    NSError *error = nil;
    id plistObj = [NSPropertyListSerialization propertyListWithStream:inputStream options:mutableContainers ? NSPropertyListMutableContainersAndLeaves : 0 format:NULL error:&error];

    if(!plistObj) {
        NSCAssert(NO, @"Error reading plist: %@", error);
    }

    [inputStream close];

    return plistObj;
}

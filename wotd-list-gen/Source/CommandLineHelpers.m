// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "CommandLineHelpers.h"


NS_FORMAT_FUNCTION(1, 2)
void info(NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *result = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    fprintf(stderr, "%s", result.UTF8String);
}

__attribute__((__overloadable__))
id task(NSString *label, id (^block)(NSString **errorMessage))
{
    info(@">> %@...", label);
    NSString *errorMessage = nil;
    id res = block(&errorMessage);
    if(errorMessage) {
        info(@" 💀\n%@\n", errorMessage);
        exit(1);
    }
    else {
        info(@" 👍\n");
    }

    return res;
}

__attribute__((__overloadable__))
id task(NSString *label, id (^block)(void))
{
    return task(label, ^(NSString **errorMessage) {
        return block();
    });
}

__attribute__((__overloadable__))
void task(NSString *label, void (^block)(void))
{
    task(label, ^(NSString **errorMessage) {
        block();
        return (id)nil;
    });
}

__attribute__((__overloadable__))
void task(NSString *label, void (^block)(NSString **errorMessage))
{
    task(label, ^(NSString **errorMessage) {
        block(errorMessage);
        return (id)nil;
    });
}

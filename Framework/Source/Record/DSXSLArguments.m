// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSXSLArguments.h"


static NSString * const DSXSLArgumentsPlaceholderForCSS = @"--- 💃 CSS Content Placeholder because XSL Kinda Sucks 🌈 ---";


@implementation DSXSLArguments

+(id)sharedKeySet
{
    static id keySet;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keySet = [NSMutableDictionary sharedKeySetForKeys:@[ DSXSLArgumentKeyParentalControl,
                                                             DSXSLArgumentKeyAriaLabel,
                                                             DSXSLArgumentKeyBaseURL,
                                                             DSXSLArgumentKeyRTLDirection,
                                                             DSXSLArgumentKeyStylesheetContent ]];
    });

    return keySet;
}

+(NSString *)XSLParameterStringForString:(NSString *)s
{
    // XSL is deeply weird. Parameters are technically XPath expressions, so if you
    // want a literal string, it needs to be in quotes. So an empty string is "''"...

    if(s.length == 0) return @"''";
    return [NSString stringWithFormat:@"'%@'", [self stringByPercentEscapingApostrophesInString:s]];
}

+(NSString *)XSLParameterStringForURL:(NSURL *)url
{
    NSString *s = url.absoluteString;
    if(s.length == 0) return nil;

    // Expand everything, then re-escape, including apostrophes.
    // Can't just use XSLParameterStringForLiteralString; parts of URLs get encoded differently

    NSString *unescaped = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapes(NULL, (__bridge CFStringRef)s, CFSTR(""));
    NSAssert(unescaped != nil, @"Error expanding percent escapes");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    NSString *escaped = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)unescaped, NULL, CFSTR("'"), kCFStringEncodingUTF8);
#pragma clang diagnostic pop

    NSAssert(escaped != nil, @"Error percent escaping");

    if(escaped.length == 0) return @"''";
    return [NSString stringWithFormat:@"'%@'", escaped];
}

+(NSString *)stringByPercentEscapingApostrophesInString:(NSString *)s
{
    static NSCharacterSet *goodChars;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        goodChars = [[NSCharacterSet characterSetWithCharactersInString:@"'"] invertedSet];
    });

    return [s stringByAddingPercentEncodingWithAllowedCharacters:goodChars];
}

+(BOOL)replaceCSSPlaceholderInDocument:(NSXMLDocument *)xmlDoc withContent:(NSString *)css
{
    // Seems like a safe assumption it's in a <style>, yah?
    NSString *placeholderXPath = [NSString stringWithFormat:@"//style[contains(text(), '%@')]", DSXSLArgumentsPlaceholderForCSS];

    NSError *xpathError = nil;
    NSArray *placeholderNodes = [xmlDoc nodesForXPath:placeholderXPath error:&xpathError];
    NSAssert(placeholderNodes != nil, @"XPath error: %@", xpathError);

    if(placeholderNodes.count == 0) return NO;

    NSXMLElement *placeholderNode = placeholderNodes[0];
    NSAssert(placeholderNode.childCount == 1 && placeholderNode.children[0].kind == NSXMLTextKind, @"Placeholder node should have exactly one child, and it should be text.");

    NSString *escapedCSS = [NSString stringWithFormat:@"/*<![CDATA[*/ %@ /*]]>*/", css];

    NSMutableString *nodeContent = [placeholderNode.stringValue mutableCopy];
    // Only replacing the first match. Seems safe.
    NSRange replacementRange = [nodeContent rangeOfString:DSXSLArgumentsPlaceholderForCSS];
    [nodeContent replaceCharactersInRange:replacementRange withString:css];

    NSXMLNode *newTextNode = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeNeverEscapeContents | NSXMLNodePreserveAll];
    newTextNode.stringValue = escapedCSS;

    [placeholderNode setChildren:@[ newTextNode ]];

    return YES;
}

-(void)setString:(NSString *)value forKey:(NSString *)key escape:(BOOL)escape
{
    self[key] = escape ? [DSXSLArguments XSLParameterStringForString:value] : value;
}

-(void)setURL:(NSURL *)url forKey:(NSString *)key escape:(BOOL)escape
{
    self[key] = escape ? [DSXSLArguments XSLParameterStringForURL:url] : url.absoluteString;
}

// The XSLs here consider '1' and only '1' to be true
-(void)setBool:(BOOL)val forKey:(NSString *)key
{
    self[key] = val ? @"'1'" : @"''";
}

-(BOOL)boolForKey:(NSString *)key
{
    return [self[key] isEqualToString:@"'1'"];
}

-(BOOL)isParentalControlEnabled
{
    return [self boolForKey:DSXSLArgumentKeyParentalControl];
}

-(void)setParentalControlEnabled:(BOOL)parentalControlEnabled
{
    [self setBool:parentalControlEnabled forKey:DSXSLArgumentKeyParentalControl];
}

-(NSString *)ariaLabel
{
    return self[DSXSLArgumentKeyAriaLabel];
}

-(void)setAriaLabel:(NSString *)ariaLabel
{
    [self setString:ariaLabel forKey:DSXSLArgumentKeyAriaLabel escape:YES];
}

-(NSURL *)baseURL
{
    NSString *urlString = self[DSXSLArgumentKeyBaseURL];
    if(!urlString) return nil;
    return [NSURL URLWithString:urlString];
}

-(void)setBaseURL:(NSURL *)baseURL
{
    [self setURL:baseURL forKey:DSXSLArgumentKeyBaseURL escape:YES];
}

-(NSString *)rtlDirection
{
    return self[DSXSLArgumentKeyRTLDirection];
}

-(void)setRtlDirection:(NSString *)rtlDirection
{
    [self setString:rtlDirection forKey:DSXSLArgumentKeyRTLDirection escape:YES];
}

-(NSString *)stylesheetContent
{
    return self[DSXSLArgumentKeyStylesheetContent];
}

-(void)setStylesheetContent:(NSString *)stylesheetContent
{
    [self setString:stylesheetContent forKey:DSXSLArgumentKeyStylesheetContent escape:YES];
}

-(void)setStylesheetContentPlaceholder
{
    self.stylesheetContent = DSXSLArgumentsPlaceholderForCSS;
}

-(id)mutableCopyWithZone:(NSZone *)zone
{
    NSMutableDictionary *newDict = [_rawDictionary mutableCopyWithZone:zone];
    return [[[self class] alloc] initWithDictionaryNoCopy:newDict];
}

@end

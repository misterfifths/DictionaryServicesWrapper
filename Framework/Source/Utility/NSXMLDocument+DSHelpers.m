// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "NSXMLDocument+DSHelpers.h"
#import "DSDictionaryXSLArguments.h"


@implementation NSXMLDocument (DSHelpers)

-(NSXMLDocument *)ds_XMLDocumentByApplyingXSL:(NSXMLDocument *)xslDoc
                                    arguments:(DSDictionaryXSLArguments *)xslArguments
{
    // TODO: if speed is unacceptable, switching to libxml2 here is the first logical step.
    // Just caching the pre-compiled XSLs would be a *huge* improvement.

    NSError *xformError = nil;
    NSXMLDocument *transformedDoc = [self objectByApplyingXSLT:xslDoc.XMLData
                                                     arguments:xslArguments.rawDictionary
                                                         error:&xformError];

    NSAssert(transformedDoc, @"Error applying XSL: %@", xformError);

    NSAssert([transformedDoc isKindOfClass:[NSXMLDocument class]], @"XSL returned an instance of %@; expected an NSXMLDocument", transformedDoc.class);

    [transformedDoc setDocumentContentKind:NSXMLDocumentXMLKind];

    return transformedDoc;
}

-(NSXMLDocument *)ds_XMLDocumentByApplyingXSLs:(NSArray *)xslDocs
                                     arguments:(DSDictionaryXSLArguments *)xslArguments
{
    NSXMLDocument *res = self;
    for(NSXMLDocument *xslDoc in xslDocs) {
        res = [res ds_XMLDocumentByApplyingXSL:xslDoc arguments:xslArguments];
    }

    return res;
}

-(BOOL)ds_replaceCSSPlaceholderWithContent:(NSString *)css
{
    // Seems like a safe assumption it's in a <style>, yah?
    NSString *placeholderXPath = [NSString stringWithFormat:@"//style[contains(text(), '%@')]", DSDictionaryXSLStyleSheetContentPlaceholder];

    NSError *xpathError = nil;
    NSArray *placeholderNodes = [self nodesForXPath:placeholderXPath error:&xpathError];
    NSAssert(placeholderNodes != nil, @"XPath error: %@", xpathError);

    if(placeholderNodes.count == 0) return NO;

    NSXMLElement *placeholderNode = placeholderNodes[0];
    NSAssert(placeholderNode.childCount == 1 && placeholderNode.children[0].kind == NSXMLTextKind, @"Placeholder node should have exactly one child, and it should be text.");

    NSString *escapedCSS = [NSString stringWithFormat:@"/*<![CDATA[*/ %@ /*]]>*/", css];

    NSMutableString *nodeContent = [placeholderNode.stringValue mutableCopy];
    // Only replacing the first match. Seems safe.
    NSRange replacementRange = [nodeContent rangeOfString:DSDictionaryXSLStyleSheetContentPlaceholder];
    [nodeContent replaceCharactersInRange:replacementRange withString:css];

    NSXMLNode *newTextNode = [[NSXMLNode alloc] initWithKind:NSXMLTextKind options:NSXMLNodeNeverEscapeContents | NSXMLNodePreserveAll];
    newTextNode.stringValue = escapedCSS;

    [placeholderNode setChildren:@[ newTextNode ]];

    return YES;
}

-(NSString *)ds_canonicalXMLStringIncludingContentType:(BOOL)includeContentType
{
    // This makes it spit out the processing directive & actually collapse empty tags
    self.documentContentKind = NSXMLDocumentXMLKind;

    self.version = @"1.0";
    self.characterEncoding = @"UTF-8";
    self.standalone = YES;

    // NSXMLDocumentIncludeContentTypeDeclaration does nothing unless our kind == XHTML or HTML
    // But if we're XHTML, it forces the output of a default xmlns, which we don't want.
    // This is just sisyphean
    if(includeContentType) {
        NSXMLElement *head = [self.rootElement elementsForName:@"head"].firstObject;
        NSAssert(head != nil, @"No <head> in document?");

        NSXMLElement *contentTypeElement = [[NSXMLElement alloc] initWithXMLString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"/>" error:NULL];
        [head insertChild:contentTypeElement atIndex:0];
    }

    NSString *xmlString = [self XMLStringWithOptions:NSXMLNodeCompactEmptyElement];
    return [xmlString stringByAppendingString:@"\n"];  // just wanted -isEqualToString: to return YES, goddammit
}

-(BOOL)ds_isEffectivelyEqualToXMLDocument:(NSXMLDocument *)other
{
    NSString *ourCanon = [self canonicalXMLStringPreservingComments:YES];
    NSString *theirCanon = [other canonicalXMLStringPreservingComments:YES];

    return [ourCanon isEqualToString:theirCanon];
}

-(NSString *)ds_sanitizedText
{
    // Translation of private method ExtractSanitizedText
    /*
     It's a strange creature. Does this:
     - The first instance of the substring "#BR#" is deleted, but sets the internal flag as if it started a new line (i.e., it starts ignoring whitespace)
     - Subsequent instances of "#BR#" are actually turned into \n
     - Any number of tabs, newlines, or spaces at the beginning of a line are ignored
     - Tabs are actually always ignored lol
     - Multiple spaces in a row are collapsed to one space
     */

    NSString *rawText = self.rootElement.stringValue;

    if(rawText.length == 0) return @"";


    const NSUInteger utf8Length = [rawText lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    const char *utf8Bytes = rawText.UTF8String;

    char *resBytes = calloc(utf8Length + 1, sizeof(char));
    NSUInteger resLength = 0;

    BOOL sawFirstBR = NO;
    BOOL atLineStart = YES;

    for(NSUInteger i = 0; i < utf8Length; i++) {
        const char c = utf8Bytes[i];
        const char nextC = utf8Bytes[i + 1];  // will give us the \0 at the end of string, which is fine

        if(i < utf8Length - 5 &&
           c == '#' &&
           nextC == 'B' &&
           utf8Bytes[i + 2] == 'R' &&
           utf8Bytes[i + 3] == '#')
        {
            // Skip past these guys in the input
            i += 3;

            // This makes little sense, but is what the framework does...
            atLineStart = YES;

            if(sawFirstBR) {
                resBytes[resLength++] = '\n';
            }

            sawFirstBR = YES;

            continue;
        }

        if(atLineStart) {
            if(c == '\t' || c == '\n' || c == ' ') continue;
        }
        else {
            if(c == '\t' || (c == ' ' && nextC == ' ')) continue;
        }

        resBytes[resLength++] = c;
        atLineStart = c == '\n';
    }

    NSString *res = [[NSString alloc] initWithBytesNoCopy:resBytes length:resLength encoding:NSUTF8StringEncoding freeWhenDone:YES];
    NSAssert(res != nil, @"Error reconstituting sanitized string");

    return res;
}

-(NSArray<NSString *> *)ds_nonEmptyTrimmedStringValuesForXPath:(NSString *)xpath
{
    // TODO: as with the XSL stuff, switching to libxml2 here would be a massive speed improvement.
    // Caching pre-compiled XPaths per-dictionary would be a *huge* improvement.

    NSError *xpathError = nil;
    NSArray *xpathResult = [self nodesForXPath:xpath error:&xpathError];
    NSAssert(xpathResult != nil, @"Error executing XPath: %@", xpathError);

    if(xpathResult.count == 0) return @[];

    NSMutableArray *res = [NSMutableArray arrayWithCapacity:xpathResult.count];
    for(NSXMLNode *xpathNode in xpathResult) {
        NSMutableString *stringValue = [xpathNode.stringValue mutableCopy];
        if(stringValue.length == 0) continue;

        // Calling this for parity with the framework; would call -stringByTrimmingCharactersInSet: in a sane world
        CFStringTrimWhitespace((__bridge CFMutableStringRef)stringValue);
        if(stringValue.length == 0) continue;

        [res addObject:stringValue];
    }

    return res;
}

@end

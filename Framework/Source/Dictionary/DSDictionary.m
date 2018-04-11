// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSDictionary.h"
#import "FrameworkInternals.h"
#import "DSRecordPrivate.h"
#import "NSLocale+DSHelpers.h"
#import "NSString+DSHelpers.h"
#import "DSXSLArguments.h"


@interface DSDictionary ()

@property (nonatomic) DCSDictionaryRef dictRef;

@property (nonatomic, readonly, copy) NSDictionary<NSString *, id> *infoDictionary;

@property (nonatomic, readonly, strong) NSBundle *bundle;

@property (nonatomic, readonly, strong) NSMutableDictionary<NSString *, DSIndex *> *cachedIndexesByName;

@end


@implementation DSDictionary

@synthesize infoDictionary=_infoDictionary;
@synthesize textElementXPaths=_textElementXPaths;
@synthesize bundle=_bundle;
@synthesize xslDocument=_xslDocument;
@synthesize defaultXSLArguments=_defaultXSLArguments;
@synthesize primaryLocale=_primaryLocale;
@synthesize contentLanguages=_contentLanguages;

+(NSArray *)dictionaryObjectsFromRefs:(NSArray *)dictRefs
{
    NSMutableArray<DSDictionary *> *dictObjs = [NSMutableArray arrayWithCapacity:dictRefs.count];

    for(id dictRefObj in dictRefs) {
        DCSDictionaryRef dictRef = (__bridge DCSDictionaryRef)dictRefObj;
        [dictObjs addObject:[[self alloc] initWithDictRef:dictRef]];
    }

    return dictObjs;
}

+(NSArray *)availableDictionaries
{
    NSArray *dictRefs = DCSCopyAvailableDictionaries();
    return [self dictionaryObjectsFromRefs:dictRefs];
}

+(NSArray *)activeDictionaries
{
    NSArray *dictRefs = DCSGetActiveDictionaries();
    return [self dictionaryObjectsFromRefs:dictRefs];
}

+(DSDictionary *)defaultDictionary
{
    static DSDictionary *_dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DCSDictionaryRef dictRef = DCSGetDefaultDictionary();
        if(dictRef) _dict = [[self alloc] initWithDictRef:dictRef];
    });

    return _dict;
}

+(DSDictionary *)defaultThesaurus
{
    static DSDictionary *_dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DCSDictionaryRef dictRef = DCSGetDefaultThesaurus();
        if(dictRef) _dict = [[self alloc] initWithDictRef:dictRef];
    });

    return _dict;
}

// Retains the dictionary!
// If that's undesirable (e.g., you created it to pass it to this method),
// the caller should release it after making an instance.
// Public in FrameworkBridging.h
-(instancetype)initWithDictRef:(DCSDictionaryRef)dictRef
{
    if(!dictRef) return nil;

    self = [super init];
    if(self) {
        _dictRef = CFRetain(dictRef);

        _cachedIndexesByName = [NSMutableDictionary new];
    }

    return self;
}

-(instancetype)initWithIdentifier:(NSString *)identifier
{
    DCSDictionaryRef dictRef = DCSDictionaryCreateWithIdentifier(identifier);
    if(!dictRef) return nil;

    self = [self initWithDictRef:dictRef];
    CFRelease(dictRef);

    return self;
}

-(instancetype)initWithURL:(NSURL *)URL
{
    DCSDictionaryRef dictRef = DCSDictionaryCreate(URL);
    if(!dictRef) return nil;

    self = [self initWithDictRef:dictRef];
    CFRelease(dictRef);

    return self;
}

-(void)dealloc
{
    if(_dictRef) CFRelease(_dictRef);
}

-(NSString *)name
{
    return DCSDictionaryGetName(self.dictRef);
}

-(NSString *)shortName
{
    return DCSDictionaryGetShortName(self.dictRef);
}

-(NSString *)identifier
{
    return DCSDictionaryGetIdentifier(self.dictRef);
}

-(NSURL *)URL
{
    return DCSDictionaryGetURL(self.dictRef);
}

-(BOOL)isNetworkDictionary
{
    return DCSDictionaryIsNetworkService(self.dictRef);
}

-(NSArray *)contentLanguages
{
    if(!_contentLanguages) {
        NSArray *languageDicts = DCSDictionaryGetLanguages(self.dictRef);
        if(languageDicts.count == 0) {
            _contentLanguages = @[];
        }
        else {
            NSMutableArray *res = [NSMutableArray arrayWithCapacity:languageDicts.count];
            for(NSDictionary *languageDict in languageDicts) {
                [res addObject:[[DSContentLanguagePair alloc] initWithDictionary:languageDict]];
            }

            _contentLanguages = res;
        }
    }

    return _contentLanguages;
}

-(NSString *)primaryLanguage
{
    return DCSDictionaryGetPrimaryLanguage(self.dictRef);
}

-(NSLocale *)primaryLocale
{
    NSString *primaryLanguage = self.primaryLanguage;
    if(primaryLanguage && !_primaryLocale) {
        _primaryLocale = [NSLocale ds_localeFromLanguageID:primaryLanguage];
    }

    return _primaryLocale;
}

-(NSArray *)indexNames
{
    NSAssert(self.URL != nil, @"Don't ask for index info on a dictionary that isn't downloaded.");
    return IDXCopyIndexNames((NSURL * __nonnull)self.URL, NO);
}

-(NSBundle *)bundle
{
    if(!_bundle) {
        NSAssert(self.URL != nil, @"Don't ask for bundle info on a dictionary that isn't downloaded.");
        _bundle = [NSBundle bundleWithURL:(NSURL * __nonnull)self.URL];
    }

    return _bundle;
}

-(NSDictionary *)infoDictionary
{
    if(!_infoDictionary) {
        _infoDictionary = [self.bundle infoDictionary];
    }

    return _infoDictionary;
}

-(NSArray *)styleSheetURLs
{
    // Merges contents of DCSDictionaryStyleSheets (array of filenames) & DCSDictionaryCSS (single filename)

    NSMutableArray *filenames = [self.infoDictionary[@"DCSDictionaryStyleSheets"] mutableCopy] ?: [NSMutableArray new];
    NSString *singleCSSFilename = self.infoDictionary[@"DCSDictionaryCSS"];
    if(singleCSSFilename) [filenames addObject:singleCSSFilename];

    if(filenames.count == 0) return filenames;

    NSMutableArray *res = [NSMutableArray arrayWithCapacity:filenames.count];
    for(NSString *filename in filenames) {
        NSURL *url = [self.bundle URLForResource:filename withExtension:nil];
        if(url) [res addObject:url];
    }

    return res;
}

-(NSString *)styleSheetContent
{
    NSArray *urls = self.styleSheetURLs;
    if(urls.count == 0) return @"";

    NSDictionary *encodingOptions = @{ NSStringEncodingDetectionAllowLossyKey: @(NO),
                                       NSStringEncodingDetectionLikelyLanguageKey: @"en",
                                       NSStringEncodingDetectionSuggestedEncodingsKey: @[ @(NSUTF8StringEncoding),
                                                                                          @(NSUTF16LittleEndianStringEncoding),
                                                                                          @(NSUTF16BigEndianStringEncoding),
                                                                                          @(NSUTF32LittleEndianStringEncoding),
                                                                                          @(NSUTF32BigEndianStringEncoding) ] };

    NSMutableString *res = [NSMutableString new];
    for(NSURL *url in urls) {
        // The CSS can apparently be encoded in any number of weird ways (BOM BOM BOM)
        NSData *data = [NSData dataWithContentsOfURL:url];
        if(!data || data.length == 0) continue;

        NSString *string = nil;
        NSStringEncoding encoding = [NSString stringEncodingForData:data
                                                    encodingOptions:encodingOptions
                                                    convertedString:&string
                                                usedLossyConversion:NULL];

        if(encoding == 0 || !string) {
            NSLog(@"Could not determine encoding of CSS file %@", url);
            continue;
        }

        [res appendString:string];
    }

    return res;
}

-(NSDictionary *)textElementXPaths
{
    if(!_textElementXPaths) {
        NSDictionary *xpaths = self.infoDictionary[@"DCSElementXPath"];
        NSMutableDictionary *res = [NSMutableDictionary dictionaryWithCapacity:xpaths.count];

        for(NSString *xpathKey in xpaths) {
            DSTextElementKey normalizedKey = DSTextElementKeyForOldName(xpathKey);
            res[normalizedKey] = xpaths[xpathKey];
        }

        if(!res[DSTextElementKeyRecordID]) {
            // This is what the framework does
            res[DSTextElementKeyRecordID] = @"//d:entry/@id";
        }

        if(!res[DSTextElementKeyTitle]) {
            // This is our invention
            res[DSTextElementKeyTitle] = @"//d:entry/@title";
        }

        if(!res[DSTextElementKeyHeadword]) {
            // Ours too, based on NOAD's syllabified headword
            res[DSTextElementKeyHeadword] = @"(//span[@class='hw'])[1]/text()";
        }

        _textElementXPaths = res;
    }

    return _textElementXPaths;
}

-(void)setOverrideXPath:(NSString *)xpath forTextElement:(DSTextElementKey)key
{
    NSMutableDictionary *xpaths = [self.textElementXPaths mutableCopy];
    xpaths[key] = xpath;
    
    _textElementXPaths = xpaths;
}

-(NSURL *)xslURL
{
    NSString *xslFilename = self.infoDictionary[@"DCSDictionaryXSL"];
    if(!xslFilename) return nil;

    return [[self.bundle resourceURL] URLByAppendingPathComponent:xslFilename];
}

-(NSXMLDocument *)xslDocument
{
    if(!_xslDocument) {
        if(!self.xslURL) return nil;

        NSError *error = nil;
        NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:(NSURL * __nonnull)self.xslURL
                                                                  options:NSXMLNodeOptionsNone
                                                                    error:&error];

        NSAssert(doc != nil, @"Error parsing dictionary XSL: %@", error);

        _xslDocument = doc;
    }

    return _xslDocument;
}

-(NSDictionary *)defaultPreferences
{
    return self.infoDictionary[@"DCSDictionaryDefaultPrefs"] ?: @{};
}

-(NSDictionary *)preferences
{
    return DCSDictionaryGetPreferences(self.dictRef) ?: self.defaultPreferences;
}

-(DSXSLArguments *)defaultXSLArguments
{
    if(!_defaultXSLArguments) {
        DSXSLArguments *args = [[DSXSLArguments alloc] initWithDictionary:self.preferences];

        args.ariaLabel = @"''";
        args.parentalControlEnabled = NO;
        args.rtlDirection = @"";
        args.stylesheetContent = @"";

        DSIndexInfo *keywordIdxInfo = [self infoForIndexNamed:DSIndexNameKeyword];
        if(keywordIdxInfo.path) {
            NSURL *keywordIdxURL = [self.bundle URLForResource:keywordIdxInfo.path withExtension:nil];

            if(keywordIdxURL) args.baseURL = keywordIdxURL;
            else [args setString:@"" forKey:DSXSLArgumentKeyBaseURL escape:YES];
        }

        _defaultXSLArguments = args;
    }

    return [_defaultXSLArguments mutableCopy];
}

-(DSIndexInfo *)infoForIndexNamed:(NSString *)indexName
{
    NSArray *indexList = self.infoDictionary[kIDXPropertyIndexList];

    for(NSDictionary<DSIndexInfoKey, id> *indexDict in indexList) {
        NSString *name = indexDict[DSIndexInfoKeyName];
        if([name isEqualToString:indexName]) {
            return [[DSIndexInfo alloc] initWithDictionary:indexDict];
        }
    }

    return nil;
}

-(DSIndex *)indexWithName:(NSString *)indexName
{
    @synchronized(self.cachedIndexesByName) {
        DSIndex *cachedIdx = self.cachedIndexesByName[indexName];
        if(!cachedIdx) {
            cachedIdx = [[DSIndex alloc] initWithName:indexName dictionary:self];
            if(cachedIdx) self.cachedIndexesByName[indexName] = cachedIdx;
        }

        return cachedIdx;
    }
}

-(DSIndex *)keywordIndex
{
    return [self indexWithName:DSIndexNameKeyword];
}

-(DSIndex *)bodyDataIndex
{
    return [self indexWithName:DSIndexNameBodyData];
}

-(DSIndex *)referenceIndex
{
    return [self indexWithName:DSIndexNameReference];
}

-(NSString *)stringByNormalizingSearchTerm:(NSString *)searchTerm
{
    return [searchTerm ds_normalizedStringForSearchInLocale:self.primaryLocale caseSensitive:NO];
}

-(BOOL)supportsDefinitionStyle:(DSDefinitionStyle)style
{
    // DS & DCS definition styles are the same. Questionable choice.
    return DCSDictionaryIsSupportedDefinitionStyle(self.dictRef, (DCSDefinitionStyle)style);
}

-(DSRecord *)firstRecordMatchingString:(NSString *)string method:(DSSearchMethod)searchMethod
{
    return [[self recordsMatchingString:string method:searchMethod maxResults:1] firstObject];
}

-(NSArray *)recordsMatchingString:(NSString *)string method:(DSSearchMethod)searchMethod
{
    return [self recordsMatchingString:string method:searchMethod maxResults:0];
}

-(NSArray *)recordsMatchingString:(NSString *)string method:(DSSearchMethod)searchMethod maxResults:(NSUInteger)maxResults
{
    // Probably overkill...
    NSAssert([[self infoForIndexNamed:DSIndexNameKeyword] supportsSearchMethod:searchMethod], @"Unsupported search method %@", searchMethod);


    DCSDictionarySearchMethod dcsSearchMethod = DSUIntegerForSearchMethod(searchMethod);
    NSArray *recordRefs = DCSCopyRecordsForSearchString(self.dictRef, string, dcsSearchMethod, maxResults);

    if(!recordRefs || recordRefs.count == 0) return @[];

    NSMutableArray *records = [NSMutableArray arrayWithCapacity:recordRefs.count];

    // Ownership here is a little confusing.
    // The records in the array are currently only owned by the recordRefs array.
    // retainCount = 1

    for(id recordRefObj in recordRefs) {
        // retainCount = 2 (strong ref in recordRefObj)

        DCSRecordRef recordRef = (__bridge DCSRecordRef)recordRefObj;
        // retainCount = 2 (just a __bridge; no change in ownership)

        DSRecord *record = [[DSConcreteRecord alloc] initWithRecordRef:recordRef dictionary:self];
        // retainCount = 3 (DSConcreteRecord retains it)

        [records addObject:record];
        // retainCount = 3
    }

    // retainCount = 2 at the end of the loop (recordRefObj goes away)

    return records;

    // and finally, retainCount goes to 1 when the recordRefs array goes away,
    // which is what we wanted - just one reference in the DSRecords in the records array
}

-(DSRecord *)recordForReference:(NSString *)referenceString
{
    // So there's the built-in DCSCopyRecordForReference, but it sucks.
    // Returns a record with the referenceString for headword/keyword/etc.
    // Going the long route...

//    DCSRecordRef recordRef = DCSCopyRecordForReference(self.dictRef, referenceString);
//    if(!recordRef) return nil;
//
//    DSRecord *record = [[DSConcreteRecord alloc] initWithRecordRef:recordRef dictionary:self];
//    CFRelease(recordRef);

    DSIndex *refIdx = self.referenceIndex;
    __block DSBodyDataID bodyDataID = 0;
    [refIdx enumerateMatchesForString:referenceString method:DSSearchMethodExactMatch usingBlock:^(DSIndexEntry *entry, BOOL *stop) {
        bodyDataID = entry.externalBodyID;
        *stop = YES;
    }];

    if(bodyDataID == 0) return nil;

    return [[DSSyntheticRecord alloc] initWithDictionary:self bodyDataID:bodyDataID];
}

-(DSRecord *)recordFromEntry:(DSIndexEntry *)entry
{
    return [[DSSyntheticRecord alloc] initWithDictionary:self indexEntry:entry];
}

-(DSRecord *)recordFromEntry:(DSIndexEntry *)entry bodyData:(NSString *)bodyData
{
    return [[DSSyntheticRecord alloc] initWithDictionary:self
                                              indexEntry:entry
                                         recordXMLString:bodyData];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p: %@, %@>", self.class, (void *)self, self.identifier, self.name];
}

@end

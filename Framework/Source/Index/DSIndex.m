// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSIndex.h"
#import "FrameworkInternals.h"
#import "DSDictionary.h"


// These are the defaults used in the higher-level DCS stuff:
static const size_t DSIndexSearchDataBufferDefaultLength = 0x20000;
static const size_t DSIndexSearchDefaultRecordBatchLimit = 1000;


@interface DSIndex () {
    void *_searchDataBuffer;
    void **_searchDataFieldPointers;
    size_t *_searchDataFieldLengths;
}

@property (nonatomic) IDXIndexRef indexRef;

@property (nonatomic, readwrite, weak) DSDictionary *dictionary;

@property (nonatomic, readwrite, strong) DSIndexInfo *info;

@end


@implementation DSIndex

// Public
-(instancetype)initWithName:(DSIndexName)indexName dictionary:(DSDictionary *)dictionary
{
    NSAssert(dictionary.URL != nil, @"Don't ask for index info on a dictionary that isn't downloaded.");

    DSIndexInfo *info = [dictionary infoForIndexNamed:indexName];
    NSAssert(info != nil, @"Unknown index name '%@'", indexName);

    IDXIndexRef indexRef = IDXCreateIndexObject(NULL, (NSURL * __nonnull)dictionary.URL, indexName);
    NSAssert(indexRef != nil, @"Couldn't make instance of index %@", indexName);

    self = [self initWithIndexRef:indexRef
                             name:indexName
                       dictionary:dictionary
                       infoNoCopy:info];

    CFRelease(indexRef);

    return self;
}

// Public in FrameworkBridging.h
-(instancetype)initWithIndexRef:(IDXIndexRef)indexRef
                           name:(DSIndexName)indexName
                     dictionary:(DSDictionary *)dictionary
{
    DSIndexInfo *info = [dictionary infoForIndexNamed:indexName];
    NSAssert(info != nil, @"Unknown index name '%@'", indexName);

    self = [self initWithIndexRef:indexRef
                             name:indexName
                       dictionary:dictionary
                       infoNoCopy:info];

    return self;
}

// Private; designated
// Retains the index!
// If that's undesirable (e.g., you created it to pass it to this method),
// the caller should release it after making an instance.
-(instancetype)initWithIndexRef:(IDXIndexRef)indexRef
                           name:(DSIndexName)indexName
                     dictionary:(DSDictionary *)dictionary
                     infoNoCopy:(DSIndexInfo *)info
{
    self = [super init];
    if(self) {
        _indexRef = CFRetain(indexRef);
        _name = [indexName copy];
        _dictionary = dictionary;
        _info = info;

        if(_info.isBigEndian) {
            // TODO: endianness. Not sure where this would rear its head, exactly.
            // Definitely in some of the index field -decodeValueFromBytes methods.

            NSLog(@"Index %@ is big endian! This is gonna get weird.", indexName);
        }

        if(IDXSupportsDataPtr(_indexRef)) {
            NSLog(@"Index %@ supports data pointers; this may get weird.", self.name);
        }
    }

    return self;
}

-(void)dealloc
{
    if(_indexRef) CFRelease(_indexRef);
    if(_searchDataBuffer) free(_searchDataBuffer);
    if(_searchDataFieldLengths) free(_searchDataFieldLengths);
    if(_searchDataFieldPointers) free(_searchDataFieldPointers);
}

-(NSArray *)fields
{
    return self.info.fields;
}

-(BOOL)supportsFindByID
{
    return self.info.supportsFindByID;
}

-(NSArray *)supportedSearchMethods
{
    return self.info.supportedSearchMethods;
}

-(BOOL)supportsSearchMethod:(DSSearchMethod)searchMethod
{
    return [self.info supportsSearchMethod:searchMethod];
}

-(void)ensureBuffers
{
    @synchronized(self) {
        if(_searchDataBuffer != NULL) return;

        _searchDataBuffer = calloc(1, DSIndexSearchDataBufferDefaultLength);

        NSUInteger fieldCount = self.fields.count;
        _searchDataFieldPointers = calloc(sizeof(void *), fieldCount);
        _searchDataFieldLengths = calloc(sizeof(size_t), fieldCount);
    }
}

-(DSIndexEntry *)firstMatchForString:(NSString *)string method:(DSSearchMethod)searchMethod
{
    // TODO: this is grossly naive.

    __block DSIndexEntry *res = nil;

    [self enumerateMatchesForString:string method:searchMethod usingBlock:^(DSIndexEntry *entry, BOOL *stop) {
        res = entry;
        *stop = YES;
    }];

    return res;
}

-(NSArray *)matchesForString:(NSString *)string method:(DSSearchMethod)searchMethod maxResults:(NSUInteger)maxResults
{
    // TODO: this is grossly naive.

    NSMutableArray *matches = [[NSMutableArray alloc] initWithCapacity:maxResults];

    [self enumerateMatchesForString:string method:searchMethod usingBlock:^(DSIndexEntry *entry, BOOL *stop) {
        [matches addObject:entry];

        if(matches.count == maxResults) *stop = YES;
    }];

    return matches;
}

-(void)enumerateMatchesForString:(NSString *)string
                          method:(DSSearchMethod)searchMethod
                      usingBlock:(void (^)(DSIndexEntry *, BOOL *))block
{
    NSString *normalizedSearchString = [self.dictionary stringByNormalizingSearchTerm:string];

    [self enumerateMatchesForNormalizedString:normalizedSearchString
                                       method:searchMethod
                                   usingBlock:block];
}

-(void)enumerateMatchesForNormalizedString:(NSString *)string
                                    method:(DSSearchMethod)searchMethod
                                usingBlock:(void (^)(DSIndexEntry *, BOOL *))block
{
    NSAssert([self.supportedSearchMethods containsObject:searchMethod], @"Index %@ does not support search method %@", self.name, searchMethod);

    NSArray *fieldNames = [self.fields valueForKey:@"name"];
    IDXSetRequestFields(self.indexRef, fieldNames);

    Boolean setSearchStringRes = IDXSetSearchString(self.indexRef, string, searchMethod);
    (void)setSearchStringRes;  // in release, analyzer doesn't like that this looks unused

    // Haven't really investigated why this would happen; assume it's just bad search method?
    NSAssert(setSearchStringRes, @"Could not set search string on index %@", self);


    [self ensureBuffers];


    CFRange *outRanges = NULL;
    uint32_t recordCount;
    BOOL stop = NO;

    do {
        recordCount = IDXGetMatchData(self.indexRef,
                                      DSIndexSearchDefaultRecordBatchLimit,
                                      DSIndexSearchDataBufferDefaultLength,
                                      _searchDataBuffer,
                                      &outRanges,
                                      NULL);

        for(NSUInteger i = 0; i < recordCount; i++) {
            CFRange recordRange = outRanges[i];
            void *recordDataStart = (char *)_searchDataBuffer + recordRange.location;
            int64_t res = IDXGetFieldDataPtrs(self.indexRef,
                                              recordDataStart,
                                              recordRange.length,
                                              _searchDataFieldPointers,
                                              _searchDataFieldLengths);

            (void)res;  // Can it, analyzer

            // TODO: on reference idx, IDXGetFieldDataPtrs returns 8.
            // In disasm for keyword idx & body idx, anything > 0 is an error
            // Ultimately, no idea what is or is not an error.
//            if(res > 0) NSLog(@"IDXGetFieldDataPtrs returned %lld, which may or may not be an error?", res);

            DSIndexEntry *entry = [self entryWithFieldDataPointers:_searchDataFieldPointers lengths:_searchDataFieldLengths];

            block(entry, &stop);

            if(stop) return;
        }
    } while(recordCount > 0);
}

-(DSIndexEntry *)entryWithFieldDataPointers:(void **)fieldPointers lengths:(size_t *)fieldLengths
{
    // There doesn't seem to be a to double check that we're getting the right number of pointers,
    // unless that's somehow what the return of IDXGetFieldDataPtrs is telling us.
    // So... full steam ahead, with the assumption that we got one per field!

    DSIndexEntry *entry = [DSIndexEntry new];

    for(NSUInteger i = 0; i < self.fields.count; i++) {
        DSIndexField *field = self.fields[i];

        void *fieldBytes = fieldPointers[i];
        size_t fieldLength = fieldLengths[i];

        if(fieldLength == 0) {
            // Not sure if this is kosher, but seems legit to me:
            // no data means no value
            continue;
        }

        id fieldValue = [field decodeValueFromBytes:fieldBytes length:fieldLength];
        NSAssert(fieldValue, @"Decode of field %@ return nil!", field.name);

        entry[field.name] = fieldValue;
    }

    return entry;
}

-(NSString *)dataForRecordID:(DSBodyDataID)recordID
{
    NSAssert(self.supportsFindByID, @"Index %@ does not support find by ID", self.name);


    /*
     v8 = IDXGetDataPtrByID(this->field_F0, *(_QWORD *)&a2->gap50[128], &buffer);
     v9 = CFDataCreateWithBytesNoCopy(0LL, v8, buffer, kCFAllocatorNull);
     // and then into a string (hardcoded UTF8)
     */

    // well... you would think, perhaps, that IDXGetDataByID would return the same sort of stuff
    // you get from a search... fields packed together as specified in the info dictionary.
    // you'd be wrong... at least in the case of the BodyData index, it's just straight up characters,
    // no header or anything. womp womp.

    // The framework hardcodes UTF8 as the encoding for the data. So be it.

    NSArray *fieldNames = [self.fields valueForKey:@"name"];
    IDXSetRequestFields(self.indexRef, fieldNames);

    if(IDXSupportsDataPtr(self.indexRef)) {
        void *internalBuffer = NULL;

        size_t dataLength = IDXGetDataPtrByID(self.indexRef, recordID, &internalBuffer);
        if(dataLength == 0 || internalBuffer == NULL) return nil;  // I assume that means "no such record"

        return [[NSString alloc] initWithBytes:internalBuffer length:dataLength encoding:NSUTF8StringEncoding];
    }

    size_t neededSize = IDXGetDataByID(self.indexRef, recordID, 0, NULL);
    if(neededSize == 0) return nil;  // I assume that means "no such record"

    void *buffer = malloc(neededSize);
    size_t bytesWritten = IDXGetDataByID(self.indexRef, recordID, neededSize, buffer);

    NSAssert(bytesWritten == neededSize, @"Expected a write of %zu bytes, but instead got %zu", neededSize, bytesWritten);

    return [[NSString alloc] initWithBytesNoCopy:buffer length:bytesWritten encoding:NSUTF8StringEncoding freeWhenDone:YES];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p: %@ in %@ (%lu fields)>", self.class, (void *)self, self.name, self.dictionary.identifier, self.fields.count];
}

@end

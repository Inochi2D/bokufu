module bokufu.token;

import std.sumtype;
import numem.all : nstring;

@nogc nothrow:

/**
    The type of a token

    NOTE: Some tokens have no data associated with them.
    Check hasData() of the Token type to know.
*/
enum TokenType {
    identToken,
    functionToken,
    atKeywordToken,
    hashToken,
    stringToken,
    badStringToken,
    urlToken,
    badUrlToken,
    delimToken,
    numberToken,
    percentageToken,
    dimensionToken,
    whitespaceToken,
    colonToken,
    semicolonToken,
    commaToken,
    openSquareToken,
    closeSquareToken,
    openParenToken,
    closeParenToken,
    openCurlyToken,
    closeCurlyToken,
}


union TokenData {
    struct IdentTokenData {
        nstring value;
    }

    struct FunctionTokenData {
        nstring value;
    }

    struct AtKeywordTokenData {
        nstring value;
    }

    struct HashTokenData {
        nstring value;
        bool isId;
    }

    struct StringTokenData {
        nstring value;
    }

    struct UrlTokenData {
        nstring value;
    }
    
    struct DelimTokenData {
        char value;
    }

    struct NumberTokenData {
        float num;
        bool hadSign;
        bool isInteger;
    }

    struct PercentageTokenData {
        float num;
        bool hadSign;
    }

    struct DimensionTokenData {
        float num;
        bool hadSign;
        bool isInteger;
        nstring unit;
    }

    IdentTokenData ident_;
    FunctionTokenData func_;
    AtKeywordTokenData at_;
    HashTokenData hash_;
    StringTokenData string_;
    UrlTokenData url_;
    DelimTokenData delim_;
    NumberTokenData number_;
    PercentageTokenData percentage_;
    DimensionTokenData dimension_;
}

struct Token {
private:
    TokenType type;
    TokenData* data;

public:

    /**
        Destructor
    */
    ~this() {
        if (data) {
            nogc_delete(data);
        }
    }

    /**
        Constructor
    */
    this(IdentTokenData ident_) {
        this.type = TokenType.identToken;
        this.data = nogc_new!TokenData;
        this.data.ident_ = ident_;
    }

    /**
        Constructor
    */
    this(FunctionTokenData func_) {
        this.type = TokenType.functionToken;
        this.data = nogc_new!TokenData;
        this.data.func_ = func_;
    }

    /**
        Constructor
    */
    this(AtKeywordTokenData at_) {
        this.type = TokenType.atKeywordToken;
        this.data = nogc_new!TokenData;
        this.data.at_ = at_;
    }

    /**
        Constructor
    */
    this(HashTokenData hash_) {
        this.type = TokenType.hashToken;
        this.data = nogc_new!TokenData;
        this.data.hash_ = hash_;
    }

    /**
        Constructor
    */
    this(StringTokenData string_) {
        this.type = TokenType.stringToken;
        this.data = nogc_new!TokenData;
        this.data.string_ = string_;
    }

    /**
        Constructor
    */
    this(UrlTokenData url_) {
        this.type = TokenType.urlToken;
        this.data = nogc_new!TokenData;
        this.data.url_ = url_;
    }

    /**
        Constructor
    */
    this(DelimTokenData delim_) {
        this.type = TokenType.delimToken;
        this.data = nogc_new!TokenData;
        this.data.delim_ = delim_;
    }

    /**
        Constructor
    */
    this(NumberTokenData number_) {
        this.type = TokenType.numberToken;
        this.data = nogc_new!TokenData;
        this.data.number_ = number_;
    }

    /**
        Constructor
    */
    this(PercentageTokenData percentage_) {
        this.type = TokenType.percentageToken;
        this.data = nogc_new!TokenData;
        this.data.percentage_ = percentage_;
    }

    /**
        Constructor
    */
    this(DimensionTokenData dimension_) {
        this.type = TokenType.dimensionToken;
        this.data = nogc_new!TokenData;
        this.data.dimension_ = dimension_;
    }

    /**
        Constructor
    */
    this(TokenType type) {
        this.type = type;
        this.data = null;
    }

    /**
        Constructor
    */
    this(TokenType type, TokenData* data) {
        this.type = type;
        this.data = data;
    }

    /**
        Whether the token has data associated with it.
    */
    bool hasData() {
        return data;
    }

    /**
        Gets the type of the token
    */
    TokenType getType() {
        return type;
    }

    /**
        Gets the token data associated with this token
    */
    TokenData* getData() {
        return data;
    }
}
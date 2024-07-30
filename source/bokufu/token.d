module bokufu.token;

import numem.all : nstring;

@nogc nothrow:

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

union TokenData {
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
@nogc nothrow:
    TokenType type;
    TokenData data;

    this(ref return scope inout(Token) src) inout
    {
        this.type = src.type;
        if (src.type == TokenType.identToken) {
            this.data.ident_ = src.data.ident_;
        } else if (src.type == TokenType.functionToken) {
            this.data.func_ = src.data.func_;
        } else if (src.type == TokenType.atKeywordToken) {
            this.data.at_ = src.data.at_;
        } else if (src.type == TokenType.hashToken) {
            this.data.hash_ = src.data.hash_;
        } else if (src.type == TokenType.urlToken) {
            this.data.url_ = src.data.url_;
        } else if (src.type == TokenType.delimToken) {
            this.data.delim_ = src.data.delim_;
        } else if (src.type == TokenType.numberToken) {
            this.data.number_ = src.data.number_;
        } else if (src.type == TokenType.percentageToken) {
            this.data.percentage_ = src.data.percentage_;
        } else if (src.type == TokenType.dimensionToken) {
            this.data.dimension_ = src.data.dimension_;
        }
    }

    this(TokenType type) {
        this.type = type;
    }

    this(IdentTokenData ident_) {
        this.type = TokenType.identToken;
        this.data.ident_ = ident_;
    }

    this(FunctionTokenData func_) {
        this.type = TokenType.functionToken;
        this.data.func_ = func_;
    }

    this(AtKeywordTokenData at_) {
        this.type = TokenType.atKeywordToken;
        this.data.at_ = at_;
    }

    this(HashTokenData hash_) {
        this.type = TokenType.hashToken;
        this.data.hash_ = hash_;
    }

    this(StringTokenData string_) {
        this.type = TokenType.stringToken;
        this.data.string_ = string_;
    }

    this(UrlTokenData url_) {
        this.type = TokenType.urlToken;
        this.data.url_ = url_;
    }

    this(DelimTokenData delim_) {
        this.type = TokenType.delimToken;
        this.data.delim_ = delim_;
    }

    this(NumberTokenData number_) {
        this.type = TokenType.numberToken;
        this.data.number_ = number_;
    }

    this(PercentageTokenData percentage_) {
        this.type = TokenType.percentageToken;
        this.data.percentage_ = percentage_;
    }

    this(DimensionTokenData dimension_) {
        this.type = TokenType.dimensionToken;
        this.data.dimension_ = dimension_;
    }
}

module bokufu.token;

import std.sumtype;
import numem.all : nstring;

@nogc nothrow:
struct IdentToken {
    nstring value;
}
struct FunctionToken {
    nstring value;
}
struct AtKeywordToken {
    nstring value;
}
struct HashToken {
    nstring value;
    bool isId;
}
struct StringToken {
    nstring value;
}
struct BadStringToken {}
struct UrlToken {
    nstring value;
}
struct BadUrlToken {}
struct DelimToken {
    char value;
}
struct NumberToken {
    float num;
    bool hadSign;
    bool isInteger;
}
struct PercentageToken {
    float num;
    bool hadSign;
}
struct DimensionToken {
    float num;
    bool hadSign;
    bool isInteger;
    nstring unit;
}
struct WhitespaceToken {}
struct ColonToken {}
struct SemicolonToken {}
struct CommaToken {}
struct OpenSquareToken {}
struct CloseSquareToken {}
struct OpenParenToken {}
struct CloseParenToken {}
struct OpenCurlyToken {}
struct CloseCurlyToken {}

alias Token = SumType!(
    IdentToken,
    FunctionToken,
    AtKeywordToken,
    HashToken,
    StringToken,
    BadStringToken,
    UrlToken,
    BadUrlToken,
    DelimToken,
    NumberToken,
    PercentageToken,
    DimensionToken,
    WhitespaceToken,
    ColonToken,
    SemicolonToken,
    CommaToken,
    OpenSquareToken,
    CloseSquareToken,
    OpenParenToken,
    CloseParenToken,
    OpenCurlyToken,
    CloseCurlyToken,
);

module bokufu.tokenizer;

import bokufu.token;

import object : hashOf;
import std.stdio;
import std.ascii : isAlpha, isDigit, isHexDigit, toLower;
import std.math : pow;
import std.algorithm : move;
import std.sumtype;

import numem.all : nogc_new;
import numem.all : nstring;

import std.traits : isArray, isSomeString;

nothrow @nogc:

bool asciiCaseInsensitiveEq(const(char)[] test, const(char)[] equal) {
	if (test.length != equal.length) {
		return false;
	}

	for (int i = 0; i < test.length; i++) {
		if (toLower(test[i]) != toLower(equal[i])) {
			return false;
		}
	}

	return true;
}

class CssParseException : Exception {
@nogc nothrow:
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

bool isCssNewlineStarter(char c) {
	return c == '\r' || c == '\n' || c == '\f';
}

bool isCssIdentStart(char c) {
	return c.isAlpha(); // TODO
}

bool isCssIdent(char c) {
	return isCssIdentStart(c) || c.isDigit() || c == '-';
}

bool isCssWhiteSpace(char c) {
	return isCssNewlineStarter(c) || c == '\t' || c == ' ';
}

struct CssNumber {
	bool hadSign;
	bool isInteger;
	double value;

	bool opEquals()(auto ref const CssNumber other) const @safe pure nothrow {
		return this.hadSign == other.hadSign
			&& this.isInteger == other.isInteger
			&& this.value == other.value;
	}

	size_t toHash() const @safe pure nothrow {
		size_t hash = hashOf(this.hadSign);
		hash = hash * 31 + hashOf(this.isInteger);
		hash = hash * 31 + hashOf(this.value);
		return hash;
	}
}

// 'current input code point' is `peek()` or `peek(0)`
// `next input code point` is `peek(1)`
// but must be guarded with `hasMore()` or `hasMore(1)`
// as the spec sidesteps this with `EOF code point`s
//
// We also do not do code point preprocessing for NUL
// or different newlines, so we have to handle them explictly.
//
// This also currently ignores HTML remanants like CDO CDC tokens.
struct Tokenizer
{
package(bokufu.tokenizer) @nogc:
	const(char)[] source;
	// Note: this parser starts with nothing in the buffer
	// and `advance()` must be called before doing anything
	size_t position = -1;
	// Position to skip to if `peekToken()` has been called
	// and then `skipToken()`
	size_t cachedPosition = -1;

	public this(const(char)[] source) {
		this.source = source;
	}

	public size_t currentPosition() {
		return this.position;
	}

	// Assumes `peek(1)` is valid and contains a whitespace char
	public void consumeWhitespace() {
		while (this.hasMore(1) && this.peek(1).isCssWhiteSpace()) {
			this.advance();
		}
	}

	public Token peekToken() {
		size_t oldPosition = this.position;
		Token t = this.consumeToken();
		this.cachedPosition = this.position;
		this.position = oldPosition;
		return t;
	}

	public void skipToken() {
		if (this.cachedPosition != -1) {
			this.position = this.cachedPosition;
			this.cachedPosition = -1;
		} else {
			this.consumeToken();
		}
	}

	public Token consumeToken() {
		this.cachedPosition = -1;

		if (this.hasMore(1)) {
			if (this.peek(1).isCssWhiteSpace()) {
				this.consumeWhitespace();

				return Token(WhitespaceToken());
			} else if (this.peek(1) == '"') {
				return this.consumeStringToken();
			} else if (this.peek(1) == '#') {
				this.advance(1);

				if (this.peek(1).isCssIdent() || this.isValidEscape(1)) {
					bool isId = this.wouldStartIdentSequence(1);
					return Token(HashToken(
						this.consumeIdentSequence(),
						isId,
					));
				} else {
					return Token(DelimToken('#'));
				}
			} else if (this.peek(1) == '\'') {
				return this.consumeStringToken();
			} else if (this.peek(1) == '(') {
				this.advance(1);
				return Token(OpenParenToken());
			} else if (this.peek(1) == ')') {
				this.advance(1);
				return Token(CloseParenToken());
			} else if (this.peek(1) == '+') {
				if (this.wouldStartNumber(1)) {
					return this.consumeNumericToken();
				} else {
					this.advance(1);

					return Token(DelimToken('+'));
				}
			} else if (this.peek(1) == ',') {
				this.advance(1);
				return Token(CommaToken());
			} else if (this.peek(1) == '-') {
				if (this.wouldStartNumber(1)) {
					return this.consumeNumericToken();
				} else if (this.wouldStartIdentSequence(1)) {
					return this.consumeIdentLikeToken();
				} else {
					this.advance(1);

					return Token(DelimToken('-'));
				}
			} else if (this.peek(1) == '.') {
				if (this.wouldStartNumber(1)) {
					return this.consumeNumericToken();
				} else {
					this.advance(1);
				
					return Token(DelimToken('.'));
				}
			} else if (this.peek(1) == ':') {
				this.advance(1);
				return Token(ColonToken());
			} else if (this.peek(1) == ';') {
				this.advance(1);
				return Token(SemicolonToken());
			} else if (this.peek(1) == '<') {
				this.advance(1);
				
				return Token(DelimToken('<'));
			} else if (this.peek(1) == '@') {
				this.advance(1);

				if (this.wouldStartIdentSequence(1)) {
					return Token(AtKeywordToken(this.consumeIdentSequence()));
				} else {
					return Token(DelimToken('@'));
				}
			} else if (this.peek(1) == '[') {
				this.advance(1);
				return Token(OpenSquareToken());
			} else if (this.peek(1) == '\\') {
				this.advance(1);
				if (this.isValidEscape(0)) {
					// TODO
					assert(0);
				} else {
					return Token(DelimToken('\\'));
				}
			} else if (this.peek(1) == ']') {
				this.advance(1);
				return Token(CloseSquareToken());
			} else if (this.peek(1) == '{') {
				this.advance(1);
				return Token(OpenCurlyToken());
			} else if (this.peek(1) == '}') {
				this.advance(1);
				return Token(CloseCurlyToken());
			} else if (this.peek(1).isDigit()) {
				return this.consumeNumericToken();
			} else if (this.peek(1).isCssIdentStart()) {
				return this.consumeIdentLikeToken();
			} else {
				this.advance();

				return Token(DelimToken(this.peek()));
			}
		} else {
			assert(0);
		}
	}

	public bool hasMoreTokens() {
		return this.hasMore(1);
	}

	// n is how many bytes to advance
	void advance(size_t n = 1) {
		this.position += n;
	}

	// n is how many bytes after position to check
	bool hasMore(size_t n) {
        if (n == 0) {
            return this.position >= 0;
        }
		return this.position + n < source.length;
	}

	// n is how many bytes of lookahead
	char peek(size_t n = 0) {
		return source[this.position + n];
	}

	// Assumes `peek(n)` is valid
	bool isValidEscape(size_t n) {
		// The newline handling here is fine because if a newline were to be \r\n,
		// `isCssNewlineStarter` would see the `\r` and return true
		return this.hasMore(n + 1) && this.peek(n) == '\\' && !isCssNewlineStarter(this.peek(n + 1));
	}

	// Assumes `peek()` is valid
	bool wouldStartIdentSequence(size_t n) {
		if (this.peek(n) == '-') {
			if (this.hasMore(n + 1)) {
				return isCssIdentStart(this.peek(n + 1)) || this.isValidEscape(n + 1);
			} else {
				return false;
			}
		} else if (isCssIdentStart(this.peek(n))) {
			return true;
		} else if (this.peek(n) == '\\') {
			return isValidEscape(n);
		} else {
			return false;
		}
	}

	// Assumes `peek(n)` is valid
	bool wouldStartNumber(size_t n) {
		if (this.peek(n) == '+' || this.peek(n) == '-') {
			if (this.hasMore(n + 1)) {
				if (this.peek(n + 1).isDigit()) {
					return true;
				} else if (this.peek(n + 1) == '.') {
					return this.hasMore(n + 2) && this.peek(n + 2).isDigit();
				} else {
					return false;
				}
			} else {
				return false;
			}
		} else if (this.peek(n) == '.') {
			return this.hasMore(n + 1) && this.peek(n + 1).isDigit();
		} else if (this.peek(n).isDigit()) {
			return true;
		} else {
			return false;
		}
	}

	bool consumeComments() {
		bool matchedComment = false;

		while (true) {
			if (consumeComment()) {
				matchedComment = true;
			} else {
				break;
			}
		}

		return matchedComment;
	}

	bool consumeComment() {
		if (this.hasMore(2) && this.peek() == '/' && this.peek(1) == '*') {
				this.advance(2);

				while (this.hasMore(1)) {
					if (this.peek() == '*' && this.hasMore(2) && this.peek(1) == '/') {
						this.advance(2);
						return true;
					}
					this.advance();
				}

				throw nogc_new!CssParseException("eof when parsing comment");
			}

		return false;
	}

	// Assumes `wouldStartNumber(1)` is true
	CssNumber consumeNumber() {
		bool hadSign = false;
		double sign = 1.0;
		if (this.peek(1) == '+') {
			hadSign = true;
			this.advance();
		} else if (this.peek(1) == '-') {
			hadSign = true;
			sign = -1.0;
			this.advance();
		}

		double intPart = 0.0;

		while (this.hasMore(1) && this.peek(1).isDigit()) {
			this.advance();
			
			intPart = intPart * 10.0 + cast(double) (this.peek() - '0');
		}

		bool isInteger = true;
		double fracPart = 0.0;

		if (this.hasMore(2) && this.peek(1) == '.' && this.peek(2).isDigit()) {
			isInteger = false;
			this.advance();

			double scale = 0.1;
			while (this.hasMore(1) && this.peek(1).isDigit()) {
				this.advance();

				fracPart = fracPart + scale * cast(double) (this.peek() - '0');
				scale *= 0.1;
			}
		}

		bool hasExponent = false;

		// We need to check for 'e' or 'E', followed by a sign bit, followed by a digit
		// This is kind of gnarly but directly follows the spec text for now
		if (this.hasMore(2) && (this.peek(1) == 'E' || this.peek(1) == 'e')) {
			if (this.peek(2) == '+' || this.peek(2) == '-') {
				if (this.hasMore(3) && this.peek(3).isDigit()) {
					hasExponent = true;
					isInteger = false;
				}
			}

			if (this.peek(2).isDigit()) {
				hasExponent = true;
				isInteger = false;
			}
		}

		double expSign = 1.0;
		double expPart = 0.0;

		if (hasExponent) {
			this.advance(1);

			if (this.peek(1) == '+') {
				this.advance();
			} else if (this.peek(1) == '-') {
				expSign = -1.0;
				this.advance();
			}

			while (this.hasMore(1) && this.peek(1).isDigit()) {
				this.advance();

				expPart = expPart * 10.0 + cast(double) (this.peek() - '0');
			}
		}

		CssNumber ret = {
			hadSign: hadSign,
			isInteger: isInteger,
			value: pow(10.0, expSign * expPart) * sign * (intPart + fracPart)
		};

		return ret;
	}
	
	// Assumes `wouldStartIdentSequence(1)` is true
	nstring consumeIdentSequence() {
		nstring ret;

		while (this.hasMore(1)) {
			if (isCssIdent(this.peek(1))) {
				// If this is part of a multi-byte UTF sequence,
				// we'll consume it all before something else happens
				this.advance();
				ret ~= this.peek();
			} else if (this.isValidEscape(1)) {
				// TODO
				assert(0);
			} else {
				break;
			}
		}
		return ret;
	}

	// Assumes `isCssNewlineStarter(peek(1))` is true
	void consumeNewline() {
		if (this.hasMore(2) && this.peek(1) == '\r' && this.peek(2) == '\n') {
			this.advance(2);
		} else {
			this.advance(1);
		}
	}

	Token consumeStringToken() {
		char stop = this.peek();

		nstring value;

		// parse error if reaches EOF
		while (this.hasMore(1)) {
			if (this.peek(1) == stop) {
				this.advance(1);
				break;
			} else if (isCssNewlineStarter(this.peek(1))) {
				return Token(BadStringToken());
			} else if (this.peek(1) == '\\') {
				this.advance(1);

				if (!this.hasMore(1)) {
					break;
				} else if (isCssNewlineStarter(this.peek(1))) {
					this.consumeNewline();
				} else if (this.isValidEscape(0)) {
					// TODO
					assert(0);
				}
			} else {
				// If this is part of a multi-byte UTF sequence,
				// we'll consume it all before something else happens
				this.advance(1);
				value ~= this.peek();
			}
		}

		return Token(StringToken(value));
	}

	Token consumeNumericToken() {
		CssNumber number = this.consumeNumber();

		if (this.hasMore(1)) {
			if (this.wouldStartIdentSequence(1)) {
				return Token(DimensionToken(
					number.value,
					number.hadSign,
					number.isInteger,
					this.consumeIdentSequence(),
				));
			} else if (this.peek(1) == '%') {
				return Token(PercentageToken(
					number.value,
					number.hadSign,
				));
			}
		}

		return Token(NumberToken(
			number.value,
			number.hadSign,
			number.isInteger,
		));
	}

	Token consumeIdentLikeToken() {
		nstring value = consumeIdentSequence();
		
		if (this.hasMore(1)) {
			if (asciiCaseInsensitiveEq(value[], "url")) {
				// TODO
				assert(0);
			} else if (this.peek(1) == '(') {
				return Token(FunctionToken(value));
			}
		}

		return Token(IdentToken(value));
	}
}

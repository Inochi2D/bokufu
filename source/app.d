module app;

import bokufu.token;
import bokufu.tokenizer;
import numem.all;
import std.stdio;
import std.file;

import std.algorithm : move;

import bokufu.parser.unparsed;
import bokufu.parser;

void main()
{
	string content = readText("test.css");

	auto tokenizer = Tokenizer(content);
	auto parserTokenizer = tokenizer;

	// vector!Token c;
	// while (tokenizer.hasMoreTokens()) {
	// 	auto next = tokenizer.consumeToken();
	// 	c ~= next;
	// }
	// writeln(c[]);
	writeln("[Token(atKeywordToken, TokenData), Token(openCurlyToken, TokenData), Token(identToken, TokenData), Token(colonToken, TokenData), Token(functionToken, TokenData), Token(openParenToken, TokenData), Token(stringToken, TokenData), Token(closeParenToken, TokenData), Token(semicolonToken, TokenData), Token(closeCurlyToken, TokenData), Token(whitespaceToken, TokenData)]")
;
	auto n = Parser(parserTokenizer);
	auto rules = n.consumeSpreadSheet();
	
	foreach (rule; rules) {
		writeln(rule);
	}
	writeln(rules[]);
}



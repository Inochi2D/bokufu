module bokufu.tokenizer.tests.number;

import bokufu.tokenizer;

unittest
{
	Tokenizer a = Tokenizer("5");
	assert(a.wouldStartNumber(1));
	auto num = a.consumeNumber();
	assert(num == CssNumber(' ', true, 5));
}


unittest
{
	Tokenizer a = Tokenizer("+5");
	assert(a.wouldStartNumber(1));
	auto num = a.consumeNumber();
	assert(num == CssNumber('+', true, 5));
}


unittest
{
	Tokenizer a = Tokenizer("-5");
	assert(a.wouldStartNumber(1));
	auto num = a.consumeNumber();
	assert(num == CssNumber('-', true, -5));
}

unittest
{
	Tokenizer a = Tokenizer("5e2");
	assert(a.wouldStartNumber(1));
	auto num = a.consumeNumber();
	assert(num == CssNumber(' ', false, 500));
}

unittest
{
	Tokenizer a = Tokenizer("5.0e2");
	assert(a.wouldStartNumber(1));
	auto num = a.consumeNumber();
	assert(num == CssNumber(' ', false, 500));
}

unittest
{
	Tokenizer a = Tokenizer("1.0e-1");
	assert(a.wouldStartNumber(1));
	auto num = a.consumeNumber();
	assert(num == CssNumber(' ', false, 0.1));
}

#ifndef __DRAGON_LISP_SCANNER_H__
#define __DRAGON_LISP_SCANNER_H__

#ifndef yyFlexLexerOnce
#include <FlexLexer.h>
#endif

#include <istream>

#include "DragonLisp.tab.hh"
#include "location.hh"

namespace DragonLisp {

class DLScanner : public yyFlexLexer {
private:
	DragonLisp::DLParser::semantic_type* yylval = nullptr;
	DragonLisp::DLParser::location_type* loc = nullptr;

public:
	DLScanner(std::istream* in) : yyFlexLexer(in) {
		this->loc = new DragonLisp::DLParser::location_type();
	}

	using FlexLexer::yylex;
	virtual int yylex(
		DragonLisp::DLParser::semantic_type* lval,
		DragonLisp::DLParser::location_type* location,
		DragonLisp::DLDriver& drv
	);
};

} // end namespace DragonLisp

#endif // __DRAGON_LISP_SCANNER_H__
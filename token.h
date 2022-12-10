#ifndef __DRAGON_LISP_TOKEN_H__
#define __DRAGON_LISP_TOKEN_H__

namespace DragonLisp {

enum Token {
	STRING,
	SPACE,
	FLOAT,
	INTEGER,
	LESS_EQUAL,
	GREATER_EQUAL,
	LESS,
	GREATER,
	NOT_EQUAL,
	EQUAL,
	LPAREN,
	RPAREN,
	PLUS,
	MINUS,
	MULTIPLY,
	DIVIDE,
};

}

#endif // __DRAGON_LISP_TOKEN_H__
#ifndef __DRAGON_LISP_TOKEN_H__
#define __DRAGON_LISP_TOKEN_H__

namespace DragonLisp {

enum Token {
	LE,
	GE,
	EQUAL,
	NE,
	LT,
	GT,
    PLUS,
    MINUS,
    MULTIPLY,
    DIVIDE,
	STRING,
};

}

#endif // __DRAGON_LISP_TOKEN_H__
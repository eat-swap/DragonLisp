#ifndef __DRAGON_LISP_TYPES_H__
#define __DRAGON_LISP_TYPES_H__

namespace DragonLisp {

enum ValueType {
	TYPE_INTEGER,
	TYPE_FLOAT,
	TYPE_STRING,
	TYPE_ARRAY,
	TYPE_T,		// has no value
	TYPE_NIL,	// has no value
};

} // namespace DragonLisp

#endif // __DRAGON_LISP_TYPES_H__

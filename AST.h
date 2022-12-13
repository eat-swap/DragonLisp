#ifndef __DRAGON_LISP_AST_H__
#define __DRAGON_LISP_AST_H__

#include <memory>
#include <variant>
#include <vector>

#include "types.h"
#include "token.h"
#include "context.h"

namespace DragonLisp {

enum ASTType {
	T_ArrayRefAST,
	T_IdentifierAST,
	T_FuncDefAST,
	T_FuncCallAST,
	T_IfAST,
	T_LoopAST,
	T_LoopForeverAST,
	T_LoopForAST,
	T_LoopDoTimesAST,
	T_UnaryAST,
	T_BinaryAST,
	T_ListAST,
	T_VarOpAST,
	T_LValOpAST,
	T_ReturnAST,
	T_LiteralAST,
};

/// BaseAST - Base class for all AST nodes.
class BaseAST {
public:
	virtual ~BaseAST() = default;

	virtual ASTType getType() const = 0;
};

class ExprAST : public BaseAST {
public:
	virtual std::shared_ptr<Value> eval(Context* parent) = 0;
};

class LValueAST : public ExprAST {
public:
	virtual std::shared_ptr<Value> set(Context* parent, std::shared_ptr<Value> value) = 0;
};

class ArrayRefAST : public LValueAST {
private:
	std::string name;
	std::shared_ptr<ExprAST> index;

public:
	ArrayRefAST(std::string name, std::shared_ptr<ExprAST> index) : name(std::move(name)), index(std::move(index)) {}

	ASTType getType() const override final {
		return T_ArrayRefAST;
	}

	std::shared_ptr<Value> eval(Context* parent) override final;

	std::shared_ptr<Value> set(Context* parent, std::shared_ptr<Value> value) override final;
};

class IdentifierAST : public LValueAST {
private:
	std::string name;

public:
	explicit IdentifierAST(std::string name) : name(std::move(name)) {}

	ASTType getType() const override final {
		return T_IdentifierAST;
	}

	std::shared_ptr<Value> eval(Context* parent) override final;

	std::shared_ptr<Value> set(Context* parent, std::shared_ptr<Value> value) override final;
};

class FuncDefAST : public BaseAST {
private:
	std::string name;
	std::vector<std::string> args;
	std::vector<std::shared_ptr<ExprAST>> body;

public:
	FuncDefAST(std::string name, std::vector<std::string> args, std::vector<std::shared_ptr<ExprAST>> body) : name(std::move(name)), args(std::move(args)), body(std::move(body)) {}

	std::shared_ptr<Value> eval(Context* parent, std::vector<std::shared_ptr<Value>> arg);

	inline ASTType getType() const override final {
		return T_FuncDefAST;
	}

	inline const std::string& getName() const {
		return this->name;
	}
};

class FuncCallAST : public ExprAST {
private:
	std::string name;
	std::vector<std::shared_ptr<ExprAST>> args;

public:
	FuncCallAST(std::string name, std::vector<std::shared_ptr<ExprAST>> args) : name(std::move(name)), args(std::move(args)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	inline ASTType getType() const override final {
		return T_FuncCallAST;
	}
};

class IfAST : public ExprAST {
private:
	std::shared_ptr<ExprAST> cond;
	std::shared_ptr<ExprAST> then;
	std::shared_ptr<ExprAST> els;

public:
	IfAST(std::shared_ptr<ExprAST> cond, std::shared_ptr<ExprAST> then, std::shared_ptr<ExprAST> els) : cond(std::move(cond)), then(std::move(then)), els(std::move(els)) {}

	std::shared_ptr<Value> eval(Context* parent) override final {
		throw std::runtime_error("You should use IfAST::getResult() instead of IfAST::eval()");
	}

	std::shared_ptr<ExprAST> getResult(Context* parent);

	inline ASTType getType() const override final {
		return T_IfAST;
	}
};

class LoopAST : public ExprAST {};

class LoopForeverAST : public LoopAST {
private:
	std::vector<std::shared_ptr<ExprAST>> body;

public:
	explicit LoopForeverAST(std::vector<std::shared_ptr<ExprAST>> body) : body(std::move(body)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	inline ASTType getType() const override final {
		return T_LoopForeverAST;
	}
};

class LoopForAST : public LoopAST {
private:
	std::string name;
	std::shared_ptr<ExprAST> start;
	std::shared_ptr<ExprAST> end;
	std::vector<std::shared_ptr<ExprAST>> body;

public:
	LoopForAST(std::string name, std::shared_ptr<ExprAST> start, std::shared_ptr<ExprAST> end, std::vector<std::shared_ptr<ExprAST>> body) : name(std::move(name)), start(std::move(start)), end(std::move(end)), body(std::move(body)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	inline ASTType getType() const override final {
		return T_LoopForAST;
	}
};

class LoopDoTimesAST : public LoopAST {
private:
	std::string name;
	std::shared_ptr<ExprAST> times;
	std::vector<std::shared_ptr<ExprAST>> body;

public:
	LoopDoTimesAST(std::string name, std::shared_ptr<ExprAST> times, std::vector<std::shared_ptr<ExprAST>> body) : name(std::move(name)), times(std::move(times)), body(std::move(body)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	inline ASTType getType() const override final {
		return T_LoopDoTimesAST;
	}
};

class UnaryAST : public ExprAST {
private:
	std::shared_ptr<ExprAST> expr;
	Token op;

public:
	UnaryAST(std::shared_ptr<ExprAST> expr, Token op) : expr(std::move(expr)), op(std::move(op)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	inline ASTType getType() const override final {
		return T_UnaryAST;
	}
};

class BinaryAST : public ExprAST {
private:
	std::shared_ptr<ExprAST> lhs;
	std::shared_ptr<ExprAST> rhs;
	Token op;

public:
	BinaryAST(std::shared_ptr<ExprAST> lhs, std::shared_ptr<ExprAST> rhs, Token op) : lhs(std::move(lhs)), rhs(std::move(rhs)), op(std::move(op)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	inline ASTType getType() const override final {
		return T_BinaryAST;
	}
};

class ListAST : public ExprAST {
private:
	std::vector<std::shared_ptr<ExprAST>> exprs;
	Token op;

public:
	ListAST(std::vector<std::shared_ptr<ExprAST>> exprs, Token op) : exprs(std::move(exprs)), op(std::move(op)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	inline ASTType getType() const override final {
		return T_ListAST;
	}
};

class VarOpAST : public ExprAST {
private:
	std::string name;
	std::shared_ptr<ExprAST> expr;
	Token op;

public:
	VarOpAST(std::string name, std::shared_ptr<ExprAST> expr, Token op) : name(std::move(name)), expr(std::move(expr)), op(std::move(op)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	inline ASTType getType() const override final {
		return T_VarOpAST;
	}
};

class LValOpAST : public ExprAST {
private:
	std::shared_ptr<ExprAST> lval;
	std::shared_ptr<ExprAST> expr;
	Token op;

public:
	LValOpAST(std::shared_ptr<ExprAST> lval, std::shared_ptr<ExprAST> expr, Token op) : lval(std::move(lval)), expr(std::move(expr)), op(std::move(op)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	inline ASTType getType() const override final {
		return T_LValOpAST;
	}
};

class ReturnAST : public ExprAST {
private:
	std::shared_ptr<ExprAST> expr;
	std::string name;

public:
	explicit ReturnAST(std::shared_ptr<ExprAST> expr) : expr(std::move(expr)), name() {}

	ReturnAST(std::shared_ptr<ExprAST> expr, std::string name) : expr(std::move(expr)), name(std::move(name)) {}

	std::shared_ptr<Value> eval(Context* parent) override final;

	std::string getName() const {
		return name;
	}

	inline ASTType getType() const override final {
		return T_ReturnAST;
	}
};

class LiteralAST : public ExprAST {
private:
	std::shared_ptr<Value> val;

public:
	explicit LiteralAST(bool val) : val(std::make_shared<SingleValue>(val)) {}

	explicit LiteralAST(std::int64_t val) : val(std::make_shared<SingleValue>(val)) {}

	explicit LiteralAST(double val) : val(std::make_shared<SingleValue>(val)) {}

	explicit LiteralAST(std::string val) : val(std::make_shared<SingleValue>(std::move(val))) {}

	inline ASTType getType() const override final {
		return T_LiteralAST;
	}

	std::shared_ptr<Value> eval(Context* parent) override final {
		return val->copy();
	}
};

}

#endif // __DRAGON_LISP_AST_H__

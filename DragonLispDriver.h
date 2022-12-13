#ifndef __DRAGON_LISP_DRIVER_H__
#define __DRAGON_LISP_DRIVER_H__

#include <string>
#include <istream>

#include "DragonLispScanner.h"
#include "DragonLisp.tab.hh"
#include "AST.h"

namespace DragonLisp {

class DLDriver {
private:
	DLParser* parser = nullptr;
	DLScanner* scanner = nullptr;
	DragonLisp::location location;

	Context* context = nullptr;

public:
	DLDriver() = default;
	virtual ~DLDriver();

	int parse(const std::string& f);
	int parse(std::istream& in, const std::string& s = "stream input");

	void error(const DLParser::location_type& l, const std::string& m);
	void error(const std::string& m);

	void execute(std::variant<std::shared_ptr<DragonLisp::ExprAST>, std::shared_ptr<DragonLisp::FuncDefAST>> ast);

	// Identifier AST
	static std::shared_ptr<LValueAST> constructLValueAST(std::string name);

	// ArrayRef AST
	static std::shared_ptr<LValueAST> constructLValueAST(std::string name, std::shared_ptr<ExprAST> index);

	// FuncDef AST
	static std::shared_ptr<FuncDefAST> constructFuncDefAST(std::string name, std::vector<std::string> args, std::vector<std::shared_ptr<ExprAST>> body);

	// Literal AST
	static std::shared_ptr<ExprAST> constructLiteralAST(bool value);
	static std::shared_ptr<ExprAST> constructLiteralAST(std::int64_t value);
	static std::shared_ptr<ExprAST> constructLiteralAST(double value);
	static std::shared_ptr<ExprAST> constructLiteralAST(std::string value);

	// BinaryExpr AST
	static std::shared_ptr<BinaryAST> constructBinaryExprAST(std::shared_ptr<ExprAST> lhs, std::shared_ptr<ExprAST> rhs, Token op);

	// UnaryExpr AST
	static std::shared_ptr<UnaryAST> constructUnaryExprAST(std::shared_ptr<ExprAST> expr, Token op);

	// ListExpr AST
	static std::shared_ptr<ListAST> constructListExprAST(std::vector<std::shared_ptr<ExprAST>> exprs, Token op);

	// If AST
	static std::shared_ptr<IfAST> constructIfAST(std::shared_ptr<ExprAST> cond, std::shared_ptr<ExprAST> then, std::shared_ptr<ExprAST> els);

	// Func Call AST
	static std::shared_ptr<FuncCallAST> constructFuncCallAST(std::string name, std::vector<std::shared_ptr<ExprAST>> args);

	// Var Op AST
	static std::shared_ptr<VarOpAST> constructVarOpAST(std::string name, std::shared_ptr<ExprAST> value, Token op);

	// LVal Op AST
	static std::shared_ptr<LValOpAST> constructLValOpAST(std::shared_ptr<LValueAST> lval, std::shared_ptr<ExprAST> value, Token op);

	// Return AST
	static std::shared_ptr<ReturnAST> constructReturnAST(std::shared_ptr<ExprAST> value);
	static std::shared_ptr<ReturnAST> constructReturnAST(std::shared_ptr<ExprAST> value, std::string name);

	// Loop AST
	static std::shared_ptr<LoopAST> constructLoopAST(std::vector<std::shared_ptr<ExprAST>> body);
	static std::shared_ptr<LoopAST> constructLoopAST(std::string id, std::shared_ptr<ExprAST> from, std::shared_ptr<ExprAST> to, std::vector<std::shared_ptr<ExprAST>> body);
	static std::shared_ptr<LoopAST> constructLoopAST(std::string id, std::shared_ptr<ExprAST> to, std::vector<std::shared_ptr<ExprAST>> body);
};

} // end namespace DragonLisp

#endif // __DRAGON_LISP_DRIVER_H__

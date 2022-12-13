#include <fstream>
#include <string>

#include "DragonLispDriver.h"

namespace DragonLisp {

DLDriver::~DLDriver() {
	delete (this->scanner);
	this->scanner = nullptr;
	delete (this->parser);
	this->parser = nullptr;
}

int DLDriver::parse(const std::string& f) {
	std::ifstream in(f);
	if (!in.good()) {
		std::printf("Could not open file %s\n", f.c_str());
		return 1;
	}
	return this->parse(in, f);
}

int DLDriver::parse(std::istream& in, const std::string& s) {
	// Scanner
	delete this->scanner;
	this->scanner = new DLScanner(&in);

	// Parser
	delete this->parser;
	this->parser = new DLParser(*this->scanner, *this);

	// Execution Context
	delete this->context;
	this->context = new Context(nullptr);

	this->parser->set_debug_level(
#ifdef DLDEBUG
	1
#else
	0
#endif
	);
	return this->parser->parse();
}

std::shared_ptr<LValueAST> DLDriver::constructLValueAST(std::string name) {
	return std::make_shared<IdentifierAST>(std::move(name));
}

std::shared_ptr<LValueAST> DLDriver::constructLValueAST(std::string name, std::shared_ptr<ExprAST> index) {
	return std::make_shared<ArrayRefAST>(std::move(name), std::move(index));
}

std::shared_ptr<FuncDefAST> DLDriver::constructFuncDefAST(std::string name, std::vector<std::string> args, std::vector<std::shared_ptr<ExprAST>> body) {
	return std::make_shared<FuncDefAST>(std::move(name), std::move(args), std::move(body));
}

std::shared_ptr<ExprAST> DLDriver::constructLiteralAST(bool value) {
	return std::make_shared<LiteralAST>(value);
}

std::shared_ptr<ExprAST> DLDriver::constructLiteralAST(std::int64_t value) {
	return std::make_shared<LiteralAST>(value);
}

std::shared_ptr<ExprAST> DLDriver::constructLiteralAST(double value) {
	return std::make_shared<LiteralAST>(value);
}

std::shared_ptr<ExprAST> DLDriver::constructLiteralAST(std::string value) {
	return std::make_shared<LiteralAST>(std::move(value));
}

std::shared_ptr<BinaryAST> DLDriver::constructBinaryExprAST(std::shared_ptr<ExprAST> lhs, std::shared_ptr<ExprAST> rhs, Token op) {
	return std::make_shared<BinaryAST>(std::move(lhs), std::move(rhs), op);
}

std::shared_ptr<UnaryAST> DLDriver::constructUnaryExprAST(std::shared_ptr<ExprAST> expr, Token op) {
	return std::make_shared<UnaryAST>(std::move(expr), op);
}

std::shared_ptr<ListAST> DLDriver::constructListExprAST(std::vector<std::shared_ptr<ExprAST>> exprs, Token op) {
	return std::make_shared<ListAST>(std::move(exprs), op);
}

std::shared_ptr<IfAST> DLDriver::constructIfAST(std::shared_ptr<ExprAST> cond, std::shared_ptr<ExprAST> then, std::shared_ptr<ExprAST> els) {
	return std::make_shared<IfAST>(std::move(cond), std::move(then), std::move(els));
}

std::shared_ptr<FuncCallAST> DLDriver::constructFuncCallAST(std::string name, std::vector<std::shared_ptr<ExprAST>> args) {
	return std::make_shared<FuncCallAST>(std::move(name), std::move(args));
}

std::shared_ptr<VarOpAST> DLDriver::constructVarOpAST(std::string name, std::shared_ptr<ExprAST> value, Token op) {
	return std::make_shared<VarOpAST>(std::move(name), std::move(value), op);
}

std::shared_ptr<LValOpAST> DLDriver::constructLValOpAST(std::shared_ptr<LValueAST> lval, std::shared_ptr<ExprAST> value, Token op) {
	return std::make_shared<LValOpAST>(std::move(lval), std::move(value), op);
}

std::shared_ptr<ReturnAST> DLDriver::constructReturnAST(std::shared_ptr<ExprAST> value) {
	return std::make_shared<ReturnAST>(std::move(value));
}

std::shared_ptr <ReturnAST> DLDriver::constructReturnAST(std::shared_ptr <ExprAST> value, std::string name) {
	return std::make_shared<ReturnAST>(std::move(value), std::move(name));
}

std::shared_ptr<LoopAST> DLDriver::constructLoopAST(std::vector<std::shared_ptr<ExprAST>> body) {
	return std::make_shared<LoopForeverAST>(
		std::move(body)
	);
}

std::shared_ptr<LoopAST> DLDriver::constructLoopAST(std::string id, std::shared_ptr<ExprAST> to, std::vector<std::shared_ptr<ExprAST>> body) {
	return std::make_shared<LoopDoTimesAST>(
		std::move(id),
		std::move(to),
		std::move(body)
	);
}

std::shared_ptr<LoopAST> DLDriver::constructLoopAST(std::string id, std::shared_ptr<ExprAST> from, std::shared_ptr<ExprAST> to, std::vector<std::shared_ptr<ExprAST>> body) {
	return std::make_shared<LoopForAST>(
		std::move(id),
		std::move(from),
		std::move(to),
		std::move(body)
	);
}

void DLDriver::execute(std::variant <std::shared_ptr<DragonLisp::ExprAST>, std::shared_ptr<DragonLisp::FuncDefAST>> ast) {
	if (ast.index() == 0) { // ExprAST
		auto expr = std::get<0>(ast);
		expr->eval(this->context);
	} else { // ast.index() == 1, FuncDefAST
		auto func = std::get<1>(ast);
		this->context->setFunc(func->getName(), func);
	}
}

} // end namespace DragonLisp

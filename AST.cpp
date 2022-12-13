#include <utility>
#include <iostream>
#include <algorithm>
#include <numeric>

#include "AST.h"

namespace DragonLisp {

std::shared_ptr<Value> ArrayRefAST::eval(Context* parent) {
	// Eval this->index
	auto idx = std::dynamic_pointer_cast<SingleValue>(this->index->eval(parent));
	if (!idx || !idx->isInt())
		throw std::runtime_error("Cannot eval index as integer");

	auto var = parent->getVariable(this->name);
	if (!var)
		throw std::runtime_error("Variable not found: " + this->name);
	auto varC = std::dynamic_pointer_cast<ArrayValue>(var);
	if (!varC)
		throw std::runtime_error("Cannot reference from non-array variable: " + this->name);
	if (varC->getSize() <= idx->getInt())
		throw std::runtime_error("Index out of range: " + std::to_string(idx->getInt()) + " >= " + std::to_string(varC->getSize()));
	return std::make_shared<SingleValue>((*varC)[idx->getInt()]);
}

std::shared_ptr<Value> ArrayRefAST::set(Context* parent, std::shared_ptr<Value> value) {
	// Eval this->index
	auto idx = std::dynamic_pointer_cast<SingleValue>(this->index->eval(parent));
	if (!idx || !idx->isInt())
		throw std::runtime_error("Cannot eval index as integer");

	auto var = parent->getVariable(this->name);
	if (!var)
		throw std::runtime_error("Variable not found: " + this->name);
	auto varC = std::dynamic_pointer_cast<ArrayValue>(var);
	if (!varC)
		throw std::runtime_error("Cannot reference from non-array variable: " + this->name);
	if (varC->getSize() <= idx->getInt())
		throw std::runtime_error("Index out of range: " + std::to_string(idx->getInt()) + " >= " + std::to_string(varC->getSize()));

	auto val = std::dynamic_pointer_cast<SingleValue>(value);
	if (!val)
		throw std::runtime_error("Cannot set array element to another array");
	varC->set(idx->getInt(), *val);
	return value;
}

std::shared_ptr<Value> IdentifierAST::eval(Context* parent) {
	auto var = parent->getVariable(this->name);
	if (!var)
		throw std::runtime_error("Variable not found: " + this->name);
	return var->copy();
}

std::shared_ptr<Value> IdentifierAST::set(Context* parent, std::shared_ptr<Value> value) {
	parent->setVariable(this->name, value);
	return value;
}

std::shared_ptr<Value> FuncDefAST::eval(Context* parent, std::vector<std::shared_ptr<Value>> arg) {
	// Create a new context
	auto ctx = std::make_shared<Context>(parent);

	// Set arguments
	for (size_t i = 0; i < this->args.size(); i++) {
		if (i >= arg.size())
			throw std::runtime_error("Too few arguments");
		ctx->setVariable(this->args[i], arg[i]);
	}

	// Eval body
	std::shared_ptr<Value> ret = std::make_shared<SingleValue>(); // which is nil
	for (auto& stmt : this->body) {
		auto* ptr = stmt.get();
		if (ptr->getType() == T_IfAST)
			ptr = dynamic_cast<IfAST*>(ptr)->getResult(ctx.get()).get();
		if (!ptr)
			continue;
		if (ptr->getType() == T_ReturnAST)
			return ptr->eval(ctx.get());
		ret = ptr->eval(ctx.get());
	}
	return ret;
}

std::shared_ptr<Value> FuncCallAST::eval(Context* parent) {
	// Get the function
	auto func = parent->getFunc(this->name);
	if (!func)
		throw std::runtime_error("Function not defined: " + this->name);

	// Eval arguments
	std::vector<std::shared_ptr<Value>> arg;
	for (const auto& a : this->args) {
		arg.push_back(a->eval(parent));
	}

	// Get the global context
	auto globalCtx = parent;
	while (globalCtx->getParent())
		globalCtx = globalCtx->getParent();

	// Eval under global context
	return func->eval(globalCtx, arg);
}


std::shared_ptr<ExprAST> IfAST::getResult(Context* parent) {
	// Eval condition
	auto c = this->cond->eval(parent);
	bool ok = c->isArray();
	if (!ok) {
		auto cc = std::dynamic_pointer_cast<SingleValue>(c);
		if (!cc)
			throw std::runtime_error("Unexpected error");
		if (!cc->isNil())
			ok = true;
	}
	return ok ? this->then : this->els;
}


std::shared_ptr<Value> LoopForeverAST::eval(Context* parent) {
	// No context is needed
	while (true) {
		for (auto& stmt : this->body) {
			auto* ptr = stmt.get();
			if (ptr->getType() == T_IfAST)
				ptr = dynamic_cast<IfAST*>(ptr)->getResult(parent).get();
			if (!ptr)
				continue;
			if (ptr->getType() == T_ReturnAST)
				return ptr->eval(parent);
			ptr->eval(parent);
		}
	}
	throw std::runtime_error("Unexpected error");
}

std::shared_ptr <Value> LoopForAST::eval(Context* parent) {
	// Create a new context
	auto ctx = std::make_shared<Context>(parent);

	// Eval condition
	auto s = std::dynamic_pointer_cast<SingleValue>(this->start->eval(parent)->copy());
	auto e = std::dynamic_pointer_cast<SingleValue>(this->end->eval(parent));

	// Assert that s and e are numeric
	if (!s || !e || (!s->isInt() && !s->isFloat()) || (!e->isInt() && !e->isFloat()))
		throw std::runtime_error("LoopForAST: start and end must be numeric");

	// Main loop
	while (*s <= *e) {
		// Set the variable
		ctx->setVariable(this->name, s);

		// Eval body
		for (auto& stmt : this->body) {
			auto* ptr = stmt.get();
			if (ptr->getType() == T_IfAST)
				ptr = dynamic_cast<IfAST*>(ptr)->getResult(ctx.get()).get();
			if (!ptr)
				continue;
			if (ptr->getType() == T_ReturnAST)
				return ptr->eval(ctx.get());
			ptr->eval(ctx.get());
		}

		// Increment
		s->operator++();
	}

	// Return nil
	return std::make_shared<SingleValue>(false);
}

std::shared_ptr <Value> LoopDoTimesAST::eval(Context* parent) {
	// Create a new context
	auto ctx = std::make_shared<Context>(parent);

	// Eval condition
	auto terminate = std::dynamic_pointer_cast<SingleValue>(this->times->eval(parent)->copy());
	if (!terminate || !terminate->isInt())
		throw std::runtime_error("DOTIMES: times must be an integer");
	auto n = terminate->getInt();

	// Main Loop
	for (std::int64_t i = 0; i < n; ++i) {
		// Set Variable
		ctx->setVariable(this->name, std::make_shared<SingleValue>(i));

		// Eval Body
		for (auto& stmt : this->body) {
			auto* ptr = stmt.get();
			if (ptr->getType() == T_IfAST)
				ptr = dynamic_cast<IfAST*>(ptr)->getResult(ctx.get()).get();
			if (!ptr)
				continue;
			if (ptr->getType() == T_ReturnAST)
				return ptr->eval(ctx.get());
			ptr->eval(ctx.get());
		}
	}

	// Return nil
	return std::make_shared<SingleValue>(false);
}

std::shared_ptr<Value> UnaryAST::eval(Context* parent) {
	auto val = this->expr->eval(parent);
	auto valS = std::dynamic_pointer_cast<SingleValue>(val);
	switch (this->op) {
		case NOT:
			return std::make_shared<SingleValue>(!val->isArray() && valS && valS->isNil());
		case MAKE_ARRAY:
			if (val->isArray() || (valS && !valS->isInt()))
				throw std::runtime_error("Array size must be an integer");
			return std::make_shared<ArrayValue>(valS->getInt());
		case PRINT:
			std::cout << val->toString() << std::endl;
			return val;
		default:
			throw std::runtime_error("Unexpected error");
	}
}

std::shared_ptr<Value> BinaryAST::eval(Context* parent) {
	// All binary operators requires
	// both operands to be int / float.
	auto lv = std::dynamic_pointer_cast<SingleValue>(this->lhs->eval(parent));
	auto rv = std::dynamic_pointer_cast<SingleValue>(this->rhs->eval(parent));
	if (!lv || !rv || !(lv->isInt() || lv->isFloat()) || !(rv->isInt() || rv->isFloat()))
		throw std::runtime_error("Both operands must be int or float");
	if (lv->isFloat() || rv->isFloat()) {
		double l = lv->isInt() ? lv->getInt() : lv->getFloat();
		double r = rv->isInt() ? rv->getInt() : rv->getFloat();
		switch (this->op) {
			case LESS:
				return std::make_shared<SingleValue>(l < r);
			case LESS_EQUAL:
				return std::make_shared<SingleValue>(l <= r);
			case GREATER:
				return std::make_shared<SingleValue>(l > r);
			case GREATER_EQUAL:
				return std::make_shared<SingleValue>(l >= r);
			case MOD:
			case REM:
				return std::make_shared<SingleValue>(std::fmod(l, r));
			default:
				throw std::runtime_error("This operator cannot be applied to float");
		}
	} else {
		std::int64_t l = lv->getInt();
		std::int64_t r = rv->getInt();
		switch (this->op) {
			case LESS:
				return std::make_shared<SingleValue>(l < r);
			case LESS_EQUAL:
				return std::make_shared<SingleValue>(l <= r);
			case GREATER:
				return std::make_shared<SingleValue>(l > r);
			case GREATER_EQUAL:
				return std::make_shared<SingleValue>(l >= r);
			case MOD:
			case REM:
				return std::make_shared<SingleValue>(l % r);
			case LOGNOR:
				return std::make_shared<SingleValue>(~(l | r));
			default:
				throw std::runtime_error("Unexpected error");
		}
	}
}

std::shared_ptr<Value> ListAST::eval(Context* parent) {
	auto ret = this->exprs[0]->eval(parent);
	auto retS = std::dynamic_pointer_cast<SingleValue>(ret);
	if (this->exprs.size() == 1) {
		switch (this->op) {
			case LOGAND:
			case LOGNOR:
			case LOGXOR:
			case LOGEQV:
				if (ret->isArray() || (retS && !retS->isInt()))
					throw std::runtime_error("Cannot apply selected operator to non-integer");
			case MAX:
			case MIN:
			case PLUS:
			case MULTIPLY:
				if (ret->isArray() || (retS && !retS->isInt() && !retS->isFloat()))
					throw std::runtime_error("Cannot apply selected operator to non-integer or non-float");
			case AND:
			case OR:
				return ret;
			case EQUAL:
			case NOT_EQUAL:
				if (ret->isArray() || (retS && !retS->isInt() && !retS->isFloat()))
					throw std::runtime_error("Cannot apply selected operator to non-integer or non-float");
				return std::make_shared<SingleValue>(true);
			default:;
		}
		throw std::runtime_error("Invalid argument count for selected operator");
	}

	// Transform #1: Eval all values.
	std::vector<std::shared_ptr<Value>> vals;
	std::transform(this->exprs.begin(), this->exprs.end(), std::back_inserter(vals), [&](std::shared_ptr<ExprAST>& ptr) {
		return ptr->eval(parent);
	});

	// For And, return NIL if any value is NIL. Otherwise, return the last value.
	if (this->op == AND) {
		if (std::any_of(vals.begin(), vals.end(), [](std::shared_ptr<Value>& ptr) {
			auto val = std::dynamic_pointer_cast<SingleValue>(ptr);
			return ptr->isArray() && val && val->isNil();
		}))
			return std::make_shared<SingleValue>(false);
		return vals.back();
	}

	// For Or, return the first non-NIL value or NIL if all values are NIL.
	if (this->op == OR) {
		auto it = std::find_if(vals.begin(), vals.end(), [](std::shared_ptr<Value>& ptr) {
			auto val = std::dynamic_pointer_cast<SingleValue>(ptr);
			return !ptr->isArray() || (val && !val->isNil());
		});
		if (it == vals.end())
			return std::make_shared<SingleValue>(false);
		return *it;
	}

	// Now, all operators require all values to be int / float.
	if (std::any_of(vals.begin(), vals.end(), [](std::shared_ptr<Value>& ptr) {
		auto val = std::dynamic_pointer_cast<SingleValue>(ptr);
		return ptr->isArray() || (val && !val->isInt() && !val->isFloat());
	}))
		throw std::runtime_error("All values must be int or float");

	// Transform #2: Convert all values
	std::vector<std::shared_ptr<SingleValue>> vals2;
	std::transform(vals.begin(), vals.end(), std::back_inserter(vals2), [](std::shared_ptr<Value>& ptr) {
		return std::dynamic_pointer_cast<SingleValue>(ptr);
	});

	// Assure that no value is nullptr.
	if (std::any_of(vals2.begin(), vals2.end(), [](std::shared_ptr<SingleValue>& ptr) {
		return ptr == nullptr;
	}))
		throw std::runtime_error("Unexpected error");

	bool hasFloat = std::any_of(vals2.begin(), vals2.end(), [](std::shared_ptr<SingleValue>& ptr) {
		return ptr->isFloat();
	});

	std::vector<std::int64_t> intVal;
	std::vector<double> floatVal;
	switch (this->op) {
		default:
			throw std::runtime_error("Unexpected error");
		case LOGAND:
		case LOGIOR:
		case LOGXOR:
		case LOGEQV:
			if (hasFloat)
				throw std::runtime_error("Cannot apply selected operator to non-integer");
			std::transform(vals2.begin(), vals2.end(), std::back_inserter(intVal), [&](std::shared_ptr<SingleValue>& ptr) {
				return ptr->getInt();
			});
			return std::make_shared<SingleValue>(std::accumulate(intVal.begin() + 1, intVal.end(), intVal[0], [this](std::int64_t x, std::int64_t y) {
				switch (this->op) {
					case LOGAND:
						return x & y;
					case LOGIOR:
						return x | y;
					case LOGXOR:
						return x ^ y;
					case LOGEQV:
						return ~(x ^ y);
					default:
						throw std::runtime_error("Unexpected error");
				}
			}));
		case MAX:
			return std::max_element(vals2.begin(), vals2.end(), [](std::shared_ptr<SingleValue>& x, std::shared_ptr<SingleValue>& y) {
				return (x->isFloat() ? x->getFloat() : x->getInt()) < (y->isFloat() ? y->getFloat() : y->getInt());
			})->operator->()->copy();
		case MIN:
			return std::min_element(vals2.begin(), vals2.end(), [](std::shared_ptr<SingleValue>& x, std::shared_ptr<SingleValue>& y) {
				return (x->isFloat() ? x->getFloat() : x->getInt()) < (y->isFloat() ? y->getFloat() : y->getInt());
			})->operator->()->copy();
		case EQUAL:
			return std::all_of(vals2.begin() + 1, vals2.end(), [&](std::shared_ptr<SingleValue>& ptr) {
				return ptr->operator==(*vals2[0]);
			}) ? std::make_shared<SingleValue>(true) : std::make_shared<SingleValue>(false);
		case NOT_EQUAL:
			return !std::all_of(vals2.begin() + 1, vals2.end(), [&](std::shared_ptr<SingleValue>& ptr) {
				return ptr->operator==(*vals2[0]);
			}) ? std::make_shared<SingleValue>(true) : std::make_shared<SingleValue>(false);
		case PLUS:
		case MINUS:
		case MULTIPLY:
		case DIVIDE:
			auto opFunc = [this](auto x, auto y) {
				switch (this->op) {
					case PLUS:
						return x + y;
					case MINUS:
						return x - y;
					case MULTIPLY:
						return x * y;
					case DIVIDE:
						return x / y;
					default:
						throw std::runtime_error("Unexpected error");
				}
			};
			if (hasFloat) {
				std::transform(vals2.begin(), vals2.end(), std::back_inserter(floatVal), [&](std::shared_ptr<SingleValue>& ptr) {
					return (ptr->isFloat() ? ptr->getFloat() : ptr->getInt());
				});
				return std::make_shared<SingleValue>(std::accumulate(floatVal.begin() + 1, floatVal.end(), floatVal[0], opFunc));
			} else {
				std::transform(vals2.begin(), vals2.end(), std::back_inserter(intVal), [&](std::shared_ptr<SingleValue>& ptr) {
					return ptr->getInt();
				});
				return std::make_shared<SingleValue>(std::accumulate(intVal.begin() + 1, intVal.end(), intVal[0], opFunc));
			}
	}

}

std::shared_ptr<Value> VarOpAST::eval(Context* parent) {
	// DEFVAR || SETQ
	if (this->op == SETQ && !parent->hasVariable(this->name)) {
		throw std::runtime_error("Variable not defined: " + this->name);
	}

	// Eval value
	auto val = this->expr->eval(parent);
	parent->setVariable(this->name, val->copy());
	return val;
}

std::shared_ptr<Value> LValOpAST::eval(Context* parent) {
	// Eval value
	auto val = this->expr->eval(parent);
	auto lv = std::dynamic_pointer_cast<LValueAST>(this->lval);
	if (!lv)
		throw std::runtime_error("Unexpected error");

	if (SETF == this->op)
		return lv->set(parent, val);

	auto original = lv->eval(parent);
	auto originalVal = std::dynamic_pointer_cast<SingleValue>(original);
	if (original->isArray() || !originalVal || !originalVal->isInt())
		throw std::runtime_error("Cannot apply INC or DEC to non-integer value");
	auto base = originalVal->getInt();

	auto valVal = std::dynamic_pointer_cast<SingleValue>(val);
	if (val->isArray() || !valVal || !valVal->isInt())
		throw std::runtime_error("Cannot INC or DEC by non-integer value");
	auto delta = valVal->getInt();

	switch (this->op) {
		case DECF:
			delta = -delta;
		case INCF:
			base += delta;
			return lv->set(parent, std::make_shared<SingleValue>(base));
		default:;
	}
	throw std::runtime_error("Unexpected error");
}

std::shared_ptr<Value> ReturnAST::eval(Context* parent) {
	return this->expr->eval(parent);
}

} // end of namespace DragonLisp

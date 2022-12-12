#ifndef __DRAGON_LISP_CONTEXT_H__
#define __DRAGON_LISP_CONTEXT_H__

#include <memory>
#include <variant>

#include "value.h"

namespace DragonLisp {

class FuncDefAST;

class Context {
private:
	std::unordered_map<std::string, std::shared_ptr<Value>> variables;

	Context* parent = nullptr;

	std::unordered_map<std::string, std::shared_ptr<FuncDefAST>>* funcs = nullptr;

public:
	explicit Context(Context* p = nullptr) : parent(p) {
		this->funcs = p ? p->funcs : new std::unordered_map<std::string, std::shared_ptr<FuncDefAST>>;
	}

	~Context() {
		if (!this->parent)
			delete this->funcs;
	}

	std::shared_ptr<Value> getVariable(const std::string& name) const {
		if (this->variables.contains(name))
			return this->variables[name];
		if (this->parent)
			return this->parent->getVariable(name);
		return nullptr;
	}

	void setVariable(const std::string& name, std::shared_ptr<Value> value) {
		this->variables[name] = std::move(value);
	}
};

}

#endif // __DRAGON_LISP_CONTEXT_H__

#ifndef __DRAGON_LISP_CONTEXT_H__
#define __DRAGON_LISP_CONTEXT_H__

#include <memory>
#include <utility>
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
			return this->variables.at(name);
		if (this->parent)
			return this->parent->getVariable(name);
		return nullptr;
	}

	void setVariable(const std::string& name, std::shared_ptr<Value> value) {
		this->variables[name] = std::move(value);
	}

	bool hasVariable(const std::string& name) const {
		if (this->variables.contains(name))
			return true;
		if (this->parent)
			return this->parent->hasVariable(name);
		return false;
	}

	std::shared_ptr<FuncDefAST> getFunc(const std::string& name) const {
		if (this->funcs->contains(name))
			return (*this->funcs)[name];
		return nullptr;
	}

	void setFunc(const std::string& name, std::shared_ptr<FuncDefAST> value) {
		(*this->funcs)[name] = std::move(value);
	}

	Context* getParent() const {
		return this->parent;
	}
};

}

#endif // __DRAGON_LISP_CONTEXT_H__

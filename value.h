#ifndef __DRAGON_LISP_VALUE_H__
#define __DRAGON_LISP_VALUE_H__

#include <variant>
#include <cstdint>
#include <string>

#include "types.h"

namespace DragonLisp {

using ValueVariant = std::variant<std::monostate, std::int64_t, double, std::string>;

class Value {
public:
	virtual bool isArray() const = 0;
};

class ArrayValue : public Value {
private:
	std::vector<ValueVariant> values;

	std::size_t size;

public:
	ArrayValue() = delete;

	explicit ArrayValue(std::size_t s) : values(s), size(s) {}

	explicit ArrayValue(std::vector<ValueVariant> v) : values(std::move(v)), size(this->values.size()) {}

	bool isArray() const override final {
		return true;
	}

	std::size_t getSize() const {
		return this->size;
	}

	ValueVariant& operator[](std::size_t i) {
		return this->values[i];
	}

	const ValueVariant& operator[](std::size_t i) const {
		return this->values[i];
	}

	std::vector<ValueVariant>& getValues() {
		return this->values;
	}

	const std::vector<ValueVariant>& getValues() const {
		return this->values;
	}
};

class SingleValue : public Value {
private:
	ValueType type;

	ValueVariant value;

	explicit SingleValue(ValueType t) : type(t), value() {}

public:
	explicit SingleValue(std::int64_t v) : value(v) {}

	explicit SingleValue(double v) : value(v) {}

	explicit SingleValue(std::string v) : value(std::move(v)) {}

	SingleValue() = delete;

	bool isArray() const override final {
		return false;
	}

	static SingleValue makeT() {
		return SingleValue(ValueType::TYPE_T);
	}

	static SingleValue makeNil() {
		return SingleValue(ValueType::TYPE_NIL);
	}

	ValueType getType() const {
		return this->type;
	}

	bool isT() const {
		return this->type == ValueType::TYPE_T;
	}

	bool isNil() const {
		return this->type == ValueType::TYPE_NIL;
	}

	bool isInt() const {
		return std::holds_alternative<std::int64_t>(this->value);
	}

	bool isFloat() const {
		return std::holds_alternative<double>(this->value);
	}

	bool isString() const {
		return std::holds_alternative<std::string>(this->value);
	}

	std::int64_t getInt() const {
		return std::get<std::int64_t>(this->value);
	}

	double getFloat() const {
		return std::get<double>(this->value);
	}

	std::string getString() const {
		return std::get<std::string>(this->value);
	}

	ValueVariant getValue() const {
		return this->value;
	}

	void setValue(ValueVariant v) {
		this->value = std::move(v);
	}
};

class _Unused_Variable {
protected:
	std::string name;

	std::variant<ArrayValue, SingleValue> val;

public:
	_Unused_Variable() = delete;

	_Unused_Variable(std::string n, SingleValue v) : name(std::move(n)), val(std::move(v)) {}

	_Unused_Variable(std::string n, ArrayValue v) : name(std::move(n)), val(std::move(v)) {}

	std::string getName() const {
		return this->name;
	}

	bool isArray() const {
		return std::holds_alternative<ArrayValue>(this->val);
	}

	bool isValue() const {
		return std::holds_alternative<SingleValue>(this->val);
	}

	ArrayValue getArray() const {
		return std::get<ArrayValue>(this->val);
	}

	SingleValue getValue() const {
		return std::get<SingleValue>(this->val);
	}

	void set(SingleValue v) {
		this->val = std::move(v);
	}

	void set(ArrayValue v) {
		this->val = std::move(v);
	}
};

}

#endif // __DRAGON_LISP_VALUE_H__

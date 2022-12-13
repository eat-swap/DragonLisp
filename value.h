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

	virtual std::shared_ptr<Value> copy() const = 0;

	virtual std::string toString() const = 0;
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

	explicit SingleValue(bool v) : type(v ? TYPE_T : TYPE_NIL), value() {}

	SingleValue() : SingleValue(ValueType::TYPE_NIL) {}

	bool isArray() const override final {
		return false;
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

	std::shared_ptr<Value> copy() const override final {
		return std::make_shared<SingleValue>(*this);
	}

	std::string toString() const override final {
		if (this->isInt())
			return std::to_string(this->getInt());
		if (this->isFloat())
			return std::to_string(this->getFloat());
		if (this->isString())
			return this->getString();
		if (this->isT())
			return "T";
		return "NIL";
	}

	bool operator==(const SingleValue& rhs) const {
		return type == rhs.type && value == rhs.value;
	}

	bool operator<(const SingleValue& rhs) const {
		if ((!this->isInt() && !this->isFloat()) || (!rhs.isInt() && !rhs.isFloat()))
			throw std::runtime_error("Cannot compare non-numeric values");
		if (this->isInt() && rhs.isInt())
			return this->getInt() < rhs.getInt();
		if (this->isInt())
			return this->getInt() < rhs.getFloat();
		if (rhs.isInt())
			return this->getFloat() < rhs.getInt();
		return this->getFloat() < rhs.getFloat();
	}

	bool operator<=(const SingleValue& rhs) const {
		if ((!this->isInt() && !this->isFloat()) || (!rhs.isInt() && !rhs.isFloat()))
			throw std::runtime_error("Cannot compare non-numeric values");
		if (this->isInt() && rhs.isInt())
			return this->getInt() <= rhs.getInt();
		if (this->isInt())
			return this->getInt() <= rhs.getFloat();
		if (rhs.isInt())
			return this->getFloat() <= rhs.getInt();
		return this->getFloat() <= rhs.getFloat();
	}

	SingleValue& operator++() {
		if (this->isInt())
			this->value = this->getInt() + 1;
		else if (this->isFloat())
			this->value = this->getFloat() + 1;
		else
			throw std::runtime_error("Cannot increment non-numeric value");
		return *this;
	}

	SingleValue& operator--() {
		if (this->isInt())
			this->value = this->getInt() - 1;
		else if (this->isFloat())
			this->value = this->getFloat() - 1;
		else
			throw std::runtime_error("Cannot decrement non-numeric value");
		return *this;
	}

	SingleValue operator++(int) {
		SingleValue tmp(*this);
		operator++();
		return tmp;
	}

	SingleValue operator--(int) {
		SingleValue tmp(*this);
		operator--();
		return tmp;
	}
};

class ArrayValue : public Value {
private:
	std::vector<SingleValue> values;

	std::size_t size;

public:
	ArrayValue() = delete;

	explicit ArrayValue(std::size_t s) : values(s), size(s) {}

	explicit ArrayValue(std::vector<SingleValue> v) : values(std::move(v)), size(this->values.size()) {}

	bool isArray() const override final {
		return true;
	}

	std::size_t getSize() const {
		return this->size;
	}

	SingleValue operator[](std::size_t i) const {
		return this->values[i];
	}

	void set(std::size_t i, SingleValue v) {
		this->values[i] = std::move(v);
	}

	std::vector<SingleValue>& getValues() {
		return this->values;
	}

	const std::vector<SingleValue>& getValues() const {
		return this->values;
	}

	std::shared_ptr<Value> copy() const override final {
		return std::make_shared<ArrayValue>(*this);
	}

	std::string toString() const override final {
		std::string result = "[";
		for (const auto& i : this->values)
			result.append(i.toString()).append(", ");
		result.pop_back();
		result.back() = ']';
		return result;
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

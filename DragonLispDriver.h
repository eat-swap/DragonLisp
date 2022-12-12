#ifndef __DRAGON_LISP_DRIVER_H__
#define __DRAGON_LISP_DRIVER_H__

#include <string>
#include <istream>

#include "DragonLispScanner.h"
#include "DragonLisp.tab.hh"

namespace DragonLisp {

class DLDriver {
public:
	DLDriver() = default;
	virtual ~DLDriver();

	int parse(const std::string& f);
	int parse(std::istream& in, const std::string& s = "stream input");

	void error(const DLParser::location_type& l, const std::string& m);
	void error(const std::string& m);

private:
	DLParser* parser = nullptr;
	DLScanner* scanner = nullptr;
	DragonLisp::location location;
};

} // end namespace DragonLisp

#endif // __DRAGON_LISP_DRIVER_H__

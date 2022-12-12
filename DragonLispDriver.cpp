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

	this->parser->set_debug_level(1);
	return this->parser->parse();
}

} // end namespace DragonLisp

#! /usr/bin/sed -nEf
# This is the script to make an API document for deployment in the S4A app
# bundle to display as part of documentation "API documentation".
# Note: there will also be a built in on the fly version in Swift code that
# will read included libraries for API reference and add that (or new pages)
# and will extract code snippets.

# This attempts to summarise the interface that the AVR module will present
# when imported, both from its swift code and imported c code via the
# clang importer

# things to extract:
# 1) public typealises
# 2) global constants defined using extern const
# 3) global constants defined using #define
# 4) method definitions directly preceded by swiftdoc comments ///

# 1) typealiases
/^[^\/]*public typealias/{
  a\
  --------------------------------------------------------\

	p
}

# 2) global constants
# extended regex version
/^extern const/s/extern const _Bool ([A-Za-z_0-9]*);/let \1: Bool = constant/p
/^extern const/s/extern const unsigned char ([A-Za-z_0-9]*);/let \1: UInt8 = constant/p
/^extern const/s/extern const unsigned short ([A-Za-z_0-9]*);/let \1: UInt16 = constant/p
/^extern /s/extern iLEDColor ([A-Za-z_0-9]*);/let \1: iLEDColor = constant/p

# 3) global constants that are defines that resolve to simple numbers
# two forms are recognised, just simple numbers
# and numbers that are cast as another type first
/^#define ([[:alnum:]_]+) ([0-9]+)/s/#define ([[:alnum:]_]+) ([0-9]+)/let \1 = \2/p
/^#define ([[:alnum:]_]+) [(]unsigned char[)]([0-9]+)/s/#define ([[:alnum:]_]+) [(]unsigned char[)]([0-9]+)/let \1: UInt8 = \2/p
/^#define ([[:alnum:]_]+) [(]_Bool[)]([0-9]+)/s/#define ([[:alnum:]_]+) [(]_Bool[)]([0-9]+)/let \1: Bool = \2/p

# 4) method definitions with preceding swiftdoc
/\/\/\//,/[{]/{ 
	/[{}]/{
	  s/[{]//
	  a\ 
	  --------------------------------------------------------\   
	}
	s/^[[:space:]]+/	/
	p
}
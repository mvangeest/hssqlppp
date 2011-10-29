
# you can build the library using cabal configure && cabal build
# more info here: http://jakewheat.github.com/hssqlppp/devel.txt.html

# the default make target is to build the automated tests exe

# stuff to add:
# build the lib using cabal
# do stuff with chaos:
#   build the 'compiler' exe only
#   produce the transformed sql
#   load the sql into pg
#   output stuff: typecheck, documentation#
# h7c stuff: needs some thought
# get the chaos sql transformation documentation working again

# want to avoid editing source or the commands to try different things
# in development
# how can have better control over conditionally compiling in different
#   test modules?

# todo: find something better than make

# this makefile is probably written wrong since I don't know how to do
# makefiles

HC              = ghc
HC_BASIC_OPTS   = -Wall -XTupleSections -XScopedTypeVariables -XDeriveDataTypeable \
		  -threaded -rtsopts
HC_INCLUDE_DIRS = -isrc:src-extra/util:src-extra/tests/:src-extra/devel-util \
		  -isrc-extra/chaos:src-extra/chaos/extensions/:src-extra/examples \
		  -isrc-extra/h7c:src-extra/tosort/util/:src-extra/extensions \
	          -isrc-extra/h7c:src-extra/chaos/extensions
HC_PACKAGES = -package haskell-src-exts -package uniplate -package mtl \
	-package base -package containers -package parsec -package pretty \
	-package syb -package transformers -package template-haskell \
	-package test-framework -package groom -package test-framework-hunit \
	-package HUnit -package HDBC -package HDBC-postgresql \
	-package pandoc -package xhtml -package illuminate -package datetime


HC_OPTS = $(HC_BASIC_OPTS) $(HC_INCLUDE_DIRS) $(HC_PACKAGES)

# this is the list of exe files which are all compiled to check
# nothing has been broken. It doesn't include some of the makefile
# utilities below
# the set of .o files for each exe, and the build rule are generated
# by a utility (use make exe_depend) since ghc -M doesn't provide
# the list of .o files which an .lhs for an exe needs to build
# (ghc -M is used for all the dependencies other than the exes)
EXE_FILES = src-extra/tests/Tests \
	src-extra/devel-util/MakeAntiNodesRunner \
	src-extra/devel-util/MakeDefaultTemplate1Catalog \
	src-extra/examples/FixSqlServerTpchSyntax \
	src-extra/examples/MakeSelect \
	src-extra/examples/Parse \
	src-extra/examples/Parse2 \
	src-extra/examples/QQ \
	src-extra/examples/ShowCatalog \
	src-extra/examples/TypeCheck \
	src-extra/examples/TypeCheckDB \
	src-extra/tosort/util/DevelTool \
	src-extra/h7c/h7c

#	src-extra/chaos/build.lhs

# used for dependency generation with ghc -M
# first all the modules which are public in the cabal package
# this is all the hs files directly in the src/Database/HsSqlPpp/ folder
# then it lists the lhs for all the exe files
SRCS_ROOTS = $(shell find src/Database/HsSqlPpp/ -maxdepth 1 -iname '*hs') \
	     $(addsuffix .lhs,$(EXE_FILES))

AG_FILES = $(shell find src -iname '*ag')

# include the autogenerated rules for the exes
-include exe_rules.mk


#special targets

# run the tests
tests : src-extra/tests/Tests
	src-extra/tests/Tests --hide-successes

# make the website
website : src-extra/tosort/util/DevelTool
	src-extra/tosort/util/DevelTool makewebsite +RTS -N

# make the haddock and put in the correct place in the generated
# website
website_haddock :
	cabal configure
	cabal haddock
	mv dist/doc/html/hssqlppp hssqlppp/haddock

# task to build the chaos sql, which takes the source sql
# transforms it and produces something which postgres understands
CHAOS_SQL_SRC = $(shell find src-extra/chaos/sql/ -iname '*.sql')

chaos.sql : $(CHAOS_SQL_SRC) src-extra/h7c/h7c
	src-extra/h7c/h7c > chaos.sql


# targets mainly used to check everything builds ok
all : $(EXE_FILES)

more_all : all website website_haddock tests


# generic rules

%.hi : %.o
	@:

%.o : %.lhs
	$(HC) $(HC_OPTS) -c $<

%.o : %.hs
	$(HC) $(HC_OPTS) -c $<

# dependency and rules for exe autogeneration:

exe_depend : src-extra/devel-util/GenerateExeRules.lhs Makefile
	ghc -isrc-extra/devel-util src-extra/devel-util/GenerateExeRules.lhs
	src-extra/devel-util/GenerateExeRules

depend :
	ghc -M $(HC_OPTS) $(SRCS_ROOTS) -dep-makefile .depend

#specific rules for generated files: astanti.hs and astinternal.hs

src/Database/HsSqlPpp/Internals/AstAnti.hs : \
		src/Database/HsSqlPpp/Internals/AstInternal.hs \
		src-extra/devel-util/MakeAntiNodesRunner
	src-extra/devel-util/MakeAntiNodesRunner

src/Database/HsSqlPpp/Internals/AstInternal.hs : $(AG_FILES)
	uuagc  -dcfwsp -P src/Database/HsSqlPpp/Internals/ \
		src/Database/HsSqlPpp/Internals/AstInternal.ag

# rule for the generated file
# src/Database/HsSqlPpp/Internals/Catalog/DefaultTemplate1Catalog.lhs
# don't want to automatically keep this up to date, only regenerate it
# manually

regenDefaultTemplate1Catalog : src-extra/devel-util/MakeDefaultTemplate1Catalog
	src-extra/devel-util/MakeDefaultTemplate1Catalog > \
		src/Database/HsSqlPpp/Internals/Catalog/DefaultTemplate1Catalog.lhs_new
	mv src/Database/HsSqlPpp/Internals/Catalog/DefaultTemplate1Catalog.lhs_new \
		src/Database/HsSqlPpp/Internals/Catalog/DefaultTemplate1Catalog.lhs

.PHONY : clean
clean :
	-rm -Rf dist
	find . -iname '*.o' -delete
	find . -iname '*.hi' -delete
	-rm chaos.sql
	-rm $(EXE_FILES)
	-rm -Rf hssqlppp

# include the ghc -M dependencies
-include .depend

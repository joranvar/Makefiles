.PHONY: default
default: all

MAKE_toolsDir ?= tools
MAKE_binDir   ?= bin
MAKE_objDir   ?= obj
MAKE_utilsDir ?= .

NUGET_nugetDir ?= lib/NuGet
include $(MAKE_utilsDir)/NuGet.mk
NUNIT_testDir ?= test
include $(MAKE_utilsDir)/NUnit.mk
include $(MAKE_utilsDir)/CSharp.mk

vpath %.cs src

# Assemblies
Unit.dll = $(call CSHARP_mkDllTarget,test/Unit.dll)

# Test assemblies
UNITTEST = $(call NUNIT_mkTestTarget,$(Unit.dll))

# Dependencies
$(Unit.dll): Unit.cs

.PHONY: all
all: $(UNITTEST)

.PHONY: clean
clean: cleanall

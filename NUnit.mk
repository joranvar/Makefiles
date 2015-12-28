TESTDIR ?= test/

include Makefiles/NuGet.mk

nunit.console = $(NUGETDIR)NUnit.Console/
nunit.console.nupkg = NUnit.Console.nupkg
nunit.console.runner = $(NUGETDIR)NUnit.Console/tools/nunit3-console.exe

.PHONY: nunit
nunit: $(nunit.console.nupkg) unit | $(TESTDIR)

$(nunit.console): $(nunit.console.nupkg)
	mkdir -p $(TESTDIR)

.PHONY: unit
unit: $(addsuffix .success, $(UNITTESTS))

%.dll.success: %.dll
	$(MONO) $(nunit.console.runner) $? --result=$@

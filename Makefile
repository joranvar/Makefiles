TESTDIR ?= test/
UNITTESTS ?= $(TESTDIR)Unit.dll
NUGETDIR ?= lib/
TOOLSDIR ?= tools/

.PHONY: all clean xunit acceptance unit

VPATH = src

all: xunit

include CSharp.mk

# Depend on xunit.console.runner
xunit.runner.console = $(NUGETDIR)xunit.runner.console/tools/xunit.console.exe
xunit.runner.console.nupkg = xunit.runner.console.nupkg

xunit.nupkg = xunit/2.0.nupkg
xunit.nupkg += $(NUGETDIR)xunit.extensibility.core/lib/portable-net45+win+wpa81+wp80+monotouch+monoandroid+Xamarin.iOS/xunit.core.dll

xunit: $(xunit.runner.console) unit acceptance | $(TESTDIR)

$(xunit.runner.console): $(xunit.runner.console.nupkg) $(xunit.nupkg)
	mkdir -p $(TESTDIR)
	cp $(NUGETDIR)xunit.core/build/portable-win81+wpa81/xunit.execution.universal.dll $(TESTDIR)

unit: $(addsuffix .success, $(UNITTESTS))

%.dll.success: %.dll
	$(MONO) $(xunit.runner.console) $? && touch $@

test/Unit.dll: $(xunit.nupkg)

# Define nuget and nugetclean targets
include NuGet.mk

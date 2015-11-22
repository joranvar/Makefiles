CURL ?= env curl
MONO ?= env mono

NUGETDIR ?= lib/NuGet/
TOOLSDIR ?= tools/

NUGET = $(TOOLSDIR)nuget/NuGet.exe

install_nuget: $(NUGET)

$(NUGET): | $(dir $(NUGET))
	$(CURL) -SsL https://www.nuget.org/nuget.exe -o $@

# Nuget dependency template
%.nupkg: PKGNAME = $(basename $(firstword $(subst /, ,$@)))
%.nupkg: VERSION = $(basename $(word 2,$(subst /, ,$@)))
%.nupkg: | $(NUGET)
	[ -d $(NUGETDIR)$(PKGNAME) ] || $(MONO) $(NUGET) install $(PKGNAME) -ExcludeVersion -OutputDirectory $(NUGETDIR) -Verbosity quiet $(if $(VERSION),-Version $(VERSION))

nugetclean:
	$(RM) -r $(NUGETDIR)

# How to make a directory
%/:
	mkdir -p $@

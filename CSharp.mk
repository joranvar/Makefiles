CC.cs ?= env mcs
System.dll ?= $(wildcard /nix/store/q3yf6a3ysjv0zgad9v2rb3rvllhih8l6-mono-4.0.3.20/lib/mono/4.5/Facades/*.dll)
OUTDIR ?= bin/

$(OUTDIR)%.dll: %.cs
	echo $?
	mkdir -p $(@D)
	@$(CC.cs) $(filter %.cs,$^) $(addprefix -r:,$(filter %.dll,$^)) -out:$@ -t:library -pkg:dotnet
	if [ '$(filter %.dll,$^)x' != 'x' ]; then cp -u $(filter %.dll,$^) $(@D); fi

$(OUTDIR)%.exe: %.cs
	echo $?
	mkdir -p $(@D)
	@$(CC.cs) $(filter %.cs,$^) $(addprefix -r:,$(filter %.dll,$^)) -out:$@ -pkg:dotnet
	if [ '$(filter %.dll,$^)x' != 'x' ]; then cp -u $(filter %.dll,$^) $(@D); fi
	@cp -u $(System.dll) $(@D)

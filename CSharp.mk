CC.cs ?= env mcs
System.dll ?= $(wildcard /nix/store/q3yf6a3ysjv0zgad9v2rb3rvllhih8l6-mono-4.0.3.20/lib/mono/4.5/Facades/*.dll)

%.dll: %.cs #$(System.dll)
	mkdir -p $(@D)
	@$(CC.cs) $(filter %.cs,$^) $(addprefix -r:,$(filter %.dll,$^)) -out:$@ -t:library -pkg:dotnet
#	@cp -u $(filter %.dll,$^) $(@D)

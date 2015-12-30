CC.fs ?= env fsharpc
FSharp.Core.dll ?= /nix/store/9nvx5380w2md40yzr63hbyh22aafsw4j-fsharp-3.1.2.5/lib/mono/4.5/FSharp.Core.dll
OUTDIR ?= bin/

$(OUTDIR)%.dll: %.fs
	mkdir -p $(@D)
	$(CC.fs) $(filter-out $<,$(filter %.fs,$^)) $< $(addprefix -r:,$(filter %.dll,$^)) -o $@ -a --nologo

$(OUTDIR)%.exe: %.fs
	mkdir -p $(@D)
	$(CC.fs) $(filter-out $<,$(filter %.fs,$^)) $< $(addprefix -r:,$(filter %.dll,$^)) -o $@ --nologo
	if [ '$(filter %.dll,$^)x' != 'x' ]; then cp -u $(filter %.dll,$^) $(@D); fi
	cp -u $(FSharp.Core.dll) $(@D)

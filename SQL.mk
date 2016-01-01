SQLSTART ?= echo "Starting SQL"
SQSH_FLAGS ?=
SQSH_OUTPUT_FLAGS ?= -mcsv
CC.sql ?= env sqsh
OUTDIR ?= bin/

$(OUTDIR)%.db: DB_NAME = $(notdir $(basename $@))
$(OUTDIR)%.db: create_%.sql
	mkdir -p $(@D)
	$(SQLSTART)
	-$(CC.sql) $(SQSH_FLAGS) -C"DROP DATABASE $(DB_NAME);"
	$(CC.sql) $(SQSH_FLAGS) -C"CREATE DATABASE $(DB_NAME);"
	$(CC.sql) $(SQSH_FLAGS) $(SQSH_OUTPUT_FLAGS) -D$(DB_NAME) $(addprefix -i,$^) -e -o$@

#CC = gcc
#RM = rm
#AR = ar
LN = ln
INSTALL = install
MKDIR = mkdir
CP = cp
FMT = clang-format

DIR_BUILD = .build
DIR_INCLUDES = include
prefix = /usr/local

PPFLAGS = -MT $@ -MMD -MP -MF $(patsubst %.o, %.d, $@) -I$(DIR_INCLUDES)

CFLAGS_LOCAL = -Wall -g -std=c99 -coverage
CFLAGS_LOCAL += $(CFLAGS)

VALGRIND = valgrind --leak-check=full --show-leak-kinds=all

APP_SOURCES = sample.c
APP_OBJECTS = $(patsubst %.c, %.o, $(APP_SOURCES))
APP = at

LIB_INCLUDES = include/at/at_command.h \
        include/at/at_fsm.h \
        include/at/at_param.h \
        include/at/at_table.h \
        include/at/internal/at_xrecord.h \
        include/at/internal/hash.h \
        include/at/internal/queue.h \
        include/at/internal/stdlog.h
LIB_SOURCES = src/at_command.c \
        src/at_fsm.c \
        src/at_param.c \
        src/at_table.c \
        src/at_xrecord.c \
        src/hash.c \
        src/queue.c \
        src/stdlog.c
LIB_OBJECTS = $(patsubst %.c, %.o, $(LIB_SOURCES))
LIB_VERSION = 0.0.1
LIB_NAME = at
LIB_SO = lib$(LIB_NAME).so.$(LIB_VERSION)
LIB_A = lib$(LIB_NAME).a.$(LIB_VERSION)

DEPFILES = $(patsubst %.o, %.d, $(addprefix $(DIR_BUILD)/, $(APP_OBJECTS)) $(addprefix $(DIR_BUILD)/, $(LIB_OBJECTS)))

.PHONY : all clean install uninstall test fmt

all : $(DIR_BUILD)/$(APP)

$(DIR_BUILD)/$(APP) : $(addprefix $(DIR_BUILD)/, $(APP_OBJECTS)) $(DIR_BUILD)/$(LIB_SO) $(DIR_BUILD)/$(LIB_A) Makefile | $(DIR_BUILD)
	$(CC) $(CFLAGS_LOCAL) -o $@ ${addprefix $(DIR_BUILD)/, $(APP_OBJECTS)} -L$(shell pwd)/$(DIR_BUILD) -l$(LIB_NAME)

$(DIR_BUILD)/lib$(LIB_NAME).so : $(DIR_BUILD)/$(LIB_SO)
	$(LN) -sf $(shell pwd)/$< $@

$(DIR_BUILD)/$(LIB_SO) : $(addprefix $(DIR_BUILD)/, $(LIB_OBJECTS)) Makefile | $(DIR_BUILD)
	$(CC) $(CFLAGS_LOCAL) -shared -o $@ $(filter %.o, $^)

$(DIR_BUILD)/lib$(LIB_NAME).a : $(DIR_BUILD)/$(LIB_A)
	$(LN) -sf $(shell pwd)/$< $@

$(DIR_BUILD)/$(LIB_A) : $(addprefix $(DIR_BUILD)/, $(LIB_OBJECTS)) Makefile | $(DIR_BUILD)
	$(AR) $(ARFLAGS) $@ $(filter %.o, $^)

$(addprefix $(DIR_BUILD)/, $(APP_OBJECTS)) : $(DIR_BUILD)/%.o : %.c Makefile | $(DIR_BUILD)
	$(MKDIR) -p $(@D)
	$(CC) $(PPFLAGS) $(CFLAGS_LOCAL) -c $< -o $@

$(addprefix $(DIR_BUILD)/, $(LIB_OBJECTS)) : $(DIR_BUILD)/%.o : %.c Makefile | $(DIR_BUILD)
	$(MKDIR) -p $(@D)
	$(CC) $(PPFLAGS) $(CFLAGS_LOCAL) -fPIC -c $< -o $@

$(DIR_BUILD)/%.d : ;
.PRECIOUS : $(DIR_BUILD)/%.d

$(DIR_BUILD) : 
	$(MKDIR) -p $@

install : all
	$(INSTALL) -d "$(prefix)/lib"
	$(INSTALL) "$(DIR_BUILD)/$(LIB_SO)" "$(prefix)/lib"
	$(LN) -sf "$(prefix)/lib/$(LIB_SO)" "$(prefix)/lib/lib$(LIB_NAME).so"
	$(INSTALL) "$(DIR_BUILD)/$(LIB_A)" "$(prefix)/lib"
	$(LN) -sf "$(prefix)/lib/$(LIB_A)" "$(prefix)/lib/lib$(LIB_NAME).a"
	$(INSTALL) -d "$(prefix)/bin"
	$(INSTALL) "$(DIR_BUILD)/$(APP)" "$(prefix)/bin"
	$(INSTALL) -d "$(prefix)/include"
	$(CP) -r $(DIR_INCLUDES)/* "$(prefix)/include/"

uninstall :
	$(RM) -f  "$(prefix)/lib/$(LIB_SO)"
	$(RM) -f  "$(prefix)/lib/lib$(LIB_NAME).so"
	$(RM) -f  "$(prefix)/lib/$(LIB_A)"
	$(RM) -f  "$(prefix)/lib/lib$(LIB_NAME).a"
	$(RM) -f  "$(prefix)/bin/$(APP)"
	$(RM) -rf "$(prefix)/include/$(LIB_NAME)"

test :
	$(VALGRIND) $(APP) -h
	$(VALGRIND) $(APP) -f test.at > log && diff log stdlog

clean :
	$(RM) -rf $(DIR_BUILD)

fmt :
	$(FMT) -i --style=file $$(find . -type f \( -name '*.c' -o -name '*.h' \))

include $(DEPFILES)

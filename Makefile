CFLAGS=-g -Wall -Wshadow -Wcast-align -Wredundant-decls -Wbad-function-cast -Wcast-qual -Wwrite-strings -Waggregate-return -Wstrict-prototypes -Wmissing-prototypes 

PACKAGE=cpuid
VERSION=$(shell date +%Y%m%d)
RELEASE=1
ARCH=i386

PROG=$(PACKAGE)

SRC_TAR=$(PACKAGE)-$(VERSION).src.tar.gz
BIN_TAR=$(PACKAGE)-$(VERSION).$(ARCH).tar.gz
RPMS=$(PACKAGE)-$(VERSION)-$(RELEASE).src.rpm \
     $(PACKAGE)-$(VERSION)-$(RELEASE).$(ARCH).rpm
DEBUG_RPM=$(PACKAGE)-debuginfo-$(VERSION)-$(RELEASE).$(ARCH).rpm

SRCS=cpuid.c

OTHER_SRCS=Makefile cpuid.man cpuid.spec

REL_DIR=../$(shell date +%Y-%m-%d)
WEB_DIR=/toad1/apps.mine/web/$(PROG)

DEV_X86_64_HOST=iggy

default: $(PROG)

# Todd's Development rules

cpuid.x86_64: cpuid.c
	scp -p cpuid.c $(DEV_X86_64_HOST):/tmp
	ssh $(DEV_X86_64_HOST) $(CC) $(CFLAGS) -o /tmp/cpuid /tmp/cpuid.c
	scp -p $(DEV_X86_64_HOST):/tmp/cpuid $@

install: cpuid cpuid.x86_64
	cp -p cpuid ~/.bin/execs/i586/cpuid
	cp -p cpuid.x86_64 ~/.bin/execs/x86_64/cpuid
	(cd ~/.bin/execs; prop i586/cpuid x86_64/cpuid)

clean:
	rm -f $(PROG) cpuid.x86_64

# Release rules

$(SRC_TAR): $(SRCS) $(OTHER_SRCS) Makefile
	@echo Tarring source
	@rm -rf $(PACKAGE)-$(VERSION)
	@mkdir $(PACKAGE)-$(VERSION)
	@ls -1d $(SRCS) $(OTHER_SRCS) | cpio -pdmuv $(PACKAGE)-$(VERSION)
	@tar cvf - $(PACKAGE)-$(VERSION) | gzip -c >| $(SRC_TAR)
	@rm -rf $(PACKAGE)-$(VERSION)

$(BIN_TAR): $(PROG) cpuid.man
	@echo Tarring binary
	@rm -rf $(PACKAGE)-$(VERSION)
	@mkdir $(PACKAGE)-$(VERSION)
	@ls -1d $(PROG) cpuid.man | cpio -pdmuv $(PACKAGE)-$(VERSION)
	@(cd $(PACKAGE)-$(VERSION); strip $(PROG))
	@tar cvf - $(PACKAGE)-$(VERSION) | gzip -c >| $(BIN_TAR)
	@rm -rf $(PACKAGE)-$(VERSION)

tar: $(SRC_TAR) $(BIN_TAR)

$(RPMS) $(DEBUG_RPM): $(SRC_TAR) $(PACKAGE).spec
	@echo Building RPMs
	@rm -rf build
	@mkdir build
	@rpmbuild -ba \
	          --define "version $(VERSION)" \
	          --define "release $(RELEASE)" \
	          --buildroot "${PWD}/build" \
	          --define "_builddir ${PWD}/build" \
	          --define "_rpmdir ${PWD}" \
	          --define "_srcrpmdir ${PWD}" \
	          --define "_sourcedir ${PWD}" \
	          --define "_specdir ${PWD}" \
	          --define "__check_files ''" \
	          --define "_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" \
	          $(PACKAGE).spec
	@rmdir --ignore-fail-on-non-empty build

rpm: $(RPMS)

# Todd's release rules

release: $(PROG) cpuid.x86_64 $(SRC_TAR) $(BIN_TAR) $(RPMS)
	if [ -d $(REL_DIR) ]; then                         \
	   echo "Makefile: $(REL_DIR) already exists" >&2; \
	   exit 1;                                         \
	fi
	mkdir $(REL_DIR)
	cp -p $(PROG) cpuid.x86_64 $(SRCS) $(OTHER_SRCS) $(REL_DIR)
	mv $(SRC_TAR) $(BIN_TAR) $(RPMS) $(REL_DIR)
	if [ -e $(DEBUG_RPM) ]; then   \
	   mv $(DEBUG_RPM) $(REL_DIR); \
	fi
	chmod -w $(REL_DIR)/*
	cp -f -p $(REL_DIR)/*.tar.gz $(REL_DIR)/*.rpm $(WEB_DIR)

rerelease:
	rm -rf $(REL_DIR)
	$(MAKE) -$(MAKEFLAGS) release

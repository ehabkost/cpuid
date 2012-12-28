CFLAGS=-g -Wall -Wshadow -Wcast-align -Wredundant-decls -Wbad-function-cast -Wcast-qual -Wwrite-strings -Waggregate-return -Wstrict-prototypes -Wmissing-prototypes -D_FILE_OFFSET_BITS=64 -DVERSION=$(VERSION)

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

OTHER_SRCS=Makefile $(PROG).man $(PACKAGE).proto.spec $(PACKAGE).spec \
           ChangeLog FUTURE LICENSE
OTHER_BINS=$(PROG).man

REL_DIR=../$(shell date +%Y-%m-%d)
WEB_DIR=/toad1/apps.mine/www/www/$(PROG)

DEV_X86_64_HOST=iggy

BUILDROOT=

default: $(PROG) $(PROG).man.gz

$(PROG): cpuid.c Makefile
	$(CC) $(CFLAGS) -o $@ cpuid.c

$(PROG).man.gz: $(PROG).man
	gzip < $< > $@

install: $(PROG) $(PROG).man.gz
	install -D -s -m 755 $(PROG)        $(BUILDROOT)/usr/bin/$(PROG)
	install -D    -m 444 $(PROG).man.gz $(BUILDROOT)/usr/share/man/man1/$(PROG).1.gz

clean:
	rm -f $(PROG) $(PROG).x86_64
	rm -f $(PACKAGE).spec $(PROG).man.gz
	rm -f $(SRC_TAR) $(BIN_TAR)
	rm -f $(RPMS)
	rm -f $(DEBUG_RPM)

# Todd's Development rules

$(PROG).x86_64: cpuid.c Makefile
	scp -p cpuid.c $(DEV_X86_64_HOST):/tmp
	ssh $(DEV_X86_64_HOST) $(CC) $(CFLAGS) -o /tmp/$(PROG) /tmp/cpuid.c
	scp -p $(DEV_X86_64_HOST):/tmp/$(PROG) $@

todd: $(PROG) $(PROG).x86_64
	cp -p $(PROG) ~/.bin/execs/i586/$(PROG)
	cp -p $(PROG).x86_64 ~/.bin/execs/x86_64/$(PROG)
	(cd ~/.bin/execs; prop i586/$(PROG) x86_64/$(PROG))

# Release rules

$(PACKAGE).spec: $(PACKAGE).proto.spec
	@(echo "%define version $(VERSION)"; \
	  echo "%define release $(RELEASE)"; \
	  cat $<) > $@

$(SRC_TAR): $(SRCS) $(OTHER_SRCS)
	@echo Tarring source
	@rm -rf $(PACKAGE)-$(VERSION)
	@mkdir $(PACKAGE)-$(VERSION)
	@ls -1d $(SRCS) $(OTHER_SRCS) | cpio -pdmuv $(PACKAGE)-$(VERSION)
	@tar cvf - $(PACKAGE)-$(VERSION) | gzip -c >| $(SRC_TAR)
	@rm -rf $(PACKAGE)-$(VERSION)

$(BIN_TAR): $(PROG) $(OTHER_BINS)
	@echo Tarring binary
	@rm -rf $(PACKAGE)-$(VERSION)
	@mkdir $(PACKAGE)-$(VERSION)
	@ls -1d $(PROG) $(OTHER_BINS) | cpio -pdmuv $(PACKAGE)-$(VERSION)
	@(cd $(PACKAGE)-$(VERSION); strip $(PROG))
	@tar cvf - $(PACKAGE)-$(VERSION) | gzip -c >| $(BIN_TAR)
	@rm -rf $(PACKAGE)-$(VERSION)

tar: $(SRC_TAR) $(BIN_TAR)

$(RPMS) $(DEBUG_RPM): $(SRC_TAR) $(PACKAGE).spec
	@echo Building RPMs
	@rm -rf build
	@mkdir build
	@rpmbuild -ba \
	          --buildroot "${PWD}/build" \
	          --define "_builddir ${PWD}/build" \
	          --define "_rpmdir ${PWD}" \
	          --define "_srcrpmdir ${PWD}" \
	          --define "_sourcedir ${PWD}" \
	          --define "_specdir ${PWD}" \
	          --define "__check_files ''" \
	          --define "_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" \
	          $(PACKAGE).spec
	@rm -rf build

rpm: $(RPMS)

# Todd's release rules

release: $(PROG) $(PROG).x86_64 $(SRC_TAR) $(BIN_TAR) $(RPMS)
	if [ -d $(REL_DIR) ]; then                         \
	   echo "Makefile: $(REL_DIR) already exists" >&2; \
	   exit 1;                                         \
	fi
	mkdir $(REL_DIR)
	cp -p $(PROG) $(PROG).x86_64 $(SRCS) $(OTHER_SRCS) $(REL_DIR)
	mv $(SRC_TAR) $(BIN_TAR) $(RPMS) $(REL_DIR)
	if [ -e $(DEBUG_RPM) ]; then   \
	   mv $(DEBUG_RPM) $(REL_DIR); \
	fi
	chmod -w $(REL_DIR)/*
	cp -f -p $(REL_DIR)/*.tar.gz $(REL_DIR)/*.rpm $(WEB_DIR)
	rm -f $(PACKAGE).spec

rerelease:
	rm -rf $(REL_DIR)
	$(MAKE) -$(MAKEFLAGS) release

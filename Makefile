
OUTPUT = $(PWD)/output
SOURCES = sources

BINUTILS_VER = 2.25.1
GCC_VER = 5.2.0
MUSL_TAG = master

GNU_SITE = http://ftp.gnu.org/pub/gnu
GCC_SITE = $(GNU_SITE)/gcc
BINUTILS_SITE = $(GNU_SITE)/binutils

COMMON_CONFIG = --disable-werror \
	--target=$(TARGET) --prefix=$(OUTPUT) \
	--with-sysroot=$(OUTPUT)/$(TARGET)

BINUTILS_CONFIG = $(COMMON_CONFIG)
GCC_CONFIG = $(COMMON_CONFIG) --enable-tls \
	--disable-libmudflap --disable-libsanitizer

GCC0_VARS = CFLAGS="-O0 -g0" CXXFLAGS="-O0 -g0"
GCC0_CONFIG = $(GCC_CONFIG) \
	--with-newlib --disable-libssp --disable-threads \
	--disable-shared --disable-libgomp --disable-libatomic \
	--disable-libquadmath --disable-decimal-float --disable-nls \
	--enable-languages=c

GCC0_BDIR = $(PWD)/gcc-$(GCC_VER)/build0/gcc
GCC0_CC = $(GCC0_BDIR)/xgcc -B $(GCC0_BDIR)

MUSL_CONFIG = CC="$(GCC0_CC)" --prefix=

-include config.mak

ifeq ($(TARGET),)
$(error TARGET must be set via config.mak or command line)
endif

all: install_binutils install_musl install_gcc

clean:
	rm -rf gcc-$(GCC_VER) binutils-$(BINUTILS_VER) musl

distclean: clean
	rm -rf sources

.PHONY: extract_binutils extract_gcc clone_musl
.PHONY: configure_binutils configure_gcc0 configure_gcc configure_musl
.PHONY: build_binutils build_gcc0 build_gcc build_musl
.PHONY: install_binutils install_gcc install_musl

extract_binutils: binutils-$(BINUTILS_VER)/.mcm_extracted
extract_gcc: gcc-$(GCC_VER)/.mcm_extracted
clone_musl: musl/.mcm_cloned

configure_binutils: binutils-$(BINUTILS_VER)/.mcm_configured
configure_gcc0: gcc-$(GCC_VER)/build0/.mcm_configured
configure_gcc: gcc-$(GCC_VER)/build/.mcm_configured
configure_musl: musl/.mcm_configured

build_binutils: binutils-$(BINUTILS_VER)/.mcm_built
build_gcc0: gcc-$(GCC_VER)/build0/.mcm_built
build_gcc: gcc-$(GCC_VER)/build/.mcm_built
build_musl: musl/.mcm_built

install_binutils: binutils-$(BINUTILS_VER)/.mcm_installed
install_gcc: gcc-$(GCC_VER)/build/.mcm_installed
install_musl: musl/.mcm_installed


$(SOURCES):
	mkdir -p $@

$(SOURCES)/config.sub: | $(SOURCES)
	wget -O $@ 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'

$(SOURCES)/binutils-%: | $(SOURCES)
	wget -c -O $@.part $(BINUTILS_SITE)/$(notdir $@)
	mv $@.part $@

$(SOURCES)/gcc-%: | $(SOURCES)
	wget -c -O $@.part $(GCC_SITE)/$(basename $(basename $(notdir $@)))/$(notdir $@)
	mv $@.part $@



binutils-$(BINUTILS_VER)/.mcm_extracted: $(SOURCES)/binutils-$(BINUTILS_VER).tar.bz2 $(SOURCES)/config.sub
	tar jxvf $<
	cat patches/binutils-$(BINUTILS_VER)/* | ( cd binutils-$(BINUTILS_VER) && patch -p1 )
	cp $(SOURCES)/config.sub binutils-$(BINUTILS_VER)
	touch $@

binutils-$(BINUTILS_VER)/.mcm_configured: binutils-$(BINUTILS_VER)/.mcm_extracted
	test -e binutils-$(BINUTILS_VER)/config.status || ( cd binutils-$(BINUTILS_VER) && ./configure $(BINUTILS_CONFIG) )
ifeq ($(shell uname),Darwin)
	echo '#define HAVE_STDLIB_H 1' >> binutils-$(BINUTILS_VER)/libiberty/config.h
	echo '#define HAVE_LIMITS_H 1' >> binutils-$(BINUTILS_VER)/libiberty/config.h
	echo '#define HAVE_STRING_H 1' >> binutils-$(BINUTILS_VER)/libiberty/config.h
	echo '#define HAVE_SYS_TYPES_H 1' >> binutils-$(BINUTILS_VER)/libiberty/config.h
	echo '#define HAVE_SYS_STAT_H 1' >> binutils-$(BINUTILS_VER)/libiberty/config.h
	echo '#define HAVE_UNISTD_H 1' >> binutils-$(BINUTILS_VER)/libiberty/config.h
	echo '#define HAVE_FCNTL_H 1' >> binutils-$(BINUTILS_VER)/libiberty/config.h
endif
	touch $@

binutils-$(BINUTILS_VER)/.mcm_built: binutils-$(BINUTILS_VER)/.mcm_configured
	$(MAKE) -C binutils-$(BINUTILS_VER)
	touch $@

binutils-$(BINUTILS_VER)/.mcm_installed: binutils-$(BINUTILS_VER)/.mcm_built
	cd binutils-$(BINUTILS_VER) && $(MAKE) install
	touch $@




gcc-$(GCC_VER)/.mcm_extracted: $(SOURCES)/gcc-$(GCC_VER).tar.bz2 $(SOURCES)/config.sub
	tar jxvf $<
	cat patches/gcc-$(GCC_VER)/* | ( cd gcc-$(GCC_VER) && patch -p1 )
	cp $(SOURCES)/config.sub gcc-$(GCC_VER)
ifeq ($(shell uname),Darwin)
	echo '#define HAVE_STDLIB_H 1' >> gcc-$(GCC_VER)/libiberty/config.in
	echo '#define HAVE_LIMITS_H 1' >> gcc-$(GCC_VER)/libiberty/config.in
	echo '#define HAVE_STRING_H 1' >> gcc-$(GCC_VER)/libiberty/config.in
	echo '#define HAVE_SYS_TYPES_H 1' >> gcc-$(GCC_VER)/libiberty/config.in
	echo '#define HAVE_SYS_STAT_H 1' >> gcc-$(GCC_VER)/libiberty/config.inø
	echo '#define HAVE_UNISTD_H 1' >> gcc-$(GCC_VER)/libiberty/config.in
	echo '#define HAVE_FCNTL_H 1' >> gcc-$(GCC_VER)/gcc/auto-host.h
	echo '#define HAVE_SYS_PARAM_H 1' >> gcc-$(GCC_VER)/gcc/auto-host.h
endif
	touch $@

gcc-$(GCC_VER)/build0/.mcm_configured: gcc-$(GCC_VER)/.mcm_extracted | binutils-$(BINUTILS_VER)/.mcm_installed
	mkdir -p gcc-$(GCC_VER)/build0
	test -e gcc-$(GCC_VER)/build0/config.status || ( cd gcc-$(GCC_VER)/build0 && $(GCC0_VARS) ../configure $(GCC0_CONFIG) )
	touch $@

gcc-$(GCC_VER)/build0/.mcm_built: gcc-$(GCC_VER)/build0/.mcm_configured
	cd gcc-$(GCC_VER)/build0 && $(MAKE)
	touch $@

gcc-$(GCC_VER)/build/.mcm_configured:  gcc-$(GCC_VER)/.mcm_extracted | binutils-$(BINUTILS_VER)/.mcm_installed musl/.mcm_installed
	mkdir -p gcc-$(GCC_VER)/build
	test -e gcc-$(GCC_VER)/build/config.status || ( cd gcc-$(GCC_VER)/build && ../configure $(GCC_CONFIG) )
	touch $@

gcc-$(GCC_VER)/build/.mcm_built: gcc-$(GCC_VER)/build/.mcm_configured
	cd gcc-$(GCC_VER)/build && $(MAKE)
	touch $@

gcc-$(GCC_VER)/build/.mcm_installed: gcc-$(GCC_VER)/build/.mcm_built
	cd gcc-$(GCC_VER)/build && $(MAKE) install
	touch $@





musl/.mcm_cloned:
	test -d musl || git clone -b $(MUSL_TAG) git://git.musl-libc.org/musl musl
	cat patches/musl/* | ( cd musl && patch -p1 )
	touch $@

musl/.mcm_configured: musl/.mcm_cloned gcc-$(GCC_VER)/build0/.mcm_built
	cd musl && ./configure $(MUSL_CONFIG)
	touch $@

musl/.mcm_built: musl/.mcm_configured
	cd musl && $(MAKE)
	touch $@

musl/.mcm_installed: musl/.mcm_built
	cd musl && $(MAKE) install DESTDIR=$(OUTPUT)/$(TARGET)
	ln -sfn . $(OUTPUT)/$(TARGET)/usr
	touch $@

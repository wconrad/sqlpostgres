SRC=$(shell find lib -name '*.rb')
EXAMPLES=$(shell find doc/examples -name '*.rb')
LIBDIR=$(DESTDIR)/usr/lib/ruby/1.8

.PHONY: default
default: build

.PHONY: distclean
distclean:
	rm -rf doc/rdoc 
	rm -f doc/manual.html
	rm -f examples-stamp
	rm -rf debian/libsqlpostgres-ruby1.8
	rm -f debian/libsqlpostgres-ruby1.8.debhelper.log
	rm -f debian/libsqlpostgres-ruby1.8.substvars

.PHONY: install
install:
	mkdir -p $(LIBDIR)/sqlpostgres
	for f in $(SRC) ; do cp $$f $(LIBDIR)/$${f##lib/} ; done

.PHONY: build
build: rdoc manual

.PHONY: test
test:
	test/test

.PHONY: examples
examples: examples-stamp

examples-stamp: $(EXAMPLES)
	doc/insertexamples.rb
	touch examples-stamp

.PHONY: rdoc
rdoc: doc/rdoc/index.html

doc/rdoc/index.html: $(SRC) examples-stamp
	doc/makerdoc

.PHONY: manual
manual: doc/manual.html

doc/manual.html: doc/manual.dbk examples-stamp
	xmlto -o $(dir $@) html-nochunks $<

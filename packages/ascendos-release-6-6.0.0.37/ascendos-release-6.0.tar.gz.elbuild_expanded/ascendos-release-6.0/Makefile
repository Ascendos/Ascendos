NAME=redhat-release
VERSION=6
RELEASE=8

create-snapshot:
	@rm -rf /tmp/$(NAME)
	@rm -rf /tmp/$(NAME)-$(VERSION)
	@tag=`cvs status Makefile | awk ' /Sticky Tag/ { print $$3 } '` 2> /dev/null; \
	[ x"$$tag" = x"(none)" ] && tag=HEAD; \
	[ x"$$TAG" != x ] && tag=$$TAG; \
	cvsroot=`cat CVS/Root` 2>/dev/null; \
        echo "*** Pulling off $$tag from $$cvsroot!"; \
	cd /tmp ; cvs -z3 -Q -d $$cvsroot export -r $$tag $(NAME) || echo "Um... export aborted."
	@mv /tmp/$(NAME)/RHEL-6 /tmp/$(NAME)-$(VERSION)
	@cd /tmp ; tar -czf $(NAME)-$(VERSION)-$(RELEASE).tar.gz $(NAME)-$(VERSION)
	@cp /tmp/$(NAME)-$(VERSION)-$(RELEASE).tar.gz .
	@rm -f /tmp/$(NAME)-$(VERSION)-$(RELEASE).tar.gz
	@rm -rf /tmp/$(NAME)-$(VERSION)
	@echo ""
	@echo "The final archive is in $(NAME)-$(VERSION)-$(RELEASE).tar.gz"

clean:
	@rm -f *.gz *~

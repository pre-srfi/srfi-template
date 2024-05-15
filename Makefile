FILENAME=template
EMACS=emacs

all: README.org $(FILENAME).html

# Original markdown targets are here.

$(FILENAME).html: README.md
	ln -sf README.md $(FILENAME).md
	pandoc --from=gfm README.md -o $(FILENAME).html

$(FILENAME).pdf:
	pandoc --standalone $(FILENAME).html -o $(FILENAME).pdf

# New org-mode targets are here.

README.org: template.scm
	gosh tools/sxml-srfi.scm template.scm

index.html: README.org

template2.html: template2.org
	$(EMACS) --batch template2.org -f org-html-export-to-html

template.scm: template2.html
	gosh tools/html-sxml.scm template2.html template.scm

# Phonies

clean:
	rm -f index.html README.org srfi-*.html template.scm

watch:
	while true; do inotifywait -q -e modify template.scm README.md; make; done

watch-mac:
	fswatch template.scm README.md | (while read; do make; done)

.PHONY: all clean watch watch-mac


doit:
	kramdown-rfc2629 draft-jennings-perc-double-01.md > draft-jennings-perc-double-01.xml
	xml2rfc  draft-jennings-perc-double-01.xml --html
	xml2rfc  draft-jennings-perc-double-01.xml --text


doit:
	kramdown-rfc2629 draft-jennings-perc-double-00.md > draft-jennings-perc-double-00.xml
	xml2rfc  draft-jennings-perc-double-00.xml --html
	xml2rfc  draft-jennings-perc-double-00.xml --text

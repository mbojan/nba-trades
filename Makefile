render=Rscript -e 'rmarkdown::render("$<")'

default: Manuscript.html

data: $(addprefix data/,nodes.rds edges.rds igraph-list.rds)

data/nodes.rds data/edges.rds data/igraph-list.rds &: make_data.Rmd data/standings.rds data-src/data/NBA_AnalysisData.RData
	$(render)

Manuscript.html: Manuscript.Rmd data/nodes.rds data/edges.rds data/igraph-list.rds NBA_Trades.html
	$(render)

publish: Manuscript.html
	mkdir -p docs
	cp $< docs/index.html

.PHONY: default data publish

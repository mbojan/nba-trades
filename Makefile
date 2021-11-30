render=Rscript -e 'rmarkdown::render("$<")'
data_files=$(addprefix data/,nodes.rds edges.rds igraph-list.rds trades.rds)

default: Manuscript.html

data: $(data_files)

$(data_files) &: make_data.Rmd data/standings.rds data-src/data/NBA_AnalysisData.RData
	$(render)

Manuscript.html: Manuscript.Rmd data/nodes.rds data/edges.rds data/igraph-list.rds NBA_Trades.html
	$(render)

publish: Manuscript.html
	mkdir -p docs
	cp $< docs/index.html

.PHONY: default data publish

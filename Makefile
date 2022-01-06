# Checks and commands ------------------------------------------------------

# This Makefile uses rules with grouped targets (`&:` syntax). See
# https://www.gnu.org/software/make/manual/make.html#Multiple-Targets and 
# section "Rules with Grouped Targets". These are supported by `make` since 
# the version 4.3. 
$(if $(filter grouped-target,${.FEATURES}) \
	,,$(warning Your version of GNU make DOES NOT support grouped targets. Parallel procesing may lead some of the steps to be executed unnecesarily more than once or perhaps to err.))

render=Rscript -e 'rmarkdown::render("$<")'
runr=Rscript $<


# Display help -------------------------------------------------------------

# Document phony targets with descriptions on the same line preceded with
# double #es.

help:	                       ## Show this help.
	@echo
	@echo Available targets
	@echo
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/:.*##/ --- /'

.PHONY: help




# Data ---------------------------------------------------------------------

data_files=$(addprefix data/,nodes.rds edges.rds igraph-list.rds trades.rds)

data: $(data_files)          ## Build data files.

$(data_files) &: make_data.Rmd data/standings.rds data-src/data/NBA_AnalysisData.RData
	$(render)

data/standings.rds data/stats_per_game.rds &: data/standings.R
	$(runr)

.PHONY: data



# Models ------------------------------------------------------------------

# Pooled ERGMs
ergm-pooled1.rds ergm-pooled2.rds ergm-pooled3.rds &: ergm-pooled.R data/igraph-list.rds 
	Rscript ergm-pooled.R

model1-table.rds model1-table-short.rds &: ergm-pooled-results.Rmd ergm-pooled1.rds ergm-pooled2.rds ergm-pooled3.rds
	$(render)

# Seasonal ERGMs
ergm-seasonal.rds: ergm-seasonal.R data/igraph-list.rds
	Rscript ergm-seasonal.R
	
ergm-seasonal-db.rds: ergm-seasonal-results.Rmd ergm-seasonal.rds data/igraph-list.rds
	$(render)

estimate: ergm-pooled1.rds ergm-pooled2.rds ergm-pooled3.rds   ## Estimate ERGMs

.PHONY: estimate



# Manuscript --------------------------------------------------------------

Manuscript.html: Manuscript.Rmd data/nodes.rds data/edges.rds data/igraph-list.rds NBA_Trades.html model1-table-short.rds ergm-seasonal-db.rds model1-table.rds
	$(render)
	
paper: Manuscript.html      ## Render manuscript.

publish: Manuscript.html NBA_Trades.html     ## Publish manuscript to '/docs'
	mkdir -p docs
	cp $< docs/index.html

.PHONY: paper publish



# Misc -------------------------------------------------------------------- 

debug:
	@echo $(.FEATURES)

.PHONY: debug

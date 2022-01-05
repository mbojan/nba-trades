# Checks and commands ------------------------------------------------------

# This Makefile uses rules with grouped targets (`&:` syntax). See
# https://www.gnu.org/software/make/manual/make.html#Multiple-Targets and 
# section "Rules with Grouped Targets". These are supported by `make` since 
# the version 4.3. 
$(if $(filter grouped-target,${.FEATURES}) \
	,$(info Your version of GNU make supports grouped targets) \
	,$(warning Your version of GNU make DOES NOT support grouped targets. Parallel procesing may lead some of the steps to be executed unnecesarily more than once or perhaps to err.))

render=Rscript -e 'rmarkdown::render("$<")'
runr=Rscript $<


# Display phony targets ---------------------------------------------------

help:	                       ## Show this help.
	@echo
	@echo Available targets
	@echo
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

.PHONY: help




# Data ---------------------------------------------------------------------

data_files=$(addprefix data/,nodes.rds edges.rds igraph-list.rds trades.rds)

data: $(data_files)          ## Build data files.

$(data_files) &: make_data.Rmd data/standings.rds data-src/data/NBA_AnalysisData.RData
	$(render)

data/standings.rds data/stats_per_game.rds &: data/standings.R
	$(runr)




.PHONY: data




# Manuscript --------------------------------------------------------------

Manuscript.html: Manuscript.Rmd data/nodes.rds data/edges.rds data/igraph-list.rds NBA_Trades.html
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

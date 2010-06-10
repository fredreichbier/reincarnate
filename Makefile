OOC?=rock
OOC_FLAGS+=-sourcepath=source/ -noclean -v -g

all: reincarnate

reincarnate: source/reincarnate.ooc source/reincarnate/*.ooc source/reincarnate/*/*.ooc
	$(OOC) $(OOC_FLAGS) reincarnate.ooc

prepare_bootstrap:
	@echo "Preparing boostrap (in build/ directory)"
	rm -rf build/
	$(OOC) $(OOC_FLAGS) -driver=make -sourcepath=source -outpath=c-source reincarnate -v -g +-w
	cp -r $(OOC_DIST)/libs build/
	@echo "Done!"

clean:
	rm -rvf reincarnate rock_tmp .libs
	
.phony: clean


OOC=ooc
OOC_FLAGS=-sourcepath=source/ -noclean -v -g

all: reincarnate

reincarnate: source/reincarnate.ooc source/reincarnate/*.ooc source/reincarnate/*/*.ooc
	$(OOC) $(OOC_FLAGS) reincarnate.ooc -o=reincarnate

clean:
	rm -rvf reincarnate ooc_tmp
	
.phony: clean


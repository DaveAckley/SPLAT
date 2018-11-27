# This file is meant to be included from inside each specific demo directory
SPLATTR:=../../splattr
MFZRUN:=../../../MFM/bin/mfzrun
MFZGEOMETRY:={{2H3}}
MFZARGS:=$(MFZGEOMETRY) -no-std
DIR:=$(shell pwd)
DEMO:=$(shell basename "$(DIR)")

run:	$(DEMO).mfz
	$(MFZRUN) $^ run $(MFZARGS)

$(DEMO).mfz:	*.splat Makefile* ../makefile*
	$(SPLATTR) *.splat $@

clean:	FORCE
	rm -rf .gen .splatgen *~ ../*~

realclean:	clean
	rm -f *.mfz

.PHONY:	FORCE

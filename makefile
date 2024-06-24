SCANNER = scanner.l
PARSER = parser-v1.y

all:
	make clean
	make build

build:
	flex $(SCANNER)
	byacc -vd $(PARSER)
	gcc -o codegen lex.yy.c y.tab.c code.c -lfl

clean:
	rm -f lex.yy.c y.tab.h y.tab.c codegen
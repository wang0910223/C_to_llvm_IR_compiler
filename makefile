all: test_case test0 test1 test2 test3 test4 test5 test6 test7 

test0: myCompilerLexer.class myCompilerParser.class myCompiler_test.class
	java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test0.c > test0.ll
	lli test0.ll

test1: myCompilerLexer.class myCompilerParser.class myCompiler_test.class
	java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test1.c > test1.ll
	lli test1.ll

test2: myCompilerLexer.class myCompilerParser.class myCompiler_test.class
	java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test2.c > test2.ll
	lli test2.ll

test3: myCompilerLexer.class myCompilerParser.class myCompiler_test.class
	java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test3.c > test3.ll
	lli test3.ll

test4: myCompilerLexer.class myCompilerParser.class myCompiler_test.class
	java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test4.c > test4.ll
	lli test4.ll

test5: myCompilerLexer.class myCompilerParser.class myCompiler_test.class
	java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test5.c > test5.ll
	lli test5.ll

test6: myCompilerLexer.class myCompilerParser.class myCompiler_test.class
	java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test6.c > test6.ll
	lli test6.ll

test7: myCompilerLexer.class myCompilerParser.class myCompiler_test.class
	java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test7.c > test7.ll
	lli test7.ll


test_case:  myCompilerLexer.class myCompilerParser.class myCompiler_test.class
		java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test_case.c > test_case.ll
		lli test_case.ll

	
	
	
myCompilerLexer.class myCompilerParser.class myCompiler_test.class: myCompilerLexer.java myCompilerParser.java myCompiler_test.java
	javac -cp ./antlr-3.5.3-complete-no-st3.jar:. *.java
	
myCompilerLexer.java myCompilerParser.java: myCompiler.g
	java -cp ./antlr-3.5.3-complete-no-st3.jar org.antlr.Tool myCompiler.g

clean:
	rm *.tokens myCompilerLexer.java myCompilerParser.java *.class *.ll




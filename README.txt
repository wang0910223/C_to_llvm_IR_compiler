如何編譯我的檔案：
	方法1：在終端進入檔案所在目錄下，輸入指令 make 即可完成所有檔案的編譯，並顯示所有測試檔的執行結果。
		  若想分開顯示不同測試檔的結果也可使用 make test0, make test1, ...等指令來執行。

	方法2：分別執行以下幾道指令
		1.  java -cp ./antlr-3.5.3-complete-no-st3.jar org.antlr.Tool myCompiler.g
		2.  javac -cp ./antlr-3.5.3-complete-no-st3.jar:. *.java
		3.  java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test0.c > test0.ll
			lli test0.ll
			(最後面 test0 可替換成 test1, test2, ... 以查看不同測試檔的結果)

	另外，可以使用 make clean 把 make 指令所產生的檔案清除。
	
	
/************以下為作業基本要求的測試檔*************/

test_case.c檔為助教公告之測試檔案   (使用指令 make test_case 查看)

test0.c檔主要測試的功能：
	1. 基本的變數宣告、數值
	2. 整數型資料的基本四則運算
	3. printf function 

test1.c檔主要測試的功能：
	1. if-then / if-then-else program constructs
	2. Comparison expression


/************以下為自訂加分功能的測試檔*************/

test2.c檔主要測試的功能：
	1. if, else if, else statements  
	2. Nested if construct

test3.c檔主要測試的功能：
	1. while loop
	2. Loop construct + if construct

test4.c檔主要測試的功能：
	1. for loop
	2. Loop construct + if construct

test5.c檔主要測試的功能：
	1. Switch-case construct

test6.c檔主要測試的功能：
	1. Function call   (可支援整數型回傳值或是沒有回傳值的function call)
		實作這個功能花費了許多心力，要大改原始sample code的結構，
		若像原始結構那樣整個程式共用一個symbol table，則會有不同function中的變數也必須有不同名字的問題。
		為了避免這樣的不合理問題，我為每個function建立一個自己的結構，
		結構中包含symbol table, variable count, label count, newLabel(), newVar()等member和member function。
		也就是要為每個function建立自己的symbol table，並且修改每個statement存取變數的程式碼，要從正確的symbol table中存取資訊。
		同時也要建立一個function table以管理所有function的symbol table。

test7.c檔主要測試的功能：
	1. Structure data type
		支援structure data type，可以建立任意數量個structure type，建立structure table以管理所有structure type。
	2. printf function 可以支援多個整數型參數

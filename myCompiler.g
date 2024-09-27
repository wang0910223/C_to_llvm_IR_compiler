grammar myCompiler;

options {
   language = Java;
}

@header {
    // import packages here.
    import java.util.HashMap;
    import java.util.ArrayList;
}

@members {
    boolean TRACEON = false;

    // Type information.
    public enum Type{
       ERR, BOOL, INT, FLOAT, CHAR, CONST_INT, CONST_FLOAT, STRING, VOID, STRUCT;
    }
   class tVar {
	   int   varIndex; // temporary variable's index. Ex: t1, t2, ..., etc.
	   int   iValue;   // value of constant integer. Ex: 123.
	   float fValue;   // value of constant floating point. Ex: 2.314.
      String sValue;
	};

   class Info {
      Type theType;  // type information.
      tVar theVar;
         
      Info() {
         theType = Type.ERR;
         theVar = new tVar();
      }
   };

   // public enum ROP_Type {
   //    GT, GE, LT, LE, EQ, NE;
   // }
    

   class print_para{
      int varcrec;
      String para;

      print_para(){
         varcrec = 0;
         para = new String();
      }
   };

      int labelCount = 0;
   int varCount = 0;
   List<String> TextCode = new ArrayList<String>();


   void prologue()
   {
      
      TextCode.add("declare dso_local i32 @printf(i8*, ...)\n");
      TextCode.add("define dso_local i32 @main()");
      TextCode.add("{");
   }
   void epilogue()
   {
      /* handle epilogue */
      TextCode.add("\n; === epilogue ===");
      TextCode.add("ret i32 0");
      TextCode.add("}");
   }
   
   
   /* Generate a new label */
   // String newLabel()
   // {
   //    labelCount ++;
   //    return (new String("L")) + Integer.toString(labelCount);
   // } 
   
   public List<String> getTextCode()
   {
      return TextCode;
   }

   class cnt {
      int labelCount;
      int varCount ;

      String newLabel(){
         labelCount ++;
         return (new String("L")) + Integer.toString(labelCount);
      } 

      int newvar(){
         varCount ++;
         return varCount;
      }

      cnt(){
         labelCount = 0;
         varCount = 0;
      }

   }
   class Func { 
      Type theType;
      String name;
      HashMap<String, Info> symtab;
      int labelCount;
      int varCount ;

      String newLabel(){
         labelCount ++;
         return (new String("L")) + Integer.toString(labelCount);
      } 

      int newvar(){
         
         return varCount++;
      }


      Func(){
         labelCount = 0;
         varCount = 0;
         theType = Type.ERR;
         name = new String();
         symtab = new HashMap<String, Info>();
      }    
   }   
   HashMap<String, Info> symtab = new HashMap<String, Info>();
   HashMap<String, Func> functab = new HashMap<String, Func>();
   HashMap<String, HashMap<String, Info>> structtab = new HashMap<String, HashMap<String, Info>>();
}

program:
      {
         // TextCode.add("; === prologue ====");
         TextCode.add("declare dso_local i32 @printf(i8*, ...)\n");
         // TextCode.add("define dso_local i32 @main()");
         // TextCode.add("{");   
      }

      (func | structure)*;
/********************************* */
structure
      : 
      { 
         HashMap<String, Info> vartab = new HashMap<String, Info>(); 
         int count = 0;
         String var = new String();
      }
      'struct' a=Identifier '{' (type b=Identifier ';'
            {
               Info theInfo = new Info();
               theInfo.theVar.varIndex = count;
               theInfo.theType = $type.attr_type;
               vartab.put($b.text, theInfo);

               if($type.attr_type == Type.INT){
                  if(count != 0){
                     var += ", ";
                  }
                  var += "i32";
               }
               count++;


            }  )* '}' ';' 

      {
         structtab.put($a.text, vartab);
         TextCode.add("\%struct." + $a.text + " = type { " + var + "}");

      }
      ;
/********************************* */
func returns[Func thefunc] @init {thefunc = new Func();}
   :
   type b=Identifier '(' a=parameter ')'
         {
            /* create symtab */
            thefunc.name = $b.text;
            thefunc.theType = $type.attr_type;
            functab.put($b.text, thefunc);
            

            /* handle parameter */
            String para = new String();
            List<String> tempCode = new ArrayList<String>();
            for(int i=0; i < $a.paraList.size(); i++){
               Info temp = $a.paraList.get(i);

               if(temp.theType == Type.INT){
                  int idx = thefunc.newvar();
                  para += ("i32 \%t" + Integer.toString(idx));


                  // temp.theVar.varIndex = idx;
                  // thefunc.symtab.put(temp.theVar.sValue, temp);


                  // tempCode.add("\t\%t" + temp.theVar.varIndex + " = alloca i32, align 4");
               }

               if(i!=$a.paraList.size()-1)
                  para += ", ";
            }


            for(int i=0; i < $a.paraList.size(); i++){
               Info temp = $a.paraList.get(i);
               int idx = thefunc.newvar();
               temp.theVar.varIndex = idx;
               thefunc.symtab.put(temp.theVar.sValue, temp);
               // System.out.println(temp.theVar.varIndex);


               if(temp.theType == Type.INT){
                  tempCode.add("\t\%t" + temp.theVar.varIndex + " = alloca i32, align 4");
                  tempCode.add("\tstore i32 \%t" + i + ", i32* \%t" + idx + ", align 4");
               }

            }


            /* declare function */
            String t = new String();
            if($type.attr_type == Type.VOID)
               t = "void";
            else if($type.attr_type == Type.INT)
               t = "i32";
            else 
               t = "void";
            TextCode.add("define dso_local "+ t + " @" + $b.text+ "(" + para + ")\n{");
            TextCode.addAll(tempCode);
         }

   '{' declarations[thefunc] statements[thefunc] 
      ('return' (r = Identifier 
                     {
                        Info return_val = thefunc.symtab.get($r.text);
                        int re = thefunc.newvar();

                        if(t == "i32"){
                           
                           TextCode.add("\t\%t"+re+" = load i32, i32* \%t" + return_val.theVar.varIndex+", align 4");
                           TextCode.add("\tret i32 \%t" + re);
                        }
                        TextCode.add("}");

                     } 
                | Integer_constant
                     {
                        if(t == "i32"){
                           TextCode.add("\tret i32 0");
                        }
                        TextCode.add("}");

                     } 
                )';'
          
      | 
         {
            if(t == "void")
               TextCode.add("\tret void");
            else{
               System.out.println("The function type is not \'void\', but without a return value!");
               System.exit(0);
            }
            TextCode.add("}");
         }  
         // }
      ) 
   '}'
   
   { if (TRACEON) System.out.println($type.text + " " + $b.text + " (...) {declarations statements}");}
         

   ;

/********************************* */
parameter returns [List<Info> paraList] @init {paraList = new ArrayList();}
   :
   (a=type c=Identifier 
      { 
         Info p = new Info();
         p.theType = $a.attr_type;
         p.theVar.sValue = $c.text;
         paraList.add(p);
      }
   
   (',' b=type d=Identifier
      { 
         Info p2 = new Info();
         p2.theType = $b.attr_type;
         p2.theVar.sValue = $d.text;
         paraList.add(p2);
      }
      
   )*)?;





/********************************* */
declarations [Func thefunc]
   :  type Identifier ';' declarations[thefunc]
         {
               if (TRACEON)
                  System.out.println("declarations: type Identifier : declarations");

               if (thefunc.symtab.containsKey($Identifier.text)) {
                  // variable re-declared.
                  System.out.println("Type Error: " + $Identifier.getLine() + ": Redeclared identifier.");
                  System.exit(0);
               }
                     
               // Add ID and its info into the symbol table. 
               Info the_entry = new Info();
               the_entry.theType = $type.attr_type;
               the_entry.theVar.varIndex = thefunc.newvar();
               thefunc.symtab.put($Identifier.text, the_entry);

               // issue the instruction.
               // Ex: \%a = alloca i32, align 4
               if ($type.attr_type == Type.INT) { 
                  TextCode.add("\t\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
               }
         }
      | 'struct' a=Identifier b=Identifier ';' declarations[thefunc]
         {
            if (thefunc.symtab.containsKey($b.text)) {
               System.out.println("Type Error: " + $a.getLine() + ": Redeclared identifier.");
               System.exit(0);
            }

            Info the_entry = new Info();
            the_entry.theType = Type.STRUCT;
            the_entry.theVar.varIndex = thefunc.newvar();
            the_entry.theVar.sValue = $a.text;
            thefunc.symtab.put($b.text, the_entry);

            
            TextCode.add("\t\%t" + the_entry.theVar.varIndex + " = alloca \%struct." + $a.text + ", align 4");
            
         }
        
        
      | 
      {
         if (TRACEON)
            System.out.println("declarations: ");
      }
      ;


/********************************* */
type returns [Type attr_type]
   : INT { if (TRACEON) System.out.println("type: INT"); $attr_type=Type.INT; }
   | CHAR { if (TRACEON) System.out.println("type: CHAR"); $attr_type=Type.CHAR; }
   | FLOAT {if (TRACEON) System.out.println("type: FLOAT"); $attr_type=Type.FLOAT; }
   | VOID  {if (TRACEON) System.out.println("type: VOID"); $attr_type=Type.VOID; }
   ;


/********************************* */
statements [Func thefunc]
   :statement[thefunc] statements[thefunc]
          |
          ;

statement [Func thefunc]
         : assign_stmt[thefunc] ';'
         | if_stmt[thefunc]
         | func_no_return_stmt[thefunc] ';'
         | for_stmt[thefunc]
         | while_stmt[thefunc]
         | switch_stmt[thefunc]
         ;

/********************************* */
switch_stmt [Func thefunc]
   :
      {
         String end = thefunc.newLabel();
      }
      SWITCH  '(' a = arith_expression[thefunc] { Info a_info = $a.theInfo; } ')' 
      '{' 
         
         (CASE b = arith_expression[thefunc] ':'
               {
                  Info b_info = $b.theInfo;
                  String cont = thefunc.newLabel();
                  String next = thefunc.newLabel();

                  if(a_info.theType == Type.INT && b_info.theType == Type.CONST_INT){
                     int r = thefunc.newvar();

                     TextCode.add("\t\%t"+ r +" = icmp eq i32 \%t"+ a_info.theVar.varIndex+", "+ b_info.theVar.iValue);
                     TextCode.add("\tbr i1 \%t" + r + ", label \%" + cont + ", label \%" + next);
                     TextCode.add("\n" + cont + ":");
                     
                  } 
               }
            statement[thefunc]?

            BREAK';'
            {
               TextCode.add("\tbr label \%" + end);
               TextCode.add("\n" + next + ":");
            } 
         )+

         (DEFAULT ':'
            statements[thefunc]
            (BREAK ';')?
         )?
      '}'
      {
         TextCode.add("\tbr label \%" + end);
         TextCode.add("\n" + end + ":");
      }
      ;  



/********************************* */
while_stmt[Func thefunc]
      : 
      WHILE 
            {
               String condition = thefunc.newLabel();
               TextCode.add("\tbr label \%" + condition);
               TextCode.add("\n" + condition + ":");
            }
      '(' b=cond_expression[thefunc]
            {
               String loopbody = thefunc.newLabel();
               String endlabel = thefunc.newLabel();
               TextCode.add("\tbr i1 \%t" + $b.theInfo.theVar.varIndex + ", label \%" + loopbody + ", label \%" + endlabel);
               TextCode.add("\n" + loopbody + ":");
            }
      ')' block_stmt[thefunc]
            {
               TextCode.add("\tbr label \%" + condition);
               TextCode.add("\n" + endlabel + ":");
            }
      ;



/********************************* */
for_stmt[Func thefunc]
      : 
      FOR 
         '(' assign_stmt[thefunc] ';' 
            {
               String condition = thefunc.newLabel();
               TextCode.add("\tbr label \%" + condition);
               TextCode.add("\n" + condition + ":");
            }
            b=cond_expression[thefunc] ';' 
            {
               String loopbody = thefunc.newLabel();
               String increment = thefunc.newLabel();
               String endlabel = thefunc.newLabel();
               TextCode.add("\tbr i1 \%t" + $b.theInfo.theVar.varIndex + ", label \%" + loopbody + ", label \%" + endlabel);
               TextCode.add("\n" + increment + ":");
            }
            assign_stmt[thefunc] 
            {
               TextCode.add("\tbr label \%" + condition);
            } 

         ')'
            {
               TextCode.add("\n" + loopbody + ":");
            } 
      block_stmt[thefunc]
         {
            TextCode.add("\tbr label \%" + increment);
            TextCode.add("\n" + endlabel + ":");

         }
      ;
		 

		 
/********************************* */
if_stmt[Func thefunc] returns [String label] @init {label = new String();}
   : a=if_then_stmt[thefunc]
   {
      String then = $a.label;
      String end = thefunc.newLabel();
      $label = end;
      TextCode.add("\tbr label \%" + $label);
      TextCode.add("\n" +then + ":");
   } 
   (ELSE b=if_then_stmt[thefunc]
   {
      String next = $b.label;
      TextCode.add("\tbr label \%" + $label);
      TextCode.add("\n" +next + ":");
   })* if_else_stmt[label, thefunc]
   {
      TextCode.add("\tbr label \%" + $label);
      TextCode.add("\n" +$label + ":");
   }
   ;


/********************************* */
if_then_stmt[Func thefunc] returns [String label] @init {label = new String();}
   : IF '('cond_expression[thefunc] ')' 
   {
      String L1 = thefunc.newLabel();
      String L2 = thefunc.newLabel();
      TextCode.add("\tbr i1 \%t" + $cond_expression.theInfo.theVar.varIndex + ", label \%" + L1 + ", label \%" + L2);
      TextCode.add("\n" + L1 + ":");
      label = L2;
   }
   block_stmt[thefunc]
   ;


/********************************* */
if_else_stmt[String label, Func thefunc]
   : ELSE block_stmt[thefunc]
   |
   ;
				  
/********************************* */
block_stmt[Func thefunc]
   : '{' statements[thefunc] '}'
	  ;


/********************************* */
assign_stmt [Func thefunc]
      : 
      a=Identifier ( ('=' 
      ( arith_expression[thefunc]
            {
               if(TRACEON) System.out.println("arith");


               Info theRHS = $arith_expression.theInfo;
               Info theLHS = thefunc.symtab.get($a.text); 

               if((theRHS.theType != theLHS.theType)
                  && !(theLHS.theType == Type.INT && theRHS.theType == Type.CONST_INT)
                  && !(theLHS.theType == Type.FLOAT && theRHS.theType == Type.CONST_FLOAT)){
                     
                     System.out.println("Type Error: " + $a.getLine() + ": Type mismatch for the two side operands in an assignment statement.");
                     System.exit(0);
                  
               }

               if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.INT)) {		   
                  // issue store insruction.
                  // Ex: store i32 \%tx, i32* \%ty
                  TextCode.add("\tstore i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex);
               } 
               else if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.CONST_INT)) {
                  // issue store insruction.
                  // Ex: store i32 value, i32* \%ty
                  TextCode.add("\tstore i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex);				
               }
            }
      | 
         b=Identifier '(' argument_return[thefunc, $b.text, $thefunc.symtab.get($a.text)] ')'
      
      
      ) )| struct_assign[thefunc, $a.text])
      ;



/********************************* */
struct_assign[Func thefunc, String s]
      : '.' a=Identifier '=' 
         ( arith_expression[thefunc]
            {
               Info theRHS = $arith_expression.theInfo;
               Info theLHS = thefunc.symtab.get(s); 
               String str = theLHS.theVar.sValue;       // struct name
               HashMap<String, Info> vartab = structtab.get(str);
               Info i = vartab.get($a.text);
               Type t = i.theType;

               if((theRHS.theType != t)
                  && !(t == Type.INT && theRHS.theType == Type.CONST_INT)
                  && !(t == Type.FLOAT && theRHS.theType == Type.CONST_FLOAT)){
                     
                     System.out.println("Type Error: " + $a.getLine() + ": Type mismatch for the two side operands in an assignment statement.");
                     System.exit(0);
                  
               }

               int idx = thefunc.newvar();
               if ((t == Type.INT) && (theRHS.theType == Type.INT)) {		   
                  TextCode.add("\t\%t" + idx + " = getelementptr inbounds \%struct." + str + ", \%struct." + str + "* \%t" + theLHS.theVar.varIndex + ", i32 0, i32 " + i.theVar.varIndex);
                  TextCode.add("\tstore i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + idx);
               } 
               else if ((t == Type.INT) && (theRHS.theType == Type.CONST_INT)) {
                  TextCode.add("\t\%t" + idx + " = getelementptr inbounds \%struct." + str + ", \%struct." + str + "* \%t" + theLHS.theVar.varIndex + ", i32 0, i32 " + i.theVar.varIndex);
                  TextCode.add("\tstore i32 " + theRHS.theVar.iValue + ", i32* \%t" + idx);				
               }
            }
      
      ) 
      ;

/********************************* */
argument_return[Func thefunc, String name, Info IDinfo] returns[Info theInfo]
   :
      
   a = arg[thefunc]
         {
            String tempcode = new String();
            if($a.theInfo.theType == Type.INT)
               tempcode = "i32  \%t" + Integer.toString($a.theInfo.theVar.varIndex);
         }

   (',' b = arg[thefunc]
         {
            tempcode += ", ";
            if($b.theInfo.theType == Type.INT)
               tempcode += "i32  \%t" + Integer.toString($b.theInfo.theVar.varIndex);
         }
   )*
   { 
      int temp = thefunc.newvar();
      Func func = functab.get(name);
      if(func.theType == Type.INT){
         TextCode.add("\t\%t" + temp + " = call i32 @" + name + "(" + tempcode + ")");
         TextCode.add("\tstore i32 \%t" + temp + ", i32* \%t" + IDinfo.theVar.varIndex);	
      }
   }
   ;


/********************************* */
func_no_return_stmt [Func thefunc]
   :  'printf' '(' printf_argument[thefunc] ')'
   |  Identifier '(' argument[thefunc, $Identifier.text] ')'
   ;



/********************************* */
argument[Func thefunc, String name]
   :
      
   a = arg[thefunc]
         {
            String tempcode = new String();
            if($a.theInfo.theType == Type.INT)
               tempcode = "i32 \%t" + Integer.toString($a.theInfo.theVar.varIndex);
         }

   (',' b = arg[thefunc]
         {
            tempcode += ", ";
            if($b.theInfo.theType == Type.INT)
               tempcode += "i32 \%t" + Integer.toString($b.theInfo.theVar.varIndex);
         }
   )*
   { 
      Func func = functab.get(name);
      if(func.theType == Type.INT)
         TextCode.add("\tcall i32 @" + name + "(" + tempcode + ")");
      else if(func.theType == Type.VOID)
         TextCode.add("\tcall void @" + name + "(" + tempcode + ")");
   }
   ;

/********************************* */
printf_argument[Func thefunc] returns [print_para thepara] @init {thepara = new print_para();}
   : a = arg[thefunc]
         {  
            int len = $a.theInfo.theVar.sValue.length()+1;
            String s = $a.theInfo.theVar.sValue;
            if (s.endsWith("\\n")) len--;

            s = s.replace("\\n","\\0A");
            TextCode.add(1 , "@t"+ varCount + " = constant [" + len + " x i8] c\"" + s + "\\00\"");
            $thepara.varcrec = varCount;
            varCount ++;
         
         }
   (',' b = arg[thefunc]
         {
            String rec = ", i32 \%t"+ $b.theInfo.theVar.varIndex;
            thepara.para += rec;
         }
   )*
   { TextCode.add("\tcall i32 (i8*, ...) @printf(i8* getelementptr inbounds ([" + len + " x i8], [" + len +" x i8]* @t" + $thepara.varcrec + ", i32 0, i32 0)" + $thepara.para + ")");}
   ;

/********************************* */
arg[Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
   : arith_expression[thefunc]  { $theInfo=$arith_expression.theInfo; } 
   | STRING_LITERAL
      {
         String s = $STRING_LITERAL.text;
         $theInfo.theType = Type.STRING;
         $theInfo.theVar.sValue = s.substring(1, s.length() - 1);
      }
   ;





/********************************* */
logical_expr[Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
      : a=and_expr[thefunc] { $theInfo=$a.theInfo; }
      ( '||' b=and_expr[thefunc]
            // { 
            //       Info theLHS = $a.theInfo; 
            //       Info theRHS = $b.theInfo;

            //       // code generation 				   
            //       int temp = thefunc.newvar();
            //       if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
            //          TextCode.add("\t\%t" + temp + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
            //          // Update arith_expression's theInfo.
            //          $theInfo.theType = Type.INT;
            //          $theInfo.theVar.varIndex = temp;
            //       } 
                  
            //    }

      
      )*
      ;

and_expr[Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
      : a=not_expr[thefunc] { $theInfo=$a.theInfo; }
      ( '&&' b=not_expr[thefunc] 
      )
      ;

not_expr[Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
      : a=pri_expr[thefunc] { $theInfo=$a.theInfo; }

      | '!'b=pri_expr[thefunc]
      ;

pri_expr[Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
      : cond_expression [thefunc]
      ;

/********************************* */
cond_expression[Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
   : a=arith_expression[thefunc] 
   ( '>' b=arith_expression[thefunc]
      {
         int temp = thefunc.newvar();
         if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sgt i32 \%t"+$a.theInfo.theVar.varIndex +", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sgt i32 \%t"+$a.theInfo.theVar.varIndex +", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sgt i32 "+$a.theInfo.theVar.iValue +", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sgt i32 "+$a.theInfo.theVar.iValue +", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
      }
   | '<' b=arith_expression[thefunc]
      {
         int temp = thefunc.newvar();
         if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp slt i32 \%t"+$a.theInfo.theVar.varIndex+", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;


         }
         else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {

            TextCode.add("\t\%t"+ temp +" = icmp slt i32 \%t"+$a.theInfo.theVar.varIndex+", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp slt i32 "+$a.theInfo.theVar.iValue +", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
            
         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp slt i32 "+$a.theInfo.theVar.iValue +", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
      }
   | '>=' b=arith_expression[thefunc]
      {
         int temp = thefunc.newvar();
         if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sge i32 \%t"+$a.theInfo.theVar.varIndex+", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {

            TextCode.add("\t\%t"+ temp +" = icmp sge i32 \%t"+$a.theInfo.theVar.varIndex+", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sge i32 "+$a.theInfo.theVar.iValue +", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sge i32 "+$a.theInfo.theVar.iValue +", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
      }
   | '<=' b=arith_expression[thefunc]
      {
         int temp = thefunc.newvar();
         if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sle i32 \%t"+$a.theInfo.theVar.varIndex+", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {

            TextCode.add("\t\%t"+ temp +" = icmp sle i32 \%t"+$a.theInfo.theVar.varIndex+", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sle i32 "+$a.theInfo.theVar.iValue +", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp sle i32 "+$a.theInfo.theVar.iValue +", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
      }
   | '==' b=arith_expression[thefunc]
      {
         int temp = thefunc.newvar();
         if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp eq i32 \%t"+$a.theInfo.theVar.varIndex+", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {

            TextCode.add("\t\%t"+ temp +" = icmp eq i32 \%t"+$a.theInfo.theVar.varIndex+", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\%t"+ temp +" = icmp eq i32 "+$a.theInfo.theVar.iValue +", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp eq i32 "+$a.theInfo.theVar.iValue +", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
      }
   | '!=' b=arith_expression[thefunc]
      {
         int temp = thefunc.newvar();
         if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp ne i32 \%t"+$a.theInfo.theVar.varIndex+", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {

            TextCode.add("\t\%t"+ temp +" = icmp ne i32 \%t"+$a.theInfo.theVar.varIndex+", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;

         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp ne i32 "+$a.theInfo.theVar.iValue +", \%t"+$b.theInfo.theVar.varIndex);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t"+ temp +" = icmp ne i32 "+$a.theInfo.theVar.iValue +", "+$b.theInfo.theVar.iValue);
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
      }
   )
   ;
			   



/********************************* */
arith_expression[Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
         : a=multExpr[thefunc] { $theInfo=$a.theInfo; }
            ( '+' b=multExpr[thefunc]
               
               { 
                  // type checking 
                  Info theLHS = $a.theInfo; 
                  Info theRHS = $b.theInfo;

                  if((theRHS.theType != theLHS.theType) 
                     && !(theLHS.theType == Type.INT && theRHS.theType == Type.CONST_INT)
                     && !(theRHS.theType == Type.INT && theLHS.theType == Type.CONST_INT)
                     && !(theLHS.theType == Type.FLOAT && theRHS.theType == Type.CONST_FLOAT)
                     && !(theRHS.theType == Type.FLOAT && theLHS.theType == Type.CONST_FLOAT)){
                        
                        System.out.println("Type Error: "  + ": Type mismatch for the two side operands in an assignment statement.");
                        System.exit(0);
                     
                  }
                  // code generation 				   
                  int temp = thefunc.newvar();
                  if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
                     TextCode.add("\t\%t" + temp + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
                     // Update arith_expression's theInfo.
                     $theInfo.theType = Type.INT;
                     $theInfo.theVar.varIndex = temp;
                  } 
                  else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                     TextCode.add("\t\%t" + temp + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
                     // Update arith_expression's theInfo.
                     $theInfo.theType = Type.INT;
                     $theInfo.theVar.varIndex = temp;
                  }
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
                     TextCode.add("\t\%t" + temp + " = add nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
                     // Update arith_expression's theInfo.
                     $theInfo.theType = Type.INT;
                     $theInfo.theVar.varIndex = temp;
                  }
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
                     TextCode.add("\t\%t" + temp + " = add nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
                     // Update arith_expression's theInfo.
                     $theInfo.theType = Type.INT;
                     $theInfo.theVar.varIndex = temp;
                  }
               }
               
               
            | '-' c = multExpr[thefunc]
                
               {
                  // type checking 
                  Info theLHS = $a.theInfo; 
                  Info theRHS = $c.theInfo;

                  if((theRHS.theType != theLHS.theType) 
                     && !(theLHS.theType == Type.INT && theRHS.theType == Type.CONST_INT)
                     && !(theRHS.theType == Type.INT && theLHS.theType == Type.CONST_INT)
                     && !(theLHS.theType == Type.FLOAT && theRHS.theType == Type.CONST_FLOAT)
                     && !(theRHS.theType == Type.FLOAT && theLHS.theType == Type.CONST_FLOAT)){
                        
                        System.out.println("Type Error: "  + ": Type mismatch for the two side operands in an assignment statement.");
                        System.exit(0);
                     
                  }


                  // code generation 		
                  int temp = thefunc.newvar();	   
                  if (($a.theInfo.theType == Type.INT) && ($c.theInfo.theType == Type.INT)) {
                     TextCode.add("\t\%t" + temp + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
                     // Update arith_expression's theInfo.
                     $theInfo.theType = Type.INT;
                     $theInfo.theVar.varIndex = temp;
                  } 
                  else if (($a.theInfo.theType == Type.INT) && ($c.theInfo.theType == Type.CONST_INT)) {
                     TextCode.add("\t\%t" + temp + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
                     // Update arith_expression's theInfo.
                     $theInfo.theType = Type.INT;
                     $theInfo.theVar.varIndex = temp;
                  }
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($c.theInfo.theType == Type.INT)) {
                     TextCode.add("\t\%t" + temp + " = sub nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $c.theInfo.theVar.varIndex);
                     // Update arith_expression's theInfo.
                     $theInfo.theType = Type.INT;
                     $theInfo.theVar.varIndex = temp;
                  }
                  else if (($a.theInfo.theType == Type.CONST_INT) && ($c.theInfo.theType == Type.CONST_INT)) {
                     TextCode.add("\t\%t" + temp + " = sub nsw i32 " + $theInfo.theVar.iValue + ", " + $c.theInfo.theVar.iValue);
                     // Update arith_expression's theInfo.
                     $theInfo.theType = Type.INT;
                     $theInfo.theVar.varIndex = temp;
                  }
               }
            )*
         ;

/********************************* */
multExpr [Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
   : a=signExpr[thefunc] { $theInfo=$a.theInfo; }
   ( '*' b=signExpr[thefunc]
      {
         int temp = thefunc.newvar();
         if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t" + temp + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
            // Update arith_expression's theInfo.
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         } 
         else if (($a.theInfo.theType == Type.INT) && ($b.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t" + temp + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
            // Update arith_expression's theInfo.
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t" + temp + " = mul nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
            // Update arith_expression's theInfo.
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($b.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t" + temp + " = mul nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
            // Update arith_expression's theInfo.
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
      }
   | '/' c=signExpr[thefunc]
      {
         int temp = thefunc.newvar();
         if (($a.theInfo.theType == Type.INT) && ($c.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t" + temp + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
            // Update arith_expression's theInfo.
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         } 
         else if (($a.theInfo.theType == Type.INT) && ($c.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t" + temp + " = sdiv i32 \%t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
            // Update arith_expression's theInfo.
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($c.theInfo.theType == Type.INT)) {
            TextCode.add("\t\%t" + temp + " = sdiv i32 " + $theInfo.theVar.iValue + ", \%t" + $c.theInfo.theVar.varIndex);
            // Update arith_expression's theInfo.
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
         else if (($a.theInfo.theType == Type.CONST_INT) && ($c.theInfo.theType == Type.CONST_INT)) {
            TextCode.add("\t\%t" + temp + " = sdiv i32 " + $theInfo.theVar.iValue + ", " + $c.theInfo.theVar.iValue);
            // Update arith_expression's theInfo.
            $theInfo.theType = Type.INT;
            $theInfo.theVar.varIndex = temp;
         }
      }
   )*
   ;

/********************************* */
signExpr [Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
      : a=primaryExpr[thefunc] { $theInfo=$a.theInfo; } 
      | '-' b=primaryExpr[thefunc]
         {
            int temp = thefunc.newvar();
            if($b.theInfo.theType == Type.INT){
               TextCode.add("\t\%t" + temp + " = sub nsw i32 " + 0 + ", \%t" + $b.theInfo.theVar.varIndex);
               $theInfo.theType = Type.INT;
               $theInfo.theVar.varIndex = temp;
            }
            else if($b.theInfo.theType == Type.CONST_INT){
               TextCode.add("\t\%t" + temp + " = sub nsw i32 " + 0 + ", " + $b.theInfo.theVar.iValue);
               $theInfo.theType = Type.INT;
               $theInfo.theVar.varIndex = temp;
            }
         }
      
	   ;
		  

/********************************* */
primaryExpr [Func thefunc] returns [Info theInfo] @init {theInfo = new Info();}
      : Integer_constant
         {
            if(TRACEON) System.out.println("int const");
            $theInfo.theType = Type.CONST_INT;
            $theInfo.theVar.iValue = Integer.parseInt($Integer_constant.text);
         }
      | Floating_point_constant
         {
            $theInfo.theType = Type.CONST_FLOAT;
            $theInfo.theVar.fValue = Float.parseFloat($Floating_point_constant.text);
         }
      | a=Identifier
         ('.' b=Identifier 
               {
                  Info theLHS = thefunc.symtab.get($a.text); 
                  String str = theLHS.theVar.sValue;       // struct name
                  HashMap<String, Info> vartab = structtab.get(str);
                  Info i = vartab.get($b.text);
                  Type t = i.theType;

                  $theInfo.theType = t;

                  int idx = thefunc.newvar();
                  int temp = thefunc.newvar();
                  switch (t) {
                     case INT: 
                        TextCode.add("\t\%t" + idx + " = getelementptr inbounds \%struct." + str + ", \%struct." + str + "* \%t" + theLHS.theVar.varIndex + ", i32 0, i32 " + i.theVar.varIndex);
                        TextCode.add("\t\%t" + temp + "=load i32, i32* \%t" + idx + ", align 4");
                        $theInfo.theVar.varIndex = temp;
                        break;

                     case FLOAT:
                        TextCode.add("\t\%t" + idx + " = getelementptr inbounds \%struct." + str + ", \%struct." + str + "* \%t" + theLHS.theVar.varIndex + ", i32 0, i32 " + i.theVar.varIndex);
                        TextCode.add("\t\%t" + temp + " = load float, float* \%t" + idx + ", align 4");
                        $theInfo.theVar.varIndex = temp;
                        break;
                     case CHAR:
                        break;
         
                  }
               }
         |
               {
                  // get type information from symtab.
                  Type the_type = thefunc.symtab.get($a.text).theType;
                  $theInfo.theType = the_type;

                  // get variable index from symtab.
                  int vIndex = thefunc.symtab.get($a.text).theVar.varIndex;
                  int temp = thefunc.newvar();
            
                  switch (the_type) {
                     case INT: 
                        // get a new temporary variable and
                        // load the variable into the temporary variable.
                        // Ex: \%tx = load i32, i32* \%ty.
                        TextCode.add("\t\%t" + temp + "=load i32, i32* \%t" + vIndex);
                        
                        // Now, Identifier's value is at the temporary variable \%t[varCount].
                        // Therefore, update it.
                        $theInfo.theVar.varIndex = temp;
                        break;

                     case FLOAT:
                        TextCode.add("\t\%t" + temp + " = load float, float* \%t" + vIndex + ", align 4");
                        $theInfo.theVar.varIndex = temp;
                        break;
                     case CHAR:
                        break;
         
                  }
               }
         )
         
	   | '&' Identifier
	   | '(' arith_expression[thefunc] ')' { $theInfo = $arith_expression.theInfo; }
      ;
/********************************* */
		   


/* description of the tokens */
FLOAT:'float';
INT:'int';
CHAR: 'char';

// MAIN: 'main';
VOID: 'void';
IF: 'if';
ELSE: 'else';
FOR: 'for';
WHILE: 'while';
SWITCH: 'switch';
CASE: 'case';
BREAK: 'break';
DEFAULT: 'default';

GT: '>';
GE: '>=';
LT: '<';
LE: '<=';
EQ: '==';
NE: '!=';

Identifier:('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
Integer_constant:('0' | '1'..'9' '0'..'9'*);
Floating_point_constant:'0'..'9'+ '.' '0'..'9'+;

STRING_LITERAL
    :  '"' ( EscapeSequence | ~('\\'|'"') )* '"'
    ;

WS:( ' ' | '\t' | '\r' | '\n' ) {$channel=HIDDEN;};
/* Comments */
COMMENT1 : '//'(.)*'\n' {$channel=HIDDEN;};
COMMENT2 : '/*' (options{greedy=false;}: .)* '*/'{$channel=HIDDEN;};

fragment
EscapeSequence
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    ;

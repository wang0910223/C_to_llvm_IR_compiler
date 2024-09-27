void sub(int a, int b){
   a = a-b;
   printf("a = %d\n", a);
}


int add(int a, int b){
   a = a+b;
   return a;
}


int main()
{
   int a;

   a = 10;
   sub(a, a+2);
   a = add(a, a+2);
   printf("a = %d\n",a);

   return 0;
   
}

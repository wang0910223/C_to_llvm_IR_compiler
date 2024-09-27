int main()
{
   int a;
   a = 1;

   if(a==0){
      printf("enter if\n");

   }
   else if(a==3){
      printf("enter else if 1\n");
   }
   else if(a==2){
      printf("enter else if 2\n");
   }
   else{
      printf("enter else \n");

      if(a == 1){
         printf("enter else{ if{} }\n");
      }

   }
   return 0;
}

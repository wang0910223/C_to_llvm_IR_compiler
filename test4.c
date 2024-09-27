int main(){
    int a;
    int b;

    b=3;

    for(a=0; a<b; a=a+1){
      printf("a = %d\n", a);

      if(a <= 0){
         printf(" a <= 0\n");
      }
      else{
         printf(" a > 0\n");
      }
   }


   return 0;
}
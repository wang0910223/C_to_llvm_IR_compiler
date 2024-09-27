int main() {
  int a;
  int b;
  int sum;
  int res;

  a = 80;
  b = 90;

  if (a > b) {
    printf("a is greater than b\n");
  } 
  else {
    printf("a is grater or equal to b\n");
  }

  sum = a + b;

  printf("a + b = %d\n", sum);

  res = (a + 1) * (b - 1) / 4 * 5 - b + 1 + 4 * a;

  printf("res = %d\n", res);

  if (res <= 69420) {
    printf("res is less than or equal to 69420\n");
  } 
  else {
    printf("res is greater than 69420\n");
  }

  return 0;
}
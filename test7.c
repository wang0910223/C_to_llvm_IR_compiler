struct node{
    int a;
    int b;

};
struct t{
    int c;
    int d;
};


int main(){
    int sum;
    struct node node1;
    struct t t1;

    t1.c = 3;
    t1.d = 2;
    sum = t1.c * t1.d;
    printf("t1.c = %d,  t1.d = %d,  t1.c * t1.d = %d\n", t1.c, t1.d, sum);

    node1.a = 9;
    node1.b = 2;
    sum = node1.a + node1.b;

    printf("node1.a = %d,  node1.b = %d,  node1.a + node1.b = %d\n", node1.a, node1.b, sum);
    return 0;

}
# Compiler Project NTUST
## 作者: [HaHa, You can still check this from commit history]

## 變動:
1.1 整個symbol table換掉  
1.2 新的symbol table整合成AST  
1.3 語法轉成AST，在AST內部做type check  

## 編譯/Build
```
make
```

## 使用說明
```
./parser < testcase/fib.scala > fib.jasm
javaa fib.jasm 
java fib 
```

或者用我寫的bash
```
./parser < testcase/fib.scala > fib.jasm 
source run.sh fib
```

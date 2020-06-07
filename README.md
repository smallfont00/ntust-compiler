# 作者: 陳泳峰 B10615004

# Lex 變動:
## 1.1 把一些non-terminal前或後加上 ``[\n ]*`` 來避免syntax error
## 1.2 使用bison編繹出來的emnumber
## 1.3 把所有的keyword都分成不同行來return不同的token(enumber)

# 編譯/Build
## `` make ``

# 使用說明
## `` ./parser < testcase/fib.scala `` 
object fibonacci
{
  def fib (n:int):int {
      if (n <= 0) return 0 
      if (n == 1 || n == 2) return 1
      return fib(n - 1) + fib(n - 2)
  }

  def main () {
    // print result
    print ("Result of computation: ")
    println (fib(8))
  }
}

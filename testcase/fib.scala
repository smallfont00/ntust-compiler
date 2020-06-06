/* fib.scala
 *
 * This test program computes the Nth Fibonacci number
 */

object fib
{
  // variables
  var n: int = 8
  var Fn: int = 1
  var FNminus1: int = 1
  var temp: int

  def main () {
    // compute the nth Fibonacci number
    while (n > 2) {
      var a = 0
      temp = Fn
      while (n > 2) {
        var a = 0
        temp = Fn
        Fn = Fn + FNminus1
        FNminus1 = temp
        n = n - 1
      }
      temp()
      Fn = Fn + FNminus1
      FNminus1 = temp
      n = n - 1
    }
    
    for (a <- 10 to 100) print(a)
    
    // print result
    print ("Result of computation: ")
    println (n)
  }
}

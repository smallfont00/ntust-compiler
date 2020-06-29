/* fib.scala
 *
 * This test program computes the Nth Fibonacci number
 */

object fib
{
  // variables
  var n: boolean = true
  var Fn: int = 1
  var FNminus1: int = 1
  var temp: int
  val constabc = 1
  def fuck(a:boolean) : boolean {
      return !a && true || false || false
  }
  def main () {
    // compute the nth Fibonacci number
    var a = 2
    var b = 3
    val c = a + b
    println a
    println b
    println c
    println constabc
    
    n = n && true
    while (n) {
      temp = Fn
      Fn = Fn + FNminus1
      FNminus1 = temp
      n = fuck(n)
      //n = n - 1
    }
    
    // print result
    print ("Result of computation: ")
    println (Fn)

     while(false) print(4)
      while(false) print(4)
      if (false) if (false) if (false) print(1) else print(2) else print(3)
      if (false) if (false) if (false) print(1) else print(2) else print(3)
    while(false) {
        if (false) if (false) if (false) print(1) else print(2) else print(3)
        while(false) print(4)
    }
    if (false) if (false) if (false) print(1) else print(2) else print(3)
    if (false) if (false) if (false) print(1) else print(2) else print(3)
     while(false) print(4)
      while(false) print(4)
  }
}

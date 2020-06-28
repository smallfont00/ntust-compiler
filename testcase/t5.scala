/* fib.scala
 *
 * This test program computes the Nth Fibonacci number
 */

object fib
{
  // variables
  var n: int = 8
  var Fn: int = 1
  var temp: int
  val test: int = 8
  def FIB (n:int) : int {
    var Fn: int = 1
    var FNminus1: int = 1
    var temp: int
    while (n > 2 ) {
      temp = Fn
      Fn = Fn + FNminus1
      FNminus1 = temp
      n = n - 1
    }
    return Fn
  }
  
  def main () {
    // compute the nth Fibonacci number
    //var nothing
    Fn = FIB(n)
    // print result
    print ("Result of computation1:")
    println (Fn)
    n = 7
    Fn = FIB(n)
    // print result
    print ("Result of computation2:")
    println (Fn)
    n = 2
    if (n <= 2)
    {
      var ttt = 10 * 2
      if (n == 2) println (ttt)
      else println("n < 2")
      if (Fn > 5)
        if (Fn > 10)
          if (Fn > 15) println ("Fn > 15")
          else println ("10 < Fn < 15")
    } 
    else
    { 
      var temp = 20
      val test = 80 * 5 + temp
      temp = FIB(temp)
      print("Fn = ")
      println(temp)
      print("Local constant test = ")
      println (test)
    }
    print("global constant test = ")
    println (test)
    print("global var temp = ")
    println (temp)
  }
}

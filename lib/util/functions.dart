import 'dart:math';

class Functions{
  ///Only displays a value over its final percentage. 
  ///The final split is outputted in values
  static double animateOver(double value, {double percent = 1.0}){
    assert(percent != null && percent >= 0 && percent <= 1.0);
    assert(value != null && value >= 0);

    double remainder = 1.0 - percent;

    return max(0, (value - percent) / remainder);
  }
}
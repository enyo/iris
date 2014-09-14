library annotations;

import "iris.dart";

/**
 * Use this annotation on methods in a [Service] class to tell [Iris]
 * that the method is a procedure.
 *
 * All methods having this annotation must implement the [ProcedureMethod] typedef.
 */
class Procedure {

  final List<FilterFunction> filters;

  /**
   * The order of this List defines the order of the execution of the filters.
   */
  const Procedure({this.filters: const []});

}


/**
 * Use this annotation on services to define filters that should be applied on
 * all procedures.
 *
 * This annotation is optional. If you don't have any service filters, you don't
 * need to assign this annotation.
 */
class IrisService {

  /**
   * The path to the .proto template which defines this service
   * (from the root of the protobuffer directory.
   */
  final String declaredIn;

  final List<FilterFunction> filters;

  /**
   * The order of this List defines the order of the execution of the filters.
   */
  const IrisService(String this.declaredIn, {this.filters: const []});

}

/**
 * Use this annotation on a class or top level function to copy the code into
 * the compiled iris library.
 */
const include = const IrisInclude();

class IrisInclude {
  const IrisInclude();
}
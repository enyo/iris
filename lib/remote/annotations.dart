library annotations;

import "iris.dart";

/**
 * Use this annotation on methods in a [Remote] class to tell [Iris]
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
 * Use this annotation on remotes to define filters that should be applied on
 * all procedures.
 *
 * This annotation is optional. If you don't have any remote filters, you don't
 * need to assign this annotation.
 */
class Remote {

  final List<FilterFunction> filters;

  /**
   * The order of this List defines the order of the execution of the filters.
   */
  const Remote({this.filters: const []});

}
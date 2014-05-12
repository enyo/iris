library annotations;

import "remote_services.dart";

/**
 * Use this annotation on methods in a [Service] class to tell [ServiceDefinitions]
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
class Service {

  final List<FilterFunction> filters;

  /**
   * The order of this List defines the order of the execution of the filters.
   */
  const Service({this.filters: const []});

}
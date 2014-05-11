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


  const Procedure({this.filters: const []});

}



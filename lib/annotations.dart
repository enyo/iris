library annotations;

import "remote_services.dart";

/**
 * Use this annotation on methods in a [Service] class to tell [RemoteServices]
 * that the method is a route.
 *
 * All methods having this annotation must implement the [RouteMethod] typedef.
 */
class Route {

  final List<FilterFunction> filters;


  const Route({this.filters});

}



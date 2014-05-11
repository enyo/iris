part of remote_services;

/**
 * The signature of a route in a [Service].
 */
typedef Future<GeneratedMessage> RouteMethod(Context context, GeneratedMessage request);


/**
 * The base class all services must extend.
 *
 * For now this doesn't do anything.
 */
class Service {

}

part of remote_services;

/**
 * The signature of a procedure in a [Service].
 */
typedef Future<GeneratedMessage> ProcedureMethod(Context context, GeneratedMessage request);


/**
 * The base class all services must extend.
 *
 * For now this doesn't do anything.
 */
class Service {

}

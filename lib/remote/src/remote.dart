part of iris;

/**
 * The signature of a procedure in a [Remote].
 */
typedef Future<GeneratedMessage> ProcedureMethod(Context context, GeneratedMessage request);


/**
 * The base class all services must extend.
 *
 * For now this doesn't do anything.
 */
class Remote {

}

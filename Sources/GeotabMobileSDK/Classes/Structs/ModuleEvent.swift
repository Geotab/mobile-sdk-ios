/// :nodoc:
public struct ModuleEvent {
    /**
     event name
     */
    let event: String
    /**
     A CustomEventInit dictionary JSON stringified, having the following fields:
     
     - "detail", optional and defaulting to null, of type any, that is an event-dependent value associated with the event.
     */
    let params: String
    public init(event: String, params: String) {
        self.event = event
        self.params = params
    }
}

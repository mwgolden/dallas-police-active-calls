class Event {
    constructor(evt) {
        this.eventType = evt.event
        this.data = evt.data
    }
}

export class EventStreamHandler {

    constructor(callObject, mapObject) {
        this.calls = callObject
        this.map = mapObject
    }

    registerEventHandlerWith(aFunction) {
        aFunction(this.eventStreamHandler)
    }
    
    eventStreamHandler(streamedEvent) {
        try {
            const evnt = new Event(JSON.parse(streamedEvent))
            if(evnt.eventType === "call_changes") {
                this.mergeCallEvents(evnt.data)
            }
            if(evnt.eventType === "address_changes") {
                this.mergeAddressEvents(evnt.data)
            }
        }
        catch (error) {
            console.error("Error parsing JSON string: ", error)
        }
    }

    mergeCallEvents(callEvents) {
        console.log("merge call events")
        callEvents.forEach(call => {
            const changeType = call.change_type
            if(changeType === "add"){
                this.addCall(call)
            }
            if(changeType === "delete"){
                this.deleteCall(call)
            }
            if(changeType === "update"){
                this.updateCall(call)
            }
        })
    }

    deleteCall(call) {
        const callId = call.callId
        map.remove_marker(callId)
        this.calls.deleteCall(call)
    }

    addCall(call) {
        this.calls.addCall(call)
    }


    mergeAddressEvents(addressEvent) {
        console.log(addressEvent)
    }
}
import { Call, Location } from "./calls.js"
import { setCallDetails } from "./templates.js"

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

    handleEventStream(streamedEvent) {
        try {
            console.log("streamed event: ", streamedEvent)
            console.log("streamed event type: ", typeof streamedEvent)
            const evnt = new Event(streamedEvent)
            if(evnt.eventType === "call_changes") {
                const eventCalls = evnt.data.map(item => {
                    return new Call(item)
                })
                this.mergeCallEvents(eventCalls)
            }
            if(evnt.eventType === "address_changes") {
                const eventLocations = evnt.data.map(item => {
                    const address = item.addresses[0]
                    return new Location({
                        "address_id": item.address_id,
                        "coords": [address.latitude, address.longitude]
                    })
                })
                this.mergeLocationEvents(eventLocations)
            }
            this.updateMap()
        }
        catch (error) {
            console.error("Error parsing JSON string: ", error)
        }
    }

    mergeCallEvents(eventCalls) {
        const toAdd = Array()
        const toDelete = Array()
        const toUpdate = Array()
        eventCalls.forEach(call => {
            const changeType = call.changeType
            if(changeType === "add"){
                toAdd.push(call)
            }
            if(changeType === "delete"){
                toDelete.push(call)
            }
            if(changeType === "update"){
                toUpdate.push(call)
            }
        })
        this.deleteCalls(toDelete)
        this.addCalls(toAdd)
        this.updateCalls(toUpdate)
    }

    deleteCalls(deleteCalls) {
        deleteCalls.forEach(call => {
            const callId = call.callId
            this.map.remove_marker(callId)
            this.calls.deleteCall(call)
        })
    }

    addCalls(addCalls) {
        addCalls.forEach(call => {
            this.calls.addCall(call)
        })
    }

    updateCalls(updateCalls) {
        updateCalls.forEach(call => {
            this.calls.updateCall(call)
        })
    }

    mergeLocationEvents(locationEvent) {
        locationEvent.forEach(location => {
            this.calls.addLocation(location)
        })
    }

    updateMap() {
        const locations = this.calls.getLocations()
        this.map.add_markers(locations, (marker) => {
            const callId = marker["callId"]
            const call = this.calls.getCallById(callId)
            setCallDetails(call)
            console.log(call)
        })
    }
}
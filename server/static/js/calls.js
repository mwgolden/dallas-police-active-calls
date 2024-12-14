export class Call {
    constructor(call) {
        this.callId = call.call_id
        this.updateDate = call.update_date
        this.locationId = call.address_id
        this.beat = call.beat
        this.block = call.block
        this.changeType = call.change_type
        this.date = call.date
        this.division = call.division
        this.expiresOn = call.expires_on
        this.incidentNumber = call.incident_number
        this.location = call.location
        this.natureOfCall = call.nature_of_call
        this.priority = call.priority
        this.reportingArea = call.reporting_area
        this.status = call.status
        this.time = call.time
        this.unitNumber = call.unit_number
    }
}

export class Location {
    constructor(location) {
        this.locationId = location.locationId
        this.coords = location.coords
    }
}

export class ActiveCalls {

    constructor() {
        this.calls = {}
        this.locations = {}
    }

    getCallById(callId) {
        return this.calls[callId]
    }

    addCall(call) {
        const callId = call.callId
        if(this.getCallById(callId)) { return }
        this.calls[callId] = call
    }

    deleteCall(call) {
        const callId = call.callId
        if(this.getCallById(callId)) { delete this.calls[callId] }
    }

    updateCall(newCall) {
        const callId = newCall.callId
        if(this.calls.has(callId)) {
            this.calls[callId] = newCall
        }
        else {
            this.addCall(newCall)
        }
    }

    getLocationById(locationId) {
        return this.locations[locationId]
    }

    addLocation(location) {
        const locationId = location.locationId
        if(this.getLocationById(locationId)) { return }
        this.locations[locationId] = location
    }

    deleteLocation(location) {
        const locationId = location.locationId
        if(this.getLocationById(locationId)) { delete this.locations[locationId] }
    }

    updateLocation(location) {
        const locationId = location.locationId
        if(this.locations.has(locationId)) {
            this.locations[locationId] = location
        }
        else {
            this.addLocation(location)
        }
    }

    getLocations() {
        const locs = Array()
        for(const callId in this.calls) {
            const call = this.calls[callId]
            const locationId = call.locationId
            if(locationId in this.locations) {
                const loc = {"callId": callId, "locationId": call.locationId, "coords": this.locations[locationId].coords }
                locs.push(loc)
            }
        }
        return locs
    }
}

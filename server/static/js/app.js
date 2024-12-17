import { currentCalls, subscribeToEvents } from './api.js'
import { Map } from './map.js'
import { ActiveCalls, Call, Location } from './calls.js'
import { EventStreamHandler } from './eventStreamHandler.js'


function app() {
    const map = new Map('map', { minZoom: 10 })
    const calls = new ActiveCalls()
    const streamHandler = new EventStreamHandler(calls, map)

    function getCurrentCalls(data) {
        data.current_active_calls.forEach(activeCall => {
            const call = new Call(activeCall)
            calls.addCall(call)
            if("address" in activeCall) {
                const address = activeCall.address
                if(address !== null && address.length > 0){
                    const location = new Location({
                        "address_id": activeCall.address_id,
                        "coords": [address[0].latitude, address[0].longitude]
                    })
                    calls.addLocation(location)
                }
            }
        })
        updateMap()
    }

    function markerClickHandler(marker) {
        const callId = marker["callId"]
        const call = calls.getCallById(callId)
        setCallDetails(call)
        console.log(call)
    }

    function updateMap() {
        const locations = calls.getLocations()
        map.add_markers(locations, markerClickHandler)
    }

    function formatDate(DateString) {
        const date = new Date(DateString)
        const formattedDate = date.toLocaleDateString('en-US', 
            {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            }
        )
        return formattedDate
    }

    function toTitleCase(str) {
        return str
            .split(' ')
            .map(word => word.charAt(0).toUpperCase + word.slice(1))
            .join(' ')
    }
    
    function setCallDetails(call) {
        const container = document.getElementById("call-detail")
        const formattedDate = formatDate(call.date)
        const titleCaseLocation = toTitleCase(call.location)
        const card = `<div class="card">
                            <div class="card-header">
                                <b>${call.incidentNumber} | ${call.natureOfCall}</b>
                            </div>
                            <div class="card-body">
                                <p class=card-text">
                                    On ${formattedDate}, at ${call.block === undefined ? "" : call.block } ${call.location} in the ${call.division} division, unit ${call.unitNumber} responded to a Priority ${call.priority} incident in Reporting Area ${call.reportingArea}. The status is currently "${call.status}."
                                </p>
                            </div>
                        </div>`
        container.innerHTML = card
    }

    function initialize() {
        try {
            currentCalls(getCurrentCalls)
            updateMap()
            subscribeToEvents(streamHandler)     
        }
        catch (error) {
            console.error("Error initializing application", error)
        }
    }
    
    initialize()
    
}

document.addEventListener('DOMContentLoaded', () => app() )
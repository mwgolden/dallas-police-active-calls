import { currentCalls, subscribeToEvents } from './api.js'
import Map from './map.js'
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
                if(address.length > 0){
                    const location = new Location({
                        "locationId": activeCall.address_id,
                        "coords": [address[0].latitude, address[0].longitude]
                    })
                    calls.addLocation(location)
                }
            }
        })
        updateMap()
    }

    function updateMap() {
        const locations = calls.getLocations()
        map.add_markers(locations, markerClickHandler)
    }

    function markerClickHandler(marker) {
        const callId = marker["callId"]
        const call = calls.getCallById(callId)
        console.log(call)
    }
    

    function initialize() {
        try {
            currentCalls(getCurrentCalls)
            updateMap()
            streamHandler.registerEventHandlerWith(subscribeToEvents)         
        }
        catch (error) {
            console.error("Error initializing application", error)
        }
    }
    
    initialize()
    
}

document.addEventListener('DOMContentLoaded', () => app() )
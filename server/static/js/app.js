import { currentCalls, subscribeToEvents } from './api.js'
import { Map } from './map.js'
import { ActiveCalls, Call, Location } from './calls.js'
import { EventStreamHandler } from './eventStreamHandler.js'
import { setCallDetails } from './templates.js'


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
        map.updateMapMarkers(calls, setCallDetails)
    }

    function initialize() {
        try {
            currentCalls(getCurrentCalls)
            subscribeToEvents(streamHandler)     
        }
        catch (error) {
            console.error("Error initializing application", error)
        }
    }
    
    initialize()
    
}

document.addEventListener('DOMContentLoaded', () => app() )
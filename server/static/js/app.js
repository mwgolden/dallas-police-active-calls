import { currentCalls, subscribeToEvents } from './api.js'
import Map from './map.js'


function app() {
    const map = new Map('map', { minZoom: 10 })
    let activeCalls = []
    let addresses = {}

    function getCurrentCalls(data) {
        activeCalls = data.current_active_calls
        addresses = activeCalls.map(call => {
            let addr = call.address
            if(addr.length > 0 && addr[0] !== null) {
                return {"call_id": call.call_id, "address_id": call.address_id, "address": addr[0]}
            }
        })
        .filter(Boolean)
        updateMap()
    }

    function updateMap() {
        const addressArray = addresses.map(addr => { 
            return {"call_id": addr.call_id,"address_id": addr.address_id, "coords": [addr.address.latitude, addr.address.longitude]}  
        })
        map.add_markers(addressArray, markerClickHandler)
    }

    function markerClickHandler(marker) {
        console.log(marker)
    }

    function initialize() {
        try {
            currentCalls(getCurrentCalls)
            subscribeToEvents()            
        }
        catch (error) {
            console.error("Error initializing application", error)
        }
    }
    
    initialize()
    
}

document.addEventListener('DOMContentLoaded', () => app() )
import { currentCalls, subscribeToEvents } from './api.js'
import Map from './map.js'


function app() {
    const map = new Map('map', { minZoom: 10 })
    let activeCalls = []

    function getCurrentCalls(data) {
        activeCalls = data.current_active_calls
        updateMap()
    }

    function updateMap() {
        const addressArray = activeCalls.map(call => { 
            const addr = call.address
            if(addr.length > 0 && addr[0] !== null) {
                return {"call_id": call.call_id, "coords": [addr[0].latitude, addr[0].longitude]}
            }
        })
        .filter(Boolean)
        map.add_markers(addressArray)
        console.log(addressArray)
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
import { current_calls } from './api.js'
import Map from './map.js'


function app() {
    const map = new Map('map', { minZoom: 10 })

    function get_current_calls(data) {
        const calls = data.current_active_calls
        const address_array = calls.map(call => { 
            const addr = call.address
            if(addr.length > 0) {
                return {"call_id": call.call_id, "coords": [addr[0].latitude, addr[0].longitude]}
            }
        })
        .filter(address => address !== "undefined" &&  address != null)
        map.add_markers(address_array)
        console.log(address_array)

    }

    current_calls(get_current_calls)
    
}

document.addEventListener('DOMContentLoaded', () => app() )
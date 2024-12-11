import { currentCalls, subscribeToEvents } from './api.js'
import Map from './map.js'


function app() {
    const map = new Map('map', { minZoom: 10 })
    let callMap = {}

    function getCurrentCalls(data) {
        data.current_active_calls.forEach(call => {
            const call_id = call.call_id
            const addr = call.address
            callMap[call_id] = call
        })
        updateMap()
    }

    function updateMap() {
        const addressArray = Object.keys(callMap).map(key => {
            const call = callMap[key]
            const address = call.address
            if(address !== null && address.length > 0) {
                return {"call_id": key,"address_id": call.address_id, "coords": [address[0].latitude, address[0].longitude]}
            }
        })
        map.add_markers(addressArray, markerClickHandler)
    }

    function markerClickHandler(marker) {
        const call_id = marker["call_id"]
        const call = callMap[call_id]
        console.log(call)
    }

    function eventStreamHandler(evt) {
        console.log("in event stream handler")
        console.log(typeof evt)
        const jsonObj = JSON.parse(evt.replace(/'/g, '"'))
        console.log(jsonObj)
        try {
            const event_type = jsonObj["event"]
            const data = jsonObj["data"]
            if(event_type === "call_changes") {
                mergeCallEvents(data)
            }
            if(event_type === "address_changes") {
                mergeAddressEvents(data)
            }
        }
        catch (error) {
            console.error("Error parsing JSON string: ", error)
        }
    }

    function mergeCallEvents(callEvents) {
        console.log("merge call events")
        callEvents.forEach(call => {
            const changeType = call.change_type
            if(changeType === "add"){
                addCall(call)
            }
            if(changeType === "delete"){
                deleteCall(call)
            }
            if(changeType === "update"){
                updateCall(call)
            }
        })
    }

    function deleteCall(call) {
        const call_id = call.call_id
        map.remove_marker(call_id)
        delete callMap[call_id]
    }

    function addCall(call) {
        const call_id = call.call_id
        callMap[call_id] = call
    }


    function updateCall(newCall) {
        const call_id = newCall.call_id
        const curCall = callMap[call_id]
        if(curCall) {
            Object.keys(newCall).forEach(key => {
                if(curCall[key] !== newCall[key]) {
                    curCall[key] = newCall[key]
                }
            })
        }
    }

    function mergeAddressEvents(addressEvent) {
        console.log(addressEvent)
    }
    

    function initialize() {
        try {
            currentCalls(getCurrentCalls)
            updateMap()
            subscribeToEvents(eventStreamHandler)            
        }
        catch (error) {
            console.error("Error initializing application", error)
        }
    }
    
    initialize()
    
}

document.addEventListener('DOMContentLoaded', () => app() )
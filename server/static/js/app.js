import { currentCalls, subscribeToEvents } from './api.js'
import { Map } from './map.js'
import { ActiveCalls } from './calls.js'
import { EventStreamHandler } from './eventStreamHandler.js'
import { setCallDetails } from './templates.js'


function app() {
    const map = new Map('map', { minZoom: 10 })
    const calls = new ActiveCalls()
    const streamHandler = new EventStreamHandler(calls, map)

    function handleCurrentActiveCalls(data) {
        const currentActiveCalls = ActiveCalls.fromApi(data)
        calls.merge(currentActiveCalls)
        map.updateMapMarkers(calls, setCallDetails)
    }

    function initialize() {
        try {
            currentCalls(handleCurrentActiveCalls)
            subscribeToEvents(streamHandler)     
        }
        catch (error) {
            console.error("Error initializing application", error)
        }
    }
    
    initialize()
    
}

document.addEventListener('DOMContentLoaded', () => app() )
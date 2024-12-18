const GEOJSON_URL = "/static/resources/dallas.geojson"

export class Map {
    constructor(id, config) {
        this.map = L.map(id, config)
        this.map.setView([32.7767, -96.7970], 10)
        this.add_tile_layer()
        this.highlight_neighborhoods()
        this.markers = {}
    }

    add_tile_layer() {
        L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
            maxZoom: 19,
            attribution: "&copy; <a href='http://www.openstreetmap.org/copyright'>OpenStreetMap</a>"
        }).addTo(this.map);
    }
    
    async fetch_geojson() {
        try {
                const response = await fetch(GEOJSON_URL);
                if(!response.ok) {
                throw new Error(`HTTP Error: ${response.status}`);
                }
                const geojson = await response.json();
                return geojson;
            }
        catch (error) {
            console.error("Error fetching file: ", error)
        }
    }
    
    highlight_neighborhoods() {
        this.fetch_geojson().then(data => {
            if(data) {
              L.geoJson(data, {
                style: {
                      "color": "#698df0",
                      "weight": 2,
                      "opacity": 0.5
                  },
                onEachFeature: function(feature, layer) {
                  layer.bindTooltip(feature.properties.name.toString(), 
                                   {permanent: false, className: "label"}),
                  layer.on({
                    click: function(event) {
                      this.map.fitBounds(layer.getBounds())
                    } 
                  })
                }
              }).addTo(this.map)
            }
        })
    }

    add_markers(locations, handler) {
        locations.forEach (location => {
            this.add_marker(location, handler)
        })
    }

    add_marker(location, handler) {
        const locationId = location["locationId"]
        const callId = location["callId"]
        if(this.markers[callId]) {
            return
        }
        let marker = L.marker(location.coords).addTo(this.map)
        marker.on("click", () => {
            const call = this.markers[callId]
            handler(call)
        })
        this.markers[callId] = {"callId": callId, "locationId": locationId, "marker": marker}
    }

    remove_marker(callId) {
        let markerEntry = this.markers[callId]
        if(markerEntry){
            const layer = markerEntry["marker"]
            this.map.removeLayer(layer)
            delete this.markers[callId]
        }
    }

    updateMapMarkers(calls, setCallDetailsCallback) {
        const locations = calls.getLocations()
        this.add_markers(locations, (marker) => {
            const callId = marker["callId"]
            const call = calls.getCallById(callId)
            setCallDetailsCallback(call)
            console.log(call)
        })
    }
}
const GEOJSON_URL = "/static/resources/dallas.geojson"

class Map {
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
                      //const center = layer.getBounds().getCenter()
                      //map.setView(center, 12)
                      this.map.fitBounds(layer.getBounds())
                    } 
                  })
                }
              }).addTo(this.map)
            }
        })
    }

    add_markers(addresses, handler) {
        addresses.forEach (address => {
            this.add_marker(address, handler)
        })
    }

    add_marker(address, handler) {
        const address_id = address["address_id"]
        const call_id = address["call_id"]
        if(this.markers[address_id]) {
            return
        }
        let marker = L.marker(address.coords).addTo(this.map)
        marker.on("click", () => {
            address = this.markers[address_id]
            handler(address)
        })
        this.markers[address_id] = {"call_id": call_id, "marker": marker}
    }

    remove_marker(address_id) {
        let markerEntry = this.markers[address_id]
        if(markerEntry){
            const layer = markerEntry["marker"]
            this.map.removeLayer(layer)
            delete this.markers[address_id]
        }
    }

}

export default Map
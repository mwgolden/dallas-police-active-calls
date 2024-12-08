const GEOJSON_URL = "/static/resources/dallas.geojson"

class Map {
    constructor(id, config) {
        this.map = L.map(id, config)
        this.map.setView([32.7767, -96.7970], 10)
        this.add_tile_layer_to()
        this.highlight_neighborhoods()
    }

    add_tile_layer_to() {
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
              console.log("add dallas neighborhoods to map")
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
                      map.fitBounds(layer.getBounds())
                    } 
                  })
                }
              }).addTo(this.map)
            }
        })
    }

    add_markers(addresses) {
        addresses.forEach (address => {
            console.log(address)
            L.marker(address.coords).addTo(this.map)
        })
    }

}

export default Map
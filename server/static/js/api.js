class Api {
    constructor(base_url) {
        this.base_url = base_url
    }

    async get(endpoint) {
        const response = await fetch(this.base_url + endpoint)
        if(!response.ok) {
            throw new Error(`HTTP error: ${response.status}`)
        }
        return await response.json()
    }

    async subscribe_to_event_stream(endpoint) {
        try {
            const response = await fetch(this.base_url + endpoint)

            if(!response.ok){
                throw new Error(`HTTP error: Status: ${response.status}`)
            }

            const reader = response.body.getReader()
            const decoder = new TextDecoder("utf-8")

            while(true) {
                const { value, done } = await reader.read()

                if(done) {
                    console.log("Stream closed by the server.")
                    break
                }

                const chunk = decoder.decode(value, { stream: true })
                console.log("Received chunk: " + chunk)
            }
        }
        catch (error) {
            console.error("Error subscribing to event stream", error)
        }
    }
}

const base_url = "/api/v1"
const api = new Api(base_url)

export function currentCalls(callback) {
    api.get('/current-calls')
        .then(data => {
            callback(data)
        })
        .catch(error => {
            console.error("Error fetching current calls:", error);
        });
}

export function subscribeToEvents() {
    api.subscribe_to_event_stream('/get-events')
}

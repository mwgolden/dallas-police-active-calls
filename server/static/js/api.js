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

    async getStream(endpoint) {
        fetch(this.base_url + endpoint)
            .then(response => {
                const reader = response.body.getReader()

                const read = async () => {
                    const { done, value } = await reader.read()
                    if(done) { return } 

                    const decoder = new TextDecoder("utf-8")
                    const chunk = decoder.decode(value)

                    console.log(chunk)
                }

                read()
            })
        .catch(error => {
            console.error('Error: ', error)
        })
    }
}

const base_url = "/api/v1"
const api = new Api(base_url)

export function current_calls(callback) {
    api.get('/current-calls')
        .then(data => {
            callback(data)
        })
        .catch(error => {
            console.error("Error fetching current calls:", error);
        });
}

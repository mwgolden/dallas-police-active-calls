import { formatDate, toTitleCase } from './utils.js'

function setCallDetails(call) {
        const container = document.getElementById("call-detail")
        const formattedDate = formatDate(call.date)
        const titleCaseLocation = toTitleCase(call.location)
        const card = `<div class="card">
                            <div class="card-header">
                                <b>${call.incidentNumber} | ${call.natureOfCall}</b>
                            </div>
                            <div class="card-body">
                                <p class=card-text">
                                    On ${formattedDate}, at ${call.block === undefined ? "" : call.block } ${call.location} in the ${call.division} division, unit ${call.unitNumber} responded to a Priority ${call.priority} incident in Reporting Area ${call.reportingArea}. The status is currently "${call.status}."
                                </p>
                            </div>
                        </div>`
        container.innerHTML = card
    }

    export { setCallDetails }